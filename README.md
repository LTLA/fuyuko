# Trace `FetchContent` dependency conflicts

## Overview

This package scans `CMakeLists.txt` files for `FetchContent` dependencies to build a inter-repository dependency graph.
Its main purpose is to identify dependency conflicts, most typically differences in the pinned SHAs from `FetchContent_Declare`.
Such differences may represent incompatibilities in the versions of the transitive dependencies.

This package was motivated by my own use of `FetchContent` within CMake to manage C++ library dependencies, e.g., in [**libscran**](https://github.com/LTLA/libscran).
`FetchContent` will fetch all transitive dependencies automatically; however, if the same dependency is declared repeatedly, only the first declaration is fulfilled.
This can cause problems if the declarations involve different versions of the upstream project that are not compatible. 
With **fuyuko**, we can identify such conflicts for manual resolution.

## Quick start

To install, you can use the usual **devtools** process:

```r
# install.packages("devtools") # if not installed
install.packages("LTLA/fuyuko")
```

Usage is fairly simple:

```r
# Clone a repository of interest.
path <- "test"
git2r::clone("https://github.com/LTLA/libscran", path)

# Query its dependencies:
library(fuyuko)
deps <- queryAllDependencies(path)
deps$dependencies[,1:2]
##              name                            git.repository
## 1          aarand            https://github.com/LTLA/aarand
## 2          aarand            https://github.com/LTLA/aarand
## 3           Annoy          https://github.com/spotify/Annoy
## 4          byteme            https://github.com/LTLA/byteme
## 5           eigen         https://gitlab.com/libeigen/eigen
## 6      googletest                                      <NA>
## 7         hnswlib           https://github.com/LTLA/hnswlib
## 8          igraph                                      <NA>
## 9           irlba          https://github.com/LTLA/CppIrlba
## 10         kmeans         https://github.com/LTLA/CppKmeans
## 11         kmeans         https://github.com/LTLA/CppKmeans
## 12       knncolle          https://github.com/LTLA/knncolle
## 13        powerit           https://github.com/LTLA/powerit
## 14         tatami            https://github.com/LTLA/tatami
## 15 WeightedLowess https://github.com/LTLA/CppWeightedLowess

# Find conflicts:
summarizeConflicts(deps)
## $name
## $name$aarand
##                   git.repository                                  git.tag  url
## 1 https://github.com/LTLA/aarand 2a8509c499f668bf424306f1aa986da429902c71 <NA>
## 2 https://github.com/LTLA/aarand afb49e269e02000373c55ccc982a4817be2b9d9d <NA>
##   url.hash
## 1     <NA>
## 2     <NA>
## 
## $name$kmeans
##                       git.repository                                  git.tag
## 10 https://github.com/LTLA/CppKmeans 4397a8d576cf0b657fd9012c049e05727c45796d
## 11 https://github.com/LTLA/CppKmeans aed1b7ad1c4eddaf80d851fc24fb81333337bf57
##     url url.hash
## 10 <NA>     <NA>
## 11 <NA>     <NA>
## 
## 
## $git.repository
## $git.repository$`https://github.com/LTLA/aarand`
##     name                                  git.tag  url url.hash
## 1 aarand 2a8509c499f668bf424306f1aa986da429902c71 <NA>     <NA>
## 2 aarand afb49e269e02000373c55ccc982a4817be2b9d9d <NA>     <NA>
## 
## $git.repository$`https://github.com/LTLA/CppKmeans`
##      name                                  git.tag  url url.hash
## 10 kmeans 4397a8d576cf0b657fd9012c049e05727c45796d <NA>     <NA>
## 11 kmeans aed1b7ad1c4eddaf80d851fc24fb81333337bf57 <NA>     <NA>
## 
## 
## $url
## list()
```

This returns a list of the dependency conflicts, defined as dependencies with the same name, Git repository URI or URLs but differences in other properties.

## Inspecting relationships

To trace the origin of these conflicts, we can inspect the relationships between dependencies.
For example, we can see that our `kmeans` conflict is driven by:

```r
deps$relationships[deps$relationships$index %in% c(10, 11),]
##    index parent                  path
## 22    10     12 extern/CMakeLists.txt
## 23    11      0 extern/CMakeLists.txt
```

So, one is required by the top-level project (i.e., **libscran** itself) while the other is required by `knncolle` (see row 12 in `deps$dependencies`).
In both cases, the `FetchContent` call lives inside the `extern/CMakeLists.txt`, which is where I put all my non-test dependencies.

Advanced users can summarize these relationships in a pretty graph:

```r
library(igraph)
g <- make_graph(rbind(
    c("source", deps$dependencies$name)[deps$relationships$parent + 1],
    deps$dependencies$name[deps$relationships$index]
))
plot(g)
```
