#!/usr/bin/env Rscript
# Deterministic paired comparison from a JSON configuration; input files are read-only.
script_arg <- grep("^--file=", commandArgs(), value = TRUE)[1]
script_path <- gsub("~+~", " ", sub("^--file=", "", script_arg), fixed = TRUE)
skill_dir <- dirname(dirname(normalizePath(script_path, mustWork = TRUE)))
source(file.path(skill_dir, "scripts", "formatting.R"))
source(file.path(skill_dir, "scripts", "palette_helpers.R"))
source(file.path(skill_dir, "scripts", "paper_layout.R"))
cache_root <- Sys.getenv("XDG_CACHE_HOME")
if (!nzchar(cache_root)) cache_root <- path.expand("~/.cache")
cache_dir <- Sys.getenv("PAPER_FIGURES_CACHE", file.path(cache_root, "paper-results-figures"))
.libPaths(c(file.path(cache_dir, "library"), .libPaths()))
suppressPackageStartupMessages(library(ggplot2))
source(file.path(skill_dir, "scripts", "font_export.R"))
source(file.path(skill_dir, "scripts", "paired_marginals.R"))
source(file.path(skill_dir, "scripts", "paired_layout.R"))
arial_faces <- resolve_arial_fonts()
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) stop("Supply one JSON configuration path.")
config_path <- normalizePath(args[[1]], mustWork = TRUE)
user <- jsonlite::fromJSON(config_path, simplifyVector = TRUE)
defaults <- list(
  plot_type = "paired-comparison-scatter", input = NULL, output_prefix = NULL,
  x = NULL, y = NULL, id = NULL, title = NULL, x_label = NULL, y_label = NULL,
  metric_source = NULL, color = NULL, color_label = NULL, color_type = "categorical",
  color_levels = NULL, color_values = NULL, colorbar_limits = NULL, colorbar_breaks = NULL,
  colorbar_digits = NULL, colorbar_height_mm = NULL, colorbar_width_mm = 1.8,
  colorbar_title_width = 14, colorbar_title_size = 1.6, colorbar_text_size = 1.6, colorbar_gap_mm = 0.65,
  colorbar_inside_title_size = 2.0, colorbar_inside_title_width = 24,
  colorbar_tick_length_mm = .6, colorbar_tick_offset_mm = 0,
  colorbar_placement = "outside", colorbar_orientation = "auto", colorbar_box = NULL,
  colorbar_inside_height_mm = 12, colorbar_padding_mm = .6,
  colorbar_title_gap_mm = .65, colorbar_tick_gap_mm = .45, size = NULL, size_label = NULL,
  size_range = c(.65, 1.9), size_breaks = NULL, size_type = "continuous",
  size_legend_placement = "auto", size_legend_box = NULL, star_ids = NULL,
  size_legend_min_height_mm = 9, size_legend_padding_mm = .65,
  point_labels = NULL, point_label_offsets = NULL, point_label_size = 1.9,
  point_label_placement = NULL, axis_canvas_layout = NULL,
  palette = "muted-green-blue-purple", alternative = "greater",
  missing_pairs = "error", limits = NULL, breaks = NULL, axis_digits = NULL,
  width = 57/25.4, height = 54/25.4, layout_columns = 3, width_mm = NULL, height_mm = NULL, base_size = 7, font_family = "Arial", panel_tag = NULL,
  point_size = 0.75, point_alpha = NULL, point_darken = NULL, stats_box = NULL,
  annotation_reference_mm = 40, stats_padding_fraction = .03, legend_padding_fraction = .06,
  guide_width_match_tolerance = .08, guide_width_match_max_padding_fraction = .10,
  stats_font_size = 2.2, stats_alpha = 0.90,
  legend_placement = "auto", legend_box = NULL, legend_font_size = 2.0, legend_title_size = 2.3, show_mean_caption = FALSE,
  marginals = FALSE, marginal_bins = 8L, marginal_strip_mm = 6, marginal_gap_mm = .65,
  marginal_bandwidth = "nrd0", marginal_kde_min_n = 5L, marginal_alpha = .35,
  marginal_reference_color = NULL, marginal_focal_color = NULL,
  formats = c("pdf", "svg", "png"), dpi = 600
)
unknown <- setdiff(names(user), names(defaults))
if (length(unknown)) stop("Unknown configuration keys: ", paste(unknown, collapse = ", "))
cfg <- utils::modifyList(defaults, user, keep.null = TRUE)
# Existing title controls are shared overrides; separate inside controls refine
# one placement without changing the compact external guide profile.
if ("colorbar_title_size" %in% names(user) && !"colorbar_inside_title_size" %in% names(user))
  cfg$colorbar_inside_title_size <- cfg$colorbar_title_size
if ("colorbar_title_width" %in% names(user) && !"colorbar_inside_title_width" %in% names(user))
  cfg$colorbar_inside_title_width <- cfg$colorbar_title_width
if (is.null(cfg$point_alpha) || is.null(cfg$point_darken)) {
  pals <- jsonlite::fromJSON(file.path(skill_dir, "palettes/palettes.json"))
  if (is.null(pals[[cfg$palette]])) stop("Unknown palette.")
  # The compact marginal layout needs deeper rainbow points on its white panel.
  # Preserve explicit/saved values and the ordinary paired palette profile.
  marginal_rainbow <- isTRUE(cfg$marginals) && identical(cfg$palette, "rainbow-transparent")
  if (is.null(cfg$point_alpha)) cfg$point_alpha <-
    if (marginal_rainbow) .90 else pals[[cfg$palette]]$paired_point_alpha
  if (is.null(cfg$point_darken)) cfg$point_darken <-
    if (marginal_rainbow) .20 else pals[[cfg$palette]]$paired_point_darken
}
cfg <- resolve_paper_dimensions(cfg,user,default_height_mm=54)
if (!identical(cfg$font_family, "Arial")) stop("All figure text must use Arial; set font_family to Arial.")
for (k in c("input", "output_prefix", "x", "y")) {
  if (!is.character(cfg[[k]]) || length(cfg[[k]]) != 1 || !nzchar(cfg[[k]])) stop("Required string: ", k)
}
if (cfg$x == cfg$y) stop("x and y must reference different columns.")
if (cfg$plot_type != "paired-comparison-scatter") stop("Unsupported plot type.")
if (!cfg$alternative %in% c("greater", "less")) stop("alternative must be greater or less.")
if (!cfg$missing_pairs %in% c("error", "drop")) stop("missing_pairs must be error or drop.")
if (!cfg$color_type %in% c("categorical", "continuous")) stop("Invalid color_type.")
if (!cfg$size_type %in% c("continuous", "count")) stop("size_type must be continuous or count.")
if (!cfg$size_legend_placement %in% c("auto", "inside", "outside")) stop("size_legend_placement must be auto, inside, or outside.")
if (!length(cfg$formats) || !all(cfg$formats %in% c("pdf", "svg", "png"))) stop("Supported formats: pdf, svg, png.")
for (k in c("width", "height", "base_size", "point_size", "point_label_size", "stats_font_size", "legend_font_size", "legend_title_size", "colorbar_width_mm", "colorbar_title_width", "colorbar_title_size", "colorbar_inside_title_size", "colorbar_inside_title_width", "colorbar_text_size", "colorbar_inside_height_mm", "colorbar_padding_mm", "colorbar_title_gap_mm", "colorbar_tick_gap_mm", "colorbar_tick_length_mm", "size_legend_min_height_mm", "size_legend_padding_mm", "annotation_reference_mm", "marginal_strip_mm", "dpi")) {
  if (!is.numeric(cfg[[k]]) || length(cfg[[k]]) != 1 || !is.finite(cfg[[k]]) || cfg[[k]] <= 0) stop("Invalid positive setting: ", k)
}
if (!is.numeric(cfg$colorbar_gap_mm) || length(cfg$colorbar_gap_mm) != 1 ||
    !is.finite(cfg$colorbar_gap_mm) || cfg$colorbar_gap_mm < 0)
  stop("colorbar_gap_mm must be a finite nonnegative number.")
if (!is.numeric(cfg$colorbar_tick_offset_mm) || length(cfg$colorbar_tick_offset_mm) != 1 ||
    !is.finite(cfg$colorbar_tick_offset_mm) || cfg$colorbar_tick_offset_mm < 0)
  stop("colorbar_tick_offset_mm must be a finite nonnegative number.")
# The former outward offset is accepted so saved configurations remain usable;
# inward marks always originate at the gradient boundary and do not apply it.
if (cfg$colorbar_tick_length_mm >= cfg$colorbar_width_mm)
  stop("colorbar_tick_length_mm must be shorter than colorbar_width_mm; ticks must not span the gradient.")
for (k in c("point_alpha", "point_darken", "stats_alpha", "marginal_alpha")) {
  if (!is.numeric(cfg[[k]]) || length(cfg[[k]]) != 1 || !is.finite(cfg[[k]]) || cfg[[k]] < 0 || cfg[[k]] > 1) stop("Invalid opacity: ", k)
}
if (!cfg$colorbar_placement %in% c("auto", "inside", "outside")) stop("colorbar_placement must be auto, inside, or outside.")
if (!cfg$colorbar_orientation %in% c("auto", "horizontal", "vertical")) stop("colorbar_orientation must be auto, horizontal, or vertical.")
if (!is.logical(cfg$marginals) || length(cfg$marginals) != 1 || is.na(cfg$marginals)) stop("marginals must be true or false.")
for (k in c("marginal_bins", "marginal_kde_min_n")) {
  if (!is.numeric(cfg[[k]]) || length(cfg[[k]]) != 1 || !is.finite(cfg[[k]]) ||
      cfg[[k]] < 3 || cfg[[k]] != round(cfg[[k]])) stop(k, " must be an integer of at least three.")
}
if (cfg$marginal_bins > 100) stop("marginal_bins must not exceed 100 at publication size.")
if (!is.numeric(cfg$marginal_gap_mm) || length(cfg$marginal_gap_mm) != 1 ||
    !is.finite(cfg$marginal_gap_mm) || cfg$marginal_gap_mm < 0) stop("marginal_gap_mm must be nonnegative.")
if (!(is.character(cfg$marginal_bandwidth) && length(cfg$marginal_bandwidth) == 1 && cfg$marginal_bandwidth == "nrd0") &&
    !(is.numeric(cfg$marginal_bandwidth) && length(cfg$marginal_bandwidth) == 1 && is.finite(cfg$marginal_bandwidth) && cfg$marginal_bandwidth > 0))
  stop("marginal_bandwidth must be nrd0 or a positive Gaussian bandwidth in score units.")
for (k in c("stats_padding_fraction", "legend_padding_fraction", "guide_width_match_max_padding_fraction"))
  if (!is.numeric(cfg[[k]]) || length(cfg[[k]]) != 1 || !is.finite(cfg[[k]]) || cfg[[k]] <= 0 || cfg[[k]] >= .25)
    stop(k, " must be a fraction between zero and .25.")
if (!is.numeric(cfg$guide_width_match_tolerance) || length(cfg$guide_width_match_tolerance) != 1 ||
    !is.finite(cfg$guide_width_match_tolerance) || cfg$guide_width_match_tolerance < 0 || cfg$guide_width_match_tolerance > .25)
  stop("guide_width_match_tolerance must be a fraction between zero and .25.")
resolve_path <- function(path) {
  path <- path.expand(path)
  if (!grepl("^(/|[A-Za-z]:[/\\\\])", path)) path <- file.path(dirname(config_path), path)
  normalizePath(path, mustWork = FALSE)
}
cfg$input <- normalizePath(resolve_path(cfg$input), mustWork = TRUE)
cfg$output_prefix <- resolve_path(cfg$output_prefix)
# One dedicated directory per figure; resolved prefixes remain idempotent.
figure_name <- basename(cfg$output_prefix)
if (basename(dirname(cfg$output_prefix)) != figure_name) {
  cfg$output_prefix <- file.path(dirname(cfg$output_prefix), figure_name, figure_name)
}
header <- names(read.csv(cfg$input, nrows = 0, check.names = FALSE))
text_columns <- intersect(unique(c(cfg$id, if (cfg$color_type == "categorical") cfg$color else NULL)), header)
column_classes <- if (length(text_columns)) setNames(rep("character", length(text_columns)), text_columns) else NA
raw <- read.csv(cfg$input, colClasses = column_classes, check.names = FALSE, stringsAsFactors = FALSE, na.strings = c("", "NA", "NaN"))
columns <- unique(unlist(cfg[c("x", "y", "id", "color", "size")], use.names = FALSE))
absent <- setdiff(columns, names(raw))
if (length(absent)) stop("Missing columns: ", paste(absent, collapse = ", "))
numeric_column <- function(name) {
  original <- raw[[name]]
  values <- suppressWarnings(as.numeric(original))
  if (any(!is.na(original) & is.na(values))) stop("Nonnumeric data in column: ", name)
  values
}
x <- numeric_column(cfg$x)
y <- numeric_column(cfg$y)
valid <- is.finite(x) & is.finite(y)
if (any(!valid) && cfg$missing_pairs == "error") stop("Missing/nonfinite paired scores at source rows: ", paste(which(!valid), collapse = ", "), ". Use missing_pairs='drop' only when appropriate.")
if (sum(valid) < 3) stop("At least three finite pairs are required.")
if (!is.null(cfg$id)) {
  keys <- as.character(raw[[cfg$id]][valid])
  if (anyNA(keys) || any(!nzchar(trimws(keys))) || anyDuplicated(keys)) stop("The pairing ID must be nonmissing and unique among retained pairs.")
} else keys <- as.character(which(valid))
dat <- data.frame(source_row = which(valid), pair_id = keys, x = x[valid], y = y[valid])
dat$difference <- dat$y - dat$x
if ((!is.null(cfg$star_ids) || !is.null(cfg$point_labels)) && is.null(cfg$id))
  stop("An explicit unique id column is required for star_ids or point_labels.")
if (!is.null(cfg$star_ids) && (!is.character(cfg$star_ids) || anyNA(cfg$star_ids) ||
    anyDuplicated(cfg$star_ids) || any(!cfg$star_ids %in% keys)))
  stop("star_ids must contain unique IDs present among the retained pairs.")
dat$point_shape <- ifelse(dat$pair_id %in% cfg$star_ids, "star", "circle")
dat$point_label <- NA_character_
if (!is.null(cfg$point_labels)) {
  labels <- unlist(cfg$point_labels, use.names = TRUE)
  if (!is.character(labels) || is.null(names(labels)) || anyDuplicated(names(labels)) ||
      any(!names(labels) %in% keys) || anyNA(labels) || any(!nzchar(trimws(labels))))
    stop("point_labels must be a named object of retained pair IDs and nonempty text.")
  dat$point_label <- unname(labels[dat$pair_id])
}
if (!is.null(cfg$point_label_offsets)) {
  if (!is.list(cfg$point_label_offsets) || is.null(names(cfg$point_label_offsets)) ||
      anyDuplicated(names(cfg$point_label_offsets)) ||
      any(!names(cfg$point_label_offsets) %in% names(cfg$point_labels)))
    stop("point_label_offsets must be a named object covering only labeled pair IDs.")
  if (any(!vapply(cfg$point_label_offsets, function(v)
      is.numeric(v) && length(v) == 2 && all(is.finite(v)), logical(1))))
    stop("Each point label offset must be two finite numbers [dx, dy] as fractions of the axis span.")
}
test <- tryCatch(t.test(dat$y, dat$x, paired = TRUE, alternative = cfg$alternative),
                 error = function(e) stop("Paired t-test is undefined for these differences: ", conditionMessage(e)))
mx <- mean(dat$x)
my <- mean(dat$y)
palette_path <- file.path(skill_dir, "palettes", "palettes.json")
palettes <- jsonlite::fromJSON(palette_path, simplifyVector = TRUE)
palette <- palettes[[cfg$palette]]
if (is.null(palette)) stop("Unknown palette: ", cfg$palette)
color_mapping <- NULL
point_color_mapping <- NULL
color_scale_record <- NULL
missing_color <- 0L
missing_size <- 0L
if (!is.null(cfg$color)) {
  if (cfg$color_type == "continuous") {
    dat$color <- numeric_column(cfg$color)[valid]
    dat$color[!is.finite(dat$color)] <- NA_real_
    if (all(is.na(dat$color))) stop("Continuous color has no finite values.")
    observed_color_range <- range(dat$color, na.rm = TRUE)
    if (is.null(cfg$colorbar_limits)) {
      cfg$colorbar_limits <- observed_color_range
      if (diff(cfg$colorbar_limits) == 0) {
        pad <- max(abs(cfg$colorbar_limits[1]) * 0.01, 0.001)
        cfg$colorbar_limits <- cfg$colorbar_limits + c(-pad, pad)
      }
    }
    if (!is.numeric(cfg$colorbar_limits) || length(cfg$colorbar_limits) != 2 ||
        any(!is.finite(cfg$colorbar_limits)) || diff(cfg$colorbar_limits) <= 0)
      stop("colorbar_limits must contain two increasing finite numbers.")
    if (observed_color_range[1] < cfg$colorbar_limits[1] || observed_color_range[2] > cfg$colorbar_limits[2])
      stop("Color-axis limits would hide covariate values; widen colorbar_limits.")
    if (is.null(cfg$colorbar_breaks)) {
      cfg$colorbar_breaks <- pretty(cfg$colorbar_limits, n = 4)
      cfg$colorbar_breaks <- cfg$colorbar_breaks[cfg$colorbar_breaks >= cfg$colorbar_limits[1] & cfg$colorbar_breaks <= cfg$colorbar_limits[2]]
      if (length(cfg$colorbar_breaks) < 2) cfg$colorbar_breaks <- cfg$colorbar_limits
    }
    if (!is.numeric(cfg$colorbar_breaks) || !length(cfg$colorbar_breaks) ||
        any(!is.finite(cfg$colorbar_breaks)) || any(diff(cfg$colorbar_breaks) <= 0) ||
        any(cfg$colorbar_breaks < cfg$colorbar_limits[1] | cfg$colorbar_breaks > cfg$colorbar_limits[2]))
      stop("colorbar_breaks must be increasing finite values within colorbar_limits.")
    colorbar_tick_labels <- format_axis_ticks(cfg$colorbar_breaks, cfg$colorbar_digits)
    internal_colorbar_breaks <- paired_internal_color_breaks(cfg$colorbar_limits)
    internal_colorbar_labels <- format_axis_ticks(internal_colorbar_breaks, cfg$colorbar_digits)
  } else {
    values <- as.character(raw[[cfg$color]][valid])
    values[!is.na(values) & !nzchar(trimws(values))] <- NA_character_
    levels <- cfg$color_levels
    if (is.null(levels)) levels <- sort(unique(values[!is.na(values)]), method = "radix")
    if (anyNA(levels) || anyDuplicated(levels) || any(!unique(values[!is.na(values)]) %in% levels)) stop("color_levels must uniquely cover all observed nonmissing categories.")
    if (!length(levels)) stop("Categorical color has no observed levels.")
    if (!is.null(cfg$color_values)) {
      color_mapping <- unlist(cfg$color_values)
      if (is.null(names(color_mapping)) || !all(levels %in% names(color_mapping))) stop("color_values must map every category name to a color.")
      color_mapping <- color_mapping[levels]
    } else {
      if (length(levels) > length(palette$categorical)) stop("More categories than palette colors. Supply explicit named color_values or add a palette.")
      color_mapping <- fixed_palette_mapping(levels, palette)[levels]
    }
    grDevices::col2rgb(color_mapping)
    dat$color <- factor(values, levels = levels)
    cfg$color_levels <- levels
    cfg$color_values <- as.list(color_mapping)
    point_color_mapping <- darken_palette_colors(color_mapping, cfg$point_darken)
  }
  missing_color <- sum(is.na(dat$color))
}
if (!is.null(cfg$color) && cfg$color_type == "continuous") {
  if (is.null(cfg$colorbar_height_mm))
    cfg$colorbar_height_mm <- max(14, min(cfg$width_mm - 24, cfg$height_mm - 20))
  if (!is.numeric(cfg$colorbar_height_mm) || length(cfg$colorbar_height_mm) != 1 ||
      !is.finite(cfg$colorbar_height_mm) || cfg$colorbar_height_mm <= 0)
    stop("colorbar_height_mm must be a positive number.")
}
if (!is.null(cfg$size)) {
  dat$size <- numeric_column(cfg$size)[valid]
  dat$size[!is.finite(dat$size)] <- NA_real_
  if (all(is.na(dat$size))) stop("Size has no finite values.")
  if (cfg$size_type == "count" && any(dat$size < 0 | abs(dat$size - round(dat$size)) > 1e-8, na.rm = TRUE))
    stop("A count size covariate must contain nonnegative whole numbers; use continuous for measured quantities.")
  missing_size <- sum(is.na(dat$size))
  if (!is.numeric(cfg$size_range) || length(cfg$size_range) != 2 || any(!is.finite(cfg$size_range)) || any(cfg$size_range <= 0) || diff(cfg$size_range) <= 0) stop("size_range must contain two increasing positive numbers.")
  if (!is.null(cfg$size_breaks) && (!is.numeric(cfg$size_breaks) || !length(cfg$size_breaks) ||
      any(!is.finite(cfg$size_breaks)) || any(diff(cfg$size_breaks) <= 0) ||
      any(cfg$size_breaks < min(dat$size, na.rm = TRUE) | cfg$size_breaks > max(dat$size, na.rm = TRUE))))
    stop("size_breaks must be increasing finite values within the observed size range.")
  if (cfg$size_type == "count" && !is.null(cfg$size_breaks) && any(abs(cfg$size_breaks - round(cfg$size_breaks)) > 1e-8))
    stop("Count size_breaks must be whole numbers.")
  if (is.null(cfg$size_breaks)) {
    cfg$size_breaks <- seq(min(dat$size, na.rm = TRUE), max(dat$size, na.rm = TRUE), length.out = 3)
    if (cfg$size_type == "count") cfg$size_breaks <- round(cfg$size_breaks)
    cfg$size_breaks <- unique(cfg$size_breaks)
  }
} else if (!is.null(cfg$size_breaks)) {
  stop("size_breaks requires a numeric size covariate.")
}
if (is.null(cfg$limits)) {
  bounds <- range(c(dat$x, dat$y))
  pad <- max(diff(bounds) * 0.045, max(abs(bounds)) * 0.01, 0.001)
  cfg$limits <- range(pretty(bounds + c(-pad, pad), n = 5))
}
limits <- cfg$limits
if (!is.numeric(limits) || length(limits) != 2 || any(!is.finite(limits)) || diff(limits) <= 0) stop("limits must contain two increasing finite numbers.")
if (any(c(dat$x, dat$y) < limits[1] | c(dat$x, dat$y) > limits[2])) stop("Axis limits would hide observations; widen the common limits.")
if (is.null(cfg$breaks)) {
  cfg$breaks <- pretty(limits, n = 5)
  cfg$breaks <- cfg$breaks[cfg$breaks >= limits[1] & cfg$breaks <= limits[2]]
}
if (!is.numeric(cfg$breaks) || !length(cfg$breaks) || any(!is.finite(cfg$breaks)) || any(diff(cfg$breaks) <= 0) || any(cfg$breaks < limits[1] | cfg$breaks > limits[2])) stop("breaks must be increasing finite values within the common limits.")
tick_labels <- format_axis_ticks(cfg$breaks, cfg$axis_digits)
p_value <- test$p.value
if (p_value == 0) {
  log_p <- pt(unname(test$statistic), df = unname(test$parameter), lower.tail = cfg$alternative == "less", log.p = TRUE)
  exponent <- floor(log_p / log(10))
  p_text <- sprintf("%.2fe%+d", exp(log_p - exponent * log(10)), as.integer(exponent))
} else {
  log_p <- log(p_value)
  p_text <- if (p_value < 0.001) formatC(p_value, format = "e", digits = 2) else formatC(p_value, format = "f", digits = 3)
}
p_label <- if (p_value < 0.05) "p-value < 0.05" else paste0("p-value = ", formatC(p_value, format = "f", digits = 3))
direction <- if (cfg$alternative == "greater") "y > x" else "y < x"
box_text <- sprintf("t-statistics = %.3f\n%s", unname(test$statistic), p_label)
`%or%` <- function(x, fallback) if (is.null(x)) fallback else x
caption <- if (isTRUE(cfg$show_mean_caption)) sprintf("Dotted lines: mean %s = %.3f; mean %s = %.3f\nn = %d paired observations", cfg$x_label %or% cfg$x, mx, cfg$y_label %or% cfg$y, my, nrow(dat)) else NULL
p <- ggplot(dat, aes(x = x, y = y)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", linewidth = 0.25, color = "#303030") +
  geom_vline(xintercept = mx, linetype = "dotted", linewidth = 0.22, color = "#777777") +
  geom_hline(yintercept = my, linetype = "dotted", linewidth = 0.22, color = "#777777")
mapping <- aes()
if (!is.null(cfg$color)) mapping$colour <- aes(colour = color)$colour
if (!is.null(cfg$size)) mapping$size <- aes(size = size)$size
# Size-mapped circles and stars use explicit physical geometry, independent
# of ggplot point-symbol conversion. Unsized circles retain the legacy geom.
GeomPairedCircle <- ggproto("GeomPairedCircle", Geom,
  required_aes = c("x", "y"),
  default_aes = aes(colour = "#333333", size = 1, alpha = 1),
  draw_key = paired_draw_key_circle,
  draw_panel = function(data, panel_params, coord) {
    coords <- coord$transform(data, panel_params)
    if (!nrow(coords)) return(grid::nullGrob())
    marks <- lapply(seq_len(nrow(coords)), function(i)
      paired_circle_grob(grid::unit(coords$x[i], "native"),
        grid::unit(coords$y[i], "native"), coords$size[i], coords$colour[i], coords$alpha[i]))
    grid::gTree(children = do.call(grid::gList, marks), name = "paired-physical-circles")
  })
# Five-point polygons retain exact area equivalence to the physical circles.
GeomPairedStar <- ggproto("GeomPairedStar", Geom,
  required_aes = c("x", "y"),
  default_aes = aes(colour = "#333333", size = 1, alpha = 1),
  draw_key = paired_draw_key_circle,
  draw_panel = function(data, panel_params, coord) {
    coords <- coord$transform(data, panel_params)
    if (!nrow(coords)) return(grid::nullGrob())
    angle <- pi / 2 + (0:9) * pi / 5
    # Normalize to the area of a circle whose diameter is the mapped size.
    radius_factor <- paired_star_radius_factor
    vertices <- lapply(seq_len(nrow(coords)), function(i) {
      radius <- coords$size[i] * radius_factor * rep(c(1, .45), 5)
      grid::polygonGrob(
        x = grid::unit(coords$x[i], "native") + grid::unit(radius * cos(angle), "mm"),
        y = grid::unit(coords$y[i], "native") + grid::unit(radius * sin(angle), "mm"),
        gp = grid::gpar(fill = scales::alpha(coords$colour[i], coords$alpha[i]), col = NA))
    })
    grid::gTree(children = do.call(grid::gList, vertices), name = "paired-star-points")
  })
point_args <- list(mapping = mapping, alpha = cfg$point_alpha)
if (is.null(cfg$color)) point_args$colour <- darken_palette_colors(palette$anchors[2], cfg$point_darken)
if (is.null(cfg$size)) point_args$size <- cfg$point_size
for (shape_kind in c("circle", "star")) {
  subset <- dat[dat$point_shape == shape_kind, , drop = FALSE]
  if (!nrow(subset)) next
  for (fallback in c(FALSE, TRUE)) {
    if (is.null(cfg$size) && fallback) next
    layer_data <- if (is.null(cfg$size)) subset else subset[is.na(subset$size) == fallback, , drop = FALSE]
    if (!nrow(layer_data)) next
    layer_args <- point_args
    layer_args$data <- layer_data
    # Guides use neutral circle keys; stars only highlight the requested IDs.
    layer_args$show.legend <- if (fallback) FALSE else shape_kind == "circle" || !any(dat$point_shape == "circle")
    if (fallback) {
      layer_args$mapping$size <- NULL
      layer_args$size <- cfg$point_size
    }
    if (shape_kind == "circle" && (is.null(cfg$size) || fallback)) {
      layer_args$shape <- 16
      p <- p + do.call(geom_point, layer_args)
    } else {
      layer_data_arg <- layer_args$data; layer_args$data <- NULL
      layer_mapping_arg <- layer_args$mapping; layer_args$mapping <- NULL
      layer_guide_arg <- layer_args$show.legend; layer_args$show.legend <- NULL
      p <- p + layer(geom = if(shape_kind == "star")GeomPairedStar else GeomPairedCircle, stat = "identity", position = "identity",
        data = layer_data_arg, mapping = layer_mapping_arg, show.legend = layer_guide_arg,
        params = layer_args)
    }
  }
}
if (!is.null(cfg$color)) {
  if (cfg$color_type == "categorical") {
    p <- p + scale_color_manual(name = cfg$color_label %or% cfg$color, values = point_color_mapping,
                               na.value = palette$missing, drop = FALSE,
                               guide = guide_legend(override.aes = list(alpha = cfg$point_alpha, size = 1.0)))
  } else {
    gradient_colors <- darken_palette_colors(palette$continuous, cfg$point_darken)
    colorbar_title <- cfg$color_label %or% cfg$color
    internal_colorbar_title <- colorbar_title
    if (!grepl("\n", colorbar_title, fixed = TRUE))
      colorbar_title <- paste(strwrap(colorbar_title, width = cfg$colorbar_title_width), collapse = "\n")
    if (!grepl("\n", internal_colorbar_title, fixed = TRUE))
      internal_colorbar_title <- paste(strwrap(internal_colorbar_title, width = cfg$colorbar_inside_title_width), collapse = "\n")
    external_color_orientation <- if (cfg$colorbar_orientation == "auto") "vertical" else cfg$colorbar_orientation
    external_color_position <- if (external_color_orientation == "vertical") "right" else "bottom"
    external_color_guide <- paired_exterior_colorbar_guide(tick_length_mm = cfg$colorbar_tick_length_mm,
        direction = external_color_orientation, position = external_color_position, order = 1,
        alpha = cfg$point_alpha,
        theme = theme(legend.key.height = grid::unit(if (external_color_orientation == "vertical") cfg$colorbar_height_mm else cfg$colorbar_width_mm, "mm"),
          legend.key.width = grid::unit(if (external_color_orientation == "vertical") cfg$colorbar_width_mm else cfg$colorbar_height_mm, "mm"),
          legend.title.position = "top", legend.text.position = if (external_color_orientation == "vertical") "right" else "bottom",
          legend.title = element_text(size = cfg$colorbar_title_size * 72.27 / 25.4, hjust = 0.5, lineheight = 0.95),
          legend.text = element_text(size = cfg$colorbar_text_size * 72.27 / 25.4,
            margin = if (external_color_orientation == "vertical") margin(l = cfg$colorbar_tick_gap_mm, unit = "mm") else
              margin(t = cfg$colorbar_tick_gap_mm, unit = "mm")),
          legend.frame = element_rect(color = "#444444", linewidth = 0.20),
          legend.ticks = element_line(color = "#444444", linewidth = .16),
          legend.background = element_blank(), legend.margin = margin(0, 0, 0, 0)))
    p <- p + scale_color_gradientn(name = colorbar_title, colors = gradient_colors,
      na.value = palette$missing, limits = cfg$colorbar_limits, breaks = cfg$colorbar_breaks,
      labels = colorbar_tick_labels, guide = external_color_guide)
    color_scale_record <- list(type = "continuous", column = cfg$color,
      label = cfg$color_label %or% cfg$color, placement = external_color_position, direction = external_color_orientation,
      limits = cfg$colorbar_limits, breaks = cfg$colorbar_breaks, labels = colorbar_tick_labels,
      external_breaks = cfg$colorbar_breaks, external_labels = colorbar_tick_labels,
      internal_breaks = internal_colorbar_breaks, internal_labels = internal_colorbar_labels,
      internal_break_rule = "first and last color-axis limits plus their arithmetic midpoint",
      separator_lines = "none", tick_marks = "short inward", tick_length_mm = cfg$colorbar_tick_length_mm,
      tick_boundary = if (external_color_orientation == "vertical") "right" else "bottom", tick_offset_mm = 0,
      legacy_tick_offset_requested_mm = cfg$colorbar_tick_offset_mm,
      tick_offset_policy = "legacy offset accepted but not applied; inward ticks start at the gradient boundary",
      external_title = colorbar_title, internal_title = internal_colorbar_title,
      title = colorbar_title, internal_title_size_reference_mm = cfg$colorbar_inside_title_size,
      external_title_size_mm = cfg$colorbar_title_size,
      external_title_wrap_width = cfg$colorbar_title_width,
      internal_title_wrap_width = cfg$colorbar_inside_title_width,
      internal_title_single_line = !grepl("\n", internal_colorbar_title, fixed = TRUE),
      gradient_colors = gradient_colors, alpha = cfg$point_alpha,
      height_mm = if (external_color_orientation == "vertical") cfg$colorbar_height_mm else cfg$colorbar_width_mm,
      width_mm = if (external_color_orientation == "vertical") cfg$colorbar_width_mm else cfg$colorbar_height_mm,
      gradient_length_mm = cfg$colorbar_height_mm, gradient_thickness_mm = cfg$colorbar_width_mm,
      title_size_mm = cfg$colorbar_title_size, text_size_mm = cfg$colorbar_text_size, gap_mm = cfg$colorbar_gap_mm)
  }
}
if (!is.null(cfg$size)) {
  physical_size_scale <- scale_size_continuous(name = cfg$size_label %or% cfg$size,
    range = cfg$size_range, breaks = cfg$size_breaks %or% waiver(),
    labels = function(x) formatC(x, format = "f", digits = if (cfg$size_type == "count") 0 else 3),
    guide = guide_legend(order = 2, override.aes = list(shape = 1, colour = "#444444", alpha = 1)))
  # Continuous scales supply rescaled raw values u in [0,1]. Interpolate area,
  # not radius; the configured endpoints remain exact physical diameters.
  physical_size_scale$palette <- function(u)
    sqrt(cfg$size_range[1]^2 + u * diff(cfg$size_range^2))
  p <- p + physical_size_scale
}
label_data <- dat[!is.na(dat$point_label), , drop = FALSE]
axis_canvas_layout <- paired_endpoint_canvas_layout(cfg, tick_labels)
cfg$axis_canvas_layout <- axis_canvas_layout
canvas_margins <- unlist(axis_canvas_layout$margin_mm)

p <- p +
  scale_x_continuous(limits = limits, breaks = cfg$breaks, labels = tick_labels, expand = expansion(mult = 0)) +
  scale_y_continuous(limits = limits, breaks = cfg$breaks, labels = tick_labels, expand = expansion(mult = 0)) +
  coord_fixed(ratio = 1, clip = "on") +
  labs(x = cfg$x_label %or% cfg$x, y = cfg$y_label %or% cfg$y, title = cfg$title, caption = caption) +
  theme_classic(base_size = cfg$base_size, base_family = cfg$font_family) +
  theme(panel.border = element_rect(fill = NA, color = "#222222", linewidth = 0.25),
        axis.line = element_blank(), axis.ticks = element_line(color = "#222222", linewidth = 0.22),
        axis.ticks.length = grid::unit(1.4, "pt"), axis.text = element_text(color = "#222222", size = cfg$base_size - 1),
        axis.title.x = element_text(size = cfg$base_size, margin = margin(t = 1.5)), axis.title.y = element_text(size = cfg$base_size, margin = margin(r = 1.5)),
        plot.title = element_text(size = cfg$base_size + 1, hjust = 0.5, margin = margin(b = 2)),
        plot.caption = element_text(size = 5, color = "#555555", hjust = 0, lineheight = 1.2, margin = margin(t = 2)),
        legend.title = element_text(size = cfg$legend_title_size * 72.27 / 25.4), legend.text = element_text(size = cfg$legend_font_size * 72.27 / 25.4, hjust = 0),
        legend.key.height = grid::unit(0.20, "cm"), legend.position = "right",
        legend.background = element_rect(fill = "white", color = "#555555", linewidth = 0.18),
        legend.margin = margin(2, 2, 2, 2),
        plot.margin = margin(canvas_margins["top"], canvas_margins["right"],
          canvas_margins["bottom"], canvas_margins["left"], unit = "mm"),
        plot.background = element_rect(fill = "white", color = NA))
# Continuous guides have their own compact gap; category guide typography is unchanged.
if (!is.null(cfg$color) && cfg$color_type == "continuous")
  p <- p + theme(legend.box.spacing = grid::unit(cfg$colorbar_gap_mm, "mm"),
                 legend.box.margin = margin(0, 0, 0, 0))
# Interior annotations use one physical scale relative to the measured square panel.
if (!cfg$legend_placement %in% c("auto", "inside", "outside")) stop("legend_placement must be auto, inside, or outside.")
marginal_record <- paired_marginal_record(cfg, dat, limits, palette)
legend_names <- names(color_mapping); legend_colors <- unname(point_color_mapping)
if (!is.null(color_mapping) && missing_color > 0) {
  legend_names <- c(legend_names, "Missing"); legend_colors <- c(legend_colors, palette$missing)
}
compact_legend <- !is.null(color_mapping) && is.null(cfg$size) && length(legend_names) <= 6
category_requested <- compact_legend && cfg$legend_placement != "outside"
colorbar_requested <- !is.null(cfg$color) && cfg$color_type == "continuous" && cfg$colorbar_placement != "outside"
size_requested <- !is.null(cfg$size) && cfg$size_legend_placement != "outside"
external_p <- p
# Suppress candidate guides before measuring; rejected candidates restore their native guide.
if (category_requested || colorbar_requested) p <- p + guides(colour = "none")
if (size_requested) p <- p + guides(size = "none")
resolve_size_layout <- function(panel_mm, statistics_box) {
  size_scale <- ggplot_build(p)$plot$scales$get_scales("size")
  keys <- as.numeric(size_scale$get_breaks()); labels <- as.character(size_scale$get_labels(keys))
  paired_size_layout(cfg, panel_mm, keys, labels, size_scale$map(keys),
    cfg$size_label %or% cfg$size, statistics_box, dat, limits, label_data)
}
inside_legend <- inside_size_legend <- inside_colorbar <- FALSE
category_guide_record <- size_guide_record <- colorbar_layout <- frame_width_matching <- NULL
# Remeasure after every native-guide fallback; the final geometry must match the final device.
for (pass in 1:4) {
  guide_changed <- FALSE
  panel_mm <- unname(paired_measure_panel(p, cfg, marginal_record, limits)["width"])
  if (panel_mm < 12) stop("The square panel is too small for readable paired annotations; adapt canvas/guide layout.")
  statistics_layout <- paired_statistics_layout(cfg, panel_mm, strsplit(box_text, "\n", fixed = TRUE)[[1]])
  b <- statistics_layout$box
  symbol_mm <- rep(cfg$point_size, nrow(dat))
  if (!is.null(cfg$size)) {
    size_scale <- ggplot_build(p)$plot$scales$get_scales("size")
    finite <- !is.na(dat$size)
    symbol_mm[finite] <- size_scale$map(dat$size[finite])
  }
  # Fixed labels constrain guide placement. Automatic labels instead yield to
  # the resolved internal guides, then find a clear position around those frames.
  guide_label_data <- dat
  omitted <- vapply(dat$pair_id, function(id) is.null(cfg$point_label_offsets[[id]]), logical(1))
  guide_label_data$point_label[omitted] <- NA_character_
  placement <- paired_place_point_labels(guide_label_data, limits, panel_mm, cfg, symbol_mm, list(b))
  label_data <- placement$data
  if (!is.null(cfg$size)) {
    size_guide_record <- resolve_size_layout(panel_mm, b)
    if (cfg$size_legend_placement == "inside" && !size_guide_record$fits)
      stop("The requested internal size guide would overlap data/statistics or crowd its labels; adjust size_legend_box, sizes or canvas before rendering.")
    inside_size_legend <- size_requested && size_guide_record$fits
    if (size_requested && !inside_size_legend) {
      size_requested <- FALSE
      guide_changed <- TRUE
      p <- p + guides(size = guide_legend(order = 2, override.aes = list(shape = 1, colour = "#444444", alpha = 1)))
    }
  }
  if (category_requested) {
    category_guide_record <- paired_category_layout(cfg, panel_mm, legend_names, legend_colors, b)
    matching <- paired_match_frame_widths(statistics_layout, category_guide_record, cfg,
      panel_mm, dat, limits, label_data)
    statistics_layout <- matching$statistics; category_guide_record <- matching$category
    frame_width_matching <- matching$record; b <- statistics_layout$box
    lb <- category_guide_record$box
    occ <- if (category_guide_record$fits) paired_candidate_occupancy(lb, dat, limits, panel_mm,
      cfg, label_data, list(b)) else list(points = 0, labels = 0, safe = FALSE)
    inside_legend <- category_guide_record$fits && occ$safe
    category_guide_record$candidate_overlapping_points <- occ$points
    category_guide_record$candidate_overlapping_labels <- occ$labels
    if (!inside_legend) {
      category_requested <- FALSE
      guide_changed <- TRUE
      p <- p + guides(colour = guide_legend(override.aes = list(alpha = cfg$point_alpha, size = 1.0)))
      if (cfg$legend_placement == "inside") warning("The category guide cannot fit safely; using the framed external legend.")
    }
  }
  if (colorbar_requested) {
    colorbar_layout <- paired_colorbar_layout(cfg, panel_mm, internal_colorbar_title, internal_colorbar_labels,
      b, dat, limits, label_data, if (inside_size_legend) list(size_guide_record$box) else list())
    inside_colorbar <- colorbar_layout$safe
    if (!inside_colorbar) {
      if (cfg$colorbar_placement == "inside")
        stop("No readable empty interior rectangle fits the complete continuous color axis; adjust colorbar_box, guide size or canvas.")
      colorbar_requested <- FALSE
      guide_changed <- TRUE
      p <- p + guides(colour = external_color_guide)
    }
  }
  if (!guide_changed) break
}
if (guide_changed) stop("Paired guide layout did not stabilize; adapt canvas or guide placement.")
# Resolve again against every final internal frame. Labels do not change panel
# dimensions or guides, and omitted offsets must clear all final annotations.
label_exclusions <- list(statistics_layout$box)
if (inside_legend) label_exclusions <- c(label_exclusions, list(category_guide_record$box))
if (inside_size_legend) label_exclusions <- c(label_exclusions, list(size_guide_record$box))
if (inside_colorbar) label_exclusions <- c(label_exclusions, list(colorbar_layout$box))
placement <- paired_place_point_labels(dat, limits, panel_mm, cfg, symbol_mm, label_exclusions)
label_data <- placement$data
cfg$point_label_placement <- placement$record
if (!is.null(cfg$size)) {
  finite_size <- !is.na(dat$size)
  dat$symbol_diameter_mm <- dat$symbol_area_mm2 <- dat$symbol_outer_radius_mm <- NA_real_
  dat$symbol_diameter_mm[finite_size] <- symbol_mm[finite_size]
  dat$symbol_area_mm2[finite_size] <- pi * symbol_mm[finite_size]^2 / 4
  dat$symbol_outer_radius_mm[finite_size] <- paired_mark_radii_mm(dat, cfg, symbol_mm)[finite_size]
}
if (nrow(label_data)) {
  label_mapping <- aes(x = label_x, y = label_y, label = point_label)
  if (!is.null(cfg$color)) label_mapping$colour <- aes(colour = color)$colour
  label_args <- list(data = label_data, mapping = label_mapping, size = cfg$point_label_size,
    family = "Arial", show.legend = FALSE, inherit.aes = FALSE)
  if (is.null(cfg$color)) label_args$colour <- darken_palette_colors(palette$anchors[2], cfg$point_darken)
  p <- p + do.call(geom_text, label_args)
  dat$label_x <- dat$label_y <- NA_real_
  ids <- match(label_data$pair_id, dat$pair_id)
  dat$label_x[ids] <- label_data$label_x
  dat$label_y[ids] <- label_data$label_y
}
# Preserve safe common-width decisions resolved against the final native-guide geometry.
b <- statistics_layout$box; box <- limits[1] + b * diff(limits)
overlap <- paired_candidate_occupancy(b, dat, limits, panel_mm, cfg, label_data)$points
if (overlap > 0) warning(overlap, " points overlap the statistics box; inspect and adjust stats_box.")
p <- p + annotate("rect", xmin = box[1], xmax = box[2], ymin = box[3], ymax = box[4],
  fill = "white", alpha = cfg$stats_alpha, color = "#555555", linewidth = .18) +
  annotate("text", x = mean(box[1:2]), y = mean(box[3:4]), label = box_text,
    hjust = .5, vjust = .5, lineheight = 1.25, size = statistics_layout$text_size_mm,
    family = "Arial", color = "#222222")
legend_overlap <- if (is.null(category_guide_record)) 0 else category_guide_record$candidate_overlapping_points
if (inside_legend) {
  bounds <- limits[1] + category_guide_record$box * diff(limits)
  p <- p + annotation_custom(paired_category_grob(category_guide_record, cfg),
    xmin = bounds[1], xmax = bounds[2], ymin = bounds[3], ymax = bounds[4])
}
if (!is.null(size_guide_record)) {
  size_guide_record$placement <- if (inside_size_legend) "inside" else "outside"
  if (inside_size_legend) {
    sb <- size_guide_record$box; bounds <- limits[1] + sb * diff(limits)
    p <- p + annotation_custom(paired_size_grob(size_guide_record, cfg),
      xmin = bounds[1], xmax = bounds[2], ymin = bounds[3], ymax = bounds[4])
  } else size_guide_record$box <- NULL
}
if (!is.null(color_scale_record)) {
  color_scale_record$placement <- if (inside_colorbar) "inside" else external_color_position
  color_scale_record$box <- if (inside_colorbar) colorbar_layout$box else NULL
  color_scale_record$inside_candidate <- colorbar_layout
  if (inside_colorbar) {
    bounds <- limits[1] + colorbar_layout$box * diff(limits)
    color_scale_record$breaks <- internal_colorbar_breaks
    color_scale_record$labels <- internal_colorbar_labels
    color_scale_record$title <- internal_colorbar_title
    color_scale_record$direction <- colorbar_layout$orientation
    color_scale_record$gradient_length_mm <- max(colorbar_layout$gradient_height_mm, colorbar_layout$gradient_width_mm)
    color_scale_record$gradient_thickness_mm <- min(colorbar_layout$gradient_height_mm, colorbar_layout$gradient_width_mm)
    color_scale_record$height_mm <- colorbar_layout$gradient_height_mm
    color_scale_record$width_mm <- colorbar_layout$gradient_width_mm
    color_scale_record$title_size_mm <- colorbar_layout$title_size_mm
    color_scale_record$text_size_mm <- colorbar_layout$text_size_mm
    color_scale_record$tick_length_mm <- colorbar_layout$tick_length_mm
    color_scale_record$tick_offset_mm <- colorbar_layout$tick_offset_mm
    color_scale_record$tick_boundary <- colorbar_layout$tick_boundary
    p <- p + annotation_custom(paired_colorbar_grob(colorbar_layout, cfg, internal_colorbar_title,
      internal_colorbar_labels, gradient_colors), xmin = bounds[1], xmax = bounds[2],
      ymin = bounds[3], ymax = bounds[4])
  }
}
# Keep null automatic boxes in the reproducible config; resolved boxes are in statistics.
p <- p + labs(tag=cfg$panel_tag) + theme(plot.tag=element_text(family="Arial",face="bold",size=9,hjust=0,vjust=1),plot.tag.position=c(0,1),plot.tag.location="plot")
dir.create(dirname(cfg$output_prefix), recursive = TRUE, showWarnings = FALSE)
outputs <- paste0(cfg$output_prefix, ".", cfg$formats)
if (cfg$input %in% c(outputs, paste0(cfg$output_prefix, ".plotted-data.csv"))) stop("Output would overwrite the source file.")
font_verification <- list(family = "Arial", resolved_faces = arial_faces)
main_panel_dimensions <- list()
for (i in seq_along(cfg$formats)) {
  device <- switch(cfg$formats[i], pdf = arial_pdf_device, svg = svglite::svglite, png = ragg::agg_png)
  if (cfg$formats[i] == "png") device(outputs[i], width = cfg$width, height = cfg$height, units = "in", res = cfg$dpi, background = "white")
  else device(outputs[i], width = cfg$width, height = cfg$height, bg = "white")
  tryCatch({
    grid::grid.newpage()
    grid::grid.draw(paired_add_marginals(ggplotGrob(p), marginal_record, limits))
    main_panel_dimensions[[cfg$formats[i]]] <- paired_panel_dimensions()
  }, finally = grDevices::dev.off())
  if (cfg$formats[i] == "pdf") font_verification$pdf <- verify_pdf_arial(outputs[i])
  if (cfg$formats[i] == "svg") font_verification$svg <- embed_arial_in_svg(outputs[i], arial_faces)
  if (cfg$formats[i] == "png") font_verification$png <- list(family = "Arial", device = "ragg")
}
summary <- list(
  marginals = marginal_record, main_panel_dimensions_mm = main_panel_dimensions,
  axis_canvas_layout = axis_canvas_layout,
  annotation_layout = list(statistics = statistics_layout, category_legend = category_guide_record,
    frame_width_matching = frame_width_matching,
    reference_panel_mm = cfg$annotation_reference_mm, measured_panel_mm = panel_mm,
    proportional_scale_factor = panel_mm / cfg$annotation_reference_mm),
  test = "one-sided paired t-test", alternative = cfg$alternative, physical_size_mm=c(width=cfg$width_mm,height=cfg$height_mm),
  font_verification = font_verification,
  hypothesis = sprintf("mean(%s - %s) %s 0", cfg$y, cfg$x, if (cfg$alternative == "greater") ">" else "<"),
  n_input = nrow(raw), n_pairs = nrow(dat), excluded_rows = which(!valid),
  mean_x = mx, mean_y = my, mean_difference_y_minus_x = mean(dat$difference),
  t_statistic = unname(test$statistic), df = unname(test$parameter), p_value = p_value,
  log_p_value = log_p, p_value_label = p_label, confidence_level = 0.95,
  one_sided_confidence_interval = as.character(test$conf.int),
  missing_color = missing_color, missing_size = missing_size,
  missing_size_rendered_at = if (missing_size) cfg$point_size else NULL,
  point_highlights = list(star_ids = cfg$star_ids, labels = cfg$point_labels,
    label_offsets = cfg$point_label_offsets, placement = cfg$point_label_placement, star_mark = "filled five-point polygon; finite mapped size has the same geometric area as a filled physical circle with the recorded diameter"),
  size_mapping = if (!is.null(cfg$size)) list(column = cfg$size, label = cfg$size_label %or% cfg$size,
    observed_range = range(dat$size, na.rm = TRUE), symbol_range_mm = cfg$size_range,
    breaks = cfg$size_breaks, mapping = "affine physical area in raw value with configured positive minimum-area offset",
    formula = "u=(value-v_min)/(v_max-v_min); D=sqrt(D_min^2+u*(D_max^2-D_min^2)); A=pi*D^2/4. Constant covariate: u=0.5.",
    area_range_mm2 = pi * cfg$size_range^2 / 4,
    area_slope_mm2_per_unit = if(diff(range(dat$size,na.rm=TRUE))==0)0 else
      pi * diff(cfg$size_range^2) / (4 * diff(range(dat$size,na.rm=TRUE))),
    area_intercept_mm2 = if(diff(range(dat$size,na.rm=TRUE))==0) pi * mean(cfg$size_range^2) / 4 else
      pi * (cfg$size_range[1]^2 - min(dat$size,na.rm=TRUE)*diff(cfg$size_range^2)/diff(range(dat$size,na.rm=TRUE))) / 4,
    proportional_through_zero = FALSE,
    circle_geometry = "filled circle, radius D/2 in mm, no outline stroke; not a ggplot nominal point symbol",
    star_geometry = "five-point polygon, inner/outer radius ratio 0.45; outer radius D*sqrt(pi/(5*0.45*sin(pi/5)))/2; no outline stroke",
    guide_geometry = "hollow circle; centerline radius reduced by half the outline width so outer stroke envelope diameter equals plotted D",
    guide_outline_width_mm = paired_size_guide_stroke_mm,
    guide_outline_width_policy = "minimum of nominal outline width and D/3, retaining a hollow center and exact outer diameter for small supplied size ranges",
    missing_fallback = "unmapped fixed-size legacy mark; no numeric area assigned or statistical weighting",
    guide = size_guide_record) else NULL,
  stats_box_overlapping_points = overlap, legend_placement_used = if (inside_legend) "inside" else "outside",
  legend_candidate_overlapping_points = legend_overlap, axis_limits = limits, axis_breaks = cfg$breaks,
  color_mapping = if (!is.null(color_mapping)) as.list(color_mapping) else NULL,
  point_color_mapping = if (!is.null(point_color_mapping)) as.list(point_color_mapping) else NULL,
  point_darken = cfg$point_darken, color_scale = color_scale_record,
  provenance = list(input = cfg$input, input_md5 = unname(tools::md5sum(cfg$input)),
                    config_md5 = unname(tools::md5sum(config_path)),
                    script_md5 = unname(tools::md5sum(script_path)),
                    formatting_md5 = unname(tools::md5sum(file.path(skill_dir, "scripts", "formatting.R"))),
                    font_export_md5 = unname(tools::md5sum(file.path(skill_dir, "scripts", "font_export.R"))),
                    palette_helpers_md5 = unname(tools::md5sum(file.path(skill_dir, "scripts", "palette_helpers.R"))),
                    paired_layout_md5 = unname(tools::md5sum(file.path(skill_dir, "scripts", "paired_layout.R"))),
                    paired_marginals_md5 = unname(tools::md5sum(file.path(skill_dir, "scripts", "paired_marginals.R"))),
                    palettes_md5 = unname(tools::md5sum(palette_path)), metric_source = cfg$metric_source,
                    generated_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE))
)
jsonlite::write_json(summary, paste0(cfg$output_prefix, ".statistics.json"), auto_unbox = TRUE, pretty = TRUE, digits = NA, na = "null", null = "null")
jsonlite::write_json(cfg, paste0(cfg$output_prefix, ".config.json"), auto_unbox = TRUE, pretty = TRUE, digits = NA, null = "null")
write.csv(dat, paste0(cfg$output_prefix, ".plotted-data.csv"), row.names = FALSE, na = "")
writeLines(capture.output(sessionInfo()), paste0(cfg$output_prefix, ".session.txt"))
message(sprintf("Rendered %d pairs; t = %.6f; p = %s; means x = %.6f, y = %.6f", nrow(dat), unname(test$statistic), p_text, mx, my))
message(paste(outputs, collapse = "\n"))
