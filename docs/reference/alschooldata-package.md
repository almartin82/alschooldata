# alschooldata: Fetch and Process Alabama School Data

Downloads and processes school data from the Alabama State Department of
Education (ALSDE). Provides functions for fetching enrollment data from
the ALSDE Federal Report Card and transforming it into tidy format for
analysis. Supports data from 2015 to present.

## Main functions

- [`fetch_enr`](https://almartin82.github.io/alschooldata/reference/fetch_enr.md):

  Fetch enrollment data for a school year

- [`fetch_enr_multi`](https://almartin82.github.io/alschooldata/reference/fetch_enr_multi.md):

  Fetch enrollment data for multiple years

- [`tidy_enr`](https://almartin82.github.io/alschooldata/reference/tidy_enr.md):

  Transform wide data to tidy (long) format

- [`id_enr_aggs`](https://almartin82.github.io/alschooldata/reference/id_enr_aggs.md):

  Add aggregation level flags

- [`enr_grade_aggs`](https://almartin82.github.io/alschooldata/reference/enr_grade_aggs.md):

  Create grade-level aggregations

- [`get_available_years`](https://almartin82.github.io/alschooldata/reference/get_available_years.md):

  Get the range of available years

## Cache functions

- [`cache_status`](https://almartin82.github.io/alschooldata/reference/cache_status.md):

  View cached data files

- [`clear_cache`](https://almartin82.github.io/alschooldata/reference/clear_cache.md):

  Remove cached data files

## ID System

Alabama uses a hierarchical system of codes:

- System (District) Codes: 3-digit codes (e.g., "001" = Autauga County)

- School Codes: 4-digit codes unique within each system

## Data Source

Data is sourced exclusively from the Alabama State Department of
Education:

- Federal Report Card Student Demographics:
  <https://reportcard.alsde.edu/SupportingData_StudentDemographics.aspx>

## Available Years

The ALSDE Federal Report Card provides enrollment data from 2015 to 2024
(school years 2014-15 through 2023-24). Data includes school-level
enrollment with demographic breakdowns by race/ethnicity, gender, and
special populations.

## See also

Useful links:

- <https://almartin82.github.io/alschooldata/>

- <https://github.com/almartin82/alschooldata>

- Report bugs at <https://github.com/almartin82/alschooldata/issues>

## Author

**Maintainer**: Al Martin <almartin@example.com>
