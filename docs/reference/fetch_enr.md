# Fetch Alabama enrollment data

Downloads and processes enrollment data from ALSDE Federal Report Card.
Data includes enrollment by school, district, and state with demographic
breakdowns by race/ethnicity, gender, and special populations.

## Usage

``` r
fetch_enr(end_year, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  A school year. Year is the end of the academic year - eg 2023-24
  school year is year '2024'. Valid values are 2015-2025.

- tidy:

  If TRUE (default), returns data in long (tidy) format with subgroup
  column. If FALSE, returns wide format.

- use_cache:

  If TRUE (default), uses locally cached data when available. Set to
  FALSE to force re-download from source.

## Value

Data frame with enrollment data. Wide format includes columns for
district_name, campus_name, and enrollment counts by demographic. Tidy
format pivots these counts into subgroup column.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 enrollment data (2023-24 school year)
enr_2024 <- fetch_enr(2024)

# Get wide format
enr_wide <- fetch_enr(2024, tidy = FALSE)

# Force fresh download (ignore cache)
enr_fresh <- fetch_enr(2024, use_cache = FALSE)

# Filter to Jefferson County
jefferson <- enr_2024 |>
  dplyr::filter(grepl("Jefferson", district_name))
} # }
```
