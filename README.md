# dtcvalid

Checks SDTM `--DTC` character values against ISO 8601, as described in **SDTMIG v3.4, section 4.4 (dates and times)**, and gives a reason for every value that fails.

Imputation is out of scope. For imputing partial dates and times, use [admiral](https://pharmaverse.github.io/admiral/) (`impute_dtc_dt()`, `impute_dtc_dtm()`).

## Install

```r
# install.packages("remotes")
remotes::install_github("SDTM-Tools/dtcvalid")
```

## Usage

```r
library(dtcvalid)

validate_dtc(c("2024-02-29", "2023-02-29", "2024---15", "2024-02-15T14:30+02:00"))
#>   value                  valid precision reason
#>   2024-02-29             TRUE  day       NA
#>   2023-02-29             FALSE NA        not_leap_year
#>   2024---15              TRUE  day       NA
#>   2024-02-15T14:30+02:00 FALSE NA        unsupported

ae <- read.csv(system.file("extdata", "ae_synthetic.csv", package = "dtcvalid"),
               colClasses = "character", na.strings = "")
check_dtc_vars(ae)  # failing values only, with row and variable
```

## Rules

- Accepted formats: `YYYY`, `YYYY-MM`, `YYYY-MM-DD`, `YYYY-MM-DDThh`, `YYYY-MM-DDThh:mm`, `YYYY-MM-DDThh:mm:ss`.
- A missing middle component may be written as a hyphen (`2024---15`, `2024-02-15T-:30`). `precision` is the most precise component present.
- Empty strings and `NA` are valid, with `precision` set to `NA`.
- Whitespace is never trimmed; leading or trailing spaces give `bad_format`.
- Reason codes: `bad_format`, `bad_month`, `bad_day`, `bad_time`, `not_leap_year`, `unsupported` (time zones, durations, intervals).

## Dependencies

Base R only. If tibble is installed, results are returned as tibbles; otherwise as data frames.

## Tested with

R 4.5.0, testthat 3.3.2, roxygen2 8.1.1, tibble 3.3.1. `R CMD check --no-manual` status OK; 28 tests, 93 expectations, 0 failures.

All test data is synthetic.
