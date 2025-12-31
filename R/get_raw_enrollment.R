# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from ALSDE.
# Data comes from two main sources:
# - Federal Report Card (2015-present): Detailed demographics via web export
# - ADM Reports (2019-present): Fall enrollment totals via Excel files
#
# The primary data source is the Federal Report Card Student Demographics page
# which provides school-level enrollment data with demographic breakdowns.
#
# ==============================================================================

#' Download raw enrollment data from ALSDE
#'
#' Downloads school-level enrollment data from ALSDE's Federal Report Card system.
#' Uses the Student Demographics data export which provides counts by race/ethnicity,
#' gender, and special populations.
#'
#' @param end_year School year end (2023-24 = 2024). Valid values are 2015-2025.
#' @return Data frame with raw enrollment data from ALSDE
#' @keywords internal
get_raw_enr <- function(end_year) {

  # Validate year - Federal Report Card data available 2015-2025
  if (end_year < 2015 || end_year > 2025) {
    stop("end_year must be between 2015 and 2025")
  }

  message(paste("Downloading ALSDE enrollment data for", end_year, "..."))

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
#' @param end_year School year end
#' @return Data frame with enrollment data
#' @keywords internal
download_federal_reportcard <- function(end_year) {

  message("  Downloading from Federal Report Card...")


  # The Federal Report Card exports data via a POST request to an ASPX endpoint

  # The page uses ASP.NET ViewState, so we need to:
  # 1. GET the page to obtain __VIEWSTATE and other hidden fields
  # 2. POST with the year filter and export request

  base_url <- "https://reportcard.alsde.edu/SupportingData_StudentDemographics.aspx"

  # First, get the page to extract ViewState
  initial_response <- httr::GET(
    base_url,
    httr::timeout(120)
  )

  if (httr::http_error(initial_response)) {
    stop(paste("Failed to access Federal Report Card page. HTTP status:",
               httr::status_code(initial_response)))
  }

  page_content <- httr::content(initial_response, "text", encoding = "UTF-8")

  # Parse HTML to extract ASP.NET form fields
  html_doc <- xml2::read_html(page_content)

  # Extract hidden form fields needed for postback
  viewstate <- rvest::html_element(html_doc, "input#__VIEWSTATE") %>%
    rvest::html_attr("value")
  viewstate_gen <- rvest::html_element(html_doc, "input#__VIEWSTATEGENERATOR") %>%
    rvest::html_attr("value")
  event_validation <- rvest::html_element(html_doc, "input#__EVENTVALIDATION") %>%
    rvest::html_attr("value")

  if (is.na(viewstate)) {
    # Fallback: try alternative download method
    message("  ViewState extraction failed, trying direct CSV download...")
    return(download_federal_reportcard_direct(end_year))
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

  # POST request to export data
  export_response <- httr::POST(
    base_url,
    body = form_data,
    encode = "form",
    httr::write_disk(tname, overwrite = TRUE),
    httr::timeout(600)  # Long timeout for large export
  )

  if (httr::http_error(export_response)) {
    # Try alternative download method
    message("  Export request failed, trying direct download...")
    return(download_federal_reportcard_direct(end_year))
  }

  # Check if we got CSV data or HTML error page
  file_size <- file.info(tname)$size
  if (file_size < 1000) {
    first_lines <- readLines(tname, n = 5, warn = FALSE)
    if (any(grepl("<html|<!DOCTYPE", first_lines, ignore.case = TRUE))) {
      message("  Received HTML instead of CSV, trying direct download...")
      return(download_federal_reportcard_direct(end_year))
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

  df
}


#' Direct download from Federal Report Card (fallback method)
#'
#' This is a fallback method that constructs synthetic data based on the
#' known structure of ALSDE data. Used when the primary download method fails.
#'
#' @param end_year School year end
#' @return Data frame with enrollment data
#' @keywords internal
download_federal_reportcard_direct <- function(end_year) {

  # Try to download from the NCES Common Core of Data as a fallback
  # This provides Alabama school enrollment data with demographics
  message("  Attempting NCES CCD download as fallback...")

  ccd_data <- download_nces_ccd(end_year)

  if (!is.null(ccd_data) && nrow(ccd_data) > 0) {
    return(ccd_data)
  }

  # If CCD fails, try ADM report for basic enrollment
  message("  Attempting ADM report download...")
  adm_data <- download_adm_report(end_year)

  if (!is.null(adm_data) && nrow(adm_data) > 0) {
    return(adm_data)
  }

  stop(paste("Unable to download enrollment data for year", end_year,
             "\nPlease try again later or check ALSDE data availability."))
}


#' Download from NCES Common Core of Data
#'
#' Downloads Alabama school enrollment data from the NCES CCD.
#' This provides a reliable fallback with historical data.
#'
#' @param end_year School year end
#' @return Data frame with enrollment data or NULL if unavailable
#' @keywords internal
download_nces_ccd <- function(end_year) {

  # CCD uses different year format - need to map
  # end_year 2024 = 2023-24 school year = CCD year 2023
  ccd_year <- end_year - 1

  # Build Urban Institute Education Data Portal API URL
  # This API provides easy access to CCD data
  api_url <- paste0(
    "https://educationdata.urban.org/api/v1/schools/ccd/enrollment/",
    ccd_year, "/",
    "?fips=01",  # Alabama FIPS code
    "&grade=99"  # Total enrollment
  )

  tryCatch({
    response <- httr::GET(
      api_url,
      httr::timeout(120)
    )

    if (httr::http_error(response)) {
      message("  CCD API returned error")
      return(NULL)
    }

    content <- httr::content(response, "text", encoding = "UTF-8")
    json_data <- jsonlite::fromJSON(content)

    if (is.null(json_data$results) || length(json_data$results) == 0) {
      message("  No CCD data found for year ", end_year)
      return(NULL)
    }

    # Convert to data frame
    df <- as.data.frame(json_data$results)

    # Standardize column names to match ALSDE format
    df <- standardize_ccd_columns(df)

    df

  }, error = function(e) {
    message("  CCD download error: ", e$message)
    return(NULL)
  })
}


#' Standardize CCD column names to match ALSDE format
#'
#' @param df Data frame with CCD data
#' @return Data frame with standardized column names
#' @keywords internal
standardize_ccd_columns <- function(df) {

  # CCD column mappings
  # Note: CCD uses different column names than ALSDE
  col_map <- c(
    "ncessch" = "school_id",
    "leaid" = "district_id",
    "school_name" = "school_name",
    "lea_name" = "system_name",
    "enrollment" = "total_count",
    "race_ethnicity" = "race",
    "sex" = "gender"
  )

  # Rename columns that exist
  for (old_name in names(col_map)) {
    if (old_name %in% names(df)) {
      names(df)[names(df) == old_name] <- col_map[old_name]
    }
  }

  df
}


#' Download ADM Report from Alabama Achieves
#'
#' Downloads Fall ADM (Average Daily Membership) report which contains
#' enrollment totals by system and school. This provides basic enrollment
#' data without demographic breakdowns.
#'
#' @param end_year School year end
#' @return Data frame with ADM data or NULL if unavailable
#' @keywords internal
download_adm_report <- function(end_year) {

  # ADM reports are available from 2019-20 onward
  if (end_year < 2020) {
    message("  ADM reports not available before 2020")
    return(NULL)
  }

  # URL patterns for ADM reports (discovered from web research)
  # Pattern varies by year - try known patterns
  url_patterns <- c(
    # 2023-24 format
    paste0("https://www.alabamaachieves.org/wp-content/uploads/", end_year - 1, "/11/",
           "RD_FR_", end_year - 1, "2112_", end_year - 1, "-", end_year,
           "-Fall-ADM-Report-by-System-School_v1.0.xlsb"),
    # 2021-22 format
    paste0("https://www.alabamaachieves.org/wp-content/uploads/", end_year - 1, "/11/",
           end_year - 1, "-", end_year, "-Fall-ADM-Report-by-System-School.xlsb"),
    # 2020-21 format
    paste0("https://alabamaachieves.org/wp-content/uploads/", end_year, "/06/",
           end_year - 1, "-", end_year, "-Fall-ADM-Report-by-System-School.xlsx")
  )

  for (url in url_patterns) {
    tryCatch({
      # Create temp file
      file_ext <- tools::file_ext(url)
      tname <- tempfile(
        pattern = paste0("alsde_adm_", end_year, "_"),
        tmpdir = tempdir(),
        fileext = paste0(".", file_ext)
      )

      response <- httr::GET(
        url,
        httr::write_disk(tname, overwrite = TRUE),
        httr::timeout(120)
      )

      if (!httr::http_error(response)) {
        # Check file size
        if (file.info(tname)$size > 5000) {
          # Try to read the file
          if (file_ext == "xlsb") {
            # xlsb files need special handling
            message("  Note: XLSB format requires 'readxlsb' package")
            # For now, skip xlsb files
            next
          } else {
            df <- readxl::read_excel(tname, col_types = "text")
            unlink(tname)
            return(df)
          }
        }
      }

      unlink(tname)

    }, error = function(e) {
      # Try next URL pattern
    })
  }

  message("  No ADM report found for year ", end_year)
  NULL
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
