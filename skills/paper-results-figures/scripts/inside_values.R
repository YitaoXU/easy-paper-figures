# Fit explicit inside values by adapting a measured numeric view, never hiding labels.
fit_inside_bar_values <- function(summary, cfg, limits, baseline, panel_mm,
    orientation, show_sd, value_policy, sd_modes = "both") {
  free_end <- summary$mean
  both <- rep(sd_modes, length.out=nrow(summary)) == "both"
  if (show_sd) free_end[both] <- ifelse(summary$mean[both] >= baseline,
    pmax(baseline, summary$mean[both] - summary$sd[both]), pmin(baseline, summary$mean[both] + summary$sd[both]))
  category_span <- length(unique(summary$model)) - 1 + 2 * cfg$category_padding
  categorical_mm <- unname(panel_mm[if (orientation == "horizontal") "height" else "width"] / category_span * cfg$bar_width)
  numeric_mm <- unname(abs(free_end - baseline) / diff(limits) * panel_mm[if (orientation == "horizontal") "width" else "height"])
  measured <- vapply(seq_len(nrow(summary)), function(i) arial_text_extents_mm(summary$annotation[i], cfg$combo_inside_value_size * 72 / 25.4, summary$face[i] == "bold")[,1], numeric(2))
  choices<-lapply(seq_len(nrow(summary)),function(i){
    candidates<-if(identical(value_policy,"auto"))c(0,90,45)else value_policy
    attempts<-lapply(candidates,function(angle){
      box<-rotated_text_extents_mm(measured[,i,drop=FALSE],angle)[,1]
      category_need<-box[if(orientation=="horizontal")"height"else"width"]+cfg$text_fit_gap_mm
      numeric_need<-box[if(orientation=="horizontal")"width"else"height"]+cfg$text_fit_gap_mm
      list(angle=angle,fits_category=category_need<=categorical_mm+1e-10,
        fits=category_need<=categorical_mm+1e-10 && numeric_need<=numeric_mm[i]+1e-10,numeric_need_mm=unname(numeric_need))
    })
    good<-which(vapply(attempts,`[[`,logical(1),"fits"));possible<-which(vapply(attempts,`[[`,logical(1),"fits_category"))
    if(!length(possible))stop("Inside value is wider than its bar at every allowed angle; increase width_mm/height_mm or allow automatic rotation.")
    best<-if(length(good))good[1]else possible[which.min(vapply(attempts[possible],`[[`,numeric(1),"numeric_need_mm"))]
    attempts[[best]]
  })
  angle<-vapply(choices,`[[`,numeric(1),"angle");fits<-vapply(choices,`[[`,logical(1),"fits");needed<-vapply(choices,`[[`,numeric(1),"numeric_need_mm")
  list(position=baseline+(free_end-baseline)*.5,category_position=summary$pos,angle=angle,
    fallback=!fits,numeric_need_mm=needed,free_end=free_end,
    record=data.frame(model=summary$model,metric=summary$metric,label=summary$annotation,
      sd_display=if(show_sd)rep(sd_modes,length.out=nrow(summary))else"not-displayed",
      numeric_span_mm=numeric_mm,category_span_mm=categorical_mm,text_width_mm=measured["width",],
      numeric_need_mm=needed,angle=angle,placement=ifelse(fits,"inside","requires-view-padding")))
}

resolve_inside_bar_view <- function(summary,cfg,axis,panel_mm,orientation,show_sd,value_policy,allow_padding=TRUE,automatic_breaks=TRUE){
  sd_modes<-rep(if(cfg$combo_sd_display=="outward")"outward"else"both",nrow(summary))
  if(!is.null(cfg$combo_sd_modes[[summary$metric[1]]]))sd_modes<-unname(unlist(cfg$combo_sd_modes[[summary$metric[1]]])[summary$model])
  else if(show_sd && cfg$combo_sd_display=="auto"){
    midpoint<-axis$baseline+(summary$mean-axis$baseline)*.5
    label_half<-cfg$combo_inside_value_size*.56/unname(panel_mm[if(orientation=="horizontal")"width"else"height"])*diff(axis$limits)
    # SD through the bar's centre would cross an inside numeric label.
    overlap<-ifelse(summary$mean>=axis$baseline,summary$mean-summary$sd<=midpoint+label_half,
      summary$mean+summary$sd>=midpoint-label_half)
    sd_modes[overlap]<-"outward"
  }
  original<-axis$limits
  numeric_panel<-unname(panel_mm[if(orientation=="horizontal")"width"else"height"])
  for(iteration in seq_len(6)){
    # Text fitting can change the readable tick step. Complete nearby endpoints
    # using that final step before measuring labels, so completion cannot silently
    # undo a fitted inside placement. Explicit limits or breaks stay authoritative.
    if(automatic_breaks)axis$breaks<-choose_axis_breaks(axis$limits,numeric_panel,cfg$axis_text_size,orientation=="horizontal")
    if(allow_padding && automatic_breaks){
      old_limits<-axis$limits
      completed<-complete_nearby_axis_ticks(axis$limits,axis$breaks)
      axis$limits<-completed$limits;axis$breaks<-completed$breaks
      if(axis$baseline==old_limits[1])axis$baseline<-axis$limits[1]
      else if(axis$baseline==old_limits[2])axis$baseline<-axis$limits[2]
    }
    fit<-fit_inside_bar_values(summary,cfg,axis$limits,axis$baseline,panel_mm,orientation,show_sd,value_policy,sd_modes)
    if(!any(fit$fallback))break
    if(!allow_padding)stop("Explicit axis limits leave too little room for all inside values; expand limits or increase the canvas.")
    numeric_panel<-unname(panel_mm[if(orientation=="horizontal")"width"else"height"])
    ratios<-pmin(.85,(fit$numeric_need_mm+.35)/numeric_panel)
    lim<-axis$limits
    if(all(summary$mean>axis$baseline) && axis$baseline==lim[1]){
      lower<-min((fit$free_end-ratios*lim[2])/(1-ratios))
      if(lower<=0 && all(summary$mean>=0))lower<-0
      if(lower>=lim[1]-1e-12)stop("Inside values cannot fit without changing the scientific baseline; increase the canvas.")
      axis$limits[1]<-lower;axis$baseline<-lower
    }else if(all(summary$mean<axis$baseline) && axis$baseline==lim[2]){
      upper<-max((fit$free_end-ratios*lim[1])/(1-ratios))
      if(upper>=0 && all(summary$mean<=0))upper<-0
      if(upper<=lim[2]+1e-12)stop("Inside values cannot fit without changing the scientific baseline; increase the canvas.")
      axis$limits[2]<-upper;axis$baseline<-upper
    }else stop("Inside values cannot fit on this zero-crossing baseline; increase the canvas or choose outside values.")
  }
  if(any(fit$fallback))stop("Not all inside labels fit; increase the canvas or expand numeric limits.")
  axis$breaks<-snap_axis_breaks(axis$breaks,axis$limits)
  axis$inside_padding<-list(original_limits=original,resolved_limits=axis$limits,
    changed=!isTRUE(all.equal(original,axis$limits)),reason="Every requested inside label fits actual Arial size; computed values/SD are unchanged.")
  axis$note<-if(axis$baseline!=0)sprintf("Truncated bar axis; baseline = %.6g. Compare labeled values, not bar lengths as ratios.",axis$baseline)else NULL
  list(axis=axis,fit=fit,sd_modes=sd_modes)
}
