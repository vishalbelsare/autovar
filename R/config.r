# config

# load default values
.onLoad <- function(libname,pkgname) {
  reset_state()
}

print.av_state <- function(x,...) {
  nn <- names(x)
  ll <- length(x)
  cat("\n")
  for (i in seq_len(ll)) {
    cat(nn[i],": ",sep="")
    if (nn[i] == 'raw_data') {
      cat(paste(dim(x[[i]])[1],'samples with',dim(x[[i]])[2],'features'),
          " [missing: ",calc_missing(x[[i]]),"]\n",sep="")
    } else if (nn[i] == 'data') {
      if (class(x[[i]]) == 'list') {
        cat("\n")
        for (j in names(x[[i]])) {
         cat("  ",j,": ",paste(dim(x[[i]][[j]])[1],'samples with',dim(x[[i]][[j]])[2],'features'),
             " [missing: ",calc_missing(x[[i]][[j]]),"]\n",sep="")
        }
      } else {
        cat(paste(dim(x[[i]])[1],'samples with',dim(x[[i]])[2],'features'),"\n")
      }
    } else {
      if (class(x[[i]]) == 'list') {
        print(x[[i]])
      } else {
        cat(x[[i]],"\n")
      }
    }
  }
  cat("\n")
  invisible(x)
}

var_model_to_string <- function(x) {
  str <- "\n  "
  nn <- names(x)
  ll <- length(x)
  nns <- seq_len(ll)
  if (!is.null(names(x))) {
    nns <- sort(names(x),index.return=TRUE)
    nns <- nns$ix
  }
  for (i in nns) {
    if (str != '\n  ') {
      str <- paste(str,"\n  ",sep='')
    }
    if (class(x[[i]]) == "data.frame") {
      strr <- "<"
      for (name in names(x[[i]])) {
        if (strr != '<') {
          strr <- paste(strr,"| ",sep='')
        }
        strr <- paste(strr,name,": ",paste(x[[i]][[name]],collapse=', '),sep='')
      }
      strr <- paste(strr,">",sep='')
      str <- paste(str,nn[i],": ",strr,sep='')
    } else {
      str <- paste(str,nn[i],": ",x[[i]],sep='')
    }
  }
  str
}
print.var_model <- function(x,...) {
  cat(var_model_to_string(x),"\n")
  invisible(x)
}

print.var_modelres <- function(x,...) {
  str <- paste(printed_model_score(x$varest)," : ",
               var_model_to_string(x$parameters),sep='')
  cat(str,"\n")
  invisible(x)
}

reset_state <- function() {
  x <- list()
  class(x) <- 'av_state'
  assign('av_state',x,pos='.GlobalEnv')
}

print_state <- function() {
  print(av_state)
}

load_test_data <- function() {
  reset_state()
  av_state$file_name <<- 'data_test.sav'
  av_state$real_file_name <<- 'data_test.sav'
  av_state$file_type <<- 'SPSS'
  av_state$raw_data <<- generate_test_data()
  av_state$data <<- list('multiple'=av_state$raw_data)
}

generate_test_data <- function() {
  data.frame(id=rep(1,times=5),tijdstip=c(1,3,5,6,7),home=c('yes','no','yes',NA,'yes'))
}
