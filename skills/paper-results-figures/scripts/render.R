#!/usr/bin/env Rscript
# Category dispatch is separate from each figure implementation.
script_arg <- grep("^--file=", commandArgs(), value = TRUE)[1]
script_path <- gsub("~+~", " ", sub("^--file=", "", script_arg), fixed = TRUE)
skill_dir <- dirname(dirname(normalizePath(script_path, mustWork = TRUE)))
cache_root <- Sys.getenv("XDG_CACHE_HOME")
if (!nzchar(cache_root)) cache_root <- path.expand("~/.cache")
cache_dir <- Sys.getenv("PAPER_FIGURES_CACHE", file.path(cache_root, "paper-results-figures"))
.libPaths(c(file.path(cache_dir, "library"), .libPaths()))
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) stop("Supply one JSON configuration path.")
config_path <- normalizePath(args[[1]], mustWork = TRUE)
config <- jsonlite::fromJSON(config_path)
registry <- c("paired-comparison-scatter" = "paired_comparison_scatter.R",
              "mutl-comparison" = "multi_comparison.R",
              "multi-comparison" = "multi_comparison.R",
              "multi-metric-comparison" = "multi_comparison.R",
              "trend-comparsion" = "trend_comparison.R",
              "trend-comparison" = "trend_comparison.R",
              "radar-comparison" = "radar_comparison.R")
category <- config$plot_type
if (!is.character(category) || length(category) != 1 || !category %in% names(registry)) {
  stop("Choose an implemented plot_type from references/figure-catalog.md. Available: ", paste(names(registry), collapse = ", "))
}
renderer <- file.path(skill_dir, "scripts", registry[[category]])
status <- system2(Sys.which("Rscript"), args = c(shQuote(renderer), shQuote(config_path)))
quit(status = status)
