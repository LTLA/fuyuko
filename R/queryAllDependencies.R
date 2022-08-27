#' Query a project for all its dependencies
#'
#' Search a CMake project for all its FetchContent-based dependencies in all its CMakeLists.txt files.
#' This is done recursively for all of its upstream dependencies.
#' 
#' @param dir String containing a path to a CMake project directory (or one of its subdirectories).
#' @param cache String containing a path to a cache directory in which to cache the dependencies.
#'
#' @return A list containing:
#' \itemize{
#' \item \code{dependencies}, a data frame where each row corresponds to a CMake project that is (directly or indirectly) a dependency of \code{dir}.
#' This contains all columns described in \code{\link{scanFetchContentDeclare}}.
#' \item \code{relationships}, a data frame describing the relationships between projects in \code{dependencies}.
#' This contains:
#' \itemize{
#' \item \code{index}, the row index of a project in \code{dependencies}.
#' \item \code{parent}, the row index of the immediate parent project that requires the project referenced by \code{index}.
#' This is set to zero for \code{dir}.
#' \item \code{path}, the file inside the parent project that requires the project of \code{index}.
#' }
#' }
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
#' (out <- queryAllDependencies(path))
#'
#' @export
queryAllDependencies <- function(dir, cache = cacheDirectory()) {
    collected <- .query_all_dependencies(dir, cache) 

    if (length(collected) == 0) {
        list(
            dependencies = data.frame(
                name = character(0),
                git.repository = character(0),
                git.tag = character(0),
                url = character(0),
                url.hash = character(0)
            ),
            relationships = data.frame(
                id = integer(0),
                parent = integer(0),
                path = character(0)
            )
        )

    } else {
        full <- do.call(rbind, collected)
        full <- unique_data.frame(full)

        unique.ids <- unique(full$`_id`)
        col.details <- colnames(full)
        col.details <- col.details[!grepl("^_", col.details)]
        unique.overview <- full[match(unique.ids, full$`_id`),col.details]
        rownames(unique.overview) <- NULL

        relationships <- data.frame(
            index = match(full$`_id`, unique.ids),
            parent = match(full$`_parent`, c(dir, unique.ids)) - 1L,
            path = full$`_path`
        )

        list(
            dependencies = unique.overview, 
            relationships = relationships
        )
    }
}

.query_all_dependencies <- function(dir, cache) {
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
                subdeps <- .query_all_dependencies(h, cache)
            }, error=function(e) {
                stop("failed to query dependencies for '", h, "':\n  - ", e$message)
            })
            collected <- c(collected, subdeps)
        }
    }

    collected
}
