# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from the
# Alabama State Department of Education (ALSDE).
#
# Data Source:
# - ALSDE Federal Report Card Student Demographics (2015-present)
#   https://reportcard.alsde.edu/SupportingData_StudentDemographics.aspx
#
# The Federal Report Card provides school-level enrollment data with detailed
# demographic breakdowns including race/ethnicity, gender, and special populations.
#
# Available Years: 2015-2025 (school year end year, e.g., 2025 = 2024-25)
#
# ==============================================================================

#' Retry an HTTP request with exponential backoff
#'
#' @param request_fn Function that makes the HTTP request and returns response
#' @param max_retries Maximum number of retry attempts (default 5)
#' @param base_delay Initial delay in seconds (default 1)
#' @param max_delay Maximum delay in seconds (default 60)
#' @param description Description of the request for logging
#' @return The HTTP response if successful
#' @keywords internal
retry_with_backoff <- function(request_fn, max_retries = 5, base_delay = 1,
                                max_delay = 60, description = "request") {
  attempt <- 1

  while (attempt <= max_retries) {
    result <- tryCatch(
      {
        response <- request_fn()
        # Check for server errors (5xx) that warrant retry
        if (httr::http_error(response)) {
          status <- httr::status_code(response)
          if (status >= 500 && status < 600) {
            stop(paste("Server error:", status))
          }
        }
        return(response)
      },
      error = function(e) {
        if (attempt < max_retries) {
          # Exponential backoff with jitter
          delay <- min(base_delay * (2 ^ (attempt - 1)), max_delay)
          jitter <- stats::runif(1, 0, delay * 0.1)
          wait_time <- delay + jitter

          message(sprintf("  Attempt %d/%d failed for %s: %s",
                          attempt, max_retries, description, e$message))
          message(sprintf("  Retrying in %.1f seconds...", wait_time))
          Sys.sleep(wait_time)
          return(NULL)  # Signal to retry
        } else {
          stop(e)
        }
      }
    )

    if (!is.null(result)) {
      if (attempt > 1) {
        message(sprintf("  %s succeeded on attempt %d", description, attempt))
      }
      return(result)
    }

    attempt <- attempt + 1
  }

  stop(paste("All", max_retries, "attempts failed for", description))
}

#' Download raw enrollment data from ALSDE
#'
#' Downloads school-level enrollment data from the Alabama State Department of
#' Education Federal Report Card Student Demographics system.
#'
#' @param end_year School year end (2024-25 = 2025). Valid values are 2015-2025.
#' @return Data frame with raw enrollment data
#' @keywords internal
get_raw_enr <- function(end_year) {

  # Get valid year range
  years <- get_available_years()

  # Validate year
  if (end_year < years$min_year || end_year > years$max_year) {
    stop(paste0("end_year must be between ", years$min_year, " and ", years$max_year,
                ". ALSDE Federal Report Card data is available for these years."))
  }

  message(paste("Downloading ALSDE enrollment data for", school_year_label(end_year), "..."))

  # Download from Federal Report Card Student Demographics
  raw_data <- download_federal_reportcard(end_year)

  # Add end_year column
  raw_data$end_year <- end_year

  raw_data
}


#' Download data from Federal Report Card Student Demographics
#'
#' The Federal Report Card provides detailed enrollment data by demographics
#' at the school level. This function downloads the CSV export.
#'
#' The Student Demographics page is available at:
#' https://reportcard.alsde.edu/SupportingData_StudentDemographics.aspx
#'
#' The export returns a CSV with columns:
#' - Year, System, School (identifiers)
#' - Grade, Gender, Ethnicity, Sub Population (filter dimensions)
#' - Total Student Count (enrollment count)
#' - Race columns: Asian, Black or African American,
#'   American Indian / Alaska Native, Native Hawaiian / Pacific Islander,
#'   White, Two or more races (with corresponding % columns)
#'
#' @param end_year School year end
#' @return Data frame with enrollment data
#' @keywords internal
download_federal_reportcard <- function(end_year) {

  message("  Downloading from ALSDE Federal Report Card...")

  # The Federal Report Card uses ASP.NET with DevExpress controls.
  # Export requires:
  # 1. GET the page to obtain ViewState and other hidden fields

  # 2. POST with __EVENTTARGET set to the CSV export button

  base_url <- "https://reportcard.alsde.edu/SupportingData_StudentDemographics.aspx"

  # Step 1: GET the page to extract form state (with retry)
  initial_response <- retry_with_backoff(
    request_fn = function() {
      httr::GET(
        base_url,
        httr::timeout(60),
        httr::user_agent("alschooldata R package (https://github.com/almartin82/alschooldata)")
      )
    },
    max_retries = 5,
    description = "ALSDE page fetch"
  )

  if (httr::http_error(initial_response)) {
    stop(paste("Failed to access ALSDE Federal Report Card page. HTTP status:",
               httr::status_code(initial_response),
               "\nPlease check if the site is accessible at:", base_url))
  }

  page_content <- httr::content(initial_response, "text", encoding = "UTF-8")

  # Parse HTML to extract ASP.NET form fields
  html_doc <- xml2::read_html(page_content)

  # Extract hidden form fields needed for postback
  viewstate <- rvest::html_element(html_doc, "input#__VIEWSTATE") |>
    rvest::html_attr("value")
  viewstate_gen <- rvest::html_element(html_doc, "input#__VIEWSTATEGENERATOR") |>
    rvest::html_attr("value")
  event_validation <- rvest::html_element(html_doc, "input#__EVENTVALIDATION") |>
    rvest::html_attr("value")
  req_token <- rvest::html_element(html_doc,
    "input[name=__RequestVerificationToken]") |>
    rvest::html_attr("value")

  if (is.na(viewstate)) {
    stop("Failed to extract ViewState from ALSDE Federal Report Card page. ",
         "The page structure may have changed. ",
         "Please report this issue at: https://github.com/almartin82/alschooldata/issues")
  }

  # Extract cookies from initial response for session continuity
  page_cookies <- httr::cookies(initial_response)

  # Build school year label for the dropdown (e.g., "2024-2025")
  year_label <- paste0(end_year - 1, "-", end_year)

  # Build form data for CSV export postback
  # The DevExpress grid uses __EVENTTARGET to trigger the export button
  form_data <- list(
    `__VIEWSTATE` = viewstate,
    `__VIEWSTATEGENERATOR` = viewstate_gen,
    `__EVENTVALIDATION` = event_validation,
    `__RequestVerificationToken` = req_token,
    `__EVENTTARGET` = "ctl00$ctl00$CPH_ReportCard$SupportingDataContent$btnDemographicsDataCSVExport",
    `__EVENTARGUMENT` = "",
    `ctl00$ctl00$CPH_ReportCard$SupportingDataContent$txtReportYear` = as.character(end_year),
    `ctl00$ctl00$CPH_ReportCard$SupportingDataContent$txtSchoolId` = "0",
    `CPH_ReportCard_SupportingDataContent_ddlReportYear_VI` = as.character(end_year),
    `ctl00$ctl00$CPH_ReportCard$SupportingDataContent$ddlReportYear` = year_label
  )

  # Create temp file for download
  tname <- tempfile(
    pattern = paste0("alsde_demographics_", end_year, "_"),
    tmpdir = tempdir(),
    fileext = ".csv"
  )

  # Step 2: POST request to export data (with retry)
  # The CSV file can be large (60-80 MB) so allow generous timeout
  export_response <- retry_with_backoff(
    request_fn = function() {
      httr::POST(
        base_url,
        body = form_data,
        encode = "form",
        httr::write_disk(tname, overwrite = TRUE),
        httr::timeout(300),
        httr::user_agent("alschooldata R package (https://github.com/almartin82/alschooldata)"),
        httr::set_cookies(.cookies = stats::setNames(
          page_cookies$value, page_cookies$name
        ))
      )
    },
    max_retries = 5,
    base_delay = 5,
    description = "ALSDE data export"
  )

  if (httr::http_error(export_response)) {
    unlink(tname)
    stop(paste("Failed to export data from ALSDE Federal Report Card. HTTP status:",
               httr::status_code(export_response),
               "\nThe server may be temporarily unavailable. Please try again later."))
  }

  # Check content type - should be text/csv
  content_type <- httr::headers(export_response)$`content-type`
  if (!is.null(content_type) && !grepl("csv", content_type, ignore.case = TRUE)) {
    # Check if we got HTML instead
    first_lines <- readLines(tname, n = 5, warn = FALSE)
    if (any(grepl("<html|<!DOCTYPE", first_lines, ignore.case = TRUE))) {
      unlink(tname)
      stop("ALSDE server returned an HTML page instead of CSV data. ",
           "This may indicate the year ", end_year, " is not available, ",
           "or the server is experiencing issues. Please try again later.")
    }
  }

  # Check file size (should be substantial for enrollment data)
  file_size <- file.info(tname)$size
  if (file_size < 1000) {
    first_lines <- readLines(tname, n = 5, warn = FALSE)
    unlink(tname)
    stop("Downloaded file is too small (", file_size, " bytes) for year ", end_year,
         ". Please verify the year is available at: ", base_url)
  }

  # Read the CSV file (all columns as character for safe parsing)
  df <- readr::read_csv(
    tname,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE
  )

  # Clean up temp file
  unlink(tname)

  if (nrow(df) == 0) {
    stop("Downloaded file contains no data for year ", end_year, ". ",
         "Please verify the year is available at: ", base_url)
  }

  message("  Downloaded ", nrow(df), " rows from ALSDE")

  df
}
