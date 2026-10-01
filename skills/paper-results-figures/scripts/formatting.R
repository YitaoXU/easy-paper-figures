# Shared axis formatting: one decimal minimum, with additional meaningful digits.
format_axis_ticks <- function(values, digits = NULL) {
  if (is.null(digits)) {
    labels <- formatC(values, format = "f", digits = 10)
    labels <- sub("0+$", "", labels)
    labels <- sub("\\.$", ".0", labels)
  } else {
    if (!is.numeric(digits) || length(digits) != 1 || !is.finite(digits) || digits < 0 || digits > 10 || digits %% 1 != 0) {
      stop("axis_digits must be null (adaptive) or an integer from 0 to 10.")
    }
    labels <- formatC(values, format = "f", digits = digits)
  }
  # Floating-point tick completion can leave an infinitesimal negative zero.
  negative_zero <- grepl("^-0(\\.0+)?$", labels)
  labels[negative_zero] <- sub("^-", "", labels[negative_zero])
  if (anyDuplicated(labels)) stop("Axis precision is too small to distinguish the labeled ticks.")
  labels
}

# Align only floating-point-near endpoint ticks with the exact view bounds.
# Scientific observations/means/uncertainty are never rounded or altered here.
snap_axis_breaks <- function(breaks, limits) {
  if(!is.numeric(breaks)||any(!is.finite(breaks))||length(limits)!=2||any(!is.finite(limits))||diff(limits)<=0)stop("Invalid numeric breaks or bounds.")
  tolerance<-64*.Machine$double.eps*max(abs(limits),diff(limits),.Machine$double.xmin)
  for(bound in limits){close<-abs(breaks-bound)<=tolerance;breaks[close]<-bound}
  unique(breaks[breaks>=limits[1]&breaks<=limits[2]])
}

# Choose readable major ticks for the actual printed axis, never a fixed 0.05 step.
# Horizontal labels consume their measured Arial width; vertical labels consume height.
choose_axis_breaks <- function(limits, available_mm, font_pt=6, horizontal=TRUE) {
  if(length(limits)!=2 || any(!is.finite(limits)) || diff(limits)<=0)stop("Invalid axis limits.")
  available_mm<-max(8,available_mm)
  for(n in 8:1) {
    ticks<-pretty(limits,n=n)
    ticks<-snap_axis_breaks(ticks,limits)
    if(length(ticks)<2)next
    labels<-format_axis_ticks(ticks)
    widths<-if(horizontal)systemfonts::string_width(labels,family="Arial",size=font_pt,res=72)*25.4/72 else rep(font_pt*25.4/72,length(ticks))
    gaps<-diff(ticks)/diff(limits)*available_mm
    required<-(head(widths,-1)+tail(widths,-1))/2+if(horizontal)1.8 else 1.5
    if(all(gaps>=required))return(ticks)
  }
  # Very short axes retain two distinct endpoints, which still require visual review.
  limits
}

# Complete a nearby outside major tick by extending only; never crop observations.
# Explicit user ranges/ticks bypass this automatic rule at the call site.
complete_nearby_axis_ticks <- function(limits, breaks, tolerance=0.20) {
  if(length(breaks)<2)return(list(limits=limits,breaks=breaks))
  steps<-diff(breaks);step<-median(steps)
  if(!is.finite(step)||step<=0||any(abs(steps-step)>step*1e-7))return(list(limits=limits,breaks=breaks))
  origin<-breaks[1];eps<-1e-9
  outside<-origin+c(floor((limits[1]-origin)/step+eps),ceiling((limits[2]-origin)/step-eps))*step
  gaps<-c(limits[1]-outside[1],outside[2]-limits[2])
  use<-gaps>=-step*eps & gaps<=step*(tolerance+eps)
  limits[use]<-signif(outside[use],12)
  bounds<-c(ceiling((limits[1]-origin)/step-eps),floor((limits[2]-origin)/step+eps))
  ticks<-origin+seq(bounds[1],bounds[2])*step
  list(limits=limits,breaks=snap_axis_breaks(signif(ticks,12),limits))
}
