# Aligned vertical bars or genuine common-axis metric lines; no unit rescaling.
stacked_tick_height_mm<-function(ticks,cfg){
 # Measure on the same actual-font raster device as manuscript previews,
 # rather than the implicit PostScript device and its fallback font metrics.
 ragg::agg_capture(width=cfg$width_mm,height=cfg$height_mm,units="mm",res=cfg$dpi)
 on.exit(grDevices::dev.off())
 grid::convertHeight(grid::grobHeight(grid::textGrob(format_axis_ticks(ticks),
  gp=grid::gpar(fontfamily="Arial",fontsize=cfg$axis_text_size))),"mm",valueOnly=TRUE)
}
if(cfg$orientation!="vertical" || cfg$delta)stop("stacked-bars/shared-axis require vertical raw/summary input without delta mode.")
if(cfg$combo_layout=="stacked-bars"){
 if(any(cfg$combo_styles!="bar"))stop("stacked-bars requires two bar styles.")
 if(!is.null(cfg$limits)||!is.null(cfg$breaks))stop("Use named combo_limits/combo_breaks for stacked-bars.")
 inside<-cfg$combo_value_placement=="inside";stacked_plots<-list();combo_axes<-list();inside_value_placement<-list()
 provisional_panel<-c(width=cfg$width_mm-12,height=(cfg$height_mm-17)/2)
 # Only the bottom panel shows model names, fitted at the complete figure dimensions.
 fitted<-fit_comparison_text(base(),cfg,labels,positions,text_fit_policy,sm$annotation,cfg$show_values&&!inside,panel_override_mm=provisional_panel)
 cfg$label_angle<-fitted$label_angle;cfg$value_angle<-fitted$value_angle;labels<-fitted$labels;text_fitting<-fitted$record
 text_fitting$values_placement<-if(inside)"inside-bars-with-measured-view-padding"else"above-panel"
 for(i in seq_along(cfg$metrics)){
  key<-cfg$metrics[i];ss<-sm[sm$metric==key,];dd<-dat[dat$metric==key,];sd_on<-metric_sd[[key]]
  ax<-resolve_multi_axis(multi_metric_extent(ss,dd,sd_on,cfg$show_points,"bar"),cfg,cfg$combo_limits[[key]],cfg$combo_breaks[[key]],provisional_panel["height"],FALSE,"bar")
  sd_modes<-rep(if(cfg$combo_sd_display=="outward")"outward"else"both",nrow(ss))
  if(inside&&cfg$show_values){
   view<-resolve_inside_bar_view(ss,cfg,ax,provisional_panel,"vertical",sd_on,text_fit_policy$value_angle,is.null(cfg$combo_limits[[key]]),is.null(cfg$combo_breaks[[key]]))
   ax<-view$axis;inside_fit<-view$fit;sd_modes<-view$sd_modes
  }
  combo_axes[[key]]<-ax;lim<-ax$limits;baseline<-ax$baseline
  # Endpoint tick text is centered at the numeric panel boundary. Reserve its
  # actual Arial device height even when there is no title or outside value row.
  tick_height_mm<-stacked_tick_height_mm(ax$breaks,cfg)
  top_gutter_mm<-max(cfg$outer_margin*25.4/72,tick_height_mm/2+.46)
  text_fitting$numeric_axis_endpoint_padding_by_metric[[key]]<-list(top_mm=top_gutter_mm,
   tick_text_height_mm=tick_height_mm,clearance_mm=.46)
  p_i<-apply_comparison_text(add_marks(base(),ss,dd,"bar",baseline,sd_on,sd_modes,combo_metric_cols[[key]]),cfg,labels,positions)+
   labs(title=NULL,tag=NULL,caption=NULL,y=metric_lab(key))+
   scale_y_continuous(breaks=ax$breaks,labels=axis_labels,expand=expansion(mult=0))+
   coord_cartesian(xlim=c(1-cfg$category_padding,length(models)+cfg$category_padding),ylim=lim,clip="off",expand=FALSE)+
   theme(plot.margin=margin(top_gutter_mm*72/25.4,cfg$outer_margin,if(i==1)cfg$combo_panel_gap_mm*72/25.4 else cfg$outer_margin,cfg$outer_margin))
  if(baseline>lim[1]&&baseline<lim[2])p_i<-p_i+geom_hline(yintercept=baseline,linewidth=.25,color="#333333")
  if(cfg$show_values){
   if(inside){
    fit<-inside_fit
    ss$.label_value<-fit$position;ss$.label_pos<-fit$category_position;ss$.label_angle<-fit$angle
    p_i<-p_i+geom_text(data=ss,aes(x=.label_pos,y=.label_value,label=annotation,angle=.label_angle),color=ss$ink,fontface=ss$face,size=cfg$combo_inside_value_size,family="Arial")
    fit$record$position<-ss$.label_value;fit$record$category_position<-ss$.label_pos;inside_value_placement[[key]]<-fit$record
   }else{
    ss$.label_value<-lim[2]+diff(lim)*.09
    p_i<-p_i+geom_text(data=ss,aes(x=pos,y=.label_value,label=annotation),color=ss$ink,fontface=ss$face,size=cfg$value_size,angle=cfg$value_angle,family="Arial")+
     theme(plot.margin=margin(max(top_gutter_mm,cfg$value_size*1.12+1)*72/25.4,cfg$outer_margin,if(i==1)cfg$combo_panel_gap_mm*72/25.4 else cfg$outer_margin,cfg$outer_margin))
   }
  }
  if(i<length(cfg$metrics))p_i<-p_i+theme(axis.text.x=element_blank(),axis.ticks.x=element_blank(),axis.title.x=element_blank())
  stacked_plots[[i]]<-p_i
 }
 cfg$show_rank<-FALSE;cfg$combo_limits<-lapply(combo_axes,`[[`,"limits");cfg$combo_breaks<-lapply(combo_axes,`[[`,"breaks");axis_note<-lapply(combo_axes,`[[`,"note")
 build_stacked_bars_grob<-function(){
  gs<-lapply(stacked_plots,ggplotGrob);widths<-do.call(grid::unit.pmax,lapply(gs,`[[`,"widths"));for(i in seq_along(gs))gs[[i]]$widths<-widths
  g<-do.call(rbind,c(gs,list(size="max")));g<-finish_metric_panels_grob(g,cfg)
  final_panel<-c(width=cfg$width_mm-grid::convertWidth(sum(g$widths),"mm",valueOnly=TRUE),height=(cfg$height_mm-grid::convertHeight(sum(g$heights),"mm",valueOnly=TRUE))/length(gs))
  if(min(final_panel)<cfg$text_min_panel_mm)stop("Stacked title/labels leave too little data space; increase height_mm or shorten text.")
  for(key in cfg$metrics)if(inside&&cfg$show_values){
   rec<-inside_value_placement[[key]];ax<-combo_axes[[key]];ss<-sm[sm$metric==key,]
   checked<-fit_inside_bar_values(ss,cfg,ax$limits,ax$baseline,final_panel,"vertical",metric_sd[[key]],text_fit_policy$value_angle,rec$sd_display)
   if(any(checked$fallback))stop("Final stacked values do not all fit; enlarge the canvas or expand numeric limits.")
  }
  text_fitting$final_panel_size_mm<<-as.list(final_panel);text_fitting$final_device_fit_verified<<-TRUE;text_fitting$method_labels_shown_once<<-TRUE
  g
 }
}else{
 if(cfg$show_points)stop("shared-axis line layers display method means; raw scatter is not available on lines.")
 for(k in c("combo_units","combo_domains"))if(is.null(cfg[[k]])||is.null(names(cfg[[k]]))||!setequal(names(cfg[[k]]),cfg$metrics))stop(k," must explicitly cover all selected metrics for shared-axis.")
 units<-unlist(cfg$combo_units)
 if(!is.character(units)||any(!nzchar(units))||length(unique(units))!=1)stop("Shared-axis metrics must have identical explicit units; use facets for incompatible units.")
 domains<-lapply(cfg$combo_domains,unlist)
 if(!all(vapply(domains,function(r)is.numeric(r)&&length(r)==2&&all(is.finite(r))&&diff(r)>0,logical(1))))stop("combo_domains must provide increasing finite scientific domains.")
 if(!all(vapply(domains,function(r)isTRUE(all.equal(unname(r),unname(domains[[1]]))),logical(1))))stop("Shared-axis metrics must have the same stated domain; no implicit rescaling is performed.")
 for(key in cfg$metrics)if(any(dat$value[dat$metric==key]<domains[[key]][1]-1e-12|dat$value[dat$metric==key]>domains[[key]][2]+1e-12))stop("Values fall outside the stated scientific domain for ",key)
 if(!is.null(cfg$combo_limits)||!is.null(cfg$combo_breaks))stop("Use limits/breaks for the one shared-axis numeric view.")
 metric_cols<-if(is.null(cfg$combo_metric_colors))fixed_palette_mapping(cfg$metrics,pal)[cfg$metrics]else unlist(cfg$combo_metric_colors)
 if(!setequal(names(metric_cols),cfg$metrics))stop("combo_metric_colors must map every metric exactly once.")
 invisible(grDevices::col2rgb(metric_cols));metric_cols<-metric_cols[cfg$metrics];cfg$combo_metric_colors<-as.list(metric_cols)
 patterns<-if(is.null(cfg$combo_line_types))setNames(rep(c("solid","dashed","dotdash","longdash","twodash","dotted"),length.out=length(cfg$metrics)),cfg$metrics)else unlist(cfg$combo_line_types)
 shapes<-if(is.null(cfg$combo_marker_shapes))setNames(rep(c(18,16,17,15,3,4),length.out=length(cfg$metrics)),cfg$metrics)else unlist(cfg$combo_marker_shapes)
 if(!setequal(names(patterns),cfg$metrics)||!setequal(names(shapes),cfg$metrics)||any(!shapes %in% 0:25))stop("Metric line types and marker shapes must cover every selected metric.")
 cfg$combo_line_types<-as.list(patterns);cfg$combo_marker_shapes<-as.list(shapes)
 extent<-sm$mean;for(key in cfg$metrics)if(metric_sd[[key]]){ss<-sm[sm$metric==key,];extent<-c(extent,ss$mean-ss$sd,ss$mean+ss$sd)}
 if(cfg$combo_bars)extent<-c(extent,0)
 ax<-resolve_multi_axis(extent,cfg,cfg$limits,cfg$breaks,cfg$height_mm-20,FALSE,if(cfg$combo_bars)"bar"else"line");combo_axes<-list(common=ax);cfg$limits<-ax$limits;cfg$breaks<-ax$breaks
 p<-ggplot(sm,aes(x=pos,y=mean,color=metric,group=metric,linetype=metric,shape=metric))+geom_line(linewidth=cfg$mean_width)+
  scale_color_manual(values=metric_cols,labels=metric_lab(cfg$metrics),breaks=cfg$metrics)+scale_linetype_manual(values=patterns,labels=metric_lab(cfg$metrics),breaks=cfg$metrics)+scale_shape_manual(values=shapes,labels=metric_lab(cfg$metrics),breaks=cfg$metrics)+
  scale_y_continuous(breaks=ax$breaks,labels=axis_labels,expand=expansion(mult=0))+scale_x_continuous(breaks=unname(positions),labels=unname(labels[names(positions)]))+
  theme_classic(base_size=cfg$base_size,base_family="Arial")+
  theme(plot.title=element_text(hjust=.5,size=cfg$title_size,margin=margin(b=3)),axis.text=element_text(size=cfg$axis_text_size,color="#222222"),axis.title=element_text(size=cfg$axis_title_size),axis.line=element_line(linewidth=.25,color="#333333"),axis.ticks=element_line(linewidth=.22,color="#333333"),axis.ticks.length=grid::unit(1.3,"pt"),legend.position="top",legend.title=element_blank(),legend.text=element_text(size=cfg$axis_text_size),legend.key.width=grid::unit(3.5,"mm"),legend.key.height=grid::unit(2.2,"mm"),legend.spacing.x=grid::unit(.7,"mm"),legend.box.spacing=grid::unit(.8,"mm"),legend.margin=margin(1,1,1,1),legend.background=element_rect(fill="white",color=NA),plot.margin=margin(cfg$outer_margin,cfg$outer_margin,cfg$outer_margin,cfg$outer_margin))+
  coord_cartesian(xlim=c(1-cfg$category_padding,length(models)+cfg$category_padding),ylim=ax$limits,expand=FALSE,clip="off")+labs(title=cfg$title,x=NULL,y=if(is.null(cfg$value_label))paste0("Score (",units[1],")")else cfg$value_label,caption=cfg$caption,tag=cfg$panel_tag)
 if(cfg$combo_bars){
  bar_step<-cfg$combo_bar_width/length(cfg$metrics)
  bar_offsets<-setNames((seq_along(cfg$metrics)-(length(cfg$metrics)+1)/2)*bar_step,cfg$metrics)
  sm$display_pos<-sm$pos+unname(bar_offsets[sm$metric]);p$data<-sm;p$mapping$x<-aes(x=display_pos)$x
  bars<-geom_rect(data=sm,aes(xmin=display_pos-bar_step*.46,xmax=display_pos+bar_step*.46,
   ymin=pmin(0,mean),ymax=pmax(0,mean),fill=metric),inherit.aes=FALSE,
   color=cfg$border_color,linewidth=cfg$outline_width*.65,alpha=cfg$fill_alpha,show.legend=FALSE)
  p$layers<-c(list(bars),p$layers)
  p<-p+scale_fill_manual(values=metric_cols,breaks=cfg$metrics)
 }
 if(cfg$line_markers)p<-p+geom_point(size=cfg$line_marker_size,stroke=cfg$inner_width)
 for(key in cfg$metrics)if(metric_sd[[key]])p<-p+geom_errorbar(data=sm[sm$metric==key,],aes(ymin=mean-sd,ymax=mean+sd),width=.09,linewidth=cfg$sd_width,linetype="solid",show.legend=FALSE)
 # Shared categorical positions may obscure another metric's mean/SD glyphs.
 # Separate complete series within each category only when physical bounds collide.
 offsets<-if(cfg$combo_bars)bar_offsets else setNames(rep(0,length(cfg$metrics)),cfg$metrics)
 panel_mm<-measure_text_panel_mm(p,cfg);axis_mm<-panel_mm["height"]
 radius<-if(cfg$line_markers)cfg$line_marker_size*.65 else 0
 obstructed<-FALSE
 for(m in models) {
  ss<-sm[sm$model==m,]
  for(j in seq_len(nrow(ss)))for(k in seq_len(nrow(ss)))if(j!=k) {
   if(cfg$line_markers && abs(ss$mean[j]-ss$mean[k])/diff(ax$limits)*axis_mm<2*radius+.35)obstructed<-TRUE
   if(cfg$line_markers && metric_sd[[ss$metric[k]]] &&
      min(abs(ss$mean[j]-c(ss$mean[k]-ss$sd[k],ss$mean[k]+ss$sd[k])))/diff(ax$limits)*axis_mm<radius+cfg$sd_width/2+.35)obstructed<-TRUE
  }
 }
 if(obstructed && !cfg$combo_bars) {
  unit_mm<-panel_mm["width"]/(length(models)-1+2*cfg$category_padding)
  step_mm<-max(2*radius+.4,.09*unit_mm+cfg$sd_width+.4)
  group_mm<-(length(cfg$metrics)-1)*step_mm+2*radius
  if(group_mm>unit_mm*.9 || group_mm/2+.35>cfg$category_padding*unit_mm)
    stop("Shared-axis mean/SD glyphs need more readable within-category space; increase the allocation or use facets.")
  offsets[]<-(seq_along(cfg$metrics)-(length(cfg$metrics)+1)/2)*step_mm/unit_mm
  sm$display_pos<-sm$pos+unname(offsets[sm$metric]);p$data<-sm;p$mapping$x<-aes(x=display_pos)$x
  for(j in seq_along(p$layers))if(is.data.frame(p$layers[[j]]$data) && all(c("metric","pos")%in%names(p$layers[[j]]$data)))
    p$layers[[j]]$data$display_pos<-p$layers[[j]]$data$pos+unname(offsets[p$layers[[j]]$data$metric])
 }
 if(cfg$combo_bars){
  glyph_span_mm<-cfg$combo_bar_width/length(cfg$metrics)*panel_mm["width"]/(length(models)-1+2*cfg$category_padding)
  if(cfg$line_markers && glyph_span_mm<2*radius+.2)
   stop("Bar-and-line mean icons need a wider allocation or fewer methods/metrics; retain readable icons.")
  for(j in seq_along(p$layers))if(is.data.frame(p$layers[[j]]$data) && all(c("metric","pos")%in%names(p$layers[[j]]$data)))
   p$layers[[j]]$data$display_pos<-p$layers[[j]]$data$pos+unname(offsets[p$layers[[j]]$data$metric])
 }
 fitted<-fit_comparison_text(p,cfg,labels,positions,text_fit_policy,NULL,FALSE);cfg$label_angle<-fitted$label_angle;cfg$value_angle<-fitted$value_angle;labels<-fitted$labels;text_fitting<-fitted$record;p<-apply_comparison_text(p,cfg,labels,positions)
 cfg$show_rank<-FALSE;cfg$show_values<-FALSE
 metric_encoding<-list(color_by="metric",colors=cfg$combo_metric_colors,line_types=cfg$combo_line_types,marker_shapes=cfg$combo_marker_shapes,common_units=units[1],common_domain=domains[[1]],rescaled=FALSE,category_series_offsets=as.list(offsets),
  category_offset_meaning=if(cfg$combo_bars)"Within-category metric offsets align each bar, mean icon and line; scores and common model order are unchanged."else"Within-category offsets separate overlapping metric symbols/SD only; scores, model identities and common order are unchanged.",
  bars=list(shown=cfg$combo_bars,baseline=if(cfg$combo_bars)0 else NULL,total_category_width=if(cfg$combo_bars)cfg$combo_bar_width else NULL),
  focal_highlight=if(length(highlight))list(models=highlight,display_labels=unname(labels[highlight]),encoding="red bold method-axis label; metric colors unchanged")else NULL)
}
