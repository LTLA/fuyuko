# library(testthat); library(fuyuko); source("test-summarizeConflicts.R")

df <- data.frame(
    name = "scran", 
    git.repository = "https://github.com/LTLA/libscran",
    git.tag = "ae74e0345303a2d2c6e70d599d72c0e02d346fb6",
    url = NA_character_,
    url.hash = NA_character_
)
path <- fetchDependencies(df)

test_that("sumarizeConflicts works as expected", {
    full <- queryAllDependencies(path)

    con <- summarizeConflicts(full)
    expect_identical(names(con), c("name", "git.repository", "url"))
    has.conflict <- FALSE

    for (prop in names(con)) {
        hits <- con[[prop]]
        for (h in names(hits)) {
            current <- hits[[h]]
            expect_false(prop %in% colnames(current))
            concat <- do.call(paste, c(as.list(current), list(sep="|")))
            expect_identical(anyDuplicated(concat), 0L)

            if (nrow(current)) {
                has.conflict <- TRUE
            }
        }
    }

    expect_true(has.conflict)
})

