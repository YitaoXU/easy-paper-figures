# Optional score-distribution strips share the retained paired sample and score axis.
paired_marginal_distribution <- function(values, limits, bins = 8L, bandwidth = "nrd0", min_n = 5L) {
  breaks <- seq(limits[1], limits[2], length.out = bins + 1L)
  h <- graphics::hist(values, breaks = breaks, plot = FALSE, include.lowest = TRUE, right = TRUE)
  reason <- if (length(values) < min_n) "too few retained values for the configured KDE minimum" else
    if (length(unique(values)) < 2L) "constant score distribution" else NULL
  d <- if (is.null(reason)) stats::density(values, bw = bandwidth, from = limits[1],
    to = limits[2], n = 512L) else NULL
  list(n = length(values), breaks = h$breaks, counts = h$counts, density = h$density,
    histogram_integral = sum(h$density * diff(h$breaks)),
    curve_x = if (is.null(d)) numeric() else d$x,
    curve_y = if (is.null(d)) numeric() else d$y,
    bandwidth = if (is.null(d)) NULL else d$bw,
    kde_status = if (is.null(d)) "omitted" else "drawn", kde_omission_reason = reason,
    max_density = max(c(h$density, if (is.null(d)) 0 else d$y)) * 1.08)
}

paired_marginal_record <- function(cfg, dat, limits, palette) {
  if (!isTRUE(cfg$marginals)) return(NULL)
  colors <- c(reference = cfg$marginal_reference_color, focal = cfg$marginal_focal_color)
  if (is.null(cfg$marginal_reference_color)) colors["reference"] <-
    darken_palette_colors(palette$anchors[2], cfg$point_darken)
  if (is.null(cfg$marginal_focal_color)) colors["focal"] <-
    darken_palette_colors(palette$anchors[3], cfg$point_darken)
  grDevices::col2rgb(colors)
  list(enabled = TRUE, retained_pair_count = nrow(dat), bins = cfg$marginal_bins,
    strip_size_mm = cfg$marginal_strip_mm, strip_gap_mm = cfg$marginal_gap_mm,
    colors = as.list(colors), histogram_alpha = cfg$marginal_alpha,
    histogram = "probability density; shared equally spaced score breaks; area equals one",
    kde = "Gaussian kernel; true density values; no peak matching to histogram",
    strip_normalization = "each strip divides both histogram and KDE by its shared max density",
    top = paired_marginal_distribution(dat$x, limits, cfg$marginal_bins,
      cfg$marginal_bandwidth, cfg$marginal_kde_min_n),
    right = paired_marginal_distribution(dat$y, limits, cfg$marginal_bins,
      cfg$marginal_bandwidth, cfg$marginal_kde_min_n))
}

paired_add_marginals <- function(g, record, limits) {
  if (is.null(record)) return(g)
  panel <- g$layout[g$layout$name == "panel", ][1, ]
  norm <- function(v) (v - limits[1]) / diff(limits)
  strip <- function(dist, orientation, color) {
    centres <- norm(head(dist$breaks, -1) + diff(dist$breaks) / 2)
    widths <- diff(dist$breaks) / diff(limits)
    heights <- dist$density / dist$max_density
    curve_pos <- norm(dist$curve_x); curve_den <- dist$curve_y / dist$max_density
    if (orientation == "top") {
      bars <- grid::rectGrob(x = centres, y = heights / 2, width = widths, height = heights,
        gp = grid::gpar(fill = scales::alpha(color, record$histogram_alpha), col = "white", lwd = .35))
      line <- if (length(curve_pos)) grid::linesGrob(x = curve_pos, y = curve_den,
        gp = grid::gpar(col = color, lwd = .8)) else grid::nullGrob()
      baseline <- grid::segmentsGrob(x0 = 0, x1 = 1, y0 = 0, y1 = 0,
        gp = grid::gpar(col = "#777777", lwd = .4))
    } else {
      bars <- grid::rectGrob(x = heights / 2, y = centres, width = heights, height = widths,
        gp = grid::gpar(fill = scales::alpha(color, record$histogram_alpha), col = "white", lwd = .35))
      line <- if (length(curve_pos)) grid::linesGrob(x = curve_den, y = curve_pos,
        gp = grid::gpar(col = color, lwd = .8)) else grid::nullGrob()
      baseline <- grid::segmentsGrob(x0 = 0, x1 = 0, y0 = 0, y1 = 1,
        gp = grid::gpar(col = "#777777", lwd = .4))
    }
    grid::grobTree(bars, line, baseline)
  }
  g <- gtable::gtable_add_rows(g, grid::unit(c(record$strip_size_mm, record$strip_gap_mm), "mm"), pos = panel$t - 1L)
  g <- gtable::gtable_add_cols(g, grid::unit(c(record$strip_gap_mm, record$strip_size_mm), "mm"), pos = panel$r)
  shifted <- g$layout[g$layout$name == "panel", ][1, ]
  g <- gtable::gtable_add_grob(g, strip(record$top, "top", record$colors$reference),
    t = shifted$t - 2L, l = shifted$l, r = shifted$r, clip = "on", name = "reference-marginal")
  gtable::gtable_add_grob(g, strip(record$right, "right", record$colors$focal),
    t = shifted$t, b = shifted$b, l = shifted$r + 2L, clip = "on", name = "focal-marginal")
}

paired_panel_dimensions <- function() {
  grid::grid.force()
  viewports <- grid::grid.ls(viewports = TRUE, grobs = FALSE, print = FALSE)$name
  panel <- viewports[grepl("^panel\\.[0-9]+-", viewports)][1]
  if (is.na(panel)) stop("Cannot measure the paired main panel viewport.")
  grid::seekViewport(panel)
  size <- c(width = grid::convertWidth(grid::unit(1, "npc"), "mm", valueOnly = TRUE),
    height = grid::convertHeight(grid::unit(1, "npc"), "mm", valueOnly = TRUE))
  grid::upViewport(0)
  if (abs(diff(size)) > .02) stop("Paired panel lost its square geometry.")
  size
}

paired_measure_panel <- function(p, cfg, record, limits) {
  path <- tempfile(fileext = ".png")
  ragg::agg_png(path, width = cfg$width, height = cfg$height, units = "in", res = 120, background = "white")
  on.exit({ grDevices::dev.off(); unlink(path) }, add = TRUE)
  grid::grid.newpage()
  grid::grid.draw(paired_add_marginals(ggplot2::ggplotGrob(p), record, limits))
  paired_panel_dimensions()
}
