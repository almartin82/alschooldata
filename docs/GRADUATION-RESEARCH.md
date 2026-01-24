# Alabama Graduation Rate Data Research

**Research Date:** 2026-01-10
**State:** Alabama (AL)
**Package:** alschooldata

---

## Executive Summary

**Viability Tier:** TIER 4 - SKIP

**Recommendation:** DO NOT IMPLEMENT graduation rate data for Alabama at this time.

**Rationale:** The Alabama State Department of Education (ALSDE) Report Card system requires JavaScript-rendered UI interactions to access graduation rate data. While the data is available through https://reportcard.alsde.edu/ with CSV export functionality, there are NO direct download URLs, NO public API endpoints, and NO static file links. The site relies entirely on DevExpress-based interactive grids with server-side pagination and filtering. Accessing this data would require browser automation (Selenium/Playwright) or reverse-engineering proprietary AJAX endpoints, both of which violate project constraints.

---

## Data Sources Investigated

### 1. ALSDE Federal Report Card - CCR & Graduation Rate

**URL:** https://reportcard.alsde.edu/SupportingData_CCRGradRate.aspx

**Assessment:** NOT VIABLE - JavaScript-rendered interactive grid

**Details:**
- DevExpress-based data grid with server-side pagination
- Shows "Page 1 of 27,607 (248,456 items)" indicating massive dataset
- Has "Export to CSV" and "Export to XLSX" buttons
- **CRITICAL ISSUE:** Export triggers JavaScript function, not direct file URL
- Data includes:
  - Year (2024 available)
  - System/School names
  - All SubPopulation (total students)
  - Subgroups: English Learners, Homeless, Migrant, Students with Disabilities, Economically Disadvantaged, Foster, Military Family
  - Counts and percentages for graduates and CCR attainment

**Sample Data Structure (from HTML table):**
```
Year: 2024
System: Alabama State Department of Education
SubPopulation: All SubPopulation
Student Count: 52,928
Graduates: 47,656
Graduation Rate: 90.04%
CCR Attainment: 44,563
CCR Rate: 84.20%

Subgroup examples:
- English Learners: 1,442 students, 71.98% grad rate
- Students with Disabilities: 4,907 students, 77.71% grad rate
- Economically Disadvantaged: 30,305 students, 86.49% grad rate
```

**Why Not Viable:**
- No static CSV/Excel download URL
- Requires JavaScript to render data grid
- Export button triggers client-side generation, not server file
- Pagination requires multiple AJAX requests to scrape all data
-DevExpress grid relies on proprietary callbacks (DXR.axd)

---

### 2. ALSDE Federal Report Card - Main Supporting Data

**URL:** https://reportcard.alsde.edu/SupportingData.aspx?ReportYear=2024&SystemCode=000

**Assessment:** NOT VIABLE - JavaScript-rendered, requires UI interaction

**Details:**
- Multiple data tabs: Accountability, Student Demographics, Participation & Proficiency, CCR & Graduation Rate, Educator Credentials
- Each tab has separate DevExpress grid
- "Export to XLSX" and "Export to CSV" buttons present
- Shows "No data to display" until filters applied or data loads via AJAX
- Column chooser UI element indicates client-side rendering

**Why Not Viable:**
- Same issues as #1 - JavaScript-dependent
- No direct API endpoints documented
- Requires session management for DevExpress callbacks
- Multiple tabs would require complex navigation logic

---

### 3. ALSDE State Report Card - Accountability Data

**URL:** https://statereportcard.alsde.edu/SupportingData_Accountability.aspx

**Assessment:** NOT VIABLE - JavaScript-rendered with different data structure

**Details:**
- Shows accountability indicators including graduation rate
- "Page 1 of 1,001 (100,056 items)"
- Data structure differs from Federal Report Card
- Contains columns for:
  - System Name, School Name
  - Indicator Type (Graduation Rate, CCR, Chronic Absenteeism, etc.)
  - Grade, Gender, Race, Ethnicity, SubPopulation
  - Score values

**Sample Data (statewide, all students):**
```
System: Alabama State Department of Education
Indicator: Graduation Rate
Grade: All Grades
Race: All Race
SubPopulation: All SubPopulation
Score: 90.04

Indicator: Graduation Rate
SubPopulation: Students with Disabilities
Score: 77.71

Indicator: Graduation Rate
SubPopulation: English Learners
Score: 71.98
```

**Why Not Viable:**
- Same technical barriers as Federal Report Card
- Different data format would require separate parsing logic
- Still requires browser automation or AJAX reverse-engineering

---

### 4. Historical Data by Year

**URL Pattern:** https://reportcard.alsde.edu/SupportingData.aspx?ReportYear={YEAR}&SystemCode=000

**Years Tested:**
- 2024: Available (graduation rate: 90.04%)
- 2023: Available (site accessible)
- 2022: Available (site accessible)
- 2021: Network errors when accessing
- 2020: Available at https://reportcard.alsde.edu/Alsde/OverallScorePage/?schoolCode=0000&systemCode=000&year=2020

**Historical Graduation Rates (from news articles):**
- 2024: 90.04%
- 2023: 88.21%
- 2022: 88.2% (dropped below 90%)
- 2021: ~90%
- 2020: 91.7% (COVID waiver year - data incomplete)
- 2019: 91.7%

**Assessment:** NOT VIABLE - Even if available, same technical constraints apply

---

### 5. ALSDE Main Website

**URL:** https://www.alsde.edu/
**Reports Section:** https://www.alsde.edu/sec/sec/ASD/ASD.aspx

**Assessment:** NOT VIABLE - No direct graduation rate downloads

**Findings:**
- Main ALSDE site focuses on enrollment data (already implemented in alschooldata)
- Graduation rate reports appear to only be through Report Card portal
- No static Excel/CSV files found for graduation rates
- "Data Downloads" section leads to Report Card portal

---

## Technical Barriers

### DevExpress Grid Framework

All ALSDE Report Card pages use DevExpress ASP.NET MVC controls with:
- **Server-side callbacks:** Data loads via `DXR.axd?r=1_89-XXXXXX` endpoints
- **ViewState dependencies:** Requires session state management
- **Dynamic callbacks:** Grid paging/filtering uses POST requests with complex payloads
- **Export handlers:** CSV/XLSX generation happens server-side after button click

**Example callback URL pattern:**
```
https://reportcard.alsde.edu/DXR.axd?r=1_89-0hmrm
```

These are NOT REST API endpoints - they're proprietary DevExpress callback handlers.

### No Public API Documentation

Searches for:
- "ALSDE API documentation"
- "reportcard.alsde.edu API endpoint"
- "SupportingData_CCRGradRate API"

**Result:** Zero relevant results. No public API exists.

### No Static File Downloads

Unlike some states that provide:
- Direct CSV URLs (e.g., `https://example.gov/data/graduation_rates_2024.csv`)
- Static Excel files in predictable paths
- FTP sites with archived data

Alabama's system is 100% interactive and session-based.

---

## Data Structure (If Accessible)

Based on HTML table inspection, the graduation rate data includes:

### Columns Identified
1. **Year** - Academic year (2021, 2022, 2023, 2024)
2. **System Code** - 3-digit district code (000 = state)
3. **System Name** - District name
4. **School Code** - 4-digit school code
5. **School Name** - School name
6. **SubPopulation** - Demographic subgroup
7. **Student Count** - Total cohort size
8. **Graduates** - Number graduating
9. **Graduation %** - Graduation rate percentage
10. **CCR Attainment** - College & Career Ready count
11. **CCR %** - CCR percentage

### Subgroups Available
- All SubPopulation (total)
- Students with Limited English Proficiency (English Learners)
- Homeless
- Migrant
- Students with Disabilities
- Economically Disadvantaged
- Foster
- Military Family

**Missing:** Race/ethnicity breakdowns in CCR & Graduation Rate view (available in Accountability view but different structure)

### Geographic Levels
- **State:** SystemCode = 000, SchoolCode = 0000
- **District:** SystemCode = XXX, SchoolCode = 0000
- **School:** SystemCode = XXX, SchoolCode = XXXX

**Note:** System codes in Alabama:
- 001-067: County systems
- 100+: City systems

---

## Historical Data Availability

| Year | Graduation Rate | COVID Impact | Data Access |
|------|----------------|--------------|-------------|
| 2024 | 90.04% | None | Report Card accessible |
| 2023 | 88.21% | None | Report Card accessible |
| 2022 | 88.2% | None | Report Card accessible |
| 2021 | ~90% | Some disruption | Network errors on test |
| 2020 | 91.7% | Federal waiver - incomplete | Report Card accessible |
| 2019 | 91.7% | None | Likely available |
| 2018 | ~89% | None | May be available |
| 2017 | ~89% | None | May be available |
| 2016-2015 | Unknown | None | Unlikely |

**Note:** Due to COVID-19, the US Department of Education waived accountability reporting requirements for 2019-2020, so graduation rate data may be incomplete or calculated differently for 2020.

---

## Alternative Approaches Considered

### 1. Browser Automation (Selenium/Playwright)

**Pros:**
- Can interact with JavaScript UI
- Can click export buttons
- Proven technology

**Cons:**
- **VIOLATES PROJECT CONSTRAINTS** - "Avoid: JavaScript-rendered sites"
- Heavy maintenance burden
- Slow execution time
- Requires headless browser infrastructure
- Brittle - breaks when UI changes
- CI/CD complexity

**Decision:** REJECTED

### 2. Reverse-Engineer DevExpress AJAX Endpoints

**Pros:**
- Could potentially access raw data
- No browser required

**Cons:**
- DevExpress callbacks are proprietary and undocumented
- Requires complex POST request payloads
- Session management complexity
- High maintenance if ALSDE upgrades DevExpress version
- May violate Terms of Service
- No public documentation to reference

**Decision:** REJECTED

### 3. Contact ALSDE for Direct Data Access

**Pros:**
- Could get CSV files directly
- Official data source
- Potential for automated future access

**Cons:**
- No guarantee they'll provide data
- May require Data Use Agreement
- Timeline uncertain
- One-time download vs. automated updates

**Decision:** POSSIBLE - but not for initial implementation

### 4. Use Archived Data Downloads

**Search for:**
- ALSDE historical CSV downloads
- Archived report card data
- Third-party aggregators with Alabama graduation data

**Results:**
- No static CSV/XLSX files found
- No third-party aggregators with raw data
- Alabama Achieves website (alabamaachieves.org) has PDF reports only

**Decision:** NOT AVAILABLE

---

## Comparison with Enrollment Data Implementation

The current alschooldata package successfully fetches enrollment data from ALSDE because:

**Enrollment Data Structure:**
- Static DevExpress grid with server-side rendering
- Predictable URL pattern: `SupportingData_Educator_Infiled.aspx` (educator data)
- Direct HTML table parsing possible
- Columns: Year, SystemCode, System, SchoolCode, School, Grade, Gender, Ethnicity, SubPopulation, racial counts + percentages

**Graduation Rate Data Structure:**
- SAME framework but different implementation
- Client-side DevExpress grid with AJAX callbacks
- Export buttons trigger JavaScript, not file downloads
- 27,607 pages vs. manageable dataset size

**Key Difference:** Enrollment data pages load complete HTML tables. Graduation rate pages use deferred loading with DevExpress callbacks.

---

## Recommendation

**DO NOT IMPLEMENT Alabama graduation rate data at this time.**

### Reasons:

1. **Technical Constraints:**
   - No direct download URLs
   - JavaScript-dependent interactive grids
   - No public API
   - Requires browser automation (prohibited by project rules)

2. **Maintenance Burden:**
   - High fragility - UI changes break scraping
   - Complex session management
   - Reverse-engineering undocumented DevExpress callbacks

3. **Project Alignment:**
   - Violates "Avoid: JavaScript-rendered sites" rule
   - Violates "Avoid: sites requiring browser automation" rule
   - Project prioritizes sustainable, low-maintenance data sources

4. **Data Availability:**
   - Only 4-5 years of readily accessible data (2020-2024)
   - 2020 data incomplete due to COVID waiver
   - No historical depth beyond Report Card era

### Future Options:

1. **Monitor ALSDE for API Development:**
   - Check if ALSDE releases a REST API
   - Look for static CSV exports in future
   - Federal requirements may drive API adoption

2. **Contact ALSDE Directly:**
   - Request bulk data download access
   - Inquire about automated data sharing agreements
   - May be viable for research purposes

3. **Re-evaluate if Technical Barriers Change:**
   - If ALSDE migrates to modern API
   - If static file downloads become available
   - If project rules around browser automation change

---

## Sources

1. [ALSDE Federal Report Card - CCR & Graduation Rate](https://reportcard.alsde.edu/SupportingData_CCRGradRate.aspx)
2. [ALSDE Federal Report Card - Supporting Data](https://reportcard.alsde.edu/SupportingData.aspx?ReportYear=2024&SystemCode=000)
3. [ALSDE State Report Card - Accountability](https://statereportcard.alsde.edu/SupportingData_Accountability.aspx)
4. [ALSDE Federal Report Card - 2020 Data](https://reportcard.alsde.edu/Alsde/OverallScorePage/?schoolCode=0000&systemCode=000&year=2020)
5. [ALSDE Main Website](https://www.alsde.edu/)
6. [ALSDE Reports & Data](https://www.alabamaachieves.org/reports-data/)
7. [Alabama Reflector - 91% Graduation Rate Article](https://alabamareflector.com/2025/06/17/alabama-public-high-school-graduation-rate-reaches-91-says-alsde/)
8. [AL.com - Class of 2022 Graduation Rates](https://www.al.com/news/2023/02/alabama-class-of-2022-graduation-rates-drop-below-90.html)
9. [Navigating the Alabama Education Report Card (PDF)](https://www.alabamaachieves.org/wp-content/uploads/2021/10/Navigating-the-Alabama-Education-Report-Card.pdf)

---

## Appendix: Sample Data Records

### Statewide Graduation Rate (2024)
```
Year: 2024
System: Alabama State Department of Education
School: Alabama State Department of Education
All Grades
All Gender
All Race
All Ethnicity
All SubPopulation
Student Count: 52,928
Graduates: 47,656
Graduation Rate: 90.04%
CCR Attainment: 44,563
CCR Rate: 84.20%
```

### Subgroup: Students with Disabilities (2024)
```
Year: 2024
SubPopulation: Students with Disabilities
Student Count: 4,907
Graduates: 3,813
Graduation Rate: 77.71%
CCR Attainment: 3,160
CCR Rate: 64.40%
```

### Subgroup: English Learners (2024)
```
Year: 2024
SubPopulation: Students with Limited English Proficiency
Student Count: 1,442
Graduates: 1,038
Graduation Rate: 71.98%
CCR Attainment: 780
CCR Rate: 54.09%
```

### Subgroup: Economically Disadvantaged (2024)
```
Year: 2024
SubPopulation: Economically Disadvantaged
Student Count: 30,305
Graduates: 26,212
Graduation Rate: 86.49%
CCR Attainment: 23,783
CCR Rate: 78.48%
```

**Data Suppression Notes:**
- `*` = number of students ≤ 10 OR total minus subgroup ≤ 10
- `~` = percentage ≥ 95% or ≤ 5%
- Some subgroups may have suppressed data for small populations

---

**End of Research Report**
