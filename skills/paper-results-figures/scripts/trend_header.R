# Build the reference-style icon/name row above one shared statistic/value row.
# All measurements run on the active Arial export device at the final size.
trend_guide_grob <- function(cfg, series, labels, colors, shapes, fits) {
  measure<-function(s)grid::convertWidth(grid::grobWidth(grid::textGrob(s,
    gp=grid::gpar(fontfamily="Arial",fontsize=cfg$legend_size))),"mm",valueOnly=TRUE)
  header<-trend_stat_header(cfg$statistics,cfg$statistic_labels,cfg$slope_reference)
  values<-vapply(series,function(key)trend_stat_values(fits[[key]],cfg$statistics,cfg$p_value_target),character(1))
  available<-cfg$width_mm-2*2*25.4/72
  key_width<-3.5;name_gap<-.7
  header_labels<-cfg$statistic_labels
  prefix_width<-if(nzchar(header))measure(header)+.8 else 0
  widths<-pmax(vapply(labels,measure,numeric(1))+key_width+name_gap,
    vapply(values,measure,numeric(1)))+.7
  # Standard mathematical symbols shorten a crowded statistic header only;
  # requested labels, series identities, values and fonts remain authoritative.
  if(cfg$mode=="continuous" && length(series)==2L && is.null(cfg$statistic_labels) &&
      prefix_width+2*max(widths)>available) {
    header_labels<-list(pearson_r="r",p_value="p")
    header<-trend_stat_header(cfg$statistics,header_labels,cfg$slope_reference)
    prefix_width<-if(nzchar(header))measure(header)+.8 else 0
  }
  columns<-length(series)
  while(columns>1L && prefix_width+columns*max(widths)>available)columns<-columns-1L
  if(cfg$mode=="continuous" && length(series)==2L && columns!=2L)
    stop("The two-row comparison guide cannot fit both model names/statistics at this width; increase width_mm or supply authorized shorter display labels.")
  if(prefix_width+max(widths)>available)
    stop("The comparison guide exceeds the final canvas at readable Arial size; increase width_mm or use authorized shorter display labels.")
  blocks<-ceiling(length(series)/columns)
  row_height<-max(3.2,cfg$legend_size*25.4/72*1.35)
  rows_per_block<-if(nzchar(header))2L else 1L
  height<-blocks*rows_per_block*row_height+.8
  model_width<-(available-prefix_width)/columns
  children<-list()
  text<-function(label,x,y,hjust=.5)grid::textGrob(label,x=grid::unit(x,"mm"),y=grid::unit(y,"mm"),
    just=c(hjust,.5),gp=grid::gpar(fontfamily="Arial",fontsize=cfg$legend_size,col="#222222"))
  for(i in seq_along(series)) {
    block<-(i-1L)%/%columns;column<-(i-1L)%%columns
    y_name<-height-.4-(block*rows_per_block+.5)*row_height
    center<-prefix_width+(column+.5)*model_width
    total<-key_width+name_gap+measure(labels[i]);left<-center-total/2
    children<-c(children,list(grid::segmentsGrob(x0=grid::unit(left,"mm"),x1=grid::unit(left+key_width,"mm"),
      y0=grid::unit(y_name,"mm"),y1=grid::unit(y_name,"mm"),
      gp=grid::gpar(col=colors[series[i]],lwd=cfg$line_width*72/25.4)),
      grid::pointsGrob(x=grid::unit(left+key_width/2,"mm"),y=grid::unit(y_name,"mm"),pch=shapes[series[i]],
        size=grid::unit(cfg$point_size,"mm"),gp=grid::gpar(col=colors[series[i]],fill=colors[series[i]],lwd=.6)),
      text(labels[i],left+key_width+name_gap,y_name,0)))
    if(nzchar(header))children<-c(children,list(text(values[i],center,y_name-row_height)))
  }
  if(nzchar(header))children<-c(children,list(text(header,0,height-.4-1.5*row_height,0)))
  list(grob=grid::grobTree(children=do.call(grid::gList,children),
    vp=grid::viewport(width=grid::unit(available,"mm"),height=grid::unit(height,"mm"))),
    height_mm=height,record=list(layout="Icon-line-name row, then one shared statistic header and aligned per-series values",
      columns=columns,blocks=blocks,rows_per_block=rows_per_block,header=header,statistic_display_labels=header_labels,values=unname(values),
      available_width_mm=available,prefix_width_mm=prefix_width,model_width_mm=model_width))
}

trend_final_grob <- function(p,cfg,series,labels,colors,shapes,fits) {
  g<-ggplot2::ggplotGrob(p)
  guide<-NULL
  if(cfg$mode=="continuous") {
    guide<-trend_guide_grob(cfg,series,labels,colors,shapes,fits)
    # Place the two compact rows immediately above the panel, after any title.
    panel_row<-min(g$layout$t[grepl("^panel",g$layout$name)])
    g<-gtable::gtable_add_rows(g,grid::unit(guide$height_mm+.6,"mm"),pos=panel_row-1L)
    g<-gtable::gtable_add_grob(g,guide$grob,t=panel_row,l=1,r=length(g$widths),clip="off",name="trend-two-row-guide")
  } else if(cfg$orientation=="vertical" && length(cfg$metric_order)>1L) {
    # Categories are common across adjacent metric panels. Keep their left-most
    # labels while every metric retains its own original-unit numeric scale.
    axes<-which(grepl("^axis-l",g$layout$name));first<-min(g$layout$l[axes])
    internal<-axes[g$layout$l[axes]>first]
    if(length(internal)) {
      columns<-unique(g$layout$l[internal])
      for(i in internal) {
        # Retain each panel's gray baseline while omitting its repeated names
        # and category ticks, matching the existing shared-row comparisons.
        g$grobs[[i]]<-grid::segmentsGrob(x0=1,x1=1,y0=0,y1=1,
          gp=grid::gpar(col="#333333",lwd=.25*72/25.4))
      }
      for(i in columns)g$widths[i]<-grid::unit(0,"mm")
    }
  }
  list(grob=g,guide=if(is.null(guide))NULL else guide$record)
}
