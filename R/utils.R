# ==============================================================================
# Utility Functions
# ==============================================================================

#' @importFrom rlang .data
NULL


#' Get Available Years
#'
#' Returns the range of years for which enrollment data is available.
#'
#' Data is sourced from the ALSDE Federal Report Card Student Demographics
#' system, which provides data from the 2014-15 school year (end_year = 2015)
#' to the present.
#'
#' @return Named list with min_year and max_year
#' @export
#' @examples
#' get_available_years()
get_available_years <- function() {
  list(
    min_year = 2015L,
    max_year = 2025L
  )
}


#' School Year Label
#'
#' Converts an end year integer to a school year label string.
#'
#' @param end_year Integer end year (e.g., 2024)
#' @return Character school year label (e.g., "2023-24")
#' @export
#' @examples
#' school_year_label(2024)  # Returns "2023-24"
#' school_year_label(2021)  # Returns "2020-21"
school_year_label <- function(end_year) {
  start_year <- end_year - 1
  end_yy <- sprintf("%02d", end_year %% 100)
  paste0(start_year, "-", end_yy)
}


#' Parse School Year Label
#'
#' Converts a school year label string to an end year integer.
#'
#' @param label Character school year label (e.g., "2023-24")
#' @return Integer end year (e.g., 2024)
#' @export
#' @examples
#' parse_school_year("2023-24")  # Returns 2024
#' parse_school_year("2020-21")  # Returns 2021
parse_school_year <- function(label) {
  # Handle both "2023-24" and "2023-2024" formats
  parts <- strsplit(label, "-")[[1]]

  if (length(parts) != 2) {
    stop("Invalid school year format. Expected format: '2023-24' or '2023-2024'")
  }

  start_year <- as.integer(parts[1])
  end_part <- parts[2]

  if (nchar(end_part) == 2) {
    # Two-digit year
    century <- floor(start_year / 100) * 100
    end_year <- century + as.integer(end_part)

    # Handle century rollover (e.g., "1999-00")
    if (end_year < start_year) {
      end_year <- end_year + 100
    }
  } else {
    # Four-digit year
    end_year <- as.integer(end_part)
  }

  end_year
}


#' Convert to numeric, handling suppression markers
#'
#' ALSDE uses various markers for suppressed data (*, <=10, etc.)
#' and may use commas in large numbers.
#'
#' @param x Vector to convert
#' @return Numeric vector with NA for non-numeric values
#' @keywords internal
safe_numeric <- function(x) {
  # Remove commas and whitespace
  x <- gsub(",", "", x)
  x <- trimws(x)

  # Handle common suppression markers
  x[x %in% c("*", ".", "-", "-1", "<5", "<=10", "N/A", "NA", "", "~")] <- NA_character_

  suppressWarnings(as.numeric(x))
}


#' Format Alabama system code to 3 digits
#'
#' @param code System code to format
#' @return Character vector with zero-padded 3-digit codes
#' @keywords internal
format_system_code <- function(code) {
  code <- as.character(code)
  code <- gsub("[^0-9]", "", code)
  sprintf("%03d", as.integer(code))
}


#' Format Alabama school code to 4 digits
#'
#' @param code School code to format
#' @return Character vector with zero-padded 4-digit codes
#' @keywords internal
format_school_code <- function(code) {
  code <- as.character(code)
  code <- gsub("[^0-9]", "", code)
  sprintf("%04d", as.integer(code))
}


#' Create combined Alabama ID
#'
#' Combines system code and school code into a single identifier
#'
#' @param system_code System (district) code
#' @param school_code School code
#' @return Character vector with combined IDs (e.g., "001-0010")
#' @keywords internal
create_al_id <- function(system_code, school_code) {
  paste0(format_system_code(system_code), "-", format_school_code(school_code))
}


#' Map school year to ALSDE report year
#'
#' ALSDE uses end year (e.g., 2024 for 2023-24 school year)
#'
#' @param end_year End year of school year (e.g., 2024 for 2023-24)
#' @return Same year (passthrough for consistency with other state packages)
#' @keywords internal
get_report_year <- function(end_year) {
  end_year
}


#' Format school year for display
#'
#' @param end_year End year of school year
#' @return Formatted string (e.g., "2023-2024")
#' @keywords internal
format_school_year <- function(end_year) {
  paste0(end_year - 1, "-", end_year)
}
