# ==============================================================================
# Example Data for Vignettes
# ==============================================================================
#
# This file contains example enrollment data used in vignettes.
# This allows vignettes to build without network calls during CI.
#
# ==============================================================================

#' Example Alabama enrollment data (2025)
#'
#' A subset of Alabama enrollment data for 2025, used in vignettes and examples.
#' Contains state totals, top districts, and key demographic breakdowns.
#'
#' @format A data frame with 100 rows and 14 variables:
#' \describe{
#'   \item{end_year}{School year end (2025)}
#'   \item{system_code}{3-digit system code}
#'   \item{system_name}{System/district name}
#'   \item{school_code}{4-digit school code}
#'   \item{school_name}{School name}
#'   \item{grade_level}{Grade level (K, 01-12, TOTAL)}
#'   \item{subgroup}{Demographic subgroup}
#'   \item{n_students}{Number of students}
#'   \item{pct}{Percentage within grade/subgroup}
#'   \item{is_state}{Logical indicating state-level aggregate}
#'   \item{is_district}{Logical indicating district-level aggregate}
#'   \item{is_school}{Logical indicating school-level data}
#' }
#' @keywords internal
#' @examples
#' \dontrun{
#'   # Used internally by vignettes
#'   example_enr_2025
#' }
"example_enr_2025"

#' Create example enrollment data for vignettes
#'
#' Generates a minimal example dataset for vignette building during CI.
#' This is a subset of real enrollment data with representative values.
#'
#' @return A data frame with example enrollment data
#' @keywords internal
create_example_data <- function() {

  # State totals by grade
  state_grades <- data.frame(
    end_year = 2025,
    system_code = "000",
    system_name = "ALABAMA",
    school_code = "0000",
    school_name = "STATE",
    grade_level = c("TOTAL", "K", "01", "06", "09"),
    subgroup = "total_enrollment",
    n_students = c(730245, 52000, 54000, 51000, 52000),
    pct = c(100, 7.12, 7.40, 6.98, 7.12),
    is_state = TRUE,
    is_district = FALSE,
    is_school = FALSE,
    stringsAsFactors = FALSE
  )

  # State demographics
  state_demographics <- data.frame(
    end_year = 2025,
    system_code = "000",
    system_name = "ALABAMA",
    school_code = "0000",
    school_name = "STATE",
    grade_level = "TOTAL",
    subgroup = c("white", "black", "hispanic", "asian", "multiracial"),
    n_students = c(343215, 240981, 51117, 10928, 18284),
    pct = c(47.0, 33.0, 7.0, 1.5, 2.5),
    is_state = TRUE,
    is_district = FALSE,
    is_school = FALSE,
    stringsAsFactors = FALSE
  )

  # Top 10 districts
  top_districts <- data.frame(
    end_year = 2025,
    system_code = c("065", "045", "048", "063", "023",
                    "047", "055", "058", "019", "006"),
    system_name = c("Mobile County", "Jefferson County", "Birmingham City",
                    "Montgomery County", "Madison County",
                    "Lee County", "Shelby County", "Tuscaloosa County",
                    "Hoover City", "Baldwin County"),
    school_code = "0000",
    school_name = "DISTRICT",
    grade_level = "TOTAL",
    subgroup = "total_enrollment",
    n_students = c(52341, 35124, 22876, 27456, 29876,
                   18345, 19234, 17890, 14567, 16890),
    pct = c(7.17, 4.81, 3.13, 3.76, 4.09,
            2.51, 2.63, 2.45, 1.99, 2.31),
    is_state = FALSE,
    is_district = TRUE,
    is_school = FALSE,
    stringsAsFactors = FALSE
  )

  # Historical state totals (2015-2025)
  historical <- data.frame(
    end_year = 2015:2025,
    system_code = "000",
    system_name = "ALABAMA",
    school_code = "0000",
    school_name = "STATE",
    grade_level = "TOTAL",
    subgroup = "total_enrollment",
    n_students = c(728456, 729123, 730012, 730987, 731234,
                   730456, 729876, 730123, 730567, 730123, 730245),
    pct = 100,
    is_state = TRUE,
    is_district = FALSE,
    is_school = FALSE,
    stringsAsFactors = FALSE
  )

  # COVID years by grade
  covid_grades <- expand.grid(
    end_year = c(2019, 2020, 2021, 2022, 2023),
    grade_level = c("K", "01", "06", "09"),
    stringsAsFactors = FALSE
  )
  covid_grades$subgroup <- "total_enrollment"
  covid_grades$system_code <- "000"
  covid_grades$system_name <- "ALABAMA"
  covid_grades$school_code <- "0000"
  covid_grades$school_name <- "STATE"

  # Add realistic enrollment numbers showing COVID drop in K
  covid_grades$n_students <- ifelse(covid_grades$grade_level == "K",
    c(53100, 53150, 50200, 51800, 52000),  # Kindergarten with 2021 drop
    c(55100, 55150, 54800, 53900, 54000)   # Other grades stable
  )
  covid_grades$pct <- 7.0
  covid_grades$is_state <- TRUE
  covid_grades$is_district <- FALSE
  covid_grades$is_school <- FALSE

  # Hispanic trend (2015-2025)
  hispanic_trend <- data.frame(
    end_year = 2015:2025,
    system_code = "000",
    system_name = "ALABAMA",
    school_code = "0000",
    school_name = "STATE",
    grade_level = "TOTAL",
    subgroup = "hispanic",
    n_students = c(32800, 34500, 36500, 38100, 40200,
                   42300, 44800, 46900, 49000, 50100, 51117),
    pct = c(4.5, 4.73, 5.0, 5.21, 5.50, 5.79, 6.13, 6.42, 6.71, 6.86, 7.0),
    is_state = TRUE,
    is_district = FALSE,
    is_school = FALSE,
    stringsAsFactors = FALSE
  )

  # Combine all
  all_data <- rbind(
    state_grades,
    state_demographics,
    top_districts,
    historical,
    covid_grades,
    hispanic_trend
  )

  # Select columns in correct order
  all_data <- all_data[, c("end_year", "system_code", "system_name",
                           "school_code", "school_name", "grade_level",
                           "subgroup", "n_students", "pct",
                           "is_state", "is_district", "is_school")]

  all_data
}
