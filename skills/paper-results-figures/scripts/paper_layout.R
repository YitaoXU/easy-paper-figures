# Physical manuscript panels: dimensions are resolved before drawing text and marks.
resolve_paper_dimensions <- function(cfg, user, default_height_mm=40) {
  if(!cfg$layout_columns %in% c(3,4)) stop("layout_columns must be 3 or 4.")
  if(!is.null(cfg$width_mm)) cfg$width<-cfg$width_mm/25.4
  else if(!"width" %in% names(user) || "layout_columns" %in% names(user)) cfg$width<-if(cfg$layout_columns==3)56/25.4 else 42/25.4
  if(!is.null(cfg$height_mm)) cfg$height<-cfg$height_mm/25.4
  else if(!"height" %in% names(user)) cfg$height<-default_height_mm/25.4
  cfg$width_mm<-cfg$width*25.4;cfg$height_mm<-cfg$height*25.4
  if(any(!is.finite(c(cfg$width_mm,cfg$height_mm))) || min(cfg$width_mm,cfg$height_mm)<=0)stop("Invalid physical dimensions.")
  cfg
}
