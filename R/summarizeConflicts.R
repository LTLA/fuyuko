#' @export
summarizeConflicts <- function(full) {
    output <- list()

    for (prop in c("name", "git.repository", "url")) {
        splitted <- split(seq_len(nrow(full)), full[[prop]])
        failures <- list()

        for (x in names(splitted)) {
            current <- splitted[[x]]
            ids <- full$`_id`[current]
            by.id <- split(full[current,c("_path", "_parent")], ids)

            if (length(by.id) > 1) {
                failures[[x]] <- by.id
            }
        }
        output[[prop]] <- failures
    }

    output
}

#' @export
summarizeDependencies <- function(full) {
    unique.ids <- unique(full$`_id`)
    col.details <- colnames(full)
    col.details <- col.details[!grepl("^_", col.details)]
    unique.overview <- full[match(unique.ids, full$`_id`),col.details]

    # Creating paths to the root for each entry.
    origins <- list()
    for (u in unique.ids) {
        flock <- data.frame(`_id` = character(0), `_path` = character(0), `_parent` = character(0), check.names=FALSE)
        current.nodes <- u

        while (length(current.nodes)) {
            kept <- full[full$`_id` %in% current.nodes, colnames(flock)]
            flock <- rbind(flock, kept)
            current.nodes <- kept$`_parent`
            current.nodes <- current.nodes[!(current.nodes %in% flock$`_id`)]
        }

        origins[[u]] <- flock
    }
    
    list(dependencies = unique.overview, origins = origins)
}
