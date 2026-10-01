# Compact categorical facets retain the complete requested manuscript canvas.
# Data and metric units stay unchanged; only measured drawing geometry adapts.
trend_categorical_final_grob <- function(p,cfg,series,labels,colors,shapes,fits) {
  g<-ggplot2::ggplotGrob(p)
  if(cfg$orientation=="vertical" && length(cfg$metric_order)>1L) {
    axes<-which(grepl("^axis-l",g$layout$name));first<-min(g$layout$l[axes])
    internal<-axes[g$layout$l[axes]>first]
    for(i in internal)g$grobs[[i]]<-grid::segmentsGrob(x0=1,x1=1,y0=0,y1=1,
      gp=grid::gpar(col="#333333",lwd=.25*72/25.4))
    for(i in unique(g$layout$l[internal]))g$widths[i]<-grid::unit(0,"mm")
  }
  guide<-trend_guide_grob(cfg,series,labels,colors,shapes,fits)
  first_row<-min(g$layout$t[grepl("^panel|^strip-t",g$layout$name)])
  g<-gtable::gtable_add_rows(g,grid::unit(guide$height_mm+.3,"mm"),pos=first_row-1L)
  g<-gtable::gtable_add_grob(g,guide$grob,t=first_row,l=1,r=length(g$widths),clip="off",name="trend-categorical-guide")
  list(grob=g,guide=guide$record)
}

# Resolve null units only after removing repeated axes and adding the real guide.
trend_categorical_panel_mm <- function(p,cfg,series,labels,colors,shapes,fits) {
  path<-tempfile("trend-panel-measure-",fileext=".pdf")
  arial_pdf_device(path,width=cfg$width_mm/25.4,height=cfg$height_mm/25.4)
  on.exit({grDevices::dev.off();unlink(path)},add=TRUE)
  g<-trend_categorical_final_grob(p,cfg,series,labels,colors,shapes,fits)$grob
  resolve<-function(units,total,horizontal) {
    is_null<-vapply(seq_along(units),function(i)grid::unitType(units[i])=="null",logical(1))
    fixed<-if(horizontal)grid::convertWidth(units,"mm",valueOnly=TRUE)else grid::convertHeight(units,"mm",valueOnly=TRUE)
    weights<-vapply(seq_along(units),function(i)if(is_null[i])as.numeric(units[i])else 0,numeric(1))
    remaining<-total-sum(fixed)
    if(remaining<=0||sum(weights)<=0)stop("Axis furniture leaves no categorical panel: increase dimensions or use authorized shorter labels.")
    fixed+remaining*weights/sum(weights)
  }
  widths<-resolve(g$widths,cfg$width_mm,TRUE);heights<-resolve(g$heights,cfg$height_mm,FALSE)
  panels<-g$layout[grepl("^panel($|-)",g$layout$name),,drop=FALSE]
  data.frame(panel=panels$name,width_mm=vapply(seq_len(nrow(panels)),function(i)sum(widths[panels$l[i]:panels$r[i]]),numeric(1)),
    height_mm=vapply(seq_len(nrow(panels)),function(i)sum(heights[panels$t[i]:panels$b[i]]),numeric(1)))
}

# Short numeric axes may need a readable subset of a regular major-tick grid.
# Keep compact round numbers rather than arbitrary high-precision data endpoints.
trend_compact_axis_breaks <- function(limits,mm,font_pt,horizontal) {
  candidates<-list()
  for(n in 8:1) {
    ticks<-snap_axis_breaks(signif(pretty(limits,n=n),12),limits)
    if(length(ticks)<2)next
    for(stride in seq_len(length(ticks)-1L))for(offset in seq_len(stride)) {
      selected<-ticks[seq(offset,length(ticks),by=stride)]
      if(length(selected)<2)next
      glyphs<-if(horizontal)arial_text_extents_mm(format_axis_ticks(selected),font_pt)["width",]else rep(font_pt*25.4/72,length(selected))
      gaps<-diff(selected)/diff(limits)*mm
      required<-(head(glyphs,-1)+tail(glyphs,-1))/2+if(horizontal)1.5 else 1.2
      positions<-(selected-limits[1])/diff(limits)*mm
      inside<-all(positions>=-1e-8 & positions<=mm+1e-8)
      # Endpoint glyph halves occupy the measured exterior/inter-panel gutters.
      if(all(gaps>=required)&&inside)candidates[[length(candidates)+1L]]<-selected
    }
  }
  if(!length(candidates))stop("Numeric ticks cannot fit at readable Arial size: increase the categorical canvas dimensions.")
  coverage<-vapply(candidates,function(x)diff(range(x))/diff(limits),numeric(1))
  counts<-vapply(candidates,length,integer(1))
  candidates[[order(-coverage,-counts)[1]]]
}

trend_compact_categorical <- function(p,cfg,dat,metrics,categories,display_labels,axis_labels,series,labels,colors,shapes,fits) {
  horizontal_numeric<-cfg$orientation=="vertical"
  p<-p+ggplot2::theme(legend.position="none",plot.margin=ggplot2::margin(1.5,3,1.5,1.5),
    axis.title=ggplot2::element_text(margin=ggplot2::margin(1,1,1,1)),
    axis.text=ggplot2::element_text(margin=ggplot2::margin(1,1,1,1)),
    strip.text=ggplot2::element_text(margin=ggplot2::margin(.4,.4,.4,.4)),
    panel.spacing=grid::unit(if(horizontal_numeric)1.5 else .9,"mm"))
  if(horizontal_numeric) {
    endpoint_width<-max(arial_text_extents_mm(format_axis_ticks(if(is.null(cfg$y_limits))range(dat$y)else cfg$y_limits),cfg$axis_text_size)["width",])
    p<-p+ggplot2::theme(panel.spacing=grid::unit(max(1.5,endpoint_width+.8),"mm"),
      plot.margin=ggplot2::margin(1.5,max(3,endpoint_width/2+.8)*72/25.4,1.5,1.5))
  }
  if(!horizontal_numeric)p<-p+ggplot2::theme(panel.spacing=grid::unit(max(.9,cfg$axis_text_size*25.4/72*1.12+.8),"mm"))
  category_display<-display_labels(categories,cfg$category_labels)
  metric_display<-display_labels(metrics,cfg$metric_labels)
  angle<-if(identical(cfg$label_angle,"auto"))0 else cfg$label_angle
  attempts<-NULL;previous<-NULL;axis_mm<-if(horizontal_numeric)cfg$width_mm/length(metrics)else cfg$height_mm/length(metrics)
  apply_numeric<-function(plot,mm) {
    # Each scale receives its own actual data range; free facets keep native units.
    limits<-local({length_mm<-mm;function(v)trend_numeric_axis(v,cfg$y_limits,cfg$y_breaks,length_mm,cfg$axis_text_size,horizontal_numeric)$limits})
    breaks<-if(is.null(cfg$y_breaks))local({length_mm<-mm;function(v)trend_compact_axis_breaks(v,length_mm,cfg$axis_text_size,horizontal_numeric)})else cfg$y_breaks
    plot+ggplot2::scale_y_continuous(name=if(is.null(cfg$y_label))"Value"else cfg$y_label,
      limits=limits,breaks=breaks,labels=axis_labels,expand=ggplot2::expansion(mult=0))
  }
  for(iteration in 1:8) {
    p<-suppressMessages(apply_numeric(p,axis_mm))
    panels<-trend_categorical_panel_mm(p,cfg,series,labels,colors,shapes,fits)
    width<-min(panels$width_mm);height<-min(panels$height_mm)
    if(min(width,height)<5)stop("Categorical facets leave less than 5 mm per panel: increase dimensions or authorize shorter labels.")
    # Facet strips share the numeric panel width, not the full export width.
    wrapped_metrics<-wrap_arial_labels(metric_display,max(width-.4,2),cfg$base_size)
    if(length(metrics)>1)p$facet$params$labeller<-ggplot2::as_labeller(setNames(wrapped_metrics,metrics))
    if(horizontal_numeric) {
      if(cfg$label_wrap=="auto")category_display<-wrap_arial_labels(display_labels(categories,cfg$category_labels),min(12,cfg$width_mm*.22),cfg$axis_text_size)
      p<-suppressMessages(p+ggplot2::scale_x_discrete(name=if(is.null(cfg$x_label))cfg$x else cfg$x_label,limits=rev(categories),labels=rev(category_display),drop=FALSE,expand=ggplot2::expansion(add=.35)))
      p<-p+ggplot2::theme(axis.text.y=ggplot2::element_text(angle=angle))
    }else {
      spacing<-width/(length(categories)-1+.7)
      extents<-arial_text_extents_mm(category_display,cfg$axis_text_size)
      fit<-try(choose_readable_text_angle(extents,spacing,min(14,cfg$height_mm*.27),cfg$label_angle,.7,"Category",TRUE),silent=TRUE)
      if(inherits(fit,"try-error")&&cfg$label_wrap=="auto") {
        category_display<-wrap_arial_labels(display_labels(categories,cfg$category_labels),max(spacing-.7,2),cfg$axis_text_size)
        fit<-choose_readable_text_angle(arial_text_extents_mm(category_display,cfg$axis_text_size),spacing,min(14,cfg$height_mm*.27),cfg$label_angle,.7,"Category",TRUE)
      }else if(inherits(fit,"try-error"))stop(as.character(fit))
      angle<-fit$angle;attempts<-fit$attempts
      p<-suppressMessages(p+ggplot2::scale_x_discrete(name=if(is.null(cfg$x_label))cfg$x else cfg$x_label,limits=categories,labels=category_display,drop=FALSE,expand=ggplot2::expansion(add=.35)))
      p<-p+ggplot2::theme(axis.text.x=ggplot2::element_text(angle=angle,hjust=if(angle==0).5 else 1,vjust=1))
    }
    actual<-trend_categorical_panel_mm(p,cfg,series,labels,colors,shapes,fits)
    axis_mm<-if(horizontal_numeric)min(actual$width_mm)else min(actual$height_mm)
    state<-c(axis_mm,min(actual$width_mm),min(actual$height_mm),angle)
    if(!is.null(previous)&&max(abs(state-previous))<.01)break
    previous<-state
  }
  p<-suppressMessages(apply_numeric(p,axis_mm))
  actual<-trend_categorical_panel_mm(p,cfg,series,labels,colors,shapes,fits)
  if(horizontal_numeric) {
    extents<-rotated_text_extents_mm(arial_text_extents_mm(category_display,cfg$axis_text_size),angle)
    if(max(extents["height",])+.7>min(actual$height_mm)/(length(categories)-1+.7))stop("Vertical category labels do not fit: increase height_mm or authorize shorter labels.")
  }
  build<-ggplot2::ggplot_build(p)
  axes<-setNames(lapply(seq_along(metrics),function(i) {
    panel_index<-which(as.character(build$layout$layout$metric)==metrics[i])[1]
    if(is.na(panel_index))panel_index<-1L
    scale<-build$layout$panel_scales_y[[build$layout$layout$SCALE_Y[panel_index]]]
    panel<-actual[panel_index,,drop=FALSE]
    list(limits=scale$get_limits(),breaks=scale$get_breaks(),panel_width_mm=panel$width_mm,panel_height_mm=panel$height_mm,
      numeric_axis_mm=if(horizontal_numeric)panel$width_mm else panel$height_mm,original_units=TRUE)
  }),metrics)
  list(plot=p,angle=angle,axes=axes,text_fitting=list(panel_mm=actual,display_labels=category_display,
    metric_strip_labels=wrapped_metrics,angle=angle,attempts=attempts,iterations=iteration,
    preserves_values=TRUE,reason="Actual Arial at final canvas size; panel measurements include shared-label removal, strips and complete guide."))
}
