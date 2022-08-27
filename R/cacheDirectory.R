#' Cache directory for project dependencies
#'
#' Cache project dependencies so that they can be re-used across functions.
#' This is set to the value of the \code{FUYUKO_CACHE_DIR} environment variable if defined,
#' otherwise it is set to a subdirectory inside \code{\link{tempdir}}.
#'
#' @return String containing the path to a cache directory.
#'
#' @author Aaron Lun
#' @examples
#' cacheDirectory()
#'
#' Sys.setenv(FUYUKO_CACHE_DIR="WHEEE")
#' cacheDirectory()
#' Sys.unsetenv("FUYUKO_CACHE_DIR")
#' 
#' @export
cacheDirectory <- function() {
    Sys.getenv("FUYUKO_CACHE_DIR", file.path(tempdir(), "fuyuko-cache"))
}
