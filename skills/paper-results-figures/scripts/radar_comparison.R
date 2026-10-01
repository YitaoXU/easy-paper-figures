#!/usr/bin/env Rscript
# Ordered summary profiles on scientifically declared radial domains.
radar_defaults <- function() list(
 plot_type="radar-comparison", input=NULL, output_prefix=NULL,
 data_mode="summary", model="model", axis="axis", value="value",
 axis_order=NULL, model_order=NULL, model_labels=NULL, axis_labels=NULL, focus_models=NULL,
 scale_mode="common-domain", metric_domain=NULL, unit=NULL, direction="higher",
 axis_specs=NULL, normalization_reason=NULL, sampling_unit=NULL,
 palette="muted-green-blue-purple", color_values=NULL, palette_mapping=NULL, line_color_values=NULL, line_darken=NULL, shape_values=NULL,
 fill_alpha=NULL, line_alpha=1, line_width=.25, point_size=.70,
 grid_style="circular", band_colors=c("#E8CCC4","#DBD4BE","#C5D2BC","#BFD6B2"), band_alpha=.28,
 grid_color="#D1D4D2", grid_width=.18, show_polygons=FALSE, show_radial_labels=NULL, radial_label_policy="endpoints",
 legend_position="auto", legend_clearance_mm=.7, show_values=FALSE, value_models=NULL, value_size=1.5,
 value_position="auto", value_offset=.055, value_clearance_mm=.30, value_offsets=NULL,
 radial_breaks=NULL, start_angle=90, clockwise=TRUE,
 title=NULL, caption=NULL, panel_tag=NULL,
 layout_columns=3, width_mm=NULL, height_mm=NULL, width=57/25.4, height=54/25.4,
 base_size=7, title_size=7.5, axis_text_size=6.0, legend_text_size=6,
 formats=c("pdf","svg","png"), dpi=600)

radar_assert <- function(ok, message) { if(!isTRUE(ok)) stop(message, call.=FALSE) }
radar_string <- function(x) is.character(x) && length(x)==1L && !is.na(x) && nzchar(trimws(x))
radar_domain <- function(x) is.numeric(x) && length(x)==2L && all(is.finite(x)) && diff(x)>0

# Radar-specific outline contrast never changes base palette slots or fills.
# An explicit base/effective map remains exact unless a transform is requested.
radar_resolve_colors <- function(cfg, models, palette) {
 named_map<-function(map, key) {
  result<-unlist(map)
  radar_assert(is.character(result) && !is.null(names(result)) && !anyDuplicated(names(result)) && all(models %in% names(result)) && !anyNA(result[models]), paste(key,"must be a named color map covering every model."))
  result<-result[models]
  tryCatch(grDevices::col2rgb(result),error=function(e)stop(paste("Invalid",key),call.=FALSE))
  result
 }
 base_resolution<-resolve_model_palette_mapping(models,palette,focal=cfg$focus_models,
  colors=cfg$color_values,saved_record=cfg$palette_mapping)
 base<-base_resolution$colors[models]
 amount<-cfg$line_darken
 if(is.null(amount))amount<-if(is.null(cfg$color_values) && is.null(cfg$line_color_values) && cfg$palette %in% c("rainbow","rainbow-transparent")).40 else 0
 radar_assert(is.numeric(amount) && length(amount)==1L && is.finite(amount) && amount>=0 && amount<=1, "line_darken must be a finite number between 0 and 1.")
 effective<-if(!is.null(cfg$line_color_values))named_map(cfg$line_color_values,"line_color_values")else if(amount==0)base else darken_palette_colors(base,amount)
 list(base=base,effective=effective,amount=amount,mapping=base_resolution$record,
  policy=if(!is.null(cfg$line_color_values))"explicit effective line map"else if(amount==0)"unchanged base RGB"else"radar RGB-channel darkening")
}

radar_plot_grob <- function(plot) {
 grob<-ggplot2::ggplotGrob(plot)
 title<-which(grob$layout$name=="title")
 if(length(title)){grob$layout$l[title]<-1L;grob$layout$r[title]<-length(grob$widths)}
 grob
}

# The guide must clear the complete circular background, not merely vertices.
# Device-space corners are measured after axis/caption/value text has fitted.
radar_legend_safe <- function(box, clearance, occupied, circle) {
 expanded<-box+c(-clearance,clearance,-clearance,clearance)
 nearest<-c(max(expanded[1],min(circle[1],expanded[2])),max(expanded[3],min(circle[2],expanded[4])))
 if(sum((nearest-circle[1:2])^2)<=circle[3]^2)return(FALSE)
 if(nrow(occupied) && any(expanded[1]<occupied[,2] & expanded[2]>occupied[,1] & expanded[3]<occupied[,4] & expanded[4]>occupied[,3]))return(FALSE)
 TRUE
}

radar_choose_legend <- function(plot,cfg,n_models,circle,occupied) {
 gap<-cfg$legend_clearance_mm
 inset<-gap+.09
 report<-list(requested=cfg$legend_position,placement="top",framed=FALSE,clearance_mm=gap,frame_width_mm=.18,
  circle_mm=c(center_x=circle[1],center_y=circle[2],radius=circle[3]),occupied_bounds_mm=occupied,
  attempts=list(),reason="No lower circle corner fits the complete guide and physical clearance.")
 corners<-if(cfg$legend_position=="lower-left")"lower-left"else if(cfg$legend_position=="lower-right")"lower-right"else c("lower-left","lower-right")
 for(nc in rev(seq_len(n_models))) {
  candidate<-plot+radar_model_guides(cfg,nc)+
   theme(legend.position="inside",legend.position.inside=c(.5,.5),legend.direction=if(nc==1L)"vertical"else"horizontal",
    legend.background=element_rect(fill="white",color="#888888",linewidth=.18),legend.margin=margin(.65,.65,.65,.65,unit="mm"))
  cg<-radar_plot_grob(candidate);index<-which(cg$layout$name=="guide-box-inside")
  guide<-cg$grobs[[index]]
  w<-grid::convertWidth(grid::grobWidth(guide),"mm",valueOnly=TRUE)
  h<-grid::convertHeight(grid::grobHeight(guide),"mm",valueOnly=TRUE)
  report$attempts[[length(report$attempts)+1L]]<-list(columns=nc,direction=if(nc==1L)"vertical"else"horizontal",width_mm=w,height_mm=h)
  if(!all(is.finite(c(w,h))) || min(w,h)<=0 || w+2*inset>cfg$width_mm || h+2*inset>cfg$height_mm)next
  for(corner in corners) {
   x_range<-if(corner=="lower-left")c(inset,min(circle[1]-w,cfg$width_mm-inset-w))else c(max(circle[1],inset),cfg$width_mm-inset-w)
   y_range<-c(inset,min(circle[2]-h,cfg$height_mm-inset-h))
   if(diff(x_range)<0 || diff(y_range)<0)next
   # Scan physical whitespace, including obstacle-edge candidates. No axis or
   # observation coordinates are prescribed by a synthetic example.
   xs<-sort(unique(c(seq(x_range[1],x_range[2],length.out=45),occupied[,1]-gap-w,occupied[,2]+gap)))
   ys<-sort(unique(c(seq(y_range[1],y_range[2],length.out=45),occupied[,3]-gap-h,occupied[,4]+gap)))
   xs<-xs[xs>=x_range[1] & xs<=x_range[2]];ys<-ys[ys>=y_range[1] & ys<=y_range[2]]
   if(corner=="lower-right")xs<-rev(xs)
   for(y in ys)for(x in xs) {
    box<-c(left=x,right=x+w,bottom=y,top=y+h)
    if(!radar_legend_safe(box,inset,occupied,circle))next
    report$placement<-corner;report$framed<-TRUE;report$columns<-nc
    report$direction<-if(nc==1L)"vertical"else"horizontal"
    report$guide_mm<-c(width=w,height=h);report$box_mm<-box
    report$frame_ink_bounds_mm<-box+c(-.09,.09,-.09,.09)
    report$reason<-"A measured lower circle corner fits every key and label, outside the complete disk and clear of text/marks."
    return(list(grob=guide,record=report))
   }
  }
 }
 if(cfg$legend_position %in% c("lower-left","lower-right"))stop("Requested lower-corner legend cannot fit safely at fixed readable size; request top/right or an explicitly larger canvas.",call.=FALSE)
 list(grob=NULL,record=report)
}

# Keep the guide's line convention identical to explicitly focused profiles.
radar_model_guides <- function(cfg, columns) {
 line_types<-ifelse(length(cfg$focus_models)>0L & !cfg$model_order %in% cfg$focus_models,"dashed","solid")
 guides(color=guide_legend(ncol=columns,byrow=TRUE,override.aes=list(linetype=line_types)),
   shape=guide_legend(ncol=columns,byrow=TRUE))
}

# External guides stay unframed and use measured native key/text widths.
radar_external_legend <- function(plot,cfg,n_models,position="top") {
 candidates<-if(position=="right")1L else rev(seq_len(n_models))
 for(nc in candidates) {
  candidate<-plot+radar_model_guides(cfg,nc)+
   theme(legend.position=position,legend.background=element_blank())
  grob<-radar_plot_grob(candidate);guide<-grob$grobs[[which(grob$layout$name==paste0("guide-box-",position))]]
  width<-grid::convertWidth(grid::grobWidth(guide),"mm",valueOnly=TRUE)
  height<-grid::convertHeight(grid::grobHeight(guide),"mm",valueOnly=TRUE)
  if(width+2*cfg$legend_clearance_mm<=cfg$width_mm)return(list(plot=candidate,columns=nc,guide_mm=c(width=width,height=height)))
 }
 stop("Model legend labels cannot fit the requested canvas at fixed readable Arial size; increase width_mm or supply authorized shorter model_labels.",call.=FALSE)
}

radar_draw <- function(plot,legend,cfg) {
 grid::grid.newpage();grid::grid.draw(radar_plot_grob(plot))
 if(!is.null(legend$grob)) {
  box<-legend$record$box_mm
  grid::pushViewport(grid::viewport(x=grid::unit(mean(box[1:2]),"mm"),y=grid::unit(mean(box[3:4]),"mm"),width=grid::unit(diff(box[1:2]),"mm"),height=grid::unit(diff(box[3:4]),"mm")))
  grid::grid.draw(legend$grob);grid::upViewport()
 }
}

radar_segment_hits <- function(a,b,box) {
 lo<-0;hi<-1
 for(j in 1:2) {
  limits<-if(j==1)box[c("left","right")]else box[c("bottom","top")]
  delta<-b[j]-a[j]
  if(abs(delta)<1e-12){if(a[j]<limits[1] || a[j]>limits[2])return(FALSE)}else{
   t<-(limits-a[j])/delta;lo<-max(lo,min(t));hi<-min(hi,max(t));if(lo>hi)return(FALSE)
  }
 }
 TRUE
}

radar_place_values <- function(values,points,paths,widths,heights,reserved,cfg,radius_mm,canvas) {
 output<-values;placed<-list()
 for(i in seq_len(nrow(values))) {
  radial<-c(cos(values$angle[i]),sin(values$angle[i]));tangent<-c(-radial[2],radial[1])
  point_index<-which(as.character(points$model)==as.character(values$model[i]) & points$axis==values$axis[i])
  radar_assert(length(point_index)==1L,"Every annotation must match one established model-axis vertex.")
  point<-points[point_index,c("x","y")]
  anchor<-as.numeric(point)
  minimum<-(abs(radial[1])*widths[i]+abs(radial[2])*heights[i])/2+cfg$point_size/2+cfg$value_clearance_mm
  base<-max(cfg$value_offset*radius_mm,minimum)
  sides<-switch(cfg$value_position,auto=c(-1,1),inside=-1,outside=1)
  custom<-if(is.null(cfg$value_offsets))numeric()else unlist(cfg$value_offsets)
  if(as.character(values$model[i]) %in% names(custom)){base<-abs(custom[[as.character(values$model[i])]])*radius_mm;sides<-sign(custom[[as.character(values$model[i])]])}
  candidates<-expand.grid(tangent=c(0,.8,-.8,1.6,-1.6,2.4,-2.4),extra=c(0,.5,1,1.8,2.8),side=sides)
  accepted<-NULL
  for(k in seq_len(nrow(candidates))) {
   candidate<-candidates[k,];shift<-candidate$side*(base+candidate$extra)
   if(values$radius[i]*radius_mm+shift<0)next
   center<-unname(anchor+shift*radial+candidate$tangent*tangent)
   box<-setNames(c(center[1]-unname(widths[i])/2,center[1]+unname(widths[i])/2,center[2]-unname(heights[i])/2,center[2]+unname(heights[i])/2),c("left","right","bottom","top"))
   expanded<-box+c(-.18,.18,-.18,.18)
   if(box["left"]<.7 || box["right"]>canvas[1]-.7 || box["bottom"]<.7 || box["top"]>canvas[2]-.7)next
   collisions<-FALSE
   for(rect in c(reserved,placed))if(expanded["left"]<=rect["right"] && expanded["right"]>=rect["left"] && expanded["bottom"]<=rect["top"] && expanded["top"]>=rect["bottom"]){collisions<-TRUE;break}
   if(collisions)next
   nearest_x<-pmax(expanded["left"],pmin(points$x,expanded["right"]));nearest_y<-pmax(expanded["bottom"],pmin(points$y,expanded["top"]))
   if(any((points$x-nearest_x)^2+(points$y-nearest_y)^2<=(cfg$point_size/2+.15)^2))next
   if(any(vapply(paths,function(path)radar_segment_hits(path[1:2],path[3:4],expanded),logical(1))))next
   accepted<-list(center=center,box=box,shift=shift,tangent=candidate$tangent);break
  }
  if(is.null(accepted))stop("Selected raw-value labels cannot clear model paths, symbols and other labels at this print size. Increase dimensions, select fewer value_models or refine explicit label offsets.",call.=FALSE)
  output$physical_x[i]<-accepted$center[1];output$physical_y[i]<-accepted$center[2]
  output$offset[i]<-accepted$shift/radius_mm;output$tangential_offset_mm[i]<-accepted$tangent
  output$effective_position[i]<-if(accepted$shift<0)"inside"else"outside"
  placed[[i]]<-accepted$box
 }
 list(data=output,boxes=placed)
}

radar_caption_width <- function(text, size_pt, face="plain") {
 grid::convertWidth(grid::grobWidth(grid::textGrob(text,gp=grid::gpar(fontfamily="Arial",fontface=face,fontsize=size_pt))),"mm",valueOnly=TRUE)
}

radar_wrap_caption <- function(caption, width_mm, size_pt) {
 if(is.null(caption))return(list(text=NULL,lines=character(),widths_mm=numeric(),available_width_mm=width_mm))
 radar_assert(radar_string(caption), "caption must be one nonempty string or null.")
 radar_assert(is.numeric(width_mm) && length(width_mm)==1L && is.finite(width_mm) && width_mm>.3, "Caption has no usable physical width.")
 # Measure the actual Arial grob on the active export device. Preserve explicit
 # paragraph boundaries; do not split, abbreviate or discard scientific words.
 paragraphs<-strsplit(paste0(caption,"\n"),"\n",fixed=TRUE)[[1]]
 lines<-character()
 for(paragraph in paragraphs) {
  if(!nzchar(trimws(paragraph))){lines<-c(lines,"");next}
  words<-strsplit(trimws(paragraph),"[[:space:]]+")[[1]]
  current<-""
  for(word in words) {
   if(radar_caption_width(word,size_pt)+.3>width_mm)stop("Caption contains an unbreakable word that cannot fit at the requested dimensions; increase width_mm or provide an authorized shorter caption.",call.=FALSE)
   candidate<-if(nzchar(current))paste(current,word)else word
   if(nzchar(current) && radar_caption_width(candidate,size_pt)+.3>width_mm){lines<-c(lines,current);current<-word}else current<-candidate
  }
  lines<-c(lines,current)
 }
 measured<-vapply(lines,radar_caption_width,numeric(1),size_pt=size_pt)
 list(text=paste(lines,collapse="\n"),lines=lines,widths_mm=measured,available_width_mm=width_mm)
}

radar_prepare <- function(raw, cfg) {
 radar_assert(identical(cfg$data_mode,"summary"), "Radar input must be summary: exactly one established value per model and axis. Prepare any scientifically authorized aggregation separately.")
 radar_assert(identical(cfg$plot_type,"radar-comparison"), "plot_type must be radar-comparison.")
 cols<-c(cfg$model,cfg$axis,cfg$value)
 radar_assert(length(cols)==3L && all(vapply(as.list(cols),radar_string,logical(1))) && !anyDuplicated(cols), "model, axis and value must name three distinct columns.")
 radar_assert(all(cols %in% names(raw)), "Input lacks a mapped model, axis or value column.")
 radar_assert(nrow(raw)>0L, "Input has no rows.")
 dat<-data.frame(source_row=seq_len(nrow(raw)),model=as.character(raw[[cfg$model]]),axis=as.character(raw[[cfg$axis]]),raw_value=raw[[cfg$value]],stringsAsFactors=FALSE)
 radar_assert(!anyNA(dat$model) && !anyNA(dat$axis) && all(nzchar(trimws(dat$model))) && all(nzchar(trimws(dat$axis))), "Model and axis identities must be nonmissing strings.")
 radar_assert(is.numeric(dat$raw_value) && all(is.finite(dat$raw_value)), "Values must be numeric and finite. Missing values are not excluded or imputed.")
 radar_assert(!anyDuplicated(dat[c("model","axis")]), "Duplicate model-axis summaries: establish aggregation before rendering; no averaging is performed.")
 axes<-cfg$axis_order
 radar_assert(is.character(axes) && length(axes)>=3L && !anyNA(axes) && !anyDuplicated(axes) && setequal(axes,unique(dat$axis)), "axis_order must explicitly list every observed axis exactly once (at least three axes).")
 models<-if(is.null(cfg$model_order))unique(dat$model)else cfg$model_order
 radar_assert(is.character(models) && length(models)>=1L && !anyNA(models) && !anyDuplicated(models) && setequal(models,unique(dat$model)), "model_order must list every observed model exactly once.")
 radar_assert(nrow(dat)==length(models)*length(axes), "Every model must have a value on every ordered axis. Incomplete profiles cannot be closed without inventing values.")
 radar_assert(cfg$scale_mode %in% c("common-domain","per-axis-domain"), "scale_mode must be common-domain or per-axis-domain.")
 if(cfg$scale_mode=="common-domain") {
  radar_assert(radar_domain(cfg$metric_domain), "common-domain requires an established increasing two-number metric_domain; never infer it from observed extrema.")
  radar_assert(radar_string(cfg$unit), "common-domain requires a declared common unit, including unitless when appropriate.")
  radar_assert(cfg$direction %in% c("higher","lower"), "direction must be higher or lower.")
  radar_assert(is.null(cfg$axis_specs), "axis_specs is only valid with per-axis-domain; mixed domains require explicit normalization.")
  specs<-setNames(lapply(axes,function(a)list(domain=cfg$metric_domain,unit=cfg$unit,direction=cfg$direction)),axes)
 } else {
  radar_assert(radar_string(cfg$normalization_reason), "per-axis-domain requires normalization_reason explaining the scientific comparability of declared domain scaling.")
  radar_assert(is.list(cfg$axis_specs) && !is.null(names(cfg$axis_specs)) && !anyDuplicated(names(cfg$axis_specs)) && setequal(names(cfg$axis_specs),axes), "axis_specs must name every axis exactly once with domain, unit and direction.")
  specs<-cfg$axis_specs[axes]
  for(a in axes) {
   s<-specs[[a]]
   radar_assert(is.list(s) && all(c("domain","unit","direction") %in% names(s)) && radar_domain(s$domain) && radar_string(s$unit) && s$direction %in% c("higher","lower"), paste0("Invalid axis_specs for ",a,"; require increasing domain, unit and higher/lower direction."))
  }
 }
 dat$axis_index<-match(dat$axis,axes)
 dat$model_index<-match(dat$model,models)
 dat<-dat[order(dat$model_index,dat$axis_index),,drop=FALSE]
 dat$domain_min<-vapply(dat$axis,function(a)specs[[a]]$domain[1],numeric(1))
 dat$domain_max<-vapply(dat$axis,function(a)specs[[a]]$domain[2],numeric(1))
 dat$unit<-vapply(dat$axis,function(a)specs[[a]]$unit,character(1))
 dat$direction<-vapply(dat$axis,function(a)specs[[a]]$direction,character(1))
 radar_assert(all(dat$raw_value>=dat$domain_min & dat$raw_value<=dat$domain_max), "Values lie outside a declared scientific domain; no clipping or domain expansion is performed.")
 dat$domain_fraction<-(dat$raw_value-dat$domain_min)/(dat$domain_max-dat$domain_min)
 dat$radius<-ifelse(dat$direction=="higher",dat$domain_fraction,1-dat$domain_fraction)
 radar_assert(is.numeric(cfg$start_angle) && length(cfg$start_angle)==1L && is.finite(cfg$start_angle), "start_angle must be finite degrees.")
 radar_assert(is.logical(cfg$clockwise) && length(cfg$clockwise)==1L && !is.na(cfg$clockwise), "clockwise must be true or false.")
 angles<-(cfg$start_angle+if(cfg$clockwise)-360*(seq_along(axes)-1)/length(axes)else 360*(seq_along(axes)-1)/length(axes))*pi/180
 dat$angle<-angles[dat$axis_index]; dat$x<-dat$radius*cos(dat$angle); dat$y<-dat$radius*sin(dat$angle)
 rownames(dat)<-NULL
 list(data=dat,axes=axes,models=models,specs=specs,angles=angles)
}

radar_main <- function(script_path, args) {
 skill_dir<-dirname(dirname(normalizePath(script_path,mustWork=TRUE)))
 cache_root<-Sys.getenv("XDG_CACHE_HOME",unset=path.expand("~/.cache"))
 .libPaths(c(file.path(Sys.getenv("PAPER_FIGURES_CACHE",file.path(cache_root,"paper-results-figures")),"library"),.libPaths()))
 suppressPackageStartupMessages(library(ggplot2))
 for(helper in c("formatting.R","palette_helpers.R","paper_layout.R","font_export.R","text_fit.R"))source(file.path(skill_dir,"scripts",helper))
 radar_assert(length(args)==1L, "Supply one JSON configuration path.")
 config_path<-normalizePath(args[1],mustWork=TRUE)
 user<-jsonlite::fromJSON(config_path,simplifyVector=TRUE,simplifyDataFrame=FALSE)
 defaults<-radar_defaults()
 radar_assert(!length(setdiff(names(user),names(defaults))), paste0("Unknown keys: ",paste(setdiff(names(user),names(defaults)),collapse=", ")))
 cfg<-utils::modifyList(defaults,user,keep.null=TRUE)
 resolve<-function(p){p<-path.expand(p);if(!grepl("^/",p))p<-file.path(dirname(config_path),p);normalizePath(p,mustWork=FALSE)}
 radar_assert(radar_string(cfg$input) && radar_string(cfg$output_prefix), "input and output_prefix are required.")
 cfg$input<-normalizePath(resolve(cfg$input),mustWork=TRUE);cfg$output_prefix<-resolve(cfg$output_prefix)
 nm<-basename(cfg$output_prefix);if(basename(dirname(cfg$output_prefix))!=nm)cfg$output_prefix<-file.path(dirname(cfg$output_prefix),nm,nm)
 cfg<-resolve_paper_dimensions(cfg,user,default_height_mm=54)
 radar_assert(is.character(cfg$formats) && length(cfg$formats)>0L && !anyDuplicated(cfg$formats) && all(cfg$formats %in% c("pdf","svg","png")), "formats must select pdf, svg and/or png without duplicates.")
 for(k in c("line_width","point_size","grid_width","value_size","value_clearance_mm","base_size","title_size","axis_text_size","legend_text_size","legend_clearance_mm","dpi"))radar_assert(is.numeric(cfg[[k]]) && length(cfg[[k]])==1L && is.finite(cfg[[k]]) && cfg[[k]]>0,paste("Invalid positive setting:",k))
 for(k in c("show_values","show_polygons"))radar_assert(is.logical(cfg[[k]]) && length(cfg[[k]])==1L && !is.na(cfg[[k]]),paste(k,"must be true or false."))
 radar_assert(is.null(cfg$show_radial_labels) || (is.logical(cfg$show_radial_labels) && length(cfg$show_radial_labels)==1L && !is.na(cfg$show_radial_labels)), "show_radial_labels must be null, true or false.")
 radar_assert(cfg$radial_label_policy %in% c("endpoints","all","none"), "radial_label_policy must be endpoints, all or none.")
 radial_policy<-if(is.null(cfg$show_radial_labels))cfg$radial_label_policy else if(cfg$show_radial_labels)"all"else"none"
 radar_assert(cfg$grid_style %in% c("circular","circular-bands","polygon"), "grid_style must be circular, circular-bands or polygon.")
 radar_assert(cfg$legend_position %in% c("auto","top","right","lower-left","lower-right"), "legend_position must be auto, top, right, lower-left or lower-right.")
 automatic_legend<-cfg$legend_position %in% c("auto","lower-left","lower-right")
 external_legend_position<-if(automatic_legend)"none"else cfg$legend_position
 radar_assert(cfg$value_position %in% c("auto","inside","outside"), "value_position must be auto, inside or outside.")
 radar_assert(is.numeric(cfg$value_offset) && length(cfg$value_offset)==1L && is.finite(cfg$value_offset) && cfg$value_offset>=0, "value_offset must be a nonnegative radial fraction.")
 radar_assert(is.character(cfg$band_colors) && length(cfg$band_colors)>0L && !anyNA(cfg$band_colors), "band_colors must list inner-to-outer decorative colors.")
 tryCatch(grDevices::col2rgb(c(cfg$band_colors,cfg$grid_color)),error=function(e)stop("Invalid decorative grid colors.",call.=FALSE))
 header<-names(read.csv(cfg$input,nrows=0,check.names=FALSE))
 text_cols<-intersect(c(cfg$model,cfg$axis),header)
 raw<-read.csv(cfg$input,colClasses=setNames(rep("character",length(text_cols)),text_cols),check.names=FALSE,stringsAsFactors=FALSE)
 prep<-radar_prepare(raw,cfg);dat<-prep$data;axes<-prep$axes;models<-prep$models;angles<-prep$angles
 cfg$axis_order<-axes;cfg$model_order<-models
 if(!is.null(cfg$focus_models))radar_assert(is.character(cfg$focus_models) && length(cfg$focus_models)>0L && !anyDuplicated(cfg$focus_models) && all(cfg$focus_models %in% models), "focus_models must explicitly select distinct observed model identities.")
 labels<-function(keys,map){if(is.null(map))return(keys);map<-unlist(map);radar_assert(!is.null(names(map)) && all(keys %in% names(map)) && all(nzchar(map[keys])), "Label maps must cover all identities with nonempty labels.");unname(map[keys])}
 model_labels<-labels(models,cfg$model_labels);axis_labels<-labels(axes,cfg$axis_labels)
 palettes<-jsonlite::fromJSON(file.path(skill_dir,"palettes/palettes.json"));pal<-palettes[[cfg$palette]]
 radar_assert(!is.null(pal), "Unknown palette.")
 if(is.null(cfg$fill_alpha))cfg$fill_alpha<-pal$fill_alpha
 for(k in c("fill_alpha","line_alpha","band_alpha"))radar_assert(is.numeric(cfg[[k]]) && length(cfg[[k]])==1L && is.finite(cfg[[k]]) && cfg[[k]]>=0 && cfg[[k]]<=1,paste("Invalid alpha:",k))
 color_resolution<-radar_resolve_colors(cfg,models,pal)
 colors<-color_resolution$base;line_colors<-color_resolution$effective
 cfg$color_values<-as.list(colors);cfg$line_color_values<-as.list(line_colors);cfg$palette_mapping<-color_resolution$mapping
 cfg$line_darken<-color_resolution$amount
 shapes<-if(is.null(cfg$shape_values))setNames(rep(c(16,17,18,15,3,8,1,2,5,0),length.out=length(models)),models)else unlist(cfg$shape_values)[models]
 radar_assert(length(shapes)==length(models) && !anyNA(shapes) && all(shapes %in% 0:25), "shape_values must cover every model with integer shape codes 0 to 25.")
 cfg$shape_values<-as.list(shapes)
 if(!is.null(cfg$value_models))radar_assert(is.character(cfg$value_models) && all(cfg$value_models %in% models), "value_models must select observed model identities.")
 if(cfg$show_values)radar_assert(is.character(cfg$value_models) && length(cfg$value_models)>0L && !anyDuplicated(cfg$value_models), "show_values requires explicit value_models; select the scientific comparison before displaying raw labels.")
 if(!is.null(cfg$value_offsets)) {
  offsets<-unlist(cfg$value_offsets)
  radar_assert(is.numeric(offsets) && !is.null(names(offsets)) && !anyDuplicated(names(offsets)) && all(names(offsets) %in% models) && all(is.finite(offsets)), "value_offsets must be a finite named model map of signed radial fractions.")
 }
 faces<-resolve_arial_fonts()
 # Calculate all labels and bounds in physical Arial units before plotting.
 widths<-systemfonts::string_width(axis_labels,family="Arial",size=cfg$axis_text_size,res=72)*25.4/72
 legend_widths<-systemfonts::string_width(model_labels,family="Arial",size=cfg$legend_text_size,res=72)*25.4/72+8
 legend_cols<-if(cfg$legend_position=="right")1L else max(1L,min(length(models),floor((cfg$width_mm-3)/max(legend_widths))))
 text_height_mm<-cfg$axis_text_size*25.4/72
 ring_labels<-data.frame(x=1.08*cos(angles),y=1.08*sin(angles),label=axis_labels)
 ring_labels$hjust<-ifelse(cos(angles)>.15,0,ifelse(cos(angles)< -.15,1,.5))
 ring_labels$vjust<-ifelse(sin(angles)>.15,0,ifelse(sin(angles)< -.15,1,.5))
 # Reserve horizontal text space rather than clipping long category labels.
 available_width<-cfg$width_mm-3
 available_height<-cfg$height_mm-5-if(automatic_legend)0 else ceiling(length(models)/legend_cols)*(cfg$legend_text_size*25.4/72*1.4+1)
 available_height<-available_height-if(is.null(cfg$title))0 else cfg$title_size*25.4/72*1.5
 # Captions and the complete legend/title are outside the fixed-aspect panel.
 available_height<-available_height-3
 radius_mm<-min(available_width,available_height)/2.2
 for(iteration in seq_len(40)) {
  bounds<-c(min(-1.05,ring_labels$x-widths/radius_mm*ring_labels$hjust),max(1.05,ring_labels$x+widths/radius_mm*(1-ring_labels$hjust)),min(-1.05,ring_labels$y-text_height_mm/radius_mm*ring_labels$vjust),max(1.05,ring_labels$y+text_height_mm/radius_mm*(1-ring_labels$vjust)))
  next_radius<-min(available_width/diff(bounds[1:2]),available_height/diff(bounds[3:4]))
  if(!is.finite(next_radius) || next_radius<7)stop("Axis labels leave too little radial panel at this size. Increase width_mm/height_mm or supply authorized shorter axis_labels.",call.=FALSE)
  if(abs(next_radius-radius_mm)<.001)break
  radius_mm<-next_radius
 }
 bounds<-bounds+c(-.03,.03,-.03,.03)
 # Bound resolution is adaptive; axis labels remain at the same readable font size.
 if(is.null(cfg$radial_breaks))cfg$radial_breaks<-if(cfg$scale_mode=="common-domain")seq(cfg$metric_domain[1],cfg$metric_domain[2],length.out=5)else seq(0,1,length.out=5)
 radar_assert(is.numeric(cfg$radial_breaks) && length(cfg$radial_breaks)>=2L && all(is.finite(cfg$radial_breaks)) && !anyDuplicated(cfg$radial_breaks) && all(diff(cfg$radial_breaks)>0), "radial_breaks must be distinct increasing finite numbers.")
 tick_values<-cfg$radial_breaks
 tick_radius<-if(cfg$scale_mode=="common-domain")(tick_values-cfg$metric_domain[1])/diff(cfg$metric_domain)else tick_values
 if(cfg$scale_mode=="common-domain" && cfg$direction=="lower")tick_radius<-1-tick_radius
 radar_assert(all(tick_radius>=0 & tick_radius<=1), "radial_breaks lie outside the declared radial domain.")
 circle_angles<-seq(0,2*pi,length.out=361)
 guide_angles<-if(cfg$grid_style %in% c("circular","circular-bands"))circle_angles else c(angles,angles[1])
 # Always draw the declared perimeter, even when requested guide breaks omit it.
 grid_radii<-sort(unique(c(tick_radius,1)))
 rings<-do.call(rbind,lapply(seq_along(grid_radii),function(i)data.frame(x=grid_radii[i]*cos(guide_angles),y=grid_radii[i]*sin(guide_angles),ring=i,
   line_type=if(cfg$grid_style=="circular" && grid_radii[i]<1)"dashed"else"solid")))
 spokes<-data.frame(x=0,y=0,xend=cos(angles),yend=sin(angles))
 # Use a between-spoke guide to separate tick text from model vertices.
 guide_angle<-angles[1]+if(cfg$clockwise)-pi/length(axes)else pi/length(axes)
 ticks<-data.frame(x=tick_radius*cos(guide_angle),y=tick_radius*sin(guide_angle),label=format_axis_ticks(tick_values))
 if(radial_policy=="endpoints"){
  endpoint_values<-if(cfg$scale_mode=="common-domain")cfg$metric_domain else c(0,1)
  endpoint_radii<-if(cfg$scale_mode=="common-domain")(endpoint_values-cfg$metric_domain[1])/diff(cfg$metric_domain)else endpoint_values
  if(cfg$scale_mode=="common-domain" && cfg$direction=="lower")endpoint_radii<-1-endpoint_radii
  ticks<-data.frame(x=endpoint_radii*cos(guide_angle),y=endpoint_radii*sin(guide_angle),label=format_axis_ticks(endpoint_values))
 }
 dat$model<-factor(dat$model,levels=models)
 draw_models<-c(setdiff(models,cfg$focus_models),intersect(models,cfg$focus_models))
 polygons<-do.call(rbind,lapply(draw_models,function(m){d<-dat[dat$model==m,,drop=FALSE];rbind(d,d[1,,drop=FALSE])}))
 p<-ggplot()
 band_radii<-sort(unique(c(0,tick_radius,1)))
 band_map<-NULL
 if(cfg$grid_style=="circular-bands") {
  n_bands<-length(band_radii)-1L
  color_slots<-if(n_bands==1L)length(cfg$band_colors)else round(seq(1,length(cfg$band_colors),length.out=n_bands))
  band_map<-data.frame(inner=head(band_radii,-1),outer=tail(band_radii,-1),color=cfg$band_colors[color_slots])
  for(i in seq_len(n_bands)) {
   band<-data.frame(x=c(band_map$outer[i]*cos(circle_angles),band_map$inner[i]*cos(rev(circle_angles))),y=c(band_map$outer[i]*sin(circle_angles),band_map$inner[i]*sin(rev(circle_angles))))
   p<-p+geom_polygon(data=band,aes(x=x,y=y),fill=band_map$color[i],alpha=cfg$band_alpha,color=NA)
  }
 }
 p<-p+geom_path(data=rings,aes(x=x,y=y,group=ring,linetype=I(line_type)),color=cfg$grid_color,linewidth=cfg$grid_width)+
  geom_segment(data=spokes,aes(x=x,y=y,xend=xend,yend=yend),color=cfg$grid_color,linewidth=cfg$grid_width)
 if(cfg$show_polygons)p<-p+geom_polygon(data=polygons,aes(x=x,y=y,group=model,fill=model),alpha=cfg$fill_alpha,color=NA,show.legend=FALSE)
 # Explicitly selected focal profiles draw last. This changes only layer order
 # and solid/dashed emphasis, never palette assignments, values or radii.
 for(m in draw_models){
  p<-p+geom_path(data=polygons[polygons$model==m,,drop=FALSE],aes(x=x,y=y,color=model,group=model),linewidth=cfg$line_width,alpha=cfg$line_alpha,
    linetype=if(length(cfg$focus_models) && !m %in% cfg$focus_models)"dashed"else"solid",show.legend=FALSE)+
   geom_point(data=dat[dat$model==m,,drop=FALSE],aes(x=x,y=y,color=model,shape=model),size=cfg$point_size,alpha=cfg$line_alpha,show.legend=FALSE)
 }
 # A single mapped layer supplies the combined model guide independently of
 # foreground draw order; no scientific observation is duplicated visually.
 legend_keys<-data.frame(model=factor(models,levels=models),x=NA_real_,y=NA_real_)
 p<-p+geom_path(data=legend_keys,aes(x=x,y=y,color=model,group=model),linewidth=cfg$line_width,alpha=cfg$line_alpha,na.rm=TRUE,show.legend=TRUE)+
  geom_point(data=legend_keys,aes(x=x,y=y,color=model,shape=model),size=cfg$point_size,alpha=cfg$line_alpha,na.rm=TRUE,show.legend=TRUE)+
  geom_text(data=ring_labels,aes(x=x,y=y,label=label,hjust=hjust,vjust=vjust),family="Arial",size=cfg$axis_text_size/ggplot2::.pt,color="#222222")+
  scale_color_manual(values=line_colors,breaks=models,labels=model_labels,name=NULL)+
  scale_shape_manual(values=shapes,breaks=models,labels=model_labels,name=NULL)+
  coord_fixed(xlim=bounds[1:2],ylim=bounds[3:4],expand=FALSE,clip="off")+
  theme_void(base_family="Arial",base_size=cfg$base_size)+
  theme(legend.position=external_legend_position,legend.text=element_text(family="Arial",size=cfg$legend_text_size,color="#222222"),legend.key.width=grid::unit(3.0,"mm"),legend.key.height=grid::unit(1.8,"mm"),legend.spacing.x=grid::unit(.3,"mm"),legend.margin=margin(0,0,1,0),legend.box.margin=margin(0,0,0,0),plot.margin=margin(2,2,2,2),plot.title=element_text(family="Arial",size=cfg$title_size,hjust=.5,margin=margin(b=2),color="#222222"),plot.caption=element_text(family="Arial",size=cfg$axis_text_size*.9,hjust=.5,margin=margin(t=2),color="#222222"),plot.tag=element_text(family="Arial",face="bold",size=9),plot.tag.position="topleft")+
  radar_model_guides(cfg,legend_cols)
 if(cfg$show_polygons)p<-p+scale_fill_manual(values=colors)
 if(radial_policy!="none")p<-p+geom_text(data=ticks,aes(x=x,y=y,label=label),family="Arial",size=cfg$axis_text_size*.78/ggplot2::.pt,color="#69716C")
 value_data<-NULL
 if(cfg$show_values){
  vd<-dat[dat$model %in% cfg$value_models,,drop=FALSE]
  vd$offset<-if(cfg$value_position %in% c("auto","inside"))-cfg$value_offset else cfg$value_offset
  if(!is.null(cfg$value_offsets)){custom<-unlist(cfg$value_offsets);changed<-as.character(vd$model) %in% names(custom);vd$offset[changed]<-custom[as.character(vd$model[changed])]}
  vd$label_radius<-pmax(0,vd$radius+vd$offset)
  vd$x<-vd$label_radius*cos(vd$angle);vd$y<-vd$label_radius*sin(vd$angle)
  value_data<-vd
  p<-p+geom_text(data=vd,aes(x=x,y=y,color=model,label=sprintf("%.3f",raw_value)),family="Arial",size=cfg$value_size,show.legend=FALSE)
  value_layer_index<-length(p$layers)
 }
 caption<-cfg$caption
 if(cfg$scale_mode=="common-domain" && is.null(caption))caption<-cfg$unit
 if(cfg$scale_mode=="per-axis-domain")caption<-paste(c("Domain-scaled score; outward = better",caption),collapse="\n")
 if(cfg$scale_mode=="common-domain" && cfg$direction=="lower")caption<-paste(c("Reversed radial scale; outward = lower",caption),collapse="\n")
 original_caption<-caption
 p<-p+labs(title=cfg$title,tag=cfg$panel_tag)
 dir.create(dirname(cfg$output_prefix),recursive=TRUE,showWarnings=FALSE)
 output_paths<-paste0(cfg$output_prefix,".",cfg$formats)
 radar_assert(!cfg$input %in% c(output_paths,paste0(cfg$output_prefix,c(".plotted-data.csv",".config.json",".statistics.json",".session.txt"))), "Output would overwrite input.")
 # Resolve outer labels against the real fixed-aspect panel, including all
 # title, caption and legend rows, on an Arial-capable device at export size.
 layout_path<-tempfile("radar-layout-",tmpdir=dirname(cfg$output_prefix),fileext=".pdf")
 arial_pdf_device(layout_path,width=cfg$width,height=cfg$height,bg="white")
 measured_panel_mm<-NULL;axis_label_bounds_mm<-NULL;caption_bounds_mm<-NULL;value_label_bounds_mm<-NULL
 legend_result<-list(grob=NULL,record=list(requested=cfg$legend_position,placement=cfg$legend_position,framed=FALSE,reason="Explicit external legend placement."))
 tryCatch({
  caption_fit<-radar_wrap_caption(original_caption,cfg$width_mm-2*1.2,cfg$axis_text_size*.9)
  caption<-caption_fit$text
  p<-p+labs(caption=caption)
  # Low-resolution glyph advances can underestimate long small-print labels.
  # Use each actual text grob on the final-size Arial PDF device instead.
  widths<-vapply(axis_labels,function(label)grid::convertWidth(grid::grobWidth(grid::textGrob(label,gp=grid::gpar(fontfamily="Arial",fontsize=cfg$axis_text_size))),"mm",valueOnly=TRUE),numeric(1))
  text_height_mm<-max(vapply(axis_labels,function(label)grid::convertHeight(grid::grobHeight(grid::textGrob(label,gp=grid::gpar(fontfamily="Arial",fontsize=cfg$axis_text_size))),"mm",valueOnly=TRUE),numeric(1)))
  if(cfg$show_values) {
   value_labels<-sprintf("%.3f",value_data$raw_value)
   value_widths<-vapply(value_labels,radar_caption_width,numeric(1),size_pt=cfg$value_size*ggplot2::.pt)
   value_heights<-vapply(value_labels,function(label)grid::convertHeight(grid::grobHeight(grid::textGrob(label,gp=grid::gpar(fontfamily="Arial",fontsize=cfg$value_size*ggplot2::.pt))),"mm",valueOnly=TRUE),numeric(1))
  }
  if(!automatic_legend) {
   external_fit<-radar_external_legend(p,cfg,length(models),cfg$legend_position)
   p<-external_fit$plot;legend_cols<-external_fit$columns
   legend_result$record$guide_mm<-external_fit$guide_mm;legend_result$record$columns<-legend_cols
  }
  for(legend_pass in seq_len(if(automatic_legend)2L else 1L)) {
  for(iteration in seq_len(20)) {
   grob<-radar_plot_grob(p);grid::grid.newpage();grid::grid.draw(grob);grid::grid.force()
   canvas_margin_mm<-.7
   if(length(caption_fit$lines)) {
    caption_loc<-grob$layout[grob$layout$name=="caption",,drop=FALSE]
    grid::seekViewport(paste0("caption.",caption_loc$t,"-",caption_loc$l,"-",caption_loc$b,"-",caption_loc$r))
    caption_center<-grid::deviceLoc(grid::unit(.5,"npc"),grid::unit(.5,"npc"),valueOnly=TRUE)$x*25.4
    grid::upViewport(0)
    caption_bounds_mm<-data.frame(line=caption_fit$lines,left=caption_center-caption_fit$widths_mm/2-.15,right=caption_center+caption_fit$widths_mm/2+.15)
    caption_available<-2*min(caption_center-canvas_margin_mm,cfg$width_mm-canvas_margin_mm-caption_center)
    if(min(caption_bounds_mm$left)<canvas_margin_mm || max(caption_bounds_mm$right)>cfg$width_mm-canvas_margin_mm) {
     caption_fit<-radar_wrap_caption(original_caption,min(caption_fit$available_width_mm,caption_available),cfg$axis_text_size*.9)
     caption<-caption_fit$text;p<-p+labs(caption=caption)
     next
    }
   }
   loc<-grob$layout[grob$layout$name=="panel",,drop=FALSE]
   viewport_name<-paste0("panel.",loc$t,"-",loc$l,"-",loc$b,"-",loc$r)
   grid::seekViewport(viewport_name)
   measured_panel_mm<-c(width=grid::convertWidth(grid::unit(1,"npc"),"mm",valueOnly=TRUE),height=grid::convertHeight(grid::unit(1,"npc"),"mm",valueOnly=TRUE))
   actual_radius<-min(measured_panel_mm[1]/diff(bounds[1:2]),measured_panel_mm[2]/diff(bounds[3:4]))
   panel_origin<-grid::deviceLoc(grid::unit(0,"npc"),grid::unit(0,"npc"),valueOnly=TRUE)
   circle_center<-c(panel_origin$x*25.4-bounds[1]/diff(bounds[1:2])*measured_panel_mm[1],panel_origin$y*25.4-bounds[3]/diff(bounds[3:4])*measured_panel_mm[2])
   if(cfg$show_values) {
    origins<-grid::deviceLoc(grid::unit(0,"npc"),grid::unit(0,"npc"),valueOnly=TRUE)
    points<-dat[c("model","axis")];points$x<-(dat$x-bounds[1])/diff(bounds[1:2])*measured_panel_mm[1]+origins$x*25.4;points$y<-(dat$y-bounds[3])/diff(bounds[3:4])*measured_panel_mm[2]+origins$y*25.4
    paths<-list()
    for(m in models){mp<-points[points$model==m,c("x","y")];mp<-rbind(mp,mp[1,]);for(j in seq_len(nrow(mp)-1))paths[[length(paths)+1L]]<-c(unlist(mp[j,]),unlist(mp[j+1,]))}
    reserved<-list()
    axis_pos<-grid::deviceLoc(grid::unit((ring_labels$x-bounds[1])/diff(bounds[1:2]),"npc"),grid::unit((ring_labels$y-bounds[3])/diff(bounds[3:4]),"npc"),valueOnly=TRUE)
    for(j in seq_along(axes))reserved[[length(reserved)+1L]]<-setNames(unname(c(axis_pos$x[j]*25.4-widths[j]*ring_labels$hjust[j],axis_pos$x[j]*25.4+widths[j]*(1-ring_labels$hjust[j]),axis_pos$y[j]*25.4-text_height_mm*ring_labels$vjust[j],axis_pos$y[j]*25.4+text_height_mm*(1-ring_labels$vjust[j]))),c("left","right","bottom","top"))
    if(radial_policy!="none")for(j in seq_len(nrow(ticks))){center<-grid::deviceLoc(grid::unit((ticks$x[j]-bounds[1])/diff(bounds[1:2]),"npc"),grid::unit((ticks$y[j]-bounds[3])/diff(bounds[3:4]),"npc"),valueOnly=TRUE);tw<-radar_caption_width(ticks$label[j],cfg$axis_text_size*.78);th<-cfg$axis_text_size*.78*25.4/72;reserved[[length(reserved)+1L]]<-c(left=center$x*25.4-tw/2,right=center$x*25.4+tw/2,bottom=center$y*25.4-th/2,top=center$y*25.4+th/2)}
    fitted_values<-radar_place_values(value_data,points,paths,value_widths,value_heights,reserved,cfg,actual_radius,c(cfg$width_mm,cfg$height_mm));vd<-fitted_values$data
    vd$x<-bounds[1]+(vd$physical_x-origins$x*25.4)/measured_panel_mm[1]*diff(bounds[1:2]);vd$y<-bounds[3]+(vd$physical_y-origins$y*25.4)/measured_panel_mm[2]*diff(bounds[3:4])
    vd$label_radius<-sqrt(vd$x^2+vd$y^2)
    changed<-max(abs(vd$x-value_data$x),abs(vd$y-value_data$y))>.001
    value_data<-vd
    if(changed){grid::upViewport(0);p$layers[[value_layer_index]]$data<-vd;next}
   }
   positions<-grid::deviceLoc(grid::unit((ring_labels$x-bounds[1])/diff(bounds[1:2]),"npc"),grid::unit((ring_labels$y-bounds[3])/diff(bounds[3:4]),"npc"),valueOnly=TRUE)
   # Check absolute exported-canvas coordinates, not only the panel's ranges.
   # A little ink/advance-width allowance protects the last glyph at either edge.
   axis_label_bounds_mm<-data.frame(axis=axes,left=positions$x*25.4-widths*ring_labels$hjust-.15,right=positions$x*25.4+widths*(1-ring_labels$hjust)+.15,bottom=positions$y*25.4-text_height_mm*ring_labels$vjust-.15,top=positions$y*25.4+text_height_mm*(1-ring_labels$vjust)+.15)
   content_bounds<-axis_label_bounds_mm[c("left","right","bottom","top")]
   if(cfg$show_values) {
    value_positions<-grid::deviceLoc(grid::unit((value_data$x-bounds[1])/diff(bounds[1:2]),"npc"),grid::unit((value_data$y-bounds[3])/diff(bounds[3:4]),"npc"),valueOnly=TRUE)
    value_label_bounds_mm<-data.frame(model=value_data$model,axis=value_data$axis,label=sprintf("%.3f",value_data$raw_value),left=value_positions$x*25.4-value_widths/2-.15,right=value_positions$x*25.4+value_widths/2+.15,bottom=value_positions$y*25.4-value_heights/2-.15,top=value_positions$y*25.4+value_heights/2+.15)
    content_bounds<-rbind(content_bounds,value_label_bounds_mm[c("left","right","bottom","top")])
   }
   overflow_mm<-pmax(0,c(canvas_margin_mm-min(content_bounds$left),max(content_bounds$right)-(cfg$width_mm-canvas_margin_mm),canvas_margin_mm-min(content_bounds$bottom),max(content_bounds$top)-(cfg$height_mm-canvas_margin_mm)))
   grid::upViewport(0)
   if(actual_radius<7)stop("Measured Arial labels leave too little radial panel; increase width_mm/height_mm or provide authorized shorter labels.",call.=FALSE)
   resolved_bounds<-c(min(-1.05,ring_labels$x-widths/actual_radius*ring_labels$hjust),max(1.05,ring_labels$x+widths/actual_radius*(1-ring_labels$hjust)),min(-1.05,ring_labels$y-text_height_mm/actual_radius*ring_labels$vjust),max(1.05,ring_labels$y+text_height_mm/actual_radius*(1-ring_labels$vjust)))+c(-.03,.03,-.03,.03)
   if(any(overflow_mm>0)) {
    resolved_bounds[1]<-min(resolved_bounds[1],bounds[1]-overflow_mm[1]/actual_radius)
    resolved_bounds[2]<-max(resolved_bounds[2],bounds[2]+overflow_mm[2]/actual_radius)
    resolved_bounds[3]<-min(resolved_bounds[3],bounds[3]-overflow_mm[3]/actual_radius)
    resolved_bounds[4]<-max(resolved_bounds[4],bounds[4]+overflow_mm[4]/actual_radius)
   }
   if(max(abs(resolved_bounds-bounds))<.002 && max(overflow_mm)<.02)break
   bounds<-resolved_bounds
   p<-suppressMessages(p+coord_fixed(xlim=bounds[1:2],ylim=bounds[3:4],expand=FALSE,clip="off"))
  }
  if(automatic_legend && legend_pass==1L) {
   occupied<-as.matrix(content_bounds)
   # Reserve complete tick glyphs, endpoint symbols and all supplied vertices.
   for(j in seq_len(nrow(ticks)))if(radial_policy!="none") {
    center<-circle_center+c(ticks$x[j],ticks$y[j])*actual_radius
    tw<-radar_caption_width(ticks$label[j],cfg$axis_text_size*.78);th<-cfg$axis_text_size*.78*25.4/72
    occupied<-rbind(occupied,c(center[1]-tw/2,center[1]+tw/2,center[2]-th/2,center[2]+th/2))
   }
   mark_radius<-cfg$point_size*.65+.25
   for(j in seq_len(nrow(dat))) {
    center<-circle_center+c(dat$x[j],dat$y[j])*actual_radius
    occupied<-rbind(occupied,c(center[1]-mark_radius,center[1]+mark_radius,center[2]-mark_radius,center[2]+mark_radius))
   }
   for(name in c("title","caption","tag")) {
    text<-switch(name,title=cfg$title,caption=caption,tag=cfg$panel_tag)
    if(is.null(text))next
    slot<-grob$layout[grob$layout$name==name,,drop=FALSE]
    if(!nrow(slot))next
    viewport_matches<-unique(grid::grid.ls(viewports=TRUE,grobs=FALSE,print=FALSE)$name)
    viewport_matches<-viewport_matches[grepl(paste0("^",name,"\\.[0-9]+-"),viewport_matches)]
    radar_assert(length(viewport_matches)==1L,paste("Cannot measure",name,"viewport for radar guide clearance."))
    grid::seekViewport(viewport_matches[1])
    origin<-grid::deviceLoc(grid::unit(0,"npc"),grid::unit(0,"npc"),valueOnly=TRUE)
    row_width<-grid::convertWidth(grid::unit(1,"npc"),"mm",valueOnly=TRUE);row_height<-grid::convertHeight(grid::unit(1,"npc"),"mm",valueOnly=TRUE)
    size<-switch(name,title=cfg$title_size,caption=cfg$axis_text_size*.9,tag=9)
    text_width<-max(vapply(strsplit(text,"\n",fixed=TRUE)[[1]],radar_caption_width,numeric(1),size_pt=size,face=if(name=="tag")"bold"else"plain"))
    cx<-if(name=="tag")origin$x*25.4+text_width/2 else origin$x*25.4+row_width/2
    occupied<-rbind(occupied,c(cx-text_width/2-.15,cx+text_width/2+.15,origin$y*25.4,origin$y*25.4+row_height))
    grid::upViewport(0)
   }
   colnames(occupied)<-c("left","right","bottom","top")
   legend_result<-radar_choose_legend(p,cfg,length(models),c(circle_center,actual_radius+max(cfg$grid_width,cfg$line_width)/2),occupied)
   if(!is.null(legend_result$grob))break
   external_fit<-radar_external_legend(p,cfg,length(models),"top")
   p<-external_fit$plot;legend_cols<-external_fit$columns
   legend_result$record$external_guide_mm<-external_fit$guide_mm;legend_result$record$columns<-legend_cols
  } else break
  }
  if(max(overflow_mm)>.05)stop("Axis-label glyphs cannot fit safely inside the measured canvas. Increase width_mm/height_mm or provide authorized shorter labels.",call.=FALSE)
  if(length(caption_fit$lines) && (min(caption_bounds_mm$left)<canvas_margin_mm || max(caption_bounds_mm$right)>cfg$width_mm-canvas_margin_mm))stop("Caption cannot fit safely inside the measured canvas; increase width_mm or provide an authorized shorter caption.",call.=FALSE)
 },finally={grDevices::dev.off();unlink(layout_path)})
 fonts<-list(family="Arial")
 for(i in seq_along(cfg$formats)){
  format<-cfg$formats[i];device<-switch(format,pdf=arial_pdf_device,svg=svglite::svglite,png=ragg::agg_png)
  if(format=="png")device(output_paths[i],width=cfg$width,height=cfg$height,units="in",res=cfg$dpi,background="white")else device(output_paths[i],width=cfg$width,height=cfg$height,bg="white")
  tryCatch({radar_draw(p,legend_result,cfg)},finally=grDevices::dev.off())
  if(format=="pdf")fonts$pdf<-verify_pdf_arial(output_paths[i])
  if(format=="svg")fonts$svg<-embed_arial_in_svg(output_paths[i],faces)
 }
 write.csv(dat,paste0(cfg$output_prefix,".plotted-data.csv"),row.names=FALSE,na="")
 jsonlite::write_json(cfg,paste0(cfg$output_prefix,".config.json"),pretty=TRUE,auto_unbox=TRUE,digits=NA,null="null")
 record<-list(model_palette_mapping=cfg$palette_mapping,n_input=nrow(raw),n_plotted=nrow(dat),n_models=length(models),n_axes=length(axes),excluded=list(),aggregation="none; one supplied summary per model-axis",sampling_unit=cfg$sampling_unit,axis_order=axes,model_order=models,scale_mode=cfg$scale_mode,axis_specs=prep$specs,normalization_reason=cfg$normalization_reason,transformation="domain_fraction = (raw_value - domain_min)/(domain_max - domain_min); radius = domain_fraction for higher and 1 - domain_fraction for lower",raw_and_transformed=dat,uncertainty="none; summary profiles do not reconstruct sampling uncertainty",limitations=c("Polygon area is not a model ranking: it depends on axis order, number, geometry and declared domains.","Adjacent spokes do not imply interpolation, correlation or a continuous covariate.","A common displayed domain does not establish scientific comparability; it must be established before rendering."),layout=list(visual_style=list(grid_style=cfg$grid_style,grid_radii=grid_radii,inner_ring_line_type=if(cfg$grid_style=="circular")"dashed"else"solid",perimeter_line_type="solid",focus_models=cfg$focus_models,draw_order=draw_models,comparator_line_type=if(length(cfg$focus_models))"dashed"else"solid",band_intervals=band_map,band_alpha=cfg$band_alpha,line_color_transform=list(policy=color_resolution$policy,line_darken=cfg$line_darken,rgb_multiplier=1-cfg$line_darken,formula="effective channel = base channel * (1 - line_darken), converted to 8-bit sRGB with grDevices::rgb (maxColorValue = 255); explicit line_color_values take precedence",base_colors=cfg$color_values,effective_colors=cfg$line_color_values,line_alpha=cfg$line_alpha,applies_to=c("outline","symbol","legend key","raw-value label"),polygon_fill_colors="unchanged base colors"),spoke_color=cfg$grid_color,spoke_width_mm=cfg$grid_width,model_outline_width_mm=cfg$line_width,point_size_mm=cfg$point_size,polygon_fill=cfg$show_polygons,legend_position=cfg$legend_position,radial_label_policy=radial_policy,raw_value_font_size_mm=cfg$value_size),raw_value_labels=value_data,value_label_bounds_mm=value_label_bounds_mm,caption=caption,caption_original=original_caption,caption_widths_mm=caption_fit$widths_mm,caption_bounds_mm=caption_bounds_mm,legend_placement=legend_result$record,legend_columns=if(is.null(legend_result$record$columns))legend_cols else legend_result$record$columns,axis_label_widths_mm=widths,bounds=bounds,measured_panel_mm=measured_panel_mm,radial_radius_mm=actual_radius,axis_label_bounds_mm=axis_label_bounds_mm,canvas_margin_mm=canvas_margin_mm),physical_size_mm=c(width=cfg$width_mm,height=cfg$height_mm),font_verification=fonts,provenance=list(input_md5=unname(tools::md5sum(cfg$input)),script_md5=unname(tools::md5sum(script_path)),palette_md5=unname(tools::md5sum(file.path(skill_dir,"palettes/palettes.json"))),generated_at_utc=format(Sys.time(),tz="UTC",usetz=TRUE)))
 jsonlite::write_json(record,paste0(cfg$output_prefix,".statistics.json"),pretty=TRUE,auto_unbox=TRUE,digits=NA,null="null",na="null")
 writeLines(capture.output(sessionInfo()),paste0(cfg$output_prefix,".session.txt"))
 message("Rendered ",length(models)," complete model profiles across ",length(axes)," explicitly ordered axes.")
 message(paste(output_paths,collapse="\n"))
}

if(sys.nframe()==0L){
 script_path<-gsub("~+~"," ",sub("^--file=","",grep("^--file=",commandArgs(),value=TRUE)[1]),fixed=TRUE)
 radar_main(script_path,commandArgs(trailingOnly=TRUE))
}
