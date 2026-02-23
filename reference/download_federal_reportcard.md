# Download data from Federal Report Card Student Demographics

The Federal Report Card provides detailed enrollment data by
demographics at the school level. This function downloads the CSV
export.

## Usage

``` r
download_federal_reportcard(end_year)
```

## Arguments

- end_year:

  School year end

## Value

Data frame with enrollment data

## Details

The Student Demographics page is available at:
https://reportcard.alsde.edu/SupportingData_StudentDemographics.aspx

The export returns a CSV with columns:

- Year, System, School (identifiers)

- Grade, Gender, Ethnicity, Sub Population (filter dimensions)

- Total Student Count (enrollment count)

- Race columns: Asian, Black or African American, American Indian /
  Alaska Native, Native Hawaiian / Pacific Islander, White, Two or more
  races (with corresponding % columns)
