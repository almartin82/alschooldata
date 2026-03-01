# ==============================================================================
# Assessment Year Coverage Tests for alschooldata
# ==============================================================================
#
# Per-year tests through ALL available ACAP assessment years (2023-2025).
# Year 2022 is excluded: not cached and raw file parsing fails due to
# different Excel format (missing system_code/system_name columns).
#
# Each year verifies:
#   - Pinned state n_tested and proficiency_count per grade (02, 03)
#   - Pinned state proficiency_rate per grade
#   - Pre-rounded percentage tolerance (district-level)
#   - system_code 3-digit zero-padded format
#   - school_code 4-digit zero-padded format
#   - District and school counts
#   - Birmingham and Mobile County presence and pinned values
#   - Subject always "Reading"
#   - Grade always "02" or "03"
#   - Entity flag correctness
#
# All pinned values come from running actual fetch functions with use_cache=TRUE
# against real ALSDE cached data. No fabricated numbers.
#
# ==============================================================================

library(testthat)


# ==============================================================================
# Year 2023
# ==============================================================================

test_that("2023 state grade 02: n_tested=53,824, prof_count=42,192, rate~0.7839", {
  assess <- alschooldata::fetch_assess(2023, use_cache = TRUE)

  state_g02 <- assess |>
    dplyr::filter(is_state, grade == "02")

  expect_equal(nrow(state_g02), 1)
  expect_equal(state_g02$n_tested, 53824)
  expect_equal(state_g02$proficiency_count, 42192)
  expect_equal(state_g02$proficiency_rate, 0.7838882, tolerance = 1e-5)
})


test_that("2023 state grade 03: n_tested=52,435, prof_count=39,616, rate~0.7555", {
  assess <- alschooldata::fetch_assess(2023, use_cache = TRUE)

  state_g03 <- assess |>
    dplyr::filter(is_state, grade == "03")

  expect_equal(nrow(state_g03), 1)
  expect_equal(state_g03$n_tested, 52435)
  expect_equal(state_g03$proficiency_count, 39616)
  expect_equal(state_g03$proficiency_rate, 0.7555259, tolerance = 1e-5)
})


test_that("2023 has 146 districts and 183 schools", {
  assess <- alschooldata::fetch_assess(2023, use_cache = TRUE)

  dist_count <- assess |>
    dplyr::filter(is_district) |>
    dplyr::pull(system_code) |>
    unique() |>
    length()
  expect_equal(dist_count, 146)

  school_count <- assess |>
    dplyr::filter(is_school) |>
    dplyr::pull(school_code) |>
    unique() |>
    length()
  expect_equal(school_count, 183)
})


test_that("2023 Birmingham grade 02: n_tested=1,618, prof_rate~0.5451", {
  assess <- alschooldata::fetch_assess(2023, use_cache = TRUE)

  # Birmingham has two district rows (raw + computed aggregate)
  bham <- assess |>
    dplyr::filter(grepl("Birmingham", system_name, ignore.case = TRUE),
                  is_district, grade == "02")

  expect_gte(nrow(bham), 1)

  # At least one row should match the expected values
  expect_true(1618 %in% bham$n_tested,
              info = "Birmingham grade 02 n_tested should be 1618")

  # Pre-rounded rate from raw source
  raw_rate <- bham$proficiency_rate[bham$n_tested == 1618]
  expect_true(any(abs(raw_rate - 0.5451) < 0.001),
              info = "Birmingham grade 02 proficiency_rate ~0.5451")
})


test_that("2023 Mobile County grade 02 present with reasonable values", {
  assess <- alschooldata::fetch_assess(2023, use_cache = TRUE)

  mobile <- assess |>
    dplyr::filter(grepl("Mobile County", system_name, ignore.case = TRUE),
                  is_district, grade == "02")

  expect_gte(nrow(mobile), 1)
  expect_true(any(mobile$n_tested > 3000),
              info = "Mobile County grade 02 should have >3000 tested")
})


test_that("2023 system_code is 3-digit zero-padded", {
  assess <- alschooldata::fetch_assess(2023, use_cache = TRUE)

  dist_codes <- assess |>
    dplyr::filter(is_district) |>
    dplyr::pull(system_code) |>
    unique()

  for (code in dist_codes) {
    expect_equal(nchar(trimws(code)), 3,
                 info = paste("system_code not 3 digits:", code))
  }
})


test_that("2023 school_code is 4-digit zero-padded", {
  assess <- alschooldata::fetch_assess(2023, use_cache = TRUE)

  school_codes <- assess |>
    dplyr::filter(is_school) |>
    dplyr::pull(school_code) |>
    unique()

  for (code in school_codes) {
    expect_equal(nchar(trimws(code)), 4,
                 info = paste("school_code not 4 digits:", code))
  }
})


test_that("2023 subject is always Reading", {
  assess <- alschooldata::fetch_assess(2023, use_cache = TRUE)
  expect_true(all(assess$subject == "Reading"))
})


test_that("2023 grades are 02 and 03 only", {
  assess <- alschooldata::fetch_assess(2023, use_cache = TRUE)
  grades <- unique(assess$grade[!is.na(assess$grade)])
  expect_true(all(grades %in% c("02", "03")))
})


test_that("2023 entity flags are mutually exclusive and exhaustive", {
  assess <- alschooldata::fetch_assess(2023, use_cache = TRUE)

  flag_sum <- as.integer(assess$is_state) +
    as.integer(assess$is_district) +
    as.integer(assess$is_school)

  expect_true(all(flag_sum == 1))
})


test_that("2023 state aggregate equals sum of school-level n_tested", {
  assess <- alschooldata::fetch_assess(2023, use_cache = TRUE)

  for (g in c("02", "03")) {
    state_tested <- assess |>
      dplyr::filter(is_state, grade == g) |>
      dplyr::pull(n_tested)

    school_sum <- assess |>
      dplyr::filter(is_school, grade == g) |>
      dplyr::summarize(total = sum(n_tested, na.rm = TRUE)) |>
      dplyr::pull(total)

    expect_equal(state_tested, school_sum,
                 info = paste("2023 state != school sum for grade", g))
  }
})


test_that("2023 proficiency_rate in 0-1 range", {
  assess <- alschooldata::fetch_assess(2023, use_cache = TRUE)
  expect_true(all(assess$proficiency_rate >= 0 & assess$proficiency_rate <= 1, na.rm = TRUE))
})


test_that("2023 proficiency_count <= n_tested", {
  assess <- alschooldata::fetch_assess(2023, use_cache = TRUE)
  valid <- assess[!is.na(assess$proficiency_count) & !is.na(assess$n_tested), ]
  expect_true(all(valid$proficiency_count <= valid$n_tested))
})


test_that("2023 end_year is 2023", {
  assess <- alschooldata::fetch_assess(2023, use_cache = TRUE)
  expect_true(all(assess$end_year == 2023))
})


# ==============================================================================
# Year 2024
# ==============================================================================

test_that("2024 state grade 02: n_tested=56,185, prof_count=46,538, rate~0.8283", {
  assess <- alschooldata::fetch_assess(2024, use_cache = TRUE)

  state_g02 <- assess |>
    dplyr::filter(is_state, grade == "02")

  expect_equal(nrow(state_g02), 1)
  expect_equal(state_g02$n_tested, 56185)
  expect_equal(state_g02$proficiency_count, 46538)
  expect_equal(state_g02$proficiency_rate, 0.8282994, tolerance = 1e-5)
})


test_that("2024 state grade 03: n_tested=53,405, prof_count=48,605, rate~0.9101", {
  assess <- alschooldata::fetch_assess(2024, use_cache = TRUE)

  state_g03 <- assess |>
    dplyr::filter(is_state, grade == "03")

  expect_equal(nrow(state_g03), 1)
  expect_equal(state_g03$n_tested, 53405)
  expect_equal(state_g03$proficiency_count, 48605)
  expect_equal(state_g03$proficiency_rate, 0.9101208, tolerance = 1e-5)
})


test_that("2024 has 147 districts and 183 schools", {
  assess <- alschooldata::fetch_assess(2024, use_cache = TRUE)

  dist_count <- assess |>
    dplyr::filter(is_district) |>
    dplyr::pull(system_code) |>
    unique() |>
    length()
  expect_equal(dist_count, 147)

  school_count <- assess |>
    dplyr::filter(is_school) |>
    dplyr::pull(school_code) |>
    unique() |>
    length()
  expect_equal(school_count, 183)
})


test_that("2024 Birmingham grade 02: n_tested=1,653, prof_rate~0.6794", {
  assess <- alschooldata::fetch_assess(2024, use_cache = TRUE)

  bham <- assess |>
    dplyr::filter(grepl("Birmingham", system_name, ignore.case = TRUE),
                  is_district, grade == "02")

  expect_gte(nrow(bham), 1)
  expect_true(1653 %in% bham$n_tested)

  raw_rate <- bham$proficiency_rate[bham$n_tested == 1653]
  expect_true(any(abs(raw_rate - 0.6794) < 0.001))
})


test_that("2024 Birmingham grade 03: n_tested includes 1,644", {
  assess <- alschooldata::fetch_assess(2024, use_cache = TRUE)

  bham <- assess |>
    dplyr::filter(grepl("Birmingham", system_name, ignore.case = TRUE),
                  is_district, grade == "03")

  expect_gte(nrow(bham), 1)
  # Raw source has n_tested=1644, computed aggregate has 1639
  expect_true(any(bham$n_tested %in% c(1644, 1639)))
})


test_that("2024 Mobile County grade 02 present with >4000 tested", {
  assess <- alschooldata::fetch_assess(2024, use_cache = TRUE)

  mobile <- assess |>
    dplyr::filter(grepl("Mobile County", system_name, ignore.case = TRUE),
                  is_district, grade == "02")

  expect_gte(nrow(mobile), 1)
  expect_true(any(mobile$n_tested > 4000))
})


test_that("2024 district proficiency_rate tolerance < 0.001 vs count/tested", {
  assess <- alschooldata::fetch_assess(2024, use_cache = TRUE)

  district_rows <- assess |>
    dplyr::filter(is_district, n_tested > 0, !is.na(proficiency_count))

  expected_rate <- district_rows$proficiency_count / district_rows$n_tested
  max_diff <- max(abs(district_rows$proficiency_rate - expected_rate))

  expect_true(max_diff < 0.001,
              info = paste("Max proficiency_rate deviation:", max_diff))
})


test_that("2024 system_code is 3-digit zero-padded", {
  assess <- alschooldata::fetch_assess(2024, use_cache = TRUE)

  dist_codes <- assess |>
    dplyr::filter(is_district) |>
    dplyr::pull(system_code) |>
    unique()

  for (code in dist_codes) {
    expect_equal(nchar(trimws(code)), 3,
                 info = paste("system_code not 3 digits:", code))
  }
})


test_that("2024 school_code is 4-digit zero-padded", {
  assess <- alschooldata::fetch_assess(2024, use_cache = TRUE)

  school_codes <- assess |>
    dplyr::filter(is_school) |>
    dplyr::pull(school_code) |>
    unique()

  for (code in school_codes) {
    expect_equal(nchar(trimws(code)), 4,
                 info = paste("school_code not 4 digits:", code))
  }
})


test_that("2024 state system_code is 000", {
  assess <- alschooldata::fetch_assess(2024, use_cache = TRUE)

  state_codes <- assess |>
    dplyr::filter(is_state) |>
    dplyr::pull(system_code) |>
    unique()

  expect_true(all(trimws(state_codes) == "000"))
})


test_that("2024 district school_code is 0000", {
  assess <- alschooldata::fetch_assess(2024, use_cache = TRUE)

  dist_school_codes <- assess |>
    dplyr::filter(is_district) |>
    dplyr::pull(school_code) |>
    unique()

  expect_true(all(trimws(dist_school_codes) == "0000"))
})


test_that("2024 subject is always Reading", {
  assess <- alschooldata::fetch_assess(2024, use_cache = TRUE)
  expect_true(all(assess$subject == "Reading"))
})


test_that("2024 grades are 02 and 03 only", {
  assess <- alschooldata::fetch_assess(2024, use_cache = TRUE)
  grades <- unique(assess$grade[!is.na(assess$grade)])
  expect_true(all(grades %in% c("02", "03")))
})


test_that("2024 entity flags are mutually exclusive and exhaustive", {
  assess <- alschooldata::fetch_assess(2024, use_cache = TRUE)

  flag_sum <- as.integer(assess$is_state) +
    as.integer(assess$is_district) +
    as.integer(assess$is_school)

  expect_true(all(flag_sum == 1))
})


test_that("2024 state aggregate equals sum of school-level n_tested", {
  assess <- alschooldata::fetch_assess(2024, use_cache = TRUE)

  for (g in c("02", "03")) {
    state_tested <- assess |>
      dplyr::filter(is_state, grade == g) |>
      dplyr::pull(n_tested)

    school_sum <- assess |>
      dplyr::filter(is_school, grade == g) |>
      dplyr::summarize(total = sum(n_tested, na.rm = TRUE)) |>
      dplyr::pull(total)

    expect_equal(state_tested, school_sum,
                 info = paste("2024 state != school sum for grade", g))
  }
})


test_that("2024 state proficiency_rate equals proficiency_count / n_tested exactly", {
  assess <- alschooldata::fetch_assess(2024, use_cache = TRUE)

  state_rows <- assess |>
    dplyr::filter(is_state, n_tested > 0)

  expected_rate <- state_rows$proficiency_count / state_rows$n_tested
  expect_equal(state_rows$proficiency_rate, expected_rate, tolerance = 1e-10)
})


test_that("2024 proficiency_rate in 0-1 range", {
  assess <- alschooldata::fetch_assess(2024, use_cache = TRUE)
  expect_true(all(assess$proficiency_rate >= 0 & assess$proficiency_rate <= 1, na.rm = TRUE))
})


test_that("2024 proficiency_count <= n_tested", {
  assess <- alschooldata::fetch_assess(2024, use_cache = TRUE)
  valid <- assess[!is.na(assess$proficiency_count) & !is.na(assess$n_tested), ]
  expect_true(all(valid$proficiency_count <= valid$n_tested))
})


test_that("2024 end_year is 2024", {
  assess <- alschooldata::fetch_assess(2024, use_cache = TRUE)
  expect_true(all(assess$end_year == 2024))
})


test_that("2024 no Inf or NaN in numeric columns", {
  assess <- alschooldata::fetch_assess(2024, use_cache = TRUE)
  numeric_cols <- names(assess)[sapply(assess, is.numeric)]

  for (col in numeric_cols) {
    expect_false(any(is.infinite(assess[[col]]), na.rm = TRUE),
                 info = paste("Inf in", col))
    expect_false(any(is.nan(assess[[col]]), na.rm = TRUE),
                 info = paste("NaN in", col))
  }
})


# ==============================================================================
# Year 2025
# ==============================================================================

test_that("2025 state grade 02: n_tested=55,332, prof_count=44,930, rate~0.8120", {
  assess <- alschooldata::fetch_assess(2025, use_cache = TRUE)

  state_g02 <- assess |>
    dplyr::filter(is_state, grade == "02")

  expect_equal(nrow(state_g02), 1)
  expect_equal(state_g02$n_tested, 55332)
  expect_equal(state_g02$proficiency_count, 44930)
  expect_equal(state_g02$proficiency_rate, 0.8120075, tolerance = 1e-5)
})


test_that("2025 state grade 03: n_tested=55,847, prof_count=49,387, rate~0.8843", {
  assess <- alschooldata::fetch_assess(2025, use_cache = TRUE)

  state_g03 <- assess |>
    dplyr::filter(is_state, grade == "03")

  expect_equal(nrow(state_g03), 1)
  expect_equal(state_g03$n_tested, 55847)
  expect_equal(state_g03$proficiency_count, 49387)
  expect_equal(state_g03$proficiency_rate, 0.8843268, tolerance = 1e-5)
})


test_that("2025 has 148 districts and 185 schools", {
  assess <- alschooldata::fetch_assess(2025, use_cache = TRUE)

  dist_count <- assess |>
    dplyr::filter(is_district) |>
    dplyr::pull(system_code) |>
    unique() |>
    length()
  expect_equal(dist_count, 148)

  school_count <- assess |>
    dplyr::filter(is_school) |>
    dplyr::pull(school_code) |>
    unique() |>
    length()
  expect_equal(school_count, 185)
})


test_that("2025 Birmingham grade 02: n_tested=1,622, prof_rate~0.6436", {
  assess <- alschooldata::fetch_assess(2025, use_cache = TRUE)

  bham <- assess |>
    dplyr::filter(grepl("Birmingham", system_name, ignore.case = TRUE),
                  is_district, grade == "02")

  expect_gte(nrow(bham), 1)
  expect_true(1622 %in% bham$n_tested)

  raw_rate <- bham$proficiency_rate[bham$n_tested == 1622]
  expect_true(any(abs(raw_rate - 0.6436) < 0.001))
})


test_that("2025 Birmingham grade 03: n_tested includes 1,697 or 1,692", {
  assess <- alschooldata::fetch_assess(2025, use_cache = TRUE)

  bham <- assess |>
    dplyr::filter(grepl("Birmingham", system_name, ignore.case = TRUE),
                  is_district, grade == "03")

  expect_gte(nrow(bham), 1)
  # Raw source has n_tested=1697, computed aggregate has 1692
  expect_true(any(bham$n_tested %in% c(1697, 1692)))
})


test_that("2025 Mobile County grade 02 present with >3900 tested", {
  assess <- alschooldata::fetch_assess(2025, use_cache = TRUE)

  mobile <- assess |>
    dplyr::filter(grepl("Mobile County", system_name, ignore.case = TRUE),
                  is_district, grade == "02")

  expect_gte(nrow(mobile), 1)
  expect_true(any(mobile$n_tested > 3900))
})


test_that("2025 district proficiency_rate tolerance < 0.001 vs count/tested", {
  assess <- alschooldata::fetch_assess(2025, use_cache = TRUE)

  district_rows <- assess |>
    dplyr::filter(is_district, n_tested > 0, !is.na(proficiency_count))

  expected_rate <- district_rows$proficiency_count / district_rows$n_tested
  max_diff <- max(abs(district_rows$proficiency_rate - expected_rate))

  expect_true(max_diff < 0.001,
              info = paste("Max proficiency_rate deviation:", max_diff))
})


test_that("2025 system_code is 3-digit zero-padded", {
  assess <- alschooldata::fetch_assess(2025, use_cache = TRUE)

  dist_codes <- assess |>
    dplyr::filter(is_district) |>
    dplyr::pull(system_code) |>
    unique()

  for (code in dist_codes) {
    expect_equal(nchar(trimws(code)), 3,
                 info = paste("system_code not 3 digits:", code))
  }
})


test_that("2025 subject is always Reading", {
  assess <- alschooldata::fetch_assess(2025, use_cache = TRUE)
  expect_true(all(assess$subject == "Reading"))
})


test_that("2025 grades are 02 and 03 only", {
  assess <- alschooldata::fetch_assess(2025, use_cache = TRUE)
  grades <- unique(assess$grade[!is.na(assess$grade)])
  expect_true(all(grades %in% c("02", "03")))
})


test_that("2025 entity flags are mutually exclusive and exhaustive", {
  assess <- alschooldata::fetch_assess(2025, use_cache = TRUE)

  flag_sum <- as.integer(assess$is_state) +
    as.integer(assess$is_district) +
    as.integer(assess$is_school)

  expect_true(all(flag_sum == 1))
})


test_that("2025 state aggregate equals sum of school-level n_tested", {
  assess <- alschooldata::fetch_assess(2025, use_cache = TRUE)

  for (g in c("02", "03")) {
    state_tested <- assess |>
      dplyr::filter(is_state, grade == g) |>
      dplyr::pull(n_tested)

    school_sum <- assess |>
      dplyr::filter(is_school, grade == g) |>
      dplyr::summarize(total = sum(n_tested, na.rm = TRUE)) |>
      dplyr::pull(total)

    expect_equal(state_tested, school_sum,
                 info = paste("2025 state != school sum for grade", g))
  }
})


test_that("2025 proficiency_rate in 0-1 range", {
  assess <- alschooldata::fetch_assess(2025, use_cache = TRUE)
  expect_true(all(assess$proficiency_rate >= 0 & assess$proficiency_rate <= 1, na.rm = TRUE))
})


test_that("2025 proficiency_count <= n_tested", {
  assess <- alschooldata::fetch_assess(2025, use_cache = TRUE)
  valid <- assess[!is.na(assess$proficiency_count) & !is.na(assess$n_tested), ]
  expect_true(all(valid$proficiency_count <= valid$n_tested))
})


test_that("2025 end_year is 2025", {
  assess <- alschooldata::fetch_assess(2025, use_cache = TRUE)
  expect_true(all(assess$end_year == 2025))
})


test_that("2025 no Inf or NaN in numeric columns", {
  assess <- alschooldata::fetch_assess(2025, use_cache = TRUE)
  numeric_cols <- names(assess)[sapply(assess, is.numeric)]

  for (col in numeric_cols) {
    expect_false(any(is.infinite(assess[[col]]), na.rm = TRUE),
                 info = paste("Inf in", col))
    expect_false(any(is.nan(assess[[col]]), na.rm = TRUE),
                 info = paste("NaN in", col))
  }
})


# ==============================================================================
# Cross-Year Assessment Trends
# ==============================================================================

test_that("state grade 02 proficiency improved 2023-2024 then dipped 2025", {
  # Real trend: 0.7839 -> 0.8283 -> 0.8120
  expected <- c("2023" = 0.7838882, "2024" = 0.8282994, "2025" = 0.8120075)

  for (yr_str in names(expected)) {
    yr <- as.integer(yr_str)
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)

    rate <- assess |>
      dplyr::filter(is_state, grade == "02") |>
      dplyr::pull(proficiency_rate)

    expect_equal(rate, expected[[yr_str]], tolerance = 1e-5,
                 info = paste("Grade 02 proficiency_rate for year", yr))
  }
})


test_that("state grade 03 proficiency improved 2023-2024 then dipped 2025", {
  # Real trend: 0.7555 -> 0.9101 -> 0.8843
  expected <- c("2023" = 0.7555259, "2024" = 0.9101208, "2025" = 0.8843268)

  for (yr_str in names(expected)) {
    yr <- as.integer(yr_str)
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)

    rate <- assess |>
      dplyr::filter(is_state, grade == "03") |>
      dplyr::pull(proficiency_rate)

    expect_equal(rate, expected[[yr_str]], tolerance = 1e-5,
                 info = paste("Grade 03 proficiency_rate for year", yr))
  }
})


test_that("fetch_assess_multi returns all 3 cached years correctly", {
  multi <- alschooldata::fetch_assess_multi(2023:2025, use_cache = TRUE)

  years_present <- unique(multi$end_year)
  expect_true(2023 %in% years_present)
  expect_true(2024 %in% years_present)
  expect_true(2025 %in% years_present)

  # Total row count should be sum of individual years
  individual_counts <- vapply(2023:2025, function(yr) {
    nrow(alschooldata::fetch_assess(yr, use_cache = TRUE))
  }, integer(1))

  expect_equal(nrow(multi), sum(individual_counts))
})


test_that("Jefferson County present in all assessment years 2023-2025", {
  for (yr in 2023:2025) {
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)

    jefferson <- assess |>
      dplyr::filter(grepl("Jefferson County", system_name, ignore.case = TRUE))

    expect_true(nrow(jefferson) > 0,
                info = paste("Jefferson County not found in year", yr))
  }
})


test_that("Mobile County present in all assessment years 2023-2025", {
  for (yr in 2023:2025) {
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)

    mobile <- assess |>
      dplyr::filter(grepl("Mobile County", system_name, ignore.case = TRUE))

    expect_true(nrow(mobile) > 0,
                info = paste("Mobile County not found in year", yr))
  }
})


test_that("assessment column schema is consistent across years 2023-2025", {
  expected_cols <- c(
    "end_year", "system_code", "system_name", "school_code", "school_name",
    "subject", "grade", "grade_level",
    "n_tested", "proficiency_count", "proficiency_rate",
    "is_state", "is_district", "is_school"
  )

  for (yr in 2023:2025) {
    assess <- alschooldata::fetch_assess(yr, use_cache = TRUE)

    for (col in expected_cols) {
      expect_true(col %in% names(assess),
                  info = paste("Missing column", col, "in year", yr))
    }
  }
})


# ==============================================================================
# End of Test File
# ==============================================================================
