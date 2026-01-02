## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  message = FALSE,
  warning = FALSE,
  fig.width = 8,
  fig.height = 5,
  eval = FALSE
)

## ----load-packages------------------------------------------------------------
# library(alschooldata)
# library(dplyr)
# library(tidyr)
# library(ggplot2)
# 
# theme_set(theme_minimal(base_size = 14))

## ----statewide-trend----------------------------------------------------------
# enr <- fetch_enr_multi(2015:2025)
# 
# state_totals <- enr |>
#   filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
#   select(end_year, n_students) |>
#   mutate(change = n_students - lag(n_students),
#          pct_change = round(change / lag(n_students) * 100, 2))
# 
# state_totals

## ----statewide-chart----------------------------------------------------------
# ggplot(state_totals, aes(x = end_year, y = n_students)) +
#   geom_line(linewidth = 1.2, color = "#9B1B30") +
#   geom_point(size = 3, color = "#9B1B30") +
#   scale_y_continuous(labels = scales::comma, limits = c(700000, 750000)) +
#   scale_x_continuous(breaks = 2015:2025) +
#   labs(
#     title = "Alabama Public School Enrollment (2015-2025)",
#     subtitle = "Statewide enrollment has remained remarkably stable",
#     x = "School Year (ending)",
#     y = "Total Enrollment"
#   )

## ----covid-grades-------------------------------------------------------------
# covid_grades <- enr |>
#   filter(is_state, subgroup == "total_enrollment",
#          grade_level %in% c("K", "01", "06", "09"),
#          end_year %in% 2019:2023) |>
#   select(end_year, grade_level, n_students) |>
#   pivot_wider(names_from = end_year, values_from = n_students) |>
#   mutate(change_2019_2021 = `2021` - `2019`,
#          pct_drop = round(change_2019_2021 / `2019` * 100, 1))
# 
# covid_grades

## ----covid-chart--------------------------------------------------------------
# enr |>
#   filter(is_state, subgroup == "total_enrollment",
#          grade_level %in% c("K", "01", "06", "09"),
#          end_year %in% 2019:2023) |>
#   mutate(grade_level = factor(grade_level,
#                               levels = c("K", "01", "06", "09"),
#                               labels = c("Kindergarten", "1st Grade", "6th Grade", "9th Grade"))) |>
#   ggplot(aes(x = end_year, y = n_students, color = grade_level)) +
#   geom_line(linewidth = 1.2) +
#   geom_point(size = 2) +
#   scale_y_continuous(labels = scales::comma) +
#   labs(
#     title = "COVID Impact by Grade Level",
#     subtitle = "Kindergarten enrollment dropped sharply in 2021",
#     x = "School Year",
#     y = "Enrollment",
#     color = "Grade"
#   )

## ----top-districts------------------------------------------------------------
# enr_2025 <- fetch_enr(2025)
# 
# top_10 <- enr_2025 |>
#   filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
#   arrange(desc(n_students)) |>
#   head(10) |>
#   select(district_name, n_students)
# 
# top_10

## ----top-districts-chart------------------------------------------------------
# top_10 |>
#   mutate(district_name = forcats::fct_reorder(district_name, n_students)) |>
#   ggplot(aes(x = n_students, y = district_name)) +
#   geom_col(fill = "#9B1B30") +
#   scale_x_continuous(labels = scales::comma) +
#   labs(
#     title = "Alabama's 10 Largest School Systems (2025)",
#     x = "Total Enrollment",
#     y = NULL
#   )

## ----birmingham-suburbs-------------------------------------------------------
# bham_area <- enr |>
#   filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
#          grepl("Hoover|Vestavia|Mountain Brook|Birmingham", district_name)) |>
#   select(end_year, district_name, n_students) |>
#   pivot_wider(names_from = end_year, values_from = n_students)
# 
# bham_area

## ----suburb-chart-------------------------------------------------------------
# enr |>
#   filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
#          grepl("Hoover|Vestavia|Mountain Brook|Birmingham City", district_name),
#          end_year >= 2018) |>
#   ggplot(aes(x = end_year, y = n_students, color = district_name)) +
#   geom_line(linewidth = 1.2) +
#   geom_point(size = 2) +
#   scale_y_continuous(labels = scales::comma) +
#   labs(
#     title = "Birmingham Metro Area Enrollment Trends",
#     subtitle = "Urban districts decline while suburbs hold steady",
#     x = "School Year",
#     y = "Enrollment",
#     color = "District"
#   )

## ----black-belt---------------------------------------------------------------
# black_belt <- enr |>
#   filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
#          grepl("Perry|Wilcox|Greene|Sumter", district_name, ignore.case = TRUE)) |>
#   group_by(district_name) |>
#   summarize(
#     y2020 = n_students[end_year == 2020],
#     y2025 = n_students[end_year == 2025],
#     pct_change = round((y2025 / y2020 - 1) * 100, 1),
#     .groups = "drop"
#   ) |>
#   arrange(pct_change)
# 
# black_belt

## ----demographics-------------------------------------------------------------
# demographics <- enr_2025 |>
#   filter(is_state, grade_level == "TOTAL",
#          subgroup %in% c("white", "black", "hispanic", "asian", "multiracial")) |>
#   mutate(pct = round(pct * 100, 1)) |>
#   select(subgroup, n_students, pct) |>
#   arrange(desc(n_students))
# 
# demographics

## ----demographics-chart-------------------------------------------------------
# demographics |>
#   mutate(subgroup = forcats::fct_reorder(subgroup, n_students)) |>
#   ggplot(aes(x = n_students, y = subgroup, fill = subgroup)) +
#   geom_col(show.legend = FALSE) +
#   geom_text(aes(label = paste0(pct, "%")), hjust = -0.1) +
#   scale_x_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
#   scale_fill_brewer(palette = "Set2") +
#   labs(
#     title = "Alabama Student Demographics (2025)",
#     x = "Number of Students",
#     y = NULL
#   )

## ----hispanic-trend-----------------------------------------------------------
# hispanic_trend <- enr |>
#   filter(is_state, subgroup == "hispanic", grade_level == "TOTAL") |>
#   mutate(pct = round(pct * 100, 2)) |>
#   select(end_year, n_students, pct)
# 
# hispanic_trend

## ----hispanic-chart-----------------------------------------------------------
# ggplot(hispanic_trend, aes(x = end_year, y = pct)) +
#   geom_line(linewidth = 1.2, color = "#2E8B57") +
#   geom_point(size = 3, color = "#2E8B57") +
#   scale_x_continuous(breaks = 2015:2025) +
#   labs(
#     title = "Hispanic Student Enrollment Growth",
#     subtitle = "Steady increase from 4.5% to nearly 7% over 10 years",
#     x = "School Year",
#     y = "Percent of Total Enrollment"
#   )

## ----madison-growth-----------------------------------------------------------
# madison <- enr |>
#   filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
#          grepl("Madison|Huntsville", district_name)) |>
#   group_by(district_name) |>
#   summarize(
#     y2020 = n_students[end_year == 2020],
#     y2025 = n_students[end_year == 2025],
#     pct_change = round((y2025 / y2020 - 1) * 100, 1),
#     .groups = "drop"
#   ) |>
#   arrange(desc(pct_change))
# 
# madison

## ----econ-disadv--------------------------------------------------------------
# econ <- enr_2025 |>
#   filter(is_state, grade_level == "TOTAL",
#          subgroup %in% c("econ_disadv", "total_enrollment")) |>
#   select(subgroup, n_students, pct)
# 
# econ

## ----mobile-------------------------------------------------------------------
# mobile <- enr_2025 |>
#   filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
#          grepl("Mobile", district_name)) |>
#   select(district_name, n_students)
# 
# mobile

