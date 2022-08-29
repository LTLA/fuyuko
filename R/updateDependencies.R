#' Suggestions for updating dependencies
#'
#' When updating a project, the FetchContent call in its downstreams usually need to be updated, e.g., to a new GIT_TAG.
#' This function walks through the set of dependencies to determine which projects need to be updated, why, and in what order.
#'
#' @param full List produced by \code{\link{queryAllDependencies}}.
#' @param updates A data frame similar to that returned by \code{\link{scanFetchContentDeclare}},
#' specifying the projects to be updated and their new Git details or URLs.
#' @param transitive Logical scalar indicating whether the transitive dependencies of the projects in \code{updates} should be added to \code{updates}.
#'
#' @return List containing:
#' \itemize{
#' \item \code{initial}, a data frame containing the initial update request.
#' This contains the same information as \code{updates} if \code{transitive = FALSE};
#' otherwise, it will also contain the transitive dependencies of the projects in \code{updates}.
#' \item \code{dependencies}, a list of projects that require updates to their dependencies.
#' Each entry is itself a list that corresponds to a to-be-updated project, with properties described in the \code{project} data frame.
#' The \code{update} data frame desecribes the project's dependencies that need to be updated according to \code{initial}.
#' \item \code{top}, a data frame describing the dependencies to be updated for the top-level project,
#' i.e., the project used to define the dependencies to create \code{full}. 
#' }
#'
#' @author Aaron Lun
#' @examples
#' # Setting up the repository:
#' df <- data.frame(
#'     name = "scran", 
#'     git.repository = "https://github.com/LTLA/libscran",
#'     git.tag = "ae74e0345303a2d2c6e70d599d72c0e02d346fb6",
#'     url = NA_character_,
#'     url.hash = NA_character_
#' )
#' 
#' path <- fetchDependencies(df)
#' out <- queryAllDependencies(path)
#' 
#' # Now considering some updates:
#' updates <- data.frame(
#'     name = "aarand", 
#'     git.repository = "https://github.com/LTLA/aarand",
#'     git.tag = "2a8509c499f668bf424306f1aa986da429902c71",
#'     url = NA_character_,
#'     url.hash = NA_character_
#' )
#' 
#' to.update <- updateDependencies(out, updates)
#'
#' # Initial update request, including transitive dependencies:
#' to.update$initial
#' 
#' # Update order is easily obtained:
#' vapply(to.update$dependencies, function(x) x$project$name, "")
#'
#' # Final set of updates at the top-level:
#' to.update$top
#'
#' @export
updateDependencies <- function(full, updates, transitive = TRUE) {
    if (transitive) {
        new.deps <- list()
        updated <- fetchDependencies(updates)
        for (u in seq_along(updated)) {
            stuff <- queryAllDependencies(updated[u])
            new.deps[[u]] <- stuff$dependencies
        }
        new.deps <- c(new.deps, list(updates))
        new.deps <- do.call(rbind, new.deps)
    } else {
        new.deps <- updates
    }

    # Check that the updates themselves are self-consistent.
    new.deps <- unique_data.frame(new.deps)
    new.con <- summarizeConflicts(list(dependencies = new.deps))
    for (x in names(new.con)) {
        current <- new.con[[x]]
        if (length(current) >= 1) {
            stop("dependency conflicts between updates at '", paste(names(current), collapse="', '"), "'")
        }
    }

    # Now checking for each replacement of 'full'. This is done
    # recursively as each update in a project is assumed to trigger updates
    # in its downstreams, simply because the version needs to be bumped.
    full.deps <- full$dependencies
    direct.update <- integer(nrow(full.deps))
    indirect.update <- rep(list(data.frame(index = integer(0), path = character(0))), nrow(full.deps))
    top.level.update <- data.frame(index = integer(0), path = character(0))

    for (r in seq_len(nrow(full.deps))) {
        current <- full.deps[r,] 

        to.replace <- new.deps$name == current$name
        if (!any(to.replace)) {
            next
        }
        to.replace <- which(to.replace)[1] # should only be one, if there are no conflicts in new.deps.
        if (identical(new.deps[to.replace,], current)) {
            next
        }
        direct.update[r] <- to.replace

        nodes <- r
        while (length(nodes)) {
            for (n in nodes) {
                parents <- full$relationships[full$relationships$index == n,c("parent", "path")]
                is.zero <- parents$parent == 0L
                if (any(is.zero)) {
                    top.level.update <- rbind(top.level.update, data.frame(index = n, path = parents$path))
                    parents <- parents[!is.zero,]
                }
                for (i in seq_len(nrow(parents))) {
                    p <- parents$parent[i]
                    indirect.update[[p]] <- rbind(indirect.update[[p]], data.frame(index = n, path = parents$path[i]))
                }
            }
            nodes <- full$relationships$parent[full$relationships$index %in% nodes]
        }
    }

    top.level.update <- unique_data.frame(top.level.update)
    for (i in seq_along(indirect.update)) {
        indirect.update[[i]] <- unique_data.frame(indirect.update[[i]])
    }

    # Topological sort of everyone involved in this process.
    ordering <- integer(0)
    candidates <- which(direct.update > 0)
    while (length(candidates)) {
        next.candidates <- integer(0)
        for (i in candidates) {
            if (all(indirect.update[[i]]$index %in% ordering)) {
                ordering <- c(ordering, i)
                parents <- full$relationships$parent[full$relationships$index == i]
                next.candidates <- union(next.candidates, parents[parents != 0L])
            } else {
                # no need to do anything, it'll get picked up as a parent of
                # some other candidate eventually.
            }
        }
        candidates <- setdiff(next.candidates, ordering)
    }

    output <- list()
    for (o in ordering) {
        details <- list(project = full.deps[o,])
        indirects <- indirect.update[[o]]
        if (nrow(indirects) > 0) {
            full.set <- full.deps[indirects$index,]
            full.set$path <- indirects$path
            details$update <- full.set
            output <- c(output, list(details))
        }
    }

    top.level <- full.deps[top.level.update$index,]
    top.level$path <- top.level.update$path
    list(initial = new.deps, dependencies = output, top = top.level)
}
