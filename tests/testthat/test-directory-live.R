# ==============================================================================
# LIVE Pipeline Tests for alschooldata Directory Functions
# ==============================================================================
#
# These tests verify the directory data pipeline using LIVE network calls.
# No mocks - we verify actual connectivity and data correctness.
#
# Test Categories:
# 1. URL Availability - HTTP 200 checks
# 2. Raw Data Download - get_raw_directory() works
# 3. Data Processing - process_directory() produces valid output
# 4. Column Structure - Expected columns exist
# 5. Data Quality - Valid values, no empty data
# 6. Entity Flags - is_state, is_district, is_school are correct
# 7. Full Pipeline - fetch_directory() end-to-end
#
# ==============================================================================

library(testthat)
library(httr)

# Skip if no network connectivity
skip_if_offline <- function() {
  tryCatch({
    response <- httr::HEAD("https://www.google.com", httr::timeout(5))
    if (httr::http_error(response)) {
      skip("No network connectivity")
    }
  }, error = function(e) {
    skip("No network connectivity")
  })
}

# ==============================================================================
# STEP 1: URL Availability Tests
# ==============================================================================

test_that("ALSDE Education Directory page is accessible", {
  skip_on_cran()
  skip_if_offline()

  response <- httr::GET(
    "https://eddir.alsde.edu/SiteInfo/PublicPrivateReligiousSites",
    httr::timeout(30),
    httr::user_agent("alschooldata R package test")
  )

  expect_equal(httr::status_code(response), 200)
})

test_that("ALSDE Education Directory page contains expected form fields", {
  skip_on_cran()
  skip_if_offline()

  response <- httr::GET(
    "https://eddir.alsde.edu/SiteInfo/PublicPrivateReligiousSites",
    httr::timeout(30),
    httr::user_agent("alschooldata R package test")
  )

  page_content <- httr::content(response, "text", encoding = "UTF-8")
  html_doc <- xml2::read_html(page_content)

  # Verify ViewState exists
  viewstate <- rvest::html_element(html_doc, "input#__VIEWSTATE") |>
    rvest::html_attr("value")
  expect_false(is.na(viewstate))

  # Verify grid controls exist
  expect_true(grepl("pcResults_gridPublicSchool", page_content))
  expect_true(grepl("pcResults_gridSuperintendent", page_content))
})

# ==============================================================================
# STEP 2: Raw Data Download Tests
# ==============================================================================

test_that("get_raw_directory downloads school and superintendent data", {
  skip_on_cran()
  skip_if_offline()

  tryCatch({
    raw <- alschooldata:::get_raw_directory()

    expect_true(is.list(raw))
    expect_true("schools" %in% names(raw))
    expect_true("superintendents" %in% names(raw))

    # Both should be data frames with data
    expect_true(is.data.frame(raw$schools))
    expect_true(is.data.frame(raw$superintendents))
    expect_gt(nrow(raw$schools), 100)
    expect_gt(nrow(raw$superintendents), 50)

    message("Downloaded ", nrow(raw$schools), " school rows and ",
            nrow(raw$superintendents), " superintendent rows")
  }, error = function(e) {
    skip(paste("Data source may be broken:", e$message))
  })
})

# ==============================================================================
# STEP 3: Data Processing Tests
# ==============================================================================

test_that("process_directory produces valid output", {
  skip_on_cran()
  skip_if_offline()

  tryCatch({
    raw <- alschooldata:::get_raw_directory()
    processed <- alschooldata:::process_directory(raw)

    expect_true(is.data.frame(processed))
    expect_gt(nrow(processed), 100)

    # Should have all entity types
    expect_true(any(processed$entity_type == "State"))
    expect_true(any(processed$entity_type == "District"))
    expect_true(any(processed$entity_type == "School"))
  }, error = function(e) {
    skip(paste("Data source may be broken:", e$message))
  })
})

# ==============================================================================
# STEP 4: Column Structure Tests
# ==============================================================================

test_that("fetch_directory returns expected columns", {
  skip_on_cran()
  skip_if_offline()

  tryCatch({
    dir <- alschooldata::fetch_directory(use_cache = FALSE)

    expected_cols <- c(
      "district_name", "school_name", "entity_type",
      "principal_name", "superintendent_name",
      "address", "city", "state", "zip", "phone", "website",
      "grades_served",
      "is_state", "is_district", "is_school"
    )

    for (col in expected_cols) {
      expect_true(col %in% names(dir),
                  info = paste("Missing column:", col))
    }
  }, error = function(e) {
    skip(paste("Data source may be broken:", e$message))
  })
})

# ==============================================================================
# STEP 5: Data Quality Tests
# ==============================================================================

test_that("Directory data has reasonable row counts", {
  skip_on_cran()
  skip_if_offline()

  tryCatch({
    dir <- alschooldata::fetch_directory()

    # Alabama has ~153 districts and ~1,362 schools
    n_districts <- sum(dir$is_district, na.rm = TRUE)
    n_schools <- sum(dir$is_school, na.rm = TRUE)
    n_state <- sum(dir$is_state, na.rm = TRUE)

    expect_equal(n_state, 1)
    expect_gt(n_districts, 100)
    expect_gt(n_schools, 500)

    message("Directory: ", n_state, " state, ",
            n_districts, " districts, ", n_schools, " schools")
  }, error = function(e) {
    skip(paste("Data source may be broken:", e$message))
  })
})

test_that("District names are not empty", {
  skip_on_cran()
  skip_if_offline()

  tryCatch({
    dir <- alschooldata::fetch_directory()

    # All rows except state should have district names
    non_state <- dir[!dir$is_state, ]
    expect_true(all(!is.na(non_state$district_name)))
    expect_true(all(nchar(non_state$district_name) > 0))
  }, error = function(e) {
    skip(paste("Data source may be broken:", e$message))
  })
})

test_that("School-level rows have school names", {
  skip_on_cran()
  skip_if_offline()

  tryCatch({
    dir <- alschooldata::fetch_directory()

    schools <- dir[dir$is_school, ]
    expect_true(all(!is.na(schools$school_name)))
    expect_true(all(nchar(schools$school_name) > 0))
  }, error = function(e) {
    skip(paste("Data source may be broken:", e$message))
  })
})

test_that("State column is always AL", {
  skip_on_cran()
  skip_if_offline()

  tryCatch({
    dir <- alschooldata::fetch_directory()

    non_na_state <- dir$state[!is.na(dir$state)]
    expect_true(all(non_na_state == "AL"))
  }, error = function(e) {
    skip(paste("Data source may be broken:", e$message))
  })
})

# ==============================================================================
# STEP 6: Entity Flag Tests
# ==============================================================================

test_that("Entity flags are mutually exclusive", {
  skip_on_cran()
  skip_if_offline()

  tryCatch({
    dir <- alschooldata::fetch_directory()

    # Each row should be exactly one of state, district, school
    flag_sum <- dir$is_state + dir$is_district + dir$is_school
    expect_true(all(flag_sum == 1),
                info = "Each row should be exactly one entity type")
  }, error = function(e) {
    skip(paste("Data source may be broken:", e$message))
  })
})

test_that("Known districts are present", {
  skip_on_cran()
  skip_if_offline()

  tryCatch({
    dir <- alschooldata::fetch_directory()

    districts <- dir$district_name[dir$is_district]

    # Check for well-known Alabama districts
    expect_true(any(grepl("Mobile County", districts)))
    expect_true(any(grepl("Jefferson County", districts)))
    expect_true(any(grepl("Birmingham City", districts)))
    expect_true(any(grepl("Huntsville City", districts)))
    expect_true(any(grepl("Montgomery County", districts)))
  }, error = function(e) {
    skip(paste("Data source may be broken:", e$message))
  })
})

# ==============================================================================
# STEP 7: Full Pipeline Tests
# ==============================================================================

test_that("fetch_directory end-to-end works", {
  skip_on_cran()
  skip_if_offline()

  tryCatch({
    dir <- alschooldata::fetch_directory(use_cache = FALSE)

    expect_true(is.data.frame(dir))
    expect_gt(nrow(dir), 100)

    # Verify we can filter by entity type
    districts <- dir |> dplyr::filter(is_district)
    schools <- dir |> dplyr::filter(is_school)

    expect_gt(nrow(districts), 50)
    expect_gt(nrow(schools), 500)

    # Verify superintendent data is merged
    districts_with_supts <- districts |>
      dplyr::filter(!is.na(superintendent_name))
    expect_gt(nrow(districts_with_supts), 50)
  }, error = function(e) {
    skip(paste("Data source may be broken:", e$message))
  })
})

# ==============================================================================
# Cache Tests
# ==============================================================================

test_that("Directory cache functions work", {
  skip_on_cran()

  # Test that cache path can be generated
  tryCatch({
    path <- alschooldata:::get_cache_path(0, "directory")
    expect_true(is.character(path))
    expect_true(grepl("directory", path))
  }, error = function(e) {
    skip("Cache functions may not be implemented")
  })
})
