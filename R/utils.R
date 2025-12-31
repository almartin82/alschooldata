# ==============================================================================
# Utility Functions
# ==============================================================================

#' Pipe operator
#'
#' See \code{dplyr::\link[dplyr:reexports]{\%>\%}} for details.
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom dplyr %>%
#' @usage lhs \%>\% rhs
#' @param lhs A value or the magrittr placeholder.
#' @param rhs A function call using the magrittr semantics.
#' @return The result of calling `rhs(lhs)`.
NULL


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
