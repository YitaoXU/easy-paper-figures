# Separate annotations inside a verified empty part of the data panel when both are shown.
resolve_comparison_annotations <- function(cfg, significance_count) {
  split <- cfg$annotation_layout == "auto" && cfg$show_values && significance_count > 0
  horizontal <- cfg$orientation == "horizontal"
  glyph_height <- if(is.null(cfg$significance_size))1.8*1.12 else cfg$significance_size * 1.12
  label_offset <- glyph_height / 2 + .2
  label_outer <- label_offset + glyph_height / 2 + .2
  list(
    policy = cfg$annotation_layout,
    values_side = if (!cfg$show_values) "none" else if (horizontal) "right" else if (split) "inside-bottom" else "above",
    rank_side = if (!isTRUE(cfg$show_rank)) "none" else if (horizontal) "right" else if (split) "inside-bottom" else "above",
    significance_side = if (significance_count == 0) "none" else if (horizontal && split) "inside-left" else if (horizontal) "right" else "above",
    significance_count = significance_count,
    significance_gap_mm = cfg$significance_gap_mm,
    significance_spacing_mm = cfg$significance_spacing_mm,
    significance_cap_mm = .35,
    significance_label_offset_mm = label_offset,
    significance_label_outer_mm = label_outer,
    significance_anchor_policy = "complete displayed extent of models spanned by each bracket; nested physical separation; outside numeric/rank block when shared",
    significance_gutter_mm = if (significance_count > 0 && !(horizontal && split)) cfg$significance_gap_mm +
      (significance_count - 1) * cfg$significance_spacing_mm + label_outer else 0,
    value_gutter_mm = 0,
    category_padding = cfg$category_padding
  )
}

measure_comparison_panel_mm <- function(plot, cfg) {
  # Resolve the null panel dimension after measuring fixed Arial text/margins.
  path <- tempfile("annotation-metrics-", fileext = ".pdf")
  arial_pdf_device(path, width = cfg$width, height = cfg$height)
  on.exit({grDevices::dev.off(); unlink(path)}, add = TRUE)
  grob <- ggplot2::ggplotGrob(plot)
  width <- cfg$width_mm - grid::convertWidth(sum(grob$widths), "mm", valueOnly = TRUE)
  height <- cfg$height_mm - grid::convertHeight(sum(grob$heights), "mm", valueOnly = TRUE)
  if (any(!is.finite(c(width, height))) || min(width, height) <= 0)
    stop("Fixed labels/margins leave no data panel; increase the canvas or reduce annotation text.")
  c(width = width, height = height)
}

reserve_comparison_annotation_strip <- function(layout, cfg, core_limits, extent, panel_mm, baseline,
    value_labels = NULL) {
  layout$data_extent <- range(extent, finite = TRUE)
  layout$data_limits <- core_limits
  layout$display_limits <- core_limits
  layout$panel_size_mm <- panel_mm
  layout$reserved_strip_mm <- 0
  layout$strip_numeric_bounds <- NULL
  layout$bar_baseline <- if (cfg$style == "bar") baseline else NULL
  inside_left <- layout$significance_side == "inside-left"
  inside_bottom <- layout$values_side == "inside-bottom"
  if (!inside_left && !inside_bottom) return(layout)
  value_height <- cfg$value_size
  if (inside_bottom && length(value_labels)) {
    value_width <- max(systemfonts::string_width(value_labels, family = "Arial",
      size = cfg$value_size * 72 / 25.4, weight = "bold", res = 72)) * 25.4 / 72
    theta <- abs(cfg$value_angle) * pi / 180
    value_height <- value_width * sin(theta) + cfg$value_size * 1.12 * cos(theta)
  }
  layout$numeric_value_height_mm <- value_height
  rank_inside <- inside_bottom && identical(layout$rank_side, "inside-bottom")
  rank_height <- if (rank_inside) max(arial_text_extents_mm("Performance Ranking", cfg$rank_size * 72 / 25.4)["height", ]) else 0
  layout$rank_text_height_mm <- rank_height
  layout$rank_bundle <- if (rank_inside) list(text_center_mm=.55+rank_height/2,
    arrow_center_mm=.55+rank_height+.55,
    value_center_mm=.55+rank_height+.55+.55+value_height/2,
    minimum_strip_mm=.55+rank_height+.55+.55+value_height+.65) else NULL
  bottom_need <- if(rank_inside)layout$rank_bundle$minimum_strip_mm else value_height+1.0
  axis_mm <- panel_mm[if (inside_left) "width" else "height"]
  if (cfg$style == "bar") {
    # A bar must still start at its visible axis baseline. Put values just inside
    # that baseline rather than adding empty data space under the bar.
    layout$bar_values_inside <- inside_bottom
    layout$bar_annotation_inside <- TRUE
    layout$reserved_strip_mm <- if (inside_left) cfg$significance_gap_mm +
      (layout$significance_count - 1) * cfg$significance_spacing_mm + layout$significance_label_outer_mm else bottom_need
    return(layout)
  }
  desired <- cfg$annotation_strip_mm
  if (is.null(desired)) desired <- if (inside_left) cfg$significance_gap_mm +
    (layout$significance_count - 1) * cfg$significance_spacing_mm + layout$significance_label_outer_mm else bottom_need
  minimum <- if (inside_left) .4 + (layout$significance_count - 1) * cfg$significance_spacing_mm + layout$significance_label_outer_mm else if(rank_inside)bottom_need-.2 else value_height + .8
  if (desired < minimum) stop("annotation_strip_mm is too small for the annotation glyphs.")
  if (desired >= axis_mm * .48) stop("The internal annotation strip would consume almost half the axis; enlarge the panel or reduce annotation text/spacing.")
  floor <- layout$data_extent[1]
  upper <- core_limits[2]
  target_lower <- (floor - desired / axis_mm * upper) / (1 - desired / axis_mm)
  span_fitted <- inside_left && is.null(cfg$annotation_strip_mm) &&
    length(layout$significance_span_floors) == layout$significance_count
  if (span_fitted) {
    if (layout$significance_count > 1 && layout$significance_spacing_mm < layout$significance_label_outer_mm + .15)
      stop("Nested horizontal significance spacing would overlap a label and the adjacent connector; increase significance_spacing_mm.")
    # Each nested bracket starts at its own span's displayed lower extent.
    # Solve the outermost label bound rather than reserving the whole stack
    # below the unrelated global minimum. Preserve a small axis clearance.
    offsets <- cfg$significance_gap_mm + rev(seq_len(layout$significance_count) - 1) *
      layout$significance_spacing_mm + layout$significance_label_outer_mm
    fractions <- offsets / axis_mm
    target_lower <- min((layout$significance_span_floors - fractions * upper) / (1 - fractions))
    layout$strip_fit_policy <- "Nested span-specific displayed extents and full label bounds; small axis clearance, no forced zero."
  }
  lower <- min(core_limits[1], target_lower)
  # Prefer a stated domain boundary when it can fit the glyphs, adapting the
  # gap to the nearest mark rather than extending a bounded score below zero.
  if (!is.null(cfg$metric_domain)) {
    domain_lower <- cfg$metric_domain[1]
    available <- (floor - domain_lower) / (upper - domain_lower) * axis_mm
    if (domain_lower <= core_limits[1] && available >= minimum && upper > domain_lower && !span_fitted)
      lower <- domain_lower
  }
  strip_mm <- (floor - lower) / (upper - lower) * axis_mm
  if (inside_left && !span_fitted) {
    layout$significance_gap_mm <- min(cfg$significance_gap_mm,
      strip_mm - (layout$significance_count - 1) * cfg$significance_spacing_mm - layout$significance_label_outer_mm)
    if (layout$significance_gap_mm < .4 - 1e-8)
      stop("No safe space for significance brackets inside the numeric axis.")
  }
  layout$reserved_strip_mm <- strip_mm
  layout$display_limits <- c(lower, upper)
  layout$strip_numeric_bounds <- c(lower, floor)
  layout$bar_values_inside <- FALSE
  layout
}

add_comparison_annotations <- function(grob, summary, positions, cfg, significance, layout) {
  panel <- grob$layout[grob$layout$name == "panel", , drop = FALSE]
  category_npc <- function(x) (x - (1 - cfg$category_padding)) /
    (length(positions) - 1 + 2 * cfg$category_padding)
  # Numeric summaries sit inside the panel, above its bottom axis. No category
  # labels or ticks move, and no separate external row is added.
  if (layout$values_side == "inside-bottom") {
    value_height <- layout$numeric_value_height_mm
    if (is.null(value_height)) value_height <- cfg$value_size * 1.12
    center <- if (!is.null(layout$rank_bundle)) layout$rank_bundle$value_center_mm else if (isTRUE(layout$bar_values_inside)) value_height / 2 + .4 else
      layout$reserved_strip_mm - value_height / 2 - .5
    yy <- grid::unit(center, "mm")
    if (isTRUE(layout$bar_values_inside)) {
      baseline_npc <- (layout$bar_baseline - cfg$limits[1]) / diff(cfg$limits)
      direction <- if (mean(summary$mean) >= layout$bar_baseline) 1 else -1
      yy <- grid::unit(baseline_npc, "npc") + direction * yy
    }
    labels <- lapply(seq_len(nrow(summary)), function(i) grid::textGrob(
      summary$annotation[i], x = category_npc(summary$pos[i]), y = yy,
      rot = cfg$value_angle,
      gp = grid::gpar(fontfamily = "Arial", fontsize = cfg$value_size * 72 / 25.4,
        fontface = summary$face[i], col = summary$ink[i])))
    grob <- gtable::gtable_add_grob(grob, do.call(grid::grobTree, labels),
      t = panel$t, l = panel$l, b = panel$b, r = panel$r, clip = "on", name = "numeric-values-inside")
  }
  if (identical(layout$rank_side, "inside-bottom") && length(positions)>1) {
    ordered <- summary[match(names(positions),summary$model),];vals<-ordered$mean
    if(!(all(diff(vals)>=0)||all(diff(vals)<=0)))stop("A ranking arrow requires monotonic model order.")
    worst<-which(if(cfg$direction=="higher")vals==min(vals)else vals==max(vals))[1]
    best<-tail(which(if(cfg$direction=="higher")vals==max(vals)else vals==min(vals)),1)
    ends<-category_npc(unname(positions[c(worst,best)]));tail_right<-ends[1]>.5
    arrow_y<-grid::unit(layout$rank_bundle$arrow_center_mm,"mm")
    text_y<-grid::unit(layout$rank_bundle$text_center_mm,"mm")
    if(isTRUE(layout$bar_values_inside)){
      baseline_npc<-(layout$bar_baseline-cfg$limits[1])/diff(cfg$limits)
      direction<-if(mean(summary$mean)>=layout$bar_baseline)1 else -1
      arrow_y<-grid::unit(baseline_npc,"npc")+direction*arrow_y
      text_y<-grid::unit(baseline_npc,"npc")+direction*text_y
    }
    rank<-grid::grobTree(grid::segmentsGrob(x0=ends[1],x1=ends[2],y0=arrow_y,y1=arrow_y,
        arrow=grid::arrow(length=grid::unit(.8,"mm"),type="closed"),gp=grid::gpar(col="#222222",fill="#222222",lwd=.22*72/25.4)),
      grid::textGrob("Performance Ranking",x=grid::unit(ends[1],"npc")+grid::unit(if(tail_right)-.3 else .3,"mm"),y=text_y,
        just=c(if(tail_right)"right"else"left","centre"),gp=grid::gpar(fontfamily="Arial",fontsize=cfg$rank_size*72/25.4,col="#222222")))
    grob<-gtable::gtable_add_grob(grob,rank,t=panel$t,l=panel$l,b=panel$b,r=panel$r,clip="on",name="ranking-inside-with-values")
  }
  if (layout$significance_count == 0) return(grob)
  comparisons <- significance$comparisons
  origin <- positions[[significance$focal]]
  comparisons <- comparisons[order(abs(positions[comparisons$comparator] - origin)), , drop = FALSE]
  marks <- list()
  gp <- grid::gpar(col = "#333333", lwd = .22 * 72 / 25.4)
  numeric_offset <- max(if (cfg$show_values && layout$values_side != "inside-bottom") cfg$value_offset else 0,
    if (cfg$show_rank && layout$rank_side!="inside-bottom") cfg$rank_offset else 0)
  label_mm <- if (cfg$show_values && layout$values_side == "right") max(
    systemfonts::string_width(summary$annotation, family = "Arial",
      size = cfg$value_size * 72 / 25.4, res = 72)) * 25.4 / 72 else 0
  previous_level <- NULL
  for (j in seq_len(nrow(comparisons))) {
    ends <- category_npc(c(origin, positions[[comparisons$comparator[j]]]))
    span_models <- names(positions)[positions >= min(origin,positions[[comparisons$comparator[j]]]) &
      positions <= max(origin,positions[[comparisons$comparator[j]]])]
    local_extent <- if(is.null(layout$mark_extent_by_model))layout$data_extent else
      range(unlist(layout$mark_extent_by_model[span_models]),finite=TRUE)
    if (layout$significance_side == "inside-left") {
      # Anchor to the complete displayed lower edge on the actual final panel.
      # Physical clearance therefore stays small when axis padding changes.
      data_edge <- (local_extent[1] - cfg$limits[1]) / diff(cfg$limits)
      level <- grid::unit(data_edge, "npc") - grid::unit(layout$significance_gap_mm,"mm")
      if(!is.null(previous_level))level<-grid::unit.pmin(level,previous_level-grid::unit(cfg$significance_spacing_mm,"mm"))
      if (isTRUE(layout$bar_annotation_inside)) {
        baseline_npc <- (layout$bar_baseline - cfg$limits[1]) / diff(cfg$limits)
        direction <- if (mean(summary$mean) >= layout$bar_baseline) 1 else -1
        level <- grid::unit(baseline_npc, "npc") + direction * grid::unit(
          layout$reserved_strip_mm - layout$significance_gap_mm - (j - 1) * cfg$significance_spacing_mm, "mm")
      }
      previous_level <- level
      marks <- c(marks, list(
        grid::segmentsGrob(x0 = level, x1 = level, y0 = ends[1], y1 = ends[2], gp = gp),
        grid::segmentsGrob(x0 = level, x1 = level + grid::unit(layout$significance_cap_mm, "mm"), y0 = ends, y1 = ends, gp = gp),
        grid::textGrob("p < 0.05", x = level - grid::unit(layout$significance_label_offset_mm, "mm"), y = mean(ends), rot = 90,
          gp = grid::gpar(fontfamily = "Arial", fontsize = cfg$significance_size * 72 / 25.4, col = "#222222"))))
    } else {
      data_edge <- if(numeric_offset > 0)1 + numeric_offset else
        (local_extent[2] - cfg$limits[1]) / diff(cfg$limits)
      level <- grid::unit(data_edge, "npc") + grid::unit(
        cfg$significance_gap_mm,"mm")
      if(!is.null(previous_level))level<-grid::unit.pmax(level,previous_level+grid::unit(cfg$significance_spacing_mm,"mm"))
      previous_level <- level
      if (layout$significance_side == "above") {
        marks <- c(marks, list(
          grid::segmentsGrob(x0 = ends[1], x1 = ends[2], y0 = level, y1 = level, gp = gp),
          grid::segmentsGrob(x0 = ends, x1 = ends, y0 = level, y1 = level - grid::unit(layout$significance_cap_mm, "mm"), gp = gp),
          grid::textGrob("p < 0.05", x = mean(ends), y = level + grid::unit(layout$significance_label_offset_mm, "mm"),
            gp = grid::gpar(fontfamily = "Arial", fontsize = cfg$significance_size * 72 / 25.4, col = "#222222"))))
      } else {
        level <- level + grid::unit(label_mm, "mm")
        marks <- c(marks, list(
          grid::segmentsGrob(x0 = level, x1 = level, y0 = ends[1], y1 = ends[2], gp = gp),
          grid::segmentsGrob(x0 = level, x1 = level - grid::unit(layout$significance_cap_mm, "mm"), y0 = ends, y1 = ends, gp = gp),
          grid::textGrob("p < 0.05", x = level + grid::unit(layout$significance_label_offset_mm, "mm"), y = mean(ends), rot = 90,
            gp = grid::gpar(fontfamily = "Arial", fontsize = cfg$significance_size * 72 / 25.4, col = "#222222"))))
      }
    }
  }
  grob <- gtable::gtable_add_grob(grob, do.call(grid::grobTree, marks),
    t = panel$t, l = panel$l, b = panel$b, r = panel$r,
    clip = if (layout$significance_side == "inside-left") "on" else "off",
    name = if (layout$significance_side == "inside-left") "focal-significance-inside" else "focal-significance")
  grob
}

# Descriptive correlation across matching method means, before affine display mapping.
compute_method_mean_correlation <- function(summary, metrics, models) {
  x <- summary[summary$metric == metrics[1], ]
  y <- summary[summary$metric == metrics[2], ]
  xx <- x$mean[match(models, x$model)]; yy <- y$mean[match(models, y$model)]
  if (any(!is.finite(c(xx, yy)))) stop("Mean correlation requires finite matching method means.")
  reason <- if (length(models) < 2) "Fewer than two methods." else if (sd(xx) == 0 || sd(yy) == 0) "At least one metric has constant method means." else NULL
  estimate <- if (is.null(reason)) unname(stats::cor(xx, yy, method="pearson")) else NA_real_
  list(method="Pearson correlation", estimate=estimate, n=length(models),
    sampling_unit="displayed method mean", metrics=metrics,
    matched_values=data.frame(model=models, first_mean=xx, second_mean=yy),
    defined=is.null(reason), undefined_reason=reason,
    inference="Descriptive association across method means; no observation-level inference or p-value is implied.",
    computed_before_display_transform=TRUE)
}

# Measure final transformed marks and find safe space for the compact statistic.
# Keep a separate external row when the full text cannot fit inside the panel.
add_method_mean_correlation <- function(grob, plot, cfg, statistic) {
  panel <- grob$layout[grob$layout$name == "panel", , drop=FALSE]
  pw <- cfg$width_mm-grid::convertWidth(sum(grob$widths),"mm",valueOnly=TRUE)
  ph <- cfg$height_mm-grid::convertHeight(sum(grob$heights),"mm",valueOnly=TRUE)
  label <- paste0("Mean Pearson r\n", if(statistic$defined)sprintf("%.3f",statistic$estimate)else"undefined", " (n = ",statistic$n,")")
  text <- grid::textGrob(label,gp=grid::gpar(fontfamily="Arial",fontsize=cfg$axis_text_size,col="#222222",lineheight=1.05))
  tw <- grid::convertWidth(grid::grobWidth(text),"mm",valueOnly=TRUE)
  th <- grid::convertHeight(grid::grobHeight(text),"mm",valueOnly=TRUE)
  built <- ggplot2::ggplot_build(plot); boxes <- list(); unknown <- character()
  add <- function(x0,x1,y0,y1,pad) {
    z<-c(min(x0,x1)*pw-pad,max(x0,x1)*pw+pad,min(y0,y1)*ph-pad,max(y0,y1)*ph+pad)
    if(all(is.finite(z)))boxes[[length(boxes)+1L]]<<-z
  }
  for(i in seq_along(built$data)) {
    d<-built$plot$coordinates$transform(built$data[[i]],built$layout$panel_params[[1]])
    geom<-class(built$plot$layers[[i]]$geom)[1]
    if(!nrow(d)||geom=="GeomBlank")next
    if(geom=="GeomPoint")for(j in seq_len(nrow(d)))add(d$x[j],d$x[j],d$y[j],d$y[j],d$size[j]*.65+d$stroke[j]/2)
    else if(geom %in% c("GeomRect","GeomErrorbar"))for(j in seq_len(nrow(d)))add(d$xmin[j],d$xmax[j],d$ymin[j],d$ymax[j],d$linewidth[j]/2)
    else if(geom %in% c("GeomLine","GeomPath"))for(ids in split(seq_len(nrow(d)),d$group)) {
      if(length(ids)>1)for(j in seq_len(length(ids)-1))add(d$x[ids[j]],d$x[ids[j+1]],d$y[ids[j]],d$y[ids[j+1]],max(d$linewidth[ids])/2)
    } else if(geom=="GeomHline")for(j in seq_len(nrow(d)))add(0,1,d$yintercept[j],d$yintercept[j],d$linewidth[j]/2)
    else unknown<-c(unknown,geom)
  }
  obs<-if(length(boxes))do.call(rbind,boxes)else matrix(numeric(),ncol=4)
  gap<-.65; best<-NULL
  if(!length(unknown) && tw+2*gap<pw && th+2*gap<ph) {
    for(y in seq(gap,ph-th-gap,length.out=25))for(x in seq(gap,pw-tw-gap,length.out=25)) {
      if(nrow(obs)&&any(x-gap<obs[,2]&x+tw+gap>obs[,1]&y-gap<obs[,4]&y+th+gap>obs[,3]))next
      dx<-pmax(obs[,1]-(x+tw),x-obs[,2],0);dy<-pmax(obs[,3]-(y+th),y-obs[,4],0)
      clearance<-min(c(x,pw-x-tw,y,ph-y-th,if(nrow(obs))sqrt(dx^2+dy^2)else Inf))
      if(is.null(best)||clearance>best$clearance)best<-list(x=x,y=y,clearance=clearance)
    }
  }
  rec<-list(label=label,font_size_pt=cfg$axis_text_size,text_mm=c(width=tw,height=th),panel_mm=c(width=pw,height=ph),clearance_mm=gap,
    occupied_mark_count=nrow(obs),occupancy_boxes_mm=obs)
  if(!is.null(best)) {
    text$x<-grid::unit((best$x+tw/2)/pw,"npc");text$y<-grid::unit((best$y+th/2)/ph,"npc")
    grob<-gtable::gtable_add_grob(grob,text,t=panel$t,b=panel$b,l=panel$l,r=panel$r,clip="on",name="method-mean-correlation")
    rec$placement<-"inside";rec$bounds_mm<-c(xmin=best$x,xmax=best$x+tw,ymin=best$y,ymax=best$y+th);rec$minimum_clearance_mm<-best$clearance
  } else {
    # The additional fixed row shrinks only the data panel within the requested canvas.
    if(ph-th-1<cfg$text_min_panel_mm)stop("Mean correlation has no safe readable space; increase height_mm or omit show_mean_correlation.")
    grob<-gtable::gtable_add_rows(grob,grid::unit(th+1,"mm"),pos=panel$t-1)
    grob<-gtable::gtable_add_grob(grob,text,t=panel$t,l=panel$l,r=panel$r,clip="off",name="method-mean-correlation-external")
    rec$placement<-"above-panel";rec$reason<-"No complete text rectangle fits clear of all marks; added a measured statistic row within the original canvas."
  }
  list(grob=grob,record=rec)
}
