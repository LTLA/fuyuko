#' Summarize conflicting dependencies
#'
#' Summarize conflicts between dependencies with similar but not identical properties.
#'
#' @param full List produced by \code{\link{queryAllDependencies}}.
#' 
#' @return List containing lists of data frames.
#'
#' This includes \code{name}, a named list of data frames where each entry corresponds to a set of conflicting dependencies.
#' Each entry is named after a particular project's name and contains a data frame of conflicting projects with differences in properties other than the name.
#'
#' The same applies for \code{git.repository}, where conflicting projects have the same Git repository but differences in other properties;
#' and \code{url}, for projects with the same URL but differences elsewhere.
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
#' summarizeConflicts(out)
#' 
#' @export
summarizeConflicts <- function(full) {
    output <- list()

    for (prop in c("name", "git.repository", "url")) {
        splitted <- split(seq_len(nrow(full$dependencies)), full$dependencies[[prop]])
        failures <- list()

        for (x in names(splitted)) {
            current <- splitted[[x]]
            if (length(current) > 1) {
                failures[[x]] <- full$dependencies[current,setdiff(colnames(full$dependencies), prop),drop=FALSE]
            }
        }
        output[[prop]] <- failures
    }

    output
}
