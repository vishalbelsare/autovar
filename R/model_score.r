# Goodness of fit tests
model_score <- function(varest) {
  # low values == better models
  es <- estat_ic(varest)
  #es$AIC+es$BIC
  es$BIC
}

printed_model_score <- function(varest) {
  # low values == better models
  es <- estat_ic(varest)
  paste("(AIC: ",round(es$AIC,digits=3),
        ", BIC: ",round(es$BIC,digits=3),")",sep='')
}

estat_ic <- function(varest) {
  varsum <- summary(varest)
  nobs <- varsum$obs
  k <- nr_parameters_est(varest)
  ll <- varsum$logLik
  # k = tparms
  # nobs = T
  aic <- -2*ll + 2*k
  bic <- -2*ll + log(nobs)*k
  res <- data.frame(Obs=nobs,
                    ll=ll,
                    df=k,
                    AIC=aic,
                    BIC=bic)
  res
}

nr_parameters_est <- function(varest) {
  r <- 0
  for (lm in varest$varresult) {
    r <- r+length(lm$coefficients)
  }
  r
}
