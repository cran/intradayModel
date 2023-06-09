#' @title Decompose Intraday Volume into Several Components
#'
#' @description This function decomposes the intraday volume into daily, seasonal, and intraday dynamic components according to (Chen et al., 2016).
#' If \code{purpose = “analysis”} (aka Kalman smoothing), the optimal components are conditioned on both the past and future observations.
#' Its mathematical expression is \eqn{\hat{x}_{\tau} = E[x_{\tau}|\{y_{j}\}_{j=1}^{M}]}{x*(\tau) = E[x(\tau) | y(j), j = 1, ... , M]},
#'              where \eqn{M} is the total number of bins in the dataset.
#'
#'              If \code{purpose = “forecast”} (aka Kalman forecasting), the optimal components are conditioned on only the past observations.
#'              Its mathematical expression is \eqn{\hat{x}_{\tau+1} = E[x_{\tau+1}|\{y_{j}\}_{j=1}^{\tau}]}{x*(\tau+1) = E[x(\tau + 1) | y(j), j = 1, ... , \tau]}.
#'
#'              Three measures are used to evaluate the model performance:
#'              \itemize{\item{Mean absolute error (MAE):
#'                             \eqn{\frac{1}{M}\sum_{\tau=1}^M|\hat{y}_{\tau} - y_{\tau}|}{\sum (|y*(\tau) - y(\tau)|) / M} ;}
#'                       \item{Mean absolute percent error (MAPE):
#'                             \eqn{\frac{1}{M}\sum_{\tau=1}^M\frac{|\hat{y}_{\tau} - y_{\tau}|}{y_{\tau}}}{\sum (|y*(\tau) - y(\tau)| / y(\tau)) / M} ;}
#'                       \item{Root mean square error (RMSE):
#'                             \eqn{\sqrt{\sum_{\tau=1}^M\frac{\left(\hat{y}_{\tau} - y_{\tau}\right)^2}{M}}}{[\sum ((y*(\tau) - y(\tau))^2 / M)]^0.5} .}
#'              }
#'
#' @author Shengjie Xiu, Yifan Yu and Daniel P. Palomar
#'
#' @param purpose String \code{"analysis"/"forecast"}. Indicates the purpose of using the provided model.
#' @param model A model object of class "\code{volume_model}" from \code{fit_volume()}.
#' @param data An n_bin * n_day matrix or an \code{xts} object storing intraday volume.
#' @param burn_in_days  Number of initial days in the burn-in period for forecast. Samples from the first \code{burn_in_days} are used to warm up the model and then are discarded.
#'
#'
#' @return A list containing the following elements:
#'        \itemize{
#'        \item{\code{original_signal}: }{A vector of original intraday volume;}
#'        \item{\code{smooth_signal} / \code{forecast_signal}: }{A vector of smooth/forecast intraday volume;}
#'        \item{\code{smooth_components} /\code{forecast_components}: }{A list of smooth/forecast components: daily, seasonal, intraday dynamic, and residual components.}
#'        \item{\code{error}: }{A list of three error measures: mae, mape, and rmse.}
#'        }
#'
#'
#' @references
#' Chen, R., Feng, Y., and Palomar, D. (2016). Forecasting intraday trading volume: A Kalman filter approach. Available at SSRN 3101695.
#'
#'
#' @examples
#' library(intradayModel)
#' data(volume_aapl)
#' volume_aapl_training <- volume_aapl[, 1:20]
#' volume_aapl_testing <- volume_aapl[, 21:50]
#' model_fit <- fit_volume(volume_aapl_training, fixed_pars = list(a_mu = 0.5, var_mu = 0.05),
#'                         init_pars = list(a_eta = 0.5))
#'
#' # analyze training volume
#' analysis_result <- decompose_volume(purpose = "analysis", model_fit, volume_aapl_training)
#'
#' # forecast testing volume
#' forecast_result <- decompose_volume(purpose = "forecast", model_fit, volume_aapl_testing)
#'
#' # forecast testing volume with burn-in
#' forecast_result <- decompose_volume(purpose = "forecast", model_fit, volume_aapl[, 1:50],
#'                              burn_in_days = 20)
#'
#' @export
decompose_volume <- function(purpose, model, data, burn_in_days = 0) {
  if (tolower(purpose) == "analysis") {
    res <- smooth_volume_model(data = data, volume_model = model)
    attr(res, "type") <- c("analysis", "smooth")
  } else if (tolower(purpose) == "forecast") {
    res <- forecast_volume_model(data = data, volume_model = model, burn_in_days = burn_in_days)
    attr(res, "type") <- "forecast"
  } else {
    warning("Wrong purpose for decompose_volume function.\n")
  }

  return(res)
}


#' @title Forecast One-bin-ahead Intraday Volume
#'
#' @description This function forecasts one-bin-ahead intraday volume.
#' Its mathematical expression is \eqn{\hat{y}_{\tau+1} = E[y_{\tau+1}|\{y_{j}\}_{j=1}^{\tau}]}{y*(\tau+1) = E[y(\tau + 1) | y(j), j = 1, ... , \tau]}.
#' It is a wrapper of \code{decompose_volume()} with \code{purpose = "forecast"}.
#'
#' @author Shengjie Xiu, Yifan Yu and Daniel P. Palomar
#'
#' @param model A model object of class "\code{volume_model}" from \code{fit_volume()}.
#' @param data An n_bin * n_day matrix or an \code{xts} object storing intraday volume.
#' @param burn_in_days  Number of initial days in the burn-in period. Samples from the first \code{burn_in_days} are used to warm up the model and then are discarded.
#'
#'
#' @return A list containing the following elements:
#'        \itemize{
#'         \item{\code{original_signal}: }{A vector of original intraday volume;}
#'         \item{\code{forecast_signal}: }{A vector of forecast intraday volume;}
#'         \item{\code{forecast_components}: }{A list of the three forecast components: daily, seasonal, intraday dynamic, and residual components.}
#'         \item{\code{error}: }{A list of three error measures: mae, mape, and rmse.}
#'         }
#'
#'
#' @references
#' Chen, R., Feng, Y., and Palomar, D. (2016). Forecasting intraday trading volume: A Kalman filter approach. Available at SSRN 3101695.
#'
#'
#' @examples
#' library(intradayModel)
#' data(volume_aapl)
#' volume_aapl_training <- volume_aapl[, 1:20]
#' volume_aapl_testing <- volume_aapl[, 21:50]
#' model_fit <- fit_volume(volume_aapl_training, fixed_pars = list(a_mu = 0.5, var_mu = 0.05),
#'                         init_pars = list(a_eta = 0.5))
#'                         
#' # forecast testing volume
#' forecast_result <- forecast_volume(model_fit, volume_aapl_testing)
#'
#' # forecast testing volume with burn-in
#' forecast_result <- forecast_volume(model_fit, volume_aapl[, 1:50], burn_in_days = 20)
#'
#' @export
forecast_volume <- function(model, data, burn_in_days = 0) {
  res <- decompose_volume("forecast", model, data, burn_in_days)
  return(res)
}


smooth_volume_model <- function(data, volume_model) {
  # error control of data
  if (!is.xts(data) & !is.matrix(data)) {
    stop("data must be matrix or xts.")
  }
  data <- clean_data(data)

  is_volume_model(volume_model, nrow(data))

  # if model isn't optimally fitted (no convergence), it cannot filter
  if (Reduce("+", volume_model$converged) != 8) {
    msg <- c(
      "All parameters must be optimally fitted. ",
      "Parameters ", paste(names(volume_model$converged[volume_model$converged == FALSE]), collapse = ", "), " are not optimally fitted."
    )
    stop(msg)
  }

  # filter using UNISS (our own Kalman)
  args <- list(
    data = log(data),
    volume_model = volume_model
  )
  uniss_obj <- do.call(specify_uniss, args)
  Kf <- uniss_kalman(uniss_obj, "smoother")

  # tidy up components (scale change)
  smooth_components <- list(
    daily = exp(Kf$xtT[1, ]),
    dynamic = exp(Kf$xtT[2, ]),
    seasonal = exp(rep(uniss_obj$par$phi, uniss_obj$n_day))
  )
  smooth_signal <- smooth_components$daily *
    smooth_components$dynamic * smooth_components$seasonal
  original_signal <- as.vector(data)
  smooth_components$residual <- original_signal / smooth_signal
  error <- list(
    mae = calculate_mae(original_signal, smooth_signal),
    mape = calculate_mape(original_signal, smooth_signal),
    rmse = calculate_rmse(original_signal, smooth_signal)
  )

  res <- list(
    original_signal = original_signal,
    smooth_signal = smooth_signal,
    smooth_components = smooth_components,
    error = error
  )

  return(res)
}

forecast_volume_model <- function(data, volume_model, burn_in_days = 0) {
  # error control of data
  if (!is.xts(data) & !is.matrix(data)) {
    stop("data must be matrix or xts.")
  }
  data <- clean_data(data)
  if (burn_in_days > ncol(data)) stop("out_sample must be smaller than the number of columns in data matrix.")

  is_volume_model(volume_model, nrow(data))

  # check if fit is necessary
  if (Reduce("+", volume_model$converged) != 8) {
    msg <- c(
      "All parameters must be fitted.\n ",
      "Parameter ", paste(names(volume_model$converged[volume_model$converged == FALSE]), collapse = ", "), " is not fitted."
    )
    stop(msg)
  }

  # one-step ahead prediction using UNISS (our own Kalman)
  args <- list(
    data = log(data),
    volume_model = volume_model
  )
  uniss_obj <- do.call(specify_uniss, args)
  Kf <- uniss_kalman(uniss_obj, "filter")

  # tidy up components (scale change)
  forecast_components <- list(
    daily = exp(Kf$xtt1[1, ]),
    dynamic = exp(Kf$xtt1[2, ]),
    seasonal = exp(rep(uniss_obj$par$phi, uniss_obj$n_day))
  )
  components_out <- lapply(forecast_components, function(c) utils::tail(c, nrow(data) * (ncol(data) - burn_in_days)))
  forecast_signal <- components_out$daily *
    components_out$dynamic * components_out$seasonal

  # error measures
  original_signal <- utils::tail(as.vector(as.matrix(data)), nrow(data) * (ncol(data) - burn_in_days))
  components_out$residual <- original_signal / forecast_signal
  error <- list(
    mae = calculate_mae(original_signal, forecast_signal),
    mape = calculate_mape(original_signal, forecast_signal),
    rmse = calculate_rmse(original_signal, forecast_signal)
  )

  # result
  res <- list(
    original_signal = original_signal,
    forecast_signal = forecast_signal,
    forecast_components = components_out,
    error = error
  )

  return(res)
}
