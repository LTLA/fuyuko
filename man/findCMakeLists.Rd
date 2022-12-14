% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/findCMakeLists.R
\name{findCMakeLists}
\alias{findCMakeLists}
\title{Find all CMakeLists within a directory}
\usage{
findCMakeLists(dir, exclude = "build")
}
\arguments{
\item{dir}{String containing a path to a CMake project directory.}

\item{exclude}{Character vector of subdirectories to exclude.
This does not apply recursively, only to the immediate contents of \code{dir}.}
}
\value{
Character vector of all found CMakeLists.txt files inside \code{dir}.
}
\description{
Search recursively for all CMakeLists.txt files inside a CMake project directory.
}
\examples{
df <- data.frame(
    name = "scran", 
    git.repository = "https://github.com/LTLA/libscran",
    git.tag = "ae74e0345303a2d2c6e70d599d72c0e02d346fb6",
    url = NA_character_,
    url.hash = NA_character_
)

path <- fetchDependencies(df)
findCMakeLists(path)

}
\author{
Aaron Lun
}
