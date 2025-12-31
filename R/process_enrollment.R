# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw ALSDE enrollment data into a
# clean, standardized format.
#
# ==============================================================================

#' Process raw ALSDE enrollment data
#'
#' Transforms raw Federal Report Card or CCD data into a standardized schema
#' combining school and district data.
#'
#' @param raw_data Data frame from get_raw_enr
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_enr <- function(raw_data, end_year) {

  # Detect data source based on column names
  cols <- names(raw_data)

  if (any(grepl("System|School", cols, ignore.case = TRUE))) {
    # Federal Report Card format
    processed <- process_federal_reportcard(raw_data, end_year)
  } else if (any(grepl("ncessch|leaid", cols, ignore.case = TRUE))) {
    # NCES CCD format
    processed <- process_ccd_data(raw_data, end_year)
  } else {
    # Unknown format - try generic processing
    processed <- process_generic(raw_data, end_year)
  }

  # Ensure required columns exist
  required_cols <- c("end_year", "type", "district_id", "campus_id",
                     "district_name", "campus_name")
  for (col in required_cols) {
    if (!col %in% names(processed)) {
      processed[[col]] <- NA_character_
    }
  }

  processed
}


#' Process Federal Report Card data
#'
#' @param df Raw data frame from Federal Report Card
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_federal_reportcard <- function(df, end_year) {

  cols <- names(df)

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  n_rows <- nrow(df)

  # Build result dataframe
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    stringsAsFactors = FALSE
  )

  # System (District) identification
  system_col <- find_col(c("^System$", "SystemCode", "System_Code", "system"))
  if (!is.null(system_col)) {
    result$district_id <- format_system_code(df[[system_col]])
    result$district_name <- NA_character_
  }

  # System name
  system_name_col <- find_col(c("SystemName", "System_Name", "system_name"))
  if (!is.null(system_name_col)) {
    result$district_name <- trimws(df[[system_name_col]])
  }

  # School identification
  school_col <- find_col(c("^School$", "SchoolCode", "School_Code", "school"))
  if (!is.null(school_col)) {
    # Handle school codes - may be numeric or character
    school_codes <- df[[school_col]]
    # Format to 4 digits if numeric
    if (any(!is.na(school_codes) & school_codes != "0000" & school_codes != "0")) {
      result$campus_id <- format_school_code(school_codes)
    } else {
      result$campus_id <- rep(NA_character_, n_rows)
    }
  }

  # School name
  school_name_col <- find_col(c("SchoolName", "School_Name", "school_name"))
  if (!is.null(school_name_col)) {
    result$campus_name <- trimws(df[[school_name_col]])
  }

  # Determine type (State, District, Campus)
  result$type <- determine_row_type(result)

  # Grade level
  grade_col <- find_col(c("^Grade$", "GradeLevel", "grade_level"))
  if (!is.null(grade_col)) {
    result$grade_level <- df[[grade_col]]
  }

  # Total enrollment count
  total_col <- find_col(c("TotalCount", "Total_Count", "total_count",
                          "TotalStudentCount", "enrollment"))
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  }

  # Gender
  male_col <- find_col(c("^Male$", "MaleCount", "male_count"))
  female_col <- find_col(c("^Female$", "FemaleCount", "female_count"))

  if (!is.null(male_col)) {
    result$male <- safe_numeric(df[[male_col]])
  }
  if (!is.null(female_col)) {
    result$female <- safe_numeric(df[[female_col]])
  }

  # Race/Ethnicity columns
  # ALSDE uses these categories: White, Black/African American, Hispanic/Latino,
  # Asian, American Indian/Alaska Native, Native Hawaiian/Pacific Islander,
  # Two or More Races

  race_map <- list(
    white = c("^White$", "WhiteCount", "white_count", "White_Count"),
    black = c("Black", "African.?American", "BlackCount", "black_count"),
    hispanic = c("Hispanic", "Latino", "HispanicCount", "hispanic_count"),
    asian = c("^Asian$", "AsianCount", "asian_count"),
    native_american = c("American.?Indian", "Alaska.?Native", "IndianCount",
                        "american_indian", "native_american"),
    pacific_islander = c("Pacific.?Islander", "Hawaiian", "PacificCount",
                         "pacific_islander"),
    multiracial = c("Two.?or.?More", "Multiple", "MultiracialCount",
                    "two_or_more", "multiracial")
  )

  for (race_name in names(race_map)) {
    col <- find_col(race_map[[race_name]])
    if (!is.null(col)) {
      result[[race_name]] <- safe_numeric(df[[col]])
    }
  }

  # Special populations
  special_map <- list(
    econ_disadv = c("Economically.?Disadvantaged", "EconDisadv", "econ_disadv",
                    "low_income", "free_reduced"),
    lep = c("Limited.?English", "LEP", "ELL", "English.?Learner", "lep"),
    special_ed = c("Disability", "Special.?Ed", "SPED", "IEP", "special_ed",
                   "students_with_disabilities")
  )

  for (pop_name in names(special_map)) {
    col <- find_col(special_map[[pop_name]])
    if (!is.null(col)) {
      result[[pop_name]] <- safe_numeric(df[[col]])
    }
  }

  # If we have demographic percentages instead of counts, convert them
  result <- convert_percentages_to_counts(result)

  # Aggregate to create district and state totals if needed
  result <- ensure_aggregation_levels(result, end_year)

  result
}


#' Process NCES CCD data
#'
#' @param df Raw data frame from CCD
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_ccd_data <- function(df, end_year) {

  cols <- names(df)

  # Helper to find column
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  n_rows <- nrow(df)

  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("Campus", n_rows),  # CCD is school-level
    stringsAsFactors = FALSE
  )

  # District/LEA ID - extract Alabama 3-digit code from full NCES ID
  lea_col <- find_col(c("leaid", "lea_id", "district_id"))
  if (!is.null(lea_col)) {
    # NCES LEA IDs are 7 digits; last 3-5 are the local ID
    # For Alabama, extract the local portion
    full_id <- df[[lea_col]]
    result$district_id <- substr(full_id, nchar(full_id) - 2, nchar(full_id))
  }

  # School ID
  school_col <- find_col(c("ncessch", "school_id", "campus_id"))
  if (!is.null(school_col)) {
    result$campus_id <- df[[school_col]]
  }

  # Names
  lea_name_col <- find_col(c("lea_name", "district_name", "system_name"))
  if (!is.null(lea_name_col)) {
    result$district_name <- trimws(df[[lea_name_col]])
  }

  school_name_col <- find_col(c("school_name", "campus_name"))
  if (!is.null(school_name_col)) {
    result$campus_name <- trimws(df[[school_name_col]])
  }

  # Enrollment total
  enr_col <- find_col(c("enrollment", "total_count", "total"))
  if (!is.null(enr_col)) {
    result$row_total <- safe_numeric(df[[enr_col]])
  }

  # Demographics from CCD - these may be in wide or long format
  # CCD uses race_ethnicity codes: 1=White, 2=Black, 3=Hispanic, etc.
  race_col <- find_col(c("race_ethnicity", "race"))
  if (!is.null(race_col)) {
    # Data is in long format - need to pivot
    result <- pivot_ccd_demographics(result, df, race_col)
  } else {
    # Try wide format columns
    demo_cols <- list(
      white = "white",
      black = "black",
      hispanic = "hispanic",
      asian = "asian",
      native_american = c("american_indian", "native_american"),
      pacific_islander = c("pacific_islander", "hawaiian"),
      multiracial = c("two_or_more", "multiracial")
    )

    for (name in names(demo_cols)) {
      col <- find_col(demo_cols[[name]])
      if (!is.null(col)) {
        result[[name]] <- safe_numeric(df[[col]])
      }
    }
  }

  # Ensure aggregation levels
  result <- ensure_aggregation_levels(result, end_year)

  result
}


#' Pivot CCD demographics from long to wide format
#'
#' @param result Partial result data frame
#' @param df Original CCD data frame
#' @param race_col Name of race column
#' @return Data frame with demographics in wide format
#' @keywords internal
pivot_ccd_demographics <- function(result, df, race_col) {
  # CCD race codes:
  # 1 = White, 2 = Black, 3 = Hispanic, 4 = Asian, 5 = American Indian,
  # 6 = Pacific Islander, 7 = Two or More, 99 = Total

  race_map <- c(
    "1" = "white", "2" = "black", "3" = "hispanic", "4" = "asian",
    "5" = "native_american", "6" = "pacific_islander", "7" = "multiracial"
  )

  # This is a simplified pivot - full implementation would use tidyr::pivot_wider
  # For now, return result as-is
  result
}


#' Process generic data format
#'
#' @param df Raw data frame
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_generic <- function(df, end_year) {
  # Add basic structure
  df$end_year <- end_year
  df$type <- "Campus"
  df$district_id <- NA_character_
  df$campus_id <- NA_character_
  df$district_name <- NA_character_
  df$campus_name <- NA_character_
  df$row_total <- NA_real_

  df
}


#' Determine row type based on IDs
#'
#' @param df Data frame with district_id and campus_id columns
#' @return Character vector of types
#' @keywords internal
determine_row_type <- function(df) {
  type <- rep("Campus", nrow(df))

  # State level: no district or campus ID
  state_rows <- (is.na(df$district_id) | df$district_id == "" |
                   df$district_id == "000") &
    (is.na(df$campus_id) | df$campus_id == "" | df$campus_id == "0000")
  type[state_rows] <- "State"

  # District level: has district ID but no campus ID
  district_rows <- !state_rows &
    (is.na(df$campus_id) | df$campus_id == "" | df$campus_id == "0000")
  type[district_rows] <- "District"

  type
}


#' Convert percentage columns to counts
#'
#' Some ALSDE data exports provide percentages rather than counts.
#' This function converts them using the row_total.
#'
#' @param df Data frame with potential percentage columns
#' @return Data frame with counts
#' @keywords internal
convert_percentages_to_counts <- function(df) {
  # Check if we have row_total
  if (!"row_total" %in% names(df) || all(is.na(df$row_total))) {
    return(df)
  }

  # Demographic columns that might be percentages
  demo_cols <- c("white", "black", "hispanic", "asian",
                 "native_american", "pacific_islander", "multiracial",
                 "male", "female", "econ_disadv", "lep", "special_ed")

  for (col in demo_cols) {
    if (col %in% names(df) && !all(is.na(df[[col]]))) {
      vals <- df[[col]]
      # If values look like percentages (0-100 or 0-1 range)
      if (max(vals, na.rm = TRUE) <= 100 && min(vals, na.rm = TRUE) >= 0) {
        if (max(vals, na.rm = TRUE) <= 1) {
          # 0-1 range - multiply by total
          df[[col]] <- round(vals * df$row_total)
        } else if (max(vals, na.rm = TRUE) > 1 && max(vals, na.rm = TRUE) <= 100) {
          # Check if sum of demographic values >> row_total (indicating percentages)
          # Only convert if values are clearly percentages
          if (median(vals, na.rm = TRUE) > 5 && median(vals, na.rm = TRUE) < 100) {
            # Likely percentages - convert
            df[[col]] <- round(vals / 100 * df$row_total)
          }
        }
      }
    }
  }

  df
}


#' Ensure all aggregation levels exist
#'
#' Creates district and state aggregates if they don't exist in the data.
#'
#' @param df Processed data frame
#' @param end_year School year end
#' @return Data frame with all aggregation levels
#' @keywords internal
ensure_aggregation_levels <- function(df, end_year) {

  # Check if we have district-level data
  has_districts <- any(df$type == "District", na.rm = TRUE)

  # Check if we have state-level data
  has_state <- any(df$type == "State", na.rm = TRUE)

  # Columns to aggregate
  sum_cols <- c("row_total", "white", "black", "hispanic", "asian",
                "native_american", "pacific_islander", "multiracial",
                "male", "female", "econ_disadv", "lep", "special_ed")
  sum_cols <- sum_cols[sum_cols %in% names(df)]

  # Create district aggregates from campus data if needed
  if (!has_districts && "district_id" %in% names(df)) {
    campus_data <- df[df$type == "Campus" & !is.na(df$district_id), ]

    if (nrow(campus_data) > 0) {
      district_agg <- campus_data %>%
        dplyr::group_by(district_id, district_name) %>%
        dplyr::summarize(
          dplyr::across(dplyr::any_of(sum_cols), ~sum(.x, na.rm = TRUE)),
          .groups = "drop"
        ) %>%
        dplyr::mutate(
          end_year = end_year,
          type = "District",
          campus_id = NA_character_,
          campus_name = NA_character_
        )

      df <- dplyr::bind_rows(df, district_agg)
    }
  }

  # Create state aggregate from district data
  if (!has_state) {
    district_data <- df[df$type == "District", ]

    if (nrow(district_data) > 0) {
      state_agg <- district_data %>%
        dplyr::summarize(
          dplyr::across(dplyr::any_of(sum_cols), ~sum(.x, na.rm = TRUE))
        ) %>%
        dplyr::mutate(
          end_year = end_year,
          type = "State",
          district_id = NA_character_,
          campus_id = NA_character_,
          district_name = NA_character_,
          campus_name = NA_character_
        )

      df <- dplyr::bind_rows(state_agg, df)
    }
  }

  df
}
