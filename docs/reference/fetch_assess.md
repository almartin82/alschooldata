# Fetch Alabama ACAP assessment data

Downloads and processes ACAP Reading assessment data from ALSDE Alabama
Achieves. Data includes school-level proficiency rates for grades 2-3
reading assessments.

## Usage

``` r
fetch_assess(end_year, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  A school year. Year is the end of the academic year - eg 2023-24
  school year is year '2024'. Valid values are 2022-2025.

- tidy:

  If TRUE (default), returns data in long (tidy) format with
  proficiency_rate column. If FALSE, returns wide format with percentage
  columns.

- use_cache:

  If TRUE (default), uses locally cached data when available. Set to
  FALSE to force re-download from source.

## Value

Data frame with assessment data. Wide format includes columns for
district_name, campus_name, grade, and proficiency percentages. Tidy
format includes proficiency_rate as a single column.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 ACAP assessment data (2023-24 school year)
assess_2024 <- fetch_assess(2024)

# Get wide format
assess_wide <- fetch_assess(2024, tidy = FALSE)

# Force fresh download (ignore cache)
assess_fresh <- fetch_assess(2024, use_cache = FALSE)

# Filter to state-level 3rd grade reading proficiency
assess_2024 |>
  dplyr::filter(is_state, grade == "03") |>
  dplyr::select(end_year, n_tested, proficiency_rate)
} # }
```
