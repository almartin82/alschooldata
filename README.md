# alschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/alschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/alschooldata/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/almartin82/alschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/alschooldata/actions/workflows/pkgdown.yaml)
<!-- badges: end -->

Fetch and analyze Alabama public school enrollment data from the Alabama State Department of Education (ALSDE).

**[Documentation](https://almartin82.github.io/alschooldata/)** | **[10 Key Insights](https://almartin82.github.io/alschooldata/articles/enrollment_hooks.html)** | **[Getting Started](https://almartin82.github.io/alschooldata/articles/quickstart.html)**

## What can you find with alschooldata?

> **See the full analysis with charts and data output:** [10 Insights from Alabama Enrollment Data](https://almartin82.github.io/alschooldata/articles/enrollment_hooks.html)

**11 years of enrollment data (2015-2025).** 730,000 students across 140+ school systems. Here are ten stories hiding in the numbers:

---

### 1. Alabama's enrollment is holding steady

Unlike many states seeing sharp declines, Alabama's public school enrollment has remained relatively stable around 730,000 students, with only modest fluctuations.

```r
library(alschooldata)
library(dplyr)

enr <- fetch_enr_multi(2015:2025)

enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students) %>%
  mutate(change = n_students - lag(n_students))
```

---

### 2. COVID hit elementary hardest

The pandemic's enrollment impact was felt most sharply in elementary grades, especially kindergarten, which saw significant drops in 2021.

```r
enr <- fetch_enr_multi(2019:2023)

enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "09")) %>%
  select(end_year, grade_level, n_students) %>%
  tidyr::pivot_wider(names_from = end_year, values_from = n_students)
```

---

### 3. Jefferson County dominates but shrinks

Jefferson County (Birmingham) is Alabama's largest school system but has been losing students while suburban systems grow.

```r
enr_2025 <- fetch_enr(2025)

enr_2025 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(10) %>%
  select(district_name, n_students)
```

---

### 4. The suburban surge around Birmingham

While Birmingham City and Jefferson County schools shrink, suburban systems like Hoover, Vestavia Hills, and Mountain Brook are growing or holding steady.

```r
enr <- fetch_enr_multi(2020:2025)

enr %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Hoover|Vestavia|Mountain Brook|Birmingham", district_name)) %>%
  select(end_year, district_name, n_students) %>%
  tidyr::pivot_wider(names_from = end_year, values_from = n_students)
```

---

### 5. Black Belt schools face existential decline

Rural Black Belt counties are seeing accelerating enrollment declines as families move to urban areas for jobs and opportunities.

```r
# Perry, Wilcox, Greene, Sumter counties
enr %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Perry|Wilcox|Greene|Sumter", district_name, ignore.case = TRUE)) %>%
  group_by(district_name) %>%
  summarize(
    y2020 = n_students[end_year == 2020],
    y2025 = n_students[end_year == 2025],
    pct_change = round((y2025 / y2020 - 1) * 100, 1)
  ) %>%
  arrange(pct_change)
```

---

### 6. Alabama is 33% Black, 47% white

Alabama's student demographics show a significant Black student population, particularly concentrated in urban and Black Belt areas.

```r
enr_2025 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian", "multiracial")) %>%
  mutate(pct = round(pct * 100, 1)) %>%
  select(subgroup, n_students, pct) %>%
  arrange(desc(n_students))
```

---

### 7. Hispanic enrollment is climbing

Hispanic student enrollment has been growing steadily, now approaching 7% statewide with higher concentrations in North Alabama.

```r
enr <- fetch_enr_multi(2015:2025)

enr %>%
  filter(is_state, subgroup == "hispanic", grade_level == "TOTAL") %>%
  mutate(pct = round(pct * 100, 1)) %>%
  select(end_year, n_students, pct)
```

---

### 8. Madison County is Alabama's growth engine

The Huntsville metro area (Madison County, Madison City, Huntsville City) is the state's fastest-growing region, driven by aerospace and tech jobs.

```r
enr <- fetch_enr_multi(2020:2025)

enr %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Madison|Huntsville", district_name)) %>%
  group_by(district_name) %>%
  summarize(
    y2020 = n_students[end_year == 2020],
    y2025 = n_students[end_year == 2025],
    pct_change = round((y2025 / y2020 - 1) * 100, 1)
  ) %>%
  arrange(desc(pct_change))
```

---

### 9. Economically disadvantaged students are the majority

Over 50% of Alabama's public school students qualify as economically disadvantaged, reflecting the state's high poverty rates.

```r
enr_2025 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("econ_disadv", "total_enrollment")) %>%
  select(subgroup, n_students, pct)
```

---

### 10. Mobile County is larger than many states

Mobile County Public Schools, with over 50,000 students, is one of the largest school systems in the Southeast and operates like a mini-state.

```r
enr_2025 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Mobile", district_name)) %>%
  select(district_name, n_students)
```

---

## Installation

```r
# install.packages("remotes")
remotes::install_github("almartin82/alschooldata")
```

## Quick start

```r
library(alschooldata)
library(dplyr)

# Fetch one year
enr_2025 <- fetch_enr(2025)

# Fetch multiple years
enr_multi <- fetch_enr_multi(2020:2025)

# State totals
enr_2025 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# District breakdown
enr_2025 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students))

# Demographics
enr_2025 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  select(subgroup, n_students, pct)
```

## Data availability

| Years | Source | Notes |
|-------|--------|-------|
| **2015-2025** | ALSDE Federal Report Card | Full demographic data |

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

## Part of the 50 State Schooldata Family

This package is part of a family of R packages providing school enrollment data for all 50 US states. Each package fetches data directly from the state's Department of Education.

**See also:** [njschooldata](https://github.com/almartin82/njschooldata) - The original state schooldata package for New Jersey.

**All packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (almartin@gmail.com)

## License

MIT
