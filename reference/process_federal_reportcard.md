# Process Federal Report Card data

Extracts enrollment data from the multi-dimensional ALSDE CSV format.
The raw data has filter dimensions (Grade, Gender, Ethnicity, Sub
Population) as columns with race/ethnicity breakdowns in value columns.

## Usage

``` r
process_federal_reportcard(df, end_year)
```

## Arguments

- df:

  Raw data frame from Federal Report Card

- end_year:

  School year end

## Value

Processed data frame in wide format
