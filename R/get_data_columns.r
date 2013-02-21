get_data_columns <- function(av_state,model) {
  exodta <- NULL
  endo <- NULL
  model_valid <- TRUE
  
  vrs <- av_state$vars
  
  # check if log transform needs to be applied
  if (apply_log_transform(model)) {
    for (name in vrs) {
      ln_name <- prefix_ln(name)
      if (!column_exists(av_state,ln_name)) {
        av_state <- add_derived_column(av_state,ln_name,name,operation='LN',av_state$log_level)
      }
    }
    vrs <- sapply(vrs,prefix_ln,USE.NAMES=FALSE)
  }
  endo <- av_state$data[[av_state$subset]][vrs]
  
  # check if exogenous_variables need to be created
  if (!is.null(model$exogenous_variables)) {
    exovrs <- NULL
    for (i in 1:nr_rows(model$exogenous_variables)) {
      exovar <- model$exogenous_variables[i,]
      cname <- prefix_ln_cond(exovar$variable,model)
      res_outliers_column <- get_outliers_column(av_state,
                                                 cname,
                                                 iteration=exovar$iteration)
      av_state <- res_outliers_column$av_state
      exovr <- res_outliers_column$target_column
      if (!is_outliers_column_valid(av_state,cname,exovar$iteration)) {
        model_valid <- FALSE
      }
      exovrs <- c(exovrs,exovr)
    }
    exodta <- av_state$data[[av_state$subset]][exovrs]
    exodta <- as.matrix(exodta)
    colnames(exodta) <- exovrs
  }
  list(av_state = av_state,endogenous = endo, 
       exogenous = exodta, model_valid = model_valid)
}

apply_log_transform <- function(model) {
  !is.null(model$apply_log_transform) && model$apply_log_transform
}

nr_rows <- function(df) {
  dim(df)[1]
}

column_exists <- function(av_state,name) {
  any(name == names(av_state$data[[av_state$subset]]))
}

prefix_ln_cond <- function(str,model) {
  if (apply_log_transform(model)) {
    prefix_ln(str)
  } else {
    str
  }
}

prefix_ln <- function(str) {
  paste('ln',str,sep="")
}

unprefix_ln <- function(str) {
  sub("^ln",'',str)
}


get_outliers_column <- function(av_state,cname,iteration) {
  target_column <- paste(cname,'_',iteration,sep='')
  if (!column_exists(av_state,target_column)) {
    dta <- av_state$data[[av_state$subset]][[cname]]
    std <- sd(dta)
    mu <- mean(dta)
    std_factor <- std_factor_for_iteration(iteration)
    scat(av_state$log_level,1,"Removing outliers outside of ",std_factor,
        "x std. min: ",mu-std_factor*std,", max: ",
        mu+std_factor*std,"\n",sep='')
    av_state$data[[av_state$subset]][[target_column]] <- 
      ((dta < mu-std_factor*std) | (dta > mu+std_factor*std))+0
  }
  list(target_column=target_column,av_state=av_state)
}

is_outliers_column_valid <- function(av_state,cname,iteration) {
  model_valid <- TRUE
  target_column <- paste(cname,'_',iteration,sep='')
  if ((iteration == 1 && all(av_state$data[[av_state$subset]][[target_column]] == 0)) ||
    (iteration > 1 && all(av_state$data[[av_state$subset]][[target_column]] == 
                          av_state$data[[av_state$subset]][[paste(cname,'_',iteration-1,sep='')]]))) {
    std_factor <- std_factor_for_iteration(iteration)
    if (iteration == 1) {
      scat(av_state$log_level,2,"\n> Removing ",std_factor,"x std. outliers for ",
          cname," has no effect. Marking model as invalid.\n",sep='')
    } else {
      scat(av_state$log_level,2,"\n> Removing ",std_factor,"x std. outliers for ",
          cname," has the same effect as removing ",
          std_factor_for_iteration(iteration-1),
          "x std. outliers. Marking model as invalid.\n",sep='')
    }
    model_valid <- FALSE
  }
  model_valid
}

std_factor_for_iteration <- function(iteration) {
  std_factor <- NULL
  if (iteration == 1) {
    # remove outliers beyond 3.5xstd
    std_factor <- 3.5
  } else if (iteration == 2) {
    # remove outliers beyond 3x std
    std_factor <- 3
  } else {
    # remove outliers beyond 2.5 std
    std_factor <- 2.5
  }
  std_factor
}

get_outliers_as_string <- function(av_state,name,iteration,model) {
  cname <- prefix_ln_cond(name,model)
  if (is.null(av_state$data[[av_state$subset]][[cname]])) {
    '???'
  } else {
    column_name <- get_outliers_column(av_state,cname,iteration=iteration)$target_column
    column <- av_state$data[[av_state$subset]][[column_name]]
    paste(which(column == 1),collapse=', ')
  }
}
