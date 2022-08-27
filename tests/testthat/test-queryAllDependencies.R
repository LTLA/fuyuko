# library(testthat); library(fuyuko); source("test-queryAllDependencies.R")

df <- data.frame(
    name = "scran", 
    git.repository = "https://github.com/LTLA/libscran",
    git.tag = "ae74e0345303a2d2c6e70d599d72c0e02d346fb6",
    url = NA_character_,
    url.hash = NA_character_
)
path <- fetchDependencies(df)

test_that("queryAllDependencies works as expected", {
    out <- queryAllDependencies(path)

    # Dependencies are indeed unique.
    superconcat <- do.call(paste, c(as.list(out$dependencies), list(sep="|")))
    expect_identical(anyDuplicated(superconcat), 0L)

    # Relationship indices pan out.
    expect_true(all(out$relationships$index %in% seq_len(nrow(out$dependencies))))
    expect_true(all(out$relationships$parent %in% 0:nrow(out$dependencies)))

    # Validating all relationships.
    deppaths <- fetchDependencies(out$dependencies)

    for (i in seq_len(nrow(out$relationships))) {
        current <- out$relationships[i,]

        if (current$parent == 0) {
            found <- file.path(path, current$path)
        } else {
            found <- file.path(deppaths[current$parent], current$path)
        }

        loaded <- scanFetchContentDeclare(found)
        moreconcat <- do.call(paste, c(as.list(loaded), list(sep="|")))
        expect_true(superconcat[current$index] %in% moreconcat)
    }
})

