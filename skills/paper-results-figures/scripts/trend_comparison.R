#!/usr/bin/env Rscript
# Continuous regression and discrete ordered profiles share a long-data contract.
script_path <- gsub("~+~"," ",sub("^--file=","",grep("^--file=",commandArgs(),value=TRUE)[1]),fixed=TRUE)
skill_dir <- dirname(dirname(normalizePath(script_path,mustWork=TRUE)))
cache_root <- Sys.getenv("XDG_CACHE_HOME",unset=path.expand("~/.cache"))
.libPaths(c(file.path(Sys.getenv("PAPER_FIGURES_CACHE",file.path(cache_root,"paper-results-figures")),"library"),.libPaths()))
suppressPackageStartupMessages(library(ggplot2))
for (helper in c("formatting.R","palette_helpers.R","font_export.R","text_fit.R","trend_helpers.R","trend_header.R","trend_compact_layout.R")) source(file.path(skill_dir,"scripts",helper))
args <- commandArgs(TRUE)
if(length(args)!=1)stop("Supply one JSON configuration.")
config_path <- normalizePath(args[1],mustWork=TRUE)
defaults <- list(plot_type="trend-comparsion",input=NULL,output_prefix=NULL,mode="continuous",x="x",value="value",model="model",metric=NULL,id=NULL,
  sampling_unit=NULL,missing="error",highlight=NULL,model_order=NULL,metric_order=NULL,category_order=NULL,model_labels=NULL,metric_labels=NULL,category_labels=NULL,
  regression="linear",fit_extent="axis",slope_reference=NULL,statistic_labels=NULL,legend_labels=NULL,statistics=c("slope","r_squared"),p_value_target="auto",show_ci=NULL,ci_level=.95,show_points=TRUE,
  palette="rainbow-transparent",color_values=NULL,palette_mapping=NULL,point_alpha=NULL,point_darken=NULL,fill_alpha=NULL,point_size=NULL,line_width=.25,shape_values=NULL,
  dual_axis=FALSE,orientation="horizontal",facet_scales="free",title=NULL,panel_tag=NULL,x_label=NULL,y_label=NULL,
  x_limits=NULL,x_breaks=NULL,y_limits=NULL,y_breaks=NULL,secondary_limits=NULL,secondary_breaks=NULL,
  width_mm=NULL,height_mm=NULL,layout_columns=3,base_size=7,axis_text_size=6,legend_size=6,title_size=7.5,label_angle="auto",label_wrap="auto",
  formats=c("pdf","svg","png"),dpi=600)
user <- jsonlite::fromJSON(config_path)
unknown <- setdiff(names(user),names(defaults));if(length(unknown))stop("Unknown keys: ",paste(unknown,collapse=", "))
cfg <- utils::modifyList(defaults,user,keep.null=TRUE)
if(!cfg$plot_type %in% c("trend-comparsion","trend-comparison"))stop("Invalid plot_type.")
if(!cfg$mode %in% c("continuous","categorical"))stop("mode must be continuous or categorical.")
if(!cfg$fit_extent %in% c("axis","observed"))stop("fit_extent must be axis or observed.")
if(!cfg$missing %in% c("error","omit"))stop("missing must be error or omit.")
if(!cfg$orientation %in% c("horizontal","vertical"))stop("orientation must be horizontal or vertical.")
if(!cfg$facet_scales %in% c("free","fixed"))stop("facet_scales must be free or fixed.")
if(!(identical(cfg$label_angle,"auto")||(is.numeric(cfg$label_angle)&&length(cfg$label_angle)==1&&is.finite(cfg$label_angle)&&abs(cfg$label_angle)<=90)))stop("label_angle must be auto or numeric between -90 and 90.")
if(!cfg$label_wrap %in% c("auto","none"))stop("label_wrap must be auto or none.")
if(length(cfg$statistics)>2 || anyDuplicated(cfg$statistics) || any(!cfg$statistics %in% c("slope","r_squared","pearson_r","p_value")))stop("Choose at most two statistic types: slope, r_squared, pearson_r, p_value.")
if(!cfg$p_value_target %in% c("auto","regression","pearson","slope"))stop("p_value_target must be auto, regression, pearson or slope.")
if(cfg$p_value_target=="auto")cfg$p_value_target<-if("pearson_r" %in% cfg$statistics)"pearson"else if("slope" %in% cfg$statistics)"slope"else"regression"
if(cfg$ci_level!=.95)stop("This category specifies 95% mean confidence intervals (ci_level: 0.95).")
if(!all(cfg$formats %in% c("pdf","svg","png")) || cfg$dpi<600)stop("Use pdf/svg/png and dpi >= 600.")
if(is.null(cfg$input)||is.null(cfg$output_prefix))stop("input and output_prefix are required.")
resolve_path <- function(path) if(grepl("^(/|[A-Za-z]:[/\\\\])",path))path else file.path(dirname(config_path),path)
cfg$input <- normalizePath(resolve_path(cfg$input),mustWork=TRUE)
prefix <- resolve_path(cfg$output_prefix);figure_name<-basename(prefix)
if(basename(dirname(prefix))!=figure_name)prefix<-file.path(dirname(prefix),figure_name,figure_name)
cfg$output_prefix<-prefix;dir.create(dirname(prefix),recursive=TRUE,showWarnings=FALSE)
generated_paths<-paste0(prefix,c(".pdf",".svg",".png",".plotted-data.csv",".excluded-data.csv",".fitted-data.csv",".config.json",".statistics.json",".session.txt",".reproduce.txt"))
if(cfg$input %in% vapply(generated_paths,normalizePath,character(1),mustWork=FALSE))stop("A generated artifact cannot be the source input; use the original CSV or retained source snapshot.")
source_data <- read.csv(cfg$input,check.names=FALSE,colClasses="character",na.strings=c("","NA"))
columns<-c(cfg$x,cfg$value,cfg$model,cfg$metric,cfg$id)
if(any(!columns %in% names(source_data)))stop("Missing mapped input columns: ",paste(setdiff(columns,names(source_data)),collapse=", "))
strict_numeric <- function(v,label){z<-suppressWarnings(as.numeric(v));if(any(!is.na(v)&is.na(z)))stop("Non-numeric value in ",label);z}
dat <- data.frame(source_row=seq_len(nrow(source_data)),x=source_data[[cfg$x]],y=strict_numeric(source_data[[cfg$value]],cfg$value),
  model=source_data[[cfg$model]],metric=if(is.null(cfg$metric))"Metric A"else source_data[[cfg$metric]],stringsAsFactors=FALSE)
if(!is.null(cfg$id))dat$id<-source_data[[cfg$id]]
if(cfg$mode=="continuous")dat$x<-strict_numeric(dat$x,cfg$x)
valid<-is.finite(dat$y)&!is.na(dat$model)&nzchar(dat$model)&!is.na(dat$metric)&nzchar(dat$metric)&
  if(cfg$mode=="continuous")is.finite(dat$x)else(!is.na(dat$x)&nzchar(dat$x))
excluded<-dat[!valid,,drop=FALSE]
if(nrow(excluded)&&cfg$missing=="error")stop("Non-finite/missing mapped values; establish missing: omit to record exclusions.")
dat<-dat[valid,,drop=FALSE];if(!nrow(dat))stop("No finite rows.")
order_levels <- function(observed,requested,label){observed<-unique(as.character(observed));if(is.null(requested))return(observed);if(anyDuplicated(requested)||!setequal(observed,requested))stop(label," must contain each retained level exactly once.");as.character(requested)}
models<-order_levels(dat$model,cfg$model_order,"model_order");metrics<-order_levels(dat$metric,cfg$metric_order,"metric_order")
cfg$model_order<-models;cfg$metric_order<-metrics
if(cfg$dual_axis && (cfg$mode!="continuous" || length(models)!=1 || length(metrics)!=2))stop("dual_axis requires one model, two metrics and continuous x.")
if(cfg$mode=="continuous" && !cfg$dual_axis && length(metrics)!=1)stop("Continuous mode requires one metric, or one-model/two-metric dual_axis.")
if(cfg$mode=="continuous" && cfg$orientation!="horizontal")stop("Continuous mode uses numeric x horizontally; orientation only changes categorical profiles.")
if(cfg$mode=="continuous" && cfg$regression!="linear" && "slope" %in% cfg$statistics && is.null(cfg$slope_reference))cfg$statistics<-setdiff(cfg$statistics,"slope")
if(cfg$mode=="categorical"){
  if(anyDuplicated(dat[c("model","metric","x")]))stop("Duplicate model/metric/category keys: supply established summaries or an explicit preparation rule; no automatic averaging.")
  categories<-order_levels(dat$x,cfg$category_order,"category_order");cfg$category_order<-categories;cfg$statistics<-character(0);cfg$show_ci<-FALSE
}
series<-if(cfg$dual_axis)metrics else models
dat$series<-if(cfg$dual_axis)dat$metric else dat$model
dat$series<-factor(dat$series,levels=series);dat$metric<-factor(dat$metric,levels=metrics)
palettes<-jsonlite::fromJSON(file.path(skill_dir,"palettes/palettes.json"),simplifyVector=TRUE)
if(!cfg$palette %in% names(palettes))stop("Unknown palette.")
palette<-palettes[[cfg$palette]]
color_resolution<-resolve_model_palette_mapping(series,palette,
 focal=if(cfg$dual_axis)character()else cfg$highlight,colors=cfg$color_values,saved_record=cfg$palette_mapping)
colors<-color_resolution$colors;cfg$palette_mapping<-color_resolution$record
if(!all(series %in% names(colors)))stop("color_values must name every series.")
cfg$color_values<-as.list(colors)
if(is.null(cfg$point_alpha))cfg$point_alpha<-palette$paired_point_alpha
if(is.null(cfg$point_darken))cfg$point_darken<-palette$paired_point_darken
if(is.null(cfg$fill_alpha))cfg$fill_alpha<-min(.10,palette$fill_alpha)
point_colors<-darken_palette_colors(colors,cfg$point_darken)
shapes<-if(is.null(cfg$shape_values))setNames(rep(c(16,17,18,15,3,4,8,7,9,10),length.out=length(series)),series)else unlist(cfg$shape_values)
if(!all(series %in% names(shapes)))stop("shape_values must name each series.")
cfg$shape_values<-as.list(shapes)
if(is.null(cfg$width_mm))cfg$width_mm<-if(cfg$layout_columns==4)42 else 57
if(is.null(cfg$height_mm))cfg$height_mm<-54
if(is.null(cfg$point_size))cfg$point_size<-if(cfg$mode=="categorical").65 else 1.1
if(any(!is.finite(c(cfg$width_mm,cfg$height_mm)))||min(cfg$width_mm,cfg$height_mm)<=0)stop("Invalid physical size.")
faces<-resolve_arial_fonts()
axis_labels<-function(x){out<-rep(NA_character_,length(x));ok<-is.finite(x);out[ok]<-format_axis_ticks(x[ok]);out}
display_labels<-function(keys,mapping){if(is.null(mapping))return(keys);mapped<-unlist(mapping);ifelse(keys %in% names(mapped),mapped[keys],keys)}
legend_labels<-if(!is.null(cfg$legend_labels))display_labels(series,cfg$legend_labels)else if(cfg$dual_axis)series else display_labels(series,cfg$model_labels)
fits<-list();predictions<-data.frame();axis_records<-list();transform<-NULL
if(cfg$mode=="continuous"){
  if(is.null(cfg$show_ci))cfg$show_ci<-length(series)<=2
  axis_records$x<-trend_numeric_axis(dat$x,cfg$x_limits,cfg$x_breaks,cfg$width_mm-17,cfg$axis_text_size)
  for(key in series){
    d<-dat[dat$series==key,,drop=FALSE]
    fitted<-trend_fit_series(d,cfg$regression,cfg$slope_reference);fits[[key]]<-fitted$statistics
    fit_range<-if(cfg$fit_extent=="axis")axis_records$x$limits else range(d$x)
    xs<-seq(fit_range[1],fit_range[2],length.out=201)
    pred<-predict(fitted$fit,newdata=data.frame(x=xs),interval="confidence",level=.95)
    predictions<-rbind(predictions,data.frame(x=xs,y=pred[,"fit"],lower=pred[,"lwr"],upper=pred[,"upr"],series=key,extrapolated=xs<min(d$x)|xs>max(d$x)))
    if("p_value" %in% cfg$statistics && cfg$p_value_target=="slope" && !is.finite(fitted$statistics$slope))stop("A polynomial slope p-value requires an explicit slope_reference.")
    fitted$statistics$annotation_p_value_target<-cfg$p_value_target;fits[[key]]<-fitted$statistics
  }
  yvalues<-function(key){p<-predictions[predictions$series==key,];c(dat$y[dat$series==key],p$y,if(cfg$show_ci)c(p$lower,p$upper))}
  if(cfg$dual_axis){
    axis_records$primary<-trend_numeric_axis(yvalues(series[1]),cfg$y_limits,cfg$y_breaks,cfg$height_mm-24,cfg$axis_text_size,FALSE)
    axis_records$secondary<-trend_numeric_axis(yvalues(series[2]),cfg$secondary_limits,cfg$secondary_breaks,cfg$height_mm-24,cfg$axis_text_size,FALSE)
    ra<-axis_records$primary$limits;rb<-axis_records$secondary$limits
    a<-diff(ra)/diff(rb);b<-ra[1]-a*rb[1]
    transform<-list(primary_range=ra,secondary_range=rb,slope=a,intercept=b,meaning="Affine display mapping only; regression/statistics remain in each metric's original units")
    secondary<-dat$series==series[2];dat$display_y<-dat$y;dat$display_y[secondary]<-a*dat$y[secondary]+b
    predictions$display_y<-predictions$y;predictions$display_lower<-predictions$lower;predictions$display_upper<-predictions$upper
    secondary<-predictions$series==series[2]
    for(field in c("y","lower","upper"))predictions[[paste0("display_",field)]][secondary]<-a*predictions[[field]][secondary]+b
  }else{
    axis_records$primary<-trend_numeric_axis(unlist(lapply(series,yvalues)),cfg$y_limits,cfg$y_breaks,cfg$height_mm-24,cfg$axis_text_size,FALSE)
    dat$display_y<-dat$y;predictions$display_y<-predictions$y;predictions$display_lower<-predictions$lower;predictions$display_upper<-predictions$upper
  }
  predictions$series<-factor(predictions$series,levels=series)
  p<-ggplot(dat,aes(x=x,y=display_y,color=series,shape=series))
  if(cfg$show_ci)p<-p+geom_ribbon(data=predictions,aes(x=x,y=NULL,ymin=display_lower,ymax=display_upper,fill=series),inherit.aes=FALSE,alpha=cfg$fill_alpha,color=NA,show.legend=FALSE)
  if(cfg$show_ci)p<-p+geom_line(data=predictions,aes(x=x,y=display_lower,color=series),inherit.aes=FALSE,linewidth=.10,alpha=.55,show.legend=FALSE)+geom_line(data=predictions,aes(x=x,y=display_upper,color=series),inherit.aes=FALSE,linewidth=.10,alpha=.55,show.legend=FALSE)
  p<-p+geom_line(data=predictions,aes(x=x,y=display_y,color=series),inherit.aes=FALSE,linewidth=cfg$line_width,show.legend=FALSE)
  if(cfg$show_points)p<-p+geom_point(size=cfg$point_size,alpha=cfg$point_alpha,color=unname(point_colors[as.character(dat$series)]),show.legend=FALSE)
  # A dedicated legend layer combines the exact series icon with its fitted line.
  legend_data<-data.frame(x=NA_real_,display_y=NA_real_,series=factor(series,levels=series))
  trend_key<-function(data,params,size){data$linetype<-1;data$linewidth<-cfg$line_width;grid::grobTree(draw_key_path(data,params,size),draw_key_point(data,params,size))}
  p<-p+geom_point(data=legend_data,size=cfg$point_size,na.rm=TRUE,show.legend=TRUE,key_glyph=trend_key)
  primary<-axis_records$primary
  if(cfg$dual_axis){
    inverse<-local({aa<-a;bb<-b;function(v)(v-bb)/aa})
    names_y<-display_labels(metrics,cfg$metric_labels)
    p<-p+scale_y_continuous(name=names_y[1],limits=primary$limits,breaks=primary$breaks,labels=axis_labels,expand=expansion(mult=0),sec.axis=sec_axis(inverse,name=names_y[2],breaks=axis_records$secondary$breaks,labels=axis_labels))
  }else p<-p+scale_y_continuous(name=if(is.null(cfg$y_label))display_labels(metrics,cfg$metric_labels)else cfg$y_label,limits=primary$limits,breaks=primary$breaks,labels=axis_labels,expand=expansion(mult=0))
  p<-p+scale_x_continuous(name=if(is.null(cfg$x_label))cfg$x else cfg$x_label,limits=axis_records$x$limits,breaks=axis_records$x$breaks,labels=axis_labels,expand=expansion(mult=0))
}else{
  dat$x<-factor(dat$x,levels=categories)
  # Explicit missing category rows prevent lines from bridging unavailable cells.
  grid_data<-expand.grid(x=categories,series=series,metric=metrics,stringsAsFactors=FALSE)
  plot_data<-merge(grid_data,data.frame(x=as.character(dat$x),series=as.character(dat$series),metric=as.character(dat$metric),y=dat$y),all.x=TRUE,sort=FALSE)
  plot_data$x<-factor(plot_data$x,levels=categories);plot_data$series<-factor(plot_data$series,levels=series);plot_data$metric<-factor(plot_data$metric,levels=metrics)
  plot_data<-plot_data[order(plot_data$metric,plot_data$series,plot_data$x),]
  plot_data$segment<-ave(is.na(plot_data$y),interaction(plot_data$metric,plot_data$series,drop=TRUE),FUN=cumsum)
  p<-ggplot(plot_data,aes(x=x,y=y,color=series,shape=series))+geom_line(aes(group=interaction(series,segment)),linewidth=cfg$line_width,na.rm=TRUE)
  if(cfg$show_points)p<-p+geom_point(size=cfg$point_size,alpha=cfg$point_alpha,
    color=unname(point_colors[as.character(plot_data$series)]),na.rm=TRUE,show.legend=FALSE)
  p<-p+scale_x_discrete(name=if(is.null(cfg$x_label))cfg$x else cfg$x_label,limits=if(cfg$orientation=="vertical")rev(categories)else categories,labels=display_labels(if(cfg$orientation=="vertical")rev(categories)else categories,cfg$category_labels),drop=FALSE,expand=expansion(add=.35))+
    scale_y_continuous(name=if(is.null(cfg$y_label))"Value"else cfg$y_label,labels=axis_labels)
  if(length(metrics)>1)p<-p+facet_wrap(~metric,nrow=if(cfg$orientation=="vertical")1L else NULL,ncol=if(cfg$orientation=="horizontal")1L else NULL,axes="margins",axis.labels="margins",scales=if(cfg$facet_scales=="free")"free_y"else"fixed",labeller=as_labeller(setNames(display_labels(metrics,cfg$metric_labels),metrics)))
  if(cfg$orientation=="vertical")p<-p+coord_flip()
}
# Measure top labels at final font size; adapt columns instead of shrinking text.
label_lines<-strsplit(legend_labels,"\n",fixed=TRUE)
label_widths<-vapply(label_lines,function(lines)max(systemfonts::string_width(lines,family="Arial",size=cfg$legend_size,res=72))*25.4/72,numeric(1))
legend_columns<-min(length(series),max(1L,floor((cfg$width_mm-6)/(max(label_widths)+7))))
if(max(label_widths)+7>cfg$width_mm-6)stop("Legend text exceeds canvas: widen width_mm or establish shorter display labels.")
cfg$show_ci<-isTRUE(cfg$show_ci)
p<-p+scale_color_manual(values=colors,breaks=series,labels=legend_labels,name=NULL)+scale_shape_manual(values=shapes,breaks=series,labels=legend_labels,name=NULL)+
  scale_fill_manual(values=colors,guide="none")+guides(color=guide_legend(ncol=legend_columns,byrow=TRUE,override.aes=list(alpha=1)),shape=guide_legend(ncol=legend_columns,byrow=TRUE))+
  labs(title=cfg$title,tag=cfg$panel_tag)+theme_classic(base_size=cfg$base_size,base_family="Arial")+
  theme(axis.text=element_text(size=cfg$axis_text_size,color="#222222"),axis.title=element_text(size=cfg$base_size),
    axis.line=element_line(linewidth=.25,color="#333333"),axis.ticks=element_line(linewidth=.22,color="#333333"),axis.ticks.length=grid::unit(1.3,"pt"),
    legend.position="top",legend.text=element_text(size=cfg$legend_size),legend.key.width=grid::unit(3.5,"mm"),legend.key.height=grid::unit(2.2,"mm"),
    legend.margin=margin(0,0,0,0),legend.spacing.x=grid::unit(.8,"mm"),legend.box.spacing=grid::unit(1,"mm"),
    plot.title=element_text(size=cfg$title_size,hjust=.5),plot.tag=element_text(size=9,face="bold"),plot.margin=margin(2,2,2,2),
    strip.background=element_blank(),strip.text=element_text(size=cfg$base_size),panel.spacing=grid::unit(2,"mm"))
if(cfg$mode=="continuous") {
  # Endpoint glyphs extend beyond the panel; reserve measured outer canvas room.
  endpoint_labels<-format_axis_ticks(range(axis_records$x$breaks))
  endpoint_half_pt<-systemfonts::string_width(endpoint_labels,family="Arial",size=cfg$axis_text_size,res=72)/2
  endpoint_margin_pt<-pmax(2,endpoint_half_pt+.7*72/25.4)
  axis_records$x$endpoint_canvas_margin_mm<-setNames(endpoint_margin_pt*25.4/72,c("left","right"))
  p<-p+theme(legend.position="none",plot.margin=margin(2,endpoint_margin_pt[2],2,endpoint_margin_pt[1]))
}
if(cfg$dual_axis)p<-p+theme(axis.title.y.left=element_text(color="#222222"),axis.title.y.right=element_text(color="#222222"))
text_fitting<-NULL
if(cfg$mode=="categorical"){
  compact<-trend_compact_categorical(p,cfg,dat,metrics,categories,display_labels,axis_labels,series,legend_labels,colors,shapes,fits)
  p<-compact$plot;cfg$label_angle<-compact$angle
  text_fitting<-compact$text_fitting;axis_records$categorical<-compact$axes
}
fonts<-list(family="Arial");guide_record<-NULL
for(format in cfg$formats){
  output<-paste0(prefix,".",format)
  if(normalizePath(output,mustWork=FALSE)==cfg$input)stop("Output would overwrite input.")
  if(format=="png")ragg::agg_png(output,width=cfg$width_mm/25.4,height=cfg$height_mm/25.4,units="in",res=cfg$dpi,background="white")
  else if(format=="pdf")arial_pdf_device(output,width=cfg$width_mm/25.4,height=cfg$height_mm/25.4)
  else svglite::svglite(output,width=cfg$width_mm/25.4,height=cfg$height_mm/25.4,bg="white")
  tryCatch({grid::grid.newpage();final<-if(cfg$mode=="categorical")trend_categorical_final_grob(p,cfg,series,legend_labels,colors,shapes,fits)else trend_final_grob(p,cfg,series,legend_labels,colors,shapes,fits);guide_record<-final$guide;grid::grid.draw(final$grob)},finally=dev.off())
  if(format=="pdf")fonts$pdf<-verify_pdf_arial(output)
  if(format=="svg")fonts$svg<-embed_arial_in_svg(output,faces)
}
snapshot<-paste0(prefix,".source.csv")
if(normalizePath(snapshot,mustWork=FALSE)!=cfg$input)file.copy(cfg$input,snapshot,overwrite=TRUE)
cfg$input<-normalizePath(snapshot,mustWork=TRUE)
write.csv(dat,paste0(prefix,".plotted-data.csv"),row.names=FALSE,na="")
write.csv(excluded,paste0(prefix,".excluded-data.csv"),row.names=FALSE,na="")
if(nrow(predictions))write.csv(predictions,paste0(prefix,".fitted-data.csv"),row.names=FALSE,na="")
jsonlite::write_json(cfg,paste0(prefix,".config.json"),pretty=TRUE,auto_unbox=TRUE,digits=NA,null="null")
record<-list(n_input=nrow(source_data),n_plotted=nrow(dat),n_excluded=nrow(excluded),excluded_source_rows=excluded$source_row,
  sampling_unit=cfg$sampling_unit,series_statistics=fits,axes=axis_records,dual_axis_transform=transform,
  fit_extent=cfg$fit_extent,extrapolation=if(cfg$mode=="continuous")list(policy=if(cfg$fit_extent=="axis")"Fits cover the requested numeric axis; extrapolated predictions are flagged without refitting or adding observations"else"Fits stay within each observed covariate range",n_predictions_outside_observed_x=sum(predictions$extrapolated),observed_ranges=setNames(lapply(series,function(key)range(dat$x[dat$series==key])),series))else NULL,
  uncertainty=if(cfg$show_ci)"Pointwise 95% confidence interval for the fitted conditional mean, not prediction interval or simultaneous band"else"Not displayed",
  inference_limitations="OLS/Pearson calculations assume independent sampling units; repeated, clustered or weighted inference requires an established analysis outside this renderer. Per-series p-values do not test differences between slopes. No multiplicity adjustment is applied.",
  categorical_connection=if(cfg$mode=="categorical")"Connects explicitly ordered category summaries only; gaps are preserved and spacing implies no continuous covariate"else NULL,
  model_palette_mapping=cfg$palette_mapping,color_mapping=colors,point_color_mapping=point_colors,text_fitting=text_fitting,legend=list(position="top",guide=guide_record,columns=if(is.null(guide_record))legend_columns else guide_record$columns,labels=legend_labels,statistics=cfg$statistics,p_value_target=cfg$p_value_target),
  physical_size_mm=c(width=cfg$width_mm,height=cfg$height_mm),font_verification=fonts,
  provenance=list(input_md5=unname(tools::md5sum(cfg$input)),script_md5=unname(tools::md5sum(script_path)),helper_md5=unname(tools::md5sum(file.path(skill_dir,"scripts/trend_helpers.R"))),guide_md5=unname(tools::md5sum(file.path(skill_dir,"scripts/trend_header.R"))),compact_layout_md5=unname(tools::md5sum(file.path(skill_dir,"scripts/trend_compact_layout.R")))))
jsonlite::write_json(record,paste0(prefix,".statistics.json"),pretty=TRUE,auto_unbox=TRUE,digits=NA,null="null",na="null")
writeLines(capture.output(sessionInfo()),paste0(prefix,".session.txt"))
writeLines(c("Replay the saved configuration with the same skill version:",paste("bash",shQuote(file.path(skill_dir,"scripts/render.sh")),shQuote(paste0(prefix,".config.json")))),paste0(prefix,".reproduce.txt"))
message("Rendered trend-comparsion: ",nrow(dat)," retained rows; ",nrow(excluded)," recorded exclusions.")
