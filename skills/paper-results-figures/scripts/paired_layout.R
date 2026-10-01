# Native axis label allocations omit glyph overhang at panel endpoints.
# Reserve measured physical canvas clearance before square-panel layout so all
# internal frames/labels use the resulting final geometry, on every device.
paired_endpoint_canvas_layout <- function(cfg, labels) {
  text_size_pt <- cfg$base_size - 1
  if (!is.finite(text_size_pt) || text_size_pt <= 0)
    stop("Paired axis text requires base_size greater than 1.")
  labels <- as.character(labels)
  path <- tempfile(fileext = ".png")
  measurement_dpi <- max(600, cfg$dpi)
  ragg::agg_png(path, width = 80, height = 80, units = "mm", res = measurement_dpi)
  metric <- tryCatch({
    vapply(labels, function(label) {
      glyph <- grid::textGrob(label,
        gp = grid::gpar(fontfamily = "Arial", fontsize = text_size_pt, lineheight = .9))
      c(width = grid::convertWidth(grid::grobWidth(glyph), "mm", valueOnly = TRUE),
        height = grid::convertHeight(grid::grobHeight(glyph), "mm", valueOnly = TRUE),
        ascent = grid::convertHeight(grid::grobAscent(glyph), "mm", valueOnly = TRUE),
        descent = grid::convertHeight(grid::grobDescent(glyph), "mm", valueOnly = TRUE))
    }, numeric(4))
  }, finally = { grDevices::dev.off(); unlink(path) })
  clearance_mm <- .35
  base_margin_mm <- 2 * 25.4 / 72.27
  margins <- c(top = max(base_margin_mm, max(metric["height", ]) / 2 + clearance_mm),
    right = max(base_margin_mm, max(metric["width", ]) / 2 + clearance_mm),
    bottom = max(base_margin_mm, clearance_mm), left = max(base_margin_mm, clearance_mm))
  list(policy = "Actual Arial endpoint extents plus physical canvas clearance; native left/bottom axis allocations retained",
    font = "Arial", text_size_pt = text_size_pt, measurement_device = "ragg",
    measurement_dpi = measurement_dpi, clearance_mm = clearance_mm,
    margin_mm = as.list(margins), native_base_margin_mm = base_margin_mm,
    tick_glyph_extents_mm = setNames(lapply(seq_along(labels), function(i) as.list(metric[, i])), labels),
    endpoint_overhang = "Half text height above top Y endpoint; half text width beyond right X endpoint. Native axis/title bands contain left and bottom endpoints.",
    canvas_dimensions_mm = c(width = cfg$width_mm, height = cfg$height_mm))
}

# A size covariate controls geometric area, with physical diameter endpoints.
# Positive minimum diameters introduce an explicitly recorded area offset.
paired_size_diameters <- function(values, diameter_range, observed_range) {
  u <- if (diff(observed_range) == 0) rep(.5, length(values)) else
    (values - observed_range[1]) / diff(observed_range)
  sqrt(diameter_range[1]^2 + u * diff(diameter_range^2))
}

paired_star_radius_factor <- sqrt(pi / (5 * .45 * sin(pi / 5))) / 2
paired_size_guide_lwd <- .55
# Grid line widths are multiples of 1/96 inch, independent of export DPI.
paired_size_guide_stroke_mm <- paired_size_guide_lwd * 25.4 / 96

paired_circle_grob <- function(x, y, diameter_mm, color, alpha = 1, hollow = FALSE) {
  radius_mm <- diameter_mm / 2
  stroke_mm <- min(paired_size_guide_stroke_mm, diameter_mm / 3)
  if (hollow) radius_mm <- radius_mm - stroke_mm / 2
  grid::circleGrob(x = x, y = y, r = grid::unit(radius_mm, "mm"),
    gp = grid::gpar(fill = if (hollow) NA else scales::alpha(color, alpha),
      col = if (hollow) scales::alpha(color, alpha) else NA,
      lwd = stroke_mm * 96 / 25.4))
}

paired_draw_key_circle <- function(data, params, size) {
  hollow <- !is.null(data$shape) && data$shape == 1
  paired_circle_grob(.5, .5, data$size, data$colour,
    alpha = if (is.null(data$alpha)) 1 else data$alpha, hollow = hollow)
}

paired_mark_radii_mm <- function(dat, cfg, symbol_mm) {
  # Preserve conservative legacy envelopes for unsized or missing-size marks.
  result <- symbol_mm * ifelse(dat$point_shape == "star", 1.15, .65)
  if (!is.null(cfg$size)) {
    finite <- !is.na(dat$size)
    result[finite] <- symbol_mm[finite] *
      ifelse(dat$point_shape[finite] == "star", paired_star_radius_factor, .5)
  }
  result
}

# Measure Arial annotations in physical units, then normalize against the square panel.
paired_arial_width <- function(text, size_mm) {
  systemfonts::string_width(text, family = "Arial", size = size_mm * 72.27 / 25.4,
    res = 1200) * 25.4 / 1200
}

# Grid uses the actual export face and multiline spacing. Cache measured glyph
# bounds so title/end-tick packing does not depend on a nominal font-size box.
paired_text_metric_cache <- new.env(parent = emptyenv())
paired_arial_bounds <- function(text, size_mm, lineheight = 1) {
  key <- paste(text, format(size_mm, digits = 15), lineheight, sep = "\r")
  if (exists(key, envir = paired_text_metric_cache, inherits = FALSE))
    return(get(key, envir = paired_text_metric_cache, inherits = FALSE))
  path <- tempfile(fileext = ".png")
  ragg::agg_png(path, width = 80, height = 80, units = "mm", res = 600)
  result <- tryCatch({
    grob <- grid::textGrob(text, gp = grid::gpar(fontfamily = "Arial",
      fontsize = size_mm * 72.27 / 25.4, lineheight = lineheight))
    c(width = grid::convertWidth(grid::grobWidth(grob), "mm", valueOnly = TRUE),
      height = grid::convertHeight(grid::grobHeight(grob), "mm", valueOnly = TRUE))
  }, finally = {grDevices::dev.off(); unlink(path)})
  assign(key, result, envir = paired_text_metric_cache)
  result
}

paired_box_valid <- function(box, name) {
  if (!is.numeric(box) || length(box) != 4 || any(!is.finite(box)) ||
      any(box < 0 | box > 1) || box[1] >= box[2] || box[3] >= box[4])
    stop(name, " must be normalized [left, right, bottom, top] within [0,1].")
  box
}

paired_box_intersects <- function(a, b, gap = 0) {
  a[1] < b[2] + gap && a[2] > b[1] - gap && a[3] < b[4] + gap && a[4] > b[3] - gap
}

paired_point_label_boxes <- function(labels, limits, panel_mm, cfg) {
  if (!nrow(labels)) return(list())
  lapply(seq_len(nrow(labels)), function(i) {
    bounds <- paired_arial_bounds(labels$point_label[i], cfg$point_label_size)
    center <- c(labels$label_x[i], labels$label_y[i])
    center <- (center - limits[1]) / diff(limits)
    c(center[1] - bounds["width"] / (2 * panel_mm),
      center[1] + bounds["width"] / (2 * panel_mm),
      center[2] - bounds["height"] / (2 * panel_mm),
      center[2] + bounds["height"] / (2 * panel_mm))
  })
}

# Resolve only omitted offsets. Conservative physical mark envelopes include
# every star tip; a fixed candidate order makes saved-config replay reproducible.
paired_place_point_labels <- function(dat, limits, panel_mm, cfg, symbol_mm,
                                     exclusions = list()) {
  labels <- dat[!is.na(dat$point_label), , drop = FALSE]
  if (!nrow(labels)) return(list(data = labels, record = NULL))
  xy <- cbind((dat$x - limits[1]) / diff(limits),
    (dat$y - limits[1]) / diff(limits)) * panel_mm
  radii <- paired_mark_radii_mm(dat, cfg, symbol_mm)
  mark_boxes <- lapply(seq_len(nrow(dat)), function(i)
    c(xy[i, 1] - radii[i], xy[i, 1] + radii[i],
      xy[i, 2] - radii[i], xy[i, 2] + radii[i]))
  exclusions <- lapply(exclusions, function(b) b * panel_mm)
  clearance <- .35; boundary <- .25
  explicit <- vapply(labels$pair_id, function(id) !is.null(cfg$point_label_offsets[[id]]), logical(1))
  placement_order <- c(which(explicit), which(!explicit)[order(labels$pair_id[!explicit], method = "radix")])
  accepted <- list(); decisions <- vector("list", nrow(labels))
  labels$label_x <- labels$label_y <- NA_real_
  angles <- unique(c(pi / 2, pi / 4, 3 * pi / 4, 0, pi, -pi / 4, -3 * pi / 4, -pi / 2,
    seq(0, 2 * pi, length.out = 33)[-33]))
  mean_xy <- colMeans(xy)
  for (i in placement_order) {
    index <- match(labels$pair_id[i], dat$pair_id)
    bounds <- paired_arial_bounds(labels$point_label[i], cfg$point_label_size)
    half_width <- unname(bounds["width"]) / 2
    half_height <- unname(bounds["height"]) / 2
    make_box <- function(center) c(center[1] - half_width, center[1] + half_width,
      center[2] - half_height, center[2] + half_height)
    inspect <- function(box) list(
      points = which(vapply(mark_boxes, function(b) paired_box_intersects(box, b, clearance), logical(1))),
      labels = which(vapply(accepted, function(b) paired_box_intersects(box, b, clearance), logical(1))),
      annotations = which(vapply(exclusions, function(b) paired_box_intersects(box, b, clearance), logical(1))),
      reference_lines = c(
        equality = box[1] - box[4] <= clearance * sqrt(2) &&
          box[2] - box[3] >= -clearance * sqrt(2),
        mean_x = box[1] <= mean_xy[1] + clearance && box[2] >= mean_xy[1] - clearance,
        mean_y = box[3] <= mean_xy[2] + clearance && box[4] >= mean_xy[2] - clearance),
      boundary = any(box[c(1, 3)] < boundary) || any(box[c(2, 4)] > panel_mm - boundary))
    candidate_index <- NA_integer_
    if (explicit[i]) {
      offset <- cfg$point_label_offsets[[labels$pair_id[i]]]
      center <- xy[index, ] + offset * panel_mm
      if (any(center < 0 | center > panel_mm))
        stop("Point label offsets place text outside the common axes; adjust them.")
    } else {
      candidates <- do.call(rbind, lapply(seq(0, max(8, panel_mm * .35), by = .5), function(extra)
        do.call(rbind, lapply(angles, function(angle) {
          distance <- radii[index] + clearance +
            half_width * abs(cos(angle)) + half_height * abs(sin(angle)) + extra
          xy[index, ] + distance * c(cos(angle), sin(angle))
        }))))
      for (j in seq_len(nrow(candidates))) {
        check <- inspect(make_box(candidates[j, ]))
        if (!length(check$points) && !length(check$labels) &&
            !length(check$annotations) && !any(check$reference_lines) && !check$boundary) {
          center <- candidates[j, ]; candidate_index <- j; break
        }
      }
      if (is.na(candidate_index))
        stop("No clear automatic position fits point label ", labels$pair_id[i],
          "; use a larger canvas or explicit point_label_offsets and inspect the result.")
    }
    box <- make_box(center); check <- inspect(box)
    labels$label_x[i] <- limits[1] + center[1] / panel_mm * diff(limits)
    labels$label_y[i] <- limits[1] + center[2] / panel_mm * diff(limits)
    accepted[[length(accepted) + 1L]] <- box
    decisions[[i]] <- list(id = labels$pair_id[i], text = labels$point_label[i],
      mode = if (explicit[i]) "explicit" else "automatic measured candidates",
      offset = unname((center - xy[index, ]) / panel_mm),
      bounds_normalized = unname(box / panel_mm), glyph_bounds_mm = as.list(bounds),
      candidate_index = candidate_index, overlapping_point_ids = dat$pair_id[check$points],
      overlapping_labels = check$labels, overlapping_annotations = check$annotations,
      overlapping_reference_lines = names(check$reference_lines)[check$reference_lines],
      boundary_clear = !check$boundary,
      safe = !length(check$points) && !length(check$labels) &&
        !length(check$annotations) && !any(check$reference_lines) && !check$boundary)
  }
  list(data = labels, record = list(policy = "deterministic Arial-measured candidates; explicit offsets preserved",
    panel_mm = panel_mm, clearance_mm = clearance, boundary_margin_mm = boundary,
    mark_envelope = "Finite size-mapped marks: exact circle radius diameter/2 or normalized star outer radius. Unsized/missing-size marks: conservative legacy envelopes (0.65 and 1.15 times nominal size).",
    placements = decisions))
}

paired_candidate_occupancy <- function(box, dat, limits, panel_mm, cfg, labels = NULL, exclusions = list()) {
  xx <- (dat$x - limits[1]) / diff(limits); yy <- (dat$y - limits[1]) / diff(limits)
  symbol_mm <- rep(cfg$point_size, nrow(dat))
  if (!is.null(cfg$size)) {
    finite <- !is.na(dat$size); r <- range(dat$size, na.rm = TRUE)
    symbol_mm[finite] <- paired_size_diameters(dat$size[finite], cfg$size_range, r)
  }
  radius <- paired_mark_radii_mm(dat, cfg, symbol_mm) / panel_mm + .004
  point_hits <- xx >= box[1] - radius & xx <= box[2] + radius &
    yy >= box[3] - radius & yy <= box[4] + radius
  label_hits <- 0L
  if (!is.null(labels) && nrow(labels)) {
    label_hits <- sum(vapply(paired_point_label_boxes(labels, limits, panel_mm, cfg),
      function(other) paired_box_intersects(box, other, .35 / panel_mm), logical(1)))
  }
  annotation_hits <- sum(vapply(exclusions, function(other) paired_box_intersects(box, other, .01), logical(1)))
  list(points = sum(point_hits), point_ids = dat$pair_id[point_hits], labels = label_hits,
    annotations = annotation_hits, safe = !any(point_hits) && label_hits == 0 && annotation_hits == 0)
}

paired_statistics_layout <- function(cfg, panel_mm, lines) {
  scale <- panel_mm / cfg$annotation_reference_mm
  size <- cfg$stats_font_size * scale
  width <- max(paired_arial_width(lines, size)) / (1 - 2 * cfg$stats_padding_fraction) / panel_mm
  height <- 2.9 * size / panel_mm
  auto <- is.null(cfg$stats_box)
  box <- if (auto) c(.97 - width, .97, .035, .035 + height) else paired_box_valid(cfg$stats_box, "stats_box")
  paired_box_valid(box, "Resolved statistics box")
  text_fraction <- max(paired_arial_width(lines, size)) / (diff(box[1:2]) * panel_mm)
  if (text_fraction > 1.001) stop("The statistics text is wider than the requested frame; increase stats_box width or adjust annotation_reference_mm.")
  list(box = box, text_size_mm = size, reference_panel_mm = cfg$annotation_reference_mm,
    scale_factor = scale, box_mode = if (auto) "measured" else "explicit",
    content_width_mm = max(paired_arial_width(lines, size)),
    text_fraction_of_width = text_fraction, horizontal_padding_fraction = (1 - text_fraction) / 2)
}

paired_category_layout <- function(cfg, panel_mm, names, colors, statistics_box) {
  scale <- panel_mm / cfg$annotation_reference_mm
  text_size <- cfg$legend_font_size * scale; title_size <- cfg$legend_title_size * scale
  ncols <- if (length(names) >= 3) 2L else length(names)
  nrows <- ceiling(length(names) / ncols)
  rows <- lapply(seq_len(nrows), function(i) seq.int((i - 1L) * ncols + 1L, min(i * ncols, length(names))))
  widths <- paired_arial_width(names, text_size)
  key <- .85 * scale; key_gap <- .60 * scale; col_gap <- 1.1 * scale
  col_widths <- vapply(seq_len(ncols), function(j) max(widths[seq.int(j, length(names), by = ncols)]), numeric(1))
  row_widths <- vapply(rows, function(ids) sum(col_widths[seq_along(ids)] + key + key_gap) +
    max(0, length(ids) - 1L) * col_gap, numeric(1))
  title <- if (is.null(cfg$color_label)) cfg$color else cfg$color_label
  content <- max(row_widths, paired_arial_width(title, title_size))
  width <- content / (1 - 2 * cfg$legend_padding_fraction) / panel_mm
  height_mm <- title_size * 1.05 + nrows * text_size * 1.3 + 1.0 * scale
  box <- if (is.null(cfg$legend_box)) c(.97 - width, .97, statistics_box[4] + .025,
    statistics_box[4] + .025 + height_mm / panel_mm) else paired_box_valid(cfg$legend_box, "legend_box")
  fits <- all(box >= 0 & box <= 1) && diff(box[1:2]) * panel_mm >= content &&
    diff(box[3:4]) * panel_mm >= height_mm * .95
  list(box = box, rows = rows, row_widths_mm = row_widths, column_widths_mm = col_widths,
    key_mm = key, key_gap_mm = key_gap, column_gap_mm = col_gap,
    text_size_mm = text_size, title_size_mm = title_size, fits = fits,
    labels = names, colors = colors, title = title,
    content_width_mm = content, box_mode = if (is.null(cfg$legend_box)) "measured" else "explicit",
    horizontal_padding_fraction = (1 - content / (diff(box[1:2]) * panel_mm)) / 2)
}

paired_match_frame_widths <- function(statistics, category, cfg, panel_mm, dat, limits, labels = NULL) {
  widths <- c(statistics = diff(statistics$box[1:2]), category = diff(category$box[1:2]))
  relative_difference <- abs(diff(widths)) / max(widths)
  record <- list(matched = FALSE, relative_difference = unname(relative_difference),
    tolerance = cfg$guide_width_match_tolerance, original_widths_mm = widths * panel_mm)
  if (statistics$box_mode != "measured" || category$box_mode != "measured") {
    record$reason <- "explicit frames preserve their supplied geometry"
  } else if (!category$fits || relative_difference > cfg$guide_width_match_tolerance) {
    record$reason <- "natural measured widths differ beyond the matching threshold or the category frame cannot fit"
  } else {
    common_width <- max(widths)
    statistic_box <- statistics$box; category_box <- category$box
    statistic_box[1] <- statistic_box[2] - common_width
    category_box[1] <- category_box[2] - common_width
    padding <- c(statistics = (1 - statistics$content_width_mm / (common_width * panel_mm)) / 2,
      category = (1 - category$content_width_mm / (common_width * panel_mm)) / 2)
    fits <- all(c(statistic_box, category_box) >= .005 & c(statistic_box, category_box) <= .995) &&
      all(padding >= 0 & padding <= cfg$guide_width_match_max_padding_fraction) &&
      paired_candidate_occupancy(statistic_box, dat, limits, panel_mm, cfg, labels,
        list(category_box))$safe &&
      paired_candidate_occupancy(category_box, dat, limits, panel_mm, cfg, labels,
        list(statistic_box))$safe
    if (fits) {
      statistics$box <- statistic_box; category$box <- category_box
      statistics$text_fraction_of_width <- 1 - 2 * padding["statistics"]
      statistics$horizontal_padding_fraction <- unname(padding["statistics"])
      category$horizontal_padding_fraction <- unname(padding["category"])
      record$matched <- TRUE; record$common_width_mm <- common_width * panel_mm
      record$reason <- "near-equal automatic frames share a readable collision-free width"
    } else record$reason <- "matching would exceed padding bounds or overlap data/annotations"
  }
  list(statistics = statistics, category = category, record = record)
}

paired_category_grob <- function(layout, cfg) {
  children <- list(grid::rectGrob(gp = grid::gpar(fill = scales::alpha("white", .90), col = "#555555", lwd = .51)),
    grid::textGrob(layout$title, x = .5, y = grid::unit(1, "npc") - grid::unit(layout$title_size_mm * .65, "mm"),
      gp = grid::gpar(fontfamily = "Arial", fontsize = layout$title_size_mm * 72.27 / 25.4, col = "#222222")))
  for (row in seq_along(layout$rows)) {
    ids <- layout$rows[[row]]
    # An incomplete final row is centered as a whole; text remains left-aligned.
    left <- grid::unit(.5, "npc") - grid::unit(layout$row_widths_mm[row] / 2, "mm")
    y <- grid::unit(1, "npc") - grid::unit(layout$title_size_mm * 1.05 +
      layout$text_size_mm * (row - .35) * 1.3 + .3 * layout$key_mm / .85, "mm")
    for (j in seq_along(ids)) {
      i <- ids[j]
      children[[length(children) + 1L]] <- grid::circleGrob(x = left + grid::unit(layout$key_mm / 2, "mm"),
        y = y, r = grid::unit(layout$key_mm / 2, "mm"),
        gp = grid::gpar(fill = scales::alpha(layout$colors[i], cfg$point_alpha), col = NA))
      children[[length(children) + 1L]] <- grid::textGrob(layout$labels[i],
        x = left + grid::unit(layout$key_mm + layout$key_gap_mm, "mm"), y = y, just = "left",
        gp = grid::gpar(fontfamily = "Arial", fontsize = layout$text_size_mm * 72.27 / 25.4, col = "#222222"))
      left <- left + grid::unit(layout$key_mm + layout$key_gap_mm + layout$column_widths_mm[j] + layout$column_gap_mm, "mm")
    }
  }
  grid::gTree(children = do.call(grid::gList, children), name = "internal-category-guide")
}

paired_size_layout <- function(cfg, panel_mm, keys, labels, symbols, title, statistics_box,
                               dat, limits, label_data = NULL) {
  scale <- panel_mm / cfg$annotation_reference_mm
  text_size <- cfg$legend_font_size * scale; title_size <- cfg$legend_title_size * scale
  title_bounds <- paired_arial_bounds(title, title_size)
  label_bounds <- vapply(labels, paired_arial_bounds, numeric(2), size_mm = text_size)
  cell_widths <- pmax(label_bounds["width", ], symbols)
  key_gap <- .8 * scale; row_gap <- .5 * scale
  padding <- cfg$size_legend_padding_mm * scale
  arrow_height <- if (length(keys) > 1) .45 * scale else 0
  key_width <- sum(cell_widths) + max(0, length(keys) - 1) * key_gap
  required_width <- max(title_bounds["width"], key_width) + 2 * padding
  content_height <- title_bounds["height"] + max(symbols) + max(label_bounds["height", ]) +
    2 * row_gap + if (length(keys) > 1) arrow_height + row_gap else 0
  required_height <- max(cfg$size_legend_min_height_mm * scale, content_height + 2 * padding)
  sb <- if (is.null(cfg$size_legend_box)) c(.97 - required_width / panel_mm, .97,
    statistics_box[4] + .025, statistics_box[4] + .025 + required_height / panel_mm) else
    paired_box_valid(cfg$size_legend_box, "size_legend_box")
  bounded <- all(sb >= 0 & sb <= 1)
  occupancy <- if (bounded) paired_candidate_occupancy(sb, dat, limits, panel_mm, cfg,
    label_data, list(statistics_box)) else list(points = 0, labels = 0, annotations = 1, safe = FALSE)
  frame_width <- diff(sb[1:2]) * panel_mm; frame_height <- diff(sb[3:4]) * panel_mm
  bottom_padding <- (frame_height - content_height) / 2
  label_y <- bottom_padding + max(label_bounds["height", ]) / 2
  arrow_y <- bottom_padding + max(label_bounds["height", ]) + row_gap + arrow_height / 2
  symbol_y <- bottom_padding + max(label_bounds["height", ]) + row_gap +
    if (length(keys) > 1) arrow_height + row_gap + max(symbols) / 2 else max(symbols) / 2
  title_y <- frame_height - bottom_padding - title_bounds["height"] / 2
  left <- (frame_width - key_width) / 2
  key_x <- left + cumsum(cell_widths + key_gap) - key_gap - cell_widths / 2
  fits <- bounded && occupancy$safe && length(keys) <= 5 && all(is.finite(symbols)) &&
    required_width <= frame_width + .02 && required_height <= frame_height + .02
  list(box = sb, breaks = keys, labels = labels, symbol_sizes_mm = symbols, title = title,
    text_size_mm = text_size, title_size_mm = title_size, fits = fits,
    required_width_mm = unname(required_width), required_height_mm = unname(required_height),
    minimum_height_mm = cfg$size_legend_min_height_mm * scale,
    top_bottom_padding_mm = unname(bottom_padding), key_x_mm = unname(key_x),
    title_y_mm = unname(title_y), symbol_y_mm = unname(symbol_y),
    arrow_y_mm = unname(arrow_y), label_y_mm = unname(label_y),
    arrow_length_mm = .65 * scale, arrow_end_padding_mm = c(.25, .35) * scale,
    frame_width_mm = unname(frame_width), frame_height_mm = unname(frame_height),
    candidate_overlapping_points = occupancy$points, candidate_overlapping_labels = occupancy$labels,
    quantity_type = cfg$size_type, symbol_geometry = "hollow circle with outer stroke envelope equal to the mapped plot-circle diameter",
    outline_width_mm = paired_size_guide_stroke_mm, effective_outline_widths_mm = pmin(paired_size_guide_stroke_mm, symbols / 3), symbol_outer_areas_mm2 = pi * symbols^2 / 4)
}

paired_size_grob <- function(layout, cfg) {
  u <- function(x) grid::unit(x, "mm")
  children <- list(grid::rectGrob(gp = grid::gpar(fill = scales::alpha("white", .90), col = "#555555", lwd = .51)),
    grid::textGrob(layout$title, x = .5, y = u(layout$title_y_mm),
      gp = grid::gpar(fontfamily = "Arial", fontsize = layout$title_size_mm * 72.27 / 25.4, col = "#222222")))
  for (i in seq_along(layout$breaks)) {
    children[[length(children) + 1L]] <- paired_circle_grob(
      x = u(layout$key_x_mm[i]), y = u(layout$symbol_y_mm),
      diameter_mm = layout$symbol_sizes_mm[i], color = "#444444", hollow = TRUE)
    children[[length(children) + 1L]] <- grid::textGrob(layout$labels[i],
      x = u(layout$key_x_mm[i]), y = u(layout$label_y_mm),
      gp = grid::gpar(fontfamily = "Arial", fontsize = layout$text_size_mm * 72.27 / 25.4, col = "#222222"))
  }
  if (length(layout$breaks) > 1) children[[length(children) + 1L]] <- grid::segmentsGrob(
    x0 = u(min(layout$key_x_mm) - layout$arrow_end_padding_mm[1]),
    x1 = u(max(layout$key_x_mm) + layout$arrow_end_padding_mm[2]),
    y0 = u(layout$arrow_y_mm), y1 = u(layout$arrow_y_mm),
    arrow = grid::arrow(length = u(layout$arrow_length_mm), type = "closed"),
    gp = grid::gpar(col = "#444444", fill = "#444444", lwd = .55))
  grid::gTree(children = do.call(grid::gList, children), name = "internal-size-guide")
}

paired_internal_color_breaks <- function(limits) {
  c(limits[1], mean(limits), limits[2])
}

paired_exterior_colorbar_guide <- function(tick_length_mm, ...) {
  guide <- ggplot2::guide_colorbar(...)
  # Draw only the label-side ticks, from that boundary into the gradient.
  # A positive physical length gives inward native Guide tick geometry.
  ggplot2::ggproto(NULL, guide, build_ticks = function(key, elements, params,
                                                     position = params$position) {
    positions <- key$.value
    if (!is.null(params$draw_lim)) {
      if (!params$draw_lim[1]) positions <- positions[-1]
      if (!params$draw_lim[2]) positions <- positions[-length(positions)]
    }
    side <- if (params$direction == "horizontal") "bottom" else "right"
    ggplot2::Guide$build_ticks(positions, elements, params, position = side,
      length = grid::unit(tick_length_mm, "mm"))
  })
}

paired_colorbar_geometry <- function(cfg, panel_mm, title, labels, orientation) {
  scale <- panel_mm / cfg$annotation_reference_mm
  size <- cfg$colorbar_inside_title_size * scale; tick_size <- cfg$colorbar_text_size * scale
  title_bounds <- paired_arial_bounds(title, size)
  label_bounds <- vapply(labels, paired_arial_bounds, numeric(2), size_mm = tick_size)
  breaks <- paired_internal_color_breaks(cfg$colorbar_limits)
  if (length(labels) != length(breaks)) stop("Internal continuous guides require first/midpoint/last labels.")
  ticks <- (breaks - cfg$colorbar_limits[1]) / diff(cfg$colorbar_limits)
  padding <- cfg$colorbar_padding_mm * scale
  title_gap <- cfg$colorbar_title_gap_mm * scale
  tick_gap <- cfg$colorbar_tick_gap_mm * scale
  tick_length <- cfg$colorbar_tick_length_mm * scale
  thickness <- cfg$colorbar_width_mm * scale
  adjacent <- if (length(ticks) > 1) head(seq_along(ticks), -1) else integer()
  min_tick_length <- if (!length(adjacent)) 0 else max(
    (label_bounds[if (orientation == "vertical") "height" else "width", adjacent] / 2 +
     label_bounds[if (orientation == "vertical") "height" else "width", adjacent + 1] / 2 + tick_gap) /
    diff(ticks))
  length_mm <- max(cfg$colorbar_inside_height_mm * scale, min_tick_length)
  if (orientation == "vertical") {
    bottom_overhang <- max(0, label_bounds["height", ] / 2 - ticks * length_mm)
    top_overhang <- max(0, label_bounds["height", ] / 2 - (1 - ticks) * length_mm)
    body_width <- thickness + tick_gap + max(label_bounds["width", ])
    full_width <- max(title_bounds["width"], body_width) + 2 * padding
    full_height <- bottom_overhang + length_mm + top_overhang + title_gap + title_bounds["height"] + 2 * padding
    gx <- (full_width - body_width) / 2; gy <- padding + bottom_overhang
    gradient_box <- c(gx, gx + thickness, gy, gy + length_mm)
    tick_x <- rep(gx + thickness + tick_gap, length(ticks)); tick_y <- gy + ticks * length_mm
    tick_segments <- lapply(seq_along(ticks), function(i) c(gx + thickness - tick_length,
      gx + thickness, tick_y[i], tick_y[i]))
    tick_boxes <- lapply(seq_along(ticks), function(i) c(tick_x[i], tick_x[i] + label_bounds["width", i],
      tick_y[i] - label_bounds["height", i] / 2, tick_y[i] + label_bounds["height", i] / 2))
    title_y <- gy + length_mm + top_overhang + title_gap + title_bounds["height"] / 2
  } else {
    left_overhang <- max(0, label_bounds["width", ] / 2 - ticks * length_mm)
    right_overhang <- max(0, label_bounds["width", ] / 2 - (1 - ticks) * length_mm)
    body_width <- left_overhang + length_mm + right_overhang
    full_width <- max(title_bounds["width"], body_width) + 2 * padding
    full_height <- max(label_bounds["height", ]) + tick_gap + thickness + title_gap + title_bounds["height"] + 2 * padding
    gx <- (full_width - body_width) / 2 + left_overhang
    gy <- padding + max(label_bounds["height", ]) + tick_gap
    gradient_box <- c(gx, gx + length_mm, gy, gy + thickness)
    tick_x <- gx + ticks * length_mm; tick_y <- rep(padding + max(label_bounds["height", ]) / 2, length(ticks))
    tick_segments <- lapply(seq_along(ticks), function(i) c(tick_x[i], tick_x[i],
      gy, gy + tick_length))
    tick_boxes <- lapply(seq_along(ticks), function(i) c(tick_x[i] - label_bounds["width", i] / 2,
      tick_x[i] + label_bounds["width", i] / 2, tick_y[i] - label_bounds["height", i] / 2,
      tick_y[i] + label_bounds["height", i] / 2))
    title_y <- gy + thickness + title_gap + title_bounds["height"] / 2
  }
  title_box <- c((full_width - title_bounds["width"]) / 2, (full_width + title_bounds["width"]) / 2,
    title_y - title_bounds["height"] / 2, title_y + title_bounds["height"] / 2)
  components <- c(list(title = unname(title_box), gradient = unname(gradient_box)),
    setNames(lapply(tick_boxes, unname), paste0("tick_", seq_along(tick_boxes))),
    setNames(lapply(tick_segments, function(b) unname(b + c(-.06, .06, -.06, .06) * scale)),
      paste0("mark_", seq_along(tick_segments))))
  if (paired_box_intersects(title_box, gradient_box) ||
      any(vapply(tick_boxes, paired_box_intersects, logical(1), b = title_box)) ||
      any(vapply(tick_boxes, paired_box_intersects, logical(1), b = gradient_box)))
    stop("Measured continuous-guide title/gradient/tick boxes overlap; adapt the guide gaps.")
  if (length(tick_boxes) > 1 && any(vapply(seq_len(length(tick_boxes) - 1), function(i)
      paired_box_intersects(tick_boxes[[i]], tick_boxes[[i + 1]]), logical(1))))
    stop("Measured continuous-guide tick boxes overlap; increase its usable length.")
  if (any(vapply(components[grep("^mark_", names(components))], function(b)
      paired_box_intersects(b, title_box) ||
      any(vapply(tick_boxes, paired_box_intersects, logical(1), b = b)), logical(1))))
    stop("Inward color-axis ticks would overlap text; adjust the guide gaps.")
  list(orientation = orientation, title_size_mm = size, text_size_mm = tick_size,
    breaks = breaks, normalized_tick_positions = c(0, .5, 1), separator_lines = "none",
    tick_marks = "short inward", tick_length_mm = tick_length, tick_offset_mm = 0,
    tick_boundary = if (orientation == "vertical") "right" else "bottom",
    gradient_width_mm = if (orientation == "vertical") thickness else length_mm,
    gradient_height_mm = if (orientation == "vertical") length_mm else thickness,
    full_width_mm = unname(full_width), full_height_mm = unname(full_height),
    title_height_mm = unname(title_bounds["height"]), title_y_mm = unname(title_y),
    gradient_box_mm = unname(gradient_box), tick_x_mm = unname(tick_x), tick_y_mm = unname(tick_y),
    tick_segment_bounds_mm = lapply(tick_segments, unname),
    component_bounds_mm = components, scale_factor = scale,
    padding_mm = padding, title_gap_mm = title_gap, tick_gap_mm = tick_gap,
    tick_boxes_overlap = FALSE, title_tick_overlap = FALSE)
}

paired_colorbar_layout <- function(cfg, panel_mm, title, labels, stats_box, dat, limits,
                                    label_data = NULL, exclusions = list()) {
  orientations <- if (cfg$colorbar_orientation == "auto") c("horizontal", "vertical") else cfg$colorbar_orientation
  solutions <- list(); checks <- list()
  for (orientation in orientations) {
    geometry <- paired_colorbar_geometry(cfg, panel_mm, title, labels, orientation)
    width <- geometry$full_width_mm / panel_mm; height <- geometry$full_height_mm / panel_mm
    if (!is.null(cfg$colorbar_box)) candidates <- list(paired_box_valid(cfg$colorbar_box, "colorbar_box")) else {
      candidates <- list(c(.97 - width, .97, stats_box[4] + .025, stats_box[4] + .025 + height))
      # Search complete measured frames, including all endpoint glyph overhang.
      for (x in unique(c(.025, .97 - width, seq(.025, max(.025, .975 - width), length.out = 7))))
        for (y in unique(c(.97 - height, .025, seq(.025, max(.025, .975 - height), length.out = 8))))
          candidates[[length(candidates) + 1L]] <- c(x, x + width, y, y + height)
    }
    for (box in candidates) {
      if (any(box < .005 | box > .995)) next
      if (diff(box[1:2]) * panel_mm < geometry$full_width_mm - .02 ||
          diff(box[3:4]) * panel_mm < geometry$full_height_mm - .02) next
      check <- paired_candidate_occupancy(box, dat, limits, panel_mm, cfg, label_data,
        c(list(stats_box), exclusions))
      checks[[length(checks) + 1L]] <- c(list(orientation = orientation), check)
      if (check$safe) {
        geometry$box <- box; geometry$safe <- TRUE
        geometry$candidate_overlapping_points <- check$points
        geometry$candidate_overlapping_labels <- check$labels
        solutions[[length(solutions) + 1L]] <- geometry
        break
      }
    }
  }
  choice <- if (length(solutions)) solutions[[which.min(vapply(solutions,
    function(x) x$full_width_mm * x$full_height_mm, numeric(1)))]] else
    c(paired_colorbar_geometry(cfg, panel_mm, title, labels, orientations[1]), list(box = NULL, safe = FALSE))
  choice$candidates_checked <- length(checks)
  choice$orientations_checked <- orientations
  choice
}

paired_colorbar_grob <- function(layout, cfg, title, labels, colors) {
  # Center the measured content if an explicit frame is larger than its minimum.
  x <- function(value) grid::unit(.5, "npc") + grid::unit(value - layout$full_width_mm / 2, "mm")
  y <- function(value) grid::unit(.5, "npc") + grid::unit(value - layout$full_height_mm / 2, "mm")
  b <- layout$gradient_box_mm
  ramp <- grDevices::colorRampPalette(colors)(256L)
  raster <- if (layout$orientation == "vertical") matrix(scales::alpha(rev(ramp), cfg$point_alpha), ncol = 1L) else
    matrix(scales::alpha(ramp, cfg$point_alpha), nrow = 1L)
  children <- list(grid::rectGrob(gp = grid::gpar(fill = scales::alpha("white", .90), col = "#555555", lwd = .51)),
    grid::textGrob(title, x = .5, y = y(layout$title_y_mm),
      gp = grid::gpar(fontfamily = "Arial", fontsize = layout$title_size_mm * 72.27 / 25.4, lineheight = 1.0, col = "#222222")),
    grid::rasterGrob(raster, x = x(mean(b[1:2])), y = y(mean(b[3:4])),
      width = grid::unit(diff(b[1:2]), "mm"), height = grid::unit(diff(b[3:4]), "mm"), interpolate = TRUE),
    grid::rectGrob(x = x(mean(b[1:2])), y = y(mean(b[3:4])), width = grid::unit(diff(b[1:2]), "mm"),
      height = grid::unit(diff(b[3:4]), "mm"), gp = grid::gpar(fill = NA, col = "#444444", lwd = .56)))
  # Short inward marks start at the label-side boundary without spanning the gradient.
  for (i in seq_along(layout$breaks)) {
    segment <- layout$tick_segment_bounds_mm[[i]]
    children[[length(children) + 1L]] <- grid::segmentsGrob(x0 = x(segment[1]), x1 = x(segment[2]),
      y0 = y(segment[3]), y1 = y(segment[4]), name = paste0("color-axis-tick-", i),
      gp = grid::gpar(col = "#444444", lwd = .45 * layout$scale_factor))
    children[[length(children) + 1L]] <- grid::textGrob(labels[i],
      x = x(layout$tick_x_mm[i]), y = y(layout$tick_y_mm[i]),
      just = if (layout$orientation == "vertical") "left" else "centre",
      gp = grid::gpar(fontfamily = "Arial", fontsize = layout$text_size_mm * 72.27 / 25.4, col = "#222222"))
  }
  grid::gTree(children = do.call(grid::gList, children), name = "internal-continuous-color-axis")
}
