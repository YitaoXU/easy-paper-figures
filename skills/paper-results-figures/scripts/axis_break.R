# Explicit empty-interval compression for raw box plots; scientific values stay unchanged.
validate_box_axis_break <- function(interval, dat, sm, show_sd) {
  if (!is.numeric(interval) || length(interval) != 2 || any(!is.finite(interval)) || diff(interval) <= 0)
    stop("axis_break must contain two increasing finite endpoints of an open interval.")
  a <- interval[1]; b <- interval[2]
  overlaps <- function(lo, hi) any(lo < b & hi > a, na.rm = TRUE)
  if (any(dat$value > a & dat$value < b)) stop("axis_break contains observations.")
  chunks <- split(dat$value, interaction(dat$model, dat$metric, drop = TRUE))
  for (v in chunks) {
    q <- quantile(v, c(.25, .5, .75), names = FALSE)
    iq <- q[3] - q[1]; wh <- range(v[v >= q[1] - 1.5 * iq & v <= q[3] + 1.5 * iq])
    if (overlaps(wh[1], wh[2])) stop("axis_break intersects a box or whisker interval.")
  }
  if (any(show_sd) && overlaps(sm$mean[show_sd] - sm$sd[show_sd], sm$mean[show_sd] + sm$sd[show_sd]))
    stop("axis_break intersects displayed mean +/- SD uncertainty.")
  invisible(TRUE)
}

box_break_transform <- function(interval, limits, gap_fraction = .05) {
  if (interval[1] <= limits[1] || interval[2] >= limits[2])
    stop("axis_break must lie strictly inside the numeric display limits.")
  a <- interval[1]; b <- interval[2]
  gap <- (diff(limits) - diff(interval)) * gap_fraction
  compression <- gap / (b - a)
  forward <- function(x) ifelse(x <= a, x, ifelse(x >= b, x - (b - a) + gap, a + (x - a) * compression))
  inverse <- function(x) ifelse(x <= a, x, ifelse(x >= a + gap, x + (b - a) - gap, a + (x - a) / compression))
  list(transform = scales::new_transform("explicit-empty-box-interval", forward, inverse),
    forward = forward, inverse = inverse, display_gap = gap, original_interval = interval,
    note = sprintf("Broken numeric axis: open interval (%.6g, %.6g) omitted; values and statistics are unchanged.", a, b))
}

apply_box_axis_break <- function(p, cfg, dat, sm, shown_sd, numeric_limits, category_limits, explicit_ticks=FALSE) {
  validate_box_axis_break(cfg$axis_break, dat, sm, shown_sd)
  tx <- box_break_transform(cfg$axis_break, numeric_limits)
  ticks <- if (is.null(cfg$breaks)) choose_axis_breaks(numeric_limits,
    if (cfg$orientation == "horizontal") cfg$width_mm - 25 else cfg$height_mm - 24,
    cfg$axis_text_size, cfg$orientation == "horizontal") else cfg$breaks
  ticks <- ticks[ticks <= cfg$axis_break[1] | ticks >= cfg$axis_break[2]]
  # Ensure each retained segment has informative ticks even for a very wide gap.
  if (!explicit_ticks && sum(ticks <= cfg$axis_break[1]) < 2) ticks <- c(ticks, pretty(c(numeric_limits[1], cfg$axis_break[1]), n = 3))
  if (!explicit_ticks && sum(ticks >= cfg$axis_break[2]) < 2) ticks <- c(ticks, pretty(c(cfg$axis_break[2], numeric_limits[2]), n = 3))
  ticks <- sort(unique(ticks[ticks >= numeric_limits[1] & ticks <= numeric_limits[2] &
    (ticks <= cfg$axis_break[1] | ticks >= cfg$axis_break[2])]))
  original_ticks <- ticks
  if(cfg$orientation=="horizontal"){
    label_width<-max(arial_text_extents_mm(format_axis_ticks(ticks),cfg$axis_text_size)["width",])
    cfg$right_margin<-max(cfg$right_margin,(label_width/2+.5)*72/25.4)
    p<-p+theme(plot.margin=margin(cfg$outer_margin,cfg$right_margin,cfg$outer_margin,cfg$outer_margin))
  } else {
    # A numeric tick centered on the upper domain endpoint extends beyond the
    # panel. Reserve its measured half-height and a readable canvas gutter.
    label_height<-max(arial_text_extents_mm(format_axis_ticks(ticks),cfg$axis_text_size)["height",])
    top_margin_pt<-max(cfg$outer_margin,(label_height/2+.7)*72/25.4)
    p<-p+theme(plot.margin=margin(top_margin_pt,cfg$right_margin,cfg$outer_margin,cfg$outer_margin))
  }
  axis_label_function <- function(x) {
    out <- rep(NA_character_,length(x));ok <- is.finite(x);out[ok] <- format_axis_ticks(x[ok]);out
  }
  candidate <- p + scale_y_continuous(transform=tx$transform,breaks=ticks,
    labels=axis_label_function,expand=expansion(mult=0))
  candidate <- candidate + labs(caption=box_break_caption(candidate,cfg,tx$note))
  panel <- measure_comparison_panel_mm(candidate,cfg)
  horizontal <- cfg$orientation=="horizontal"
  axis_length <- unname(panel[if(horizontal)"width"else"height"])
  span <- diff(tx$forward(numeric_limits)); gap_mm <- .7
  extents <- arial_text_extents_mm(axis_label_function(ticks),cfg$axis_text_size)
  glyph_extent <- unname(extents[if(horizontal)"width"else"height",])
  positions_mm <- (tx$forward(ticks)-tx$forward(numeric_limits)[1])/span*axis_length
  priorities <- ifelse(ticks %in% cfg$axis_break,3,1)
  repeat {
    if(length(ticks)<2)break
    clearance <- diff(positions_mm)-(head(glyph_extent,-1)+tail(glyph_extent,-1))/2
    collision <- which(clearance<gap_mm-1e-8)
    if(!length(collision))break
    if(explicit_ticks)stop("Explicit broken-axis tick labels overlap at the requested dimensions; coarsen breaks or increase the canvas.")
    i<-collision[which.min(clearance[collision])]
    drop<-if(priorities[i]<priorities[i+1])i else i+1
    ticks<-ticks[-drop];glyph_extent<-glyph_extent[-drop];positions_mm<-positions_mm[-drop];priorities<-priorities[-drop]
  }
  if(!any(ticks<=cfg$axis_break[1]) || !any(ticks>=cfg$axis_break[2]))
    stop("Broken-axis segments need readable labeled ticks on both sides; increase the canvas.")
  p <- p + scale_y_continuous(transform=tx$transform,breaks=ticks,
    labels=axis_label_function,expand=expansion(mult=0))
  tick_fit <- list(axis_length_mm=axis_length,orientation=cfg$orientation,minimum_gap_mm=gap_mm,
    original_candidates=original_ticks,resolved_ticks=ticks,positions_mm=positions_mm,
    glyph_extent_mm=glyph_extent,adjacent_clearance_mm=if(length(ticks)>1)diff(positions_mm)-(head(glyph_extent,-1)+tail(glyph_extent,-1))/2 else numeric(),
    measurement="Actual Arial label extents on the compressed numeric axis at final panel size")
  # Double slashes cross the numeric axis at the center of the omitted segment.
  y0 <- tx$forward(cfg$axis_break[1]) + tx$display_gap / 2
  slash_h <- span * .013; slash_dx <- diff(category_limits) * .012
  for (shift in c(-.008, .008) * span) {
    p <- p + annotate("segment", x = category_limits[1] - slash_dx,
      xend = category_limits[1] + slash_dx,
      y = tx$inverse(y0 + shift - slash_h / 2),
      yend = tx$inverse(y0 + shift + slash_h / 2), linewidth = .3, color = "#222222")
  }
  cfg$breaks <- ticks
  list(plot = p, breaks = ticks, right_margin = cfg$right_margin, record = list(interval = cfg$axis_break,
    endpoint_gutter_mm = if(cfg$orientation=="horizontal")cfg$right_margin*25.4/72 else top_margin_pt*25.4/72,
    endpoint_policy = "Open interval; endpoints remain visible.", display_gap_fraction = .05,
    display_gap = tx$display_gap, tick_fitting = tick_fit, validation = "No observations, box/whisker intervals or displayed SD intersect the open interval.",
    values_and_statistics = "Original uncompressed values", disclosure = tx$note), note = tx$note)
}

# Wrap mandatory disclosure using actual Arial at the final caption size.
box_break_caption <- function(p, cfg, note) {
  panel <- measure_comparison_panel_mm(p, cfg)
  width <- max(1, unname(panel["width"]) - 1)
  parts <- c(cfg$caption, note)
  lines <- character()
  for (part in parts) for (paragraph in strsplit(part, "\n", fixed=TRUE)[[1]]) {
    current <- ""
    for (word in strsplit(paragraph, " +")[[1]]) {
      candidate <- if(nzchar(current))paste(current, word)else word
      if(arial_text_extents_mm(word,5)["width",1]>width)stop("Caption contains a token wider than the available panel; increase width_mm or use readable shorter caption text.")
      measured <- arial_text_extents_mm(candidate, 5)["width",1]
      if(nzchar(current) && measured > width) {lines <- c(lines,current);current <- word} else current <- candidate
    }
    lines <- c(lines,current)
  }
  paste(lines,collapse="\n")
}
