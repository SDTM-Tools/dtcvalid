ae <- utils::read.csv(system.file("extdata", "ae_synthetic.csv", package = "dtcvalid"),
                      colClasses = "character", na.strings = "")

test_that("returns only failing rows across all *DTC columns", {
  r <- check_dtc_vars(ae)
  expect_identical(names(r), c("row", "variable", "value", "valid", "precision", "reason"))
  expect_identical(r$variable, c("AESTDTC", "AESTDTC", "AEENDTC", "AEENDTC"))
  expect_identical(r$row, c(3L, 5L, 4L, 5L))
  expect_identical(r$reason, c("not_leap_year", "bad_format", "bad_month", "bad_time"))
  expect_false(any(r$valid))
})

test_that("vars limits the columns checked", {
  r <- check_dtc_vars(ae, vars = "AEENDTC")
  expect_identical(unique(r$variable), "AEENDTC")
})

test_that("unknown vars and non-data-frames error", {
  expect_error(check_dtc_vars(ae, vars = "XXDTC"), "not found")
  expect_error(check_dtc_vars(list()), "data frame")
})

test_that("all-valid data gives zero rows", {
  expect_identical(nrow(check_dtc_vars(ae[1, ])), 0L)
})
