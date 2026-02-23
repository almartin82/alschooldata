# ==============================================================================
# Example Data for Vignettes
# ==============================================================================
#
# This file contains example enrollment data used in vignettes during CI.
# Based on real Alabama enrollment patterns from the ALSDE Federal Report Card.
# Used as a fallback when the ALSDE server is unavailable during automated builds.
#
# Available years: 2021-2025
#
# ==============================================================================

#' Create example enrollment data for vignettes
#'
#' Returns a minimal dataset for vignette building during CI.
#' Based on real enrollment patterns from Alabama DOE data.
#'
#' @return A data frame with example enrollment data
#' @keywords internal
create_example_data <- function() {

  cols <- c("end_year", "district_id", "district_name",
            "campus_id", "campus_name", "type",
            "grade_level", "subgroup", "n_students", "pct")

  make_row <- function(end_year, district_id = NA_character_,
                       district_name = NA_character_,
                       campus_id = NA_character_,
                       campus_name = NA_character_,
                       type = "State",
                       grade_level = "TOTAL",
                       subgroup = "total_enrollment",
                       n_students, pct = NA_real_) {
    data.frame(
      end_year = end_year,
      district_id = district_id,
      district_name = district_name,
      campus_id = campus_id,
      campus_name = campus_name,
      type = type,
      grade_level = grade_level,
      subgroup = subgroup,
      n_students = n_students,
      pct = pct,
      stringsAsFactors = FALSE
    )
  }

  frames <- list()
  fi <- 1

  # ===== STATE TOTALS (2021-2025) =====
  yr_totals <- c(`2021` = 726348, `2022` = 729571, `2023` = 731894,
                 `2024` = 733156, `2025` = 734817)
  for (yr in names(yr_totals)) {
    frames[[fi]] <- make_row(as.integer(yr), n_students = yr_totals[yr], pct = 1.0)
    fi <- fi + 1
  }

  # ===== STATE DEMOGRAPHICS (2021-2025) =====
  demo_data <- list(
    `2021` = list(
      white = 352847, black = 238912, hispanic = 44217, asian = 10183,
      native_american = 4923, pacific_islander = 1587, multiracial = 16873,
      male = 373064, female = 353284,
      econ_disadv = 382741, lep = 35217, special_ed = 96482),
    `2022` = list(
      white = 349213, black = 238541, hispanic = 47893, asian = 10527,
      native_american = 4891, pacific_islander = 1612, multiracial = 17634,
      male = 374817, female = 354754,
      econ_disadv = 384923, lep = 39184, special_ed = 98917),
    `2023` = list(
      white = 346198, black = 238127, hispanic = 51842, asian = 10819,
      native_american = 4873, pacific_islander = 1641, multiracial = 18493,
      male = 376012, female = 355882,
      econ_disadv = 386517, lep = 42893, special_ed = 101284),
    `2024` = list(
      white = 343718, black = 237814, hispanic = 55391, asian = 11042,
      native_american = 4847, pacific_islander = 1659, multiracial = 19217,
      male = 376893, female = 356263,
      econ_disadv = 387914, lep = 45128, special_ed = 102847),
    `2025` = list(
      white = 341278, black = 237491, hispanic = 58934, asian = 11247,
      native_american = 4819, pacific_islander = 1673, multiracial = 19842,
      male = 377614, female = 357203,
      econ_disadv = 389102, lep = 47823, special_ed = 104216)
  )

  for (yr in names(demo_data)) {
    yr_int <- as.integer(yr)
    total <- yr_totals[yr]
    for (sg in names(demo_data[[yr]])) {
      n <- demo_data[[yr]][[sg]]
      frames[[fi]] <- make_row(yr_int, subgroup = sg,
                               n_students = n, pct = n / total)
      fi <- fi + 1
    }
  }

  # ===== STATE GRADE DISTRIBUTION (2021-2025) =====
  grade_base <- c(K = 51847, `01` = 53912, `02` = 54718, `03` = 55312,
                  `04` = 55893, `05` = 55641, `06` = 54817, `07` = 53984,
                  `08` = 53178, `09` = 61284, `10` = 57123, `11` = 52847,
                  `12` = 50412)
  grade_growth <- c(K = 354, `01` = 245, `02` = 254, `03` = 277,
                    `04` = 303, `05` = 302, `06` = 291, `07` = 288,
                    `08` = 278, `09` = 322, `10` = 270, `11` = 267,
                    `12` = 286)

  for (yr in 2021:2025) {
    yr_offset <- yr - 2021
    for (gl in names(grade_base)) {
      n <- as.integer(grade_base[gl] + yr_offset * grade_growth[gl])
      frames[[fi]] <- make_row(yr, grade_level = gl, n_students = n)
      fi <- fi + 1
    }
    # PK row
    pk_n <- as.integer(7812 + yr_offset * 275)
    frames[[fi]] <- make_row(yr, grade_level = "PK", n_students = pk_n)
    fi <- fi + 1
  }

  # ===== DISTRICT DATA =====
  # Districts with multi-year trends (2021-2025)

  district_trends <- list(
    list(id = "049", name = "Mobile County",
         vals = c(52184, 51473, 50912, 50347, 49823)),
    list(id = "037", name = "Jefferson County",
         vals = c(35412, 35018, 34712, 34473, 34217)),
    list(id = "002", name = "Baldwin County",
         vals = c(31284, 31893, 32417, 32918, 33412)),
    list(id = "059", name = "Shelby County",
         vals = c(33847, 34128, 34412, 34647, 34892)),
    list(id = "051", name = "Montgomery County",
         vals = c(28412, 27918, 27493, 27184, 26914)),
    list(id = "130", name = "Huntsville City",
         vals = c(23412, 23891, 24217, 24518, 24831)),
    list(id = "045", name = "Madison County",
         vals = c(22847, 23284, 23712, 23984, 24273)),
    list(id = "110", name = "Birmingham City",
         vals = c(21384, 20817, 20293, 19847, 19417)),
    list(id = "063", name = "Tuscaloosa County",
         vals = c(18217, 18412, 18584, 18763, 18934)),
    list(id = "052", name = "Morgan County",
         vals = c(14817, 14984, 15093, 15184, 15273)),
    list(id = "129", name = "Hoover City",
         vals = c(13847, 13982, 14093, 14187, 14283)),
    list(id = "026", name = "Elmore County",
         vals = c(11712, 11847, 11984, 12084, 12184)),
    list(id = "136", name = "Madison City",
         vals = c(11284, 11693, 12047, 12418, 12817)),
    list(id = "041", name = "Lee County",
         vals = c(9817, 9918, 10047, 10147, 10247)),
    list(id = "116", name = "Decatur City",
         vals = c(8547, 8684, 8793, 8871, 8934)),
    list(id = "118", name = "Dothan City",
         vals = c(9184, 9247, 9312, 9371, 9412)),
    list(id = "138", name = "Vestavia Hills City",
         vals = c(6712, 6741, 6783, 6814, 6847)),
    list(id = "128", name = "Mountain Brook City",
         vals = c(4823, 4847, 4871, 4893, 4912))
  )

  for (dt in district_trends) {
    for (i in 1:5) {
      yr <- 2020 + i
      frames[[fi]] <- make_row(yr, district_id = dt$id,
                               district_name = dt$name,
                               type = "District",
                               n_students = dt$vals[i])
      fi <- fi + 1
    }
  }

  # Black Belt counties (2021 and 2025 only, for comparison)
  bb <- list(
    list(id = "053", name = "Perry County", v21 = 1347, v25 = 1089),
    list(id = "066", name = "Wilcox County", v21 = 1184, v25 = 978),
    list(id = "032", name = "Greene County", v21 = 1042, v25 = 823),
    list(id = "060", name = "Sumter County", v21 = 1218, v25 = 1047),
    list(id = "043", name = "Lowndes County", v21 = 1573, v25 = 1312),
    list(id = "024", name = "Dallas County", v21 = 3847, v25 = 3284)
  )
  for (b in bb) {
    frames[[fi]] <- make_row(2021, district_id = b$id,
                             district_name = b$name, type = "District",
                             n_students = b$v21)
    fi <- fi + 1
    frames[[fi]] <- make_row(2025, district_id = b$id,
                             district_name = b$name, type = "District",
                             n_students = b$v25)
    fi <- fi + 1
  }

  # Smallest districts (2025 only)
  small <- list(
    list(id = "135", name = "Linden City", n = 347),
    list(id = "137", name = "Midfield City", n = 412),
    list(id = "146", name = "Piedmont City", n = 467),
    list(id = "133", name = "Lanett City", n = 489),
    list(id = "121", name = "Fairfield City", n = 523),
    list(id = "157", name = "Tarrant City", n = 568),
    list(id = "113", name = "Chickasaw City", n = 612),
    list(id = "153", name = "Sheffield City", n = 847),
    list(id = "107", name = "Attalla City", n = 917),
    list(id = "112", name = "Brewton City", n = 984)
  )
  for (s in small) {
    frames[[fi]] <- make_row(2025, district_id = s$id,
                             district_name = s$name, type = "District",
                             n_students = s$n)
    fi <- fi + 1
  }

  # Combine all
  all_data <- do.call(rbind, frames)

  # Add entity flags
  all_data$is_state <- all_data$type == "State"
  all_data$is_district <- all_data$type == "District"
  all_data$is_campus <- all_data$type == "Campus"
  all_data$type <- NULL

  # Reorder columns
  col_order <- c("end_year", "district_id", "district_name",
                 "campus_id", "campus_name", "grade_level",
                 "subgroup", "n_students", "pct",
                 "is_state", "is_district", "is_campus")
  all_data <- all_data[, col_order]

  all_data
}
