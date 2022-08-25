#' @export
findCMakeLists <- function(dir) {
    list.files(dir, recursive=TRUE, pattern="CMakeLists.txt")
}
