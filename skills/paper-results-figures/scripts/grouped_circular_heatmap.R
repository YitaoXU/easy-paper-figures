#!/usr/bin/env Rscript
# Matched item scores: proportional group sectors, model tracks and raw violins.
assert <- function(ok, message) if (!isTRUE(ok)) stop(message, call.=FALSE)
scalar_text <- function(x) is.character(x) && length(x)==1L && !is.na(x) && nzchar(trimws(x))
defaults <- function() list(plot_type="grouped-circular-heatmap", input=NULL, output_prefix=NULL,
  item="item", group="group", model="model", value="score", metric_label=NULL,
  metric_domain=NULL, sampling_unit=NULL, direction="higher", focus_model=NULL,
  model_order=NULL, group_order=NULL, item_order=NULL,
  heatmap_palette="muted-green-blue-purple-light", palette=NULL,
  group_palette=NULL, color_values=NULL, palette_mapping=NULL,
  group_colors=NULL, show_violin=TRUE, show_mean=TRUE, group_legend_placement="auto",
  show_significance=FALSE, significance_model=NULL, independent_items=NULL, p_adjust="holm",
  show_item_labels=TRUE, label_every=NULL,
  title=NULL, caption=NULL, width_mm=180, height_mm=168,
  item_text_size=5.6, text_size=7, title_size=9, dpi=600,
  violin_model_size=9, violin_text_size=8, violin_tick_size=7.5, violin_axis_title_size=8.5,
  formats=c("pdf","svg","png"))

prepare <- function(raw,cfg) {
  cols<-c(cfg$item,cfg$group,cfg$model,cfg$value)
  assert(length(cols)==4L && !anyDuplicated(cols) && all(cols %in% names(raw)),
    "Map item, group, model and value to four distinct existing columns.")
  dat<-data.frame(source_row=seq_len(nrow(raw)),item=as.character(raw[[cfg$item]]),
    group=as.character(raw[[cfg$group]]),model=as.character(raw[[cfg$model]]),score=raw[[cfg$value]])
  assert(nrow(dat)>0L,"Input is empty.")
  for(k in c("item","group","model")) assert(!anyNA(dat[[k]]) && all(nzchar(trimws(dat[[k]]))),paste(k,"must contain nonempty IDs."))
  assert(is.numeric(dat$score) && all(is.finite(dat$score)),"Scores must be finite numeric raw observations; no exclusion or imputation is performed.")
  assert(!anyDuplicated(dat[c("item","model")]),"Duplicate item/model values: establish an observation-level key; no averaging is performed.")
  assert(all(vapply(split(dat$group,dat$item),function(x)length(unique(x))==1L,logical(1))),"Each item must belong to exactly one group across models.")
  items<-unique(dat$item);models<-unique(dat$model)
  assert(length(models)>=2L && length(models)<=6L,"This compound layout supports two to six models.")
  assert(nrow(dat)==length(items)*length(models),"All models must have exactly the same item set; missing cells are an error.")
  assert(is.numeric(cfg$metric_domain) && length(cfg$metric_domain)==2L && all(is.finite(cfg$metric_domain)) && diff(cfg$metric_domain)>0,"Declare metric_domain as two increasing scientific bounds.")
  assert(all(dat$score>=cfg$metric_domain[1] & dat$score<=cfg$metric_domain[2]),"Scores fall outside the declared metric domain; values are never clipped.")
  assert(scalar_text(cfg$metric_label) && scalar_text(cfg$sampling_unit),"Declare metric_label and sampling_unit.")
  assert(cfg$direction %in% c("higher","lower"),"direction must be higher or lower.")
  focus<-cfg$focus_model
  if(is.null(focus))focus<-if("Ours" %in% models)"Ours" else character()
  assert(is.character(focus) && length(focus)<=1L && all(focus %in% models),"focus_model must name one observed model or be null.")
  means<-tapply(dat$score,dat$model,mean)
  if(is.null(cfg$model_order)) {
    comparators<-setdiff(sort(models,method="radix"),focus)
    # Outer-to-inner / top-to-bottom: weak to strong, focal last.
    comparators<-comparators[order(if(cfg$direction=="higher")means[comparators]else -means[comparators])]
    cfg$model_order<-c(comparators,focus)
  }
  exact_order<-function(x,observed,name) assert(is.character(x) && !anyNA(x) && !anyDuplicated(x) && setequal(x,observed),paste(name,"must list every observed ID exactly once."))
  exact_order(cfg$model_order,models,"model_order")
  counts<-table(unique(dat[c("item","group")])$group)
  assert(length(counts)<=12L,"The group guide supports up to twelve groups; select a separate figure for additional groups.")
  if(is.null(cfg$group_order))cfg$group_order<-names(counts)[order(-as.integer(counts),names(counts))]
  exact_order(cfg$group_order,unique(dat$group),"group_order")
  if(is.null(cfg$item_order))cfg$item_order<-unlist(lapply(cfg$group_order,function(g)sort(unique(dat$item[dat$group==g]),method="radix")),use.names=FALSE)
  exact_order(cfg$item_order,items,"item_order")
  cfg$focus_model<-if(length(focus))focus else NULL
  list(data=dat,config=cfg,counts=counts)
}

render <- function(config_path,skill_dir) {
  cfg<-defaults();request<-jsonlite::fromJSON(config_path)
  unknown<-setdiff(names(request),names(cfg));assert(!length(unknown),paste("Unknown configuration fields:",paste(unknown,collapse=", ")))
  for(k in names(request))cfg[k]<-list(request[[k]])
  if(isTRUE(cfg$show_significance) && !"show_mean" %in% names(request))cfg$show_mean<-FALSE
  assert(identical(cfg$plot_type,"grouped-circular-heatmap"),"Incorrect plot_type.")
  assert(scalar_text(cfg$input) && scalar_text(cfg$output_prefix),"Supply input and output_prefix.")
  assert(is.numeric(cfg$width_mm) && is.numeric(cfg$height_mm) && length(cfg$width_mm)==1L && length(cfg$height_mm)==1L && is.finite(cfg$width_mm) && is.finite(cfg$height_mm) && cfg$width_mm>=160 && cfg$height_mm>=155,"The dense compound figure requires an explicit full-row allocation of at least 160 x 155 mm.")
  for(k in c("item_text_size","text_size","title_size","dpi","violin_model_size","violin_text_size","violin_tick_size","violin_axis_title_size"))assert(is.numeric(cfg[[k]]) && length(cfg[[k]])==1L && is.finite(cfg[[k]]) && cfg[[k]]>0,paste(k,"must be a positive finite number."))
  for(k in c("show_violin","show_mean","show_significance","show_item_labels"))assert(is.logical(cfg[[k]]) && length(cfg[[k]])==1L && !is.na(cfg[[k]]),paste(k,"must be boolean."))
  assert(scalar_text(cfg$p_adjust) && cfg$p_adjust %in% c("none","holm"),"p_adjust must be none or holm.")
  if(cfg$show_significance){
    assert(cfg$show_violin,"Significance annotations require show_violin: true.")
    assert(!cfg$show_mean,"Choose mean or significance annotations, not both.")
    assert(isTRUE(cfg$independent_items),"Significance requires independent_items: true, establishing independent matched-item differences.")
    assert(scalar_text(cfg$significance_model),"Supply an explicit significance_model for the scientific focal hypothesis.")
  }
  assert(scalar_text(cfg$group_legend_placement) && cfg$group_legend_placement %in% c("auto","center","right"),"group_legend_placement must be auto, center or right.")
  assert(is.character(cfg$formats) && length(cfg$formats)>0 && !anyDuplicated(cfg$formats) && all(cfg$formats %in% c("pdf","svg","png")),"formats must select pdf, svg or png.")
  raw<-read.csv(cfg$input,check.names=FALSE,colClasses="character")
  assert(cfg$value %in% names(raw),"Input lacks the mapped score column.")
  raw[[cfg$value]]<-suppressWarnings(as.numeric(raw[[cfg$value]]))
  prep<-prepare(raw,cfg);dat<-prep$data;cfg<-prep$config;counts<-prep$counts
  palettes<-jsonlite::fromJSON(file.path(skill_dir,"palettes","palettes.json"),simplifyVector=TRUE)
  if(is.null(cfg$palette))cfg$palette<-cfg$heatmap_palette
  if(is.null(cfg$group_palette)){
    assert(cfg$heatmap_palette %in% names(palettes),"Unknown heatmap_palette")
    group_slots<-palettes[[cfg$heatmap_palette]]$group_categorical
    if(is.null(group_slots))group_slots<-palettes[[cfg$heatmap_palette]]$categorical
    cfg$group_palette<-if(length(cfg$group_order)<=length(group_slots))cfg$heatmap_palette else "muted-balanced-twelve"
  }
  for(k in c("heatmap_palette","palette","group_palette"))assert(cfg[[k]] %in% names(palettes),paste("Unknown",k))
  model_map<-resolve_model_palette_mapping(cfg$model_order,palettes[[cfg$palette]],cfg$focus_model,cfg$color_values,cfg$palette_mapping)
  cfg$color_values<-as.list(model_map$colors);cfg$palette_mapping<-model_map$record
  group_preset<-palettes[[cfg$group_palette]]
  if(!is.null(group_preset$group_categorical))group_preset$categorical<-group_preset$group_categorical
  group_colors<-if(is.null(cfg$group_colors))fixed_palette_mapping(cfg$group_order,group_preset)else unlist(cfg$group_colors)
  assert(is.character(group_colors) && !is.null(names(group_colors)) && !anyDuplicated(names(group_colors)) && all(cfg$group_order %in% names(group_colors)),"group_colors must cover every group by name.")
  grDevices::col2rgb(group_colors);cfg$group_colors<-as.list(group_colors[cfg$group_order])
  ramp<-grDevices::colorRamp(palettes[[cfg$heatmap_palette]]$continuous)
  heat_color<-function(v)grDevices::rgb(ramp((v-cfg$metric_domain[1])/diff(cfg$metric_domain)),maxColorValue=255)
  # Stable physical geometry, with the whole canvas explicitly allocated.
  W<-cfg$width_mm;H<-cfg$height_mm;cy<-.492*H
  if(cfg$group_legend_placement=="auto")cfg$group_legend_placement<-if(length(cfg$group_order)>6L)"right" else "center"
  faces<-resolve_arial_fonts()
  metric_probe<-tempfile(fileext=".pdf");arial_pdf_device(metric_probe,W/25.4,H/25.4)
  measured_group_widths<-tryCatch(vapply(cfg$group_order,function(g)grid::convertWidth(grid::grobWidth(grid::textGrob(paste0(g," (n=",counts[[g]],")"),gp=grid::gpar(fontfamily="Arial",fontsize=6))),"mm",valueOnly=TRUE),numeric(1)),finally={grDevices::dev.off();unlink(metric_probe)})
  sidebar_width<-if(cfg$group_legend_placement=="right")max(measured_group_widths)+7 else 0
  cx<-if(sidebar_width>0)(W-sidebar_width-3)/2 else .5*W
  R<-min(.355*W,.382*H)
  # Additional guide rows require a larger hole, while every model still gets a track.
  guide_rows<-if(cfg$group_legend_placement=="center")ceiling(length(cfg$group_order)/2) else 0L
  inner<-max(.405*R, 18+2.5*guide_rows)
  gap<-min(5,25/max(1,length(cfg$group_order)-1));sweep<-278
  unit_angle<-(sweep-gap*(length(cfg$group_order)-1))/length(cfg$item_order)
  assert(unit_angle>0,"Too many groups to allocate positive sector angles.")
  if(is.null(cfg$label_every))cfg$label_every<-max(1L,ceiling(cfg$item_text_size*25.4/72*1.10/(R*unit_angle*pi/180)))
  assert(is.numeric(cfg$label_every) && length(cfg$label_every)==1L && is.finite(cfg$label_every) && cfg$label_every>=1 && cfg$label_every==as.integer(cfg$label_every),"label_every must be a positive integer.")
  start<-90;positions<-list();sectors<-list()
  for(g in cfg$group_order) {
    ids<-cfg$item_order[cfg$item_order %in% dat$item[dat$group==g]]
    end<-start+length(ids)*unit_angle
    sectors[[g]]<-list(group=g,start=start,end=end,n=length(ids),color=group_colors[[g]])
    positions[[g]]<-data.frame(item=ids,group=g,start=start+(seq_along(ids)-1)*unit_angle,end=start+seq_along(ids)*unit_angle)
    start<-end+gap
  }
  item_pos<-do.call(rbind,positions);rownames(item_pos)<-NULL
  dat<-merge(dat,item_pos,by=c("item","group"),sort=FALSE);dat<-dat[order(dat$source_row),]
  track_height<-(R-inner)/length(cfg$model_order)
  dat$track<-match(dat$model,cfg$model_order)
  dat$outer_mm<-R-(dat$track-1)*track_height;dat$inner_mm<-dat$outer_mm-track_height
  dat$fill<-heat_color(dat$score)
  summary<-do.call(rbind,lapply(cfg$model_order,function(m){v<-dat$score[dat$model==m];q<-quantile(v,c(.25,.5,.75),names=FALSE);data.frame(model=m,n=length(v),mean=mean(v),sd=sd(v),min=min(v),q1=q[1],median=q[2],q3=q[3],max=max(v))}))
  group_summary<-aggregate(score~group+model,dat,mean)
  significance<-list(enabled=FALSE,displayed=FALSE)
  if(cfg$show_significance){
    test_data<-data.frame(id=dat$item,model=dat$model,value=dat$score)
    significance<-focal_t_tests(test_data,cfg$significance_model,paired=TRUE,direction=cfg$direction,adjust=cfg$p_adjust,data_mode="raw")
    differences<-lapply(significance$comparisons$comparator,function(m){
      f<-dat[dat$model==cfg$significance_model,];o<-dat[dat$model==m,];f$score-o$score[match(f$item,o$item)]
    })
    significance$comparisons$mean_difference<-vapply(differences,mean,numeric(1))
    significance$comparisons$sd_difference<-vapply(differences,sd,numeric(1))
    # Do not infer a paired effect from parser/rounding noise at source precision.
    f<-dat[dat$model==cfg$significance_model,]
    tolerance<-vapply(significance$comparisons$comparator,function(m){
      o<-dat[dat$model==m,];8*.Machine$double.eps*max(abs(c(f$score,o$score)))
    },numeric(1))
    indistinguishable<-vapply(seq_along(differences),function(j)max(abs(differences[[j]]))<=tolerance[j],logical(1))
    significance$comparisons$source_precision_tolerance<-tolerance
    if(any(indistinguishable)){
      tab<-significance$comparisons
      tab[indistinguishable,c("t_statistic","df","p_value")]<-NA_real_
      tab$status[indistinguishable]<-"not_testable"
      tab$reason[indistinguishable]<-"Paired differences are numerically indistinguishable at source-scale floating precision."
      tab$p_adjusted<-stats::p.adjust(tab$p_value,method=cfg$p_adjust)
      tab$significant<-is.finite(tab$p_adjusted)&tab$p_adjusted<.05
      significance$comparisons<-tab
      significance$all_significant<-all(tab$significant)
      significance$displayed<-significance$all_significant
      significance$reason<-"At least one focal-versus-other test does not meet the threshold or cannot be evaluated; no significance brackets are drawn."
    }
    # Keep the complete prespecified comparison family, including failed tests.
    tab<-significance$comparisons
    tab$p_adjusted<-stats::p.adjust(tab$p_value,method=cfg$p_adjust,n=nrow(tab))
    tab$significant<-is.finite(tab$p_adjusted)&tab$p_adjusted<.05
    significance$comparisons<-tab
    significance$all_significant<-all(tab$significant)
    significance$displayed<-significance$all_significant
    significance$independent_items<-TRUE
  }
  densities<-list();violin_notes<-list()
  for(m in cfg$model_order){v<-dat$score[dat$model==m]
    if(length(v)<3L || length(unique(v))<2L){densities[[m]]<-NULL;violin_notes[[m]]<-"Insufficient varying raw observations; show an exact point/range instead of a KDE.";next}
    d<-density(v,bw="nrd0",n=512,from=min(v),to=max(v),cut=0)
    densities[[m]]<-data.frame(model=m,score=d$x,density=d$y)
  }
  prefix<-cfg$output_prefix
  dir.create(dirname(prefix),recursive=TRUE,showWarnings=FALSE)
  outputs<-paste0(prefix,c(paste0(".",cfg$formats),".config.json",".statistics.json",".plotted-data.csv",".density.csv",".session.txt"))
  assert(!normalizePath(cfg$input,mustWork=TRUE) %in% normalizePath(outputs,mustWork=FALSE),"Output would overwrite input.")
  text_bounds<-list();layout_record<-list();label_record<-list()
  draw<-function(measure=FALSE,svg_gradient=FALSE){
    grid::grid.newpage()
    xy<-function(r,a)cbind(cx+r*cos(a*pi/180),cy+r*sin(a*pi/180))
    line<-function(x,y,lwd=.6,lty=1,col="#747474")grid::grid.lines(grid::unit(x,"mm"),grid::unit(y,"mm"),gp=grid::gpar(col=col,lwd=lwd,lty=lty))
    txt<-function(label,x,y,size=cfg$text_size,just="centre",rot=0,face="plain"){
      grob<-grid::textGrob(label,x=grid::unit(x,"mm"),y=grid::unit(y,"mm"),just=just,rot=rot,gp=grid::gpar(fontfamily="Arial",fontsize=size,fontface=face,col="#282828"))
      grid::grid.draw(grob)
      {
        w<-grid::convertWidth(grid::grobWidth(grid::textGrob(label,gp=grob$gp)),"mm",valueOnly=TRUE)
        h<-size*25.4/72*1.18
        corners<-rbind(c(0,-h/2),c(w,-h/2),c(w,h/2),c(0,h/2))
        if(just=="right")corners[,1]<-corners[,1]-w else if(just=="centre")corners[,1]<-corners[,1]-w/2
        theta<-rot*pi/180;transform<-matrix(c(cos(theta),sin(theta),-sin(theta),cos(theta)),2,2)
        p<-corners%*%t(transform);p[,1]<-p[,1]+x;p[,2]<-p[,2]+y
        box<-c(left=min(p[,1]),right=max(p[,1]),bottom=min(p[,2]),top=max(p[,2]))
        if(measure){
          assert(box[1]>=.7 && box[2]<=W-.7 && box[3]>=.7 && box[4]<=H-.7,paste("Text exceeds canvas:",label,". Increase dimensions or provide shorter labels."))
          text_bounds[[length(text_bounds)+1L]]<<-list(label=label,box_mm=box)
        }
        invisible(box)
      }
    }
    annulus<-function(a,b,r0,r1,fill,border=NA,lwd=.18){
      angles<-seq(a,b,length.out=max(3L,ceiling((b-a)/.45)+1L))
      p<-rbind(xy(r1,angles),xy(r0,rev(angles)))
      grid::grid.polygon(grid::unit(p[,1],"mm"),grid::unit(p[,2],"mm"),gp=grid::gpar(fill=fill,col=border,lwd=lwd))
    }
    if(!is.null(cfg$title))txt(cfg$title,W/2,H-4,cfg$title_size,face="bold")
    for(i in seq_len(nrow(dat)))annulus(dat$start[i],dat$end[i],dat$inner_mm[i],dat$outer_mm[i],dat$fill[i],"white",.22)
    for(s in sectors){
      annulus(s$start,s$end,inner-4.3,inner-1.2,s$color)
      for(k in seq_len(length(cfg$model_order)-1L)){p<-xy(R-k*track_height,seq(s$start,s$end,length.out=160));line(p[,1],p[,2],.55)}
    }
    item_boxes<-list()
    if(cfg$show_item_labels)for(g in cfg$group_order){
      pos<-item_pos[item_pos$group==g,];selected<-seq(1,nrow(pos),by=cfg$label_every)
      selected<-selected[nrow(pos)-selected>=cfg$label_every]
      selected<-c(selected,nrow(pos))
      for(i in selected){a<-mean(c(pos$start[i],pos$end[i]));p<-xy(c(R+.6,R+1.5),a);line(p[,1],p[,2],.35)
        anchor<-xy(R+2,a);rot<-a%%360;just<-"left"
        if(rot>90 && rot<270){rot<-rot+180;just<-"right"}
        # Preserve each group endpoint without adding a neighboring label inside the stride.
        item_boxes[[length(item_boxes)+1L]]<-txt(pos$item[i],anchor[1],anchor[2],cfg$item_text_size,just,rot)
        if(measure)label_record[[length(label_record)+1L]]<<-list(item=pos$item[i],group=g,angle_degrees=a)
      }
    }
    # Single model key beside the open top boundary, aligned with violin rows.
    ys<-cy+R-(seq_along(cfg$model_order)-.5)*track_height
    model_size<-if(cfg$show_violin)cfg$violin_model_size else cfg$text_size
    widths<-vapply(cfg$model_order,function(m)grid::convertWidth(grid::grobWidth(grid::textGrob(m,gp=grid::gpar(fontfamily="Arial",fontsize=model_size,fontface="bold"))),"mm",valueOnly=TRUE),numeric(1))
    key_gap<-4;vx0<-cx+max(widths)+2*key_gap
    sector_right<-cx+R*max(vapply(sectors,function(s){
      candidates<-c(s$start,s$end,360*seq(floor(s$start/360),ceiling(s$end/360)))
      max(cos(candidates[candidates>=s$start & candidates<=s$end]*pi/180))
    },numeric(1)))
    item_right<-max(c(sector_right,vapply(item_boxes,function(b)b[["right"]],numeric(1))))
    content_right<-item_right+1.2
    mean_width<-if(cfg$show_violin && cfg$show_mean)max(vapply(c("Mean",sprintf("%.3f",summary$mean)),function(s)grid::convertWidth(grid::grobWidth(grid::textGrob(s,gp=grid::gpar(fontfamily="Arial",fontsize=cfg$violin_text_size))),"mm",valueOnly=TRUE),numeric(1))) else 0
    sig_count<-if(isTRUE(significance$displayed))nrow(significance$comparisons) else 0L
    sig_thickness<-cfg$violin_text_size*25.4/72*1.18;sig_spacing<-sig_thickness+.8
    sig_bracket_width<-if(sig_count>0)2+sig_thickness+(sig_count-1)*sig_spacing else 0
    sig_heading<-if(cfg$p_adjust=="holm")"Holm" else "Unadjusted"
    sig_heading_width<-grid::convertWidth(grid::grobWidth(grid::textGrob(sig_heading,gp=grid::gpar(fontfamily="Arial",fontsize=cfg$violin_text_size))),"mm",valueOnly=TRUE)
    sig_width<-sig_bracket_width
    sig_heading_raised<-sig_count>0 && sig_heading_width>sig_bracket_width
    mean_left<-content_right-mean_width
    vx1<-if(mean_width>0)mean_left-2 else if(sig_width>0)content_right-sig_width else content_right;label_x<-mean(c(cx,vx0))
    assert(vx1-vx0>=35,"Model labels leave less than 35 mm for the violin axis; supply shorter labels or increase width_mm.")
    if(measure)layout_record<<-list(sector_start_x_mm=cx,model_label_center_x_mm=label_x,
      violin_axis_left_mm=vx0,violin_axis_right_mm=vx1,sector_right_mm=sector_right,
      item_label_right_mm=item_right,companion_right_mm=content_right,companion_right_extension_mm=1.2,
      mean_column_left_mm=if(mean_width>0)mean_left else NULL,mean_column_right_mm=if(mean_width>0)content_right else NULL,
      significance_column_width_mm=sig_width,significance_heading_raised=sig_heading_raised,significance_spacing_mm=if(sig_count>0)sig_spacing else NULL,
      violin_font_sizes_pt=list(model=model_size,text=cfg$violin_text_size,tick=cfg$violin_tick_size,axis_title=cfg$violin_axis_title_size),
      model_label_clearance_mm=as.list(setNames((vx0-cx-widths)/2,cfg$model_order)),
      model_label_width_mm=as.list(widths),guide_rows=guide_rows)
    for(i in seq_along(ys)){line(c(cx+.5,cx+2.8),rep(ys[i],2),.7);txt(cfg$model_order[i],label_x,ys[i],model_size,face="bold")}
    if(cfg$show_violin){
      to_x<-function(v)vx0+(v-cfg$metric_domain[1])/diff(cfg$metric_domain)*(vx1-vx0)
      half<-min(3.7,.32*track_height)
      txt(paste0("Matched items (n = ",length(cfg$item_order),")"),mean(c(vx0,vx1)),ys[1]+half+5,cfg$violin_text_size)
      if(cfg$show_mean)txt("Mean",content_right,ys[1]+half+5,cfg$violin_text_size,just="right")
      if(sig_count>0){
        if(sig_heading_raised)txt(sig_heading,content_right,ys[1]+half+9.5,cfg$violin_text_size,just="right")
        else txt(sig_heading,mean(c(vx1,content_right)),ys[1]+half+5,cfg$violin_text_size)
      }
      for(i in seq_along(ys)){m<-cfg$model_order[i];d<-densities[[m]];v<-dat$score[dat$model==m]
        if(is.null(d)){line(to_x(range(v)),rep(ys[i],2),1.1);grid::grid.points(grid::unit(to_x(v),"mm"),grid::unit(rep(ys[i],length(v)),"mm"),pch=16,size=grid::unit(1,"mm"),gp=grid::gpar(col=model_map$colors[[m]]))} else {
        x<-to_x(d$score);spread<-half*d$density/max(d$density)
        # Close at the observed extrema; no tails beyond observed scores.
        xx<-c(x[1],x,x[length(x)],rev(x));yy<-c(ys[i],ys[i]+spread,ys[i],ys[i]-rev(spread))
        fill<-grDevices::adjustcolor(model_map$colors[[m]],alpha.f=palettes[[cfg$palette]]$fill_alpha)
        grid::grid.polygon(grid::unit(xx,"mm"),grid::unit(yy,"mm"),gp=grid::gpar(fill=fill,col="#555555CC",lwd=.38*72/25.4))
        q<-quantile(v,c(.25,.5,.75),names=FALSE)
        for(j in seq_along(q)){h<-approx(d$score,spread,xout=q[j])$y;line(rep(to_x(q[j]),2),ys[i]+c(-h,h),if(j==2).38*.75*72/25.4 else .22*72/25.4,if(j==2)1 else 2,"#555555CC")}
        }
        if(cfg$show_mean)txt(sprintf("%.3f",mean(v)),content_right,ys[i],cfg$violin_text_size,just="right")
      }
      if(sig_count>0){
        focal_y<-ys[match(significance$focal,cfg$model_order)]
        pairs<-significance$comparisons;pairs<-pairs[order(abs(ys[match(pairs$comparator,cfg$model_order)]-focal_y)),]
        brackets<-list()
        for(j in seq_len(sig_count)){
          comparator_y<-ys[match(pairs$comparator[j],cfg$model_order)];x<-vx1+sig_width-sig_bracket_width+1.5+(j-1)*sig_spacing
          line(rep(x,2),c(focal_y,comparator_y),.7)
          line(c(x-.5,x),rep(focal_y,2),.7);line(c(x-.5,x),rep(comparator_y,2),.7)
          b<-txt("p-value < 0.05",x+.5+sig_thickness/2,mean(c(focal_y,comparator_y)),cfg$violin_text_size,rot=90)
          brackets[[j]]<-list(focal=significance$focal,comparator=pairs$comparator[j],x_mm=x,ends_y_mm=c(focal_y,comparator_y),p_adjusted=pairs$p_adjusted[j],label="p-value < 0.05",label_bounds_mm=b)
        }
        if(measure)layout_record$significance_brackets<<-brackets
      }
      axis_y<-tail(ys,1)-half-3.2;line(c(vx0,vx1),rep(axis_y,2),.7)
      ticks<-pretty(cfg$metric_domain,n=4);ticks<-ticks[ticks>=cfg$metric_domain[1] & ticks<=cfg$metric_domain[2]]
      for(v in ticks){line(rep(to_x(v),2),c(axis_y,axis_y-1),.7);txt(format_axis_ticks(v),to_x(v),axis_y-3.7,cfg$violin_tick_size)}
      txt(cfg$metric_label,mean(c(vx0,vx1)),axis_y-8.2,cfg$violin_axis_title_size)
      if(cfg$show_significance && sig_count==0)txt("Brackets omitted",mean(c(vx0,vx1)),axis_y-12.5,cfg$violin_text_size)
    }
    # Group identity and numeric score use separate, explicitly titled keys.
    ng<-length(cfg$group_order);rows<-guide_rows;legend_top<-cy+5+rows
    legend_widths<-vapply(seq_len(ng),function(i)grid::convertWidth(grid::grobWidth(grid::textGrob(paste0(cfg$group_order[i]," (n=",counts[[cfg$group_order[i]]],")"),gp=grid::gpar(fontfamily="Arial",fontsize=6))),"mm",valueOnly=TRUE),numeric(1))
    if(measure){
      if(cfg$group_legend_placement=="center")assert(max(legend_widths)<=18.5,"Group legend labels exceed the center guide; use right placement or shorter authorized group identities.")
      metric_width<-grid::convertWidth(grid::grobWidth(grid::textGrob(cfg$metric_label,gp=grid::gpar(fontfamily="Arial",fontsize=7))),"mm",valueOnly=TRUE)
      assert(metric_width<=35,"metric_label cannot fit the center guide; use a shorter scientific label.")
    }
    if(cfg$group_legend_placement=="right"){
      legend_left<-item_right+3;legend_right<-legend_left+sidebar_width
      legend_top<-if(cfg$show_violin)axis_y-13 else cy+R-8
      legend_bottom<-legend_top-(ng-1)*4-3
      if(measure){assert(legend_right<=W-.7,"Right group legend exceeds canvas; increase width_mm or provide shorter labels.");assert(legend_bottom>=.7,"Right group legend exceeds canvas vertically; increase height_mm.")}
      grid::grid.rect(grid::unit(mean(c(legend_left,legend_right)),"mm"),grid::unit(mean(c(legend_bottom,legend_top+8)),"mm"),width=grid::unit(sidebar_width,"mm"),height=grid::unit(legend_top+8-legend_bottom,"mm"),gp=grid::gpar(fill="white",col="#747474",lwd=.6))
      txt("Groups",mean(c(legend_left,legend_right)),legend_top+4.5,7.5,face="bold")
      if(measure)layout_record$group_legend<<-list(placement="right",bounds_mm=c(left=legend_left,right=legend_right,bottom=legend_bottom,top=legend_top+8),item_label_clearance_mm=3,rows=ng)
    } else {
      txt("Groups",cx,legend_top+5,7.5,face="bold")
      if(measure)layout_record$group_legend<<-list(placement="center",rows=rows)
    }
    for(i in seq_len(ng)){col<-(i-1)%%2;row<-(i-1)%/%2
      if(cfg$group_legend_placement=="right"){x<-legend_left+2.5;y<-legend_top-(i-1)*4} else {x<-if(ng==1L)cx-(legend_widths[1]+4)/2 else cx-18.5+col*22;y<-legend_top-row*4}
      grid::grid.rect(grid::unit(x,"mm"),grid::unit(y,"mm"),width=grid::unit(2,"mm"),height=grid::unit(2,"mm"),gp=grid::gpar(fill=group_colors[[cfg$group_order[i]]],col=NA))
      txt(paste0(cfg$group_order[i]," (n=",counts[[cfg$group_order[i]]],")"),x+2,y,6,just="left")
    }
    bar_y<-if(cfg$group_legend_placement=="right")cy+1 else legend_top-rows*4-4;bar_w<-33
    colors<-heat_color(seq(cfg$metric_domain[1],cfg$metric_domain[2],length.out=256))
    if(svg_gradient)grid::grid.rect(grid::unit(cx,"mm"),grid::unit(bar_y,"mm"),width=grid::unit(bar_w,"mm"),height=grid::unit(3.6,"mm"),gp=grid::gpar(fill="#010203",col=NA)) else
      for(i in seq_along(colors))grid::grid.rect(grid::unit(cx-bar_w/2+(i-.5)*bar_w/256,"mm"),grid::unit(bar_y,"mm"),width=grid::unit(bar_w/256+.01,"mm"),height=grid::unit(3.6,"mm"),gp=grid::gpar(fill=colors[i],col=NA))
    ticks<-c(cfg$metric_domain[1],mean(cfg$metric_domain),cfg$metric_domain[2])
    for(v in ticks){x<-cx-bar_w/2+(v-cfg$metric_domain[1])/diff(cfg$metric_domain)*bar_w;line(rep(x,2),bar_y+c(-1.8,-1.1),.4);txt(format_axis_ticks(v),x,bar_y-4,6)}
    txt(cfg$metric_label,cx,bar_y-8,7)
    if(!is.null(cfg$caption))txt(cfg$caption,W/2,4,6)
  }
  probe<-tempfile(tmpdir=dirname(prefix),fileext=".pdf")
  arial_pdf_device(probe,W/25.4,H/25.4)
  tryCatch(draw(TRUE),finally={grDevices::dev.off();unlink(probe)})
  font_report<-list()
  for(f in cfg$formats){path<-paste0(prefix,".",f)
    switch(f,pdf=arial_pdf_device(path,W/25.4,H/25.4),svg=svglite::svglite(path,W/25.4,H/25.4),png=ragg::agg_png(path,width=W,height=H,units="mm",res=cfg$dpi,background="white"))
    tryCatch(draw(svg_gradient=f=="svg"),finally=grDevices::dev.off())
    if(f=="pdf")font_report$pdf<-verify_pdf_arial(path)
    if(f=="svg"){
      # One editable SVG gradient avoids seams between antialiased adjacent tiles.
      svg<-paste(readLines(path,warn=FALSE),collapse="\n")
      assert(length(regmatches(svg,gregexpr("fill: #010203;",svg,fixed=TRUE))[[1]])==1L,"SVG gradient marker must occur exactly once.")
      anchors<-palettes[[cfg$heatmap_palette]]$continuous
      stops<-paste(vapply(seq_along(anchors),function(i)sprintf('<stop offset="%.8f%%" stop-color="%s"/>',100*(i-1)/(length(anchors)-1),anchors[i]),character(1)),collapse="")
      gradient<-paste0('<linearGradient id="score-gradient" x1="0%" y1="0%" x2="100%" y2="0%">',stops,'</linearGradient>')
      svg<-sub("<defs>",paste0("<defs>\n",gradient),svg,fixed=TRUE)
      svg<-sub("fill: #010203;","fill: url(#score-gradient);",svg,fixed=TRUE)
      writeLines(svg,path,useBytes=TRUE)
      font_report$svg<-embed_arial_in_svg(path,faces)
    }
  }
  stats<-list(metric=cfg$metric_label,domain=cfg$metric_domain,direction=cfg$direction,
    sampling_unit=cfg$sampling_unit,paired=TRUE,n_items=length(cfg$item_order),n_rows=nrow(dat),excluded=0,
    models=summary,group_means=group_summary,group_counts=as.list(counts),
    violin=list(sample="all matched items, one value per item/model; unequal group sizes retain item weights",bandwidth="nrd0",support="observed min/max; KDE is descriptive, not uncertainty",quartiles="type 7; solid median and dashed Q1/Q3",limitations=violin_notes),
    mean_annotation=list(shown=cfg$show_violin && cfg$show_mean,precision=3,sampling="arithmetic mean of all matched items, equal item weights"),
    significance=significance,
    inference=if(cfg$show_significance)"Explicit one-sided paired t-tests of the designated method against all comparators; matched-item differences assumed independent; all results retained." else "No hypothesis test requested or performed.",
    geometry=list(width_mm=W,height_mm=H,center_mm=c(cx,cy),outer_radius_mm=R,inner_radius_mm=inner,
      sweep_degrees=sweep,sector_gap_degrees=gap,item_angle_degrees=unit_angle,group_sectors=sectors,
      model_order_outer_to_inner=cfg$model_order,item_label_stride=cfg$label_every,selected_item_labels=label_record,compound_layout=layout_record,text_bounds=text_bounds),
    fonts=font_report,source_md5=unname(tools::md5sum(cfg$input)))
  jsonlite::write_json(cfg,paste0(prefix,".config.json"),pretty=TRUE,auto_unbox=TRUE,null="null",digits=NA)
  jsonlite::write_json(stats,paste0(prefix,".statistics.json"),pretty=TRUE,auto_unbox=TRUE,null="null",digits=NA)
  write.csv(dat,paste0(prefix,".plotted-data.csv"),row.names=FALSE)
  ds<-do.call(rbind,densities);if(!is.null(ds))write.csv(ds,paste0(prefix,".density.csv"),row.names=FALSE)
  writeLines(capture.output(sessionInfo()),paste0(prefix,".session.txt"))
  message("Rendered grouped circular heatmap: ",prefix)
}

script_arg<-grep("^--file=",commandArgs(),value=TRUE)[1]
skill_dir<-dirname(dirname(normalizePath(gsub("~+~"," ",sub("^--file=","",script_arg),fixed=TRUE))))
cache_root<-Sys.getenv("XDG_CACHE_HOME");if(!nzchar(cache_root))cache_root<-path.expand("~/.cache")
cache_dir<-Sys.getenv("PAPER_FIGURES_CACHE",file.path(cache_root,"paper-results-figures"))
.libPaths(c(file.path(cache_dir,"library"),.libPaths()))
source(file.path(skill_dir,"scripts","font_export.R"))
source(file.path(skill_dir,"scripts","palette_helpers.R"))
source(file.path(skill_dir,"scripts","formatting.R"))
source(file.path(skill_dir,"scripts","significance.R"))
args<-commandArgs(trailingOnly=TRUE);assert(length(args)==1L,"Supply one JSON configuration.")
render(normalizePath(args[[1]],mustWork=TRUE),skill_dir)
