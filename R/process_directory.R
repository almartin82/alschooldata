# ==============================================================================
# Directory Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw ALSDE directory data into a
# clean, standardized format.
#
# Data is sourced exclusively from the ALSDE Education Directory.
#
# ==============================================================================

#' Process raw ALSDE directory data
#'
#' Combines and standardizes school and superintendent directory data into
#' a single data frame with consistent column names.
#'
#' @param raw_data List with 'schools' and 'superintendents' data frames
#'   from get_raw_directory()
#' @return Processed data frame with standardized columns
#' @keywords internal
process_directory <- function(raw_data) {

  message("Processing ALSDE directory data...")

  schools <- process_school_directory(raw_data$schools)
  supts <- process_superintendent_directory(raw_data$superintendents)

  # Merge superintendent info into school data
  # Each superintendent row has a system (district) name
  supt_lookup <- supts |>
    dplyr::select(
      district_name = "district_name",
      superintendent_name = "superintendent_name"
    ) |>
    dplyr::distinct()

  # Join superintendent names to school data
  result <- schools |>
    dplyr::left_join(supt_lookup, by = "district_name")

  # Also create district-level rows from superintendent data
  district_rows <- supts |>
    dplyr::mutate(
      entity_type = "District",
      school_name = NA_character_,
      grades_served = NA_character_
    ) |>
    dplyr::rename(
      principal_name = "superintendent_name"
    ) |>
    dplyr::mutate(superintendent_name = .data$principal_name)

  # Ensure matching columns
  common_cols <- intersect(names(result), names(district_rows))
  result <- dplyr::bind_rows(
    result[, common_cols],
    district_rows[, common_cols]
  )

  # Add entity flags
  result <- result |>
    dplyr::mutate(
      is_district = .data$entity_type == "District",
      is_school = .data$entity_type == "School"
    )

  # Add state row
  state_row <- data.frame(
    district_name = "Alabama State Department of Education",
    school_name = NA_character_,
    entity_type = "State",
    principal_name = NA_character_,
    address = NA_character_,
    city = "Montgomery",
    state = "AL",
    zip = "36104",
    phone = NA_character_,
    website = "https://www.alsde.edu",
    grades_served = NA_character_,
    superintendent_name = NA_character_,
    is_district = FALSE,
    is_school = FALSE,
    stringsAsFactors = FALSE
  )

  result <- dplyr::bind_rows(state_row, result) |>
    dplyr::mutate(
      is_state = .data$entity_type == "State"
    )

  # Ensure column order
  col_order <- c(
    "district_name", "school_name", "entity_type",
    "principal_name", "superintendent_name",
    "address", "city", "state", "zip", "phone", "website",
    "grades_served",
    "is_state", "is_district", "is_school"
  )
  col_order <- col_order[col_order %in% names(result)]

  result[, col_order]
}


#' Process raw school directory CSV
#'
#' Standardizes column names from the public school CSV export.
#'
#' @param df Raw data frame from DevExpress CSV export
#' @return Processed data frame
#' @keywords internal
process_school_directory <- function(df) {

  # Standardize column names (case-insensitive matching)
  cols <- names(df)

  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  result <- data.frame(
    entity_type = rep("School", nrow(df)),
    stringsAsFactors = FALSE
  )

  # System Name -> district_name
  col <- find_col(c("^System.?Name$", "^System$"))
  if (!is.null(col)) {
    result$district_name <- trimws(df[[col]])
  }

  # School Name -> school_name
  col <- find_col(c("^School.?Name$", "^School$"))
  if (!is.null(col)) {
    result$school_name <- trimws(df[[col]])
  }

  # Administrator -> principal_name
  col <- find_col(c("^Administrator$", "^Principal$"))
  if (!is.null(col)) {
    result$principal_name <- trimws(df[[col]])
  }

  # Physical Address -> address
  col <- find_col(c("^Street$", "^Address$", "^Physical.?Address$"))
  if (!is.null(col)) {
    result$address <- trimws(df[[col]])
  }

  # City
  col <- find_col(c("^City$"))
  if (!is.null(col)) {
    result$city <- trimws(df[[col]])
  }

  # State
  col <- find_col(c("^State$"))
  if (!is.null(col)) {
    result$state <- trimws(df[[col]])
  }

  # ZIP Code
  col <- find_col(c("^ZIP.?Code$", "^ZIP$", "^Zip$"))
  if (!is.null(col)) {
    result$zip <- trimws(gsub("-\\s*$", "", df[[col]]))
  }

  # Phone
  col <- find_col(c("^Phone$", "^Telephone$"))
  if (!is.null(col)) {
    result$phone <- trimws(df[[col]])
  }

  # Website
  col <- find_col(c("^Website$", "^Web$", "^URL$"))
  if (!is.null(col)) {
    result$website <- trimws(df[[col]])
  }

  # Grade Range
  col <- find_col(c("^Grade.?Range$", "^Grades$", "^Grade.?Span$"))
  if (!is.null(col)) {
    result$grades_served <- trimws(df[[col]])
  }

  # Remove duplicate rows
  # The DevExpress export may include duplicate rows for schools with
  # multiple administrators. Keep only unique school entries.
  result <- result |>
    dplyr::distinct(
      .data$district_name, .data$school_name, .data$address,
      .keep_all = TRUE
    )

  result
}


#' Process raw superintendent directory CSV
#'
#' Standardizes column names from the superintendent CSV export.
#'
#' @param df Raw data frame from DevExpress CSV export
#' @return Processed data frame
#' @keywords internal
process_superintendent_directory <- function(df) {

  cols <- names(df)

  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  result <- data.frame(
    entity_type = rep("District", nrow(df)),
    stringsAsFactors = FALSE
  )

  # System Name -> district_name
  col <- find_col(c("^System.?Name$", "^System$"))
  if (!is.null(col)) {
    result$district_name <- trimws(df[[col]])
  }

  # Administrator -> superintendent_name
  col <- find_col(c("^Administrator$", "^Superintendent$"))
  if (!is.null(col)) {
    result$superintendent_name <- trimws(df[[col]])
  }

  # Physical Address -> address
  col <- find_col(c("^Street$", "^Address$", "^Physical.?Address$"))
  if (!is.null(col)) {
    result$address <- trimws(df[[col]])
  }

  # City
  col <- find_col(c("^City$"))
  if (!is.null(col)) {
    result$city <- trimws(df[[col]])
  }

  # State
  col <- find_col(c("^State$"))
  if (!is.null(col)) {
    result$state <- trimws(df[[col]])
  }

  # ZIP Code
  col <- find_col(c("^ZIP.?Code$", "^ZIP$", "^Zip$"))
  if (!is.null(col)) {
    result$zip <- trimws(gsub("-\\s*$", "", df[[col]]))
  }

  # Phone
  col <- find_col(c("^Phone$", "^Telephone$"))
  if (!is.null(col)) {
    result$phone <- trimws(df[[col]])
  }

  # Website
  col <- find_col(c("^Website$", "^Web$", "^URL$"))
  if (!is.null(col)) {
    result$website <- trimws(df[[col]])
  }

  result
}
