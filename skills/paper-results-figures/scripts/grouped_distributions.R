# Consecutive metric clusters on an established comparable scale, colored by model.
if (cfg$delta) stop("grouped-distributions does not support paired deltas.")
if (cfg$combo_color_by != "model") stop("grouped-distributions requires model colors.")
if (cfg$show_rank || cfg$show_values) stop("grouped-distributions uses a model legend; show_rank and show_values must be false.")
if (!is.null(cfg$combo_limits) || !is.null(cfg$combo_breaks)) stop("Use common limits/breaks for grouped-distributions.")
if (cfg$combo_value_placement != "outside" || cfg$combo_sd_display == "outward")
  stop("grouped-distributions uses full symmetric SD and no inside values.")
if (length(unique(cfg$combo_styles)) != 1 || !cfg$combo_styles[1] %in% c("bar", "box", "violin"))
  stop("grouped-distributions requires one uniform bar, box or violin style.")
for (key in cfg$metrics) {
  if (is.null(cfg$combo_units[[key]]) || length(cfg$combo_units[[key]]) != 1 ||
      !is.character(cfg$combo_units[[key]]) || !nzchar(trimws(cfg$combo_units[[key]])))
    stop("combo_units must map every selected metric to a nonempty unit description.")
  dom <- cfg$combo_domains[[key]]
  if (!is.numeric(dom) || length(dom) != 2 || any(!is.finite(dom)) || diff(dom) <= 0)
    stop("combo_domains must map every selected metric to established increasing scientific bounds.")
}
if (!setequal(names(cfg$combo_units), cfg$metrics) || !setequal(names(cfg$combo_domains), cfg$metrics))
  stop("Comparable units and domains must cover exactly the selected metrics.")
if (length(unique(unlist(cfg$combo_units[cfg$metrics]))) != 1 ||
    !all(vapply(cfg$combo_domains[cfg$metrics], function(x) identical(as.numeric(x), as.numeric(cfg$combo_domains[[cfg$metrics[1]]])), logical(1))))
  stop("grouped-distributions requires identical established units and domains; use separate axes for unlike metrics.")
common_domain <- cfg$combo_domains[[cfg$metrics[1]]]
if (any(dat$value < common_domain[1] | dat$value > common_domain[2]))
  stop("Values lie outside the declared common scientific domain.")
style_i <- cfg$combo_styles[1]
if (style_i %in% c("box", "violin") && cfg$data_mode != "raw") stop("Distributions require raw observations.")
if (style_i == "violin" && any(sm$n < 2)) stop("Violin density requires at least two observations per group.")
# Dense metric clusters communicate distributions through quartiles/medians.
# Keep additional mean diamonds and SD absent unless requested explicitly;
# summary statistics are still calculated and exported without rounding.
if (style_i %in% c("box", "violin") && is.null(user$show_sd)) {
  cfg$show_sd <- FALSE
  metric_sd[] <- FALSE
  if (!is.null(user$combo_show_sd)) for (key in names(user$combo_show_sd))
    metric_sd[[key]] <- user$combo_show_sd[[key]]
  cfg$combo_show_sd <- as.list(metric_sd)
}
# Metric and model orders persist; gaps delineate consecutive metric clusters.
n_models <- length(models); stride <- n_models + 1
metric_centers <- setNames((seq_along(cfg$metrics) - 1) * stride + (n_models + 1) / 2, cfg$metrics)
group_pos <- function(metric, model) (match(metric, cfg$metrics) - 1) * stride + match(model, models)
sm$pos <- group_pos(sm$metric, sm$model); dat$pos <- group_pos(dat$metric, dat$model)
if (cfg$orientation == "horizontal") {
  total <- max(sm$pos) + 1; sm$pos <- total - sm$pos; dat$pos <- total - dat$pos
  metric_centers <- total - metric_centers
}
p <- base()
if (style_i != "bar") p$scales$scales <- Filter(function(s) !"fill" %in% s$aesthetics, p$scales$scales)
for (key in cfg$metrics) p <- add_marks(p, sm[sm$metric == key, ], dat[dat$metric == key, ],
  style_i, 0, metric_sd[[key]])
extent <- sm$mean
if (any(metric_sd)) {
  shown <- unname(metric_sd[sm$metric]); extent <- c(extent, sm$mean[shown] - sm$sd[shown], sm$mean[shown] + sm$sd[shown])
}
if (style_i %in% c("box", "violin") || cfg$show_points) extent <- c(extent, dat$value)
if (style_i == "bar") extent <- c(extent, 0)
# Grouped bars retain zero as their baseline; unlike free-axis panels no hidden
# per-metric truncated baselines are meaningful on this common numeric axis.
axis_cfg <- cfg; if (style_i == "bar") axis_cfg$axis_policy <- "zero"
ax <- resolve_multi_axis(extent, axis_cfg, cfg$limits, cfg$breaks,
  if (cfg$orientation == "horizontal") cfg$width_mm - 25 else cfg$height_mm - 24,
  cfg$orientation == "horizontal", style_i)
cfg$limits <- ax$limits; cfg$breaks <- ax$breaks
# Reserve full-canvas endpoint glyph room before fitting metric names and guides.
# This changes drawing space only; the common scale and observations stay intact.
if(is.null(user$outer_margin)) {
  endpoint_half_mm<-max(systemfonts::string_width(axis_labels(range(cfg$breaks)),
    family="Arial",size=cfg$axis_text_size,res=72))*25.4/72/2
  cfg$outer_margin<-max(cfg$outer_margin,(endpoint_half_mm+.7)*72/25.4)
}
p<-p+theme(plot.margin=margin(cfg$outer_margin,cfg$outer_margin,cfg$outer_margin,cfg$outer_margin))
cat_limits <- range(sm$pos) + c(-cfg$category_padding, cfg$category_padding)
metric_labels <- setNames(metric_lab(cfg$metrics), cfg$metrics)
p <- p + scale_x_continuous(breaks = unname(metric_centers), labels = unname(metric_labels[names(metric_centers)]), expand = expansion(mult = 0)) +
  scale_y_continuous(breaks = cfg$breaks, labels = axis_labels, expand = expansion(mult = 0))
if (cfg$orientation == "horizontal") {p <- p + coord_flip(xlim = cat_limits, ylim = cfg$limits, expand = FALSE, clip = "off")} else {p <- p + coord_cartesian(xlim = cat_limits, ylim = cfg$limits, expand = FALSE, clip = "off")}
fitted <- fit_comparison_text(p, cfg, metric_labels, metric_centers, text_fit_policy, NULL, FALSE)
cfg$label_angle <- fitted$label_angle; cfg$value_angle <- fitted$value_angle; text_fitting <- fitted$record
p <- apply_comparison_text(p, cfg, fitted$labels, metric_centers)
legend_keys <- data.frame(model = models, .x = NA_real_, .y = NA_real_)
p <- p + geom_rect(data = legend_keys, aes(xmin = .x, xmax = .x, ymin = .y, ymax = .y, fill = model),
  color = edge, alpha = cfg$fill_alpha, show.legend = TRUE, na.rm = TRUE) +
  scale_fill_manual(values = cols, breaks = models, labels = unname(labels[models]), name = NULL) +
  theme(legend.position = "top", legend.location = "plot", legend.text = element_text(size = cfg$axis_text_size, family = "Arial"),
    legend.background = element_rect(fill="white",color=NA),
    legend.key.size = grid::unit(2, "mm"), legend.spacing.x = grid::unit(.6, "mm"),
    legend.margin = margin(1, 1, 1, 1), legend.box.spacing = grid::unit(.6, "mm"),
    axis.text = element_text(size = cfg$axis_text_size, family = "Arial"),
    axis.text.x = element_text(size = if(cfg$orientation=="vertical")cfg$category_text_size else cfg$axis_text_size),
    axis.text.y = element_text(size = if(cfg$orientation=="horizontal")cfg$category_text_size else cfg$axis_text_size))
# Measure the actual complete guide, including key/text spacing and frame,
# rather than estimating rows from the sum of label widths.
legend_path <- tempfile("grouped-legend-fit-",fileext=".pdf")
arial_pdf_device(legend_path,width=cfg$width,height=cfg$height)
legend_fit <- tryCatch({
 # A full-figure external guide can extend over the numeric-axis label gutter.
 # Reserve measured half-glyph height plus breathing room above vertical ticks.
 endpoint_guide_gap <- .6
 if(cfg$orientation=="vertical") {
  glyph_height <- max(arial_text_extents_mm(axis_labels(cfg$breaks),cfg$axis_text_size)["height",])
  endpoint_guide_gap <- max(endpoint_guide_gap,glyph_height/2+cfg$legend_clearance_mm+.2)
 }
 p <- p+theme(legend.box.spacing=grid::unit(endpoint_guide_gap,"mm"))
 available <- cfg$width_mm - 2*cfg$outer_margin*25.4/72 - 1
 chosen <- NULL; attempts <- list()
 for (nc in rev(seq_len(n_models))) {
  candidate <- p + guides(fill=guide_legend(ncol=nc,byrow=TRUE,
   override.aes=list(alpha=cfg$fill_alpha,color=edge)))
  gg <- ggplotGrob(candidate)
  gi <- which(gg$layout$name=="guide-box-top")
  guide <- gg$grobs[[gi]]
  width <- grid::convertWidth(grid::grobWidth(guide),"mm",valueOnly=TRUE)
  height <- grid::convertHeight(grid::grobHeight(guide),"mm",valueOnly=TRUE)
  attempts[[length(attempts)+1]] <- list(columns=nc,width_mm=width,height_mm=height)
  if(width<=available && height<=cfg$height_mm-25){chosen<-list(plot=candidate,columns=nc,width_mm=width,height_mm=height);break}
 }
 if(is.null(chosen))stop("Model legend cannot fit at the readable size; increase width_mm/height_mm or provide shorter model_labels.")
 chosen$anchor<-"full-figure";chosen$available_width_mm<-available;chosen$attempts<-attempts
 chosen$endpoint_guide_gap_mm<-endpoint_guide_gap;chosen
},finally={grDevices::dev.off();unlink(legend_path)})
p<-legend_fit$plot;legend_fit$plot<-NULL
legend_rows <- ceiling(n_models/legend_fit$columns)
if(!is.null(cfg$caption))p<-p+labs(caption=box_break_caption(p,cfg,NULL))
combo_axes <- setNames(rep(list(ax), length(cfg$metrics)), cfg$metrics)
metric_encoding <- list(color_by = "model", colors = cfg$color_values, metric_order = cfg$metrics,
  common_units = cfg$combo_units[[cfg$metrics[1]]], common_domain = common_domain,
  summary_overlay = list(default = "No mean diamond or SD for grouped box/violin distributions; explicit SD requests are retained.",
    mean_and_sd_shown_by_metric = as.list(metric_sd), computed_summaries = "Full-precision mean and SD remain in scientific records."),
  baseline = if (style_i == "bar") 0 else NULL, cluster_stride = stride, legend_rows = legend_rows, legend_fitting = legend_fit,
  endpoint_canvas_margin_mm = cfg$outer_margin*25.4/72)
axis_note <- ax$note
if (!is.null(cfg$axis_break)) {
  br <- apply_box_axis_break(p, cfg, dat, sm, unname(metric_sd[sm$metric]), cfg$limits, cat_limits, explicit_ticks=!is.null(user$breaks))
  p <- br$plot; cfg$breaks <- br$breaks; cfg$right_margin <- br$right_margin; axis_break_record <- br$record; axis_note <- br$note
  p <- p + labs(caption = box_break_caption(p, cfg, br$note))
}
