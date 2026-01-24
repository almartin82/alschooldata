# Download ACAP Reading assessment data

The Alabama Achieves website provides ACAP Reading assessment data in
Excel format. This function downloads the appropriate file for the
requested school year.

## Usage

``` r
download_acap_assessment(end_year)
```

## Arguments

- end_year:

  School year end

## Value

Data frame with assessment data

## Details

File URLs follow this pattern:

- 2021-2022:
  https://www.alabamaachieves.org/wp-content/uploads/2022/07/2021-2022-ACAP-Reading.xlsx

- 2022-2023:
  https://www.alabamaachieves.org/wp-content/uploads/2023/06/RD_SP_202368_2022-2023-ACAP-Reading_V1.0.xlsx

- 2023-2024:
  https://www.alabamaachieves.org/wp-content/uploads/2024/06/RD_SP_2024613_2023-2024-ACAP-Reading.xlsx

- 2024-2025:
  https://www.alabamaachieves.org/wp-content/uploads/2025/06/RD_SP_2025612_ACAP-Reading_v1.0.xlsx
