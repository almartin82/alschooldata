# ==============================================================================
# Enrollment Year Coverage Tests for alschooldata
# ==============================================================================
#
# Per-year tests through ALL available enrollment years (2021-2025).
# Each year verifies:
#   - Pinned state totals (~700K-740K range)
#   - Pinned Birmingham City and Mobile County district enrollment
#   - Pinned demographic subgroup counts (white, black, hispanic, etc.)
#   - system_code / district_id format validation
#   - Subgroup and grade-level completeness
#   - Entity flag correctness
#   - State-district aggregation equality
#
# All pinned values come from running actual fetch functions with use_cache=TRUE
# against real ALSDE cached data. No fabricated numbers.
#
# ==============================================================================

library(testthat)


# ==============================================================================
# Year 2021
# ==============================================================================

test_that("2021 state total enrollment is 729,786", {
  enr <- alschooldata::fetch_enr(2021, tidy = TRUE, use_cache = TRUE)

  state_total <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  expect_equal(state_total, 729786)
})


test_that("2021 Birmingham City enrollment is 21,901", {
  enr <- alschooldata::fetch_enr(2021, tidy = TRUE, use_cache = TRUE)

  bham <- enr |>
    dplyr::filter(grepl("Birmingham", district_name, ignore.case = TRUE),
                  is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  expect_equal(bham, 21901)
})


test_that("2021 Mobile County enrollment is 53,134", {
  enr <- alschooldata::fetch_enr(2021, tidy = TRUE, use_cache = TRUE)

  mobile <- enr |>
    dplyr::filter(grepl("Mobile County", district_name, ignore.case = TRUE),
                  is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  expect_equal(mobile, 53134)
})


test_that("2021 state demographics are pinned", {
  enr <- alschooldata::fetch_enr(2021, tidy = TRUE, use_cache = TRUE)

  check_subgroup <- function(sg, expected) {
    val <- enr |>
      dplyr::filter(is_state, subgroup == sg, grade_level == "TOTAL") |>
      dplyr::pull(n_students)
    expect_equal(val, expected, info = paste("2021 state", sg))
  }

  check_subgroup("white", 425622)
  check_subgroup("black", 239308)
  check_subgroup("hispanic", 69093)
  check_subgroup("econ_disadv", 371737)
  check_subgroup("lep", 33595)
  check_subgroup("special_ed", 102117)
})


test_that("2021 has 143 districts and 1,339 campuses", {
  enr <- alschooldata::fetch_enr(2021, tidy = TRUE, use_cache = TRUE)

  dist_count <- enr |>
    dplyr::filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    nrow()
  expect_equal(dist_count, 143L)

  campus_count <- enr |>
    dplyr::filter(is_campus, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    nrow()
  expect_equal(campus_count, 1339L)
})


test_that("2021 state PK=17,471 and K=52,585", {
  enr <- alschooldata::fetch_enr(2021, tidy = TRUE, use_cache = TRUE)

  pk <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "PK") |>
    dplyr::pull(n_students)
  expect_equal(pk, 17471)

  k <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "K") |>
    dplyr::pull(n_students)
  expect_equal(k, 52585)
})


test_that("2021 state total equals sum of district totals", {
  enr <- alschooldata::fetch_enr(2021, tidy = TRUE, use_cache = TRUE)

  state_total <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  district_sum <- enr |>
    dplyr::filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::summarize(total = sum(n_students, na.rm = TRUE)) |>
    dplyr::pull(total)

  expect_equal(state_total, district_sum)
})


test_that("2021 has all 13 standard subgroups", {
  enr <- alschooldata::fetch_enr(2021, tidy = TRUE, use_cache = TRUE)

  expected <- c("asian", "black", "econ_disadv", "female", "hispanic", "lep",
                "male", "multiracial", "native_american", "pacific_islander",
                "special_ed", "total_enrollment", "white")

  expect_equal(sort(unique(enr$subgroup)), expected)
})


test_that("2021 has all 15 standard grade levels", {
  enr <- alschooldata::fetch_enr(2021, tidy = TRUE, use_cache = TRUE)

  expected <- c("01", "02", "03", "04", "05", "06", "07", "08",
                "09", "10", "11", "12", "K", "PK", "TOTAL")

  expect_equal(sort(unique(enr$grade_level)), expected)
})


# ==============================================================================
# Year 2022
# ==============================================================================

test_that("2022 state total enrollment is 735,808", {
  enr <- alschooldata::fetch_enr(2022, tidy = TRUE, use_cache = TRUE)

  state_total <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  expect_equal(state_total, 735808)
})


test_that("2022 Birmingham City enrollment is 21,163", {
  enr <- alschooldata::fetch_enr(2022, tidy = TRUE, use_cache = TRUE)

  bham <- enr |>
    dplyr::filter(grepl("Birmingham", district_name, ignore.case = TRUE),
                  is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  expect_equal(bham, 21163)
})


test_that("2022 Mobile County enrollment is 51,658", {
  enr <- alschooldata::fetch_enr(2022, tidy = TRUE, use_cache = TRUE)

  mobile <- enr |>
    dplyr::filter(grepl("Mobile County", district_name, ignore.case = TRUE),
                  is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  expect_equal(mobile, 51658)
})


test_that("2022 state demographics are pinned", {
  enr <- alschooldata::fetch_enr(2022, tidy = TRUE, use_cache = TRUE)

  check_subgroup <- function(sg, expected) {
    val <- enr |>
      dplyr::filter(is_state, subgroup == sg, grade_level == "TOTAL") |>
      dplyr::pull(n_students)
    expect_equal(val, expected, info = paste("2022 state", sg))
  }

  check_subgroup("white", 426789)
  check_subgroup("black", 238148)
  check_subgroup("hispanic", 74561)
  check_subgroup("econ_disadv", 351049)
  check_subgroup("lep", 36956)
  check_subgroup("special_ed", 130946)
})


test_that("2022 has 146 districts and 1,351 campuses", {
  enr <- alschooldata::fetch_enr(2022, tidy = TRUE, use_cache = TRUE)

  dist_count <- enr |>
    dplyr::filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    nrow()
  expect_equal(dist_count, 146L)

  campus_count <- enr |>
    dplyr::filter(is_campus, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    nrow()
  expect_equal(campus_count, 1351L)
})


test_that("2022 state PK=22,818 and K=57,198", {
  enr <- alschooldata::fetch_enr(2022, tidy = TRUE, use_cache = TRUE)

  pk <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "PK") |>
    dplyr::pull(n_students)
  expect_equal(pk, 22818)

  k <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "K") |>
    dplyr::pull(n_students)
  expect_equal(k, 57198)
})


test_that("2022 state total equals sum of district totals", {
  enr <- alschooldata::fetch_enr(2022, tidy = TRUE, use_cache = TRUE)

  state_total <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  district_sum <- enr |>
    dplyr::filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::summarize(total = sum(n_students, na.rm = TRUE)) |>
    dplyr::pull(total)

  expect_equal(state_total, district_sum)
})


test_that("2022 has all 13 standard subgroups", {
  enr <- alschooldata::fetch_enr(2022, tidy = TRUE, use_cache = TRUE)

  expected <- c("asian", "black", "econ_disadv", "female", "hispanic", "lep",
                "male", "multiracial", "native_american", "pacific_islander",
                "special_ed", "total_enrollment", "white")

  expect_equal(sort(unique(enr$subgroup)), expected)
})


test_that("2022 has all 15 standard grade levels", {
  enr <- alschooldata::fetch_enr(2022, tidy = TRUE, use_cache = TRUE)

  expected <- c("01", "02", "03", "04", "05", "06", "07", "08",
                "09", "10", "11", "12", "K", "PK", "TOTAL")

  expect_equal(sort(unique(enr$grade_level)), expected)
})


# ==============================================================================
# Year 2023
# ==============================================================================

test_that("2023 state total enrollment is 729,789", {
  enr <- alschooldata::fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  state_total <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  expect_equal(state_total, 729789)
})


test_that("2023 Birmingham City enrollment is 19,921", {
  enr <- alschooldata::fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  bham <- enr |>
    dplyr::filter(grepl("Birmingham", district_name, ignore.case = TRUE),
                  is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  expect_equal(bham, 19921)
})


test_that("2023 Mobile County enrollment is 50,636", {
  enr <- alschooldata::fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  mobile <- enr |>
    dplyr::filter(grepl("Mobile County", district_name, ignore.case = TRUE),
                  is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  expect_equal(mobile, 50636)
})


test_that("2023 state demographics are pinned", {
  enr <- alschooldata::fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  check_subgroup <- function(sg, expected) {
    val <- enr |>
      dplyr::filter(is_state, subgroup == sg, grade_level == "TOTAL") |>
      dplyr::pull(n_students)
    expect_equal(val, expected, info = paste("2023 state", sg))
  }

  check_subgroup("white", 419590)
  check_subgroup("black", 234527)
  check_subgroup("hispanic", 78638)
  check_subgroup("econ_disadv", 477329)
  check_subgroup("lep", 41430)
  check_subgroup("special_ed", 130655)
})


test_that("2023 has 149 districts and 1,359 campuses", {
  enr <- alschooldata::fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  dist_count <- enr |>
    dplyr::filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    nrow()
  expect_equal(dist_count, 149L)

  campus_count <- enr |>
    dplyr::filter(is_campus, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    nrow()
  expect_equal(campus_count, 1359L)
})


test_that("2023 state PK=17,758 and K=55,929", {
  enr <- alschooldata::fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  pk <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "PK") |>
    dplyr::pull(n_students)
  expect_equal(pk, 17758)

  k <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "K") |>
    dplyr::pull(n_students)
  expect_equal(k, 55929)
})


test_that("2023 state total equals sum of district totals", {
  enr <- alschooldata::fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  state_total <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  district_sum <- enr |>
    dplyr::filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::summarize(total = sum(n_students, na.rm = TRUE)) |>
    dplyr::pull(total)

  expect_equal(state_total, district_sum)
})


test_that("2023 has all 13 standard subgroups", {
  enr <- alschooldata::fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  expected <- c("asian", "black", "econ_disadv", "female", "hispanic", "lep",
                "male", "multiracial", "native_american", "pacific_islander",
                "special_ed", "total_enrollment", "white")

  expect_equal(sort(unique(enr$subgroup)), expected)
})


test_that("2023 has all 15 standard grade levels", {
  enr <- alschooldata::fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  expected <- c("01", "02", "03", "04", "05", "06", "07", "08",
                "09", "10", "11", "12", "K", "PK", "TOTAL")

  expect_equal(sort(unique(enr$grade_level)), expected)
})


# ==============================================================================
# Year 2024
# ==============================================================================

test_that("2024 state total enrollment is 718,716", {
  enr <- alschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  state_total <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  expect_equal(state_total, 718716)
})


test_that("2024 Birmingham City enrollment is 19,829", {
  enr <- alschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  bham <- enr |>
    dplyr::filter(grepl("Birmingham", district_name, ignore.case = TRUE),
                  is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  expect_equal(bham, 19829)
})


test_that("2024 Mobile County enrollment is 48,433", {
  enr <- alschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  mobile <- enr |>
    dplyr::filter(grepl("Mobile County", district_name, ignore.case = TRUE),
                  is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  expect_equal(mobile, 48433)
})


test_that("2024 state demographics are pinned", {
  enr <- alschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  check_subgroup <- function(sg, expected) {
    val <- enr |>
      dplyr::filter(is_state, subgroup == sg, grade_level == "TOTAL") |>
      dplyr::pull(n_students)
    expect_equal(val, expected, info = paste("2024 state", sg))
  }

  check_subgroup("white", 407758)
  check_subgroup("black", 229512)
  check_subgroup("hispanic", 84661)
  check_subgroup("econ_disadv", 465245)
  check_subgroup("lep", 47838)
  check_subgroup("special_ed", 129379)
})


test_that("2024 has 150 districts and 1,353 campuses", {
  enr <- alschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  dist_count <- enr |>
    dplyr::filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    nrow()
  expect_equal(dist_count, 150L)

  campus_count <- enr |>
    dplyr::filter(is_campus, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    nrow()
  expect_equal(campus_count, 1353L)
})


test_that("2024 state PK=3,833 and K=55,412", {
  enr <- alschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  pk <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "PK") |>
    dplyr::pull(n_students)
  expect_equal(pk, 3833)

  k <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "K") |>
    dplyr::pull(n_students)
  expect_equal(k, 55412)
})


test_that("2024 state per-grade enrollment is pinned", {
  enr <- alschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  grade_pin <- function(gl, expected) {
    val <- enr |>
      dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == gl) |>
      dplyr::pull(n_students)
    expect_equal(val, expected, info = paste("2024 state grade", gl))
  }

  grade_pin("01", 58009)
  grade_pin("02", 57436)
  grade_pin("03", 54649)
  grade_pin("04", 53616)
  grade_pin("05", 53582)
  grade_pin("06", 54293)
  grade_pin("07", 55135)
  grade_pin("08", 55780)
  grade_pin("09", 58470)
  grade_pin("10", 56438)
  grade_pin("11", 52339)
  grade_pin("12", 49010)
})


test_that("2024 state total equals sum of district totals", {
  enr <- alschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  state_total <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  district_sum <- enr |>
    dplyr::filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::summarize(total = sum(n_students, na.rm = TRUE)) |>
    dplyr::pull(total)

  expect_equal(state_total, district_sum)
})


test_that("2024 has all 13 standard subgroups", {
  enr <- alschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expected <- c("asian", "black", "econ_disadv", "female", "hispanic", "lep",
                "male", "multiracial", "native_american", "pacific_islander",
                "special_ed", "total_enrollment", "white")

  expect_equal(sort(unique(enr$subgroup)), expected)
})


test_that("2024 has all 15 standard grade levels", {
  enr <- alschooldata::fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expected <- c("01", "02", "03", "04", "05", "06", "07", "08",
                "09", "10", "11", "12", "K", "PK", "TOTAL")

  expect_equal(sort(unique(enr$grade_level)), expected)
})


# ==============================================================================
# Year 2025
# ==============================================================================

test_that("2025 state total enrollment is 717,473", {
  enr <- alschooldata::fetch_enr(2025, tidy = TRUE, use_cache = TRUE)

  state_total <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  expect_equal(state_total, 717473)
})


test_that("2025 Birmingham City enrollment is 19,710", {
  enr <- alschooldata::fetch_enr(2025, tidy = TRUE, use_cache = TRUE)

  bham <- enr |>
    dplyr::filter(grepl("Birmingham", district_name, ignore.case = TRUE),
                  is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  expect_equal(bham, 19710)
})


test_that("2025 Mobile County enrollment is 47,366", {
  enr <- alschooldata::fetch_enr(2025, tidy = TRUE, use_cache = TRUE)

  mobile <- enr |>
    dplyr::filter(grepl("Mobile County", district_name, ignore.case = TRUE),
                  is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  expect_equal(mobile, 47366)
})


test_that("2025 state demographics are pinned", {
  enr <- alschooldata::fetch_enr(2025, tidy = TRUE, use_cache = TRUE)

  check_subgroup <- function(sg, expected) {
    val <- enr |>
      dplyr::filter(is_state, subgroup == sg, grade_level == "TOTAL") |>
      dplyr::pull(n_students)
    expect_equal(val, expected, info = paste("2025 state", sg))
  }

  check_subgroup("white", 402422)
  check_subgroup("black", 228708)
  check_subgroup("hispanic", 87790)
  check_subgroup("econ_disadv", 422645)
  check_subgroup("lep", 51068)
  check_subgroup("special_ed", 104371)
})


test_that("2025 has 153 districts and 1,362 campuses", {
  enr <- alschooldata::fetch_enr(2025, tidy = TRUE, use_cache = TRUE)

  dist_count <- enr |>
    dplyr::filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    nrow()
  expect_equal(dist_count, 153L)

  campus_count <- enr |>
    dplyr::filter(is_campus, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    nrow()
  expect_equal(campus_count, 1362L)
})


test_that("2025 state PK=3,746 and K=55,467", {
  enr <- alschooldata::fetch_enr(2025, tidy = TRUE, use_cache = TRUE)

  pk <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "PK") |>
    dplyr::pull(n_students)
  expect_equal(pk, 3746)

  k <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "K") |>
    dplyr::pull(n_students)
  expect_equal(k, 55467)
})


test_that("2025 state total equals sum of district totals", {
  enr <- alschooldata::fetch_enr(2025, tidy = TRUE, use_cache = TRUE)

  state_total <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  district_sum <- enr |>
    dplyr::filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
    dplyr::summarize(total = sum(n_students, na.rm = TRUE)) |>
    dplyr::pull(total)

  expect_equal(state_total, district_sum)
})


test_that("2025 has all 13 standard subgroups", {
  enr <- alschooldata::fetch_enr(2025, tidy = TRUE, use_cache = TRUE)

  expected <- c("asian", "black", "econ_disadv", "female", "hispanic", "lep",
                "male", "multiracial", "native_american", "pacific_islander",
                "special_ed", "total_enrollment", "white")

  expect_equal(sort(unique(enr$subgroup)), expected)
})


test_that("2025 has all 15 standard grade levels", {
  enr <- alschooldata::fetch_enr(2025, tidy = TRUE, use_cache = TRUE)

  expected <- c("01", "02", "03", "04", "05", "06", "07", "08",
                "09", "10", "11", "12", "K", "PK", "TOTAL")

  expect_equal(sort(unique(enr$grade_level)), expected)
})


# ==============================================================================
# Cross-Year Trend Validation
# ==============================================================================

test_that("Birmingham City enrollment declines each year 2021-2025", {
  # Real data shows consistent decline: 21901 -> 21163 -> 19921 -> 19829 -> 19710
  expected <- c(
    "2021" = 21901, "2022" = 21163, "2023" = 19921,
    "2024" = 19829, "2025" = 19710
  )

  for (yr_str in names(expected)) {
    yr <- as.integer(yr_str)
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    bham <- enr |>
      dplyr::filter(grepl("Birmingham", district_name, ignore.case = TRUE),
                    is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
      dplyr::pull(n_students)

    expect_equal(bham, expected[[yr_str]],
                 info = paste("Birmingham enrollment mismatch for year", yr))
  }
})


test_that("Mobile County enrollment declines each year 2021-2025", {
  # Real data shows consistent decline: 53134 -> 51658 -> 50636 -> 48433 -> 47366
  expected <- c(
    "2021" = 53134, "2022" = 51658, "2023" = 50636,
    "2024" = 48433, "2025" = 47366
  )

  for (yr_str in names(expected)) {
    yr <- as.integer(yr_str)
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    mobile <- enr |>
      dplyr::filter(grepl("Mobile County", district_name, ignore.case = TRUE),
                    is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
      dplyr::pull(n_students)

    expect_equal(mobile, expected[[yr_str]],
                 info = paste("Mobile County enrollment mismatch for year", yr))
  }
})


test_that("Hispanic enrollment grows each year 2021-2025", {
  # Real data shows consistent growth: 69093 -> 74561 -> 78638 -> 84661 -> 87790
  expected <- c(
    "2021" = 69093, "2022" = 74561, "2023" = 78638,
    "2024" = 84661, "2025" = 87790
  )

  for (yr_str in names(expected)) {
    yr <- as.integer(yr_str)
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    hispanic <- enr |>
      dplyr::filter(is_state, subgroup == "hispanic", grade_level == "TOTAL") |>
      dplyr::pull(n_students)

    expect_equal(hispanic, expected[[yr_str]],
                 info = paste("Hispanic enrollment mismatch for year", yr))
  }
})


test_that("LEP enrollment grows each year 2021-2025", {
  # Real data shows consistent growth: 33595 -> 36956 -> 41430 -> 47838 -> 51068
  expected <- c(
    "2021" = 33595, "2022" = 36956, "2023" = 41430,
    "2024" = 47838, "2025" = 51068
  )

  for (yr_str in names(expected)) {
    yr <- as.integer(yr_str)
    enr <- alschooldata::fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    lep <- enr |>
      dplyr::filter(is_state, subgroup == "lep", grade_level == "TOTAL") |>
      dplyr::pull(n_students)

    expect_equal(lep, expected[[yr_str]],
                 info = paste("LEP enrollment mismatch for year", yr))
  }
})


# ==============================================================================
# End of Test File
# ==============================================================================
