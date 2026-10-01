# Horizontal aligned metric panels with one shared Method column.
if(cfg$orientation!="horizontal" || cfg$delta)stop("shared-rows requires horizontal raw/summary data without delta mode.")
if(length(cfg$combo_styles)!=2 || any(cfg$combo_styles!="bar"))stop("shared-rows requires two bar styles.")
shared_rank_sign<-NULL
if(cfg$show_rank){
 dirs<-cfg$combo_directions
 if(is.null(dirs))dirs<-setNames(rep(cfg$direction,length(cfg$metrics)),cfg$metrics)
 if(is.null(names(dirs))||!all(cfg$metrics %in% names(dirs))||!all(unlist(dirs)[cfg$metrics] %in% c("higher","lower")))stop("combo_directions must map each metric to higher or lower.")
 rank_signs<-vapply(cfg$metrics,function(key){
  ss<-sm[sm$metric==key,];v<-ss$mean[match(models,ss$model)]
  if(dirs[[key]]=="lower")v<--v
  dv<-diff(v)
  if(all(dv>=0)&&any(dv>0))return(1)
  if(all(dv<=0)&&any(dv<0))return(-1)
  stop("A common ranking arrow requires both metrics to improve monotonically in the displayed row order; disable show_rank.")
 },numeric(1))
 if(length(unique(rank_signs))!=1)stop("Metrics improve in opposite directions; a common ranking arrow would be misleading.")
 shared_rank_sign<-rank_signs[1];cfg$combo_directions<-as.list(dirs)
}
if(!is.null(cfg$limits)||!is.null(cfg$breaks))stop("Use named combo_limits/combo_breaks for shared-rows scales.")
shared_plots<-list();combo_axes<-list();inside_value_placement<-list()
inside<-cfg$combo_value_placement=="inside"
label_mm<-max(arial_text_extents_mm(labels,cfg$category_text_size)["width",])
value_mm<-if(cfg$show_values&&!inside)max(arial_text_extents_mm(sm$annotation,cfg$value_size*72/25.4,TRUE)["width",])+1.45 else 3.0
rank_gutter_mm<-if(cfg$show_rank)4.5 else 0
panel_mm<-(cfg$width_mm-label_mm-2*value_mm-5-rank_gutter_mm)/2
fitted<-fit_comparison_text(base(),cfg,labels,positions,text_fit_policy,sm$annotation,cfg$show_values&&!inside,
 panel_override_mm=c(width=panel_mm,height=cfg$height_mm-14))
cfg$label_angle<-fitted$label_angle;cfg$value_angle<-fitted$value_angle;labels<-fitted$labels
text_fitting<-fitted$record
# External columns consume width. Rotate only when measured method text gets
# materially narrower and every complete label still fits its physical row.
if(!inside && identical(text_fit_policy$label_angle,"auto")){
 ext<-arial_text_extents_mm(labels,cfg$category_text_size)
 pitch<-(cfg$height_mm-14)/(length(models)-1+2*cfg$category_padding)
 candidates<-lapply(c(0,15,30,45),function(a){e<-rotated_text_extents_mm(ext,a);list(angle=a,width=max(e["width",]),height=max(e["height",]))})
 eligible<-Filter(function(x)x$height+cfg$text_fit_gap_mm<=pitch,candidates)
 if(max(ext["width",])>=8 && length(eligible)){
  choice<-eligible[[which.min(vapply(eligible,`[[`,numeric(1),"width"))]]
  if(choice$width<max(ext["width",])-.4){
   cfg$label_angle<-choice$angle
   text_fitting$method<-c(choice,list(fits=TRUE,attempts=candidates,reason="Measured rotation reduces external-label width while retaining full row clearance."))
  }
 }
}
text_fitting$outside_value_gap_mm<-if(!inside).45 else NULL
label_mm<-max(rotated_text_extents_mm(arial_text_extents_mm(labels,cfg$category_text_size),cfg$label_angle)["width",])
if(!inside&&cfg$show_values)value_mm<-max(rotated_text_extents_mm(arial_text_extents_mm(sm$annotation,cfg$value_size*72/25.4,TRUE),cfg$value_angle)["width",])+1.45
panel_mm<-(cfg$width_mm-label_mm-2*value_mm-5-rank_gutter_mm)/2
if(panel_mm<cfg$text_min_panel_mm)stop("Shared-row canvas is too narrow for readable metric panels; increase width_mm.")
text_fitting$panel_size_mm$width<-panel_mm
text_fitting$values_placement<-if(inside)"inside-bars-with-measured-view-padding"else"external-right-columns"
for(i in seq_along(cfg$metrics)){
 key<-cfg$metrics[i];ss<-sm[sm$metric==key,];dd<-dat[dat$metric==key,]
 sd_on<-metric_sd[[key]]
 extent<-multi_metric_extent(ss,dd,sd_on,cfg$show_points,"bar")
 ax<-resolve_multi_axis(extent,cfg,cfg$combo_limits[[key]],cfg$combo_breaks[[key]],panel_mm,TRUE,"bar")
 sd_modes<-rep(if(cfg$combo_sd_display=="outward")"outward"else"both",nrow(ss))
 if(inside&&cfg$show_values){
  view<-resolve_inside_bar_view(ss,cfg,ax,c(width=panel_mm,height=cfg$height_mm-14),"horizontal",sd_on,text_fit_policy$value_angle,is.null(cfg$combo_limits[[key]]),is.null(cfg$combo_breaks[[key]]))
  ax<-view$axis;inside_fit<-view$fit;sd_modes<-view$sd_modes
 }
 lim<-ax$limits;baseline<-ax$baseline;combo_axes[[key]]<-ax
 # Endpoint tick labels extend beyond the panel by half their Arial width.
 # Reserve that physical overhang, including when values are inside the bars.
 tick_overhang<-max(arial_text_extents_mm(axis_labels(ax$breaks),cfg$axis_text_size)["width",])/2+.35
 right_gutter_mm<-max(value_mm,tick_overhang)
 text_fitting$tick_overhang_mm[[key]]<-tick_overhang
 p_i<-add_marks(base(),ss,dd,"bar",baseline,sd_on,sd_modes,combo_metric_cols[[key]])+labs(title=NULL,tag=NULL,caption=NULL,y=metric_lab(key))+
  scale_y_continuous(breaks=ax$breaks,labels=axis_labels,expand=expansion(mult=0))+
  coord_flip(xlim=c(1-cfg$category_padding,length(models)+cfg$category_padding),ylim=lim,clip="off",expand=FALSE)+
  theme(axis.text.y=element_text(size=cfg$category_text_size,angle=cfg$label_angle,hjust=if(cfg$label_angle==0)1 else .5,vjust=.5),plot.margin=margin(0,right_gutter_mm*72/25.4,cfg$outer_margin,if(i==1)cfg$outer_margin else cfg$combo_panel_gap_mm*72/25.4))
 if(baseline>lim[1]&&baseline<lim[2])p_i<-p_i+geom_hline(yintercept=0,linewidth=.25,color="#333333")
 if(cfg$show_values){
  if(inside){
   fit<-inside_fit
   ss$.label_value<-fit$position;ss$.label_pos<-fit$category_position;ss$.label_angle<-fit$angle
   p_i<-p_i+geom_text(data=ss,aes(x=.label_pos,y=.label_value,label=annotation,angle=.label_angle),color=ss$ink,fontface=ss$face,size=cfg$combo_inside_value_size,family="Arial")
   fit$record$position<-ss$.label_value;fit$record$category_position<-ss$.label_pos;inside_value_placement[[key]]<-fit$record
  }else{
   ss$.label_value<-lim[2]+diff(lim)*.45/panel_mm
   p_i<-p_i+geom_text(data=ss,aes(x=pos,y=.label_value,label=annotation),hjust=0,color=ss$ink,fontface=ss$face,size=cfg$value_size,angle=cfg$value_angle,family="Arial")
  }
 }
 if(i>1)p_i<-p_i+theme(axis.text.y=element_blank(),axis.ticks.y=element_blank())
 shared_plots[[i]]<-p_i
}
cfg$combo_limits<-lapply(combo_axes,`[[`,"limits");cfg$combo_breaks<-lapply(combo_axes,`[[`,"breaks")
axis_note<-lapply(combo_axes,`[[`,"note")
# Build inside the final output device so all fixed Arial widths are actual millimetres.
build_shared_rows_grob<-function(refinement=0L){
 gs<-lapply(shared_plots,ggplotGrob)
 h<-grid::unit.pmax(gs[[1]]$heights,gs[[2]]$heights);gs[[1]]$heights<-h;gs[[2]]$heights<-h
 g<-cbind(gs[[1]],gs[[2]],size="max")
 if(cfg$show_rank){
  panel<-gs[[2]]$layout[gs[[2]]$layout$name=="panel",]
  npc<-function(x)(x-(1-cfg$category_padding))/(length(models)-1+2*cfg$category_padding)
  ends<-npc(unname(positions[models[c(1,length(models))]]));if(shared_rank_sign<0)ends<-rev(ends)
  arrow<-grid::grobTree(
   grid::segmentsGrob(x0=grid::unit(3.2,"mm"),x1=grid::unit(3.2,"mm"),y0=ends[1],y1=ends[2],arrow=grid::arrow(length=grid::unit(.8,"mm"),type="closed"),gp=grid::gpar(col="#222222",fill="#222222",lwd=.22*72/25.4)),
   grid::textGrob("Performance Ranking",x=grid::unit(1.8,"mm"),y=ends[1]+if(ends[1]>.5)-.004 else .004,rot=90,just=c(if(ends[1]>.5)"right"else"left","centre"),gp=grid::gpar(fontfamily="Arial",fontsize=cfg$rank_size*72/25.4,col="#222222")))
  g<-gtable::gtable_add_cols(g,grid::unit(rank_gutter_mm,"mm"))
  g<-gtable::gtable_add_grob(g,arrow,t=panel$t,b=panel$b,l=ncol(g),r=ncol(g),clip="off",name="shared-ranking")
 }
 g<-finish_metric_panels_grob(g,cfg)
 final_panel<-c(width=(cfg$width_mm-grid::convertWidth(sum(g$widths),"mm",valueOnly=TRUE))/2,
  height=cfg$height_mm-grid::convertHeight(sum(g$heights),"mm",valueOnly=TRUE))
 if(any(!is.finite(final_panel))||min(final_panel)<cfg$text_min_panel_mm)stop("Complete shared-row labels/title leave too little data space; increase the canvas or shorten text.")
 pitch<-final_panel["height"]/(length(models)-1+2*cfg$category_padding)
 method_extents<-arial_text_extents_mm(labels,cfg$category_text_size)
 choose_readable_text_angle(method_extents,max(rotated_text_extents_mm(method_extents,cfg$label_angle)["width",])+cfg$text_fit_gap_mm,pitch,cfg$label_angle,cfg$text_fit_gap_mm,"Shared-row Method")
 if(cfg$show_values&&!inside)choose_readable_text_angle(arial_text_extents_mm(sm$annotation,cfg$value_size*72/25.4,TRUE),value_mm,pitch,cfg$value_angle,cfg$text_fit_gap_mm,"Shared-row numeric value")
 if(inside&&cfg$show_values)for(key in cfg$metrics){
  rec<-inside_value_placement[[key]];ss<-sm[sm$metric==key,];ax<-combo_axes[[key]]
  checked<-fit_inside_bar_values(ss,cfg,ax$limits,ax$baseline,final_panel,"horizontal",metric_sd[[key]],text_fit_policy$value_angle,rec$sd_display)
  if(any(checked$fallback))stop("Final inside values do not all fit; increase width_mm/height_mm or expand numeric limits.")
 }

 text_fitting$final_panel_size_mm<<-as.list(final_panel);text_fitting$final_device_fit_verified<<-TRUE
 g
}
