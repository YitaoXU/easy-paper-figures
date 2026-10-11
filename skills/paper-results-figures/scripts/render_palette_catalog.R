#!/usr/bin/env Rscript
# Render generic family references with actual Arial; no scientific data.
args <- commandArgs(TRUE)
script <- sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())][1])
skill <- normalizePath(file.path(dirname(script), ".."))
output <- if (length(args)) args[1] else file.path(skill, "examples", "palettes")
record_dir <- if (length(args) > 1) args[2] else NULL
dir.create(output, recursive=TRUE, showWarnings=FALSE)
source(file.path(skill, "scripts", "font_export.R"))
faces <- resolve_arial_fonts()
source(file.path(skill, "scripts", "palette_helpers.R"))
registry <- jsonlite::fromJSON(file.path(skill, "palettes", "palette-families.json"), simplifyVector=FALSE)
palettes <- jsonlite::fromJSON(file.path(skill, "palettes", "palettes.json"))

render <- function(stem, families, width_mm=180, row_mm=20) {
  height_mm <- 16 + length(families)*row_mm
  records <- list()
  for (format in c("pdf", "svg", "png")) {
    path <- file.path(output, paste0(stem, ".", format))
    if (format == "pdf") arial_pdf_device(path, width=width_mm/25.4, height=height_mm/25.4)
    if (format == "svg") svglite::svglite(path, width=width_mm/25.4, height=height_mm/25.4, bg="white")
    if (format == "png") ragg::agg_png(path, width=width_mm, height=height_mm, units="mm", res=600, background="white")
    grid::grid.newpage()
    text <- function(label,x,y,size=9,bold=FALSE,col="#333333",just="left")
      grid::grid.text(label,x=grid::unit(x,"mm"),y=grid::unit(y,"mm"),just=just,
        gp=grid::gpar(fontfamily="Arial",fontsize=size,fontface=if(bold)"bold"else"plain",col=col))
    text(if(length(families)==1)"Pastel four-color palette"else"Common palette families",4,height_mm-5,13,TRUE)
    text("Default ordered sequence. Upper strip: base RGB; lower strip: distribution-fill opacity.",4,height_mm-11,7.5)
    for (i in seq_along(families)) {
      family <- families[[i]];pal <- palettes[[family$recommended_preset]]
      yy <- height_mm-16-(i-1)*row_mm
      text(family$title,4,yy-3,10,TRUE)
      text(family$recommended_preset,4,yy-8,7)
      roles <- pal$focal_model_mapping
      capacity <- length(roles$focal_slots)+length(roles$comparator_slots)
      text(sprintf("Fill %.2f; up to %d methods with one focal",pal$fill_alpha,capacity),4,yy-13,7)
      colors <- pal$categorical[order_palette_slots(seq_along(pal$categorical),pal)];n <- length(colors);left <- 82;slot <- (width_mm-left-4)/n
      for (j in seq_along(colors)) {
        center <- left+(j-.5)*slot
        grid::grid.rect(x=grid::unit(center,"mm"),y=grid::unit(yy-3,"mm"),
          width=grid::unit(slot-.7,"mm"),height=grid::unit(4,"mm"),
          gp=grid::gpar(fill=colors[j],col="#CCCCCC",lwd=.3))
        grid::grid.rect(x=grid::unit(center,"mm"),y=grid::unit(yy-8,"mm"),
          width=grid::unit(slot-.7,"mm"),height=grid::unit(4,"mm"),
          gp=grid::gpar(fill=grDevices::adjustcolor(colors[j],alpha.f=pal$fill_alpha),col="#CCCCCC",lwd=.3))
        if(n<=6)text(colors[j],center,yy-13,6.5,just="centre")
      }
    }
    grDevices::dev.off()
    if(format=="pdf")records$pdf<-verify_pdf_arial(path)
    if(format=="svg")records$svg<-embed_arial_in_svg(path,faces)
  }
  if(!is.null(record_dir)){
    dir.create(record_dir,recursive=TRUE,showWarnings=FALSE)
    jsonlite::write_json(list(fonts=records,width_mm=width_mm,height_mm=height_mm,
      families=vapply(families,`[[`,character(1),"id")),file.path(record_dir,paste0(stem,".json")),pretty=TRUE,auto_unbox=TRUE)
  }
}
common <- Filter(function(x)x$tier=="common",registry$families)
render("palette-families-overview",common)
render("palette-pastel-green-blue-purple-peach",Filter(function(x)x$id=="pastel-green-blue-purple-peach",registry$families),row_mm=24)

# Compare only sequence, keeping each family's selected RGB set and fill opacity.
width_mm <- 180; height_mm <- 14 + length(common)*22
for (format in c("pdf", "svg", "png")) {
 path <- file.path(output,paste0("palette-order-comparison.",format))
 if(format=="pdf")arial_pdf_device(path,width=width_mm/25.4,height=height_mm/25.4)
 if(format=="svg")svglite::svglite(path,width=width_mm/25.4,height=height_mm/25.4,bg="white")
 if(format=="png")ragg::agg_png(path,width=width_mm,height=height_mm,units="mm",res=600,background="white")
 grid::grid.newpage()
 label<-function(x,y,s,size=8)grid::grid.text(s,x=grid::unit(x,"mm"),y=grid::unit(y,"mm"),just="left",gp=grid::gpar(fontfamily="Arial",fontsize=size))
 label(4,height_mm-5,"Color order: same colors, same opacity",13)
 for(i in seq_along(common)){
  family<-common[[i]];pal<-palettes[[family$recommended_preset]];yy<-height_mm-14-(i-1)*22
  label(4,yy-4,family$title,9)
  for(j in 1:2){
   mode<-c("ordered","shuffled")[j];slots<-order_palette_slots(seq_along(pal$categorical),pal,mode,42)
   colors<-pal$categorical[slots];slot<-(width_mm-90)/length(colors)
   label(54,yy-(j-1)*7,if(j==1)"Ordered"else"Shuffled (42)",7)
   for(k in seq_along(colors))grid::grid.rect(x=grid::unit(86+(k-.5)*slot,"mm"),y=grid::unit(yy-(j-1)*7,"mm"),width=grid::unit(slot-.7,"mm"),height=grid::unit(5,"mm"),gp=grid::gpar(fill=grDevices::adjustcolor(colors[k],alpha.f=pal$fill_alpha),col="#CCCCCC",lwd=.3))
  }
 }
 grDevices::dev.off()
 if(format=="pdf")verify_pdf_arial(path)
 if(format=="svg")embed_arial_in_svg(path,faces)
}
