# ==============================================================================
# Directory Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading school directory data from the
# Alabama State Department of Education (ALSDE).
#
# IMPORTANT: This package uses ONLY ALSDE data sources.
# No federal data sources (NCES, Urban Institute, etc.) are used.
#
# Data Source:
# - ALSDE Education Directory - Registered School Information
#   https://eddir.alsde.edu/SiteInfo/PublicPrivateReligiousSites
#
# ==============================================================================

#' Fetch Alabama school directory data
#'
#' Downloads and processes school directory data from the ALSDE Education
#' Directory. Data includes school and district contact information including
#' administrator names, physical addresses, phone numbers, websites,
#' grade ranges, and superintendent names.
#'
#' Directory data is a point-in-time snapshot (not year-specific) reflecting
#' the current state of the ALSDE Education Directory.
#'
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'   Set to FALSE to force re-download from source.
#' @return Data frame with directory data containing columns:
#'   \describe{
#'     \item{district_name}{Name of the school system/district}
#'     \item{school_name}{Name of the school (NA for district/state rows)}
#'     \item{entity_type}{One of "State", "District", or "School"}
#'     \item{principal_name}{School principal or district administrator name}
#'     \item{superintendent_name}{District superintendent name}
#'     \item{address}{Physical street address}
#'     \item{city}{City}
#'     \item{state}{State (always "AL")}
#'     \item{zip}{ZIP code}
#'     \item{phone}{Phone number}
#'     \item{website}{Website URL}
#'     \item{grades_served}{Grade range offered (e.g., "PK-05", "09-12")}
#'     \item{is_state}{TRUE for state-level row}
#'     \item{is_district}{TRUE for district-level rows}
#'     \item{is_school}{TRUE for school-level rows}
#'   }
#' @export
#' @examples
#' \dontrun{
#' # Get directory data
#' dir <- fetch_directory()
#'
#' # List all districts with superintendents
#' dir |>
#'   dplyr::filter(is_district) |>
#'   dplyr::select(district_name, superintendent_name)
#'
#' # Find schools in Jefferson County
#' dir |>
#'   dplyr::filter(is_school, grepl("Jefferson", district_name)) |>
#'   dplyr::select(school_name, principal_name, grades_served)
#'
#' # Count schools per district
#' dir |>
#'   dplyr::filter(is_school) |>
#'   dplyr::count(district_name, sort = TRUE)
#'
#' # Force fresh download (ignore cache)
#' dir_fresh <- fetch_directory(use_cache = FALSE)
#' }
fetch_directory <- function(use_cache = TRUE) {

  cache_type <- "directory"

  # Use a pseudo-year for cache key (0 = current snapshot)
  cache_year <- 0L

  # Check cache first
  if (use_cache && cache_exists(cache_year, cache_type)) {
    message("Using cached directory data")
    return(read_cache(cache_year, cache_type))
  }

  # Get raw data from ALSDE
  raw <- get_raw_directory()

  # Process to standard schema
  processed <- process_directory(raw)

  # Cache the result
  if (use_cache) {
    write_cache(processed, cache_year, cache_type)
  }

  processed
}


#' Clear directory data cache
#'
#' Removes cached directory data files.
#'
#' @return Invisibly returns the number of files removed
#' @export
#' @examples
#' \dontrun{
#' # Clear directory cache
#' clear_directory_cache()
#' }
clear_directory_cache <- function() {
  cache_dir <- get_cache_dir()
  files <- list.files(cache_dir, pattern = "^directory_", full.names = TRUE)

  # Also match enr_directory pattern from get_cache_path
  files2 <- list.files(cache_dir, pattern = "^enr_directory_", full.names = TRUE)
  files <- unique(c(files, files2))

  if (length(files) > 0) {
    file.remove(files)
    message(paste("Removed", length(files), "cached directory file(s)"))
  } else {
    message("No cached directory files to remove")
  }

  invisible(length(files))
}
