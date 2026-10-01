# Regression calculations remain independent of drawing and display transforms.
trend_fit_candidate <- function(d, degree) {
  if (nrow(d) <= degree + 2L || length(unique(d$x)) <= degree) return(NULL)
  fit <- lm(y ~ poly(x, degree, raw = TRUE), data = d)
  if (fit$rank != degree + 1L) return(NULL)
  n <- nrow(d); k <- degree + 2L
  aicc <- if (n > k + 1L) AIC(fit) + 2 * k * (k + 1) / (n - k - 1) else Inf
  h <- hatvalues(fit)
  loocv <- if (any(h >= 1 - 1e-10)) Inf else mean((residuals(fit)/(1-h))^2)
  list(fit = fit, degree = degree, aicc = aicc, loocv_mse = loocv)
}

trend_fit_series <- function(d, regression = "linear", slope_reference = NULL) {
  degrees <- c(linear=1L, quadratic=2L, cubic=3L)
  if (!regression %in% c(names(degrees), "auto")) stop("Invalid regression.")
  candidates <- lapply(1:3, function(k) trend_fit_candidate(d,k))
  eligible <- which(!vapply(candidates,is.null,logical(1)))
  if (!1L %in% eligible) stop("A trend needs at least four finite observations and two distinct x values.")
  chosen <- if (regression == "auto") 1L else unname(degrees[regression])
  if (!chosen %in% eligible) stop("Insufficient observations or distinct x values for requested polynomial.")
  if (regression == "auto" && nrow(d) >= 10L) {
    for (degree in eligible[eligible > 1L]) {
      candidate <- candidates[[degree]]; incumbent <- candidates[[chosen]]
      if (is.finite(candidate$aicc) && is.finite(candidate$loocv_mse) &&
          incumbent$aicc - candidate$aicc >= 4 && candidate$loocv_mse <= .9 * incumbent$loocv_mse)
        chosen <- degree
    }
  }
  fit <- candidates[[chosen]]$fit; sm <- summary(fit)
  fs <- sm$fstatistic
  model_p <- if (is.null(fs)) NA_real_ else pf(fs[1],fs[2],fs[3],lower.tail=FALSE)
  correlation <- if (sd(d$y) > 0) cor.test(d$x,d$y,method="pearson") else NULL
  derivative <- NA_real_; derivative_se <- NA_real_
  reference <- if (chosen == 1L) 0 else slope_reference
  if (!is.null(reference)) {
    if (length(reference)!=1 || !is.finite(reference)) stop("slope_reference must be one finite x value.")
    if (chosen > 1 && (reference < min(d$x) || reference > max(d$x))) stop("slope_reference must lie within each fitted x range.")
    derivative_weights <- c(0,(1:chosen)*reference^((1:chosen)-1))
    derivative <- sum(coef(fit)*derivative_weights)
    derivative_se <- sqrt(as.numeric(t(derivative_weights)%*%vcov(fit)%*%derivative_weights))
  }
  diagnostics <- do.call(rbind,lapply(eligible,function(i) data.frame(degree=i,aicc=candidates[[i]]$aicc,loocv_mse=candidates[[i]]$loocv_mse,selected=i==chosen)))
  list(fit=fit,statistics=list(n=nrow(d),degree=chosen,coefficients=unname(coef(fit)),coefficient_names=names(coef(fit)),
    r_squared=unname(sm$r.squared),adjusted_r_squared=unname(sm$adj.r.squared),
    pearson_r=if(is.null(correlation))NA_real_ else unname(correlation$estimate),
    pearson_p=if(is.null(correlation))NA_real_ else correlation$p.value,
    p_value=unname(model_p),p_value_definition="Two-sided overall regression F test against an intercept-only model",
    slope=derivative,slope_se=derivative_se,slope_p=if(is.finite(derivative)&&is.finite(derivative_se)&&derivative_se>0)2*pt(-abs(derivative/derivative_se),df=df.residual(fit))else NA_real_,slope_reference=if(chosen==1)NULL else reference,
    slope_definition=if(chosen==1)"Constant linear slope" else if(is.null(reference))"Not displayed: polynomial has no constant slope" else "Local polynomial derivative at slope_reference",
    residual_df=df.residual(fit),residual_sd=sm$sigma,candidates=diagnostics,regression_requested=regression,
    selection_policy="Auto requires n >= 10, AICc improvement >= 4 and LOOCV MSE improvement >= 10%; no significance-based selection"))
}

trend_numeric_axis <- function(values, limits=NULL, breaks=NULL, mm=40, font_pt=6, horizontal=TRUE) {
  automatic <- is.null(limits) && is.null(breaks)
  r <- range(values[is.finite(values)])
  if (!length(r) || any(!is.finite(r))) stop("No finite axis values.")
  if(is.null(limits)){delta<-diff(r);if(delta==0)delta<-max(abs(r),1)*.1;limits<-r+c(-1,1)*delta*.06}
  if(length(limits)!=2 || any(!is.finite(limits)) || diff(limits)<=0)stop("Axis limits must be two increasing finite values.")
  if(any(values[is.finite(values)] < limits[1] | values[is.finite(values)] > limits[2]))stop("Axis limits would crop observations or shown confidence intervals.")
  if(is.null(breaks))breaks<-choose_axis_breaks(limits,mm,font_pt,horizontal)
  else if(!is.numeric(breaks)||any(!is.finite(breaks)))stop("Axis breaks must be finite numbers.")
  if(automatic) {
    completed<-complete_nearby_axis_ticks(limits,breaks)
    limits<-completed$limits;breaks<-completed$breaks
  }
  list(limits=limits,breaks=snap_axis_breaks(breaks,limits))
}

trend_stat_text <- function(st, keys, p_value_target="regression") {
  labels <- vapply(keys,function(key){
    value<-switch(key,slope=st$slope,r_squared=st$r_squared,pearson_r=st$pearson_r,p_value=switch(p_value_target,regression=st$p_value,pearson=st$pearson_p,slope=st$slope_p))
    if(!is.finite(value))return(paste0(switch(key,slope="Slope",r_squared="R²",pearson_r="Pearson r",p_value="p-value"),": unavailable"))
    if(key=="p_value")return(if(value<.05)"p-value < 0.05" else sprintf("p-value = %.3f",value))
    label<-switch(key,slope=if(st$degree>1)sprintf("Slope at x=%.3f",st$slope_reference)else"Slope",r_squared="R²",pearson_r="Pearson r")
    sprintf("%s: %.3f",label,value)
  },character(1))
  paste(labels,collapse="\n")
}

# A shared statistic header is separate from per-series values in the two-row guide.
trend_stat_header <- function(keys, labels=NULL, slope_reference=NULL) {
  stat_names<-c(slope=if(is.null(slope_reference))"Slope"else sprintf("Slope at x=%.3f",slope_reference),
    r_squared="R²",pearson_r="Pearson r",p_value="p-value")
  if(!is.null(labels)) {
    custom<-unlist(labels)
    if(is.null(names(custom)) || any(!names(custom) %in% names(stat_names)) || anyNA(custom) || any(!nzchar(custom)))
      stop("statistic_labels must be a named map of nonempty display labels for known statistics.")
    stat_names[names(custom)]<-custom
  }
  if(!length(keys))return("")
  if(length(keys)==1L)return(paste0(stat_names[keys],":"))
  paste0(stat_names[keys[1]]," (",stat_names[keys[2]],"):")
}

trend_stat_values <- function(st, keys, p_value_target="regression") {
  values<-vapply(keys,function(key) {
    value<-switch(key,slope=st$slope,r_squared=st$r_squared,pearson_r=st$pearson_r,
      p_value=switch(p_value_target,regression=st$p_value,pearson=st$pearson_p,slope=st$slope_p))
    if(!is.finite(value))return("unavailable")
    if(key=="p_value" && value<.05)return("<0.05")
    sprintf("%.3f",value)
  },character(1))
  if(!length(values))return("")
  if(length(values)==1L)return(values)
  paste0(values[1]," (",values[2],")")
}
