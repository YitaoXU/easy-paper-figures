#!/usr/bin/env Rscript
# Render eligible single-metric candidates from one scientifically validated configuration.
sp <- gsub("~+~", " ", sub("^--file=", "", grep("^--file=", commandArgs(), value=TRUE)[1]), fixed=TRUE)
root <- dirname(dirname(normalizePath(sp)))
args <- commandArgs(TRUE)
if (!length(args) || length(args)>2) stop("Supply a base JSON configuration and optional comma-separated styles.")
status <- system2("bash", shQuote(file.path(root,"scripts/ensure_environment.sh")))
if (status!=0) stop("Environment setup failed.")
cache <- Sys.getenv("PAPER_FIGURES_CACHE",file.path(Sys.getenv("XDG_CACHE_HOME",path.expand("~/.cache")),"paper-results-figures"))
.libPaths(c(file.path(cache,"library"),.libPaths()))
cp <- normalizePath(args[1],mustWork=TRUE)
cfg <- jsonlite::fromJSON(cp)
if (is.null(cfg$plot_type)) cfg$plot_type <- "mutl-comparison"
if (!cfg$plot_type %in% c("mutl-comparison","multi-comparison")) stop("Candidates require single-metric multiple-model input.")
resolve <- function(p) {if(is.null(p))stop("input and output_prefix are required.");p<-path.expand(p);if(!grepl("^/",p))p<-file.path(dirname(cp),p);normalizePath(p,mustWork=FALSE)}
cfg$input <- normalizePath(resolve(cfg$input),mustWork=TRUE)
prefix <- resolve(cfg$output_prefix); stem <- basename(prefix)
parent <- dirname(prefix); if(basename(parent)==stem)parent<-dirname(parent)
is_raw <- is.null(cfg$data_mode) || cfg$data_mode=="raw"
has_ref <- isTRUE(cfg$paired) && !is.null(cfg$reference)
styles <- if(length(args)==2)strsplit(args[2],",",fixed=TRUE)[[1]] else if(is_raw)c("box","violin","bar",if(has_ref)"line") else "bar"
if(!length(styles)||anyDuplicated(styles)||!all(styles %in% c("box","violin","bar","line")))stop("Invalid or duplicate candidate styles.")
if(!is_raw && any(styles %in% c("box","violin")))stop("Summary input cannot create distributions.")
paths <- labels <- names_out <- character()
for(style in styles){
  candidate <- cfg;candidate$style<-style
  candidate$delta<-is_raw && has_ref && style=="line"
  candidate$show_points<-style!="line" && is_raw && (is.null(cfg$show_points)||isTRUE(cfg$show_points))
  candidate$show_sd<-if(is.null(cfg$show_sd))is_raw || !is.null(cfg$sd) else cfg$show_sd
  if(is.null(cfg$line_markers))candidate$line_markers<-TRUE
  if(candidate$delta){candidate$limits<-NULL;candidate$breaks<-NULL;candidate$axis_policy<-"full";candidate$value_label<-paste0("Difference in ",if(is.null(cfg$value_label))cfg$value else cfg$value_label);candidate$title<-paste0(if(is.null(cfg$title))"Paired comparison" else cfg$title,"\ndifference from ",if(!is.null(cfg$model_labels[[cfg$reference]]))cfg$model_labels[[cfg$reference]] else cfg$reference)}
  suffix<-if(candidate$delta)"delta_reference_line" else paste0(style,if(candidate$show_points)"_points",if(candidate$show_sd)"_sd")
  name<-paste0(stem,"_",suffix);folder<-file.path(parent,name);dir.create(folder,recursive=TRUE,showWarnings=FALSE)
  candidate$output_prefix<-file.path(folder,name)
  input_config<-file.path(folder,paste0(name,".input-config.json"))
  jsonlite::write_json(candidate,input_config,auto_unbox=TRUE,pretty=TRUE,null="null")
  log<-file.path(folder,"render.log")
  status<-system2("bash",c(shQuote(file.path(root,"scripts/render.sh")),shQuote(input_config)),stdout=log,stderr=log)
  if(status!=0)stop("Candidate failed; inspect ",log,". Completed candidates are retained.")
  resolved<-jsonlite::fromJSON(paste0(candidate$output_prefix,".config.json"))
  # Reuse assignments even when raw and reference-difference ranks differ.
  if(is.null(cfg$color_values))cfg$color_values<-resolved$color_values
  snap<-file.path(folder,"reproducibility");dir.create(snap,showWarnings=FALSE)
  for(sub in c("scripts","palettes")){
    dest<-file.path(snap,sub);dir.create(dest,showWarnings=FALSE)
    files<-list.files(file.path(root,sub),full.names=TRUE)
    if(!all(file.copy(files,dest,overwrite=TRUE)))stop("Failed to preserve renderer snapshot.")
  }
  writeLines(c("#!/usr/bin/env bash","set -euo pipefail",'figure_dir="$(cd "$(dirname "$0")" && pwd)"',paste0('bash "$figure_dir/reproducibility/scripts/render.sh" "$figure_dir/',name,'.config.json"')),file.path(folder,"reproduce.sh"))
  writeLines(c(paste0("# ",name),"","Generated with the reusable candidate workflow. Inspect this preview and the statistics before final delivery; rendering does not establish completed visual or scientific QA.","",paste0("Reproduce with `bash reproduce.sh`. Final settings: `",name,".config.json`. Source data remain external and read-only; their path and hash are recorded in the statistics. Renderer and palette snapshots are retained in `reproducibility/`.")),file.path(folder,"README.md"))
  names_out<-c(names_out,name);paths<-c(paths,candidate$output_prefix)
  labels<-c(labels,paste0(if(candidate$delta)"Paired difference" else tools::toTitleCase(style),if(candidate$show_points)" + points",if(candidate$show_sd)" + SD"))
}
first<-dirname(paths[1])
index<-c("# Candidate figures","","These candidates use the same source and model colors. Final layout review and data checks belong to the applying agent.","")
for(i in seq_along(paths)){
  formats<-c("pdf","svg","png","config.json")
  available<-formats[file.exists(paste0(paths[i],".",formats))]
  links<-vapply(available,function(ext)paste0("[",if(ext=="config.json")"Configuration" else toupper(ext),"](../",names_out[i],"/",names_out[i],".",ext,")"),character(1))
  index<-c(index,paste0("- ",labels[i],": ",paste(links,collapse=" · ")))
}
# Build an overview only when PNG output was requested for every candidate.
if(all(file.exists(paste0(paths,".png")))){
  configs<-lapply(paste0(paths,".config.json"),jsonlite::fromJSON)
  widths<-vapply(configs,function(c)c$width_mm,numeric(1));heights<-vapply(configs,function(c)c$height_mm,numeric(1))
  cw<-max(widths);ch<-max(heights)+4;nc<-min(2,length(paths));nr<-ceiling(length(paths)/nc)
  ragg::agg_png(file.path(first,"candidates-overview.png"),width=cw*nc,height=ch*nr,units="mm",res=260,background="white")
  grid::grid.newpage();grid::pushViewport(grid::viewport(layout=grid::grid.layout(nr,nc)))
  for(i in seq_along(paths)){
    grid::pushViewport(grid::viewport(layout.pos.row=ceiling(i/nc),layout.pos.col=(i-1)%%nc+1))
    grid::grid.raster(png::readPNG(paste0(paths[i],".png"),native=TRUE),y=(ch-4)/(2*ch),width=widths[i]/cw,height=heights[i]/ch)
    grid::grid.text(labels[i],y=1-1/ch,vjust=1,gp=grid::gpar(fontfamily="Arial",fontsize=6,fontface="bold"));grid::popViewport()
  }
  grDevices::dev.off();index<-c(index,"","![Candidate overview](candidates-overview.png)","","Overview style headers are outside individual figure dimensions.")
}
writeLines(index,file.path(first,"candidate-index.md"))
message("Candidate index: ",file.path(first,"candidate-index.md"))
