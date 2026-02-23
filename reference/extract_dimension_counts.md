# Extract counts from a specific dimension filter

Helper to match dimension-specific rows (e.g., Grade = "Grade 09") back
to the base result frame using System + School name matching.

## Usage

``` r
extract_dimension_counts(raw_df, result_df, dimension, value)
```

## Arguments

- raw_df:

  Full raw data frame

- result_df:

  Result data frame with district_name and campus_name

- dimension:

  Column name of the dimension (e.g., "Grade", "Gender")

- value:

  Value to filter on (e.g., "Grade 09", "Male")

## Value

Numeric vector of counts aligned to result_df rows
