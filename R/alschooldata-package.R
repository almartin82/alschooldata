#' alschooldata: Fetch and Process Alabama School Data
#'
#' Downloads and processes school data from the Alabama State Department of
#' Education (ALSDE). Provides functions for fetching enrollment data from the
#' Federal Report Card system and transforming it into tidy format for analysis.
#'
#' @section Main functions:
#' \describe{
#'   \item{\code{\link{fetch_enr}}}{Fetch enrollment data for a school year}
#'   \item{\code{\link{fetch_enr_multi}}}{Fetch enrollment data for multiple years}
#'   \item{\code{\link{tidy_enr}}}{Transform wide data to tidy (long) format}
#'   \item{\code{\link{id_enr_aggs}}}{Add aggregation level flags}
#'   \item{\code{\link{enr_grade_aggs}}}{Create grade-level aggregations}
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
#' @section Data Sources:
#' Data is sourced from the Alabama State Department of Education's Federal
#' Report Card system:
#' \itemize{
#'   \item Federal Report Card: \url{https://reportcard.alsde.edu/}
#'   \item Alabama Achieves: \url{https://www.alabamaachieves.org/reports-data/}
#' }
#'
#' @section Data Eras:
#' Alabama enrollment data is available in two main eras:
#' \itemize{
#'   \item Federal Report Card Era (2015-present): Detailed demographics via
#'     the ALSDE Federal Report Card system with CSV export capability
#'   \item ADM Reports (2019-present): Fall enrollment reports via Alabama
#'     Achieves with total enrollment by system and school
#' }
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
