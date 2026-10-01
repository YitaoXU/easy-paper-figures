# Explicit, lossless input adaptation for the figure renderers.
# This helper does not infer scientific meaning, aggregate, impute, or run tests.

prepare_figure_data <- function(config_path) {
  cache_root <- Sys.getenv("XDG_CACHE_HOME", unset = path.expand("~/.cache"))
  .libPaths(c(file.path(Sys.getenv("PAPER_FIGURES_CACHE", file.path(cache_root, "paper-results-figures")), "library"), .libPaths()))
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("The jsonlite package is required.")
  config_path <- normalizePath(config_path, mustWork = TRUE)
  cfg <- jsonlite::fromJSON(config_path, simplifyVector = FALSE)
  defaults <- list(input = NULL, output_prefix = NULL, operation = NULL, data_mode = NULL,
    delimiter = ",", na_values = c("", "NA", "NaN"), filter = NULL,
    id = NULL, model = NULL, value = NULL, x_model = NULL, y_model = NULL,
    paired = FALSE, keep = NULL, metric_columns = NULL, sd_columns = NULL,
    n_columns = NULL, metric = NULL, metrics = NULL, model_columns = NULL,
    rename = NULL, numeric_columns = NULL, input_format = "auto", sheet = NULL)
  bad <- setdiff(names(cfg), names(defaults))
  if (length(bad)) stop("Unknown preparation fields: ", paste(bad, collapse = ", "))
  for (k in names(cfg)) defaults[k] <- cfg[k]
  cfg <- defaults
  scalar <- function(x) is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)
  for (k in c("input", "output_prefix", "operation", "data_mode"))
    if (!scalar(cfg[[k]])) stop(k, " must be one nonempty string.")
  if (!cfg$operation %in% c("columns", "paired-long-to-wide", "metrics-wide-to-long", "transposed-to-long"))
    stop("Unsupported preparation operation.")
  if (!cfg$data_mode %in% c("raw", "summary")) stop("Establish data_mode as raw or summary before preparation.")
  if (!is.logical(cfg$paired) || length(cfg$paired) != 1L || is.na(cfg$paired)) stop("paired must be true or false.")
  if (!scalar(cfg$delimiter) || nchar(cfg$delimiter) != 1L) stop("delimiter must be one character.")
  cfg$na_values <- unlist(cfg$na_values, use.names = FALSE)
  path <- function(x) if (grepl("^(/|[A-Za-z]:[/\\\\])", x)) x else file.path(dirname(config_path), x)
  cfg$input <- normalizePath(path(cfg$input), mustWork = TRUE)
  prefix <- path(cfg$output_prefix)
  if (basename(dirname(prefix)) != basename(prefix)) prefix <- file.path(dirname(prefix), basename(prefix), basename(prefix))
  prefix <- normalizePath(prefix, mustWork = FALSE)
  outputs <- paste0(prefix, c(".prepared.csv", ".preparation.config.json", ".preparation.json", ".source-data", ".prepare-data.R", ".prepare.R"))
  if (cfg$input %in% setdiff(outputs, paste0(prefix, ".source-data"))) stop("Preparation outputs must not replace their source.")
  if (config_path %in% setdiff(outputs, paste0(prefix, ".preparation.config.json"))) stop("Preparation outputs must not replace their original configuration.")
  if (!cfg$input_format %in% c("auto", "delimited", "xlsx", "xls")) stop("input_format must be auto, delimited, xlsx or xls.")
  if (cfg$input_format == "auto") {
    ext <- tolower(tools::file_ext(cfg$input))
    cfg$input_format <- if (ext %in% c("xlsx", "xls")) ext else "delimited"
    if (ext == "tsv" && !"delimiter" %in% names(jsonlite::fromJSON(config_path))) cfg$delimiter <- "\t"
  }
  if (cfg$input_format %in% c("xlsx", "xls")) {
    if (!requireNamespace("readxl", quietly = TRUE)) stop("The readxl package is required for Excel input; run ensure_environment.sh.")
    sheets <- readxl::excel_sheets(cfg$input)
    if (is.null(cfg$sheet)) {
      if (length(sheets) != 1L) stop("Workbook has multiple sheets; establish the input sheet explicitly.")
      cfg$sheet <- sheets[1L]
    }
    reader <- if (cfg$input_format == "xlsx") readxl::read_xlsx else readxl::read_xls
    cells <- reader(cfg$input, sheet = cfg$sheet, col_types = "list",
      na = cfg$na_values, trim_ws = FALSE, .name_repair = "minimal")
    # Preserve native Excel doubles at round-trip precision and lexical text IDs.
    serialize_cell <- function(v) {
      if (length(v) != 1L || is.na(v)) return(NA_character_)
      if (inherits(v, c("Date", "POSIXt"))) return(as.character(v))
      if (is.numeric(v)) return(sprintf("%.17g", v))
      as.character(v)
    }
    raw <- as.data.frame(lapply(cells, function(column) vapply(column, serialize_cell, character(1))),
      stringsAsFactors = FALSE, check.names = FALSE)
  } else raw <- read.table(cfg$input, header = TRUE, sep = cfg$delimiter, quote = "\"",
      comment.char = "", colClasses = "character", check.names = FALSE,
      stringsAsFactors = FALSE, na.strings = cfg$na_values, fileEncoding = "UTF-8-BOM")
  if (!nrow(raw) || anyDuplicated(names(raw)) || any(!nzchar(names(raw))))
    stop("Input must have observations and unique nonempty column names.")
  if (".source_row" %in% names(raw)) stop("The source uses a reserved provenance column: .source_row.")
  raw$.source_row <- seq_len(nrow(raw))
  needed <- function(cols) {
    absent <- setdiff(cols, names(raw))
    if (length(absent)) stop("Missing source columns: ", paste(absent, collapse = ", "))
  }
  mapping <- function(x, name, required = FALSE) {
    if (is.null(x)) { if (required) stop(name, " requires an explicit named mapping."); return(character()) }
    z <- unlist(x, use.names = TRUE)
    if (!is.character(z) || !length(z) || is.null(names(z)) || anyNA(z) ||
        any(!nzchar(z)) || any(!nzchar(names(z))) || anyDuplicated(names(z)))
      stop(name, " must map distinct output names to source columns.")
    needed(unname(z)); z
  }
  keep <- mapping(cfg$keep, "keep")
  if (length(intersect(names(keep), c("id", "x", "y", "model", "metric", "value", "sd", "n", ".source_row", ".source_row_x", ".source_row_y"))))
    stop("keep names must not replace canonical or provenance columns.")
  exclusions <- data.frame(source_row = integer(), reason = character())
  exclude <- function(rows, reason) {
    if (length(rows)) exclusions <<- rbind(exclusions, data.frame(source_row = rows, reason = reason))
  }
  d <- raw
  if (!is.null(cfg$filter)) {
    filters <- cfg$filter
    if (is.null(names(filters)) || anyDuplicated(names(filters))) stop("filter must be a named column-to-accepted-values object.")
    for (k in names(filters)) {
      needed(k); accepted <- unlist(filters[[k]], use.names = FALSE)
      ok <- !is.na(d[[k]]) & d[[k]] %in% accepted
      exclude(d$.source_row[!ok], paste0("filter:", k)); d <- d[ok, , drop = FALSE]
    }
  }
  if (!nrow(d)) stop("No rows remain after the explicit filter.")
  numeric_changes <- list()
  numeric <- function(x, label) {
    z <- suppressWarnings(as.numeric(trimws(x)))
    invalid <- !is.na(x) & (is.na(z) | !is.finite(z))
    if (any(invalid)) stop("Cannot safely parse ", label, ": ", paste(unique(x[invalid]), collapse = ", "), ". Establish units/encoding instead of guessing.")
    numeric_changes[[label]] <<- list(nonmissing = sum(!is.na(z)), missing = sum(is.na(z)))
    z
  }
  keys <- function(x, label) {
    if (anyNA(x) || any(!nzchar(trimws(x)))) stop(label, " contains missing or blank keys.")
    x
  }
  check_pairs <- function(frame) {
    methods <- unique(frame$model)
    for (m in methods) {
      ids <- frame$id[frame$model == m]
      keys(ids, "Pairing ID"); if (anyDuplicated(ids)) stop("Duplicate model/ID keys; do not average them automatically.")
    }
    reference <- frame$id[frame$model == methods[1L]]
    if (any(!vapply(methods, function(m) setequal(frame$id[frame$model == m], reference), logical(1))))
      stop("Methods have different pairing ID sets; establish missing-data handling before preparation.")
  }
  if (cfg$operation == "columns") {
    rename <- mapping(cfg$rename, "rename")
    if (anyDuplicated(unname(rename))) stop("A source column cannot be renamed twice.")
    out <- d
    names(out)[match(unname(rename), names(out))] <- names(rename)
    if (anyDuplicated(names(out))) stop("Renaming would create duplicate columns.")
    for (k in unlist(cfg$numeric_columns, use.names = FALSE)) {
      if (!k %in% names(out)) stop("Missing numeric output column: ", k)
      out[[k]] <- numeric(out[[k]], k)
    }
  } else if (cfg$operation == "paired-long-to-wide") {
    if (cfg$data_mode != "raw") stop("Paired scatter preparation requires actual paired raw observations.")
    for (k in c("id", "model", "value", "x_model", "y_model")) if (!scalar(cfg[[k]])) stop(k, " must be established explicitly.")
    if (cfg$x_model == cfg$y_model) stop("x_model and y_model must differ.")
    needed(c(cfg$id, cfg$model, cfg$value)); selected <- d[[cfg$model]] %in% c(cfg$x_model, cfg$y_model)
    exclude(d$.source_row[!selected], "unselected method"); d <- d[selected, , drop = FALSE]
    frame <- data.frame(model = keys(d[[cfg$model]], "Method"), id = keys(d[[cfg$id]], "Pairing ID"), stringsAsFactors = FALSE)
    if (!all(c(cfg$x_model, cfg$y_model) %in% frame$model)) stop("Both selected methods must occur in the source.")
    check_pairs(frame)
    dx <- d[d[[cfg$model]] == cfg$x_model, , drop = FALSE]
    dy <- d[d[[cfg$model]] == cfg$y_model, , drop = FALSE]
    dy <- dy[match(dx[[cfg$id]], dy[[cfg$id]]), , drop = FALSE]
    out <- data.frame(id = dx[[cfg$id]], x = numeric(dx[[cfg$value]], "x"),
      y = numeric(dy[[cfg$value]], "y"), .source_row_x = dx$.source_row,
      .source_row_y = dy$.source_row, stringsAsFactors = FALSE)
    for (k in names(keep)) {
      a <- dx[[keep[[k]]]]; b <- dy[[keep[[k]]]]
      equal <- (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)
      if (any(!equal)) stop("Pair covariate ", k, " differs between methods; choose its scientific meaning/source explicitly.")
      out[[k]] <- a
    }
    cfg$paired <- TRUE
  } else if (cfg$operation == "metrics-wide-to-long") {
    if (!scalar(cfg$model)) stop("model must name the source method column.")
    needed(cfg$model); keys(d[[cfg$model]], "Method")
    metrics <- mapping(cfg$metric_columns, "metric_columns", TRUE)
    sd <- mapping(cfg$sd_columns, "sd_columns"); n <- mapping(cfg$n_columns, "n_columns")
    if (length(setdiff(c(names(sd), names(n)), names(metrics)))) stop("SD/count mappings must refer to selected metric IDs.")
    if (cfg$data_mode == "raw" && (length(sd) || length(n))) stop("Raw observations cannot be mixed with summary SD/count fields.")
    if (cfg$data_mode == "summary" && anyDuplicated(d[[cfg$model]])) stop("Summary input requires one row per method; do not average duplicated summaries.")
    if (cfg$paired && cfg$data_mode != "raw") stop("Pairing is an observation-level property; summary means are not paired samples.")
    if (!is.null(cfg$id)) {needed(cfg$id); keys(d[[cfg$id]], "Observation ID")}
    if (cfg$paired && is.null(cfg$id)) stop("Paired raw preparation requires id.")
    if (cfg$paired) check_pairs(data.frame(model = d[[cfg$model]], id = d[[cfg$id]]))
    chunks <- lapply(names(metrics), function(m) {
      z <- data.frame(model = d[[cfg$model]], metric = m,
        value = numeric(d[[metrics[[m]]]], paste0("value:", m)), .source_row = d$.source_row, stringsAsFactors = FALSE)
      if (!is.null(cfg$id)) z$id <- d[[cfg$id]]
      if (length(sd)) z$sd <- if (m %in% names(sd)) numeric(d[[sd[[m]]]], paste0("sd:", m)) else NA_real_
      if (length(n)) z$n <- if (m %in% names(n)) numeric(d[[n[[m]]]], paste0("n:", m)) else NA_real_
      for (k in names(keep)) z[[k]] <- d[[keep[[k]]]]
      z
    })
    out <- do.call(rbind, chunks)
  } else {
    if (cfg$data_mode != "summary" || cfg$paired) stop("Transposed metric rows represent summary scores, not raw paired observations.")
    if (!scalar(cfg$metric)) stop("metric must name the source row-label column.")
    needed(cfg$metric); model_cols <- mapping(cfg$model_columns, "model_columns", TRUE)
    if (length(keep)) stop("Transposed input has no observation-level keep fields; save a custom explicit transformation if needed.")
    cfg$metrics <- unlist(cfg$metrics, use.names = FALSE)
    if (!is.character(cfg$metrics) || !length(cfg$metrics) || anyDuplicated(cfg$metrics) || anyNA(cfg$metrics)) stop("metrics must select explicit distinct row labels.")
    selected <- d[[cfg$metric]] %in% cfg$metrics
    exclude(d$.source_row[!selected], "unselected metric"); d <- d[selected, , drop = FALSE]
    if (anyDuplicated(d[[cfg$metric]]) || !setequal(d[[cfg$metric]], cfg$metrics)) stop("Each selected metric must have exactly one source row.")
    out <- do.call(rbind, lapply(names(model_cols), function(m)
      data.frame(model = m, metric = d[[cfg$metric]], value = numeric(d[[model_cols[[m]]]], paste0("value:", m)),
        .source_row = d$.source_row, stringsAsFactors = FALSE)))
  }
  for (k in unlist(cfg$numeric_columns, use.names = FALSE)) {
    if (!k %in% names(out)) stop("Missing numeric output column: ", k)
    if (!is.numeric(out[[k]])) out[[k]] <- numeric(out[[k]], k)
  }
  if ("sd" %in% names(out) && any(out$sd < 0, na.rm = TRUE)) stop("SD cannot be negative.")
  if ("n" %in% names(out) && any(out$n < 0 | out$n != round(out$n), na.rm = TRUE)) stop("Sample counts must be nonnegative whole numbers.")
  dir.create(dirname(prefix), recursive = TRUE, showWarnings = FALSE)
  cfg$output_prefix <- basename(prefix); cfg$input <- basename(paste0(prefix, ".source-data"))
  # Serialize numeric columns with 17 significant digits so conversion never rounds analysis values.
  printed <- out
  for (k in names(out)) if (is.numeric(out[[k]])) printed[[k]] <- ifelse(is.na(out[[k]]), NA_character_, sprintf("%.17g", out[[k]]))
  write.csv(printed, paste0(prefix, ".prepared.csv"), row.names = FALSE, na = "", fileEncoding = "UTF-8")
  original_source <- normalizePath(path(defaults$input), mustWork = TRUE)
  if (normalizePath(original_source, mustWork = FALSE) != normalizePath(paste0(prefix, ".source-data"), mustWork = FALSE) &&
      !file.copy(original_source, paste0(prefix, ".source-data"), overwrite = TRUE)) stop("Could not save the unchanged source snapshot.")
  jsonlite::write_json(cfg, paste0(prefix, ".preparation.config.json"), pretty = TRUE, auto_unbox = TRUE, null = "null", digits = NA)
  helper <- attr(prepare_figure_data, "source_path")
  if (!is.null(helper)) {
    if (normalizePath(helper, mustWork = FALSE) != normalizePath(paste0(prefix, ".prepare-data.R"), mustWork = FALSE) &&
        !file.copy(helper, paste0(prefix, ".prepare-data.R"), overwrite = TRUE)) stop("Could not save the preparation helper snapshot.")
    writeLines(c('args <- commandArgs(trailingOnly = FALSE)',
      'self <- gsub("~+~", " ", sub("^--file=", "", args[grepl("^--file=", args)][1L]), fixed = TRUE)',
      'if (is.na(self)) stop("Run this reproduction script with Rscript.")',
      'setwd(dirname(normalizePath(self, mustWork = TRUE)))',
      sprintf('source(%s)', encodeString(basename(paste0(prefix, ".prepare-data.R")), quote = '"')),
      sprintf('prepare_figure_data(%s)', encodeString(basename(paste0(prefix, ".preparation.config.json")), quote = '"'))),
      paste0(prefix, ".prepare.R"))
  }
  report <- list(operation = cfg$operation, data_mode = cfg$data_mode, paired = cfg$paired,
    source = list(path = original_source, md5 = unname(tools::md5sum(original_source)), rows = nrow(raw), columns = setdiff(names(raw), ".source_row")),
    output = list(path = paste0(prefix, ".prepared.csv"), md5 = unname(tools::md5sum(paste0(prefix, ".prepared.csv"))), rows = nrow(out), columns = names(out)),
    excluded_source_rows = exclusions, retained_source_rows = sort(unique(d$.source_row)),
    numeric_conversions = numeric_changes, mapping = cfg,
    scientific_choices = list(aggregation = "none", imputation = "none", unit_conversion = "none", precision = "17 significant digits for numeric CSV serialization"),
    provenance = list(preparation_config_md5 = unname(tools::md5sum(paste0(prefix, ".preparation.config.json"))),
      helper_md5 = if (is.null(helper)) NULL else unname(tools::md5sum(helper))))
  jsonlite::write_json(report, paste0(prefix, ".preparation.json"), pretty = TRUE, auto_unbox = TRUE, null = "null", na = "null", digits = NA)
  message("Prepared ", nrow(out), " rows: ", paste0(prefix, ".prepared.csv"))
  invisible(list(data = out, report = report))
}

source_file <- local({
  frames <- sys.frames()
  z <- Filter(Negate(is.null), lapply(frames, function(x) x$ofile))
  if (length(z)) normalizePath(z[[length(z)]], mustWork = TRUE) else {
    a <- commandArgs(trailingOnly = FALSE); f <- a[grepl("^--file=", a)]
    if (length(f)) normalizePath(gsub("~+~", " ", sub("^--file=", "", f[1L]), fixed = TRUE), mustWork = TRUE) else NULL
  }
})
attr(prepare_figure_data, "source_path") <- source_file
if (sys.nframe() == 0L) {
  cache_root <- Sys.getenv("XDG_CACHE_HOME", unset = path.expand("~/.cache"))
  .libPaths(c(file.path(Sys.getenv("PAPER_FIGURES_CACHE", file.path(cache_root, "paper-results-figures")), "library"), .libPaths()))
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 1L) stop("Usage: Rscript prepare_data.R /absolute/path/to/preparation-config.json")
  prepare_figure_data(args[1L])
}
