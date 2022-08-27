#' Find all CMakeLists within a directory
#'
#' Search recursively for all CMakeLists.txt files inside a CMake project directory.
#'
#' @param dir String containing a path to a CMake project directory.
#' @param exclude Character vector of subdirectories to exclude.
#' This does not apply recursively, only to the immediate contents of \code{dir}.
#' 
#' @return Character vector of all found CMakeLists.txt files inside \code{dir}.
#'
#' @author Aaron Lun
#'
#' @examples
#' df <- data.frame(
#'     name = "scran", 
#'     git.repository = "https://github.com/LTLA/libscran",
#'     git.tag = "ae74e0345303a2d2c6e70d599d72c0e02d346fb6",
#'     url = NA_character_,
#'     url.hash = NA_character_
#' )
#'
#' path <- fetchDependencies(df)
#' findCMakeLists(path)
#' 
#' @export
findCMakeLists <- function(dir, exclude="build") {
    candidates <- character(0)
    for (x in setdiff(list.files(dir), exclude)) {
        if (x == "CMakeLists.txt") {
            candidates <- c(candidates, "CMakeLists.txt")
            next
        } 
        full <- file.path(dir, x)
        if (dir.exists(full)) {
            childs <- list.files(full, recursive=TRUE, pattern="CMakeLists.txt")
            candidates <- c(candidates, file.path(x, childs))
        }
    }
    candidates
}
