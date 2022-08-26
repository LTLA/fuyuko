order_data.frame <- function(df) {
    do.call(order, as.list(df))
}

diff_data.frame <- function(df) {
    keep <- rep(FALSE, nrow(df))
    for (x in names(df)) {
        current <- df[,x]
        no.first <- current[-1]
        no.last <- current[-length(current)]

        has.diff <- is.na(no.first) != is.na(no.last)
        both.ok <- !is.na(no.first) & !is.na(no.last)
        has.diff[both.ok] <- no.first[both.ok] != no.last[both.ok]

        keep <- keep | c(TRUE, has.diff)
    }
    keep
}

unique_data.frame <- function(df) {
    o <- order_data.frame(df)
    df <- df[o,]
    d <- diff_data.frame(df)
    final <- df[d,]
    rownames(final) <- NULL
    final
}
