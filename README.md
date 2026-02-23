# alschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/alschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/alschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/alschooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/alschooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/alschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/alschooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

Fetch and analyze Alabama school enrollment data from the Alabama State Department of Education (ALSDE) in R or Python.

**Part of the [State Schooldata Project](https://github.com/almartin82/njschooldata)** - a simple, consistent interface for accessing state-published school data. Originally built as an extension of [njschooldata](https://github.com/almartin82/njschooldata), the New Jersey package that started it all.

**[Documentation](https://almartin82.github.io/alschooldata/)** | **[15 Key Insights](https://almartin82.github.io/alschooldata/articles/enrollment_hooks.html)**

## What can you find with alschooldata?

**5 years of enrollment data (2021-2025).** Alabama's public schools serve over 717,000 students across 153 school systems. This package lets you explore:

- Statewide enrollment trends and post-COVID shifts
- District and school-level data for all 153 systems and 1,400+ schools
- Student demographics (race/ethnicity, economic status, English learners, special education)
- Grade-level breakdowns from Pre-K through 12
- Regional patterns: urban-suburban shifts, Black Belt decline, tech corridor growth

> **See the full analysis with charts and data output:** [15 Insights from Alabama Enrollment Data](https://almartin82.github.io/alschooldata/articles/enrollment_hooks.html)

---

## Installation

### R

```r
# Install from GitHub
remotes::install_github("almartin82/alschooldata")
```

### Python

```bash
pip install pyalschooldata
```

---

## Quick Start

### R

```r
library(alschooldata)
library(dplyr)

# Fetch 2025 enrollment data (2024-25 school year)
enr <- fetch_enr(2025)

# State total enrollment
enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students)
#>   end_year n_students
#> 1     2025     717473
```

### Python

```python
from pyalschooldata import fetch_enr

# Fetch 2025 enrollment data
enr = fetch_enr(2025)

# State total
enr[(enr['is_state']) & (enr['subgroup'] == 'total_enrollment') & (enr['grade_level'] == 'TOTAL')]
```

---

## 15 Insights from Alabama Enrollment Data

All stories below are verified against real ALSDE data. Code matches the [vignette](https://almartin82.github.io/alschooldata/articles/enrollment_hooks.html) exactly.

---

### 1. Alabama lost 12,000 students in four years

Despite a post-COVID bounce in 2022, Alabama's K-12 enrollment has declined from 730,000 to 717,000 since 2021.

```r
library(alschooldata)
library(dplyr)
library(tidyr)
library(ggplot2)

theme_set(theme_minimal(base_size = 14))

enr <- fetch_enr_multi(2021:2025, use_cache = TRUE)

state_totals <- enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students) |>
  arrange(end_year) |>
  mutate(change = n_students - lag(n_students),
         pct_change = round(change / lag(n_students) * 100, 1))

stopifnot(nrow(state_totals) > 0)
state_totals
```

![Statewide enrollment trend](https://almartin82.github.io/alschooldata/articles/enrollment_hooks_files/figure-html/statewide-chart-1.png)

---

### 2. Hispanic enrollment grew 27% in four years

Hispanic students are the fastest-growing demographic, rising from 9.5% to 12.2% of enrollment since 2021.

```r
hispanic_trend <- enr |>
  filter(is_state, subgroup == "hispanic", grade_level == "TOTAL") |>
  mutate(pct = round(pct * 100, 1)) |>
  select(end_year, n_students, pct) |>
  arrange(end_year)

stopifnot(nrow(hispanic_trend) > 0)
hispanic_trend
```

![Hispanic enrollment trend](https://almartin82.github.io/alschooldata/articles/enrollment_hooks_files/figure-html/hispanic-chart-1.png)

---

### 3. Mobile County leads with 47,000 students

Alabama has 153 school systems. Mobile County alone enrolls more than double the second-largest district.

```r
enr_2025 <- enr |> filter(end_year == 2025)

top_10 <- enr_2025 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  head(10) |>
  select(district_name, n_students)

stopifnot(nrow(top_10) > 0)
top_10
```

![Top 10 districts](https://almartin82.github.io/alschooldata/articles/enrollment_hooks_files/figure-html/top-districts-chart-1.png)

---

### 4. Birmingham shrinks while suburbs hold steady

Birmingham City lost 2,200 students since 2021 while nearby Homewood, Trussville, and Mountain Brook grew.

```r
bham_districts <- c("Birmingham City", "Hoover City",
                    "Vestavia Hills City", "Mountain Brook City",
                    "Homewood City", "Trussville City")

bham_area <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         district_name %in% bham_districts) |>
  select(end_year, district_name, n_students) |>
  pivot_wider(names_from = end_year, values_from = n_students,
              values_fn = max)

stopifnot(nrow(bham_area) > 0)
bham_area
```

![Birmingham metro trends](https://almartin82.github.io/alschooldata/articles/enrollment_hooks_files/figure-html/suburb-chart-1.png)

---

### 5. Black Belt lost nearly 1 in 5 students since 2021

Eight Black Belt counties lost 19% of their combined enrollment in just four years, from 13,100 to 10,600 students.

```r
bb_counties <- c("Perry County", "Wilcox County", "Greene County",
                 "Sumter County", "Lowndes County", "Macon County",
                 "Dallas County", "Hale County")

bb_trend <- enr |>
  filter(is_district, district_name %in% bb_counties,
         subgroup == "total_enrollment", grade_level == "TOTAL") |>
  group_by(end_year) |>
  summarize(total = sum(n_students), .groups = "drop") |>
  arrange(end_year) |>
  mutate(pct_from_2021 = round((total / first(total) - 1) * 100, 1))

stopifnot(nrow(bb_trend) > 0)
bb_trend
```

![Black Belt enrollment](https://almartin82.github.io/alschooldata/articles/enrollment_hooks_files/figure-html/black-belt-chart-1.png)

---

### 6. Alabama is 56% white, 32% Black, 12% Hispanic

White students are the majority but their share has dropped from 58% to 56% since 2021 as Hispanic enrollment grows.

```r
demographics <- enr_2025 |>
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian",
                         "multiracial", "native_american",
                         "pacific_islander")) |>
  mutate(pct = round(pct * 100, 1)) |>
  select(subgroup, n_students, pct) |>
  arrange(desc(n_students))

stopifnot(nrow(demographics) > 0)
demographics
```

![Demographics chart](https://almartin82.github.io/alschooldata/articles/enrollment_hooks_files/figure-html/demographics-chart-1.png)

---

### 7. The white share is falling 0.5 points per year

White enrollment dropped from 58.3% in 2021 to 56.1% in 2025 as the student body diversifies.

```r
demo_shares <- enr |>
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic")) |>
  mutate(pct = round(pct * 100, 1)) |>
  select(end_year, subgroup, pct) |>
  pivot_wider(names_from = subgroup, values_from = pct) |>
  arrange(end_year)

stopifnot(nrow(demo_shares) > 0)
demo_shares
```

![Demographic shift chart](https://almartin82.github.io/alschooldata/articles/enrollment_hooks_files/figure-html/demographic-shift-chart-1.png)

---

### 8. Madison City grew 9% on Huntsville's tech boom

The Huntsville metro area is Alabama's growth engine, with Madison City adding 1,100 students since 2021.

```r
madison_area <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         district_name %in% c("Madison City", "Madison County", "Huntsville City")) |>
  select(end_year, district_name, n_students) |>
  pivot_wider(names_from = end_year, values_from = n_students, values_fn = max) |>
  mutate(change = `2025` - `2021`,
         pct_change = round((`2025` / `2021` - 1) * 100, 1))

stopifnot(nrow(madison_area) > 0)
madison_area
```

![Madison growth chart](https://almartin82.github.io/alschooldata/articles/enrollment_hooks_files/figure-html/madison-chart-1.png)

---

### 9. Nearly 59% of students are economically disadvantaged

Alabama's poverty rate makes the majority of public school students eligible for free/reduced lunch.

```r
econ_trend <- enr |>
  filter(is_state, grade_level == "TOTAL", subgroup == "econ_disadv") |>
  mutate(pct = round(pct * 100, 1)) |>
  select(end_year, n_students, pct) |>
  arrange(end_year)

stopifnot(nrow(econ_trend) > 0)
econ_trend
```

![Econ disadvantaged chart](https://almartin82.github.io/alschooldata/articles/enrollment_hooks_files/figure-html/econ-chart-1.png)

---

### 10. English Learners grew 52% in four years

EL enrollment surged from 33,600 to 51,100 students, the fastest growth of any subgroup.

```r
el_trend <- enr |>
  filter(is_state, subgroup == "lep", grade_level == "TOTAL") |>
  mutate(pct = round(pct * 100, 1)) |>
  select(end_year, n_students, pct) |>
  arrange(end_year)

stopifnot(nrow(el_trend) > 0)
el_trend
```

![English Learner chart](https://almartin82.github.io/alschooldata/articles/enrollment_hooks_files/figure-html/el-chart-1.png)

---

### 11. Mobile County lost 5,800 students in four years

Alabama's largest district is shrinking faster than the state average, losing 11% of enrollment since 2021.

```r
mobile_trend <- enr |>
  filter(is_district, district_name == "Mobile County",
         subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students) |>
  arrange(end_year) |>
  mutate(pct_from_2021 = round((n_students / first(n_students) - 1) * 100, 1))

stopifnot(nrow(mobile_trend) > 0)
mobile_trend
```

![Mobile County chart](https://almartin82.github.io/alschooldata/articles/enrollment_hooks_files/figure-html/mobile-chart-1.png)

---

### 12. Special education enrollment spiked in 2022-2023

The number of students with disabilities jumped from 102,000 to 131,000 in 2022, potentially reflecting expanded identification after pandemic disruptions.

```r
sped_trend <- enr |>
  filter(is_state, subgroup == "special_ed", grade_level == "TOTAL") |>
  mutate(pct = round(pct * 100, 1)) |>
  select(end_year, n_students, pct) |>
  arrange(end_year)

stopifnot(nrow(sped_trend) > 0)
sped_trend
```

![Special ed chart](https://almartin82.github.io/alschooldata/articles/enrollment_hooks_files/figure-html/sped-chart-1.png)

---

### 13. 9th grade is the largest class — 5,800 more than 12th

The "9th grade bulge" reflects retention policies, with 56,600 freshmen versus 50,800 seniors in 2025.

```r
grade_dist <- enr_2025 |>
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("PK", "K", "01", "02", "03", "04", "05",
                            "06", "07", "08", "09", "10", "11", "12")) |>
  mutate(grade_level = factor(grade_level,
                              levels = c("PK", "K", "01", "02", "03", "04", "05",
                                        "06", "07", "08", "09", "10", "11", "12"))) |>
  select(grade_level, n_students)

stopifnot(nrow(grade_dist) > 0)
grade_dist
```

![Grade distribution chart](https://almartin82.github.io/alschooldata/articles/enrollment_hooks_files/figure-html/grade-chart-1.png)

---

### 14. Eufaula City grew 49% — the fastest in the state

Eufaula City added nearly 3,000 students since 2021, making it the fastest-growing district by percentage.

```r
growth <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         end_year %in% c(2021, 2025)) |>
  select(end_year, district_name, n_students) |>
  pivot_wider(names_from = end_year, values_from = n_students,
              values_fn = max) |>
  filter(!is.na(`2021`) & !is.na(`2025`) & `2021` > 500) |>
  mutate(change = `2025` - `2021`,
         pct_change = round((`2025` / `2021` - 1) * 100, 1)) |>
  arrange(desc(pct_change)) |>
  head(10) |>
  select(district_name, `2021`, `2025`, change, pct_change)

stopifnot(nrow(growth) > 0)
growth
```

![Fastest growing chart](https://almartin82.github.io/alschooldata/articles/enrollment_hooks_files/figure-html/growth-chart-1.png)

---

### 15. Perry County lost a third of its students

The steepest decline is in Perry County, which dropped from 1,148 to 778 students — a 32% loss since 2021.

```r
decline <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         end_year %in% c(2021, 2025)) |>
  select(end_year, district_name, n_students) |>
  pivot_wider(names_from = end_year, values_from = n_students,
              values_fn = max) |>
  filter(!is.na(`2021`) & !is.na(`2025`) & `2021` > 500) |>
  mutate(change = `2025` - `2021`,
         pct_change = round((`2025` / `2021` - 1) * 100, 1)) |>
  arrange(pct_change) |>
  head(10) |>
  select(district_name, `2021`, `2025`, change, pct_change)

stopifnot(nrow(decline) > 0)
decline
```

![Fastest declining chart](https://almartin82.github.io/alschooldata/articles/enrollment_hooks_files/figure-html/decline-chart-1.png)

---

## Summary

Alabama's school enrollment data reveals a state in demographic transition:

- **Overall decline** from 730,000 to 717,000 students since 2021
- **Hispanic growth** is the dominant demographic trend (+27% in 4 years)
- **English Learner surge** mirrors Hispanic growth (+52% since 2021)
- **Urban-to-suburban shift** continues around Birmingham and Huntsville
- **Black Belt crisis** — rural counties losing 19% of enrollment in 4 years
- **High poverty** — nearly 59% of students are economically disadvantaged

---

## Data Notes

- **Source:** Alabama State Department of Education (ALSDE) [Federal Report Card](https://reportcard.alsde.edu/)
- **Years available:** 2015-2025 (this package uses 2021-2025)
- **Entities:** ~153 school systems, ~1,400 schools
- **Suppression:** Counts below 5 are marked with `*` or `~` to protect student privacy
- **Reporting:** Data reflects Census Day enrollment for each school year
- **Race/ethnicity:** Federal reporting standard — Hispanic/Latino is an ethnicity overlay on race categories

---

*Part of the [state schooldata](https://github.com/almartin82/njschooldata) project.*
