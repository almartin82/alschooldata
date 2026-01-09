# alschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/alschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/alschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/alschooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/alschooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/alschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/alschooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

Fetch and analyze Alabama school enrollment data from the Alabama State Department of Education (ALSDE) in R or Python.

**[Documentation](https://almartin82.github.io/alschooldata/)** | **[10 Key Insights](https://almartin82.github.io/alschooldata/articles/enrollment_hooks.html)** | **[Getting Started](https://almartin82.github.io/alschooldata/articles/quickstart.html)**

## What can you find with alschooldata?

> **See the full analysis with charts and data output:** [10 Insights from Alabama Enrollment Data](https://almartin82.github.io/alschooldata/articles/enrollment_hooks.html)

**10 years of enrollment data (2015-2024).** Fetch and analyze Alabama school enrollment data including:

- Statewide enrollment trends
- District and school-level data
- Student demographics (race/ethnicity, economic status, English learners, special education)
- Grade-level breakdowns
- Multi-year comparisons

See the [enrollment insights vignette](https://almartin82.github.io/alschooldata/articles/enrollment_hooks.html) for example analyses.

---

## Installation

```r
# install.packages("remotes")
remotes::install_github("almartin82/alschooldata")
```

## Quick start

### R

```r
library(alschooldata)
library(dplyr)

# Fetch one year
enr_2024 <- fetch_enr(2024)

# Fetch multiple years
enr_multi <- fetch_enr_multi(2020:2024)

# State totals
enr_2024 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# District breakdown
enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students))

# Demographics
enr_2024 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  select(subgroup, n_students, pct)
```

### Python

```python
import pyalschooldata as al

# Fetch one year
enr_2024 = al.fetch_enr(2024)

# Fetch multiple years
enr_multi = al.fetch_enr_multi([2020, 2021, 2022, 2023, 2024])

# State totals
enr_2024[
    (enr_2024['is_state'] == True) &
    (enr_2024['subgroup'] == 'total_enrollment') &
    (enr_2024['grade_level'] == 'TOTAL')
]

# District breakdown
district_df = enr_2024[
    (enr_2024['is_district'] == True) &
    (enr_2024['subgroup'] == 'total_enrollment') &
    (enr_2024['grade_level'] == 'TOTAL')
].sort_values('n_students', ascending=False)

# Demographics
enr_2024[
    (enr_2024['is_state'] == True) &
    (enr_2024['grade_level'] == 'TOTAL') &
    (enr_2024['subgroup'].isin(['white', 'black', 'hispanic', 'asian']))
][['subgroup', 'n_students', 'pct']]
```

## Data availability

| Years | Source | Notes |
|-------|--------|-------|
| **2015-2024** | ALSDE Federal Report Card | Full demographic data |

Data is sourced from the Alabama State Department of Education Federal Report Card Student Demographics.

### What's included

- **Levels:** State, system (~140), school (~1,600)
- **Demographics:** White, Black, Hispanic, Asian, American Indian, Pacific Islander, Two or More Races
- **Special populations:** Economically disadvantaged, English learners, Students with disabilities
- **Grade levels:** K-12

### Alabama ID system

- **System codes:** 3 digits (001-067 for counties, 100+ for cities)
- **School codes:** 4 digits unique within each system

## Data source

Alabama State Department of Education: [Report Card](https://reportcard.alsde.edu/)

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data in Python and R.

**All 50 state packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (almartin@gmail.com)

## License

MIT
