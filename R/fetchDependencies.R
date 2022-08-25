#' @export
#' @importFrom utils URLencode
fetchDependencies <- function(dependencies, cache) {
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
                system2("git", c("clone", repo, tpath))
                system(paste("cd", tpath, "&& git checkout", tag))
            }, error=function(e) {
                unlink(tpath, recursive=TRUE)
                stop(e)
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
                download.file(url, tmp)
            }

            if (grepl("\\.tar\\.gz$", url)) {
                # Extraction puts it one layer deeper than it should be,
                # but whatever, we'll be searching it recursively anyway.
                tryCatch(
                    untar(tmp, exdir=hpath), 
                    error=function(e) {
                        unlink(hpath, recursive=TRUE)
                        stop(e)
                    }
                )
            } else if (grepl("\\.zip$", url)) {
                tryCatch(
                    unzip(tmp, exdir=hpath), 
                    error=function(e) {
                        unlink(hpath, recursive=TRUE)
                        stop(e)
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
