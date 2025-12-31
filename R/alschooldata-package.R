#' alschooldata: Fetch and Process Alabama School Data
#'
#' Downloads and processes school data from the Alabama State Department of
#' Education (ALSDE). Provides functions for fetching enrollment data from
#' the ALSDE Federal Report Card and transforming it into tidy format for
#' analysis. Supports data from 2015 to present.
#'
#' @section Main functions:
#' \describe{
#'   \item{\code{\link{fetch_enr}}}{Fetch enrollment data for a school year}
#'   \item{\code{\link{fetch_enr_multi}}}{Fetch enrollment data for multiple years}
#'   \item{\code{\link{tidy_enr}}}{Transform wide data to tidy (long) format}
#'   \item{\code{\link{id_enr_aggs}}}{Add aggregation level flags}
#'   \item{\code{\link{enr_grade_aggs}}}{Create grade-level aggregations}
#'   \item{\code{\link{get_available_years}}}{Get the range of available years}
#' }
#'
#' @section Cache functions:
#' \describe{
#'   \item{\code{\link{cache_status}}}{View cached data files}
#'   \item{\code{\link{clear_cache}}}{Remove cached data files}
#' }
#'
#' @section ID System:
#' Alabama uses a hierarchical system of codes:
#' \itemize{
#'   \item System (District) Codes: 3-digit codes (e.g., "001" = Autauga County)
#'   \item School Codes: 4-digit codes unique within each system
#' }
#'
#' @section Data Source:
#' Data is sourced exclusively from the Alabama State Department of Education:
#' \itemize{
#'   \item Federal Report Card Student Demographics:
#'     \url{https://reportcard.alsde.edu/SupportingData_StudentDemographics.aspx}
#' }
#'
#' @section Available Years:
#' The ALSDE Federal Report Card provides enrollment data from 2015 to 2025
#' (school years 2014-15 through 2024-25). Data includes school-level enrollment
#' with demographic breakdowns by race/ethnicity, gender, and special populations.
#'
#' @docType package
#' @name alschooldata-package
#' @aliases alschooldata
#' @keywords internal
"_PACKAGE"

#' Pipe operator
#'
#' See \code{magrittr::\link[magrittr:pipe]{\%>\%}} for details.
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
