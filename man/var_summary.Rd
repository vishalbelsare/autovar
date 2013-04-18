\name{var_summary}
\alias{var_summary}
\title{Print the output of var_main}
\usage{
  var_summary(av_state, msg = NULL)
}
\arguments{
  \item{av_state}{an object of class \code{av_state} that
  was the result of a call to \code{\link{var_main}}}

  \item{msg}{an optional message to display at the start.
  If this argument is \code{NULL}, a default message is
  shown instead.}
}
\description{
  This function repeats the output that is shown after a
  call of var_main.
}
\examples{
# av_state is the result of a call to var_main
var_summary(av_state)
}
