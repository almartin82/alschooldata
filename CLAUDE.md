# alschooldata Package

R package for downloading and processing Alabama school enrollment data from the Alabama State Department of Education (ALSDE).

## Data Source

**ALSDE Federal Report Card Student Demographics**
- URL: https://reportcard.alsde.edu/SupportingData_StudentDemographics.aspx
- Available Years: 2015-2025 (school year end years, e.g., 2025 = 2024-25)
- Data Format: CSV export via ASP.NET form submission
- Update Frequency: Annually, typically available in fall

## How Data Download Works

The Federal Report Card page uses ASP.NET ViewState for form handling:
1. GET the page to extract `__VIEWSTATE`, `__VIEWSTATEGENERATOR`, and `__EVENTVALIDATION` hidden fields
2. POST with the year selection and "Export to CSV" button to download data
3. Parse the returned CSV file

## Available Data Fields

The Student Demographics export includes:
- System (district) and school identifiers
- Total enrollment counts
- Race/ethnicity breakdowns: White, Black/African American, Hispanic/Latino, Asian, American Indian/Alaska Native, Native Hawaiian/Pacific Islander, Two or More Races
- Gender: Male, Female
- Special populations: Economically Disadvantaged, English Learners, Students with Disabilities

## Alabama ID System

- **System Codes**: 3-digit codes (001-067 for counties, 100+ for cities)
- **School Codes**: 4-digit codes unique within each system
- Combined format: "SSS-CCCC" (e.g., "001-0010")

## Important Notes

- Data is sourced ONLY from ALSDE - no federal data sources (NCES CCD, Urban Institute API)
- Minimum year available is 2015 (2014-15 school year)
- The ALSDE website may occasionally be unavailable; built-in error handling provides informative messages
- Large exports may take up to 10 minutes to complete

## Key Functions

- `fetch_enr(end_year)` - Fetch enrollment data for a single year
- `fetch_enr_multi(start_year, end_year)` - Fetch data for multiple years
- `get_available_years()` - Returns min_year=2015, max_year=2025
- `clear_cache()` - Remove cached data files

## Testing

Before releasing, test downloads for multiple years:
```r
# Test recent year
enr_2025 <- fetch_enr(2025)

# Test oldest available year
enr_2015 <- fetch_enr(2015)

# Test multi-year fetch
enr_multi <- fetch_enr_multi(2020, 2025)
```

## Troubleshooting

If downloads fail:
1. Check if ALSDE site is accessible: https://reportcard.alsde.edu/
2. The ASP.NET ViewState may have changed - check if page structure changed
3. Report issues at: https://github.com/almartin82/alschooldata/issues
