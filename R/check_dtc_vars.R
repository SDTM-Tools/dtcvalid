#' Check every --DTC column in a data frame
#'
#' Runs [validate_dtc()] over each column whose name ends in `DTC` (or the
#' columns named in `vars`) and returns only the failing values.
#'
#' @param data A data frame.
#' @param vars Optional character vector of column names to check.
#' @return A data frame (a tibble when tibble is installed) with columns
#'   `row`, `variable`, `value`, `valid`, `precision` and `reason`, one row per
#'   failing value. It has zero rows when everything is valid.
#' @examples
#' ae <- read.csv(system.file("extdata", "ae_synthetic.csv", package = "dtcvalid"),
#'                colClasses = "character", na.strings = "")
#' check_dtc_vars(ae)
#' @export
check_dtc_vars <- function(data, vars = NULL) {
  if (!is.data.frame(data)) stop("`data` must be a data frame.", call. = FALSE)
  if (is.null(vars)) {
    vars <- grep("DTC$", names(data), value = TRUE)
  } else {
    missing <- setdiff(vars, names(data))
    if (length(missing)) {
      stop("Columns not found: ", paste(missing, collapse = ", "), call. = FALSE)
    }
  }
  pieces <- lapply(vars, function(v) {
    r <- as.data.frame(validate_dtc(as.character(data[[v]])))
    r <- cbind(row = seq_len(nrow(data)), variable = rep(v, nrow(data)), r,
               stringsAsFactors = FALSE)
    r[!r$valid, , drop = FALSE]
  })
  empty <- data.frame(row = integer(), variable = character(), value = character(),
                      valid = logical(), precision = character(),
                      reason = character(), stringsAsFactors = FALSE)
  out <- do.call(rbind, c(list(empty), pieces))
  rownames(out) <- NULL
  as_tbl(out)
}
