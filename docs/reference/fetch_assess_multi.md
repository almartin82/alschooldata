# Fetch assessment data for multiple years

Downloads and combines ACAP assessment data for multiple school years.

## Usage

``` r
fetch_assess_multi(end_years, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_years:

  Vector of school year ends (e.g., c(2022, 2023, 2024))

- tidy:

  If TRUE (default), returns data in long (tidy) format.

- use_cache:

  If TRUE (default), uses locally cached data when available.

## Value

Combined data frame with assessment data for all requested years

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 3 years of assessment data
assess_multi <- fetch_assess_multi(2022:2024)

# Track 3rd grade reading proficiency trends
assess_multi |>
  dplyr::filter(is_state, grade == "03") |>
  dplyr::select(end_year, n_tested, proficiency_rate)
} # }
```
