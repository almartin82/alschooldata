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
# Available Years: 2015-2024 (school year end year, e.g., 2024 = 2023-24)
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
          jitter <- runif(1, 0, delay * 0.1)
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
#' @param end_year School year end (2023-24 = 2024). Valid values are 2015-2024.
#' @return Data frame with raw enrollment data
#' @keywords internal
get_raw_enr <- function(end_year) {

  # Get valid year range
  years <- get_available_years()

  # Validate year
  if (end_year < years$min_year || end_year > years$max_year) {
    stop(paste0("end_year must be between ", years$min_year, " and ", years$max_year,
                ". ALSDE Federal Report Card data is only available for 2015-2024."))
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
#' @param end_year School year end
#' @return Data frame with enrollment data
#' @keywords internal
download_federal_reportcard <- function(end_year) {

  message("  Downloading from ALSDE Federal Report Card...")

  # The Federal Report Card exports data via a POST request to an ASPX endpoint
  # The page uses ASP.NET ViewState, so we need to:
  # 1. GET the page to obtain __VIEWSTATE and other hidden fields
  # 2. POST with the year filter and export request

  base_url <- "https://reportcard.alsde.edu/SupportingData_StudentDemographics.aspx"

  # First, get the page to extract ViewState (with retry)
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

  if (is.na(viewstate)) {
    stop("Failed to extract ViewState from ALSDE Federal Report Card page. ",
         "The page structure may have changed. ",
         "Please report this issue at: https://github.com/almartin82/alschooldata/issues")
  }

  # Build form data for export request
  # The grid exports all data when clicking the CSV export button
  form_data <- list(
    `__VIEWSTATE` = viewstate,
    `__VIEWSTATEGENERATOR` = viewstate_gen,
    `__EVENTVALIDATION` = event_validation,
    `ctl00$ContentPlaceHolder1$ddlYear` = as.character(end_year),
    `ctl00$ContentPlaceHolder1$btnExportCSV` = "Export to CSV"
  )

  # Create temp file for download
  tname <- tempfile(
    pattern = paste0("alsde_demographics_", end_year, "_"),
    tmpdir = tempdir(),
    fileext = ".csv"
  )

  # POST request to export data (with retry)
  export_response <- retry_with_backoff(
    request_fn = function() {
      httr::POST(
        base_url,
        body = form_data,
        encode = "form",
        httr::write_disk(tname, overwrite = TRUE),
        httr::timeout(60),
        httr::user_agent("alschooldata R package (https://github.com/almartin82/alschooldata)")
      )
    },
    max_retries = 5,
    base_delay = 2,  # Start with 2s delay for export requests
    description = "ALSDE data export"
  )

  if (httr::http_error(export_response)) {
    unlink(tname)
    stop(paste("Failed to export data from ALSDE Federal Report Card. HTTP status:",
               httr::status_code(export_response),
               "\nThe server may be temporarily unavailable. Please try again later."))
  }

  # Check if we got CSV data or HTML error page
  file_size <- file.info(tname)$size
  if (file_size < 1000) {
    first_lines <- readLines(tname, n = 5, warn = FALSE)
    if (any(grepl("<html|<!DOCTYPE", first_lines, ignore.case = TRUE))) {
      unlink(tname)
      stop("ALSDE server returned an HTML page instead of CSV data. ",
           "This may indicate the year ", end_year, " is not available, ",
           "or the server is experiencing issues. Please try again later.")
    }
  }

  # Read the CSV file
  df <- readr::read_csv(
    tname,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE
  )

  # Clean up
  unlink(tname)

  if (nrow(df) == 0) {
    stop("Downloaded file contains no data for year ", end_year, ". ",
         "Please verify the year is available at: ", base_url)
  }

  message("  Downloaded ", nrow(df), " rows from ALSDE")

  df
}


#' Get Alabama system (district) lookup table
#'
#' Returns a data frame mapping system codes to system names.
#' Alabama has approximately 140 school systems (67 county, 73 city).
#'
#' @return Data frame with system_code and system_name columns
#' @keywords internal
get_system_lookup <- function() {

  # This lookup table contains all Alabama public school systems
  # Source: ALSDE Education Directory
  systems <- data.frame(
    system_code = c(
      "001", "002", "003", "004", "005", "006", "007", "008", "009", "010",
      "011", "012", "013", "014", "015", "016", "017", "018", "019", "020",
      "021", "022", "023", "024", "025", "026", "027", "028", "029", "030",
      "031", "032", "033", "034", "035", "036", "037", "038", "039", "040",
      "041", "042", "043", "044", "045", "046", "047", "048", "049", "050",
      "051", "052", "053", "054", "055", "056", "057", "058", "059", "060",
      "061", "062", "063", "064", "065", "066", "067", "100", "101", "102",
      "103", "104", "105", "106", "107", "108", "109", "110", "111", "112",
      "113", "114", "115", "116", "117", "118", "119", "120", "121", "122",
      "123", "124", "125", "126", "127", "128", "129", "130", "131", "132",
      "133", "134", "135", "136", "137", "138", "139", "140", "141", "142",
      "143", "144", "145", "146", "147", "148", "149", "150", "151", "152",
      "153", "154", "155", "156", "157", "158", "159", "160", "161", "162",
      "163", "164", "165", "166", "167", "168", "169", "170", "171", "172",
      "173"
    ),
    system_name = c(
      # County Systems (001-067)
      "Autauga County", "Baldwin County", "Barbour County", "Bibb County",
      "Blount County", "Bullock County", "Butler County", "Calhoun County",
      "Chambers County", "Cherokee County", "Chilton County", "Choctaw County",
      "Clarke County", "Clay County", "Cleburne County", "Coffee County",
      "Colbert County", "Conecuh County", "Coosa County", "Covington County",
      "Crenshaw County", "Cullman County", "Dale County", "Dallas County",
      "DeKalb County", "Elmore County", "Escambia County", "Etowah County",
      "Fayette County", "Franklin County", "Geneva County", "Greene County",
      "Hale County", "Henry County", "Houston County", "Jackson County",
      "Jefferson County", "Lamar County", "Lauderdale County", "Lawrence County",
      "Lee County", "Limestone County", "Lowndes County", "Macon County",
      "Madison County", "Marengo County", "Marion County", "Marshall County",
      "Mobile County", "Monroe County", "Montgomery County", "Morgan County",
      "Perry County", "Pickens County", "Pike County", "Randolph County",
      "Russell County", "St. Clair County", "Shelby County", "Sumter County",
      "Talladega County", "Tallapoosa County", "Tuscaloosa County", "Walker County",
      "Washington County", "Wilcox County", "Winston County",
      # City Systems (100+)
      "Albertville City", "Alexander City", "Andalusia City", "Anniston City",
      "Arab City", "Athens City", "Attalla City", "Auburn City",
      "Bessemer City", "Birmingham City", "Boaz City", "Brewton City",
      "Chickasaw City", "Cullman City", "Daleville City", "Decatur City",
      "Demopolis City", "Dothan City", "Enterprise City", "Eufaula City",
      "Fairfield City", "Florence City", "Fort Payne City", "Gadsden City",
      "Guntersville City", "Haleyville City", "Hartselle City", "Homewood City",
      "Hoover City", "Huntsville City", "Jacksonville City", "Jasper City",
      "Lanett City", "Leeds City", "Linden City", "Madison City",
      "Midfield City", "Mountain Brook City", "Muscle Shoals City", "Oneonta City",
      "Opelika City", "Oxford City", "Ozark City", "Pelham City",
      "Phenix City", "Piedmont City", "Roanoke City", "Russell County (Phenix City)",
      "Russellville City", "Saraland City", "Scottsboro City", "Selma City",
      "Sheffield City", "Sylacauga City", "Talladega City", "Tallassee City",
      "Tarrant City", "Thomasville City", "Troy City", "Trussville City",
      "Tuscaloosa City", "Tuscumbia City", "Vestavia Hills City", "Winfield City",
      "Alabama School of Fine Arts", "Alabama School of Math/Science",
      # Additional/Charter systems
      "LEAD Academy", "Woodland Prep", "Legacy Prep", "I3 Academy",
      "University Charter School", "Capitol Heights Middle", "Other"
    ),
    stringsAsFactors = FALSE
  )

  systems
}
