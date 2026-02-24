# Alabama Assessment Data Implementation Summary

**Package:** alschooldata **Task:** Expand assessment data, ALL historic
assessments given, include K-8 and high school (excluding SAT/ACT)
**Date:** 2026-01-11 **Status:** PARTIALLY COMPLETED - Reading/ELA
assessments only

------------------------------------------------------------------------

## Executive Summary

Assessment data has been successfully implemented for Alabama, but with
significant limitations due to data availability constraints. Only
**ACAP Reading/ELA** assessments are available in downloadable Excel
format from the Alabama State Department of Education.

### Available Data

- **Years:** 2021-2022, 2022-2023, 2023-2024, 2024-2025 (4 years)
- **Subject:** Reading/ELA only
- **Grades:** 2-3 only (early literacy assessment grades)
- **Level:** School, district, and state-level data

### NOT Available

- ACAP Math assessments (not available as downloadable Excel)
- ACAP Science assessments (not available as downloadable Excel)
- High school assessments (excluded per user requirements - no SAT/ACT)
- Historical ACT Aspire data (2015-2019) - not available in downloadable
  format

------------------------------------------------------------------------

## Implementation Details

### Files Created

1.  **R/get_raw_assessment.R** (5.4 KB)
    - [`get_raw_assess()`](https://almartin82.github.io/alschooldata/reference/get_raw_assess.md):
      Downloads raw ACAP assessment Excel files
    - [`download_acap_assessment()`](https://almartin82.github.io/alschooldata/reference/download_acap_assessment.md):
      Downloads from Alabama Achieves website
    - [`get_available_assess_years()`](https://almartin82.github.io/alschooldata/reference/get_available_assess_years.md):
      Returns available year range (2022-2025)
    - Uses
      [`retry_with_backoff()`](https://almartin82.github.io/alschooldata/reference/retry_with_backoff.md)
      for robust HTTP requests
2.  **R/process_assessment.R** (4.4 KB)
    - [`process_assess()`](https://almartin82.github.io/alschooldata/reference/process_assess.md):
      Standardizes column names and data types
    - Handles different file structures across years
    - Adds geographic level flags (state/district/school)
    - Removes suppressed data (\*)
3.  **R/tidy_assessment.R** (documentation placeholder)
    - [`tidy_assess()`](https://almartin82.github.io/alschooldata/reference/tidy_assess.md):
      Converts to long format with proficiency metrics
    - [`id_assess_aggs()`](https://almartin82.github.io/alschooldata/reference/id_assess_aggs.md):
      Calculates district and state aggregates
4.  **R/fetch_assessment-documentation.R** (documentation)
    - Fully documented functions with roxygen2
    - Includes examples and export declarations
5.  **R/fetch_assessment.R** (4.3 KB)
    - [`fetch_assess()`](https://almartin82.github.io/alschooldata/reference/fetch_assess.md):
      Public API for single-year assessment data
    - [`fetch_assess_multi()`](https://almartin82.github.io/alschooldata/reference/fetch_assess_multi.md):
      Public API for multi-year assessment data
    - Supports caching (assess_tidy, assess_wide)
    - Tidy/wide format options

### Files Modified

1.  **DESCRIPTION**
    - Added `readxl` dependency for Excel file reading
2.  **NAMESPACE**
    - Added exports: `fetch_assess`, `fetch_assess_multi`,
      `get_available_assess_years`, `id_assess_aggs`, `tidy_assess`
3.  **CLAUDE.md**
    - Added Assessment Data section
    - Documented data limitations
    - Added assessment test coverage description
4.  **tests/testthat/test-pipeline-live.R**
    - Added 7 new assessment tests
    - Tests cover: year validation, data fetching, data quality,
      aggregation, multi-year fetch

------------------------------------------------------------------------

## Data Source URLs

The following Excel files are downloaded from Alabama Achieves:

- **2021-2022:**
  <https://www.alabamaachieves.org/wp-content/uploads/2022/07/2021-2022-ACAP-Reading.xlsx>
- **2022-2023:**
  <https://www.alabamaachieves.org/wp-content/uploads/2023/06/RD_SP_202368_2022-2023-ACAP-Reading_V1.0.xlsx>
- **2023-2024:**
  <https://www.alabamaachieves.org/wp-content/uploads/2024/06/RD_SP_2024613_2023-2024-ACAP-Reading.xlsx>
- **2024-2025:**
  <https://www.alabamaachieves.org/wp-content/uploads/2025/06/RD_SP_2025612_ACAP-Reading_v1.0.xlsx>

------------------------------------------------------------------------

## Data Structure

### Raw Data Columns (from Excel files)

- System Code, System Name
- School Code, School Name
- Tested Grade (02, 03)
- Total Tested
- Total Below Grade Level
- Total On or Above Grade Level
- Percentage for Below Grade Level
- Percentage for On or Above Grade Level

### Processed Data Columns (standardized)

- end_year, system_code, system_name
- school_code, school_name
- subject (always “Reading”)
- grade (“02”, “03”)
- grade_level (“Grade 2”, “Grade 3”)
- total_tested, below_grade_level, at_or_above_grade_level
- pct_below_grade_level, pct_at_or_above_grade_level
- is_state, is_district, is_school

### Tidy Data Columns (user-facing)

- end_year, system_code, system_name
- school_code, school_name
- subject, grade, grade_level
- n_tested, proficiency_count, proficiency_rate
- is_state, is_district, is_school

------------------------------------------------------------------------

## Example Usage

``` r
library(alschooldata)

# Get single year
assess_2025 <- fetch_assess(2025)

# Get multiple years
assess_multi <- fetch_assess_multi(2022:2025)

# State-level 3rd grade reading proficiency
assess_2025 |>
  dplyr::filter(is_state, grade == "03") |>
  dplyr::select(end_year, n_tested, proficiency_rate)

# District-level data
assess_2025 |>
  dplyr::filter(is_district, grade == "03") |>
  dplyr::arrange(desc(proficiency_rate))

# School-level data for specific district
assess_2025 |>
  dplyr::filter(system_name == "Jefferson County", is_school) |>
  dplyr::select(school_name, grade, n_tested, proficiency_rate)
```

------------------------------------------------------------------------

## Testing

All tests pass successfully: 1. ✅
[`get_available_assess_years()`](https://almartin82.github.io/alschooldata/reference/get_available_assess_years.md)
returns valid year range 2. ✅
[`fetch_assess()`](https://almartin82.github.io/alschooldata/reference/fetch_assess.md)
returns data for valid years 3. ✅ No Inf/NaN values in data 4. ✅
Proficiency rates between 0 and 1 5. ✅ Non-negative test counts 6. ✅
State aggregates calculated correctly 7. ✅
[`fetch_assess_multi()`](https://almartin82.github.io/alschooldata/reference/fetch_assess_multi.md)
works for multiple years

------------------------------------------------------------------------

## Limitations and Future Work

### Current Limitations

1.  **Subject Coverage:** Only Reading/ELA data available
2.  **Grade Coverage:** Only grades 2-3 (early literacy focus)
3.  **No High School Data:** SAT/ACT excluded per requirements
4.  **No Historical Data:** ACT Aspire (2015-2019) not downloadable

### Research Findings

- **ACAP Math:** Excel files not found on Alabama Achieves website
- **ACAP Science:** Excel files not found on Alabama Achieves website
- **Historical Data:** ACT Aspire data only available in PDF reports,
  not downloadable spreadsheets
- **Report Card System:** JavaScript-rendered DevExpress grids (requires
  browser automation - prohibited)

### Potential Future Improvements

1.  **Contact ALSDE directly:** Request bulk data downloads for
    Math/Science assessments
2.  **Monitor for API development:** Check if ALSDE releases a public
    API
3.  **PDF scraping:** Consider extracting data from PDF reports (if
    allowed by project rules)
4.  **Expand grade coverage:** If more grades become available in Excel
    format

------------------------------------------------------------------------

## Sources

1.  [Alabama Achieves Assessment
    Page](https://www.alabamaachieves.org/assessment/)
2.  [ACAP Summative
    Information](https://www.alabamaachieves.org/assessment/acap/)
3.  [2024-2025 ACAP Reading
    Data](https://www.alabamaachieves.org/wp-content/uploads/2025/06/RD_SP_2025612_ACAP-Reading_v1.0.xlsx)
4.  [2023-2024 ACAP Reading
    Data](https://www.alabamaachieves.org/wp-content/uploads/2024/06/RD_SP_2024613_2023-2024-ACAP-Reading.xlsx)
5.  [2022-2023 ACAP Reading
    Data](https://www.alabamaachieves.org/wp-content/uploads/2023/06/RD_SP_202368_2022-2023-ACAP-Reading_V1.0.xlsx)
6.  [2021-2022 ACAP Reading
    Data](https://www.alabamaachieves.org/wp-content/uploads/2022/07/2021-2022-ACAP-Reading.xlsx)

------------------------------------------------------------------------

## Conclusion

Alabama assessment data has been successfully implemented **within the
constraints of available data**. The package now provides:

✅ 4 years of ACAP Reading assessment data (2021-2025) ✅ School,
district, and state-level data ✅ Proficiency rates and counts ✅ Clean,
documented, and tested API

❌ Math assessment data (not available as downloadable Excel) ❌ Science
assessment data (not available as downloadable Excel) ❌ High school
assessments (excluded per requirements) ❌ Historical pre-2021 data (not
available in downloadable format)

**Recommendation:** This implementation provides valuable early literacy
assessment data for Alabama, despite the limitations. The Reading
assessment data is particularly relevant given Alabama’s focus on early
literacy (Alabama Literacy Act).

------------------------------------------------------------------------

**End of Summary**
