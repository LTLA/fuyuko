#' Create a dependency graph
#'
#' Create a directed graph of the project dependencies,
#' highlighting conflicts and their impacts on the graph.
#'
#' @param full List containing the output of \code{\link{queryAllDependencies}}.
#' @param short.names Logical scalar indicating whether to summarize each project with a string containing its name and row index in \code{full$dependencies}.
#' @param graph.only Logical scalar indicating whether to skip the plot.
#' 
#' @return An \pkg{igraph} directed graph is returned where each node is a CMake project and edges are formed to its dependent projects.
#' Multiple edges may be created between two projects if it is required in multiple CMakeLists.txt files.
#'
#' If \code{short.names=TRUE}, each node is named after the project name, with duplicates resolved by appending the row index in \code{full$dependencies}.
#' The source project is named as \code{"SOURCE"}.
#' Otherwise, the row index is used directly as the node name, with the source named as 0.
#'
#' A plot is displayed on the current graphics device where all conflicts are marked in red and all impacted dependents are marked in orange.
#' All unaffected dependencies are marked in green.
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
#' out <- queryAllDependencies(path)
#' g <- graphDependencies(out)
#' 
#' @export
graphDependencies <- function(full, short.names = TRUE, graph.only = FALSE) {
    index <- full$relationships$index
    parent <- full$relationships$parent
    
    if (short.names) {
        naming <- full$dependencies$name
        dup <- naming[duplicated(naming)]
        needs.suffix <- naming %in% dup
        naming[needs.suffix] <- sprintf("%s-%i", naming[needs.suffix], which(needs.suffix))
        nodes <- c("SOURCE", naming)
        index <- nodes[index + 1L]
        parent <- nodes[parent + 1L]
    }

    g <- igraph::make_graph(rbind(parent, index))

    if (!graph.only) {
        conflicts <- summarizeConflicts(full)

        conflicted <- character(0) 
        for (x in conflicts) {
            for (y in x) {
                conflicted <- union(conflicted, rownames(y))
            }
        }

        if (short.names) {
            conflicted <- nodes[as.integer(conflicted) + 1L]
        }

        indirects <- character(0)
        for (x in conflicted) {
            indirects <- union(indirects, names(igraph::subcomponent(g, x, mode="in")))
        }

        full.set <- names(igraph::V(g))
        colors <- rep("green", length(full.set))
        colors[full.set %in% indirects] <- "orange"
        colors[full.set %in% conflicted] <- "red"

        igraph::plot.igraph(g, vertex.color=colors)
    }

    g
}
