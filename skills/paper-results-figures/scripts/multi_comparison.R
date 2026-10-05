#!/usr/bin/env Rscript
# Reusable multi-method summaries, distributions, paired deltas and metric panels.
script_path <- gsub("~+~", " ", sub("^--file=", "", grep("^--file=", commandArgs(), value=TRUE)[1]), fixed=TRUE)
skill_dir <- dirname(dirname(normalizePath(script_path)))
cache_root <- Sys.getenv("XDG_CACHE_HOME", unset=path.expand("~/.cache"))
.libPaths(c(file.path(Sys.getenv("PAPER_FIGURES_CACHE", file.path(cache_root,"paper-results-figures")),"library"),.libPaths()))
suppressPackageStartupMessages(library(ggplot2))
source(file.path(skill_dir,"scripts/formatting.R"))
source(file.path(skill_dir,"scripts/palette_helpers.R"))
source(file.path(skill_dir,"scripts/paper_layout.R"))
source(file.path(skill_dir,"scripts/significance.R"))
source(file.path(skill_dir,"scripts/comparison_annotations.R"))
source(file.path(skill_dir,"scripts/text_fit.R"))
source(file.path(skill_dir,"scripts/multi_axes.R"))
source(file.path(skill_dir,"scripts/axis_break.R"))
source(file.path(skill_dir,"scripts/inside_values.R"))
source(file.path(skill_dir,"scripts/legend_space.R"))
source(file.path(skill_dir,"scripts/font_export.R"))
faces <- resolve_arial_fonts()
axis_labels <- function(x) {out<-rep(NA_character_,length(x));ok<-is.finite(x);out[ok]<-format_axis_ticks(x[ok]);out}
args <- commandArgs(TRUE)
if(length(args)!=1) stop("Supply one JSON configuration.")
config_path <- normalizePath(args[1],mustWork=TRUE)
defaults <- list(plot_type="mutl-comparison", input=NULL, output_prefix=NULL,
 data_mode="raw", layout="long", model="model", value="value", model_columns=NULL,
 sd=NULL, n=NULL, id=NULL, paired=FALSE, metric=NULL, metrics=NULL, filter=NULL,
 model_labels=NULL, model_order=NULL, color_values=NULL, palette_mapping=NULL, palette="rainbow-transparent",
 style="bar", orientation="vertical", direction="higher", sort="performance", highlight=NULL,
 reference=NULL, delta=FALSE, availability=NULL, unavailable_values=c("False","false","0"),
 missing="error", penalty=NULL, title=NULL, panel_tag=NULL, value_label=NULL, caption=NULL,
 show_points=FALSE, show_sd=FALSE, show_values=TRUE, show_rank=TRUE,
 show_significance=FALSE, significance_model=NULL, p_adjust="none", significance_size=1.8, significance_spacing_mm=2.2,
 significance_gap_mm=0.6, annotation_layout="auto", annotation_strip_mm=NULL, metric_domain=NULL, data_limits=NULL,
 point_alpha=NULL, point_size=NULL, jitter_width=0.11, seed=42,
 limits=NULL, breaks=NULL, axis_break=NULL, axis_policy="auto", occupancy=0.92,
 legend_placement="auto", legend_clearance_mm=.8,
 width=56/25.4, height=40/25.4, layout_columns=3, width_mm=NULL, height_mm=NULL, font_family="Arial", base_size=7, title_size=7.5,
 axis_title_size=7, axis_text_size=6, category_text_size=6.4, value_size=2.2,
 rank_size=2.1, right_margin=36, annotation_gap=17, label_angle="auto", value_angle="auto", label_wrap="auto", text_fit_gap_mm=.7, text_min_panel_mm=12, bar_width=NULL, border_color="#454545",
 outline_width=0.28, inner_width=0.22, border_alpha=0.8, point_darken=NULL, category_padding=NULL, sd_width=0.30, mean_width=0.38,
 rank_offset=0.07, value_offset=0.135, rank_text_gap=0.045, tag_size=9, outer_margin=2,
 fill_alpha=NULL, line_markers=TRUE, line_marker_shape=18, line_marker_size=1.3, line_type="dashed", combo_styles=c("bar","line"),
 combo_layout="facets", combo_labels=NULL, combo_order_by=NULL, combo_directions=NULL, combo_limits=NULL, combo_breaks=NULL,
 combo_value_placement="outside", combo_inside_value_size=2.7, combo_sd_display="auto", combo_sd_modes=NULL, bar_min_fraction=.15, combo_color_by="model", combo_show_sd=NULL, combo_units=NULL, combo_domains=NULL,
 combo_metric_colors=NULL, combo_line_types=NULL, combo_marker_shapes=NULL, combo_bars=FALSE, combo_bar_width=.72,
 show_mean_correlation=NULL, combo_panel_gap_mm=2.0, formats=c("pdf","svg","png"), dpi=600)
user <- jsonlite::fromJSON(config_path)
unknown <- setdiff(names(user),names(defaults)); if(length(unknown)) stop("Unknown keys: ",paste(unknown,collapse=", "))
cfg <- utils::modifyList(defaults,user,keep.null=TRUE)
if(!cfg$legend_placement %in% c("auto","inside","outside"))stop("legend_placement must be auto, inside or outside.")
if(!is.numeric(cfg$legend_clearance_mm)||length(cfg$legend_clearance_mm)!=1||!is.finite(cfg$legend_clearance_mm)||cfg$legend_clearance_mm<=0)stop("legend_clearance_mm must be one positive physical distance.")
text_fit_policy<-list(label_angle=cfg$label_angle,value_angle=cfg$value_angle,label_wrap=cfg$label_wrap)
validate_text_fit_controls(cfg)
# The first physical measurement uses unrotated text, then resolves the policy.
if(identical(cfg$label_angle,"auto"))cfg$label_angle<-0
if(identical(cfg$value_angle,"auto"))cfg$value_angle<-0
text_fitting<-list()
# Apply a physical visual profile only to omitted controls. Scientific input,
# semantic choices, explicit dimensions and saved per-figure overrides persist.
visual_profile<-if(cfg$layout_columns==4)"four-column"else"three-column"
if(cfg$layout_columns==4){
 compact<-list(category_text_size=5.7,value_size=1.9,rank_size=1.8,title_size=7,
  axis_title_size=6.5,axis_text_size=5.5,value_offset=.19,rank_text_gap=.05)
 for(k in names(compact))if(!k %in% names(user))cfg[[k]]<-compact[[k]]
 if(!any(c("height","height_mm") %in% names(user)))cfg$height_mm<-40
}
# Paired reference differences use a larger mean diamond while saved overrides persist.
if(cfg$plot_type!="multi-metric-comparison" && cfg$style=="line" &&
   isTRUE(cfg$delta)){
 if(!"line_marker_size" %in% names(user))cfg$line_marker_size<-2.3
 if(cfg$orientation=="vertical"){
  if(!"rank_offset" %in% names(user))cfg$rank_offset<-.055
  if(!"value_offset" %in% names(user))cfg$value_offset<-.105
  if(!"rank_text_gap" %in% names(user))cfg$rank_text_gap<-.020
 }
}
# Bring horizontal bar values and rotated ranking text closer to their arrow.
# Explicit per-figure offsets retain their saved positions.
if(cfg$plot_type!="multi-metric-comparison" && cfg$orientation=="horizontal"){
 if(!"right_margin" %in% names(user))cfg$right_margin<-32
 # Rotated significance labels need enough room between nested connector
 # lines. Span-aware strip fitting below removes unnecessary axis padding.
 if(isTRUE(cfg$show_significance) && !"significance_spacing_mm" %in% names(user))
  cfg$significance_spacing_mm<-2.7
 if(isTRUE(cfg$show_rank)){
 if(!"rank_offset" %in% names(user))cfg$rank_offset<-.04
 if(!"value_offset" %in% names(user))cfg$value_offset<-cfg$rank_offset+if(cfg$style=="bar").03 else .035
 if(!"rank_text_gap" %in% names(user))cfg$rank_text_gap<-if(cfg$style=="bar").04 else .055
 }
}
if(cfg$plot_type=="multi-metric-comparison" && cfg$combo_layout %in% c("shared-rows","stacked-bars","shared-axis")){
 if(!"orientation" %in% names(user))cfg$orientation<-if(cfg$combo_layout=="shared-rows")"horizontal"else"vertical"
 if(!"combo_styles" %in% names(user))cfg$combo_styles<-if(cfg$combo_layout=="shared-axis")"line"else c("bar","bar")
 if(!"show_rank" %in% names(user))cfg$show_rank<-FALSE
 visual_profile<-cfg$combo_layout
 if(!any(c("width_mm","width","layout_columns") %in% names(user)))cfg$width_mm<-if(cfg$combo_layout %in% c("shared-rows","stacked-bars"))88 else 56
 if(cfg$layout_columns==3 && !any(c("height_mm","height") %in% names(user)))cfg$height_mm<-40
 # Internal values need sufficient bar thickness for automatic 90-degree fitting.
 # This uses category space without shrinking Arial or widening the canvas.
 if(cfg$combo_layout=="shared-rows" && cfg$combo_value_placement=="inside" && !"bar_width" %in% names(user))cfg$bar_width<-.84
 if(cfg$combo_layout=="stacked-bars"){
  if(!"bar_width" %in% names(user))cfg$bar_width<-.84
  if(!"category_padding" %in% names(user))cfg$category_padding<-cfg$bar_width/2+.28
 }
 if(cfg$combo_layout=="shared-axis" && !"line_marker_size" %in% names(user))cfg$line_marker_size<-if(cfg$combo_bars)1.6 else 2.0
}
if(cfg$plot_type=="multi-metric-comparison" && cfg$combo_layout=="dual-axis"){
 visual_profile<-"dual-axis"
 if(!"category_text_size" %in% names(user))cfg$category_text_size<-if(cfg$layout_columns==4)5.7 else 6
 if(!"line_marker_size" %in% names(user))cfg$line_marker_size<-2.0
}
if(cfg$plot_type=="multi-metric-comparison" && cfg$combo_layout=="grouped-distributions"){
 visual_profile<-"grouped-distributions"
 if(!"combo_styles" %in% names(user))cfg$combo_styles<-cfg$style
 if(!"show_rank" %in% names(user))cfg$show_rank<-FALSE
 if(!"show_values" %in% names(user))cfg$show_values<-FALSE
 if(!any(c("width","width_mm","layout_columns") %in% names(user)))cfg$width_mm<-if(cfg$layout_columns==4)42 else 56
 if(!any(c("height","height_mm") %in% names(user)))cfg$height_mm<-40
}
if(!is.null(cfg$axis_break)){
 if(cfg$style!="box" || cfg$data_mode!="raw")stop("axis_break is supported only for raw box plots.")
 if(!"show_values" %in% names(user))cfg$show_values<-FALSE
 if(!"show_rank" %in% names(user))cfg$show_rank<-FALSE
 if(!any(c("height","height_mm") %in% names(user)))cfg$height_mm<-40
 if(!"right_margin" %in% names(user))cfg$right_margin<-cfg$outer_margin
 if(cfg$show_values || cfg$show_rank || cfg$show_significance)stop("Broken boxes do not support value, ranking or significance annotations; use separate continuous-axis views for inference.")
}
if(cfg$plot_type=="multi-metric-comparison" && cfg$combo_layout=="facets"){
 visual_profile<-"facets"
 if(!any(c("width","width_mm","layout_columns") %in% names(user)))cfg$width_mm<-88
}
if(cfg$plot_type!="multi-metric-comparison" && isTRUE(cfg$show_significance) && cfg$layout_columns==3 &&
   !any(c("height","height_mm") %in% names(user)))cfg$height_mm<-40
cfg <- resolve_paper_dimensions(cfg,user)
palettes<-jsonlite::fromJSON(file.path(skill_dir,"palettes/palettes.json"));pal<-palettes[[cfg$palette]]
if(is.null(pal))stop("Unknown palette.")
if(is.null(cfg$fill_alpha))cfg$fill_alpha<-pal$fill_alpha
if(is.null(cfg$point_alpha))cfg$point_alpha<-pal$distribution_point_alpha
if(is.null(cfg$point_darken))cfg$point_darken<-pal$distribution_point_darken
# Category padding includes the mark half-width; apply it exactly once.
if(is.null(cfg$bar_width))cfg$bar_width<-if(cfg$style=="bar")0.72 else 0.65
if(is.null(cfg$category_padding))cfg$category_padding<-switch(cfg$style,
 box=if(cfg$orientation=="vertical")max(.50,cfg$bar_width/2+.025) else cfg$bar_width/2+.24,
 bar=cfg$bar_width/2+if(cfg$orientation=="horizontal").24 else .18,
 violin=if(cfg$orientation=="vertical").58 else .64,line=if(cfg$orientation=="vertical").46 else .28)
if(isTRUE(cfg$show_significance) && cfg$orientation=="horizontal" &&
   cfg$style %in% c("box","violin") && !"category_padding" %in% names(user))
 cfg$category_padding<-max(if(cfg$style=="box")cfg$bar_width/2+.24 else .58,.62)
axis_policy_requested<-cfg$axis_policy
if(identical(cfg$axis_policy,"auto"))cfg$axis_policy<-if(cfg$style=="bar" && !(cfg$plot_type=="multi-metric-comparison"&&cfg$combo_layout=="shared-axis"))"zoom"else"full"
if(cfg$font_family!="Arial") stop("Every text element must use Arial.")
if(!cfg$plot_type %in% c("mutl-comparison","multi-comparison","multi-metric-comparison")) stop("Invalid plot_type.")
combo <- cfg$plot_type=="multi-metric-comparison"
if(!is.null(cfg$axis_break) && combo && cfg$combo_layout!="grouped-distributions")stop("axis_break supports single-metric or grouped-distributions raw boxes only.")
if(!cfg$style %in% c("bar","box","violin","line")) stop("Unsupported style.")
if(!cfg$data_mode %in% c("raw","summary") || !cfg$layout %in% c("long","wide")) stop("Invalid data contract.")
if(!cfg$direction %in% c("higher","lower") || !cfg$sort %in% c("performance","input","reverse-performance")) stop("Invalid direction/sort.")
if(!cfg$orientation %in% c("horizontal","vertical")) stop("Invalid orientation.")
if(!cfg$missing %in% c("error","drop","penalty") || !cfg$axis_policy %in% c("full","zero","zoom")) stop("Invalid missing or axis policy.")
if(!cfg$annotation_layout %in% c("auto","same-side"))stop("annotation_layout must be auto or same-side.")
for(k in c("metric_domain","data_limits"))if(!is.null(cfg[[k]]) && (!is.numeric(cfg[[k]]) || length(cfg[[k]])!=2 || any(!is.finite(cfg[[k]])) || diff(cfg[[k]])<=0))stop(k," must contain two increasing finite values.")
if(!is.null(cfg$annotation_strip_mm) && (!is.numeric(cfg$annotation_strip_mm) || length(cfg$annotation_strip_mm)!=1 || !is.finite(cfg$annotation_strip_mm) || cfg$annotation_strip_mm<=0))stop("annotation_strip_mm must be a positive finite value.")
if(!is.numeric(cfg$category_padding) || length(cfg$category_padding)!=1 || !is.finite(cfg$category_padding) || cfg$category_padding<=0)stop("category_padding must be a positive finite number.")
if(!cfg$combo_layout %in% c("facets","dual-axis","shared-rows","stacked-bars","shared-axis","grouped-distributions")) stop("Invalid combo layout.")
if(!cfg$combo_value_placement %in% c("outside","inside"))stop("combo_value_placement must be outside or inside.")
if(!cfg$combo_sd_display %in% c("auto","both","outward"))stop("combo_sd_display must be auto, both or outward.")
if(!cfg$combo_color_by %in% c("model","metric"))stop("combo_color_by must be model or metric.")
if(!is.numeric(cfg$bar_min_fraction)||length(cfg$bar_min_fraction)!=1||!is.finite(cfg$bar_min_fraction)||cfg$bar_min_fraction<=0||cfg$bar_min_fraction>=.5)stop("bar_min_fraction must be between zero and one half.")
for(k in c("combo_inside_value_size","combo_panel_gap_mm"))if(!is.numeric(cfg[[k]])||length(cfg[[k]])!=1||!is.finite(cfg[[k]])||cfg[[k]]<=0)stop(k," must be positive and finite.")
if(cfg$data_mode=="summary" && (cfg$show_points || cfg$style %in% c("box","violin") || cfg$delta)) stop("Summary means cannot reconstruct observations, distributions or paired differences.")
if(cfg$delta && (!cfg$paired || is.null(cfg$id) || is.null(cfg$reference))) stop("Deltas require paired raw values, id and reference.")
if(cfg$paired && is.null(cfg$id) && cfg$data_mode=="raw") stop("Paired input requires an ID.")
if(!length(cfg$formats) || !all(cfg$formats %in% c("pdf","svg","png"))) stop("Invalid formats.")
for(k in c("width","height","base_size","title_size","axis_title_size","axis_text_size","category_text_size","value_size","rank_size","sd_width","mean_width","line_marker_size","significance_size","significance_spacing_mm","significance_gap_mm","dpi")) if(!is.numeric(cfg[[k]]) || length(cfg[[k]])!=1 || !is.finite(cfg[[k]]) || cfg[[k]]<=0) stop("Invalid positive setting: ",k)
if(!is.logical(cfg$combo_bars)||length(cfg$combo_bars)!=1||is.na(cfg$combo_bars))stop("combo_bars must be true or false.")
if(cfg$combo_bars && !(combo && cfg$combo_layout=="shared-axis"))stop("combo_bars is supported only for shared-axis mean lines.")
if(!is.numeric(cfg$combo_bar_width)||length(cfg$combo_bar_width)!=1||!is.finite(cfg$combo_bar_width)||cfg$combo_bar_width<=0||cfg$combo_bar_width>.9)stop("combo_bar_width must be positive and at most 0.9 category units.")
if(is.null(cfg$show_mean_correlation))cfg$show_mean_correlation<-combo && cfg$combo_layout=="dual-axis" && cfg$combo_color_by=="metric"
if(!is.logical(cfg$show_mean_correlation)||length(cfg$show_mean_correlation)!=1||is.na(cfg$show_mean_correlation))stop("show_mean_correlation must be true or false.")
if(cfg$show_mean_correlation && !(combo && cfg$combo_layout=="dual-axis"))stop("show_mean_correlation requires dual-axis metrics.")
if(!is.logical(cfg$line_markers) || length(cfg$line_markers)!=1 || is.na(cfg$line_markers))stop("line_markers must be true or false.")
if(!is.numeric(cfg$line_marker_shape) || length(cfg$line_marker_shape)!=1 || !is.finite(cfg$line_marker_shape) || !cfg$line_marker_shape %in% 0:25)stop("line_marker_shape must be an integer from 0 to 25.")
for(k in c("point_alpha","fill_alpha","point_darken")) if(length(cfg[[k]])!=1 || !is.finite(cfg[[k]]) || cfg[[k]]<0 || cfg[[k]]>1) stop("Invalid alpha.")
if(cfg$occupancy<0.90 || cfg$occupancy>0.95) stop("Zoom occupancy must be between 0.90 and 0.95.")
resolve <- function(p) {p<-path.expand(p); if(!grepl("^/",p)) p<-file.path(dirname(config_path),p); normalizePath(p,mustWork=FALSE)}
if(is.null(cfg$input)||is.null(cfg$output_prefix)) stop("input and output_prefix are required.")
cfg$input <- normalizePath(resolve(cfg$input),mustWork=TRUE); cfg$output_prefix<-resolve(cfg$output_prefix)
nm<-basename(cfg$output_prefix);if(basename(dirname(cfg$output_prefix))!=nm)cfg$output_prefix<-file.path(dirname(cfg$output_prefix),nm,nm)
header<-names(read.csv(cfg$input,nrows=0,check.names=FALSE))
text_columns<-intersect(unique(c(cfg$id,cfg$model,cfg$metric)),header)
column_classes<-if(length(text_columns))setNames(rep("character",length(text_columns)),text_columns)else NA
raw <- read.csv(cfg$input,colClasses=column_classes,check.names=FALSE,stringsAsFactors=FALSE,na.strings=c("","NA","NaN"))
raw$.source_row<-seq_len(nrow(raw));n_input<-nrow(raw)
require_cols <- function(cols) {bad<-setdiff(cols,names(raw));if(length(bad))stop("Missing columns: ",paste(bad,collapse=", "))}
if(!is.null(cfg$filter)) for(k in names(cfg$filter)) {require_cols(k);raw<-raw[!is.na(raw[[k]]) & raw[[k]] %in% cfg$filter[[k]],,drop=FALSE]}
if(!nrow(raw))stop("No rows after filtering.")
filtered_rows<-setdiff(seq_len(n_input),raw$.source_row)
num <- function(x) {z<-suppressWarnings(as.numeric(x));if(any(!is.na(x)&is.na(z)))stop("Nonnumeric score or uncertainty.");z}
if(cfg$layout=="wide") {
 if(combo || cfg$data_mode!="raw" || is.null(cfg$model_columns))stop("Wide input supports raw single-metric data; model_columns is a named model-to-column mapping.")
 require_cols(unlist(cfg$model_columns));chunks<-lapply(names(cfg$model_columns),function(m){r<-raw;r$.model<-m;r$.value<-num(r[[cfg$model_columns[[m]]]]);r});raw<-do.call(rbind,chunks)
 cfg$model<-".model";cfg$value<-".value"
}
require_cols(c(cfg$model,cfg$value,cfg$id,cfg$sd,cfg$n,cfg$availability,cfg$metric))
metric_values <- if(is.null(cfg$metric)) rep("Metric",nrow(raw)) else as.character(raw[[cfg$metric]])
if(combo && (is.null(cfg$metric)||anyDuplicated(cfg$metrics)||length(cfg$metrics)<2))stop("Combination input requires a metric column and at least two distinct metrics.")
if(combo && !cfg$combo_layout %in% c("shared-axis","grouped-distributions") && length(cfg$metrics)!=2)stop("This combination layout requires exactly two metrics; shared-axis supports two or more.")
if(combo){
 if(cfg$combo_layout %in% c("shared-axis","grouped-distributions") && length(cfg$combo_styles)==1)cfg$combo_styles<-rep(cfg$combo_styles,length(cfg$metrics))
 if(length(cfg$combo_styles)!=length(cfg$metrics)||!all(cfg$combo_styles %in% if(cfg$combo_layout=="grouped-distributions")c("bar","box","violin")else c("bar","line")))stop("combo_styles must provide one supported entry per metric.")
 if(cfg$combo_layout=="shared-axis" && any(cfg$combo_styles!="line"))stop("shared-axis requires line styles for all metrics.")
 for(k in c("combo_limits","combo_breaks","combo_show_sd"))if(!is.null(cfg[[k]]) && (is.null(names(cfg[[k]]))||any(!names(cfg[[k]]) %in% cfg$metrics)))stop(k," must be named by selected metric IDs.")
 if(!is.null(cfg$combo_show_sd))for(v in cfg$combo_show_sd)if(!is.logical(v)||length(v)!=1||is.na(v))stop("combo_show_sd values must be true or false.")
 if(!is.null(cfg$combo_directions) && (is.null(names(cfg$combo_directions))||!setequal(names(cfg$combo_directions),cfg$metrics)||!all(unlist(cfg$combo_directions) %in% c("higher","lower"))))stop("combo_directions must map every selected metric to higher or lower.")
 if(is.null(cfg$combo_directions))cfg$combo_directions<-as.list(setNames(rep(cfg$direction,length(cfg$metrics)),cfg$metrics))
 metric_sd<-setNames(rep(cfg$show_sd,length(cfg$metrics)),cfg$metrics)
 if(cfg$combo_layout=="dual-axis")metric_sd[cfg$combo_styles=="line"]<-FALSE
 if(!is.null(cfg$combo_show_sd))for(k in names(cfg$combo_show_sd))metric_sd[[k]]<-cfg$combo_show_sd[[k]]
 cfg$combo_show_sd<-as.list(metric_sd)
}else metric_sd<-setNames(cfg$show_sd,"single")
if(combo){raw<-raw[metric_values %in% cfg$metrics,,drop=FALSE];metric_values<-as.character(raw[[cfg$metric]])} else if(!is.null(cfg$metric)){if(length(cfg$metrics)!=1)stop("Select exactly one metric.");raw<-raw[metric_values %in% cfg$metrics,,drop=FALSE];metric_values<-as.character(raw[[cfg$metric]])}
dat<-data.frame(source_row=raw$.source_row, model=as.character(raw[[cfg$model]]),metric=metric_values,
 id=if(is.null(cfg$id)) as.character(seq_len(nrow(raw))) else as.character(raw[[cfg$id]]),value=num(raw[[cfg$value]]),stringsAsFactors=FALSE)
if(anyNA(dat$model)||any(!nzchar(dat$model))||anyNA(dat$metric))stop("Missing model or metric.")
dat$original_value<-dat$value; dat$penalized<-FALSE
unavailable<-if(is.null(cfg$availability))rep(FALSE,nrow(raw)) else is.na(raw[[cfg$availability]])|tolower(trimws(as.character(raw[[cfg$availability]]))) %in% tolower(trimws(cfg$unavailable_values))
bad<-!is.finite(dat$value)|unavailable
excluded<-dat[FALSE,,drop=FALSE]
if(any(bad)) {
 if(cfg$missing=="error")stop("Missing/unavailable values; choose an explicit policy.")
 if(cfg$missing=="drop") {excluded<-dat[bad,,drop=FALSE];dat<-dat[!bad,,drop=FALSE];raw<-raw[!bad,,drop=FALSE]}
 if(cfg$missing=="penalty") {
  if(is.null(cfg$penalty))stop("Explicit penalty required; do not infer a theoretical bound from observed extremes.")
  for(k in unique(dat$metric)) {idx<-bad & dat$metric==k;v<-if(is.list(cfg$penalty)||length(cfg$penalty)>1)cfg$penalty[[k]] else cfg$penalty;if(length(v)!=1||!is.finite(v))stop("Invalid metric penalty.");dat$value[idx]<-v;dat$penalized[idx]<-TRUE}
 }
}
if(!nrow(dat))stop("No observations.")
# Resolve density-sensitive size after filtering/missing handling, using the densest group.
if(is.null(cfg$point_size))cfg$point_size<-if(cfg$data_mode=="raw" && max(table(dat$model,dat$metric))>=200)0.36 else 0.48
if(!is.numeric(cfg$point_size)||length(cfg$point_size)!=1||!is.finite(cfg$point_size)||cfg$point_size<=0)stop("Invalid positive setting: point_size")
if(cfg$data_mode=="raw" && cfg$paired){
 if(anyNA(dat$id)||any(!nzchar(dat$id))||anyDuplicated(dat[c("model","metric","id")]))stop("Each model/metric/ID must be unique and nonmissing.")
 for(k in unique(dat$metric)) {ids<-split(dat$id[dat$metric==k],dat$model[dat$metric==k]);if(!all(vapply(ids,function(x)setequal(x,ids[[1]]),logical(1))))stop("Paired models must contain identical ID sets; complete or explicitly resolve missing pairs first.")}
}
if(cfg$delta) {
 for(k in unique(dat$metric)) {ref<-dat[dat$model==cfg$reference & dat$metric==k,];if(!nrow(ref))stop("Reference missing.");idx<-which(dat$metric==k);dat$value[idx]<-dat$value[idx]-ref$value[match(dat$id[idx],ref$id)];if(anyNA(dat$value[idx]))stop("Unmatched reference IDs.")}
}
if(cfg$data_mode=="summary") {
 if(anyDuplicated(dat[c("model","metric")]))stop("Summary input requires one row per model/metric.")
 dat$sd<-if(is.null(cfg$sd))NA_real_ else num(raw[[cfg$sd]])
 dat$n<-if(is.null(cfg$n))NA_real_ else num(raw[[cfg$n]])
 if(any(dat$sd<0,na.rm=TRUE)||any(!is.finite(dat$sd)&!is.na(dat$sd)))stop("Invalid SD.")
 if(any((dat$n<1|dat$n!=floor(dat$n))&!is.na(dat$n)))stop("Invalid sample size.")
 sm<-data.frame(model=dat$model,metric=dat$metric,mean=dat$value,sd=dat$sd,n=dat$n)
} else {
 chunks<-split(seq_len(nrow(dat)),interaction(dat$model,dat$metric,drop=TRUE))
 sm<-do.call(rbind,lapply(chunks,function(idx)data.frame(model=dat$model[idx[1]],metric=dat$metric[idx[1]],mean=mean(dat$value[idx]),sd=if(length(idx)>1)sd(dat$value[idx])else NA_real_,n=length(idx))))
}
if(any(metric_sd) && any(!is.finite(sm$sd[if(combo)unname(metric_sd[sm$metric])else rep(TRUE,nrow(sm))])))stop("SD requested but not available for every displayed group.")
if(cfg$style=="violin" && any(sm$n<2))stop("Violin density requires at least two observations per group.")
if(combo && (!setequal(unique(dat$metric),cfg$metrics) || !all(vapply(cfg$metrics,function(k)setequal(sm$model[sm$metric==k],sm$model[sm$metric==cfg$metrics[1]]),logical(1)))))stop("Every selected metric must contain identical model sets.")
models<-unique(dat$model)
if(!is.null(cfg$model_order)){if(anyDuplicated(cfg$model_order)||!setequal(cfg$model_order,models))stop("model_order must cover every model exactly once.");models<-cfg$model_order}
if(!combo && is.null(cfg$model_order) && cfg$sort!="input") {o<-match(models,sm$model);asc<-if(cfg$orientation=="vertical")cfg$direction=="lower" else cfg$direction=="higher";if(cfg$sort=="reverse-performance")asc<-!asc;models<-models[order(sm$mean[o],decreasing=!asc,method="radix")]}
if(combo && is.null(cfg$model_order) && cfg$sort!="input"){
 if(is.null(cfg$combo_order_by))cfg$combo_order_by<-cfg$metrics[1]
 if(!cfg$combo_order_by %in% cfg$metrics)stop("combo_order_by must name a selected metric.")
 order_sm<-sm[sm$metric==cfg$combo_order_by,];vals<-order_sm$mean[match(models,order_sm$model)]
 order_direction<-if(is.null(cfg$combo_directions[[cfg$combo_order_by]]))cfg$direction else cfg$combo_directions[[cfg$combo_order_by]]
 decreasing<-if(cfg$orientation=="horizontal")order_direction=="lower"else order_direction=="higher";if(cfg$sort=="reverse-performance")decreasing<-!decreasing
 models<-models[order(vals,decreasing=decreasing,method="radix")]
}
labels<-setNames(models,models);if(!is.null(cfg$model_labels)){if(!all(models %in% names(cfg$model_labels)))stop("model_labels must cover every model.");labels<-unlist(cfg$model_labels)[models]}

# Metric-colored encodings do not reserve a method hue: their colors mean metrics.
model_color_active<-!(combo && (cfg$combo_color_by=="metric" || cfg$combo_layout=="shared-axis"))
model_color_resolution<-resolve_model_palette_mapping(models,pal,
 focal=if(model_color_active)user$highlight else character(),
 colors=cfg$color_values,saved_record=cfg$palette_mapping)
cols<-model_color_resolution$colors[models];cfg$palette_mapping<-model_color_resolution$record
invisible(grDevices::col2rgb(cols));cfg$color_values<-as.list(cols);cfg$model_order<-models
combo_metric_cols<-NULL
metric_color_policy<-NULL
if(combo && (cfg$combo_color_by=="metric" || cfg$combo_layout=="shared-axis")){
 if(cfg$combo_layout=="shared-axis")cfg$combo_color_by<-"metric"
 combo_metric_cols<-if(is.null(cfg$combo_metric_colors))fixed_palette_mapping(cfg$metrics,pal)[cfg$metrics]else unlist(cfg$combo_metric_colors)
 metric_color_policy<-if(is.null(cfg$combo_metric_colors))"fixed-palette-metric-identity"else"explicit-named-metric-map"
 if(is.null(cfg$combo_metric_colors) && cfg$combo_layout=="dual-axis" && length(cfg$combo_styles)==2 &&
    setequal(cfg$combo_styles,c("bar","line")) && cfg$palette %in% c("blue-yellow","blue-yellow-transparent")){
  combo_metric_cols<-setNames(ifelse(cfg$combo_styles=="bar",pal$categorical[3],pal$categorical[2]),cfg$metrics)
  metric_color_policy<-"fixed-blue-yellow-role-slots: bar=3, line=2"
 }
 if(!setequal(names(combo_metric_cols),cfg$metrics))stop("combo_metric_colors must map every selected metric exactly once.")
 invisible(grDevices::col2rgb(combo_metric_cols));combo_metric_cols<-combo_metric_cols[cfg$metrics];cfg$combo_metric_colors<-as.list(combo_metric_cols)
}
highlight<-cfg$highlight
if(is.null(highlight)&&!combo)highlight<-sm$model[if(cfg$direction=="higher")which.max(sm$mean)else which.min(sm$mean)]
if(!is.null(highlight)&&!all(highlight %in% models))stop("Unknown highlight model.")
cfg$highlight<-highlight
if(combo && !is.null(cfg$combo_sd_modes)){
 if(is.null(names(cfg$combo_sd_modes))||any(!names(cfg$combo_sd_modes) %in% cfg$metrics))stop("combo_sd_modes must be named by selected metric IDs.")
 for(key in names(cfg$combo_sd_modes)){
  mapped<-unlist(cfg$combo_sd_modes[[key]])
  if(!setequal(names(mapped),models)||!all(mapped %in% c("both","outward")))stop("Each combo_sd_modes entry must map every model to both or outward.")
 }
}
positions<-setNames(if(cfg$orientation=="horizontal")rev(seq_along(models))else seq_along(models),models)
sm$pos<-unname(positions[sm$model]);dat$pos<-unname(positions[dat$model]);sm$annotation<-sprintf("%.3f",sm$mean)
sm$rank<-NA_real_
for(key in unique(sm$metric)){
 ix<-sm$metric==key;direction_i<-if(combo)cfg$combo_directions[[key]]else cfg$direction
 sm$rank[ix]<-rank(if(direction_i=="higher")-sm$mean[ix]else sm$mean[ix],ties.method="min")
}
if(cfg$delta)sm$annotation<-sprintf("%+.3f",sm$mean)
sm$ink<-ifelse(sm$model %in% highlight,"#D62728","#111111")
sm$face<-ifelse(sm$model %in% highlight,"bold","plain")
significance<-list(enabled=FALSE,displayed=FALSE)
if(cfg$show_significance){
 if(combo)stop("Significance brackets currently require a single-metric comparison.")
 focal<-cfg$significance_model
 if(is.null(focal))focal<-user$highlight
 if(length(focal)!=1)stop("Specify one focal model before testing; do not select it from observed ranking.")
 significance<-focal_t_tests(dat,focal,cfg$paired,cfg$direction,cfg$p_adjust,cfg$data_mode)
}
sig_count<-if(isTRUE(significance$displayed))nrow(significance$comparisons)else 0L
annotation_layout<-resolve_comparison_annotations(cfg,sig_count)
sig_gutter<-annotation_layout$significance_gutter_mm*72/25.4
sig_top_gutter<-if(annotation_layout$significance_side=="above")sig_gutter else 0
sig_right_gutter<-if(annotation_layout$significance_side=="right")sig_gutter else 0
top_annotation_pt<-if(!combo && cfg$orientation=="vertical" && (annotation_layout$values_side=="above" || annotation_layout$rank_side=="above"))cfg$annotation_gap else 2
metric_lab <- function(x) {if(is.null(cfg$combo_labels))return(x);z<-unlist(cfg$combo_labels);if(!all(x %in% names(z)))stop("combo_labels must cover metrics.");unname(z[x])}
edge<-grDevices::adjustcolor(cfg$border_color,alpha.f=cfg$border_alpha)
point_cols<-vapply(cols,function(z){rgb<-grDevices::col2rgb(z)/255;grDevices::rgb(rgb[1]*(1-cfg$point_darken),rgb[2]*(1-cfg$point_darken),rgb[3]*(1-cfg$point_darken))},character(1))
base <- function()ggplot()+theme_classic(base_size=cfg$base_size,base_family="Arial")+
 theme(plot.title.position="plot",plot.title=element_text(size=cfg$title_size,hjust=.5,lineheight=1.02,margin=margin(t=if(is.null(cfg$panel_tag))0 else 5,b=if(!combo && cfg$orientation=="vertical")top_annotation_pt+sig_top_gutter else 2)),
 axis.title=element_text(size=cfg$axis_title_size),axis.title.x=element_text(margin=margin(t=1.5)),axis.title.y=element_text(margin=margin(r=1.5)),
 axis.text=element_text(size=cfg$axis_text_size,color="#222222",margin=margin(1,1,1,1)),axis.text.x=element_text(angle=if(cfg$orientation=="vertical")cfg$label_angle else 0,hjust=if(cfg$orientation=="horizontal" || cfg$label_angle==0).5 else 1),
 axis.line=element_line(linewidth=.25,color="#333333"),axis.ticks=element_line(linewidth=.22,color="#333333"),axis.ticks.length=grid::unit(1.3,"pt"),
 panel.spacing=grid::unit(1.5,"mm"),strip.text=element_text(size=cfg$base_size),legend.background=element_rect(fill="white",color=NA),
 plot.tag=element_text(family="Arial",face="bold",size=cfg$tag_size,hjust=0,vjust=1),plot.tag.position=c(0,1),plot.tag.location="plot",legend.title=element_blank(),
 plot.caption=element_text(size=5,hjust=0,margin=margin(t=2)),plot.margin=margin(cfg$outer_margin,cfg$outer_margin,cfg$outer_margin,cfg$outer_margin))+
 (if((combo || cfg$style=="bar") && !(combo && cfg$combo_color_by=="metric")) scale_fill_manual(values=cols) else NULL)+scale_color_manual(values=point_cols,guide="none")+
 scale_x_continuous(breaks=unname(positions),labels=unname(labels[names(positions)]),expand=expansion(add=cfg$category_padding))+
 labs(title=cfg$title,tag=cfg$panel_tag,x=NULL,y=cfg$value_label,caption=cfg$caption)
distributions<-list()
add_marks <- function(p,s,d,style,baseline=0,show_sd=cfg$show_sd,sd_modes="both",mark_color=NULL){
 force(baseline);force(show_sd);force(sd_modes);force(mark_color) # Freeze per-panel baselines before ggplot evaluates mappings.
 qlayers<-list()
 if(style=="bar")p<-p+geom_rect(data=s,aes(xmin=pos-cfg$bar_width/2,xmax=pos+cfg$bar_width/2,ymin=pmin(baseline,mean),ymax=pmax(baseline,mean),fill=model),color=NA,alpha=cfg$fill_alpha,show.legend=FALSE)+
  geom_rect(data=s,aes(xmin=pos-cfg$bar_width/2,xmax=pos+cfg$bar_width/2,ymin=pmin(baseline,mean),ymax=pmax(baseline,mean)),fill=NA,color=edge,linewidth=cfg$outline_width)
 if(style=="bar" && !is.null(mark_color))p$layers[[length(p$layers)-1]]$aes_params$fill<-mark_color
 if(style %in% c("box","violin"))for(m in unique(d$model)){
  dd<-d[d$model==m,];v<-dd$value;x<-dd$pos[1];q<-as.numeric(quantile(v,c(.25,.5,.75)));iq<-q[3]-q[1];wh<-range(v[v>=q[1]-1.5*iq & v<=q[3]+1.5*iq]);hw<-cfg$bar_width/2
  distributions[[paste(m,dd$metric[1],sep="/")]]<<-list(model=m,metric=dd$metric[1],q1=q[1],median=q[2],q3=q[3],whisker_min=wh[1],whisker_max=wh[2])
  if(style=="box"){
   p<-p+annotate("rect",xmin=x-hw,xmax=x+hw,ymin=q[1],ymax=q[3],fill=grDevices::adjustcolor(cols[[m]],alpha.f=cfg$fill_alpha),color=NA)+
    annotate("segment",x=c(x-hw,x+hw),xend=c(x-hw,x+hw),y=q[1],yend=q[3],color=edge,linewidth=cfg$outline_width)+
    annotate("segment",x=x,xend=x,y=c(wh[1],q[3]),yend=c(q[1],wh[2]),color=edge,linewidth=cfg$inner_width)+
    annotate("segment",x=x-hw*.45,xend=x+hw*.45,y=wh,yend=wh,color=edge,linewidth=cfg$inner_width)
   widths<-rep(hw,3)
   if(!cfg$show_points){vv<-v[v<wh[1]|v>wh[2]];if(length(vv))p<-p+annotate("point",x=rep(x,length(vv)),y=vv,color=point_cols[[m]],alpha=cfg$point_alpha,size=cfg$point_size)}
  }else{
   if(diff(range(v))==0) {yy<-rep(v[1],2);ww<-c(0,0)}else{den<-density(v,from=min(v),to=max(v),n=256);yy<-den$x;ww<-den$y/max(den$y)*.40}
   poly<-data.frame(x=c(x-ww,rev(x+ww)),y=c(yy,rev(yy)))
   p<-p+geom_polygon(data=poly,aes(x=x,y=y),fill=grDevices::adjustcolor(cols[[m]],alpha.f=cfg$fill_alpha),color=edge,linewidth=cfg$outline_width)
   widths<-if(length(unique(yy))>1)approx(yy,ww,xout=q,rule=2)$y else rep(.12,3)
  }
  qlayers<-c(qlayers,list(annotate("segment",x=x-widths[c(1,3)],xend=x+widths[c(1,3)],y=q[c(1,3)],yend=q[c(1,3)],color=edge,linewidth=cfg$inner_width,linetype=if(style=="box")"solid"else"dashed"),
   annotate("segment",x=x-widths[2],xend=x+widths[2],y=q[2],yend=q[2],color=edge,linewidth=cfg$outline_width*.75)))
 }
 if(cfg$show_points && style!="line"){
  if(is.null(mark_color))p<-p+geom_point(data=d,aes(x=pos,y=value,color=model),position=position_jitter(width=cfg$jitter_width,height=0,seed=cfg$seed),size=cfg$point_size,stroke=0,alpha=cfg$point_alpha)
  else {
   rgb<-grDevices::col2rgb(mark_color)/255;ink<-grDevices::rgb(rgb[1]*(1-cfg$point_darken),rgb[2]*(1-cfg$point_darken),rgb[3]*(1-cfg$point_darken))
   p<-p+geom_point(data=d,aes(x=pos,y=value),color=ink,position=position_jitter(width=cfg$jitter_width,height=0,seed=cfg$seed),size=cfg$point_size,stroke=0,alpha=cfg$point_alpha)
  }
 }
 for(layer in qlayers)p<-p+layer
 if(show_sd){
  s$.sd_lower<-ifelse(sd_modes=="outward" & s$mean>=baseline,s$mean,s$mean-s$sd)
  s$.sd_upper<-ifelse(sd_modes=="outward" & s$mean<baseline,s$mean,s$mean+s$sd)
  p<-p+geom_errorbar(data=s,aes(x=pos,ymin=.sd_lower,ymax=.sd_upper),width=.13,color=edge,linewidth=cfg$sd_width)
 }
 if(style %in% c("box","violin") && show_sd)p<-p+geom_point(data=s,aes(x=pos,y=mean),shape=23,fill="white",color=edge,size=.85,stroke=cfg$sd_width)
 if(style=="line") {
  p<-p+geom_line(data=s,aes(x=pos,y=mean,group=1),color=if(is.null(mark_color))"#777777"else mark_color,linetype=cfg$line_type,linewidth=cfg$mean_width)
  if(cfg$line_markers){
   if(is.null(mark_color))p<-p+geom_point(data=s,aes(x=pos,y=mean,color=model,fill=model),shape=cfg$line_marker_shape,size=cfg$line_marker_size,stroke=cfg$inner_width,show.legend=FALSE)
   else p<-p+geom_point(data=s,aes(x=pos,y=mean),color=mark_color,fill=mark_color,shape=cfg$line_marker_shape,size=cfg$line_marker_size,stroke=cfg$inner_width,show.legend=FALSE)
  }
 }
 p
}
axis_break_record<-NULL
mean_correlation<-NULL;correlation_placements<-list()
axis_note<-NULL;transformation<-NULL;combo_axes<-list();inside_value_placement<-list();metric_encoding<-if(!is.null(combo_metric_cols))list(color_by="metric",colors=cfg$combo_metric_colors,color_policy=metric_color_policy)else NULL
if(!combo){
 extent<-sm$mean
 if(cfg$show_sd)extent<-c(extent,sm$mean-sm$sd,sm$mean+sm$sd)
 if(cfg$style %in% c("box","violin")||cfg$show_points)extent<-c(extent,dat$value)
 if(cfg$delta||cfg$axis_policy=="zero"||(cfg$style=="bar"&&cfg$axis_policy!="zoom"))extent<-c(extent,0)
 rr<-range(extent,finite=TRUE);sp<-diff(rr);if(sp==0)sp<-max(abs(rr),1)*.1
 auto_limits<-is.null(cfg$limits) && is.null(cfg$data_limits)
 limits<-if(is.null(cfg$data_limits))cfg$limits else cfg$data_limits
 if(is.null(limits)){pad<-if(cfg$axis_policy=="zoom")sp*(1/cfg$occupancy-1)/2 else sp*.06;limits<-rr+c(-pad,pad);if(cfg$style=="bar"&&cfg$axis_policy!="zoom"&&rr[1]==0)limits[1]<-0}
 if(length(limits)!=2||any(!is.finite(limits))||diff(limits)<=0)stop("limits must increase.")
 if(min(extent)<limits[1]-1e-12||max(extent)>limits[2]+1e-12)stop("Limits would hide observations or uncertainty; expand them.")
 # Positive bars start at the axis; keep negative SD visible with an internal zero axis.
 if(cfg$style=="bar" && min(extent)>=0 && limits[1]<0)limits[1]<-0
 if(cfg$style=="bar" && max(extent)<=0 && limits[2]>0)limits[2]<-0
 if(is.null(cfg$breaks)){
  # Measure Arial labels at final print size and allow for labels/annotation gutters.
  available_mm<-if(cfg$orientation=="horizontal")cfg$width_mm-
   max(systemfonts::string_width(labels,family="Arial",size=cfg$category_text_size,res=72))*25.4/72-
   (cfg$right_margin+sig_right_gutter+cfg$outer_margin+5)*25.4/72 else cfg$height_mm-20
  cfg$breaks<-choose_axis_breaks(limits,available_mm,cfg$axis_text_size,cfg$orientation=="horizontal")
 }
 cfg$breaks<-cfg$breaks[cfg$breaks>=limits[1]-1e-10 & cfg$breaks<=limits[2]+1e-10]
 # Baseline extension changes the tick step and can bring an endpoint within
 # the shared completion threshold. Re-select and complete using the final
 # step until the automatic numeric view settles, as in multi-metric axes.
 # Explicit limits and breaks remain authoritative, including saved replay.
 for(iteration in seq_len(6)){
  previous_limits<-limits
  if(auto_limits && cfg$style=="bar" && cfg$axis_policy=="zoom"){
   if(min(extent)>0 && limits[1]>0)limits[1]<-max(0,min(limits[1],(min(extent)-cfg$bar_min_fraction*limits[2])/(1-cfg$bar_min_fraction)))
   if(max(extent)<0 && limits[2]<0)limits[2]<-min(0,max(limits[2],(max(extent)-cfg$bar_min_fraction*limits[1])/(1-cfg$bar_min_fraction)))
  }
  if(is.null(user$breaks))cfg$breaks<-choose_axis_breaks(limits,available_mm,cfg$axis_text_size,cfg$orientation=="horizontal")
  if(auto_limits && is.null(user$breaks)){
   completed<-complete_nearby_axis_ticks(limits,cfg$breaks)
   limits<-completed$limits;cfg$breaks<-completed$breaks
  }
  if(isTRUE(all.equal(previous_limits,limits,tolerance=1e-12)))break
 }
 if(auto_limits){
  zero_tolerance<-64*.Machine$double.eps*max(abs(limits),diff(limits),.Machine$double.xmin)
  limits[abs(limits)<=zero_tolerance]<-0
 }
 span<-diff(limits);cfg$limits<-limits
 baseline<-if(cfg$style=="bar"&&cfg$axis_policy=="zoom"&&limits[1]>0)limits[1] else if(cfg$style=="bar"&&cfg$axis_policy=="zoom"&&limits[2]<0)limits[2] else 0
 if(baseline!=0)axis_note<-sprintf("Truncated bar axis; baseline = %.6g. Compare labeled values, not bar lengths as ratios.",baseline)
 if(cfg$delta){axis_note<-paste(c(axis_note,"Paired differences are computed per ID before mean and SD; reference differences equal zero."),collapse=" ")}
 p<-add_marks(base(),sm,dat,cfg$style,baseline)
 if(cfg$style=="bar" && baseline>limits[1] && baseline<limits[2])p<-p+geom_hline(yintercept=baseline,linewidth=.25,color="#333333")+theme(axis.line.x=if(cfg$orientation=="vertical")element_blank()else element_line(linewidth=.25),axis.line.y=if(cfg$orientation=="horizontal")element_blank()else element_line(linewidth=.25))
 if(cfg$delta)p<-p+geom_hline(yintercept=0,linetype="dotted",linewidth=.25,color="#555555")
 # Estimate the physical data panel, then reserve a safe strip inside its numeric axis.
 core_limits<-limits;cfg$data_limits<-core_limits
 measurement_plot<-p+scale_y_continuous(breaks=cfg$breaks,labels=axis_labels,expand=expansion(mult=0))
 if(cfg$orientation=="horizontal")measurement_plot<-measurement_plot+coord_flip(xlim=c(1-cfg$category_padding,length(models)+cfg$category_padding),ylim=core_limits,clip="off",expand=FALSE)+theme(axis.text.y=element_text(size=cfg$category_text_size),plot.margin=margin(cfg$outer_margin,cfg$right_margin+sig_right_gutter,cfg$outer_margin,cfg$outer_margin))
 else measurement_plot<-measurement_plot+coord_cartesian(xlim=c(1-cfg$category_padding,length(models)+cfg$category_padding),ylim=core_limits,clip="off",expand=FALSE)+theme(axis.text.x=element_text(size=cfg$category_text_size,angle=cfg$label_angle,hjust=if(cfg$label_angle==0).5 else 1),plot.margin=margin(if(is.null(cfg$title)&&(cfg$show_rank||cfg$show_values||sig_count>0))top_annotation_pt+sig_top_gutter else cfg$outer_margin,cfg$outer_margin,cfg$outer_margin,cfg$outer_margin))
 fitted<-fit_comparison_text(measurement_plot,cfg,labels,positions,text_fit_policy,sm$annotation,cfg$show_values)
 cfg$label_angle<-fitted$label_angle;cfg$value_angle<-fitted$value_angle;labels<-fitted$labels
 text_fitting<-fitted$record
 p<-apply_comparison_text(p,cfg,labels,positions)
 measurement_plot<-apply_comparison_text(measurement_plot,cfg,labels,positions)
 annotation_layout$mark_extent_by_model<-setNames(lapply(models,function(m){
  ss<-sm[sm$model==m,];shown<-ss$mean
  if(cfg$show_sd)shown<-c(shown,ss$mean-ss$sd,ss$mean+ss$sd)
  if(cfg$style %in% c("box","violin")||cfg$show_points)shown<-c(shown,dat$value[dat$model==m])
  if(cfg$style=="bar")shown<-c(shown,baseline)
  range(shown,finite=TRUE)
 }),models)
 if(annotation_layout$significance_side=="inside-left"){
  comparisons<-significance$comparisons
  origin<-positions[[significance$focal]]
  comparisons<-comparisons[order(abs(positions[comparisons$comparator]-origin)),,drop=FALSE]
  annotation_layout$significance_span_floors<-vapply(comparisons$comparator,function(m){
   span_models<-names(positions)[positions>=min(origin,positions[[m]]) & positions<=max(origin,positions[[m]])]
   min(unlist(annotation_layout$mark_extent_by_model[span_models]))
  },numeric(1))
 }
 if(annotation_layout$values_side=="inside-bottom" || annotation_layout$significance_side=="inside-left"){
  panel_mm<-measure_comparison_panel_mm(measurement_plot,cfg)
  annotation_layout<-reserve_comparison_annotation_strip(annotation_layout,cfg,core_limits,extent,panel_mm,baseline,sm$annotation)
  limits<-annotation_layout$display_limits;cfg$limits<-limits;span<-diff(limits)
  if(is.null(user$breaks))cfg$breaks<-choose_axis_breaks(limits,panel_mm[if(cfg$orientation=="horizontal")"width"else"height"],cfg$axis_text_size,cfg$orientation=="horizontal")
  if(!isTRUE(all.equal(core_limits,limits)))axis_note<-paste(c(axis_note,"Numeric-axis display limits include an empty internal annotation strip; plotted values and uncertainty are unchanged."),collapse=" ")
 }else{annotation_layout$data_extent<-rr;annotation_layout$data_limits<-core_limits;annotation_layout$display_limits<-limits;annotation_layout$reserved_strip_mm<-0}
 # Saved display ticks may sit in the annotation strip below the core data
 # limits. Validate the original requested breaks against the final display
 # range rather than permanently filtering them during core-axis measurement.
 cfg$breaks<-snap_axis_breaks(if(is.null(user$breaks))cfg$breaks else user$breaks,limits)
 # Resolve the outside ranking strip before adding either label layer. Negative
 # bars can reach the zero baseline at the upper view boundary, so their ranking
 # text needs measured clearance from that mark edge, not only from the arrow.
 if(cfg$show_rank && annotation_layout$rank_side!="inside-bottom" && length(models)>1 &&
    (!"rank_text_gap" %in% names(user) || (cfg$orientation=="horizontal" && !"rank_offset" %in% names(user)))){
  rank_panel_mm<-measure_comparison_panel_mm(measurement_plot,cfg)[if(cfg$orientation=="horizontal")"width"else"height"]
  rank_height_mm<-max(arial_text_extents_mm("Performance Ranking",cfg$rank_size*72/25.4)["height",])
  if(!"rank_text_gap" %in% names(user)){
   cfg$rank_text_gap<-max(cfg$rank_text_gap,(rank_height_mm/2+.46)/rank_panel_mm)
   annotation_layout$rank_text_clearance_mm<-cfg$rank_text_gap*rank_panel_mm-rank_height_mm/2-.11
  }
  if(cfg$orientation=="horizontal" && !"rank_offset" %in% names(user)){
   mark_edge<-max(unlist(annotation_layout$mark_extent_by_model))
   required_offset<-(mark_edge-limits[2])/span+cfg$rank_text_gap+(rank_height_mm/2+.46)/rank_panel_mm
   cfg$rank_offset<-max(cfg$rank_offset,required_offset)
   if(!"value_offset" %in% names(user))cfg$value_offset<-max(cfg$value_offset,cfg$rank_offset+if(cfg$style=="bar").03 else .035)
   annotation_layout$rank_mark_clearance_mm<-(limits[2]+span*(cfg$rank_offset-cfg$rank_text_gap)-mark_edge)/span*rank_panel_mm-rank_height_mm/2
  }
 }
 if(cfg$show_values && annotation_layout$values_side!="inside-bottom")p<-p+geom_text(data=sm,aes(x=pos,y=limits[2]+span*cfg$value_offset,label=annotation),hjust=if(cfg$orientation=="horizontal")0 else .5,color=sm$ink,fontface=sm$face,size=cfg$value_size,angle=cfg$value_angle,family="Arial")
 if(cfg$show_rank && annotation_layout$rank_side!="inside-bottom" && length(models)>1){
  vals<-sm$mean[match(models,sm$model)];monotonic<-all(diff(vals)>=0)||all(diff(vals)<=0)
  if(!monotonic)stop("A single ranking arrow requires monotonic model order; sort by performance or disable show_rank.")
  worst<-which(if(cfg$direction=="higher")vals==min(vals)else vals==max(vals))[1];best<-tail(which(if(cfg$direction=="higher")vals==max(vals)else vals==min(vals)),1)
  arrow_y<-limits[2]+span*cfg$rank_offset
  p<-p+annotate("segment",x=positions[models[worst]],xend=positions[models[best]],y=arrow_y,yend=arrow_y,linewidth=.22,arrow=grid::arrow(length=grid::unit(.8,"mm"),type="closed"))+
   annotate("text",x=positions[models[worst]]+if(positions[models[worst]]>mean(positions))-.04 else .04,y=arrow_y-span*cfg$rank_text_gap,label="Performance Ranking",hjust=if(positions[models[worst]]>mean(positions))1 else 0,angle=if(cfg$orientation=="horizontal")90 else 0,family="Arial",size=cfg$rank_size)
 }
 p<-p+scale_y_continuous(breaks=cfg$breaks,labels=axis_labels,expand=expansion(mult=0))
 if(cfg$orientation=="horizontal")p<-p+coord_flip(xlim=c(1-cfg$category_padding,length(models)+cfg$category_padding),ylim=limits,clip="off",expand=FALSE)+theme(axis.text.y=element_text(size=cfg$category_text_size),plot.margin=margin(cfg$outer_margin,cfg$right_margin+sig_right_gutter,cfg$outer_margin,cfg$outer_margin))
 else p<-p+coord_cartesian(xlim=c(1-cfg$category_padding,length(models)+cfg$category_padding),ylim=limits,clip="off",expand=FALSE)+theme(axis.text.x=element_text(size=cfg$category_text_size,angle=cfg$label_angle,hjust=if(cfg$label_angle==0).5 else 1),plot.margin=margin(if(is.null(cfg$title)&&(cfg$show_rank||cfg$show_values||sig_count>0))top_annotation_pt+sig_top_gutter else cfg$outer_margin,cfg$outer_margin,cfg$outer_margin,cfg$outer_margin))
 if(!is.null(cfg$axis_break)){
  br<-apply_box_axis_break(p,cfg,dat,sm,rep(cfg$show_sd,nrow(sm)),cfg$limits,c(1-cfg$category_padding,length(models)+cfg$category_padding),explicit_ticks=!is.null(user$breaks))
  p<-br$plot;cfg$breaks<-br$breaks;cfg$right_margin<-br$right_margin;axis_break_record<-br$record;axis_note<-br$note
  p<-p+labs(caption=box_break_caption(p,cfg,br$note))
 }
} else if(cfg$combo_layout=="grouped-distributions") {
 source(file.path(skill_dir,"scripts/grouped_distributions.R"),local=TRUE)
} else if(cfg$combo_layout=="shared-rows") {
 source(file.path(skill_dir,"scripts/shared_rows.R"),local=TRUE)
} else if(cfg$combo_layout %in% c("stacked-bars","shared-axis")) {
 source(file.path(skill_dir,"scripts/multi_metric_layouts.R"),local=TRUE)
} else {
 if(cfg$orientation!="vertical" || cfg$delta)stop("Combination figures currently support vertical raw/summary values without delta mode.")
 if(length(cfg$combo_styles)!=2||!all(cfg$combo_styles %in% c("bar","line")))stop("combo_styles must contain two bar/line entries.")
 p<-base()
 if(cfg$combo_layout=="facets"){
  bounds_data<-list()
  for(i in 1:2){
   key<-cfg$metrics[i];ss<-sm[sm$metric==key,];dd<-dat[dat$metric==key,];style_i<-cfg$combo_styles[i]
   ax<-resolve_multi_axis(multi_metric_extent(ss,dd,metric_sd[[key]],cfg$show_points,style_i),cfg,cfg$combo_limits[[key]],cfg$combo_breaks[[key]],cfg$height_mm-20,FALSE,style_i)
   combo_axes[[key]]<-ax
   p<-add_marks(p,ss,dd,style_i,if(is.null(ax$baseline))0 else ax$baseline,metric_sd[[key]],if(cfg$combo_sd_display=="outward"&&style_i=="bar")"outward"else"both",combo_metric_cols[[key]])
   bounds_data[[key]]<-data.frame(metric=key,pos=1,value=ax$limits)
  }
  p<-p+geom_blank(data=do.call(rbind,bounds_data),aes(x=pos,y=value))+
   facet_wrap(~metric,scales="free_y",labeller=as_labeller(setNames(metric_lab(cfg$metrics),cfg$metrics)))+
   scale_y_continuous(labels=axis_labels,expand=expansion(mult=0),breaks=function(lim){
    match_axis<-which(vapply(combo_axes,function(ax)isTRUE(all.equal(unname(lim),unname(ax$limits),tolerance=1e-8)),logical(1)))
    if(length(match_axis))combo_axes[[match_axis[1]]]$breaks else choose_axis_breaks(lim,cfg$height_mm-20,cfg$axis_text_size,FALSE)
   })
  axis_note<-lapply(combo_axes,`[[`,"note")
 }else{
  if(!setequal(cfg$combo_styles,c("bar","line")))stop("Dual-axis overlay requires one bar and one line metric so marks remain distinguishable.")
  # Original units already appear on the axes; the style guide uses metric names.
  subtitle_text<-paste(paste(ifelse(cfg$combo_styles=="bar","Bars","Line"),cfg$metrics,sep=": "),collapse="   |   ")
  subtitle_width_mm<-cfg$width_mm-8-2*cfg$outer_margin*25.4/72
  subtitle_text<-wrap_arial_labels(subtitle_text,subtitle_width_mm,cfg$base_size-1)
  text_fitting$dual_axis_subtitle<-list(text=subtitle_text,width_mm=subtitle_width_mm,font_size_pt=cfg$base_size-1,units="retained in axis labels")
  p<-p+labs(subtitle=subtitle_text)+theme(plot.subtitle=element_text(hjust=.5,size=cfg$base_size-1,family="Arial"))
  a<-sm[sm$metric==cfg$metrics[1],];b<-sm[sm$metric==cfg$metrics[2],]
  if(cfg$show_mean_correlation)mean_correlation<-compute_method_mean_correlation(sm,cfg$metrics,models)
  da<-dat[dat$metric==cfg$metrics[1],];db<-dat[dat$metric==cfg$metrics[2],]
  ax_a<-resolve_multi_axis(multi_metric_extent(a,da,metric_sd[[cfg$metrics[1]]],cfg$show_points,cfg$combo_styles[1]),cfg,cfg$combo_limits[[cfg$metrics[1]]],cfg$combo_breaks[[cfg$metrics[1]]],cfg$height_mm-22,FALSE,cfg$combo_styles[1])
  ax_b<-resolve_multi_axis(multi_metric_extent(b,db,metric_sd[[cfg$metrics[2]]],cfg$show_points,cfg$combo_styles[2]),cfg,cfg$combo_limits[[cfg$metrics[2]]],cfg$combo_breaks[[cfg$metrics[2]]],cfg$height_mm-22,FALSE,cfg$combo_styles[2])
  # Reserve line-symbol edges and visible bar-SD caps on automatic dual axes.
  # This alters only the display range, never means, SD or source observations.
  dual_clearance<-list(adapted=FALSE,reason="Explicit axes or no overlapping line-symbol/SD-cap geometry.")
  line_i<-which(cfg$combo_styles=="line");bar_i<-which(cfg$combo_styles=="bar")
  line_key<-cfg$metrics[line_i];bar_key<-cfg$metrics[bar_i]
  if(cfg$line_markers && metric_sd[[bar_key]] && is.null(cfg$combo_limits[[line_key]]) && is.null(cfg$combo_breaks[[line_key]])) {
    line_rows<-if(line_i==1)a else b;bar_rows<-if(bar_i==1)a else b
    line_axis<-if(line_i==1)ax_a else ax_b;bar_axis<-if(bar_i==1)ax_a else ax_b
    original_range<-line_axis$limits;axis_mm<-cfg$height_mm-22
    required_mm<-cfg$line_marker_size*.65+cfg$sd_width/2+.35
    radius_mm<-cfg$line_marker_size*.65+.35
    cap_lo<-(bar_rows$mean-bar_rows$sd-bar_axis$limits[1])/diff(bar_axis$limits)
    cap_hi<-(bar_rows$mean+bar_rows$sd-bar_axis$limits[1])/diff(bar_axis$limits)
    inspect_range<-function(rng) {
      centers<-(line_rows$mean-rng[1])/diff(rng)
      min(c(abs(centers-cap_lo),abs(centers-cap_hi)))*axis_mm>=required_mm &&
        min(c(centers,1-centers))*axis_mm>=radius_mm
    }
    if(!inspect_range(original_range)) {
      grid<-expand.grid(lower=seq(0,.8,.05),upper=seq(0,.8,.05))
      grid<-grid[order(grid$lower+grid$upper,abs(grid$lower-grid$upper)),]
      chosen<-NULL
      for(j in seq_len(nrow(grid))) {
        candidate<-original_range+diff(original_range)*c(-grid$lower[j],grid$upper[j])
        if(inspect_range(candidate)){chosen<-candidate;break}
      }
      if(!is.null(chosen)) {
        line_axis<-resolve_multi_axis(multi_metric_extent(line_rows,if(line_i==1)da else db,metric_sd[[line_key]],cfg$show_points,"line"),cfg,chosen,NULL,axis_mm,FALSE,"line")
        if(line_i==1)ax_a<-line_axis else ax_b<-line_axis
        dual_clearance<-list(adapted=TRUE,line_metric=line_key,original_range=original_range,effective_range=chosen,
          minimum_symbol_to_cap_mm=required_mm,estimated_numeric_axis_mm=axis_mm,
          reason="Expanded an automatic line-axis display range to retain full symbols and visible bar-SD caps; original values and uncertainty are unchanged.")
      }else dual_clearance$reason<-"No safe automatic display-range expansion found; inspect the overlay or use facets."
    }
  }
  combo_axes[[cfg$metrics[1]]]<-ax_a;combo_axes[[cfg$metrics[2]]]<-ax_b
  ra<-ax_a$limits;rb<-ax_b$limits;slope<-diff(ra)/diff(rb);intercept<-ra[1]-slope*rb[1]
  b$mean<-b$mean*slope+intercept;b$sd<-b$sd*slope;db$value<-db$value*slope+intercept
  p<-add_marks(p,a,da,cfg$combo_styles[1],if(is.null(ax_a$baseline))0 else ax_a$baseline,metric_sd[[cfg$metrics[1]]],if(cfg$combo_sd_display=="outward"&&cfg$combo_styles[1]=="bar")"outward"else"both",combo_metric_cols[[cfg$metrics[1]]])
  p<-add_marks(p,b,db,cfg$combo_styles[2],if(is.null(ax_b$baseline))0 else ax_b$baseline*slope+intercept,metric_sd[[cfg$metrics[2]]],if(cfg$combo_sd_display=="outward"&&cfg$combo_styles[2]=="bar")"outward"else"both",combo_metric_cols[[cfg$metrics[2]]])
  secondary_inverse<-local({primary<-ra;secondary<-rb;function(x)affine_axis_inverse(x,primary,secondary)})
  p<-p+scale_y_continuous(name=metric_lab(cfg$metrics[1]),breaks=ax_a$breaks,labels=axis_labels,limits=ra,expand=expansion(mult=0),sec.axis=sec_axis(secondary_inverse,name=metric_lab(cfg$metrics[2]),breaks=ax_b$breaks,labels=axis_labels))
  axis_note<-lapply(combo_axes,`[[`,"note")
  transformation<-list(primary_range=ra,secondary_range=rb,slope=slope,intercept=intercept,automatic_marker_clearance=dual_clearance,axis_inverse_policy="Origin-based inverse with display-endpoint snapping within 64 machine epsilons; scientific values and limits are unchanged.",meaning="Secondary display coordinate = slope * secondary value + intercept; does not establish association.")
  if(cfg$combo_color_by=="metric"){
   legend_labels<-metric_lab(cfg$metrics)
   legend_shapes<-ifelse(cfg$combo_styles=="bar",NA_real_,cfg$line_marker_shape)
   legend_key_width<-max(3,cfg$line_marker_size)
   legend_key_height<-max(2,cfg$line_marker_size)
   legend_width<-sum(arial_text_extents_mm(legend_labels,cfg$axis_text_size)["width",])+length(cfg$metrics)*4.5
   legend_rows<-if(legend_width<=cfg$width_mm-2*cfg$outer_margin*25.4/72)1L else 2L
   keys<-data.frame(.x=NA_real_,.y=NA_real_,.metric=cfg$metrics)
   draw_dual_metric_key<-function(data,params,size){
    if(is.na(data$shape[1]))ggplot2::draw_key_rect(data,params,size)
    else ggplot2::draw_key_point(data,params,size)
   }
   p<-p+labs(subtitle=NULL)+geom_rect(data=keys,aes(xmin=.x,xmax=.x,ymin=.y,ymax=.y,fill=.metric),color=NA,na.rm=TRUE,show.legend=TRUE,key_glyph=draw_dual_metric_key)+
    scale_fill_manual(values=combo_metric_cols,breaks=cfg$metrics,labels=legend_labels,name=NULL,
      guide=guide_legend(nrow=legend_rows,byrow=TRUE,override.aes=list(alpha=1,color=unname(combo_metric_cols),fill=unname(combo_metric_cols),shape=legend_shapes,size=cfg$line_marker_size,stroke=cfg$inner_width)))+
    theme(legend.position="top",legend.text=element_text(size=cfg$axis_text_size,family="Arial"),legend.key.width=grid::unit(legend_key_width,"mm"),legend.key.height=grid::unit(legend_key_height,"mm"),legend.spacing.x=grid::unit(.7,"mm"),legend.margin=margin(1,1,1,1),legend.box.margin=margin(0,0,0,0),legend.box.spacing=grid::unit(.6,"mm"),legend.background=element_rect(fill="white",color=NA))
   metric_encoding$legend<-list(position="top",rows=legend_rows,font_size_pt=cfg$axis_text_size,labels=legend_labels,key_types=as.list(setNames(ifelse(cfg$combo_styles=="bar","colored-rectangle","mean-icon"),cfg$metrics)),line_marker_shape=cfg$line_marker_shape,line_marker_size_mm=cfg$line_marker_size,key_width_mm=legend_key_width,key_height_mm=legend_key_height,subtitle_replaced=TRUE)
  }
 }
 cfg$combo_limits<-lapply(combo_axes,`[[`,"limits");cfg$combo_breaks<-lapply(combo_axes,`[[`,"breaks")
 p<-p+coord_cartesian(xlim=c(1-cfg$category_padding,length(models)+cfg$category_padding),expand=FALSE,clip="off")
 fitted<-fit_comparison_text(p,cfg,labels,positions,text_fit_policy,NULL,FALSE)
 cfg$label_angle<-fitted$label_angle;cfg$value_angle<-fitted$value_angle;labels<-fitted$labels
 text_fitting<-fitted$record;p<-apply_comparison_text(p,cfg,labels,positions)
 cfg$show_rank<-FALSE;cfg$show_values<-FALSE
}
dir.create(dirname(cfg$output_prefix),recursive=TRUE,showWarnings=FALSE)
outputs<-paste0(cfg$output_prefix,".",cfg$formats)
if(cfg$input %in% c(outputs,paste0(cfg$output_prefix,".plotted-data.csv")))stop("Output would overwrite input.")
fonts<-list(family="Arial")
legend_placements<-list()
for(i in seq_along(cfg$formats)){
 device<-switch(cfg$formats[i],pdf=arial_pdf_device,svg=svglite::svglite,png=ragg::agg_png)
 # Build layout inside each Arial-capable output device for correct text metrics.
 if(cfg$formats[i]=="png")device(outputs[i],width=cfg$width,height=cfg$height,units="in",res=cfg$dpi,background="white")
 else device(outputs[i],width=cfg$width,height=cfg$height,bg="white")
 tryCatch({
  grid::grid.newpage()
  export_plot<-if(combo && cfg$combo_layout %in% c("shared-rows","stacked-bars"))NULL else p
  if(combo && cfg$combo_layout=="grouped-distributions") {
   placement<-place_grouped_legend(p,cfg,length(models),edge)
   export_plot<-placement$plot;legend_placements[[cfg$formats[i]]]<-placement$record
  }
  grob<-if(combo && cfg$combo_layout=="shared-rows")build_shared_rows_grob() else if(combo && cfg$combo_layout=="stacked-bars")build_stacked_bars_grob()else ggplotGrob(export_plot)
  if(combo && cfg$combo_layout %in% c("shared-axis","facets","dual-axis") && length(highlight))
   grob<-highlight_category_grob(grob,unname(labels[highlight]))
  # Include the entire ranking gutter when centering the title.
  ti<-which(grob$layout$name=="title")
  if(length(ti)){grob$layout$l[ti]<-1L;grob$layout$r[ti]<-length(grob$widths)}
  if(!is.null(mean_correlation)){
   placement<-add_method_mean_correlation(grob,export_plot,cfg,mean_correlation)
   grob<-placement$grob;correlation_placements[[cfg$formats[i]]]<-placement$record
  }
  if(!combo)grob<-add_comparison_annotations(grob,sm,positions,cfg,significance,annotation_layout)
  grid::grid.draw(grob)
 },finally=grDevices::dev.off())
 if(cfg$formats[i]=="pdf")fonts$pdf<-verify_pdf_arial(outputs[i])
 if(cfg$formats[i]=="svg")fonts$svg<-embed_arial_in_svg(outputs[i],faces)
}
write.csv(dat,paste0(cfg$output_prefix,".plotted-data.csv"),row.names=FALSE,na="")
write.csv(sm,paste0(cfg$output_prefix,".summary.csv"),row.names=FALSE,na="")
if(combo && cfg$combo_value_placement=="inside"){
 cfg$value_angle<-text_fit_policy$value_angle
 cfg$combo_sd_modes<-lapply(inside_value_placement,function(rec)as.list(setNames(ifelse(rec$sd_display=="outward","outward","both"),rec$model)))
}
jsonlite::write_json(cfg,paste0(cfg$output_prefix,".config.json"),pretty=TRUE,auto_unbox=TRUE,digits=NA,null="null")
sd_display_by_group<-NULL
if(combo){
 sd_display_by_group<-data.frame(model=sm$model,metric=sm$metric,mean=sm$mean,computed_sd=sm$sd,
  shown=unname(metric_sd[sm$metric]),display=ifelse(unname(metric_sd[sm$metric]),"both","not-displayed"),
  full_lower=sm$mean-sm$sd,full_upper=sm$mean+sm$sd,shown_lower=sm$mean-sm$sd,shown_upper=sm$mean+sm$sd)
 for(i in seq_len(nrow(sm))){
  key<-sm$metric[i];bar_i<-cfg$combo_styles[match(key,cfg$metrics)]=="bar"
  if(bar_i && sd_display_by_group$shown[i]){
   mode<-if(cfg$combo_sd_display=="outward")"outward"else"both"
   rec<-inside_value_placement[[key]]
   if(!is.null(rec))mode<-rec$sd_display[match(sm$model[i],rec$model)]
   sd_display_by_group$display[i]<-mode
   if(mode=="outward"){
    baseline_i<-combo_axes[[key]]$baseline
    if(sm$mean[i]>=baseline_i)sd_display_by_group$shown_lower[i]<-sm$mean[i]else sd_display_by_group$shown_upper[i]<-sm$mean[i]
   }
  }
  if(!sd_display_by_group$shown[i])sd_display_by_group$shown_lower[i]<-sd_display_by_group$shown_upper[i]<-NA_real_
 }
}
if(combo && cfg$combo_layout=="grouped-distributions")metric_encoding$legend_placement<-legend_placements
inside_labels_shown<-combo && cfg$combo_value_placement=="inside" && length(inside_value_placement)>0L
if(inside_labels_shown){
 inside_records<-do.call(rbind,inside_value_placement)
 annotation_layout$values_side<-"inside-bars"
 text_fitting$values<-list(angle_policy=text_fit_policy$value_angle,
  fits=all(inside_records$placement=="inside"),label_count=nrow(inside_records),size_mm=cfg$combo_inside_value_size,
  reason="Numeric labels are displayed inside bars with measured per-label rotation and view padding; see inside_value_placement for each label's geometry.")
 text_fitting$values_placement<-"inside-bars-with-measured-view-padding"
}
record<-list(n_input=n_input,n_plotted=nrow(dat),filtered_source_rows=filtered_rows,excluded=excluded,
 visual_profile=list(name=visual_profile,width_mm=cfg$width_mm,height_mm=cfg$height_mm,
  fonts_pt=list(title=cfg$title_size,axis_title=cfg$axis_title_size,axis_text=cfg$axis_text_size,method=cfg$category_text_size),
  numeric_value_size_mm=if(inside_labels_shown)cfg$combo_inside_value_size else cfg$value_size,line_marker_size_mm=cfg$line_marker_size,bar_width=cfg$bar_width,category_padding=cfg$category_padding),
 penalized_n=sum(dat$penalized),summary=sm,paired=cfg$paired,delta=cfg$delta,reference=cfg$reference,
 model_palette_mapping=cfg$palette_mapping,significance=significance, annotation_layout=annotation_layout,text_fitting=text_fitting,
 uncertainty=if(any(metric_sd))"sample standard deviation (not SEM or CI)"else "not displayed",
 uncertainty_by_metric=if(combo)cfg$combo_show_sd else NULL,sd_display_by_group=sd_display_by_group,combo_axes=if(combo)combo_axes else NULL,inside_value_placement=if(combo)inside_value_placement else NULL,metric_encoding=metric_encoding,axis_policy_requested=axis_policy_requested,
 mean_line_marker=list(shown=cfg$line_markers && if(combo)any(cfg$combo_styles=="line")else cfg$style=="line",shape=cfg$line_marker_shape,size_mm=cfg$line_marker_size),
 mean_correlation=mean_correlation,mean_correlation_placement=correlation_placements,
 axis_break=axis_break_record,physical_size_mm=c(width=cfg$width_mm,height=cfg$height_mm),distributions=distributions,axis_note=axis_note,dual_axis_transform=transformation,font_verification=fonts,
 provenance=list(input_md5=unname(tools::md5sum(cfg$input)),script_md5=unname(tools::md5sum(script_path)),significance_helper_md5=unname(tools::md5sum(file.path(skill_dir,"scripts/significance.R"))),annotation_helper_md5=unname(tools::md5sum(file.path(skill_dir,"scripts/comparison_annotations.R"))),text_fit_helper_md5=unname(tools::md5sum(file.path(skill_dir,"scripts/text_fit.R"))),multi_axis_helper_md5=unname(tools::md5sum(file.path(skill_dir,"scripts/multi_axes.R"))),legend_space_helper_md5=if(combo && cfg$combo_layout=="grouped-distributions")unname(tools::md5sum(file.path(skill_dir,"scripts/legend_space.R")))else NULL,grouped_distributions_helper_md5=if(combo && cfg$combo_layout=="grouped-distributions")unname(tools::md5sum(file.path(skill_dir,"scripts/grouped_distributions.R")))else NULL,axis_break_helper_md5=if(!is.null(cfg$axis_break))unname(tools::md5sum(file.path(skill_dir,"scripts/axis_break.R")))else NULL,inside_values_helper_md5=unname(tools::md5sum(file.path(skill_dir,"scripts/inside_values.R"))),generated_at_utc=format(Sys.time(),tz="UTC",usetz=TRUE)))
jsonlite::write_json(record,paste0(cfg$output_prefix,".statistics.json"),pretty=TRUE,auto_unbox=TRUE,digits=NA,null="null",na="null")
writeLines(capture.output(sessionInfo()),paste0(cfg$output_prefix,".session.txt"))
message("Rendered ",nrow(dat)," rows in ",length(models)," models; ",sum(dat$penalized)," penalty records.")
message(paste(outputs,collapse="\n"))
