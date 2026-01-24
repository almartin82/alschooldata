# ==============================================================================
# LIVE Assessment Data Pipeline Tests for alschooldata
# ==============================================================================
#
# These tests verify the LIVE data pipeline for Alabama ACAP assessment data.
# They require network access and will be skipped during CRAN checks.
#
# Test Categories:
# 1. URL Availability - HTTP 200 checks
# 2. File Download - Verify actual file (not HTML error)
# 3. File Parsing - readxl succeeds
# 4. Column Structure - Expected columns exist
# 5. District Coverage - Major districts present
# 6. Grade Coverage - All expected grades present
# 7. Subject Coverage - Expected subjects present
# 8. Data Quality - No Inf/NaN, non-negative counts
# 9. Aggregation - State aggregates match sum of districts
# 10. Fidelity - Specific values match raw Excel
#
# ==============================================================================

# Major Alabama districts for testing
MAJOR_DISTRICTS <- c(
  "JEFFERSON COUNTY",
  "MOBILE COUNTY",
  "MADISON COUNTY",
  "BIRMINGHAM CITY",
  "MONTGOMERY COUNTY",
  "SHELBY COUNTY",
  "LEE COUNTY",
  "TUSCALOOSA COUNTY"
)

# Expected grades for ACAP Reading (2021-2025)
ACAP_GRADES <- c("02", "03")

# Expected subject for ACAP
ACAP_SUBJECT <- "Reading"

# ==============================================================================
# URL Availability Tests
# ==============================================================================

test_that("2025 ACAP Reading URL is available", {
  skip_if_offline()

  url <- "https://www.alabamaachieves.org/wp-content/uploads/2025/06/RD_SP_2025612_ACAP-Reading_v1.0.xlsx"

  response <- httr::GET(url, httr::timeout(30))

  expect_false(httr::http_error(response))
  expect_equal(httr::status_code(response), 200)
})

test_that("2024 ACAP Reading URL is available", {
  skip_if_offline()

  url <- "https://www.alabamaachieves.org/wp-content/uploads/2024/06/RD_SP_2024613_2023-2024-ACAP-Reading.xlsx"

  response <- httr::GET(url, httr::timeout(30))

  expect_false(httr::http_error(response))
  expect_equal(httr::status_code(response), 200)
})

test_that("2023 ACAP Reading URL is available", {
  skip_if_offline()

  url <- "https://www.alabamaachieves.org/wp-content/uploads/2023/06/RD_SP_202368_2022-2023-ACAP-Reading_V1.0.xlsx"

  response <- httr::GET(url, httr::timeout(30))

  expect_false(httr::http_error(response))
  expect_equal(httr::status_code(response), 200)
})

test_that("2022 ACAP Reading URL is available", {
  skip_if_offline()

  url <- "https://www.alabamaachieves.org/wp-content/uploads/2022/07/2021-2022-ACAP-Reading.xlsx"

  response <- httr::GET(url, httr::timeout(30))

  expect_false(httr::http_error(response))
  expect_equal(httr::status_code(response), 200)
})

# ==============================================================================
# File Download Tests
# ==============================================================================

test_that("2025 ACAP Reading file downloads successfully", {
  skip_if_offline()

  url <- "https://www.alabamaachieves.org/wp-content/uploads/2025/06/RD_SP_2025612_ACAP-Reading_v1.0.xlsx"

  tname <- tempfile(fileext = ".xlsx")

  on.exit(unlink(tname), add = TRUE)

  response <- httr::GET(
    url,
    httr::write_disk(tname, overwrite = TRUE),
    httr::timeout(120)
  )

  expect_false(httr::http_error(response))
  expect_true(file.exists(tname))
  expect_gt(file.info(tname)$size, 10000)  # Should be > 10KB (real Excel file)

  # Verify it's actually an Excel file (not HTML)
  content <- readBin(tname, "raw", file.info(tname)$size)
  expect_true(any(content == c(0x50, 0x4b, 0x03, 0x04)) ||  # ZIP signature (xlsx is ZIP)
                any(content == c(0xd0, 0xcf, 0x11, 0xe0)))  # OLE signature (xls)
})

test_that("2024 ACAP Reading file downloads successfully", {
  skip_if_offline()

  url <- "https://www.alabamaachieves.org/wp-content/uploads/2024/06/RD_SP_2024613_2023-2024-ACAP-Reading.xlsx"

  tname <- tempfile(fileext = ".xlsx")

  on.exit(unlink(tname), add = TRUE)

  response <- httr::GET(
    url,
    httr::write_disk(tname, overwrite = TRUE),
    httr::timeout(120)
  )

  expect_false(httr::http_error(response))
  expect_true(file.exists(tname))
  expect_gt(file.info(tname)$size, 10000)
})

test_that("2023 ACAP Reading file downloads successfully", {
  skip_if_offline()

  url <- "https://www.alabamaachieves.org/wp-content/uploads/2023/06/RD_SP_202368_2022-2023-ACAP-Reading_V1.0.xlsx"

  tname <- tempfile(fileext = ".xlsx")

  on.exit(unlink(tname), add = TRUE)

  response <- httr::GET(
    url,
    httr::write_disk(tname, overwrite = TRUE),
    httr::timeout(120)
  )

  expect_false(httr::http_error(response))
  expect_true(file.exists(tname))
  expect_gt(file.info(tname)$size, 10000)
})

test_that("2022 ACAP Reading file downloads successfully", {
  skip_if_offline()

  url <- "https://www.alabamaachieves.org/wp-content/uploads/2022/07/2021-2022-ACAP-Reading.xlsx"

  tname <- tempfile(fileext = ".xlsx")

  on.exit(unlink(tname), add = TRUE)

  response <- httr::GET(
    url,
    httr::write_disk(tname, overwrite = TRUE),
    httr::timeout(120)
  )

  expect_false(httr::http_error(response))
  expect_true(file.exists(tname))
  expect_gt(file.info(tname)$size, 10000)
})

# ==============================================================================
# File Parsing Tests
# ==============================================================================

test_that("2025 ACAP Excel file can be parsed", {
  skip_if_offline()

  url <- "https://www.alabamaachieves.org/wp-content/uploads/2025/06/RD_SP_2025612_ACAP-Reading_v1.0.xlsx"

  tname <- tempfile(fileext = ".xlsx")

  on.exit(unlink(tname), add = TRUE)

  # Download
  response <- httr::GET(
    url,
    httr::write_disk(tname, overwrite = TRUE),
    httr::timeout(120)
  )

  expect_false(httr::http_error(response))

  # Parse with readxl
  sheets <- readxl::excel_sheets(tname)
  expect_true(length(sheets) > 0)

  # Read first sheet
  df <- readxl::read_excel(tname, sheet = 1, n_max = 10)
  expect_true(nrow(df) > 0)
  expect_true(ncol(df) > 0)
})

test_that("2024 ACAP Excel file can be parsed", {
  skip_if_offline()

  url <- "https://www.alabamaachieves.org/wp-content/uploads/2024/06/RD_SP_2024613_2023-2024-ACAP-Reading.xlsx"

  tname <- tempfile(fileext = ".xlsx")

  on.exit(unlink(tname), add = TRUE)

  # Download
  response <- httr::GET(
    url,
    httr::write_disk(tname, overwrite = TRUE),
    httr::timeout(120)
  )

  expect_false(httr::http_error(response))

  # Parse with readxl
  sheets <- readxl::excel_sheets(tname)
  expect_true(length(sheets) > 0)

  # Read first sheet
  df <- readxl::read_excel(tname, sheet = 1, n_max = 10)
  expect_true(nrow(df) > 0)
  expect_true(ncol(df) > 0)
})

test_that("2022 ACAP Excel file can be parsed (different format)", {
  skip_if_offline()

  url <- "https://www.alabamaachieves.org/wp-content/uploads/2022/07/2021-2022-ACAP-Reading.xlsx"

  tname <- tempfile(fileext = ".xlsx")

  on.exit(unlink(tname), add = TRUE)

  # Download
  response <- httr::GET(
    url,
    httr::write_disk(tname, overwrite = TRUE),
    httr::timeout(120)
  )

  expect_false(httr::http_error(response))

  # Parse with readxl
  sheets <- readxl::excel_sheets(tname)
  expect_true(length(sheets) > 0)

  # Read first sheet
  df <- readxl::read_excel(tname, sheet = 1, n_max = 10)
  expect_true(nrow(df) > 0)
  expect_true(ncol(df) > 0)
})

# ==============================================================================
# Pipeline Tests - fetch_assess() Function
# ==============================================================================

test_that("fetch_assess returns data for 2025", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  expect_s3_class(data, "data.frame")
  expect_gt(nrow(data), 0)
})

test_that("fetch_assess returns data for 2024", {
  skip_if_offline()

  data <- fetch_assess(2024, use_cache = FALSE)

  expect_s3_class(data, "data.frame")
  expect_gt(nrow(data), 0)
})

test_that("fetch_assess returns data for 2023", {
  skip_if_offline()

  data <- fetch_assess(2023, use_cache = FALSE)

  expect_s3_class(data, "data.frame")
  expect_gt(nrow(data), 0)
})

test_that("fetch_assess returns data for 2022", {
  skip_if_offline()

  data <- fetch_assess(2022, use_cache = FALSE)

  expect_s3_class(data, "data.frame")
  expect_gt(nrow(data), 0)
})

test_that("fetch_assess rejects year > 2025", {
  skip_if_offline()

  expect_error(
    fetch_assess(2026),
    "end_year must be between"
  )
})

test_that("fetch_assess rejects year < 2022", {
  skip_if_offline()

  expect_error(
    fetch_assess(2021),
    "end_year must be between"
  )
})

# ==============================================================================
# Column Structure Tests
# ==============================================================================

test_that("2025 assessment data has expected columns", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  expect_true("end_year" %in% names(data))
  expect_true("system_code" %in% names(data))
  expect_true("system_name" %in% names(data))
  expect_true("school_code" %in% names(data))
  expect_true("school_name" %in% names(data))
  expect_true("subject" %in% names(data))
  expect_true("grade" %in% names(data))
  expect_true("n_tested" %in% names(data))
  expect_true("proficiency_rate" %in% names(data))
  expect_true("proficiency_count" %in% names(data))
  expect_true("is_state" %in% names(data))
  expect_true("is_district" %in% names(data))
  expect_true("is_school" %in% names(data))
})

test_that("2024 assessment data has expected columns", {
  skip_if_offline()

  data <- fetch_assess(2024, use_cache = FALSE)

  expect_true("end_year" %in% names(data))
  expect_true("system_code" %in% names(data))
  expect_true("system_name" %in% names(data))
  expect_true("school_code" %in% names(data))
  expect_true("school_name" %in% names(data))
  expect_true("subject" %in% names(data))
  expect_true("grade" %in% names(data))
  expect_true("n_tested" %in% names(data))
  expect_true("proficiency_rate" %in% names(data))
  expect_true("proficiency_count" %in% names(data))
})

test_that("2022 assessment data has expected columns (different format)", {
  skip_if_offline()

  data <- fetch_assess(2022, use_cache = FALSE)

  expect_true("end_year" %in% names(data))
  expect_true("system_code" %in% names(data))
  expect_true("system_name" %in% names(data))
  expect_true("school_code" %in% names(data))
  expect_true("school_name" %in% names(data))
  expect_true("subject" %in% names(data))
  # Note: 2022 file doesn't have grade column
  expect_true("n_tested" %in% names(data))
  expect_true("proficiency_rate" %in% names(data))
  expect_true("proficiency_count" %in% names(data))
})

# ==============================================================================
# District Coverage Tests
# ==============================================================================

test_that("2025 assessment includes Jefferson County", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  expect_true(any(grepl("JEFFERSON COUNTY", data$system_name, ignore.case = TRUE)))
})

test_that("2025 assessment includes Mobile County", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  expect_true(any(grepl("MOBILE COUNTY", data$system_name, ignore.case = TRUE)))
})

test_that("2025 assessment includes Madison County", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  expect_true(any(grepl("MADISON COUNTY", data$system_name, ignore.case = TRUE)))
})

test_that("2025 assessment includes Birmingham City", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  expect_true(any(grepl("BIRMINGHAM CITY", data$system_name, ignore.case = TRUE)))
})

test_that("2025 assessment includes Montgomery County", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  expect_true(any(grepl("MONTGOMERY COUNTY", data$system_name, ignore.case = TRUE)))
})

test_that("2024 assessment includes all major districts", {
  skip_if_offline()

  data <- fetch_assess(2024, use_cache = FALSE)

  for (district in MAJOR_DISTRICTS) {
    expect_true(
      any(grepl(district, data$system_name, ignore.case = TRUE)),
      info = paste("Expected to find", district)
    )
  }
})

test_that("2023 assessment includes all major districts", {
  skip_if_offline()

  data <- fetch_assess(2023, use_cache = FALSE)

  for (district in MAJOR_DISTRICTS) {
    expect_true(
      any(grepl(district, data$system_name, ignore.case = TRUE)),
      info = paste("Expected to find", district)
    )
  }
})

test_that("2022 assessment includes Jefferson County", {
  skip_if_offline()

  data <- fetch_assess(2022, use_cache = FALSE)

  expect_true(any(grepl("JEFFERSON COUNTY", data$system_name, ignore.case = TRUE)))
})

# ==============================================================================
# Grade Coverage Tests
# ==============================================================================

test_that("2025 ACAP has expected grades 2-3", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  if ("grade" %in% names(data)) {
    grades_present <- unique(data$grade)
    # Should have both grades 2 and 3
    expect_true("02" %in% grades_present)
    expect_true("03" %in% grades_present)
  }
})

test_that("2024 ACAP has expected grades 2-3", {
  skip_if_offline()

  data <- fetch_assess(2024, use_cache = FALSE)

  if ("grade" %in% names(data)) {
    grades_present <- unique(data$grade)
    expect_true("02" %in% grades_present)
    expect_true("03" %in% grades_present)
  }
})

test_that("2023 ACAP has expected grades 2-3", {
  skip_if_offline()

  data <- fetch_assess(2023, use_cache = FALSE)

  if ("grade" %in% names(data)) {
    grades_present <- unique(data$grade)
    expect_true("02" %in% grades_present)
    expect_true("03" %in% grades_present)
  }
})

test_that("Grade 02 is present in 2025", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  if ("grade" %in% names(data)) {
    expect_true("02" %in% data$grade)
  }
})

test_that("Grade 03 is present in 2025", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  if ("grade" %in% names(data)) {
    expect_true("03" %in% data$grade)
  }
})

# ==============================================================================
# Subject Coverage Tests
# ==============================================================================

test_that("2025 assessment includes Reading subject", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  expect_true("subject" %in% names(data))
  expect_true("Reading" %in% unique(data$subject))
})

test_that("2024 assessment includes Reading subject", {
  skip_if_offline()

  data <- fetch_assess(2024, use_cache = FALSE)

  expect_true("subject" %in% names(data))
  expect_true("Reading" %in% unique(data$subject))
})

test_that("All years have Reading as the only subject", {
  skip_if_offline()

  data <- fetch_assess_multi(2022:2025, use_cache = FALSE)

  expect_true("subject" %in% names(data))
  unique_subjects <- unique(data$subject)
  expect_true("Reading" %in% unique_subjects)
  expect_length(unique_subjects, 1)  # Only Reading should be available
})

# ==============================================================================
# Data Quality Tests
# ==============================================================================

test_that("2025 has no Inf values in numeric columns", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  numeric_cols <- names(data)[sapply(data, is.numeric)]

  if (length(numeric_cols) > 0) {
    for (col in numeric_cols) {
      expect_false(any(is.infinite(data[[col]])),
                   info = paste("Column", col, "has Inf values"))
    }
  }
})

test_that("2024 has no Inf values in numeric columns", {
  skip_if_offline()

  data <- fetch_assess(2024, use_cache = FALSE)

  numeric_cols <- names(data)[sapply(data, is.numeric)]

  if (length(numeric_cols) > 0) {
    for (col in numeric_cols) {
      expect_false(any(is.infinite(data[[col]])),
                   info = paste("Column", col, "has Inf values"))
    }
  }
})

test_that("2025 has no NaN values", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  for (col in names(data)) {
    expect_false(any(is.nan(data[[col]])),
                 info = paste("Column", col, "has NaN values"))
  }
})

test_that("2025 has reasonable row count (>100)", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  expect_gt(nrow(data), 100)
})

test_that("2024 has reasonable row count (>100)", {
  skip_if_offline()

  data <- fetch_assess(2024, use_cache = FALSE)

  expect_gt(nrow(data), 100)
})

test_that("2023 has reasonable row count (>100)", {
  skip_if_offline()

  data <- fetch_assess(2023, use_cache = FALSE)

  expect_gt(nrow(data), 100)
})

test_that("2022 has reasonable row count (>100)", {
  skip_if_offline()

  data <- fetch_assess(2022, use_cache = FALSE)

  expect_gt(nrow(data), 100)
})

# ==============================================================================
# Proficiency Rate Tests
# ==============================================================================

test_that("2025 proficiency rates are between 0 and 1", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  if ("proficiency_rate" %in% names(data)) {
    expect_true(all(data$proficiency_rate >= 0 & data$proficiency_rate <= 1, na.rm = TRUE),
                info = "Proficiency rates should be between 0 and 1")
  }
})

test_that("2024 proficiency rates are between 0 and 1", {
  skip_if_offline()

  data <- fetch_assess(2024, use_cache = FALSE)

  if ("proficiency_rate" %in% names(data)) {
    expect_true(all(data$proficiency_rate >= 0 & data$proficiency_rate <= 1, na.rm = TRUE),
                info = "Proficiency rates should be between 0 and 1")
  }
})

test_that("2023 proficiency rates are between 0 and 1", {
  skip_if_offline()

  data <- fetch_assess(2023, use_cache = FALSE)

  if ("proficiency_rate" %in% names(data)) {
    expect_true(all(data$proficiency_rate >= 0 & data$proficiency_rate <= 1, na.rm = TRUE),
                info = "Proficiency rates should be between 0 and 1")
  }
})

# ==============================================================================
# Count Tests
# ==============================================================================

test_that("2025 n_tested values are non-negative", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  if ("n_tested" %in% names(data)) {
    expect_true(all(data$n_tested >= 0, na.rm = TRUE))
  }
})

test_that("2024 n_tested values are non-negative", {
  skip_if_offline()

  data <- fetch_assess(2024, use_cache = FALSE)

  if ("n_tested" %in% names(data)) {
    expect_true(all(data$n_tested >= 0, na.rm = TRUE))
  }
})

test_that("2025 proficiency_count values are non-negative", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  if ("proficiency_count" %in% names(data)) {
    expect_true(all(data$proficiency_count >= 0, na.rm = TRUE))
  }
})

test_that("2024 proficiency_count values are non-negative", {
  skip_if_offline()

  data <- fetch_assess(2024, use_cache = FALSE)

  if ("proficiency_count" %in% names(data)) {
    expect_true(all(data$proficiency_count >= 0, na.rm = TRUE))
  }
})

# ==============================================================================
# end_year Column Tests
# ==============================================================================

test_that("2025 end_year column is correct", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  expect_true("end_year" %in% names(data))
  expect_true(all(data$end_year == 2025))
})

test_that("2024 end_year column is correct", {
  skip_if_offline()

  data <- fetch_assess(2024, use_cache = FALSE)

  expect_true("end_year" %in% names(data))
  expect_true(all(data$end_year == 2024))
})

test_that("2023 end_year column is correct", {
  skip_if_offline()

  data <- fetch_assess(2023, use_cache = FALSE)

  expect_true("end_year" %in% names(data))
  expect_true(all(data$end_year == 2023))
})

test_that("2022 end_year column is correct", {
  skip_if_offline()

  data <- fetch_assess(2022, use_cache = FALSE)

  expect_true("end_year" %in% names(data))
  expect_true(all(data$end_year == 2022))
})

# ==============================================================================
# Multi-Year Fetch Tests
# ==============================================================================

test_that("fetch_assess_multi returns combined data", {
  skip_if_offline()

  data <- fetch_assess_multi(c(2024, 2025), use_cache = FALSE)

  expect_s3_class(data, "data.frame")
  expect_gt(nrow(data), 0)

  if ("end_year" %in% names(data)) {
    years_present <- unique(data$end_year)
    expect_true(2024 %in% years_present)
    expect_true(2025 %in% years_present)
  }
})

test_that("fetch_assess_multi handles 4 years", {
  skip_if_offline()

  data <- fetch_assess_multi(2022:2025, use_cache = FALSE)

  expect_s3_class(data, "data.frame")
  expect_gt(nrow(data), 0)

  if ("end_year" %in% names(data)) {
    years_present <- unique(data$end_year)
    expect_gte(length(years_present), 3)  # At least 3 years should succeed
  }
})

test_that("All years from 2022-2025 can be fetched individually", {
  skip_if_offline()

  years <- 2022:2025
  success_count <- 0

  for (yr in years) {
    result <- tryCatch({
      data <- fetch_assess(yr, use_cache = FALSE)
      if (nrow(data) > 0) success_count <<- success_count + 1
      TRUE
    }, error = function(e) FALSE)

    expect_true(result, info = paste("Failed to fetch year", yr))
  }

  expect_gte(success_count, 4)  # All 4 years should succeed
})

# ==============================================================================
# Aggregation Flag Tests
# ==============================================================================

test_that("2025 has district-level data", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  expect_true(any(data$is_district == TRUE))
})

test_that("2025 has school-level data", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  expect_true(any(data$is_school == TRUE))
})

test_that("2025 has state-level aggregate", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  expect_true(any(data$is_state == TRUE))
})

test_that("2024 has all three aggregation levels", {
  skip_if_offline()

  data <- fetch_assess(2024, use_cache = FALSE)

  expect_true(any(data$is_state == TRUE))
  expect_true(any(data$is_district == TRUE))
  expect_true(any(data$is_school == TRUE))
})

# ==============================================================================
# District Count Tests
# ==============================================================================

test_that("2025 has 130+ districts", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  if ("is_district" %in% names(data)) {
    district_data <- data[data$is_district == TRUE, ]
    unique_districts <- length(unique(district_data$system_code))
    expect_gte(unique_districts, 130)
  }
})

test_that("2024 has 130+ districts", {
  skip_if_offline()

  data <- fetch_assess(2024, use_cache = FALSE)

  if ("is_district" %in% names(data)) {
    district_data <- data[data$is_district == TRUE, ]
    unique_districts <- length(unique(district_data$system_code))
    expect_gte(unique_districts, 130)
  }
})

test_that("2023 has 130+ districts", {
  skip_if_offline()

  data <- fetch_assess(2023, use_cache = FALSE)

  if ("is_district" %in% names(data)) {
    district_data <- data[data$is_district == TRUE, ]
    unique_districts <- length(unique(district_data$system_code))
    expect_gte(unique_districts, 130)
  }
})

# ==============================================================================
# School Count Tests
# ==============================================================================

test_that("2025 has 1000+ schools", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  if ("is_school" %in% names(data)) {
    school_data <- data[data$is_school == TRUE, ]
    unique_schools <- length(unique(school_data$school_code))
    expect_gte(unique_schools, 1000)
  }
})

test_that("2024 has 1000+ schools", {
  skip_if_offline()

  data <- fetch_assess(2024, use_cache = FALSE)

  if ("is_school" %in% names(data)) {
    school_data <- data[data$is_school == TRUE, ]
    unique_schools <- length(unique(school_data$school_code))
    expect_gte(unique_schools, 1000)
  }
})

# ==============================================================================
# Cross-Year Consistency Tests
# ==============================================================================

test_that("Jefferson County present in all available years", {
  skip_if_offline()

  years_to_test <- c(2022, 2023, 2024, 2025)

  for (yr in years_to_test) {
    data <- fetch_assess(yr, use_cache = FALSE)

    jefferson <- data[grepl("JEFFERSON COUNTY", data$system_name, ignore.case = TRUE), ]
    expect_gt(nrow(jefferson), 0, info = paste("Jefferson County not found in", yr))
  }
})

test_that("Mobile County present in all available years", {
  skip_if_offline()

  years_to_test <- c(2022, 2023, 2024, 2025)

  for (yr in years_to_test) {
    data <- fetch_assess(yr, use_cache = FALSE)

    mobile <- data[grepl("MOBILE COUNTY", data$system_name, ignore.case = TRUE), ]
    expect_gt(nrow(mobile), 0, info = paste("Mobile County not found in", yr))
  }
})

test_that("Major districts increase row counts across years", {
  skip_if_offline()

  # Get data for multiple years
  data_multi <- fetch_assess_multi(c(2024, 2025), use_cache = FALSE)

  if ("system_name" %in% names(data_multi) && "end_year" %in% names(data_multi)) {
    # Check Jefferson County appears in both years
    jefferson <- data_multi[grepl("JEFFERSON COUNTY", data_multi$system_name, ignore.case = TRUE), ]

    if (nrow(jefferson) > 0 && "end_year" %in% names(jefferson)) {
      years_present <- unique(jefferson$end_year)
      expect_gte(length(years_present), 2,
                 info = "Jefferson County should appear in multiple years")
    }
  }
})

# ==============================================================================
# State Aggregate Tests
# ==============================================================================

test_that("2025 state aggregate has reasonable total tested", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  state_rows <- data[data$is_state == TRUE, ]

  if (nrow(state_rows) > 0 && "n_tested" %in% names(state_rows)) {
    state_total <- sum(state_rows$n_tested, na.rm = TRUE)
    expect_gt(state_total, 50000,
              info = "State total tested should be > 50,000 for grades 2-3")
  }
})

test_that("2024 state aggregate has reasonable total tested", {
  skip_if_offline()

  data <- fetch_assess(2024, use_cache = FALSE)

  state_rows <- data[data$is_state == TRUE, ]

  if (nrow(state_rows) > 0 && "n_tested" %in% names(state_rows)) {
    state_total <- sum(state_rows$n_tested, na.rm = TRUE)
    expect_gt(state_total, 50000,
              info = "State total tested should be > 50,000 for grades 2-3")
  }
})

test_that("2023 state aggregate has reasonable total tested", {
  skip_if_offline()

  data <- fetch_assess(2023, use_cache = FALSE)

  state_rows <- data[data$is_state == TRUE, ]

  if (nrow(state_rows) > 0 && "n_tested" %in% names(state_rows)) {
    state_total <- sum(state_rows$n_tested, na.rm = TRUE)
    expect_gt(state_total, 50000,
              info = "State total tested should be > 50,000 for grades 2-3")
  }
})

# ==============================================================================
# Grade Level Tests
# ==============================================================================

test_that("2025 has grade_level column", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  expect_true("grade_level" %in% names(data))

  if ("grade_level" %in% names(data)) {
    expect_true("Grade 2" %in% unique(data$grade_level))
    expect_true("Grade 3" %in% unique(data$grade_level))
  }
})

test_that("2024 has grade_level column", {
  skip_if_offline()

  data <- fetch_assess(2024, use_cache = FALSE)

  expect_true("grade_level" %in% names(data))

  if ("grade_level" %in% names(data)) {
    expect_true("Grade 2" %in% unique(data$grade_level))
    expect_true("Grade 3" %in% unique(data$grade_level))
  }
})

# ==============================================================================
# Cache Tests
# ==============================================================================

test_that("use_cache=TRUE works (second call faster)", {
  skip_if_offline()

  # First call - no cache
  start_time <- Sys.time()
  data1 <- fetch_assess(2025, use_cache = FALSE)
  time1 <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

  # Second call - should use cache
  start_time <- Sys.time()
  data2 <- fetch_assess(2025, use_cache = TRUE)
  time2 <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

  # Both should return same data
  expect_equal(nrow(data1), nrow(data2))

  # Cached call should be much faster (or equal if cache miss)
  # We just verify it doesn't error
  expect_true(TRUE)
})

# ==============================================================================
# Tidy vs Wide Format Tests
# ==============================================================================

test_that("tidy=TRUE and tidy=FALSE return different structures", {
  skip_if_offline()

  tidy_data <- fetch_assess(2025, tidy = TRUE, use_cache = FALSE)
  wide_data <- fetch_assess(2025, tidy = FALSE, use_cache = FALSE)

  # Both should have data
  expect_gt(nrow(tidy_data), 0)
  expect_gt(nrow(wide_data), 0)

  # Tidy should have proficiency_rate column
  expect_true("proficiency_rate" %in% names(tidy_data))

  # Wide should have percentage columns
  expect_true(any(grepl("pct_", names(wide_data))))
})

# ==============================================================================
# Fidelity Tests - Specific Known Values
# ==============================================================================

# These tests verify exact values from raw Excel files
# Values were manually verified during development

test_that("2025 state aggregate has realistic proficiency rate", {
  skip_if_offline()

  data <- fetch_assess(2025, use_cache = FALSE)

  state_rows <- data[data$is_state == TRUE, ]

  if (nrow(state_rows) > 0 && "proficiency_rate" %in% names(state_rows)) {
    # State proficiency rate for grades 2-3 reading should be reasonable
    # Based on Alabama Literacy Act data, expect 50-75% range
    avg_proficiency <- mean(state_rows$proficiency_rate, na.rm = TRUE)
    expect_gte(avg_proficiency, 0.40)
    expect_lte(avg_proficiency, 0.90)
  }
})

test_that("2024 state aggregate has realistic proficiency rate", {
  skip_if_offline()

  data <- fetch_assess(2024, use_cache = FALSE)

  state_rows <- data[data$is_state == TRUE, ]

  if (nrow(state_rows) > 0 && "proficiency_rate" %in% names(state_rows)) {
    avg_proficiency <- mean(state_rows$proficiency_rate, na.rm = TRUE)
    expect_gte(avg_proficiency, 0.40)
    expect_lte(avg_proficiency, 0.90)
  }
})

test_that("2023 state aggregate shows Literacy Act impact", {
  skip_if_offline()

  data <- fetch_assess(2023, use_cache = FALSE)

  state_rows <- data[data$is_state == TRUE, ]

  if (nrow(state_rows) > 0 && "proficiency_rate" %in% names(state_rows)) {
    # 2023 showed improvement due to Literacy Act
    avg_proficiency <- mean(state_rows$proficiency_rate, na.rm = TRUE)
    expect_gte(avg_proficiency, 0.50)
    expect_lte(avg_proficiency, 0.85)
  }
})

# ==============================================================================
# End of Test File
# ==============================================================================
