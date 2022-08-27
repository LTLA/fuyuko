# library(testthat); library(fuyuko); source("test-scanFetchContentDeclare.R")

cmake.file <- "
FetchContent_Declare(foo GIT_REPOSITORY https://github.com/LTLA/foo GIT_TAG master)

FetchContent_Declare(blah 
     GIT_REPOSITORY https://github.com/LTLA/blah 
     GIT_TAG 87as68a768c6ac768a76
)

FetchContent_Declare(whee URL https://blah.com/thing.1.1.tar.gz)

FetchContent_Declare(stuff URL https://stuff.net/downloads/stuff.0.9.1.zip
   URL_HASH MD5=asdas8d7a8d7a9s8d7)
"

test_that("scanFetchContentDeclare works as expected", {
    stuff <- scanFetchContentDeclare(lines=strsplit(cmake.file, "\n")[[1]])

    expect_identical(stuff$name[1], "foo")
    expect_match(stuff$git.repository[1], "LTLA/foo$")
    expect_identical(stuff$git.tag[1], "master")
    expect_true(is.na(stuff$url[1]))
    expect_true(is.na(stuff$url.hash[1]))

    expect_identical(stuff$name[2], "blah")
    expect_match(stuff$git.repository[2], "LTLA/blah$")
    expect_match(stuff$git.tag[2], "76$")
    expect_true(is.na(stuff$url[2]))
    expect_true(is.na(stuff$url.hash[2]))

    expect_identical(stuff$name[3], "whee")
    expect_match(stuff$url[3], "tar.gz$")
    expect_true(is.na(stuff$url.hash[3]))
    expect_true(is.na(stuff$git.repository[3]))
    expect_true(is.na(stuff$git.tag[3]))

    expect_identical(stuff$name[4], "stuff")
    expect_match(stuff$url[4], "zip$")
    expect_match(stuff$url.hash[4], "d7$")
    expect_true(is.na(stuff$git.repository[3]))
    expect_true(is.na(stuff$git.tag[3]))
})
