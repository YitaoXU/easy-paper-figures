# Optional numeric thresholds; never statistics or categorical comparisons.
resolve_numeric_reference_lines <- function(lines, cfg) {
  if (is.null(lines) || (is.list(lines) && !length(lines))) return(list())
  if (is.data.frame(lines)) lines <- lapply(seq_len(nrow(lines)), function(i) as.list(lines[i, , drop = FALSE]))
  if (!is.list(lines) || !length(lines) || !all(vapply(lines, is.list, logical(1))))
    stop("reference_lines must be an array of objects with one finite numeric value each.")
  if (cfg$plot_type == "multi-metric-comparison") stop("reference_lines currently supports single-metric comparisons only.")
  if (!is.null(cfg$axis_break)) stop("reference_lines requires a continuous numeric axis; omit axis_break.")
  allowed <- c("value", "label", "color", "linetype", "linewidth", "label_size")
  lapply(lines, function(line) {
    unknown <- setdiff(names(line), allowed)
    if (length(unknown)) stop("Unknown reference_lines fields: ", paste(unknown, collapse = ", "))
    defaults <- list(label = NULL, color = "#D62728", linetype = "42", linewidth = .28,
      label_size = cfg$axis_text_size * 25.4 / 72)
    line <- utils::modifyList(defaults, line, keep.null = TRUE)
    if (!is.numeric(line$value) || length(line$value) != 1 || !is.finite(line$value))
      stop("Each reference line value must be one finite number.")
    if (!is.null(line$label) && (!is.character(line$label) || length(line$label) != 1 || is.na(line$label)))
      stop("Reference line label must be one string or null.")
    if (!is.character(line$color) || length(line$color) != 1 || is.na(line$color) ||
        inherits(try(grDevices::col2rgb(line$color), silent = TRUE), "try-error"))
      stop("Reference line color must be one valid R color.")
    if (!((is.character(line$linetype) && length(line$linetype) == 1 && !is.na(line$linetype) &&
        (line$linetype %in% c("solid", "dashed", "dotted", "dotdash", "longdash", "twodash") ||
        grepl("^(?:[1-9A-Fa-f]{2}){1,4}$", line$linetype, perl = TRUE))) ||
        (is.numeric(line$linetype) && length(line$linetype) == 1 && is.finite(line$linetype) && line$linetype %in% 1:6)))
      stop("Reference linetype must be a named type, integer 1 to 6, or a 2/4/6/8-digit positive hexadecimal dash pattern.")
    for (key in c("linewidth", "label_size")) if (!is.numeric(line[[key]]) ||
        length(line[[key]]) != 1 || !is.finite(line[[key]]) || line[[key]] <= 0)
      stop("Reference ", key, " must be one positive finite size in millimeters.")
    line
  })
}

add_numeric_reference_marks <- function(plot, cfg) {
  for (line in cfg$reference_lines) plot <- plot + ggplot2::geom_hline(
    yintercept = line$value, color = line$color, linetype = line$linetype,
    linewidth = line$linewidth, inherit.aes = FALSE, show.legend = FALSE)
  plot
}

frame_numeric_reference_labels <- function(grob, cfg, draw = TRUE) {
  lines <- cfg$reference_lines
  if (!length(lines)) return(list(grob = grob, record = list(enabled = FALSE)))
  panel <- grob$layout[grob$layout$name == "panel", , drop = FALSE]
  if (nrow(panel) != 1) stop("Numeric reference annotations require one data panel.")
  limits <- if (is.null(cfg$limits)) cfg$data_limits else cfg$limits
  if (is.null(limits)) stop("Numeric reference annotations need resolved axis limits.")
  pw <- cfg$width_mm - grid::convertWidth(sum(grob$widths), "mm", valueOnly = TRUE)
  ph <- cfg$height_mm - grid::convertHeight(sum(grob$heights), "mm", valueOnly = TRUE)
  if (min(pw, ph) <= 0) stop("No data panel remains for numeric reference annotations.")
  labeled <- which(vapply(lines, function(z) !is.null(z$label) && nzchar(z$label), logical(1)))
  record <- list(enabled = TRUE, numeric_axis = if (cfg$orientation == "horizontal") "x" else "y",
    line_values = vapply(lines, `[[`, numeric(1), "value"), limits = limits,
    label_policy = "Measured exterior labels with retained Arial size; reference values remain exact.",
    labels = list(), reserved_mm = 0)
  if (!length(labeled)) return(list(grob = grob, record = record))
  gap <- .65
  horizontal <- cfg$orientation == "horizontal"
  # A right-hand reference frame narrows the category panel and can rotate
  # mean labels. Reserve their actual rotated Arial bounds above the panel.
  # Keep all no-reference and horizontal geometry untouched.
  top <- attr(cfg, "reference_top_annotation")
  if (!horizontal && !is.null(top)) {
    existing <- if (is.null(cfg$title)) grid::convertHeight(grob$heights[1], "mm", valueOnly = TRUE) else
      cfg$annotation_gap * 25.4 / 72 + top$layout$significance_gutter_mm
    offsets <- halves <- numeric()
    if (top$layout$values_side == "above" && length(top$values)) {
      extents <- vapply(seq_along(top$values), function(i)
        arial_text_extents_mm(top$values[i], cfg$value_size * 72 / 25.4,
          bold = top$faces[i] == "bold")[, 1], numeric(2))
      value_height <- max(rotated_text_extents_mm(extents, cfg$value_angle)["height", ])
      offsets <- c(offsets, cfg$value_offset); halves <- c(halves, value_height / 2)
    }
    if (top$layout$rank_side == "above") {
      rank_height <- arial_text_extents_mm("Performance Ranking", cfg$rank_size * 72 / 25.4)["height", 1]
      offsets <- c(offsets, cfg$rank_offset, cfg$rank_offset - cfg$rank_text_gap)
      halves <- c(halves, .4, rank_height / 2)
    }
    extra <- if (length(offsets)) max(0, (offsets * ph + halves + gap - existing) / (1 + offsets)) else 0
    if (extra > 0) {
      if (ph - extra < cfg$text_min_panel_mm)
        stop("Reference annotations leave insufficient panel height; shorten labels or increase height_mm.")
      grob <- gtable::gtable_add_rows(grob, grid::unit(extra, "mm"), pos = panel$t - 1)
      panel <- grob$layout[grob$layout$name == "panel", , drop = FALSE]
      ph <- ph - extra
    }
    record$top_annotation_frame <- list(existing_mm = existing, additional_mm = extra,
      glyph_half_heights_mm = halves, numeric_offsets = offsets,
      clearance_mm = gap, preserved_font_size = TRUE, preserved_numeric_offsets = TRUE)
  }
  sizes <- lapply(lines[labeled], function(z) arial_text_extents_mm(z$label, z$label_size * 72 / 25.4))
  if (horizontal) {
    # The label row may use the numeric/ranking gutter, clear of its lower marks.
    right_fixed <- grid::convertWidth(sum(grob$widths[seq.int(panel$r + 1, length(grob$widths))]), "mm", valueOnly = TRUE)
    frame_width <- pw + max(0, right_fixed - cfg$outer_margin * 25.4 / 72)
    labels <- vapply(lines[labeled], `[[`, character(1), "label")
    for (i in seq_along(labeled)) if (sizes[[i]]["width", 1] + 2 * gap > frame_width) {
      labels[i] <- wrap_arial_labels(labels[i], frame_width - 2 * gap, lines[[labeled[i]]]$label_size * 72 / 25.4)
      sizes[[i]] <- arial_text_extents_mm(labels[i], lines[[labeled[i]]]$label_size * 72 / 25.4)
      if (sizes[[i]]["width", 1] + 2 * gap > frame_width)
        stop("Reference label cannot fit at its Arial size; use shorter label text or increase width_mm.")
    }
    heights <- vapply(sizes, function(z) z["height", 1] + 2 * gap, numeric(1))
    reserve <- sum(heights)
    if (ph - reserve < cfg$text_min_panel_mm)
      stop("Reference labels leave insufficient panel height; shorten labels or increase height_mm.")
    grob <- gtable::gtable_add_rows(grob, grid::unit(reserve, "mm"), pos = panel$t - 1)
    row <- panel$t
    panel <- grob$layout[grob$layout$name == "panel", , drop = FALSE]
    marks <- list(); bottom <- 0
    for (i in seq_along(labeled)) {
      line <- lines[[labeled[i]]]; width <- sizes[[i]]["width", 1]; height <- sizes[[i]]["height", 1]
      anchor <- (line$value - limits[1]) / diff(limits) * pw
      center <- min(max(anchor, width / 2 + gap), frame_width - width / 2 - gap)
      yy <- bottom + gap + height / 2
      if (draw) marks <- c(marks, list(grid::textGrob(labels[i], x = grid::unit(center, "mm"),
        y = grid::unit(yy, "mm"), gp = grid::gpar(fontfamily = "Arial", fontsize = line$label_size * 72 / 25.4,
          col = line$color, lineheight = 1.12))))
      record$labels[[i]] <- list(value = line$value, original_label = line$label, displayed_label = labels[i],
        font_size_mm = line$label_size, anchor_mm = anchor,
        bounds_mm = c(xmin = center - width / 2, xmax = center + width / 2, ymin = bottom + gap, ymax = bottom + gap + height))
      bottom <- bottom + heights[i]
    }
    if (draw) grob <- gtable::gtable_add_grob(grob, do.call(grid::grobTree, marks), t = row,
      l = panel$l, r = length(grob$widths), clip = "on", name = "numeric-reference-labels-above")
    record$placement <- "above-panel"; record$frame_width_mm <- frame_width
  } else {
    widths <- vapply(sizes, function(z) z["width", 1] + 2 * gap, numeric(1))
    reserve <- sum(widths)
    if (pw - reserve < cfg$text_min_panel_mm)
      stop("Reference labels leave insufficient panel width; shorten labels or increase width_mm.")
    grob <- gtable::gtable_add_cols(grob, grid::unit(reserve, "mm"), pos = panel$r)
    marks <- list(); left <- 0
    for (i in seq_along(labeled)) {
      line <- lines[[labeled[i]]]; width <- sizes[[i]]["width", 1]; height <- sizes[[i]]["height", 1]
      if (height + 2 * gap > ph) stop("Reference label is taller than the panel; shorten it or increase height_mm.")
      anchor <- (line$value - limits[1]) / diff(limits) * ph
      center <- min(max(anchor, height / 2 + gap), ph - height / 2 - gap)
      if (draw) marks <- c(marks, list(grid::textGrob(line$label, x = grid::unit(left + gap, "mm"),
        y = grid::unit(center, "mm"), just = c("left", "centre"),
        gp = grid::gpar(fontfamily = "Arial", fontsize = line$label_size * 72 / 25.4, col = line$color, lineheight = 1.12))))
      record$labels[[i]] <- list(value = line$value, original_label = line$label, displayed_label = line$label,
        font_size_mm = line$label_size, anchor_mm = anchor,
        bounds_mm = c(xmin = left + gap, xmax = left + gap + width, ymin = center - height / 2, ymax = center + height / 2))
      left <- left + widths[i]
    }
    if (draw) grob <- gtable::gtable_add_grob(grob, do.call(grid::grobTree, marks), t = panel$t, b = panel$b,
      l = panel$r + 1, clip = "on", name = "numeric-reference-labels-right")
    record$placement <- "right-of-panel"
  }
  record$reserved_mm <- reserve; record$clearance_mm <- gap
  record$panel_mm <- c(width = pw - if (horizontal) 0 else reserve, height = ph - if (horizontal) reserve else 0)
  list(grob = grob, record = record)
}
