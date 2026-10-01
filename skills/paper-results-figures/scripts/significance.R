# Compare an explicitly designated focal method with every other displayed method.
# Paired input is matched by ID; independent input uses Welch's t-test.
focal_t_tests <- function(dat, focal, paired=FALSE, direction="higher", adjust="none", data_mode="raw") {
  if(!adjust %in% c("none","holm"))stop("p_adjust must be none or holm.")
  result<-list(enabled=TRUE,focal=focal,alternative=if(direction=="higher")"greater"else"less",
    method=if(paired)"paired one-sided t-test"else"Welch one-sided t-test",p_adjust=adjust,
    threshold=.05,all_significant=FALSE,displayed=FALSE,comparisons=NULL,
    assumption="The observational units (paired differences for paired input) must be independent. Repeated observations within a source may require an explicitly chosen aggregation or dependence-aware analysis.")
  if(data_mode!="raw"){result$reason<-"Raw observations are required; no test is inferred from pooled scores.";return(result)}
  if(length(focal)!=1 || !focal %in% dat$model)stop("Supply one explicit significance_model or highlight for significance tests.")
  others<-setdiff(unique(dat$model),focal)
  if(!length(others)){result$reason<-"No comparator methods.";return(result)}
  f<-dat[dat$model==focal,]
  comparisons<-lapply(others,function(m){
    o<-dat[dat$model==m,]
    if(paired){if(anyDuplicated(f$id)||anyDuplicated(o$id)||!setequal(f$id,o$id))stop("Significance requires matching unique IDs.");o<-o[match(f$id,o$id),]}
    test<-tryCatch(stats::t.test(f$value,o$value,paired=paired,alternative=result$alternative),error=function(e)e)
    ok<-!inherits(test,"error") && is.finite(test$p.value) && is.finite(unname(test$statistic))
    failure<-if(inherits(test,"error"))conditionMessage(test)else if(!ok)"Nonfinite test result; variance may be degenerate."else ""
    data.frame(focal=focal,comparator=m,n_focal=nrow(f),n_comparator=nrow(o),
      t_statistic=if(ok)unname(test$statistic)else NA_real_,df=if(ok)unname(test$parameter)else NA_real_,
      p_value=if(ok)test$p.value else NA_real_,status=if(ok)"tested"else"not_testable",
      reason=failure,stringsAsFactors=FALSE)
  })
  tab<-do.call(rbind,comparisons);tab$p_adjusted<-stats::p.adjust(tab$p_value,method=adjust)
  tab$significant<-is.finite(tab$p_adjusted)&tab$p_adjusted<.05
  result$comparisons<-tab;result$all_significant<-all(tab$significant)
  result$displayed<-result$all_significant
  result$reason<-if(result$all_significant)"Every focal-versus-other test meets the threshold."else"At least one focal-versus-other test does not meet the threshold or cannot be evaluated; no significance brackets are drawn."
  result
}
