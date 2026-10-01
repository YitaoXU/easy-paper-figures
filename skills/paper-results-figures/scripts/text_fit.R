# Fit Method and numeric labels with actual Arial widths at final physical size.
validate_text_fit_controls <- function(cfg) {
  for (key in c("label_angle", "value_angle")) {
    angle <- cfg[[key]]
    if (!(identical(angle, "auto") || (is.numeric(angle) && length(angle) == 1 &&
        is.finite(angle) && angle >= -90 && angle <= 90)))
      stop(key, " must be auto or a finite numeric angle between -90 and 90.")
  }
  if (!cfg$label_wrap %in% c("auto", "none")) stop("label_wrap must be auto or none.")
  for (key in c("text_fit_gap_mm", "text_min_panel_mm"))
    if (!is.numeric(cfg[[key]]) || length(cfg[[key]]) != 1 ||
        !is.finite(cfg[[key]]) || cfg[[key]] <= 0) stop(key, " must be positive and finite.")
}

arial_text_extents_mm <- function(strings, size_pt, bold = FALSE) {
  vapply(as.character(strings), function(s) {
    lines <- strsplit(s, "\n", fixed = TRUE)[[1]]
    c(width = max(systemfonts::string_width(lines, family = "Arial", size = size_pt,
        weight = if (bold) "bold" else "normal", res = 72)) * 25.4 / 72,
      height = length(lines) * size_pt * 25.4 / 72 * 1.12)
  }, numeric(2))
}

# Preserve metric colors while making an explicitly designated focal method
# visible when a combined layout omits numeric mean labels.
highlight_category_grob <- function(grob, display_labels, color = "#D62728") {
  visit <- function(g) {
    if (inherits(g, "text")) {
      focal <- as.character(g$label) %in% display_labels
      if (any(focal)) {
        n <- length(g$label)
        ink <- if (is.null(g$gp$col)) rep("#222222", n) else rep(g$gp$col, length.out = n)
        face <- if (is.null(g$gp$font)) rep(1L, n) else rep(g$gp$font, length.out = n)
        ink[focal] <- color; face[focal] <- 2L
        g$gp$col <- ink; g$gp$font <- face
      }
    }
    if (length(g$grobs)) g$grobs <- lapply(g$grobs, visit)
    if (length(g$children)) g$children <- do.call(grid::gList, lapply(as.list(g$children), visit))
    g
  }
  axes <- which(grepl("^axis-b($|-)", grob$layout$name))
  for (i in axes) grob$grobs[[i]] <- visit(grob$grobs[[i]])
  grob
}

rotated_text_extents_mm <- function(extents, angle) {
  theta <- abs(angle) * pi / 180
  rbind(width = extents["width", ] * cos(theta) + extents["height", ] * sin(theta),
    height = extents["width", ] * sin(theta) + extents["height", ] * cos(theta))
}

wrap_arial_labels <- function(labels, width_mm, size_pt) {
  vapply(labels, function(label) {
    words <- strsplit(label, "[[:space:]]+")[[1]]
    lines <- character(); current <- ""
    for (word in words) {
      candidate <- if (nzchar(current)) paste(current, word) else word
      if (nzchar(current) && arial_text_extents_mm(candidate, size_pt)["width", 1] > width_mm) {
        lines <- c(lines, current); current <- word
      } else current <- candidate
    }
    paste(c(lines, current), collapse = "\n")
  }, character(1), USE.NAMES = FALSE)
}

measure_text_panel_mm <- function(plot, cfg) {
  path <- tempfile("arial-text-fit-", fileext = ".pdf")
  arial_pdf_device(path, width = cfg$width, height = cfg$height)
  on.exit({grDevices::dev.off(); unlink(path)}, add = TRUE)
  g <- ggplot2::ggplotGrob(plot)
  panels <- g$layout[grepl("^panel($|-)", g$layout$name), , drop = FALSE]
  # Null panel units have zero physical extent here; subtract only fixed units.
  c(width = (cfg$width_mm - grid::convertWidth(sum(g$widths), "mm", valueOnly = TRUE)) /
      length(unique(panels$l)),
    height = (cfg$height_mm - grid::convertHeight(sum(g$heights), "mm", valueOnly = TRUE)) /
      length(unique(panels$t)))
}

choose_readable_text_angle <- function(extents, available_width_mm, available_height_mm,
    policy, gap_mm, kind, parallel_labels = FALSE, auto_angles = c(0, 45, 90)) {
  candidates <- if (identical(policy, "auto")) auto_angles else policy
  attempts <- lapply(candidates, function(angle) {
    box <- rotated_text_extents_mm(extents, angle)
    # Parallel angled labels can have overlapping axis-aligned boxes while
    # their actual glyph rectangles remain separated perpendicular to the text.
    perpendicular_gap <- available_width_mm * abs(sin(angle * pi / 180))
    separated <- parallel_labels && angle != 0 &&
      perpendicular_gap >= max(extents["height", ]) + gap_mm - 1e-8
    list(angle = angle, fits = (max(box["width", ]) + gap_mm <= available_width_mm + 1e-8 || separated) &&
      max(box["height", ]) + gap_mm <= available_height_mm + 1e-8,
      max_width_mm = max(box["width", ]), max_height_mm = max(box["height", ]),
      perpendicular_separation_mm = if (parallel_labels && angle != 0) perpendicular_gap else NULL)
  })
  good <- which(vapply(attempts, `[[`, logical(1), "fits"))
  if (!length(good)) stop(kind, " labels do not fit at the requested readable size/angle; ",
    "increase width_mm/height_mm, use shorter display labels or allow label_wrap/automatic angles.")
  chosen <- attempts[[good[1]]]
  chosen$attempts <- attempts
  chosen
}

apply_comparison_text <- function(plot, cfg, labels, positions) {
  plot <- plot + ggplot2::scale_x_continuous(breaks = unname(positions),
    labels = unname(labels[names(positions)]), expand = ggplot2::expansion(add = cfg$category_padding))
  if (cfg$orientation == "horizontal") plot + ggplot2::theme(axis.text.y = ggplot2::element_text(
    size = cfg$category_text_size, angle = cfg$label_angle,
    hjust = if (cfg$label_angle == 0) 1 else .5, vjust = .5))
  else plot + ggplot2::theme(axis.text.x = ggplot2::element_text(
    size = cfg$category_text_size, angle = cfg$label_angle,
    hjust = if (cfg$label_angle == 0) .5 else 1,
    vjust = 1))
}

fit_comparison_text <- function(plot, cfg, labels, positions, policy, values = NULL,
    show_values = FALSE, panel_override_mm = NULL) {
  horizontal <- cfg$orientation == "horizontal"
  original <- labels
  panel <- if (is.null(panel_override_mm)) measure_text_panel_mm(plot, cfg) else panel_override_mm
  n <- length(positions)
  category_span <- diff(range(unname(positions))) + 2 * cfg$category_padding
  category_step <- if (n > 1) min(diff(sort(unique(unname(positions))))) else 1
  category_slot <- category_step / category_span
  method <- arial_text_extents_mm(labels, cfg$category_text_size)
  if (horizontal && policy$label_wrap == "auto" &&
      (panel["width"] < cfg$text_min_panel_mm || max(method["width", ]) > cfg$width_mm * .36)) {
    budget <- min(cfg$width_mm * .36,
      max(8, max(method["width", ]) + panel["width"] - cfg$text_min_panel_mm))
    labels[] <- wrap_arial_labels(labels, budget, cfg$category_text_size)
    plot <- apply_comparison_text(plot, cfg, labels, positions)
    panel <- if (is.null(panel_override_mm)) measure_text_panel_mm(plot, cfg) else
      panel + c(width = max(method["width", ]) -
        max(arial_text_extents_mm(labels, cfg$category_text_size)["width", ]), height = 0)
    method <- arial_text_extents_mm(labels, cfg$category_text_size)
  }
  if (horizontal) {
    method_width <- max(method["width", ]) + cfg$text_fit_gap_mm
    method_height <- panel["height"] * category_slot
  } else {
    method_width <- panel["width"] * category_slot
    method_height <- max(cfg$height_mm * .36, cfg$category_text_size * 25.4 / 72 * 2.4)
  }
  chosen <- tryCatch(choose_readable_text_angle(method, method_width, method_height,
    policy$label_angle, cfg$text_fit_gap_mm, "Method", parallel_labels = !horizontal,
    auto_angles = if (horizontal) c(0, 15, 30, 45, 90) else c(0, 45, 90)), error = function(e) e)
  if (inherits(chosen, "error") && !horizontal && policy$label_wrap == "auto") {
    labels[] <- wrap_arial_labels(labels, max(6, method_width - cfg$text_fit_gap_mm), cfg$category_text_size)
    method <- arial_text_extents_mm(labels, cfg$category_text_size)
    chosen <- choose_readable_text_angle(method, method_width, method_height,
      policy$label_angle, cfg$text_fit_gap_mm, "Method", parallel_labels = !horizontal)
  }
  if (inherits(chosen, "error")) stop(chosen)
  cfg$label_angle <- chosen$angle
  plot <- apply_comparison_text(plot, cfg, labels, positions)
  panel <- if (is.null(panel_override_mm)) measure_text_panel_mm(plot, cfg) else panel
  if (any(!is.finite(panel)) || min(panel) < cfg$text_min_panel_mm)
    stop("Labels/margins leave a data panel smaller than text_min_panel_mm; increase the canvas or shorten labels.")
  value <- list(angle = if (identical(policy$value_angle, "auto")) 0 else policy$value_angle,
    fits = TRUE, reason = "No numeric value labels are displayed.")
  if (show_values && length(values)) {
    numeric_extents <- arial_text_extents_mm(values, cfg$value_size * 72 / 25.4, bold = TRUE)
    value <- choose_readable_text_angle(numeric_extents,
      if (horizontal) max(numeric_extents["width", ]) + cfg$text_fit_gap_mm else panel["width"] * category_slot,
      if (horizontal) panel["height"] * category_slot else max(5.5, cfg$annotation_gap * 25.4 / 72),
      policy$value_angle, cfg$text_fit_gap_mm, "Numeric value", parallel_labels = !horizontal)
  }
  list(labels = labels, label_angle = chosen$angle, value_angle = value$angle,
    record = list(policy = policy, rendered_model_labels = as.list(labels),
      wrapped = !identical(unname(original), unname(labels)), method = chosen, values = value,
      panel_size_mm = as.list(panel), minimum_panel_mm = cfg$text_min_panel_mm,
      gap_mm = cfg$text_fit_gap_mm,
      preserves_values = TRUE, reason = "Arial text extents were compared with category spacing at final physical dimensions."))
}
