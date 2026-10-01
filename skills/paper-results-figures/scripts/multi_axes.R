# Resolve honest numeric views from every mark/interval that is actually shown.
# Inverse display coordinates use a stable origin. Snap numerical roundoff only
# at stated axis endpoints so secondary boundary ticks survive break selection.
affine_axis_inverse <- function(x, primary_limits, secondary_limits) {
  y <- secondary_limits[1] + (x - primary_limits[1]) *
    (diff(secondary_limits) / diff(primary_limits))
  tolerance <- 64 * .Machine$double.eps * max(abs(primary_limits),
    diff(primary_limits), .Machine$double.xmin)
  lower <- is.finite(x) & abs(x - primary_limits[1]) <= tolerance
  upper <- is.finite(x) & abs(x - primary_limits[2]) <= tolerance
  y[lower] <- secondary_limits[1]
  y[upper] <- secondary_limits[2]
  y
}

resolve_multi_axis <- function(extent, cfg, limits = NULL, breaks = NULL,
    available_mm, horizontal = FALSE, style = "bar") {
  extent <- extent[is.finite(extent)]
  if (!length(extent)) stop("No finite numeric extent to display.")
  included <- extent
  if (cfg$axis_policy == "zero" || (style == "bar" && cfg$axis_policy == "full"))
    included <- c(included, 0)
  rr <- range(included); span <- diff(rr)
  if (span == 0) span <- max(abs(rr), 1) * .1
  automatic <- is.null(limits)
  if (automatic) {
    pad <- if (cfg$axis_policy == "zoom") span * (1 / cfg$occupancy - 1) / 2 else span * .06
    limits <- rr + c(-pad, pad)
    if (style == "bar" && min(included) >= 0 && limits[1] < 0) limits[1] <- 0
    if (style == "bar" && max(included) <= 0 && limits[2] > 0) limits[2] <- 0
  }
  if (!is.numeric(limits) || length(limits) != 2 || any(!is.finite(limits)) || diff(limits) <= 0)
    stop("Numeric limits must contain two increasing finite values.")
  if (min(extent) < limits[1] - 1e-12 || max(extent) > limits[2] + 1e-12)
    stop("Numeric limits would hide observations or displayed uncertainty.")
  automatic_breaks <- is.null(breaks)
  if (automatic_breaks) breaks <- choose_axis_breaks(limits, available_mm, cfg$axis_text_size, horizontal)
  if (!is.numeric(breaks) || any(!is.finite(breaks))) stop("Numeric breaks must be finite.")
  breaks <- breaks[breaks >= limits[1] - 1e-10 & breaks <= limits[2] + 1e-10]
  # Re-select and complete ticks after every automatic baseline extension. The
  # final tick step, rather than a discarded provisional step, defines closeness.
  for (iteration in seq_len(6)) {
    previous <- limits
    if (automatic && style == "bar" && cfg$axis_policy == "zoom" && !is.null(cfg$bar_min_fraction)) {
      if (min(extent)>0 && limits[1]>0)
        limits[1]<-max(0,min(limits[1],(min(extent)-cfg$bar_min_fraction*limits[2])/(1-cfg$bar_min_fraction)))
      if (max(extent)<0 && limits[2]<0)
        limits[2]<-min(0,max(limits[2],(max(extent)-cfg$bar_min_fraction*limits[1])/(1-cfg$bar_min_fraction)))
    }
    if (automatic_breaks) breaks <- choose_axis_breaks(limits, available_mm, cfg$axis_text_size, horizontal)
    if (automatic && automatic_breaks) {
      completed <- complete_nearby_axis_ticks(limits, breaks)
      limits <- completed$limits; breaks <- completed$breaks
    }
    if (isTRUE(all.equal(previous, limits, tolerance=1e-12))) break
  }
  # Tick completion can leave a machine-roundoff residue at a zero endpoint.
  # Normalize only automatic limits; explicit scientific bounds remain exact.
  if (automatic) {
    zero_tolerance <- 64 * .Machine$double.eps * max(abs(limits), diff(limits), .Machine$double.xmin)
    limits[abs(limits) <= zero_tolerance] <- 0
  }
  baseline <- if (style != "bar") NULL else if (limits[1] > 0) limits[1] else if (limits[2] < 0) limits[2] else 0
  breaks<-snap_axis_breaks(breaks,limits)
  list(limits = limits, breaks = breaks, baseline = baseline,
    included_extent = range(extent), policy = cfg$axis_policy,
    note = if (!is.null(baseline) && baseline != 0)
      sprintf("Truncated bar axis; baseline = %.6g. Compare labeled values, not bar lengths as ratios.", baseline) else NULL)
}

multi_metric_extent <- function(summary, observations, show_sd, show_points, style) {
  values <- summary$mean
  if (show_sd) values <- c(values, summary$mean - summary$sd, summary$mean + summary$sd)
  if (show_points && style != "line") values <- c(values, observations$value)
  values
}

finish_metric_panels_grob <- function(grob, cfg) {
  if (!is.null(cfg$title)) {
    title <- grid::textGrob(cfg$title, gp = grid::gpar(fontfamily = "Arial", fontsize = cfg$title_size, lineheight = 1.02))
    grob <- gtable::gtable_add_rows(grob, grid::grobHeight(title) + grid::unit(1.5, "mm"), pos = 0)
    grob <- gtable::gtable_add_grob(grob, title, t = 1, l = 1, r = ncol(grob), clip = "off", name = "shared-title")
  }
  if (!is.null(cfg$panel_tag)) {
    tag <- grid::textGrob(cfg$panel_tag, x = grid::unit(cfg$outer_margin, "pt"), just = "left",
      gp = grid::gpar(fontfamily = "Arial", fontface = "bold", fontsize = cfg$tag_size))
    grob <- gtable::gtable_add_rows(grob, grid::unit(cfg$tag_size * 1.05, "pt"), pos = 0)
    grob <- gtable::gtable_add_grob(grob, tag, t = 1, l = 1, r = ncol(grob), clip = "off", name = "shared-tag")
  }
  if (!is.null(cfg$caption)) {
    caption <- grid::textGrob(cfg$caption, x = grid::unit(cfg$outer_margin, "pt"), just = "left",
      gp = grid::gpar(fontfamily = "Arial", fontsize = 5))
    grob <- gtable::gtable_add_rows(grob, grid::grobHeight(caption) + grid::unit(1, "mm"))
    grob <- gtable::gtable_add_grob(grob, caption, t = nrow(grob), l = 1, r = ncol(grob), clip = "off", name = "shared-caption")
  }
  gtable::gtable_add_rows(grob, grid::unit(.5, "mm"), pos = 0)
}
