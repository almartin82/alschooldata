# Alabama School Data Package Expansion Plan

> Last researched: 2026-01-03 Package: alschooldata Current status:
> R-CMD-check passing, Python tests passing, pkgdown passing

## Current Capabilities

| Data Type           | Status      | Years     | Function                                                                          |
|---------------------|-------------|-----------|-----------------------------------------------------------------------------------|
| Enrollment          | implemented | 2015-2024 | [`fetch_enr()`](https://almartin82.github.io/alschooldata/reference/fetch_enr.md) |
| Graduation Rates    | not started | \-        | \-                                                                                |
| Assessments         | not started | \-        | \-                                                                                |
| Chronic Absenteeism | not started | \-        | \-                                                                                |

## State DOE Data Sources

### Data Portal Overview

- **Main data portal**: <https://www.alabamaachieves.org/reports-data/>
- **Student data page**:
  <https://www.alabamaachieves.org/reports-data/student-data/>
- **Federal Report Card**: <https://reportcard.alsde.edu/>
- **API availability**: No public API - uses ASP.NET web forms with CSV
  export

### Available Data Types at State DOE

#### Enrollment (IMPLEMENTED)

- **URL**:
  <https://reportcard.alsde.edu/SupportingData_StudentDemographics.aspx>
- **Format**: CSV export via ASP.NET postback
- **Years available**: 2015-2024
- **Update frequency**: Annual (typically available by October)
- **Access method**: Web form POST with ViewState
- **Notes**: Requires parsing ASP.NET form fields. Includes
  race/ethnicity, gender, special populations at school level.

#### Graduation Rates

- **URL**: <https://reportcard.alsde.edu/SupportingData_Graduation.aspx>
- **Status**: Available - needs implementation
- **Format**: CSV export via same ASP.NET pattern as enrollment
- **Years available**: 2015-2024 (4-year, 5-year cohort rates)
- **Notes**: Same access pattern as enrollment - can reuse
  [`retry_with_backoff()`](https://almartin82.github.io/alschooldata/reference/retry_with_backoff.md)
  and ViewState parsing. Includes rates by subgroup.

#### Assessments (ACAP)

- **URL**: <https://reportcard.alsde.edu/SupportingData_Assessment.aspx>
- **Status**: Available - needs implementation
- **Format**: CSV export
- **Years available**: 2019-2024 (ACAP replaced previous assessments in
  2019)
- **Notes**: Alabama Comprehensive Assessment Program (ACAP). Grades 2-8
  and high school. ELA, Math, Science subjects.

#### Chronic Absenteeism

- **URL**: <https://reportcard.alsde.edu/SupportingData_Attendance.aspx>
- **Status**: Available - needs implementation
- **Format**: CSV export
- **Years available**: 2018-2024
- **Notes**: Includes chronic absence rates by subgroup at school level.

#### Educator Demographics

- **URL**:
  <https://reportcard.alsde.edu/SupportingData_Educator_Demographics.aspx>
- **Status**: Available - lower priority
- **Format**: CSV export
- **Notes**: Teacher demographics by school/district.

#### Discipline Data

- **URL**: <https://reportcard.alsde.edu/SupportingData_Discipline.aspx>
- **Status**: Available - lower priority
- **Format**: CSV export
- **Notes**: Discipline incidents and actions by school.

## Implementation Queue

Priority order for implementation. Each item follows the raw→tidy
pipeline.

### Priority 1: Graduation Rates

**Requirements:** - \[ \] `get_raw_grad(end_year)` - Download from
Federal Report Card Graduation page - \[ \]
`process_grad(raw, end_year)` - Standardize column names - \[ \]
`tidy_grad(df)` - Convert to long format with subgroups - \[ \]
`fetch_grad(end_year, tidy=TRUE)` - Public API - \[ \]
`fetch_grad_multi(end_years, tidy=TRUE)` - Multi-year convenience
function

**Implementation Notes:** - Reuse existing ASP.NET patterns from
`get_raw_enrollment.R`: -
[`retry_with_backoff()`](https://almartin82.github.io/alschooldata/reference/retry_with_backoff.md)
function - ViewState parsing with rvest - POST request with form data -
Same URL pattern:
`https://reportcard.alsde.edu/SupportingData_Graduation.aspx` - Form
field for year: `ctl00$ContentPlaceHolder1$ddlYear` - Export button:
`ctl00$ContentPlaceHolder1$btnExportCSV` - Expected columns: System
Code, School Code, School Name, Cohort Year, subgroup rates

**Test Requirements:** - \[ \] URL returns HTTP 200
(test-pipeline-live.R) - \[ \] File download returns CSV not HTML (size
\> 1000 bytes) - \[ \] File parsing with readr succeeds - \[ \] Expected
columns present (4-year rate, 5-year rate, subgroups) - \[ \] Year
filtering works correctly - \[ \] Aggregation: state rate is weighted
average of school rates - \[ \] Data quality: rates between 0-100%, no
Inf/NaN - \[ \] Fidelity: tidy output matches raw CSV values exactly

**Estimated complexity**: Low (reuses existing patterns)

------------------------------------------------------------------------

### Priority 2: Assessments (ACAP)

**Requirements:** - \[ \] `get_raw_assess(end_year, subject)` - Download
assessment data - \[ \] `process_assess(raw, end_year, subject)` -
Standardize columns - \[ \] `tidy_assess(df)` - Long format with
proficiency levels - \[ \]
`fetch_assess(end_year, subject=NULL, tidy=TRUE)` - Public API

**Implementation Notes:** - Same ASP.NET pattern as enrollment and
graduation - URL:
`https://reportcard.alsde.edu/SupportingData_Assessment.aspx` - May have
subject filter dropdown (ELA, Math, Science) - Proficiency levels: Level
1, Level 2, Level 3, Level 4 (or similar) - Includes percent proficient
and N tested by subgroup

**Test Requirements:** - \[ \] All 8 test categories from CLAUDE.md - \[
\] Subject filtering works (ELA, Math, Science) - \[ \] Grade level
filtering works - \[ \] Proficiency percentages sum correctly - \[ \]
Raw value fidelity for specific schools/years

**Estimated complexity**: Medium (new subject dimension)

------------------------------------------------------------------------

### Priority 3: Chronic Absenteeism

**Requirements:** - \[ \] `get_raw_absence(end_year)` - Download absence
data - \[ \] `process_absence(raw, end_year)` - Standardize columns - \[
\] `tidy_absence(df)` - Long format with subgroups - \[ \]
`fetch_absence(end_year, tidy=TRUE)` - Public API

**Implementation Notes:** - Same ASP.NET pattern - URL:
`https://reportcard.alsde.edu/SupportingData_Attendance.aspx` - Chronic
absence = 15+ days absent - Includes rates by subgroup

**Test Requirements:** - \[ \] Standard 8 test categories - \[ \] Rates
between 0-100% - \[ \] Subgroup presence (race, gender, special
populations)

**Estimated complexity**: Low

------------------------------------------------------------------------

## Research Log

### 2026-01-03

- Confirmed Federal Report Card site structure at reportcard.alsde.edu
- All supporting data pages use same ASP.NET export pattern
- Available data types: Enrollment (done), Graduation, Assessment,
  Attendance, Discipline, Educator Demographics
- Priority recommendation: Graduation rates (low complexity, high value,
  reuses existing code)
- Noted ACAP replaced previous state assessments in 2019

------------------------------------------------------------------------

## Blocked / Not Available

| Data Type            | Reason                      | Alternative Source?          |
|----------------------|-----------------------------|------------------------------|
| Pre-2015 Enrollment  | Not on Federal Report Card  | May exist elsewhere on ALSDE |
| Pre-2019 Assessments | Different assessment system | Legacy data may be archived  |
