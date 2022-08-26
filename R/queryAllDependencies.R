#' @export
queryAllDependencies <- function(dir, cache) {
    all.paths <- findCMakeLists(dir)
    collected <- list()

    for (p in all.paths) {
        tryCatch({
            deps <- scanFetchContentDeclare(file.path(dir, p))
        }, error=function(e) {
            stop("failed to parse '", p, "' in '", dir, "':\n  - ", e$message)
        })
        if (!nrow(deps)) {
            next
        }

        tryCatch({
            hosted <- fetchDependencies(deps, cache)
        }, error=function(e) {
            stop("failed to fetch dependencies for '", dir, "':\n  - ", e$message)
        })

        deps$`_id` <- hosted
        deps$`_path` <- rep(p, nrow(deps))
        deps$`_parent` <- rep(dir, nrow(deps))
        collected <- c(collected, list(deps))

        for (h in hosted) {
            tryCatch({
                subdeps <- queryAllDependencies(h, cache)
            }, error=function(e) {
                stop("failed to query dependencies for '", h, "':\n  - ", e$message)
            })
            collected <- c(collected, list(subdeps))
        }
    }

    if (length(collected) == 0) {
        data.frame(
            name = character(0),
            git.repository = character(0),
            git.tag = character(0),
            url = character(0),
            url.hash = character(0),
            `_id` = character(0),
            `_path` = character(0),
            `_parent` = character(0)
        )
    } else {
        final <-do.call(rbind, collected)
        unique_data.frame(final)
    }
}
