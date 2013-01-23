# vargranger
# if the exclusion of variable a is significant for the equation of variable b,
# then a granger causes b.
# also give a one line summary for results

vargranger <- function(varest) {
  # TODO: make this function work when var has more than two variables
  if (dim(varest$y)[[2]] > 2) {
    stop("the current vargranger implementation only works for two variables")
  }
  cat("\nGranger causality Wald tests\n")
  res <- vargranger_aux(varest)
  print(res)
  tos <- vargranger_to_string(res)
  if (tos != '') {
    cat('Vargranger causes: ',tos,'\n',sep='')
  } else {
    cat('No significant Granger causes detected.\n')
  }
  tos
}

df_in_rows <- function(df) {
  lst <- NULL
  if (!is.null(df)) {
    for (i in 1:(dim(df)[[1]])) {
      lst <- c(lst,list(df[i,]))
    }
  }
  lst
}

vargranger_aux <- function(varest) {
  res <- NULL
  for (eqname in dimnames(varest$y)[[2]]) {
    for (exname in dimnames(varest$y)[[2]]) {
      if (exname == eqname) { next }
      gres <- NULL
      tryCatch(gres <- causality(varest,cause=exname)$Granger,error=function(e) { })
      if (is.null(gres)) { next }
      F <- gres$statistic[1,1]
      df <- get_named(gres$parameter,'df1')
      df_r <- get_named(gres$parameter,'df2')
      P <- gres$p.value[1,1]
      if (is.null(res)) {
        res <- data.frame(Equation=eqname,
                          Excluded=exname,
                          F=F,df=df,df_r=df_r,
                          P=P,
                          stringsAsFactors=FALSE)
      } else {
        res <- rbind(res,list(eqname,exname,F,df,df_r,P))
      }
    }
  }
  res
}

get_named <- function(arr,name) {
  if (name %in% names(arr)) {
    arr[[which(name == names(arr))]]
  } else {
    NULL
  }
}

vargranger_to_string <- function(res) {
  # res is a vargranger_aux result
  str <- NULL
  for (row in df_in_rows(res)) {
    if (row$P <= av_state$significance) {
      str <- c(str,paste(unprefix_ln(row$Excluded),
                         ' Granger causes ',
                         unprefix_ln(row$Equation),
                         ' (',signif(row$P,digits=3),')',sep=''))
    } else if (row$P <= 2*av_state$significance) {
      str <- c(str,paste(unprefix_ln(row$Excluded),
                         ' almost Granger causes ',
                         unprefix_ln(row$Equation),
                         ' (',signif(row$P,digits=3),')',sep=''))
    }
  }
  if (!is.null(str)) {
    str <- paste(str,collapse='; ')
  } else {
    str <- ''
  }
  str
}

vargranger_line <- function(varest) {
  vargranger_to_string(vargranger_aux(varest))
}
