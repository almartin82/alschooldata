# Process raw ALSDE enrollment data

Transforms raw Federal Report Card data into a standardized schema
combining school and district data.

## Usage

``` r
process_enr(raw_data, end_year)
```

## Arguments

- raw_data:

  Data frame from get_raw_enr

- end_year:

  School year end

## Value

Processed data frame with standardized columns
