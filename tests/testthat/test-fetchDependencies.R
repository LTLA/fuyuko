# library(testthat); library(fuyuko); source("test-fetchDependencies.R")

df <- rbind(
    data.frame(
        name = "kmeans", 
        git.repository = "https://github.com/LTLA/CppKmeans",
        git.tag = "698cd1279530675e8ea10bf58d3a1d1508fa1fb8",
        url = NA_character_,
        url.hash = NA_character_
    ),
    data.frame(
        name = "igraph",
        git.repository = NA_character_,
        git.tag = NA_character_,
        url = "https://github.com/igraph/igraph/releases/download/0.9.4/igraph-0.9.4.tar.gz",
        url.hash = "MD5=ea8d7791579cfbc590060570e0597f6b"
    ),
    data.frame(
        name = "googletest",
        git.repository = NA_character_,
        git.tag = NA_character_,
        url = "https://github.com/google/googletest/archive/609281088cfefc76f9d0ce82e1ff6c30cc3591e5.zip",
        url.hash = NA_character_
    )
)

test_that("fetchDependencies works as expected", {
    paths <- fetchDependencies(df)
    expect_identical(length(paths), nrow(df))
    expect_match(paths[1], "kmeans/.*CppKmeans/.*a1fb8$")
    expect_match(paths[2], "igraph/.*tar.gz/.*597f6b$")
    expect_match(paths[3], "googletest/.*3591e5.zip/_missing$")
})

test_that("fetchDependencies emits the expected errors", {
    copy <- df
    copy$git.repository[1] <- "FOO"
    expect_error(fetchDependencies(copy), "failed to clone")

    copy <- df
    copy$url[2] <- "FOO"
    expect_error(suppressWarnings(fetchDependencies(copy)), "failed to download")
})
