# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw ALSDE enrollment data into a
# clean, standardized format.
#
# The ALSDE Federal Report Card CSV has a multi-dimensional structure:
# - Rows: School x Grade x Gender x Ethnicity x SubPopulation combinations
# - Columns: Year, System, School, Grade, Gender, Ethnicity, Sub Population,
#   Total Student Count, plus race/ethnicity counts and percentages
#
# For our wide format, we extract the "base" rows where all filter dimensions
# are set to "All" (All Grades, All Gender, All Ethnicity, All SubPopulation),
# giving us one row per school/district with race breakdown in columns.
# Grade-level and sub-population data are extracted from the appropriate
# dimension-specific rows.
#
# ==============================================================================

#' Process raw ALSDE enrollment data
#'
#' Transforms raw Federal Report Card data into a standardized schema.
#'
#' @param raw_data Data frame from get_raw_enr
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_enr <- function(raw_data, end_year) {
  process_federal_reportcard(raw_data, end_year)
}


#' Process Federal Report Card data
#'
#' Extracts enrollment data from the multi-dimensional ALSDE CSV format.
#' The raw data has filter dimensions (Grade, Gender, Ethnicity, Sub Population)
#' as columns with race/ethnicity breakdowns in value columns.
#'
#' @param df Raw data frame from Federal Report Card
#' @param end_year School year end
#' @return Processed data frame in wide format
#' @keywords internal
process_federal_reportcard <- function(df, end_year) {

  # --- Extract base enrollment (one row per entity) ---
  # Filter to "All" for all dimensions to get totals with race breakdown
  base <- df[
    df$Grade == "All Grades" &
    df$Gender == "All Gender" &
    df$Ethnicity == "All Ethnicity" &
    df[["Sub Population"]] == "All SubPopulation",
  ]

  if (nrow(base) == 0) {
    stop("No base enrollment rows found (All Grades/Gender/Ethnicity/SubPopulation). ",
         "The ALSDE data format may have changed.")
  }

  # Deduplicate exact duplicate rows (some charter schools appear twice)
  base <- base[!duplicated(base), ]

  # Handle edge case: same System == School name with different counts
  # (e.g., Legacy Prep has a 501 district total and 291 school-level row,
  # both with System == School). Keep the max-count row as the district total
  # and reclassify the smaller row as a campus.
  sys_school_key <- paste(base$System, base$School, sep = "|")
  dupe_keys <- sys_school_key[duplicated(sys_school_key)]

  if (length(dupe_keys) > 0) {
    for (dk in unique(dupe_keys)) {
      idx <- which(sys_school_key == dk)
      counts <- safe_numeric(base[["Total Student Count"]][idx])
      # Keep the row with the highest count
      max_idx <- idx[which.max(counts)]
      # Mark other rows: change School name to distinguish as a sub-school
      other_idx <- setdiff(idx, max_idx)
      for (oi in other_idx) {
        base$School[oi] <- paste0(base$School[oi], " (school)")
      }
    }
  }

  # Build result data frame
  result <- data.frame(
    end_year = rep(end_year, nrow(base)),
    district_name = trimws(base$System),
    campus_name = trimws(base$School),
    stringsAsFactors = FALSE
  )

  # Determine entity type
  # System == School (after dedup) means district/system level
  result$type <- ifelse(
    result$district_name == result$campus_name,
    "District",
    "Campus"
  )

  # Mark the state-level row (ALSDE reports state total as a "system")
  state_row <- grepl("Alabama State Department of Education",
                     result$district_name, ignore.case = TRUE) &
    result$district_name == result$campus_name
  result$type[state_row] <- "State"

  # Total enrollment
  result$row_total <- safe_numeric(base[["Total Student Count"]])

  # Race/ethnicity columns (counts)
  result$asian <- safe_numeric(base$Asian)
  result$black <- safe_numeric(base[["Black or African American"]])
  result$native_american <- safe_numeric(base[["American Indian / Alaska Native"]])
  result$pacific_islander <- safe_numeric(base[["Native Hawaiian / Pacific Islander"]])
  result$white <- safe_numeric(base$White)
  result$multiracial <- safe_numeric(base[["Two or more races"]])

  # --- Extract Hispanic/Latino counts from Ethnicity dimension ---
  result$hispanic <- extract_dimension_counts(
    df, result, "Ethnicity", "Hispanic/Latino"
  )

  # --- Extract gender counts ---
  result$male <- extract_dimension_counts(df, result, "Gender", "Male")
  result$female <- extract_dimension_counts(df, result, "Gender", "Female")

  # --- Extract special population counts ---
  result$econ_disadv <- extract_dimension_counts(
    df, result, "Sub Population", "Economically Disadvantaged"
  )
  result$lep <- extract_dimension_counts(
    df, result, "Sub Population", "Students with Limited English Proficiency"
  )
  result$special_ed <- extract_dimension_counts(
    df, result, "Sub Population", "Students with Disabilities"
  )

  # --- Extract grade-level enrollment ---
  grade_map <- c(
    "Pre K" = "grade_pk",
    "Grade K" = "grade_k",
    "Grade 01" = "grade_01",
    "Grade 02" = "grade_02",
    "Grade 03" = "grade_03",
    "Grade 04" = "grade_04",
    "Grade 05" = "grade_05",
    "Grade 06" = "grade_06",
    "Grade 07" = "grade_07",
    "Grade 08" = "grade_08",
    "Grade 09" = "grade_09",
    "Grade 10" = "grade_10",
    "Grade 11" = "grade_11",
    "Grade 12" = "grade_12"
  )

  for (raw_grade in names(grade_map)) {
    col_name <- grade_map[raw_grade]
    result[[col_name]] <- extract_dimension_counts(
      df, result, "Grade", raw_grade
    )
  }

  # Generate simple IDs (not available in raw data - ALSDE uses names)
  result$district_id <- NA_character_
  result$campus_id <- NA_character_

  result
}


#' Extract counts from a specific dimension filter
#'
#' Helper to match dimension-specific rows (e.g., Grade = "Grade 09") back
#' to the base result frame using System + School name matching.
#'
#' @param raw_df Full raw data frame
#' @param result_df Result data frame with district_name and campus_name
#' @param dimension Column name of the dimension (e.g., "Grade", "Gender")
#' @param value Value to filter on (e.g., "Grade 09", "Male")
#' @return Numeric vector of counts aligned to result_df rows
#' @keywords internal
extract_dimension_counts <- function(raw_df, result_df, dimension, value) {

  # Build filter: all dimensions "All" except the target dimension
  dim_filters <- list(
    Grade = "All Grades",
    Gender = "All Gender",
    Ethnicity = "All Ethnicity",
    `Sub Population` = "All SubPopulation"
  )
  dim_filters[[dimension]] <- value

  # Apply filters
  filtered <- raw_df[
    raw_df$Grade == dim_filters$Grade &
    raw_df$Gender == dim_filters$Gender &
    raw_df$Ethnicity == dim_filters$Ethnicity &
    raw_df[["Sub Population"]] == dim_filters[["Sub Population"]],
  ]

  if (nrow(filtered) == 0) return(rep(NA_real_, nrow(result_df)))

  # Deduplicate
  filtered <- filtered[!duplicated(filtered[, c("System", "School", "Total Student Count")]), ]

  # Match by System + School name
  filtered_key <- paste(trimws(filtered$System), trimws(filtered$School), sep = "|")
  result_key <- paste(result_df$district_name, result_df$campus_name, sep = "|")

  # For campus_name that was renamed with " (school)" suffix during dedup,

  # try matching without the suffix
  matched_idx <- match(result_key, filtered_key)

  # For unmatched rows with " (school)" suffix, try the original name
  unmatched <- is.na(matched_idx) & grepl(" \\(school\\)$", result_df$campus_name)
  if (any(unmatched)) {
    orig_key <- paste(
      result_df$district_name[unmatched],
      sub(" \\(school\\)$", "", result_df$campus_name[unmatched]),
      sep = "|"
    )
    # For these, match to the row with the LOWEST count (school-level, not district)
    for (i in which(unmatched)) {
      ok <- orig_key[sum(unmatched[1:i])]
      candidates <- which(filtered_key == ok)
      if (length(candidates) > 1) {
        # Pick the one with the smaller count (school-level)
        counts <- safe_numeric(filtered[["Total Student Count"]][candidates])
        matched_idx[i] <- candidates[which.min(counts)]
      } else if (length(candidates) == 1) {
        matched_idx[i] <- candidates
      }
    }
  }

  safe_numeric(filtered[["Total Student Count"]])[matched_idx]
}
