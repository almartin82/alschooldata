# ==============================================================================
# Assessment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw assessment data from ALSDE
# into a standardized format.
#
# ==============================================================================

#' Process raw ACAP assessment data
#'
#' Standardizes column names and data types from raw ACAP assessment download.
#'
#' @param raw_data Raw data frame from get_raw_assess()
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_assess <- function(raw_data, end_year) {

  message("Processing ACAP assessment data...")

  # Standardize column names
  # Raw files have slightly different column names across years
  names(raw_data) <- tolower(names(raw_data))
  names(raw_data) <- gsub(" ", "_", names(raw_data))
  names(raw_data) <- gsub("[^a-z0-9_]", "", names(raw_data))

  # Map to standard column names
  col_mapping <- c(
    "system_code" = "system_code",
    "system_name" = "system_name",
    "school_code" = "school_code",
    "school_name" = "school_name",
    "tested_grade" = "grade",
    "test_grade" = "grade",
    "total_tested" = "total_tested",
    "total_below_grade_level" = "below_grade_level",
    "total_on_or_above_grade_level" = "at_or_above_grade_level",
    "percentage_for_below_grade_level" = "pct_below_grade_level",
    "percentage_for_on_or_above_grade_level" = "pct_at_or_above_grade_level"
  )

  # Rename columns based on mapping
  for (old_name in names(col_mapping)) {
    if (old_name %in% names(raw_data)) {
      names(raw_data)[names(raw_data) == old_name] <- col_mapping[old_name]
    }
  }

  # Ensure required columns exist
  required_cols <- c("system_code", "system_name", "school_code", "school_name")
  missing_cols <- setdiff(required_cols, names(raw_data))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }

  # Handle 2021-2022 file which doesn't have grade column
  if (end_year == 2022 && !"grade" %in% names(raw_data)) {
    raw_data$grade <- NA
  }

  # Clean data: remove rows with suppressed data (*)
  raw_data <- raw_data[raw_data$total_tested != "*", ]

  # Convert numeric columns
  numeric_cols <- c("total_tested", "below_grade_level", "at_or_above_grade_level",
                    "pct_below_grade_level", "pct_at_or_above_grade_level")

  for (col in numeric_cols) {
    if (col %in% names(raw_data)) {
      raw_data[[col]] <- as.numeric(raw_data[[col]])
    }
  }

  # Convert grade to character (some may be "02", "03")
  if ("grade" %in% names(raw_data)) {
    raw_data$grade <- as.character(raw_data$grade)
    # Pad single digits with leading zero
    raw_data$grade <- ifelse(nchar(raw_data$grade) == 1,
                             paste0("0", raw_data$grade),
                             raw_data$grade)
  }

  # Add grade_level column (map to standard names)
  if ("grade" %in% names(raw_data)) {
    raw_data$grade_level <- dplyr::case_when(
      raw_data$grade == "02" ~ "Grade 2",
      raw_data$grade == "03" ~ "Grade 3",
      TRUE ~ raw_data$grade
    )
  }

  # Add subject column
  raw_data$subject <- "Reading"

  # Add geographic level flags
  raw_data$is_state <- raw_data$system_code == "000" & raw_data$school_code == "0000"
  raw_data$is_district <- raw_data$school_code == "0000" & !raw_data$is_state
  raw_data$is_school <- raw_data$school_code != "0000"

  # Remove state aggregate row (keep in separate summary)
  # Keep only district and school level
  df <- raw_data[!raw_data$is_state, ]

  # Ensure school_code is character with leading zeros
  df$school_code <- sprintf("%04s", df$school_code)

  # Ensure system_code is character with leading zeros
  df$system_code <- sprintf("%03s", df$system_code)

  # Select and order columns
  output_cols <- c(
    "end_year",
    "system_code",
    "system_name",
    "school_code",
    "school_name",
    "subject",
    "grade",
    "grade_level",
    "total_tested",
    "below_grade_level",
    "at_or_above_grade_level",
    "pct_below_grade_level",
    "pct_at_or_above_grade_level",
    "is_state",
    "is_district",
    "is_school"
  )

  # Keep only columns that exist
  output_cols <- output_cols[output_cols %in% names(df)]

  df <- df[, output_cols]

  df
}
