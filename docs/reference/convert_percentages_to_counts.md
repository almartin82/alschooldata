# Convert percentage columns to counts

Some ALSDE data exports provide percentages rather than counts. This
function converts them using the row_total.

## Usage

``` r
convert_percentages_to_counts(df)
```

## Arguments

- df:

  Data frame with potential percentage columns

## Value

Data frame with counts
