# Get available ACAP assessment years

Returns the minimum and maximum years available for ACAP Reading
assessment data.

Returns the minimum and maximum years available for ACAP assessment
data.

## Usage

``` r
get_available_assess_years()

get_available_assess_years()
```

## Value

List with components:

- min_year:

  First available year (2022)

- max_year:

  Last available year (2025)

List with min_year and max_year

## Examples

``` r
get_available_assess_years()
#> $min_year
#> [1] 2022
#> 
#> $max_year
#> [1] 2025
#> 

# Returns: list(min_year = 2022, max_year = 2025)
```
