# ==============================================================================
# Raw Assessment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw assessment data from the
# Alabama State Department of Education (ALSDE).
#
# Data Source:
# - ALSDE Alabama Achieves ACAP Reading Assessment (2021-2025)
#   https://www.alabamaachieves.org/assessment/
#
# The Alabama Comprehensive Assessment Program (ACAP) provides school-level
# reading/ELA assessment data with proficiency breakdowns.
#
# Available Years: 2021-2022, 2022-2023, 2023-2024, 2024-2025
# Available Grades: 02, 03 (early literacy assessment grades)
# Available Subjects: Reading/ELA only
#
# ==============================================================================

#' Download raw assessment data from ALSDE
#'
#' Downloads school-level ACAP Reading assessment data from the Alabama State
#' Department of Education Alabama Achieves website.
#'
#' @param end_year School year end (2023-24 = 2024). Valid values are 2022-2025.
#' @return Data frame with raw assessment data
#' @keywords internal
get_raw_assess <- function(end_year) {

  # Get valid year range
  years <- get_available_assess_years()

  # Validate year
  if (end_year < years$min_year || end_year > years$max_year) {
    stop(paste0("end_year must be between ", years$min_year, " and ", years$max_year,
                ". ALSDE ACAP assessment data is only available for 2021-2025."))
  }

  message(paste("Downloading ALSDE ACAP assessment data for", school_year_label(end_year), "..."))

  # Download from Alabama Achieves
  raw_data <- download_acap_assessment(end_year)

  # Add end_year column
  raw_data$end_year <- end_year

  raw_data
}


#' Download ACAP Reading assessment data
#'
#' The Alabama Achieves website provides ACAP Reading assessment data in Excel format.
#' This function downloads the appropriate file for the requested school year.
#'
#' File URLs follow this pattern:
#' - 2021-2022: https://www.alabamaachieves.org/wp-content/uploads/2022/07/2021-2022-ACAP-Reading.xlsx
#' - 2022-2023: https://www.alabamaachieves.org/wp-content/uploads/2023/06/RD_SP_202368_2022-2023-ACAP-Reading_V1.0.xlsx
#' - 2023-2024: https://www.alabamaachieves.org/wp-content/uploads/2024/06/RD_SP_2024613_2023-2024-ACAP-Reading.xlsx
#' - 2024-2025: https://www.alabamaachieves.org/wp-content/uploads/2025/06/RD_SP_2025612_ACAP-Reading_v1.0.xlsx
#'
#' @param end_year School year end
#' @return Data frame with assessment data
#' @keywords internal
download_acap_assessment <- function(end_year) {

  message("  Downloading from ALSDE Alabama Achieves...")

  # Map end_year to file URL
  file_urls <- list(
    "2022" = "https://www.alabamaachieves.org/wp-content/uploads/2022/07/2021-2022-ACAP-Reading.xlsx",
    "2023" = "https://www.alabamaachieves.org/wp-content/uploads/2023/06/RD_SP_202368_2022-2023-ACAP-Reading_V1.0.xlsx",
    "2024" = "https://www.alabamaachieves.org/wp-content/uploads/2024/06/RD_SP_2024613_2023-2024-ACAP-Reading.xlsx",
    "2025" = "https://www.alabamaachieves.org/wp-content/uploads/2025/06/RD_SP_2025612_ACAP-Reading_v1.0.xlsx"
  )

  # Get URL for this year
  url_key <- as.character(end_year)
  if (!url_key %in% names(file_urls)) {
    stop("ACAP assessment data not available for end_year ", end_year)
  }

  file_url <- file_urls[[url_key]]

  # Create temp file for download
  tname <- tempfile(
    pattern = paste0("alsde_acap_", end_year, "_"),
    tmpdir = tempdir(),
    fileext = ".xlsx"
  )

  # Download file (with retry)
  response <- retry_with_backoff(
    request_fn = function() {
      httr::GET(
        file_url,
        httr::write_disk(tname, overwrite = TRUE),
        httr::timeout(60),
        httr::user_agent("alschooldata R package (https://github.com/almartin82/alschooldata)")
      )
    },
    max_retries = 5,
    base_delay = 2,
    description = "ALSDE ACAP assessment download"
  )

  if (httr::http_error(response)) {
    unlink(tname)
    stop(paste("Failed to download ACAP assessment data. HTTP status:",
               httr::status_code(response),
               "\nURL:", file_url))
  }

  # Check file size
  file_size <- file.info(tname)$size
  if (file_size < 1000) {
    unlink(tname)
    stop("Downloaded file is too small. The file may not be available for year ", end_year)
  }

  # Read the Excel file
  # Files have different structures:
  # - 2021-2022: No grade column, header is row 1
  # - 2022-2025: Have grade column, header is row 5

  if (end_year == 2022) {
    # 2021-2022 file has different structure
    df <- readxl::read_excel(
      tname,
      sheet = 1,
      skip = 0
    )
    # First row is header
    names(df) <- df[1, ]
    df <- df[-1, ]
  } else {
    # 2022-2025 files have header on row 5
    df <- readxl::read_excel(
      tname,
      sheet = 1,
      skip = 4
    )
  }

  # Clean up temp file
  unlink(tname)

  if (nrow(df) == 0) {
    stop("Downloaded file contains no data for year ", end_year)
  }

  message("  Downloaded ", nrow(df), " rows from ALSDE")

  df
}


#' Get available assessment years
#'
#' Returns the minimum and maximum years available for ACAP assessment data.
#'
#' @return List with min_year and max_year
#' @keywords internal
get_available_assess_years <- function() {
  list(
    min_year = 2022,
    max_year = 2025
  )
}
