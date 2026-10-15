#' Validate SDTM --DTC values
#'
#' Checks each value against the ISO 8601 subset that SDTMIG v3.4 section 4.4
#' allows: `YYYY`, `YYYY-MM`, `YYYY-MM-DD`, `YYYY-MM-DDThh`,
#' `YYYY-MM-DDThh:mm` and `YYYY-MM-DDThh:mm:ss`. A missing middle component
#' may be written as a single hyphen (for example `2024---15`). Empty strings
#' and `NA` are valid. Whitespace is never trimmed.
#'
#' @param x A character vector.
#' @return A data frame (a tibble when tibble is installed) with columns
#'   `value`, `valid`, `precision` and `reason`. `reason` is one of
#'   `bad_format`, `bad_month`, `bad_day`, `bad_time`, `not_leap_year`,
#'   `unsupported`, or `NA` when the value is valid.
#' @examples
#' validate_dtc(c("2024-02-29", "2023-02-29", "2024---15", "P3D"))
#' @export
validate_dtc <- function(x) {
  if (!is.character(x) && !all(is.na(x))) {
    stop("`x` must be a character vector.", call. = FALSE)
  }
  x <- as.character(x)
  res <- lapply(x, check_one)
  out <- data.frame(
    value = x,
    valid = vapply(res, `[[`, logical(1), "valid"),
    precision = vapply(res, `[[`, character(1), "precision"),
    reason = vapply(res, `[[`, character(1), "reason"),
    stringsAsFactors = FALSE
  )
  as_tbl(out)
}

as_tbl <- function(df) {
  if (requireNamespace("tibble", quietly = TRUE)) tibble::as_tibble(df) else df
}

ok <- function(precision) list(valid = TRUE, precision = precision, reason = NA_character_)
fail <- function(reason) list(valid = FALSE, precision = NA_character_, reason = reason)

dtc_re <- paste0(
  "^([0-9]{4})",
  "(?:-([0-9]{2}|-)",
  "(?:-([0-9]{2}|-)",
  "(?:T([0-9]{2}|-)",
  "(?::([0-9]{2}|-)",
  "(?::([0-9]{2}|-))?)?)?)?)?$"
)

is_unsupported <- function(v) {
  grepl("^R?[0-9]*/?P", v) ||                                  # durations, repeats
    grepl("^[0-9]{4}[^/]*/[0-9P]", v) && grepl("^[0-9]{4}-", v) || # intervals
    grepl("T[0-9:-]+(Z|[+-][0-9]{2}(:?[0-9]{2})?)$", v)           # time zones
}

check_one <- function(v) {
  if (is.na(v) || identical(v, "")) return(ok(NA_character_))
  m <- regmatches(v, regexec(dtc_re, v, perl = TRUE))[[1]]
  if (length(m) == 0) {
    if (is_unsupported(v)) return(fail("unsupported"))
    return(fail("bad_format"))
  }
  parts <- m[-1]
  names(parts) <- c("year", "month", "day", "hour", "minute", "second")
  present <- parts != "" & parts != "-"
  # a placeholder hyphen must sit between present components
  last <- max(which(present))
  if (any(parts[seq_len(last)] == "")) return(fail("bad_format"))

  yr <- as.integer(parts[["year"]])
  if (present[["month"]]) {
    mo <- as.integer(parts[["month"]])
    if (mo < 1 || mo > 12) return(fail("bad_month"))
  }
  if (present[["day"]]) {
    dy <- as.integer(parts[["day"]])
    if (present[["month"]]) {
      leap <- (yr %% 4 == 0 && yr %% 100 != 0) || yr %% 400 == 0
      dim <- c(31, if (leap) 29 else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)[mo]
      if (mo == 2 && dy == 29 && !leap) return(fail("not_leap_year"))
      if (dy < 1 || dy > dim) return(fail("bad_day"))
    } else if (dy < 1 || dy > 31) {
      return(fail("bad_day"))
    }
  }
  if (present[["hour"]] && as.integer(parts[["hour"]]) > 23) return(fail("bad_time"))
  if (present[["minute"]] && as.integer(parts[["minute"]]) > 59) return(fail("bad_time"))
  if (present[["second"]] && as.integer(parts[["second"]]) > 59) return(fail("bad_time"))

  ok(names(parts)[last])
}
