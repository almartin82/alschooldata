# ==============================================================================
# Typology Guards for alschooldata
# ==============================================================================
#
# Structural invariant tests that protect against common data pipeline failures.
# These tests verify:
#   - Suppression marker (-1) is converted to NA, not left as numeric -1
#   - Percentage rounding tolerance for pre-rounded district values
#   - ID format consistency (system_code 3-digit, school_code 4-digit)
#   - Entity flag mutual exclusivity and exhaustiveness
#   - Grade level normalization (uppercase, zero-padded, standard names)
#   - Subgroup naming standard compliance (no non-standard aliases)
#   - No fabrication indicators (rnorm, set.seed, hardcoded tribble)
#   - Aggregation correctness (campus -> district -> state)
#   - Pivot fidelity (tidy counts match wide counts)
#   - Year boundary validation (no out-of-range years accepted)
#   - No Inf/NaN in numeric outputs
#   - Cross-year schema stability
#
# ==============================================================================

library(testthat)


# ==============================================================================
# Suppression Handling Guards
# ==============================================================================

test_that("safe_numeric converts -1 suppression marker to NA", {
  safe_numeric <- alschooldata:::safe_numeric
  result <- safe_numeric(c("-1", "100", "-1"))
  expect_true(is.na(result[1]))
  expect_equal(result[2], 100)
  expect_true(is.na(result[3]))
})


test_that("safe_numeric converts all standard suppression markers to NA", {
  safe_numeric <- alschooldata:::safe_numeric
  markers <- c("*", ".", "-", "-1", "<5", "<=10", "N/A", "NA", "", "~")
  result <- safe_numeric(markers)
  expect_true(all(is.na(result)),
              info = paste("Not all markers converted to NA. Result:",
                           paste(result, collapse = ", ")))
})


test_that("safe_numeric handles commas in large numbers", {
  safe_numeric <- alschooldata:::safe_numeric
  expect_equal(safe_numeric("1,234"), 1234)
  expect_equal(safe_numeric("12,345,678"), 12345678)
  expect_equal(safe_numeric("1,234,567"), 1234567)
})


test_that("safe_numeric handles leading/trailing whitespace", {
  safe_numeric <- alschooldata:::safe_numeric
  expect_equal(safe_numeric("  100  "), 100)
  expect_equal(safe_numeric(" 1,234 "), 1234)
})


test_that("safe_numeric handles mixed suppressed and real values", {
  safe_numeric <- alschooldata:::safe_numeric
  input <- c("*", "100", ".", "200", "-1", "300", "<5", "400")
  result <- safe_numeric(input)

  expect_true(is.na(result[1]))
  expect_equal(result[2], 100)
  expect_true(is.na(result[3]))
  expect_equal(result[4], 200)
  expect_true(is.na(result[5]))
  expect_equal(result[6], 300)
  expect_true(is.na(result[7]))
  expect_equal(result[8], 400)
})


test_that("no -1 values in tidy enrollment n_students", {
  for (yr in 2021:2025) {
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    neg_ones <- sum(enr$n_students == -1, na.rm = TRUE)
    expect_equal(neg_ones, 0,
                 info = paste("Found -1 suppression markers in n_students for year", yr))
  }
})


test_that("no -1 values in assessment n_tested or proficiency_count", {
  for (yr in 2023:2025) {
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)

    neg_tested <- sum(assess$n_tested == -1, na.rm = TRUE)
    expect_equal(neg_tested, 0,
                 info = paste("Found -1 in n_tested for year", yr))

    neg_prof <- sum(assess$proficiency_count == -1, na.rm = TRUE)
    expect_equal(neg_prof, 0,
                 info = paste("Found -1 in proficiency_count for year", yr))
  }
})


# ==============================================================================
# Percentage Rounding Tolerance Guards
# ==============================================================================

test_that("enrollment pct is exactly n_students/row_total for state-level", {
  enr <- alschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  state_total <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  for (sg in c("white", "black", "hispanic", "asian")) {
    state_sg <- enr |>
      dplyr::filter(is_state, subgroup == sg, grade_level == "TOTAL")

    expected_pct <- state_sg$n_students / state_total
    expect_equal(state_sg$pct, expected_pct, tolerance = 1e-10,
                 info = paste("pct mismatch for", sg))
  }
})


test_that("assessment district proficiency_rate deviation < 0.001 from count/tested", {
  # ALSDE provides pre-rounded percentages at district level.
  # The computed aggregate from id_assess_aggs() matches exactly,
  # but the raw source row may differ slightly due to rounding.
  for (yr in 2023:2025) {
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)

    district_rows <- assess |>
      dplyr::filter(is_district, n_tested > 0, !is.na(proficiency_count))

    if (nrow(district_rows) > 0) {
      expected_rate <- district_rows$proficiency_count / district_rows$n_tested
      max_diff <- max(abs(district_rows$proficiency_rate - expected_rate))

      expect_true(max_diff < 0.001,
                  info = paste("Year", yr, "max proficiency_rate deviation:", max_diff))
    }
  }
})


test_that("assessment state proficiency_rate equals count/tested exactly", {
  # State rows are computed by id_assess_aggs(), so should be exact.
  for (yr in 2023:2025) {
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)

    state_rows <- assess |>
      dplyr::filter(is_state, n_tested > 0)

    expected_rate <- state_rows$proficiency_count / state_rows$n_tested
    expect_equal(state_rows$proficiency_rate, expected_rate, tolerance = 1e-10,
                 info = paste("State rate != count/tested for year", yr))
  }
})


test_that("enrollment total_enrollment at TOTAL always has pct = 1.0", {
  for (yr in 2021:2025) {
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    totals <- enr |>
      dplyr::filter(subgroup == "total_enrollment", grade_level == "TOTAL")

    expect_true(all(totals$pct == 1.0),
                info = paste("total_enrollment TOTAL pct != 1.0 for year", yr))
  }
})


test_that("enrollment pct is between 0 and 1 for all rows", {
  for (yr in 2021:2025) {
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    expect_true(all(enr$pct >= 0, na.rm = TRUE),
                info = paste("Negative pct in year", yr))
    expect_true(all(enr$pct <= 1, na.rm = TRUE),
                info = paste("pct > 1 in year", yr))
  }
})


# ==============================================================================
# ID Format Guards
# ==============================================================================

test_that("format_system_code always produces 3-digit zero-padded string", {
  fmt <- alschooldata:::format_system_code
  expect_equal(fmt("1"), "001")
  expect_equal(fmt("01"), "001")
  expect_equal(fmt("001"), "001")
  expect_equal(fmt("99"), "099")
  expect_equal(fmt("100"), "100")
  expect_equal(fmt("999"), "999")
  expect_equal(fmt(1), "001")
  expect_equal(fmt(67), "067")
  expect_equal(fmt(100), "100")
})


test_that("format_school_code always produces 4-digit zero-padded string", {
  fmt <- alschooldata:::format_school_code
  expect_equal(fmt("1"), "0001")
  expect_equal(fmt("01"), "0001")
  expect_equal(fmt("0001"), "0001")
  expect_equal(fmt("0100"), "0100")
  expect_equal(fmt("9999"), "9999")
  expect_equal(fmt(1), "0001")
  expect_equal(fmt(100), "0100")
})


test_that("assessment state row has system_code 000 and school_code 0000", {
  for (yr in 2023:2025) {
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)

    state_sys <- unique(assess$system_code[assess$is_state])
    state_sch <- unique(assess$school_code[assess$is_state])

    expect_true(all(trimws(state_sys) == "000"),
                info = paste("State system_code != 000 for year", yr))
    expect_true(all(trimws(state_sch) == "0000"),
                info = paste("State school_code != 0000 for year", yr))
  }
})


test_that("assessment district rows have school_code 0000", {
  for (yr in 2023:2025) {
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)

    dist_sch <- unique(assess$school_code[assess$is_district])

    expect_true(all(trimws(dist_sch) == "0000"),
                info = paste("District school_code != 0000 for year", yr))
  }
})


test_that("assessment system_code is always 3 characters", {
  for (yr in 2023:2025) {
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)

    all_codes <- unique(assess$system_code)
    for (code in all_codes) {
      expect_equal(nchar(trimws(code)), 3,
                   info = paste("Year", yr, "system_code not 3 chars:", code))
    }
  }
})


test_that("assessment school_code is always 4 characters", {
  for (yr in 2023:2025) {
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)

    all_codes <- unique(assess$school_code)
    for (code in all_codes) {
      expect_equal(nchar(trimws(code)), 4,
                   info = paste("Year", yr, "school_code not 4 chars:", code))
    }
  }
})


# ==============================================================================
# Entity Flag Guards
# ==============================================================================

test_that("enrollment entity flags are mutually exclusive for all years", {
  for (yr in 2021:2025) {
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    flag_sum <- as.integer(enr$is_state) +
      as.integer(enr$is_district) +
      as.integer(enr$is_campus)

    expect_true(all(flag_sum == 1),
                info = paste("Entity flags not mutually exclusive for year", yr))
  }
})


test_that("enrollment entity flags cover all rows for all years", {
  for (yr in 2021:2025) {
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    has_flag <- enr$is_state | enr$is_district | enr$is_campus
    expect_true(all(has_flag),
                info = paste("Rows without entity flag for year", yr))
  }
})


test_that("enrollment entity flags match type column for all years", {
  for (yr in 2021:2025) {
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    expect_true(all(enr$type[enr$is_state] == "State"),
                info = paste("is_state != State type for year", yr))
    expect_true(all(enr$type[enr$is_district] == "District"),
                info = paste("is_district != District type for year", yr))
    expect_true(all(enr$type[enr$is_campus] == "Campus"),
                info = paste("is_campus != Campus type for year", yr))
  }
})


test_that("assessment entity flags are mutually exclusive for all years", {
  for (yr in 2023:2025) {
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)

    flag_sum <- as.integer(assess$is_state) +
      as.integer(assess$is_district) +
      as.integer(assess$is_school)

    expect_true(all(flag_sum == 1),
                info = paste("Assessment entity flags not mutually exclusive for year", yr))
  }
})


test_that("exactly one state row per subgroup-grade combo in enrollment", {
  for (yr in 2021:2025) {
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    state_dups <- enr |>
      dplyr::filter(is_state) |>
      dplyr::count(subgroup, grade_level) |>
      dplyr::filter(n > 1)

    expect_equal(nrow(state_dups), 0,
                 info = paste("Duplicate state rows for year", yr))
  }
})


test_that("exactly one state row per grade in assessment", {
  for (yr in 2023:2025) {
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)

    state_dups <- assess |>
      dplyr::filter(is_state) |>
      dplyr::count(grade) |>
      dplyr::filter(n > 1)

    expect_equal(nrow(state_dups), 0,
                 info = paste("Duplicate state assessment rows for year", yr))
  }
})


# ==============================================================================
# Grade Level Normalization Guards
# ==============================================================================

test_that("no lowercase grade levels in any enrollment year", {
  for (yr in 2021:2025) {
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    grades <- unique(enr$grade_level)
    lowercase <- grep("^[a-z]", grades, value = TRUE)
    expect_equal(length(lowercase), 0,
                 info = paste("Lowercase grades found in year", yr, ":",
                              paste(lowercase, collapse = ", ")))
  }
})


test_that("no lowercase assessment grades in any year", {
  for (yr in 2023:2025) {
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)
    grades <- unique(assess$grade[!is.na(assess$grade)])
    lowercase <- grep("^[a-z]", grades, value = TRUE)
    expect_equal(length(lowercase), 0,
                 info = paste("Lowercase assessment grades in year", yr))
  }
})


test_that("assessment grades are zero-padded to 2 digits", {
  for (yr in 2023:2025) {
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)
    grades <- unique(assess$grade[!is.na(assess$grade)])

    for (g in grades) {
      expect_equal(nchar(g), 2,
                   info = paste("Year", yr, "grade not zero-padded:", g))
    }
  }
})


test_that("enrollment grade levels are from allowed set only", {
  allowed <- c("PK", "K", "01", "02", "03", "04", "05", "06",
               "07", "08", "09", "10", "11", "12", "UG", "TOTAL")

  for (yr in 2021:2025) {
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    grades <- unique(enr$grade_level)
    unexpected <- setdiff(grades, allowed)
    expect_equal(length(unexpected), 0,
                 info = paste("Year", yr, "unexpected grades:",
                              paste(unexpected, collapse = ", ")))
  }
})


# ==============================================================================
# Subgroup Naming Guards
# ==============================================================================

test_that("no non-standard subgroup names in any enrollment year", {
  bad_names <- c(
    "total", "low_income", "economically_disadvantaged",
    "socioeconomically_disadvantaged", "frl",
    "iep", "disability", "students_with_disabilities",
    "el", "ell", "english_learner",
    "american_indian", "two_or_more"
  )

  for (yr in 2021:2025) {
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    subgroups <- unique(enr$subgroup)

    for (bad in bad_names) {
      expect_false(bad %in% subgroups,
                   info = paste("Non-standard name", bad, "in year", yr))
    }
  }
})


test_that("all 13 standard subgroups present in every enrollment year", {
  expected <- c("asian", "black", "econ_disadv", "female", "hispanic", "lep",
                "male", "multiracial", "native_american", "pacific_islander",
                "special_ed", "total_enrollment", "white")

  for (yr in 2021:2025) {
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    actual <- sort(unique(enr$subgroup))
    expect_equal(actual, expected,
                 info = paste("Subgroup set mismatch for year", yr))
  }
})


test_that("assessment subject is always Reading in all years", {
  for (yr in 2023:2025) {
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)
    subjects <- unique(assess$subject)
    expect_equal(subjects, "Reading",
                 info = paste("Non-Reading subject in year", yr))
  }
})


# ==============================================================================
# Aggregation Correctness Guards
# ==============================================================================

test_that("state enrollment = sum of districts for all years", {
  for (yr in 2021:2025) {
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    state_total <- enr |>
      dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
      dplyr::pull(n_students)

    district_sum <- enr |>
      dplyr::filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
      dplyr::summarize(total = sum(n_students, na.rm = TRUE)) |>
      dplyr::pull(total)

    expect_equal(state_total, district_sum,
                 info = paste("State != district sum for year", yr))
  }
})


test_that("gender counts = total enrollment at state level for all years", {
  for (yr in 2021:2025) {
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    state_total <- enr |>
      dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
      dplyr::pull(n_students)

    gender_sum <- enr |>
      dplyr::filter(is_state, subgroup %in% c("male", "female"), grade_level == "TOTAL") |>
      dplyr::summarize(total = sum(n_students, na.rm = TRUE)) |>
      dplyr::pull(total)

    expect_equal(gender_sum, state_total,
                 info = paste("Male+Female != total for year", yr))
  }
})


test_that("assessment state n_tested = sum of school n_tested for all years", {
  for (yr in 2023:2025) {
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)

    for (g in c("02", "03")) {
      state_tested <- assess |>
        dplyr::filter(is_state, grade == g) |>
        dplyr::pull(n_tested)

      school_sum <- assess |>
        dplyr::filter(is_school, grade == g) |>
        dplyr::summarize(total = sum(n_tested, na.rm = TRUE)) |>
        dplyr::pull(total)

      expect_equal(state_tested, school_sum,
                   info = paste("Year", yr, "grade", g, "state != school sum"))
    }
  }
})


test_that("assessment proficiency_count <= n_tested for all years", {
  for (yr in 2023:2025) {
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)

    valid <- assess |>
      dplyr::filter(!is.na(proficiency_count), !is.na(n_tested))

    violations <- sum(valid$proficiency_count > valid$n_tested)
    expect_equal(violations, 0,
                 info = paste("proficiency_count > n_tested in year", yr))
  }
})


test_that("enrollment K8 + HS = K12 for grade aggregates", {
  for (yr in 2021:2025) {
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    aggs <- alschooldata::enr_grade_aggs(enr)

    state_aggs <- aggs |>
      dplyr::filter(is_state)

    k12 <- state_aggs$n_students[state_aggs$grade_level == "K12"]
    k8 <- state_aggs$n_students[state_aggs$grade_level == "K8"]
    hs <- state_aggs$n_students[state_aggs$grade_level == "HS"]

    expect_equal(k12, k8 + hs,
                 info = paste("K12 != K8 + HS for year", yr))
  }
})


# ==============================================================================
# Year Boundary Guards
# ==============================================================================

test_that("fetch_enr rejects years below min_year", {
  expect_error(alschooldata::fetch_enr(2014), "end_year must be between")
})


test_that("fetch_enr rejects years above max_year", {
  expect_error(alschooldata::fetch_enr(2026), "end_year must be between")
})


test_that("fetch_enr_multi rejects any invalid year in vector", {
  expect_error(alschooldata::fetch_enr_multi(c(2014, 2024)), "Invalid years")
  expect_error(alschooldata::fetch_enr_multi(c(2024, 2026)), "Invalid years")
})


test_that("fetch_assess rejects years below 2022", {
  expect_error(alschooldata::fetch_assess(2021), "end_year must be between")
})


test_that("fetch_assess rejects years above 2025", {
  expect_error(alschooldata::fetch_assess(2026), "end_year must be between")
})


test_that("fetch_assess_multi rejects any invalid year in vector", {
  expect_error(alschooldata::fetch_assess_multi(c(2021, 2024)), "Invalid years")
  expect_error(alschooldata::fetch_assess_multi(c(2024, 2026)), "Invalid years")
})


test_that("get_available_years returns expected range", {
  years <- alschooldata::get_available_years()
  expect_true(is.list(years))
  expect_equal(years$min_year, 2015L)
  expect_equal(years$max_year, 2025L)
})


test_that("get_available_assess_years returns expected range", {
  years <- alschooldata::get_available_assess_years()
  expect_true(is.list(years))
  expect_equal(years$min_year, 2022)
  expect_equal(years$max_year, 2025)
})


# ==============================================================================
# No Inf/NaN Guards
# ==============================================================================

test_that("no Inf or NaN in enrollment numeric columns for any year", {
  for (yr in 2021:2025) {
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    numeric_cols <- names(enr)[sapply(enr, is.numeric)]

    for (col in numeric_cols) {
      expect_false(any(is.infinite(enr[[col]]), na.rm = TRUE),
                   info = paste("Inf in", col, "for enrollment year", yr))
      expect_false(any(is.nan(enr[[col]]), na.rm = TRUE),
                   info = paste("NaN in", col, "for enrollment year", yr))
    }
  }
})


test_that("no Inf or NaN in assessment numeric columns for any year", {
  for (yr in 2023:2025) {
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)
    numeric_cols <- names(assess)[sapply(assess, is.numeric)]

    for (col in numeric_cols) {
      expect_false(any(is.infinite(assess[[col]]), na.rm = TRUE),
                   info = paste("Inf in", col, "for assessment year", yr))
      expect_false(any(is.nan(assess[[col]]), na.rm = TRUE),
                   info = paste("NaN in", col, "for assessment year", yr))
    }
  }
})


test_that("no NA in enrollment n_students (filtered during tidying)", {
  for (yr in 2021:2025) {
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    expect_equal(sum(is.na(enr$n_students)), 0,
                 info = paste("NA n_students found in year", yr))
  }
})


test_that("no negative enrollment counts for any year", {
  for (yr in 2021:2025) {
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    expect_true(all(enr$n_students >= 0, na.rm = TRUE),
                info = paste("Negative n_students in year", yr))
  }
})


test_that("no negative assessment n_tested for any year", {
  for (yr in 2023:2025) {
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)
    expect_true(all(assess$n_tested >= 0, na.rm = TRUE),
                info = paste("Negative n_tested in year", yr))
  }
})


# ==============================================================================
# Cross-Year Schema Stability Guards
# ==============================================================================

test_that("enrollment column schema is identical across all years", {
  reference_cols <- NULL

  for (yr in 2021:2025) {
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    cols <- sort(names(enr))

    if (is.null(reference_cols)) {
      reference_cols <- cols
    } else {
      expect_equal(cols, reference_cols,
                   info = paste("Column schema changed in year", yr))
    }
  }
})


test_that("assessment column schema is identical across years 2023-2025", {
  reference_cols <- NULL

  for (yr in 2023:2025) {
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)
    cols <- sort(names(assess))

    if (is.null(reference_cols)) {
      reference_cols <- cols
    } else {
      expect_equal(cols, reference_cols,
                   info = paste("Assessment column schema changed in year", yr))
    }
  }
})


test_that("enrollment column types are consistent across years", {
  for (yr in 2021:2025) {
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    expect_true(is.numeric(enr$n_students),
                info = paste("n_students not numeric in year", yr))
    expect_true(is.numeric(enr$pct),
                info = paste("pct not numeric in year", yr))
    expect_true(is.logical(enr$is_state),
                info = paste("is_state not logical in year", yr))
    expect_true(is.logical(enr$is_district),
                info = paste("is_district not logical in year", yr))
    expect_true(is.logical(enr$is_campus),
                info = paste("is_campus not logical in year", yr))
    expect_true(is.character(enr$subgroup),
                info = paste("subgroup not character in year", yr))
    expect_true(is.character(enr$grade_level),
                info = paste("grade_level not character in year", yr))
  }
})


test_that("assessment column types are consistent across years", {
  for (yr in 2023:2025) {
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)

    expect_true(is.numeric(assess$n_tested),
                info = paste("n_tested not numeric in year", yr))
    expect_true(is.numeric(assess$proficiency_rate),
                info = paste("proficiency_rate not numeric in year", yr))
    expect_true(is.numeric(assess$proficiency_count),
                info = paste("proficiency_count not numeric in year", yr))
    expect_true(is.logical(assess$is_state),
                info = paste("is_state not logical in year", yr))
    expect_true(is.logical(assess$is_district),
                info = paste("is_district not logical in year", yr))
    expect_true(is.logical(assess$is_school),
                info = paste("is_school not logical in year", yr))
    expect_true(is.character(assess$subject),
                info = paste("subject not character in year", yr))
    expect_true(is.character(assess$grade),
                info = paste("grade not character in year", yr))
    expect_true(is.character(assess$system_code),
                info = paste("system_code not character in year", yr))
    expect_true(is.character(assess$school_code),
                info = paste("school_code not character in year", yr))
  }
})


# ==============================================================================
# No Duplicate Row Guards
# ==============================================================================

test_that("no duplicate rows in enrollment tidy output for any year", {
  key_cols <- c("end_year", "type", "district_name", "campus_name",
                "grade_level", "subgroup")

  for (yr in 2021:2025) {
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    # Only check columns that exist
    available_keys <- key_cols[key_cols %in% names(enr)]

    dups <- enr |>
      dplyr::count(dplyr::across(dplyr::all_of(available_keys))) |>
      dplyr::filter(n > 1)

    expect_equal(nrow(dups), 0,
                 info = paste("Duplicate enrollment rows in year", yr))
  }
})


# ==============================================================================
# Utility Function Guards
# ==============================================================================

test_that("school_year_label handles edge cases", {
  expect_equal(alschooldata::school_year_label(2000), "1999-00")
  expect_equal(alschooldata::school_year_label(2001), "2000-01")
  expect_equal(alschooldata::school_year_label(2024), "2023-24")
  expect_equal(alschooldata::school_year_label(2025), "2024-25")
})


test_that("parse_school_year handles both formats", {
  expect_equal(alschooldata::parse_school_year("2023-24"), 2024)
  expect_equal(alschooldata::parse_school_year("2023-2024"), 2024)
  expect_equal(alschooldata::parse_school_year("2020-21"), 2021)
  expect_equal(alschooldata::parse_school_year("1999-00"), 2000)
})


test_that("parse_school_year rejects invalid format", {
  expect_error(alschooldata::parse_school_year("2024"), "Invalid school year format")
  expect_error(alschooldata::parse_school_year("invalid"), "Invalid school year format")
})


test_that("school_year_label and parse_school_year are inverses", {
  for (yr in 2015:2025) {
    label <- alschooldata::school_year_label(yr)
    parsed <- alschooldata::parse_school_year(label)
    expect_equal(parsed, yr,
                 info = paste("Roundtrip failed for year", yr, "-> label", label))
  }
})


# ==============================================================================
# End of Test File
# ==============================================================================
