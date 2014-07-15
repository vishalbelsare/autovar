#' Return a JSON array of network data of a fitting model
#' 
#' This function uses repeated calls to \code{\link{var_main}} to find a fitting model for the data provided and then calls \code{\link{convert_to_graph}} to return a JSON representation of best valid model found.
#' @param data a data frame of 17 columns (ontspanning, opgewektheid, hier_en_nu, concentratie, beweging, iets_betekenen, humor, buiten_zijn, eigenwaarde, levenslust, onrust, somberheid, lichamelijk_ongemak, tekortschieten, piekeren, eenzaamheid, uw_eigen_factor) and 90 rows
#' @param timestamp the date of the first measurement in the format \code{'yyyy-mm-dd'}
#' @return This function returns a string representing a json array of two networks.
#' @export
generate_network <- function(data, timestamp) {
  if (class(data) != "data.frame") return("data argument is not a data.frame")
  if (any(dim(data) != c(90,17))) return("Wrong number of columns or rows in the data.frame")
  if (class(timestamp) != "character") return("timestamp argument is not a character string")
  if (nchar(timestamp) != 10) return("Wrong timestamp format, should be: yyyy-mm-dd")
  data <- select_relevant_columns(data)
  imin <- 0
  imax <- 0
  if (any(is.na(data))) {
    imin <- 1
    imax <- 1
  }
  SIGNIFICANCES <- c(0.05,0.01,0.005,0.001)
  #SIGNIFICANCES <- 0.05
  for (signif in SIGNIFICANCES) {
    for (ptime in imin:imax) {
      ndata <- data
      if (ptime == 1) ndata <- impute_dataframe(data,2)
      if (ptime == 2) ndata <- impute_dataframe(data,1)
      if (any(is.na(ndata))) next # sometimes it fails
      d<-load_dataframe(ndata,log_level=3)
      d<-add_trend(d,log_level=3)
      d<-set_timestamps(d,date_of_first_measurement=timestamp,
                        measurements_per_day=3,log_level=3)
      # squared trend is always included when trend is
      d<-var_main(d,names(ndata),significance=signif,log_level=3,
                  criterion="AIC",include_squared_trend=TRUE,
                  exclude_almost=TRUE,simple_models=TRUE,
                  split_up_outliers=TRUE)
      #gn <<- d
      if (length(d$accepted_models) > 0)
        return(convert_to_graph(d))
    }
  }
  NULL
}
