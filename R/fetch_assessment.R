# ==============================================================================
# Assessment Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading assessment data from the
# Alabama State Department of Education (ALSDE).
#
# IMPORTANT: This package uses ONLY ALSDE data sources.
# No federal data sources (NCES, Urban Institute, etc.) are used.
#
# ==============================================================================

#' Fetch Alabama ACAP assessment data
#'
#' Downloads and processes ACAP Reading assessment data from ALSDE Alabama Achieves.
#' Data includes school-level proficiency rates for grades 2-3 reading assessments.
#'
#' @param end_year A school year. Year is the end of the academic year - eg 2023-24
#'   school year is year '2024'. Valid values are 2022-2025.
#' @param tidy If TRUE (default), returns data in long (tidy) format with
#'   proficiency_rate column. If FALSE, returns wide format with percentage columns.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'   Set to FALSE to force re-download from source.
#' @return Data frame with assessment data. Wide format includes columns for
#'   district_name, campus_name, grade, and proficiency percentages.
#'   Tidy format includes proficiency_rate as a single column.
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 ACAP assessment data (2023-24 school year)
#' assess_2024 <- fetch_assess(2024)
#'
#' # Get wide format
#' assess_wide <- fetch_assess(2024, tidy = FALSE)
#'
#' # Force fresh download (ignore cache)
#' assess_fresh <- fetch_assess(2024, use_cache = FALSE)
#'
#' # Filter to state-level 3rd grade reading proficiency
#' assess_2024 |>
#'   dplyr::filter(is_state, grade == "03") |>
#'   dplyr::select(end_year, n_tested, proficiency_rate)
#' }
fetch_assess <- function(end_year, tidy = TRUE, use_cache = TRUE) {

  # Validate year
  available <- get_available_assess_years()
  if (end_year < available$min_year || end_year > available$max_year) {
    stop(paste0(
      "end_year must be between ", available$min_year, " and ", available$max_year,
      ".\nUse get_available_assess_years() for details on data availability."
    ))
  }

  # Determine cache type based on tidy parameter
  cache_type <- if (tidy) "assess_tidy" else "assess_wide"

  # Check cache first
  if (use_cache && cache_exists(end_year, cache_type)) {
    message(paste("Using cached assessment data for", end_year))
    return(read_cache(end_year, cache_type))
  }

  # Get raw data from ALSDE
  raw <- get_raw_assess(end_year)

  # Process to standard schema
  processed <- process_assess(raw, end_year)

  # Optionally tidy
  if (tidy) {
    processed <- tidy_assess(processed) |>
      id_assess_aggs()
  }

  # Cache the result
  if (use_cache) {
    write_cache(processed, end_year, cache_type)
  }

  processed
}


#' Fetch assessment data for multiple years
#'
#' Downloads and combines ACAP assessment data for multiple school years.
#'
#' @param end_years Vector of school year ends (e.g., c(2022, 2023, 2024))
#' @param tidy If TRUE (default), returns data in long (tidy) format.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#' @return Combined data frame with assessment data for all requested years
#' @export
#' @examples
#' \dontrun{
#' # Get 3 years of assessment data
#' assess_multi <- fetch_assess_multi(2022:2024)
#'
#' # Track 3rd grade reading proficiency trends
#' assess_multi |>
#'   dplyr::filter(is_state, grade == "03") |>
#'   dplyr::select(end_year, n_tested, proficiency_rate)
#' }
fetch_assess_multi <- function(end_years, tidy = TRUE, use_cache = TRUE) {

  # Validate years
  available <- get_available_assess_years()
  invalid_years <- end_years[end_years < available$min_year | end_years > available$max_year]
  if (length(invalid_years) > 0) {
    stop(paste("Invalid years:", paste(invalid_years, collapse = ", "),
               "\nend_year must be between", available$min_year, "and", available$max_year))
  }

  # Fetch each year
  results <- purrr::map(
    end_years,
    function(yr) {
      message(paste("Fetching", yr, "..."))
      fetch_assess(yr, tidy = tidy, use_cache = use_cache)
    }
  )

  # Combine
  dplyr::bind_rows(results)
}
