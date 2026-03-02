# Process raw ALSDE directory data

Combines and standardizes school and superintendent directory data into
a single data frame with consistent column names.

## Usage

``` r
process_directory(raw_data)
```

## Arguments

- raw_data:

  List with 'schools' and 'superintendents' data frames from
  get_raw_directory()

## Value

Processed data frame with standardized columns
