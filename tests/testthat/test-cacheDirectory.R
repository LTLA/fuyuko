# library(testthat); library(fuyuko); source("test-cacheDirectory.R")

test_that("cacheDirectory works as expected", {
    original <- cacheDirectory()

    env <- Sys.getenv("FUYUKO_CACHE_DIR", NA)
    Sys.setenv(FUYUKO_CACHE_DIR="WHEE")
    restore <- function() {
        if (is.na(env)) {
            Sys.unsetenv("FUYUKO_CACHE_DIR")
        } else {
            Sys.setenv(FUYUKO_CACHE_DIR=env)
        }
    }
    on.exit(restore())

    expect_identical(cacheDirectory(), "WHEE")
    restore()
    expect_identical(cacheDirectory(), original)
})
