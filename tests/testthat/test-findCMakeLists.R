# library(testthat); library(fuyuko); source("test-findCMakeLists.R")

df <- data.frame(
    name = "scran",
    git.repository = "https://github.com/LTLA/libscran",
    git.tag = "ae74e0345303a2d2c6e70d599d72c0e02d346fb6",
    url = NA_character_,
    url.hash = NA_character_
)

path <- fetchDependencies(df)

test_that("findCMakeLists works as expected", {
    found <- findCMakeLists(path)
    expect_true(all(basename(found) == "CMakeLists.txt"))

    ref <- list.files(path, recursive=TRUE)
    keep <- ref[basename(ref) == "CMakeLists.txt"]
    expect_identical(sort(keep), sort(found))
})

test_that("findCMakeLists excludes directories as expected", {
    original <- findCMakeLists(path)
    expect_true(any(dirname(original) == "tests"))

    found <- findCMakeLists(path, exclude="tests")
    expect_false(any(dirname(found) == "tests"))
})
