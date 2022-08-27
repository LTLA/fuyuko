# library(testthat); library(fuyuko); source("test-utils.R")

test_that("order_data.frame works as expected", {
    df <- data.frame(X = sample(LETTERS, 100, replace=TRUE), Y = runif(100))

    o <- fuyuko:::order_data.frame(df)
    df <- df[o,]
    expect_false(is.unsorted(df[,1]))

    by.X <- split(df[,2], df[,1])
    for (i in by.X) {
        expect_false(is.unsorted(i))
    }
})

test_that("unique_data.frame works as expected", {
    df <- data.frame(X = sample(LETTERS, 1000, replace=TRUE), Y = sample(letters, 1000, replace=TRUE))
    u1 <- unique(paste0(df$X, "_", df$Y))
    expect_true(length(u1) < nrow(df))

    out <- fuyuko:::unique_data.frame(df)
    u2 <- paste0(out$X, "_", out$Y)
    expect_identical(sort(u1), sort(u2))
})

