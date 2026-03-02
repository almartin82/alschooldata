# ==============================================================================
# Raw Directory Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw school directory data from the
# Alabama State Department of Education (ALSDE).
#
# Data Source:
# - ALSDE Education Directory - Registered School Information
#   https://eddir.alsde.edu/SiteInfo/PublicPrivateReligiousSites
#
# The Education Directory provides school-level and district-level contact
# information including administrator names, addresses, phone numbers, websites,
# and grade ranges.
#
# The page uses DevExpress ASPxGridView controls with CSV/XLSX export.
# Export is triggered via ASP.NET __doPostBack with serialized DevExpress
# callback arguments.
#
# ==============================================================================

#' Download raw public school directory data from ALSDE
#'
#' Downloads school-level directory data from the Alabama State Department of
#' Education Education Directory.
#'
#' @return Data frame with raw school directory data
#' @keywords internal
get_raw_directory <- function() {

  message("Downloading ALSDE school directory data...")

  # Download public schools
  schools <- download_directory_grid("pcResults$gridPublicSchool", "public schools")

  # Download superintendent/district data
  supts <- download_directory_grid("pcResults$gridSuperintendent", "superintendents")

  list(
    schools = schools,
    superintendents = supts
  )
}


#' Download a DevExpress grid as CSV from the ALSDE Education Directory
#'
#' The Education Directory page uses DevExpress ASPxGridView controls.
#' Export is triggered by posting back to the same page with the grid's
#' UniqueID as __EVENTTARGET and serialized DevExpress callback args
#' as __EVENTARGUMENT.
#'
#' The serialized format for ExportTo("Csv") is: "6|EXPORT3|Csv"
#' This comes from the DevExpress SerializeCallbackArgs function which
#' encodes each argument as: length|value
#'
#' @param grid_unique_id The ASP.NET UniqueID of the grid control
#'   (e.g., "pcResults$gridPublicSchool")
#' @param description Human-readable description for logging
#' @return Data frame with directory data
#' @keywords internal
download_directory_grid <- function(grid_unique_id, description) {

  base_url <- "https://eddir.alsde.edu/SiteInfo/PublicPrivateReligiousSites"

  # Step 1: GET the page to obtain ASP.NET ViewState tokens
  initial_response <- retry_with_backoff(
    request_fn = function() {
      httr::GET(
        base_url,
        httr::timeout(60),
        httr::user_agent("alschooldata R package (https://github.com/almartin82/alschooldata)")
      )
    },
    max_retries = 5,
    description = paste("ALSDE directory page fetch for", description)
  )

  if (httr::http_error(initial_response)) {
    stop(paste("Failed to access ALSDE Education Directory. HTTP status:",
               httr::status_code(initial_response),
               "\nPlease check if the site is accessible at:", base_url))
  }

  page_content <- httr::content(initial_response, "text", encoding = "UTF-8")

  # Extract ASP.NET hidden form fields
  html_doc <- xml2::read_html(page_content)

  viewstate <- rvest::html_element(html_doc, "input#__VIEWSTATE") |>
    rvest::html_attr("value")
  viewstate_gen <- rvest::html_element(html_doc, "input#__VIEWSTATEGENERATOR") |>
    rvest::html_attr("value")
  event_validation <- rvest::html_element(html_doc, "input#__EVENTVALIDATION") |>
    rvest::html_attr("value")

  if (is.na(viewstate)) {
    stop("Failed to extract ViewState from ALSDE Education Directory page. ",
         "The page structure may have changed. ",
         "Please report this issue at: https://github.com/almartin82/alschooldata/issues")
  }

  # Step 2: POST with DevExpress export callback args
  # DevExpress ExportTo("Csv") serializes as: "6|EXPORT3|Csv"
  # __EVENTTARGET = grid's UniqueID
  # __EVENTARGUMENT = serialized callback args

  tname <- tempfile(
    pattern = paste0("alsde_directory_", gsub("\\$", "_", grid_unique_id), "_"),
    tmpdir = tempdir(),
    fileext = ".csv"
  )

  export_response <- retry_with_backoff(
    request_fn = function() {
      httr::POST(
        base_url,
        body = list(
          `__VIEWSTATE` = viewstate,
          `__VIEWSTATEGENERATOR` = viewstate_gen,
          `__EVENTVALIDATION` = event_validation,
          `__EVENTTARGET` = grid_unique_id,
          `__EVENTARGUMENT` = "6|EXPORT3|Csv"
        ),
        encode = "form",
        httr::write_disk(tname, overwrite = TRUE),
        httr::timeout(120),
        httr::user_agent("alschooldata R package (https://github.com/almartin82/alschooldata)")
      )
    },
    max_retries = 5,
    base_delay = 2,
    description = paste("ALSDE directory CSV export for", description)
  )

  if (httr::http_error(export_response)) {
    unlink(tname)
    stop(paste("Failed to export directory data from ALSDE. HTTP status:",
               httr::status_code(export_response),
               "\nThe server may be temporarily unavailable. Please try again later."))
  }

  # Verify we got CSV data (not an HTML error page)
  content_type <- httr::headers(export_response)[["content-type"]]
  if (!is.null(content_type) && !grepl("csv", content_type, ignore.case = TRUE)) {
    first_lines <- readLines(tname, n = 5, warn = FALSE)
    if (any(grepl("<html|<!DOCTYPE", first_lines, ignore.case = TRUE))) {
      unlink(tname)
      stop("ALSDE server returned an HTML page instead of CSV data for ", description, ". ",
           "The server may be experiencing issues. Please try again later.")
    }
  }

  file_size <- file.info(tname)$size
  if (file_size < 100) {
    unlink(tname)
    stop("Downloaded file for ", description, " is too small (", file_size, " bytes). ",
         "The data may not be available.")
  }

  # Read the CSV file
  # The DevExpress CSV has a two-row header:
  # Row 1: parent headers (e.g., "Physical Address" spans 4 columns)
  # Row 2: sub-headers (e.g., "Street", "City", "State", "ZIP Code")
  # We skip the first row and use the second as headers

  # Read all lines and handle the multi-row header
  # The ALSDE server sometimes returns Windows-1252 encoded data
  # (e.g., curly apostrophes). Read as latin1 and convert to UTF-8.
  all_lines <- tryCatch(
    readLines(tname, warn = FALSE, encoding = "UTF-8"),
    error = function(e) {
      readLines(tname, warn = FALSE, encoding = "latin1")
    }
  )
  # Ensure valid UTF-8 by converting from latin1 if needed
  all_lines <- iconv(all_lines, from = "latin1", to = "UTF-8", sub = "'")

  if (length(all_lines) < 3) {
    unlink(tname)
    stop("Downloaded file for ", description, " contains insufficient data.")
  }

  # Row 1 is parent header, Row 2 is sub-header
  # Combine them intelligently: use sub-header names where they exist,

  # fall back to parent header names
  parent_header <- strsplit(all_lines[1], ",")[[1]]
  sub_header <- strsplit(all_lines[2], ",")[[1]]

  # Build column names: prefer sub-header, use parent if sub is empty
  col_names <- character(length(parent_header))
  for (i in seq_along(parent_header)) {
    sub_val <- if (i <= length(sub_header)) trimws(sub_header[i]) else ""
    parent_val <- trimws(parent_header[i])

    if (nchar(sub_val) > 0) {
      col_names[i] <- sub_val
    } else if (nchar(parent_val) > 0) {
      col_names[i] <- parent_val
    } else {
      col_names[i] <- paste0("col_", i)
    }
  }

  # Write data (skipping both header rows) to a temp file and read
  data_lines <- all_lines[3:length(all_lines)]
  tname_data <- tempfile(fileext = ".csv")
  writeLines(data_lines, tname_data, useBytes = TRUE)

  df <- readr::read_csv(
    tname_data,
    col_names = col_names,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE,
    locale = readr::locale(encoding = "UTF-8")
  )

  # Clean up
  unlink(tname)
  unlink(tname_data)

  if (nrow(df) == 0) {
    stop("Downloaded file contains no data for ", description, ".")
  }

  message("  Downloaded ", nrow(df), " rows for ", description)

  df
}
