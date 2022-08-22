# Scan `FetchContent` dependencies

This package scans `CMakeLists.txt` files for `FetchContent` dependencies to build a inter-repository dependency graph.
Its main purpose is to identify discrepancies in the pinned SHAs from `FetchContent`,
so that developers can figure out if anything in the stack needs to be updated.
