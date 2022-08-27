#' Download dependencies to disk
#'
#' Fetch CMake project dependencies by cloning Git repositories or downloading their contents.
#' These are unpacked into a cache directory for re-use across multiple requests.
#'
#' @param dependencies Data frame containing a manifest of dependencies,
#' typically the return value from \code{\link{scanFetchContentDeclare}}.
#' Each row represents a CMake project.
#' @param cache String containing a path to a cache directory.
#'
#' @return Character vector of length equal to the number of rows in \code{dependencies}.
#' Each entry contains the path to the directory (stored inside \code{cache}) for the corresponding project.
#' 
#' @author Aaron Lun
#' @examples
#' df <- rbind(
#'     data.frame(
#'         name = "kmeans", 
#'         git.repository = "https://github.com/LTLA/CppKmeans",
#'         git.tag = "698cd1279530675e8ea10bf58d3a1d1508fa1fb8",
#'         url = NA_character_,
#'         url.hash = NA_character_
#'     ),
#'     data.frame(
#'         name = "igraph",
#'         git.repository = NA_character_,
#'         git.tag = NA_character_,
#'         url = "https://github.com/igraph/igraph/releases/download/0.9.4/igraph-0.9.4.tar.gz",
#'         url.hash = "MD5=ea8d7791579cfbc590060570e0597f6b"
#'     )
#' )
#' 
#' (paths <- fetchDependencies(df))
#' 
#' @export
#' @importFrom utils URLencode download.file untar unzip
#' @importFrom git2r clone checkout
fetchDependencies <- function(dependencies, cache = cacheDirectory()) {
    dir.create(cache, showWarnings=FALSE)
    all.paths <- rep(NA_character_, nrow(dependencies))

    # Cloning the Git repositories first.
    for (i in which(!is.na(dependencies$git.repository))) {
        npath <- file.path(cache, dependencies$name[i])
        dir.create(npath, showWarnings=FALSE)

        repo <- dependencies$git.repository[i]
        rpath <- file.path(npath, URLencode(repo, reserved=TRUE))
        dir.create(rpath, showWarnings=FALSE)

        tag <- dependencies$git.tag[i]
        tpath <- file.path(rpath, URLencode(tag, reserved=TRUE))
        if (!file.exists(tpath)) {
            tryCatch({
                clone(repo, tpath)
                checkout(tpath, tag)
            }, error=function(e) {
                unlink(tpath, recursive=TRUE)
                stop("failed to clone Git repository from '", repo, "' (", tag, ")\n  - ", e$message)
            })
        }

        all.paths[i] <- tpath
    }

    # Handling everything else.
    for (i in which(!is.na(dependencies$url))) {
        npath <- file.path(cache, dependencies$name[i])
        dir.create(npath, showWarnings=FALSE)

        url <- dependencies$url[i]
        upath <- file.path(npath, URLencode(url, reserved=TRUE))
        dir.create(upath, showWarnings=FALSE)

        hash <- dependencies$url.hash[i]
        if (!is.na(hash)) {
            stopifnot(hash != "_missing")
            hpath <- file.path(upath, URLencode(hash, reserved=TRUE))
        } else {
            hpath <- file.path(upath, "_missing")
        }

        if (!file.exists(hpath)) {
            tmp <- paste0(hpath, "-download")
            if (!file.exists(tmp)) {
                tryCatch(
                    download.file(url, tmp),
                    error=function(e) {
                        unlink(tmp)
                        stop("failed to download '", url, "'\n  - ", e$message)
                    }
                )
            }

            if (grepl("\\.tar\\.gz$", url)) {
                # Extraction puts it one layer deeper than it should be,
                # but whatever, we'll be searching it recursively anyway.
                tryCatch(
                    untar(tmp, exdir=hpath), 
                    error=function(e) {
                        unlink(hpath, recursive=TRUE)
                        stop("failed to unpack tarball from '", url, "'\n  - ", e$message)
                    }
                )
            } else if (grepl("\\.zip$", url)) {
                tryCatch(
                    unzip(tmp, exdir=hpath), 
                    error=function(e) {
                        unlink(hpath, recursive=TRUE)
                        stop("failed to unpack zipfile from '", url, "'\n  - ", e$message)
                    }
                )
            } else {
                stop("unknown file extension for '", url, "'")
            }

            unlink(tmp)
        }

        all.paths[i] <- hpath
    }

    all.paths
}
