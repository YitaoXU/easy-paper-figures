# Place an ordinary model guide in measured empty space without changing data.
# All measurements use the active Arial export device and final panel geometry.
place_grouped_legend <- function(plot, cfg, n_models, edge) {
  requested <- cfg$legend_placement
  if (!requested %in% c("auto", "inside", "outside"))
    stop("legend_placement must be auto, inside or outside.")
  gap <- cfg$legend_clearance_mm
  if (!is.numeric(gap) || length(gap) != 1 || !is.finite(gap) || gap <= 0)
    stop("legend_clearance_mm must be one positive physical distance.")
  outside <- list(plot=plot, record=list(requested=requested, placement="outside",
    clearance_mm=gap, reason="Explicit outside placement."))
  if (requested == "outside") return(outside)
  bare <- plot + theme(legend.position="none")
  g <- ggplotGrob(bare)
  panel <- which(g$layout$name == "panel")
  if (length(panel) != 1) stop("Automatic model guides require one plotting panel.")
  pw <- cfg$width_mm - grid::convertWidth(sum(g$widths), "mm", valueOnly=TRUE)
  ph <- cfg$height_mm - grid::convertHeight(sum(g$heights), "mm", valueOnly=TRUE)
  if (!all(is.finite(c(pw, ph))) || min(pw, ph) <= 0) stop("No readable panel remains for the model guide.")
  built <- ggplot_build(bare)
  boxes <- list(); unsupported <- character()
  add <- function(x0,x1,y0,y1,pad=0) {
    z <- c(min(x0,x1)*pw-pad,max(x0,x1)*pw+pad,min(y0,y1)*ph-pad,max(y0,y1)*ph+pad)
    if (all(is.finite(z))) boxes[[length(boxes)+1L]] <<- z
  }
  for (i in seq_along(built$data)) {
    d <- built$plot$coordinates$transform(built$data[[i]], built$layout$panel_params[[1]])
    geom <- class(built$plot$layers[[i]]$geom)[1]
    if (!nrow(d) || geom == "GeomBlank") next
    width <- function(j) if ("linewidth" %in% names(d) && is.finite(d$linewidth[j])) d$linewidth[j]/2 else .2
    if (geom == "GeomPoint") {
      for (j in seq_len(nrow(d))) {
        pad <- if ("size" %in% names(d)) d$size[j]*.65 else 1
        if ("stroke" %in% names(d)) pad <- pad+d$stroke[j]/2
        add(d$x[j],d$x[j],d$y[j],d$y[j],pad)
      }
    } else if (geom %in% c("GeomRect", "GeomErrorbar")) {
      for (j in seq_len(nrow(d))) add(d$xmin[j],d$xmax[j],d$ymin[j],d$ymax[j],width(j))
    } else if (geom == "GeomSegment") {
      for (j in seq_len(nrow(d))) add(d$x[j],d$xend[j],d$y[j],d$yend[j],width(j))
    } else if (geom %in% c("GeomPolygon", "GeomPath", "GeomLine")) {
      for (ids in split(seq_len(nrow(d)),d$group)) {
        if (geom == "GeomPolygon") add(range(d$x[ids]),range(d$x[ids]),range(d$y[ids]),range(d$y[ids]),max(vapply(ids,width,numeric(1))))
        else if (length(ids)>1) for (j in seq_len(length(ids)-1))
          add(d$x[ids[j]],d$x[ids[j+1]],d$y[ids[j]],d$y[ids[j+1]],width(ids[j]))
      }
    } else unsupported <- c(unsupported,geom)
  }
  obs <- if (length(boxes)) do.call(rbind,boxes) else matrix(numeric(),ncol=4)
  colnames(obs) <- c("xmin","xmax","ymin","ymax")
  # Conservative polygon/segment bounds may reserve more space than the ink;
  # this is preferable to covering a distribution or uncertainty interval.
  report <- list(requested=requested, placement="outside", clearance_mm=gap,
    panel_mm=list(width=pw,height=ph), occupied_mark_count=nrow(obs),
    occupancy_boxes_mm=obs, geometry="Final coordinate-transformed marks, conservative physical bounds.",
    attempts=list())
  if (length(unsupported)) {
    report$reason <- paste("Unrecognized annotation geometry:",paste(unique(unsupported),collapse=", "))
    if(requested=="inside")stop(report$reason)
    outside$record <- report; return(outside)
  }
  # Test all compact guide layouts and favor a broad empty region rather than
  # the first narrow inter-cluster slit. Preserve the actual font/key sizes.
  best <- NULL
  for (nc in rev(seq_len(n_models))) {
    candidate <- plot + guides(fill=guide_legend(ncol=nc,byrow=TRUE,
      override.aes=list(alpha=cfg$fill_alpha,color=edge))) +
      theme(legend.position="inside",legend.direction="horizontal",legend.justification=c(.5,.5),
        legend.position.inside=c(.5,.5),legend.background=element_rect(fill="white",color=edge,linewidth=.2),
        legend.margin=margin(.6,.8,.6,.8,unit="mm"))
    cg <- ggplotGrob(candidate); guide <- cg$grobs[[which(cg$layout$name=="guide-box-inside")]]
    # Include the half-stroke extending beyond either guide edge.
    w <- grid::convertWidth(grid::grobWidth(guide),"mm",valueOnly=TRUE)+.2
    h <- grid::convertHeight(grid::grobHeight(guide),"mm",valueOnly=TRUE)+.2
    report$attempts[[length(report$attempts)+1]] <- list(columns=nc,width_mm=w,height_mm=h)
    if(w+2*gap>pw || h+2*gap>ph)next
    anchors <- function(length_mm,size_mm,lo,hi) {
      # Merge projected mark support before deriving gap anchors. Dense raw
      # samples must not create a quadratic search in observation count.
      intervals<-data.frame(lo=lo,hi=hi);intervals<-intervals[order(intervals$lo),,drop=FALSE]
      merged<-list()
      if(nrow(intervals))for(j in seq_len(nrow(intervals))){
       if(!length(merged)||intervals$lo[j]>merged[[length(merged)]][2])merged[[length(merged)+1]]<-c(intervals$lo[j],intervals$hi[j])
       else merged[[length(merged)]][2]<-max(merged[[length(merged)]][2],intervals$hi[j])
      }
      support<-if(length(merged))do.call(rbind,merged)else matrix(numeric(),ncol=2)
      x <- unique(c(gap,length_mm-gap-size_mm,support[,1]-gap-size_mm,support[,2]+gap,
        seq(gap,length_mm-gap-size_mm,length.out=15)))
      sort(x[is.finite(x) & x>=gap-1e-9 & x+size_mm<=length_mm-gap+1e-9],decreasing=TRUE)
    }
    xs <- anchors(pw,w,obs[,1],obs[,2]); ys <- anchors(ph,h,obs[,3],obs[,4])
    for(y in ys)for(x in xs) {
      collision <- nrow(obs) && any(x-gap<obs[,2] & x+w+gap>obs[,1] & y-gap<obs[,4] & y+h+gap>obs[,3])
      if(collision)next
      dx<-pmax(obs[,1]-(x+w),x-obs[,2],0);dy<-pmax(obs[,3]-(y+h),y-obs[,4],0)
      mark_gap<-if(nrow(obs))min(sqrt(dx^2+dy^2))else Inf
      boundary_gap<-min(x,pw-x-w,y,ph-y-h)
      score<-min(mark_gap,boundary_gap)
      if(is.null(best)||score>best$score+1e-8)best<-list(plot=candidate,x=x,y=y,width=w,height=h,
        columns=nc,score=score,mark_gap=mark_gap,boundary_gap=boundary_gap)
    }
  }
  if(!is.null(best)){
    report$placement<-"inside";report$reason<-"The framed guide fits a broad measured empty region with maximum minimum physical clearance."
    report$columns<-best$columns;report$guide_mm<-list(width=best$width,height=best$height)
    report$framed<-TRUE;report$selection_score_mm<-best$score
    report$minimum_mark_clearance_mm<-best$mark_gap;report$minimum_boundary_clearance_mm<-best$boundary_gap
    report$box_mm<-c(xmin=best$x,xmax=best$x+best$width,ymin=best$y,ymax=best$y+best$height)
    report$box_normalized<-report$box_mm/c(pw,pw,ph,ph)
    return(list(plot=best$plot+theme(legend.position.inside=c((best$x+best$width/2)/pw,(best$y+best$height/2)/ph)),record=report))
  }
  report$reason <- "No empty region fits the complete guide with the required clearance; retain the measured external guide."
  if(requested=="inside")stop("Unsafe inside model guide: ",report$reason," Use outside, shorter display labels or an explicitly larger allocation.")
  outside$record <- report;outside
}
