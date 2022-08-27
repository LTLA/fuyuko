#' Scan a CMakeLists.txt for FetchContent calls
#'
#' Scan a CMakeLists.txt file (or the lines thereof) for \code{FetchContent_Declare} calls,
#' and extract all identified dependencies.
#' 
#' @param path String containing a path to a CMakeLists.txt.
#' Ignored if \code{lines} is supplied.
#' @param lines Character vector containing the content of a CMakeLists.txt.
#' Each entry should contain a newline.
#'
#' @return Data frame where each row corresponds to a CMake project dependency in \code{lines}.
#' This contains the following columns:
#' \itemize{
#' \item \code{name}, the name of the project as defined in \code{lines}.
#' \item \code{git.repository}, the URL of the Git repository hosting the project.
#' This may be \code{NA} if \code{url} is supplied.
#' \item \code{git.tag}, the branch, tag or commit SHA of the Git repository.
#' This is always present if \code{git.repository} is non-\code{NA}, otherwise it will be \code{NA}.
#' \item \code{url}, the URL of the tarball or zip file containing the project files.
#' This may be \code{NA} if \code{git.repository} is supplied.
#' \item \code{url.hash}, a hash of the file in \code{url}.
#' This may be \code{NA}, even if \code{url} is supplied.
#' }
#'
#' @author Aaron Lun
#' @examples
#' cmake.file <- "
#' FetchContent_Declare(foo GIT_REPOSITORY https://github.com/LTLA/foo GIT_TAG master)
#'
#' FetchContent_Declare(blah 
#'      GIT_REPOSITORY https://github.com/LTLA/blah 
#'      GIT_TAG 87as68a768c6ac768a76
#' )
#'
#' FetchContent_Declare(whee URL https://blah.com/thing.1.1.tar.gz)
#'
#' FetchContent_Declare(stuff URL https://stuff.net/downloads/stuff.0.9.1.zip
#'    URL_HASH MD5=asdas8d7a8d7a9s8d7)
#' "
#'
#' scanFetchContentDeclare(lines=strsplit(cmake.file, "\n")[[1]])
#'
#' @export
scanFetchContentDeclare <- function(path, lines = readLines(path)) {
    collected.names <- character(0)
    collected.git.repo <- character(0)
    collected.git.tag <- character(0)
    collected.url <- character(0)
    collected.url.hash <- character(0)

    found <- grep("FetchContent_Declare\\(", lines)
    for (x in found) {
        counter <- x

        # Trying to get the name.
        curline <- lines[x]
        curline <- sub(".*FetchContent_Declare\\(\\s*", "", curline)
        args <- character(0)

        repeat{ 
            termination <- grepl("\\)", curline)
            if (termination) {
                curline <- sub("\\).*", "", curline)
            }

            components <- strsplit(curline, "\\s+")[[1]]
            args <- c(args, components[components != ""])

            if (termination) {
                break
            }

            counter <- counter + 1L
            if (counter > length(lines)) {
                stop("failed to find closing brace for FetchContent call on line ", x)
            }

            curline <- sub("^\\s*(.*)\\s*$", "\\1", lines[counter])
        }

        if (!length(args)) {
            stop("failed to determine name of the FetchContent call on line ", x)
        }

        current.name <- args[1]
        current.git.repo <- NA_character_
        current.git.tag <- NA_character_
        current.url <- NA_character_
        current.url.hash <- NA_character_
        
        if (length(is.git <- which(args == "GIT_REPOSITORY"))) {
            current.git.repo <- args[is.git + 1L]
            is.tag <- which(args == "GIT_TAG")
            if (length(is.tag) != 1L) {
                stop("failed to find GIT_TAG for the FetchContent call on line ", x)
            }
            current.git.tag <- args[is.tag + 1L]
        } else if (length(is.url <- which(args == "URL"))) {
            current.url <- args[is.url + 1L]
            is.hash <- which(args == "URL_HASH")
            if (length(is.hash) == 1L) {
                current.url.hash <- args[is.hash + 1L]
            }
        }

        collected.names <- c(collected.names, current.name)
        collected.git.repo <- c(collected.git.repo, current.git.repo)
        collected.git.tag <- c(collected.git.tag, current.git.tag)
        collected.url <- c(collected.url, current.url)
        collected.url.hash <- c(collected.url.hash, current.url.hash)  
    }

    data.frame(
        name = collected.names, 
        git.repository=collected.git.repo,
        git.tag=collected.git.tag,
        url=collected.url,
        url.hash=collected.url.hash
    )
}
