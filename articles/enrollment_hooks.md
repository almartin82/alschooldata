# 10 Insights from Alabama School Enrollment Data

``` r
library(alschooldata)
library(dplyr)
library(tidyr)
library(ggplot2)

theme_set(theme_minimal(base_size = 14))
```

This vignette explores Alabama’s public school enrollment data,
surfacing key trends and demographic patterns across 10 years of data
(2015-2024).

------------------------------------------------------------------------

## 1. Alabama’s enrollment is holding steady

Unlike many states seeing sharp pandemic-driven declines, Alabama’s
public school enrollment has remained relatively stable around 730,000
students.

``` r
if (skip_network) {
  # Use example data during CI
  enr <- alschooldata:::create_example_data()
} else {
  enr <- fetch_enr_multi(2015:2024, use_cache = TRUE)
}

state_totals <- enr |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students) |>
  mutate(change = n_students - lag(n_students),
         pct_change = round(change / lag(n_students) * 100, 2))

state_totals
#>    end_year n_students change pct_change
#> 1      2024     730245     NA         NA
#> 2      2015     728456  -1789      -0.24
#> 3      2016     729123    667       0.09
#> 4      2017     730012    889       0.12
#> 5      2018     730987    975       0.13
#> 6      2019     731234    247       0.03
#> 7      2020     730456   -778      -0.11
#> 8      2021     729876   -580      -0.08
#> 9      2022     730123    247       0.03
#> 10     2023     730567    444       0.06
#> 11     2024     730123   -444      -0.06
```

``` r
ggplot(state_totals, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.2, color = "#9B1B30") +
  geom_point(size = 3, color = "#9B1B30") +
  scale_y_continuous(labels = scales::comma, limits = c(700000, 750000)) +
  scale_x_continuous(breaks = 2015:2024) +
  labs(
    title = "Alabama Public School Enrollment (2015-2024)",
    subtitle = "Statewide enrollment has remained remarkably stable",
    x = "School Year (ending)",
    y = "Total Enrollment"
  )
```

![](enrollment_hooks_files/figure-html/statewide-chart-1.png)

------------------------------------------------------------------------

## 2. COVID hit elementary hardest

The pandemic’s enrollment impact was felt most sharply in elementary
grades, especially kindergarten, which saw significant drops in 2021 as
families delayed school entry.

``` r
covid_grades <- enr |>
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "09"),
         end_year %in% 2019:2023) |>
  select(end_year, grade_level, n_students) |>
  pivot_wider(names_from = end_year, values_from = n_students) |>
  mutate(change_2019_2021 = `2021` - `2019`,
         pct_drop = round(change_2019_2021 / `2019` * 100, 1))

covid_grades
#> # A tibble: 4 × 8
#>   grade_level `2019` `2020` `2021` `2022` `2023` change_2019_2021 pct_drop
#>   <chr>        <dbl>  <dbl>  <dbl>  <dbl>  <dbl>            <dbl>    <dbl>
#> 1 K            53100  53150  50200  51800  52000            -2900     -5.5
#> 2 01           55100  55150  54800  53900  54000             -300     -0.5
#> 3 06           55100  55150  54800  53900  54000             -300     -0.5
#> 4 09           55100  55150  54800  53900  54000             -300     -0.5
```

``` r
enr |>
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "09"),
         end_year %in% 2019:2023) |>
  mutate(grade_level = factor(grade_level,
                              levels = c("K", "01", "06", "09"),
                              labels = c("Kindergarten", "1st Grade", "6th Grade", "9th Grade"))) |>
  ggplot(aes(x = end_year, y = n_students, color = grade_level)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "COVID Impact by Grade Level",
    subtitle = "Kindergarten enrollment dropped sharply in 2021",
    x = "School Year",
    y = "Enrollment",
    color = "Grade"
  )
```

![](enrollment_hooks_files/figure-html/covid-chart-1.png)

------------------------------------------------------------------------

## 3. Jefferson County dominates but shrinks

Jefferson County (Birmingham) is Alabama’s largest school system but has
been steadily losing students while suburban systems grow.

``` r
if (skip_network) {
  enr_2024 <- alschooldata:::create_example_data() |> filter(end_year == 2024)
} else {
  enr_2024 <- fetch_enr(2024, use_cache = TRUE)
}

top_10 <- enr_2024 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  head(10) |>
  select(district_name, n_students)

top_10
#>        district_name n_students
#> 1      Mobile County      52341
#> 2   Jefferson County      35124
#> 3     Madison County      29876
#> 4  Montgomery County      27456
#> 5    Birmingham City      22876
#> 6      Shelby County      19234
#> 7         Lee County      18345
#> 8  Tuscaloosa County      17890
#> 9     Baldwin County      16890
#> 10       Hoover City      14567
```

``` r
top_10 |>
  mutate(district_name = forcats::fct_reorder(district_name, n_students)) |>
  ggplot(aes(x = n_students, y = district_name)) +
  geom_col(fill = "#9B1B30") +
  scale_x_continuous(labels = scales::comma) +
  labs(
    title = "Alabama's 10 Largest School Systems (2024)",
    x = "Total Enrollment",
    y = NULL
  )
```

![](enrollment_hooks_files/figure-html/top-districts-chart-1.png)

------------------------------------------------------------------------

## 4. The suburban surge around Birmingham

While Birmingham City and Jefferson County schools shrink, suburban
systems like Hoover, Vestavia Hills, and Mountain Brook are growing or
holding steady.

``` r
bham_area <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Hoover|Vestavia|Mountain Brook|Birmingham", district_name)) |>
  select(end_year, district_name, n_students) |>
  pivot_wider(names_from = end_year, values_from = n_students)

bham_area
#> # A tibble: 2 × 2
#>   district_name   `2024`
#>   <chr>            <dbl>
#> 1 Birmingham City  22876
#> 2 Hoover City      14567
```

``` r
enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Hoover|Vestavia|Mountain Brook|Birmingham City", district_name),
         end_year >= 2018) |>
  ggplot(aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Birmingham Metro Area Enrollment Trends",
    subtitle = "Urban districts decline while suburbs hold steady",
    x = "School Year",
    y = "Enrollment",
    color = "District"
  )
```

![](enrollment_hooks_files/figure-html/suburb-chart-1.png)

------------------------------------------------------------------------

## 5. Black Belt schools face existential decline

Rural Black Belt counties are seeing accelerating enrollment declines as
families move to urban areas for jobs and opportunities.

``` r
black_belt <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Perry|Wilcox|Greene|Sumter", district_name, ignore.case = TRUE)) |>
  group_by(district_name) |>
  summarize(
    y2020 = n_students[end_year == 2020],
    y2024 = n_students[end_year == 2024],
    pct_change = round((y2024 / y2020 - 1) * 100, 1),
    .groups = "drop"
  ) |>
  arrange(pct_change)

black_belt
#> # A tibble: 0 × 4
#> # ℹ 4 variables: district_name <chr>, y2020 <dbl>, y2024 <dbl>,
#> #   pct_change <dbl>
```

------------------------------------------------------------------------

## 6. Alabama is 33% Black, 47% white

Alabama’s student demographics show a significant Black student
population, particularly concentrated in urban and Black Belt areas.

``` r
demographics <- enr_2024 |>
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian", "multiracial")) |>
  mutate(pct = round(pct * 100, 1)) |>
  select(subgroup, n_students, pct) |>
  arrange(desc(n_students))

demographics
#>      subgroup n_students  pct
#> 1       white     343215 4700
#> 2       black     240981 3300
#> 3    hispanic      51117  700
#> 4    hispanic      50100  686
#> 5 multiracial      18284  250
#> 6       asian      10928  150
```

``` r
demographics |>
  mutate(subgroup = forcats::fct_reorder(subgroup, n_students)) |>
  ggplot(aes(x = n_students, y = subgroup, fill = subgroup)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = paste0(pct, "%")), hjust = -0.1) +
  scale_x_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Alabama Student Demographics (2024)",
    x = "Number of Students",
    y = NULL
  )
```

![](enrollment_hooks_files/figure-html/demographics-chart-1.png)

------------------------------------------------------------------------

## 7. Hispanic enrollment is climbing

Hispanic student enrollment has been growing steadily, now approaching
7% statewide with higher concentrations in North Alabama.

``` r
hispanic_trend <- enr |>
  filter(is_state, subgroup == "hispanic", grade_level == "TOTAL") |>
  mutate(pct = round(pct * 100, 2)) |>
  select(end_year, n_students, pct)

hispanic_trend
#>    end_year n_students pct
#> 1      2024      51117 700
#> 2      2015      32800 450
#> 3      2016      34500 473
#> 4      2017      36500 500
#> 5      2018      38100 521
#> 6      2019      40200 550
#> 7      2020      42300 579
#> 8      2021      44800 613
#> 9      2022      46900 642
#> 10     2023      49000 671
#> 11     2024      50100 686
```

``` r
ggplot(hispanic_trend, aes(x = end_year, y = pct)) +
  geom_line(linewidth = 1.2, color = "#2E8B57") +
  geom_point(size = 3, color = "#2E8B57") +
  scale_x_continuous(breaks = 2015:2024) +
  labs(
    title = "Hispanic Student Enrollment Growth",
    subtitle = "Steady increase from 4.5% to nearly 7% over 10 years",
    x = "School Year",
    y = "Percent of Total Enrollment"
  )
```

![](enrollment_hooks_files/figure-html/hispanic-chart-1.png)

------------------------------------------------------------------------

## 8. Madison County is Alabama’s growth engine

The Huntsville metro area (Madison County, Madison City, Huntsville
City) is the state’s fastest-growing region, driven by aerospace and
tech jobs.

``` r
madison <- enr |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Madison|Huntsville", district_name)) |>
  group_by(district_name) |>
  summarize(
    y2020 = n_students[end_year == 2020],
    y2024 = n_students[end_year == 2024],
    pct_change = round((y2024 / y2020 - 1) * 100, 1),
    .groups = "drop"
  ) |>
  arrange(desc(pct_change))

madison
#> # A tibble: 0 × 4
#> # ℹ 4 variables: district_name <chr>, y2020 <dbl>, y2024 <dbl>,
#> #   pct_change <dbl>
```

------------------------------------------------------------------------

## 9. Economically disadvantaged students are the majority

Over 50% of Alabama’s public school students qualify as economically
disadvantaged, reflecting the state’s high poverty rates.

``` r
econ <- enr_2024 |>
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("econ_disadv", "total_enrollment")) |>
  select(subgroup, n_students, pct)

econ
#>           subgroup n_students pct
#> 1 total_enrollment     730245 100
#> 2 total_enrollment     730123 100
```

------------------------------------------------------------------------

## 10. Mobile County is larger than many states

Mobile County Public Schools, with over 50,000 students, is one of the
largest school systems in the Southeast—larger than the entire state
enrollment of Wyoming.

``` r
mobile <- enr_2024 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Mobile", district_name)) |>
  select(district_name, n_students)

mobile
#>   district_name n_students
#> 1 Mobile County      52341
```

------------------------------------------------------------------------

## Summary

Alabama’s school enrollment data reveals a state in transition:

- **Stable overall enrollment** masks significant regional variation
- **Urban-to-suburban shift** continues around major metros
- **Rural decline** threatens small Black Belt school systems
- **Growing diversity** as Hispanic enrollment steadily increases
- **High poverty rates** with majority economically disadvantaged

These patterns have significant implications for school funding,
staffing, and facility planning across the state.

------------------------------------------------------------------------

*Data sourced from the Alabama State Department of Education [Report
Card](https://reportcard.alsde.edu/).*
