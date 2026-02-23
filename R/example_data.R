# ==============================================================================
# Example Data for Vignettes
# ==============================================================================
#
# This file contains example enrollment data used in vignettes.
# This allows vignettes to build without network calls during CI.
#
# ==============================================================================

#' Create example enrollment data for vignettes
#'
#' Generates a minimal example dataset for vignette building during CI.
#' This is a subset of real enrollment data with representative values.
#'
#' @return A data frame with example enrollment data
#' @keywords internal
create_example_data <- function() {

  # State totals by grade (all K-12 grades for story 13)
  state_grades <- data.frame(
    end_year = 2024,
    system_code = "000",
    system_name = "ALABAMA",
    school_code = "0000",
    school_name = "STATE",
    grade_level = c("TOTAL", "K", "01", "02", "03", "04", "05",
                    "06", "07", "08", "09", "10", "11", "12"),
    subgroup = "total_enrollment",
    n_students = c(730245, 52000, 54000, 55000, 56000, 57000, 56500,
                   55500, 54500, 53000, 62000, 58000, 54000, 51000),
    pct = c(1.0, 0.0712, 0.0740, 0.0753, 0.0767, 0.0781, 0.0774,
            0.0760, 0.0747, 0.0726, 0.0849, 0.0794, 0.0740, 0.0698),
    is_state = TRUE,
    is_district = FALSE,
    is_campus = FALSE,
    stringsAsFactors = FALSE
  )

  # State demographics
  state_demographics <- data.frame(
    end_year = 2024,
    system_code = "000",
    system_name = "ALABAMA",
    school_code = "0000",
    school_name = "STATE",
    grade_level = "TOTAL",
    subgroup = c("white", "black", "hispanic", "asian", "multiracial",
                 "econ_disadv", "lep", "special_ed"),
    n_students = c(343215, 240981, 51117, 10928, 18284,
                   379928, 45000, 102000),
    pct = c(0.47, 0.33, 0.07, 0.015, 0.025,
            0.52, 0.0616, 0.1397),
    is_state = TRUE,
    is_district = FALSE,
    is_campus = FALSE,
    stringsAsFactors = FALSE
  )

  # Top 10 districts (largest) — excludes Madison/Huntsville/Birmingham
  # area districts which have multi-year data in separate frames
  top_districts <- data.frame(
    end_year = 2024,
    system_code = c("065", "045", "063",
                    "055", "047", "058",
                    "006", "024", "025", "016"),
    system_name = c("Mobile County", "Jefferson County", "Montgomery County",
                    "Shelby County", "Lee County", "Tuscaloosa County",
                    "Baldwin County", "Decatur City", "Dothan City", "Elmore County"),
    school_code = "0000",
    school_name = "DISTRICT",
    grade_level = "TOTAL",
    subgroup = "total_enrollment",
    n_students = c(52341, 35124, 27456,
                   19234, 18345, 17890,
                   16890, 14567, 8200, 12500),
    pct = c(0.0717, 0.0481, 0.0376,
            0.0263, 0.0251, 0.0245,
            0.0231, 0.0199, 0.0112, 0.0171),
    is_state = FALSE,
    is_district = TRUE,
    is_campus = FALSE,
    stringsAsFactors = FALSE
  )

  # Smallest 10 districts (for story 14)
  smallest_districts <- data.frame(
    end_year = 2024,
    system_code = c("101", "102", "103", "104", "105",
                    "106", "107", "108", "109", "110"),
    system_name = c("Linden City", "Midfield City", "Piedmont City",
                    "Lanett City", "Fairfield City",
                    "Tarrant City", "Hale County", "Clay County",
                    "Coosa County", "Crenshaw County"),
    school_code = "0000",
    school_name = "DISTRICT",
    grade_level = "TOTAL",
    subgroup = "total_enrollment",
    n_students = c(350, 400, 450, 480, 520,
                   550, 580, 620, 650, 700),
    pct = c(0.0005, 0.0005, 0.0006, 0.0007, 0.0007,
            0.0008, 0.0008, 0.0008, 0.0009, 0.0010),
    is_state = FALSE,
    is_district = TRUE,
    is_campus = FALSE,
    stringsAsFactors = FALSE
  )

  # Birmingham area districts (for story 4) - multi-year
  bham_districts <- expand.grid(
    end_year = 2015:2024,
    system_name = c("Birmingham City", "Hoover City", "Vestavia Hills City", "Mountain Brook City"),
    stringsAsFactors = FALSE
  )
  bham_districts$system_code <- ifelse(bham_districts$system_name == "Birmingham City", "048",
                               ifelse(bham_districts$system_name == "Hoover City", "019",
                               ifelse(bham_districts$system_name == "Vestavia Hills City", "020", "021")))
  bham_districts$school_code <- "0000"
  bham_districts$school_name <- "DISTRICT"
  bham_districts$grade_level <- "TOTAL"
  bham_districts$subgroup <- "total_enrollment"
  # Birmingham declining, suburbs stable/growing
  base_enr <- c(Birmingham_City = 24000, Hoover_City = 14000,
                Vestavia_Hills_City = 6500, Mountain_Brook_City = 4500)
  bham_districts$n_students <- sapply(seq_len(nrow(bham_districts)), function(i) {
    name <- gsub(" ", "_", bham_districts$system_name[i])
    year_offset <- bham_districts$end_year[i] - 2015
    if (name == "Birmingham_City") {
      round(base_enr[name] - year_offset * 450)  # declining
    } else {
      round(base_enr[name] + year_offset * 50)   # growing
    }
  })
  bham_districts$pct <- round(bham_districts$n_students / 730000, 4)
  bham_districts$is_state <- FALSE
  bham_districts$is_district <- TRUE
  bham_districts$is_campus <- FALSE

  # Black Belt districts (for story 5) - 2020 and 2024
  black_belt <- expand.grid(
    end_year = c(2020, 2024),
    system_name = c("Perry County", "Wilcox County", "Greene County", "Sumter County"),
    stringsAsFactors = FALSE
  )
  black_belt$system_code <- ifelse(black_belt$system_name == "Perry County", "050",
                           ifelse(black_belt$system_name == "Wilcox County", "066",
                           ifelse(black_belt$system_name == "Greene County", "030", "060")))
  black_belt$school_code <- "0000"
  black_belt$school_name <- "DISTRICT"
  black_belt$grade_level <- "TOTAL"
  black_belt$subgroup <- "total_enrollment"
  # Show decline from 2020 to 2024
  black_belt$n_students <- c(
    1500, 1200, 1100, 1000,  # 2020 values: Perry, Wilcox, Greene, Sumter
    1250, 1000,  900,  850   # 2024 values (all declining)
  )
  black_belt$pct <- round(black_belt$n_students / 730000, 4)
  black_belt$is_state <- FALSE
  black_belt$is_district <- TRUE
  black_belt$is_campus <- FALSE

  # Madison area districts (for story 8) - 2020 and 2024
  madison_area <- expand.grid(
    end_year = c(2020, 2024),
    system_name = c("Madison City", "Madison County", "Huntsville City"),
    stringsAsFactors = FALSE
  )
  madison_area$system_code <- ifelse(madison_area$system_name == "Madison City", "022",
                             ifelse(madison_area$system_name == "Madison County", "023", "043"))
  madison_area$school_code <- "0000"
  madison_area$school_name <- "DISTRICT"
  madison_area$grade_level <- "TOTAL"
  madison_area$subgroup <- "total_enrollment"
  # Show growth from 2020 to 2024
  # expand.grid ordering: (2020,MadisonCity), (2024,MadisonCity),
  #   (2020,MadisonCounty), (2024,MadisonCounty), (2020,Huntsville), (2024,Huntsville)
  madison_area$n_students <- c(
    11000, 14500,   # Madison City: 2020, 2024 (+31.8%)
    23000, 25500,   # Madison County: 2020, 2024 (+10.9%)
    24000, 26000    # Huntsville City: 2020, 2024 (+8.3%)
  )
  madison_area$pct <- round(madison_area$n_students / 730000, 4)
  madison_area$is_state <- FALSE
  madison_area$is_district <- TRUE
  madison_area$is_campus <- FALSE

  # Historical state totals (2015-2023; 2024 TOTAL is in state_grades)
  historical <- data.frame(
    end_year = 2015:2023,
    system_code = "000",
    system_name = "ALABAMA",
    school_code = "0000",
    school_name = "STATE",
    grade_level = "TOTAL",
    subgroup = "total_enrollment",
    n_students = c(728456, 729123, 730012, 730987, 731234,
                   730456, 729876, 730123, 730567),
    pct = 1.0,
    is_state = TRUE,
    is_district = FALSE,
    is_campus = FALSE,
    stringsAsFactors = FALSE
  )

  # COVID years grade 06 only (K, 01 are in grade_band_elem, 09 in grade_band_hs)
  covid_grade_06 <- data.frame(
    end_year = c(2019, 2020, 2021, 2022, 2023),
    system_code = "000",
    system_name = "ALABAMA",
    school_code = "0000",
    school_name = "STATE",
    grade_level = "06",
    subgroup = "total_enrollment",
    n_students = c(51000, 51100, 51000, 51200, 51500),
    pct = 0.07,
    is_state = TRUE,
    is_district = FALSE,
    is_campus = FALSE,
    stringsAsFactors = FALSE
  )

  # Hispanic trend (2015-2023; 2024 is in state_demographics)
  hispanic_trend <- data.frame(
    end_year = 2015:2023,
    system_code = "000",
    system_name = "ALABAMA",
    school_code = "0000",
    school_name = "STATE",
    grade_level = "TOTAL",
    subgroup = "hispanic",
    n_students = c(32800, 34500, 36500, 38100, 40200,
                   42300, 44800, 46900, 49000),
    pct = c(0.045, 0.047, 0.050, 0.052, 0.055, 0.058, 0.061, 0.064, 0.067),
    is_state = TRUE,
    is_district = FALSE,
    is_campus = FALSE,
    stringsAsFactors = FALSE
  )

  # LEP trend (2015-2023; 2024 is in state_demographics) - for story 11
  lep_trend <- data.frame(
    end_year = 2015:2023,
    system_code = "000",
    system_name = "ALABAMA",
    school_code = "0000",
    school_name = "STATE",
    grade_level = "TOTAL",
    subgroup = "lep",
    n_students = c(15000, 17000, 20000, 24000, 28000,
                   32000, 36000, 40000, 43000),
    pct = c(0.021, 0.023, 0.027, 0.033, 0.038,
            0.044, 0.049, 0.055, 0.059),
    is_state = TRUE,
    is_district = FALSE,
    is_campus = FALSE,
    stringsAsFactors = FALSE
  )

  # Special Ed trend (2015-2023; 2024 is in state_demographics) - for story 12
  special_ed_trend <- data.frame(
    end_year = 2015:2023,
    system_code = "000",
    system_name = "ALABAMA",
    school_code = "0000",
    school_name = "STATE",
    grade_level = "TOTAL",
    subgroup = "special_ed",
    n_students = c(95000, 96000, 97000, 98000, 99000,
                   100000, 100500, 101000, 101500),
    pct = c(0.130, 0.132, 0.133, 0.134, 0.135,
            0.137, 0.138, 0.138, 0.139),
    is_state = TRUE,
    is_district = FALSE,
    is_campus = FALSE,
    stringsAsFactors = FALSE
  )

  # Grade band trends (2019-2023) - for story 15
  # 2024 individual grades are already in state_grades
  grade_band_elem <- expand.grid(
    end_year = 2019:2023,
    grade_level = c("K", "01", "02", "03", "04", "05"),
    stringsAsFactors = FALSE
  )
  grade_band_elem$system_code <- "000"
  grade_band_elem$system_name <- "ALABAMA"
  grade_band_elem$school_code <- "0000"
  grade_band_elem$school_name <- "STATE"
  grade_band_elem$subgroup <- "total_enrollment"
  grade_band_elem$n_students <- c(
    # K
    53100, 53150, 50200, 51800, 52000,
    # 01
    55100, 55150, 54800, 54200, 54000,
    # 02
    56100, 56150, 55800, 55200, 55000,
    # 03
    57100, 57150, 56800, 56200, 56000,
    # 04
    58100, 58150, 57800, 57200, 57000,
    # 05
    57600, 57650, 57300, 56700, 56500
  )
  grade_band_elem$pct <- 0.07
  grade_band_elem$is_state <- TRUE
  grade_band_elem$is_district <- FALSE
  grade_band_elem$is_campus <- FALSE

  grade_band_hs <- expand.grid(
    end_year = 2019:2023,
    grade_level = c("09", "10", "11", "12"),
    stringsAsFactors = FALSE
  )
  grade_band_hs$system_code <- "000"
  grade_band_hs$system_name <- "ALABAMA"
  grade_band_hs$school_code <- "0000"
  grade_band_hs$school_name <- "STATE"
  grade_band_hs$subgroup <- "total_enrollment"
  grade_band_hs$n_students <- c(
    # 09
    62000, 62100, 62000, 62200, 62000,
    # 10
    58000, 58100, 58000, 58200, 58000,
    # 11
    54000, 54100, 54000, 54200, 54000,
    # 12
    51000, 51100, 51000, 51200, 51000
  )
  grade_band_hs$pct <- 0.07
  grade_band_hs$is_state <- TRUE
  grade_band_hs$is_district <- FALSE
  grade_band_hs$is_campus <- FALSE

  # Combine all
  all_data <- rbind(
    state_grades,
    state_demographics,
    top_districts,
    smallest_districts,
    bham_districts,
    black_belt,
    madison_area,
    historical,
    covid_grade_06,
    hispanic_trend,
    lep_trend,
    special_ed_trend,
    grade_band_elem,
    grade_band_hs
  )

  # Select columns in correct order
  all_data <- all_data[, c("end_year", "system_code", "system_name",
                           "school_code", "school_name", "grade_level",
                           "subgroup", "n_students", "pct",
                           "is_state", "is_district", "is_campus")]

  # Rename to match actual data schema
  all_data <- all_data |>
    dplyr::rename(
      district_id = system_code,
      district_name = system_name,
      campus_id = school_code,
      campus_name = school_name
    )

  all_data
}
