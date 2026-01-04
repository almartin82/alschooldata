# Get Available Years

Returns the range of years for which enrollment data is available.

## Usage

``` r
get_available_years()
```

## Value

Named list with min_year and max_year

## Details

Data is sourced from the ALSDE Federal Report Card Student Demographics
system, which provides data from the 2014-15 school year (end_year =
2015) to the present.

## Examples

``` r
get_available_years()
#> $min_year
#> [1] 2015
#> 
#> $max_year
#> [1] 2024
#> 
```
