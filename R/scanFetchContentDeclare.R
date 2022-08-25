#' @export
scanFetchContentDeclare <- function(path) {
    lines <- readLines(path)

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
