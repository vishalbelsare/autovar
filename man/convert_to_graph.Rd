% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/convert_to_graph.r
\name{convert_to_graph}
\alias{convert_to_graph}
\title{Convert best model to graph}
\usage{
convert_to_graph(av_state, net_cfg, forced_variable = NULL)
}
\arguments{
\item{av_state}{an object of class \code{av_state}, containing at least one valid model}

\item{net_cfg}{a net_cfg object providing metadata about the networks}

\item{forced_variable}{a variable that, if not \code{NULL}, will be the target of the third connection in the top three of connections that is returned by this function.}
}
\value{
This function returns a string representing a json array of two networks.
}
\description{
This function returns a JSON representation of a the graphs for the best valid model found in the given \code{av_state}.
}
\examples{
\dontrun{
GN_COLUMNS <- c('ontspanning', 'opgewektheid', 'hier_en_nu', 'concentratie',
                'beweging', 'iets_betekenen', 'humor', 'buiten_zijn',
                'eigenwaarde', 'levenslust', 'onrust', 'somberheid',
                'lichamelijk_ongemak', 'tekortschieten', 'piekeren', 'eenzaamheid',
                'uw_eigen_factor')
data<-load_file("../data/input/DataDndN_nonimputed_voorAndo.sav",log_level=3)
data<-data$raw_data[,GN_COLUMNS]
net_cfg <- new_net_cfg()
net_cfg$vars <- unique(names(data))
net_cfg$always_include <- 'uw_eigen_factor'
net_cfg$pairs <- c('opgewektheid','onrust',
                   'somberheid','ontspanning',
                   'somberheid','onrust')
net_cfg$positive_variables <- c('opgewektheid','ontspanning','hier_en_nu',
                                'concentratie', 'beweging','iets_betekenen',
                                'humor', 'buiten_zijn','eigenwaarde', 'levenslust')
net_cfg$negative_variables <- c('onrust','somberheid','lichamelijk_ongemak',
                                'tekortschieten','piekeren','eenzaamheid')
net_cfg$measurements_per_day <- 3
net_cfg$max_network_size <- 6
odata <- select_relevant_columns(data,net_cfg,FALSE,6)
first_measurement_index <- 1
timestamp <- '2014-05-06'
res <- select_relevant_rows(odata,timestamp,net_cfg)
odata <- res$data
first_measurement_index <- res$first_measurement_index
timestamp <- res$timestamp
if (any(is.na(odata)))
  odata <- impute_dataframe(odata,net_cfg$measurements_per_day)
d<-load_dataframe(odata,net_cfg)
d<-add_trend(d)
d<-set_timestamps(d,date_of_first_measurement=timestamp,
                    first_measurement_index=first_measurement_index,
                    measurements_per_day=net_cfg$measurements_per_day)
d<-var_main(d,names(odata),significance=0.01,log_level=3,
              criterion="AIC",include_squared_trend=TRUE,
              exclude_almost=TRUE,simple_models=TRUE,
              split_up_outliers=TRUE)
cat(convert_to_graph(d,net_cfg))
}
}
