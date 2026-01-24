# ==============================================================================
# Assessment Data Function Documentation
# ==============================================================================
#
# This file contains roxygen2 documentation for assessment data functions.
# Documentation is split into separate files to avoid circular dependencies.
#
# ==============================================================================

#' Get available ACAP assessment years
#'
#' Returns the minimum and maximum years available for ACAP Reading assessment data.
#'
#' @return List with components:
#'   \item{min_year}{First available year (2022)}
#'   \item{max_year}{Last available year (2025)}
#' @export
#' @examples
#' get_available_assess_years()
#'
#' # Returns: list(min_year = 2022, max_year = 2025)
get_available_assess_years <- function() {
  list(
    min_year = 2022,
    max_year = 2025
  )
}


#' Convert assessment data to tidy format
#'
#' Converts wide-format assessment data into long format with proficiency
#' metrics as columns.
#'
#' @param df Processed assessment data frame from process_assess()
#' @return Tidy data frame with proficiency_rate and proficiency_count columns
#' @keywords internal
tidy_assess <- function(df) {

  # Proficiency = at or above grade level
  df <- df |>
    dplyr::mutate(
      proficiency_rate = .data$pct_at_or_above_grade_level / 100,
      proficiency_count = .data$at_or_above_grade_level,
      n_tested = .data$total_tested
    )

  # Select columns for tidy output
  tidy_df <- df |>
    dplyr::select(
      end_year = .data$end_year,
      system_code = .data$system_code,
      system_name = .data$system_name,
      school_code = .data$school_code,
      school_name = .data$school_name,
      subject = .data$subject,
      grade = .data$grade,
      grade_level = .data$grade_level,
      n_tested = .data$n_tested,
      proficiency_count = .data$proficiency_count,
      proficiency_rate = .data$proficiency_rate,
      is_state = .data$is_state,
      is_district = .data$is_district,
      is_school = .data$is_school
    )

  tidy_df
}


#' Add district and state aggregates to assessment data
#'
#' Calculates district-level and state-level aggregates from school-level data.
#' This ensures that totals match the sum of constituent schools.
#'
#' @param df Tidy assessment data frame
#' @return Data frame with added district and state aggregates
#' @keywords internal
id_assess_aggs <- function(df) {

  # Start with school-level data only
  school_data <- df |>
    dplyr::filter(.data$is_school)

  # Calculate district aggregates from school data
  district_agg <- school_data |>
    dplyr::group_by(
      end_year = .data$end_year,
      system_code = .data$system_code,
      system_name = .data$system_name,
      subject = .data$subject,
      grade = .data$grade,
      grade_level = .data$grade_level
    ) |>
    dplyr::summarise(
      n_tested = sum(.data$n_tested, na.rm = TRUE),
      proficiency_count = sum(.data$proficiency_count, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::filter(.data$n_tested > 0) |>
    dplyr::mutate(
      proficiency_rate = .data$proficiency_count / .data$n_tested,
      school_code = "0000",
      school_name = .data$system_name,
      is_state = FALSE,
      is_district = TRUE,
      is_school = FALSE
    )

  # Calculate state aggregates from school data
  state_agg <- school_data |>
    dplyr::group_by(
      end_year = .data$end_year,
      subject = .data$subject,
      grade = .data$grade,
      grade_level = .data$grade_level
    ) |>
    dplyr::summarise(
      n_tested = sum(.data$n_tested, na.rm = TRUE),
      proficiency_count = sum(.data$proficiency_count, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::filter(.data$n_tested > 0) |>
    dplyr::mutate(
      proficiency_rate = .data$proficiency_count / .data$n_tested,
      system_code = "000",
      system_name = "Alabama State Department of Education",
      school_code = "0000",
      school_name = "Alabama State Department of Education",
      is_state = TRUE,
      is_district = FALSE,
      is_school = FALSE
    )

  # Combine original data with aggregates
  result <- df |>
    dplyr::bind_rows(district_agg) |>
    dplyr::bind_rows(state_agg) |>
    dplyr::arrange(.data$end_year, .data$system_code, .data$school_code, .data$grade) |>
    dplyr::filter(!is.na(.data$end_year))

  result
}
