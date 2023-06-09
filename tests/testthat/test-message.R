data(volume_aapl)

test_that("is_volume_model works", {
  skip_on_cran()
  data <- volume_aapl
  n_bin <- 26
  fixed_pars <- list()
  fixed_pars$"a_mu" <- 1
  fixed_pars$"var_eta" <- 4
  fixed_pars$"x0" <- matrix(0,2)
  fixed_pars$"phi" <- matrix(2, n_bin)
  modelSpec <- spec_volume_model(fixed_pars = fixed_pars)
  
  modelSpec_check1 <- modelSpec[c("par", "init")]
  expect_error(is_volume_model(modelSpec_check1), "Elements converged are missing from the model.\n")
  
  modelSpec_check2 <- modelSpec
  modelSpec_check2$par[["x0"]] <- NULL
  expect_error(is_volume_model(modelSpec_check2),"Elements x0 are missing from volume_model[$]par.\n")
  
  modelSpec_check3 <- modelSpec
  modelSpec_check3$converged[["var_eta"]] <- FALSE
  expect_error(is_volume_model(modelSpec_check3), "volume_model[$]par[$]var_eta and volume_model[$]converged[$]var_eta are conflicted.\n")
  modelSpec_check3$converged[["a_eta"]] <- Inf
  expect_error(is_volume_model(modelSpec_check3), "Elements in volume_model[$]converged must be TRUE/FALSE.\n")
  modelSpec_check3$converged[["a_eta"]] <- NA
  expect_error(is_volume_model(modelSpec_check3), "Elements in volume_model[$]converged must be TRUE/FALSE.\n")
  
  
  modelSpec_check4 <- modelSpec
  modelSpec_check4$par[["x0"]] <- 1
  modelSpec_check4$par[["var_eta"]] <- array(c(1,2))
  error_message <- paste("Length of volume_model[$]par[$]var_eta is wrong.\n")
  expect_error(is_volume_model(modelSpec_check4, 25), error_message)
})

test_that("forecast_volume_model/Smooth works", {
  skip_on_cran()
  data <- volume_aapl
  n_bin <- 26
  fixed_pars <- list()
  fixed_pars$"a_mu" <- 1
  fixed_pars$"var_eta" <- 4
  fixed_pars$"x0" <- matrix(0,2)
  fixed_pars$"phi" <- matrix(2, n_bin)
  modelSpec <- spec_volume_model(fixed_pars = fixed_pars)
  expect_error(smooth_volume_model(data, modelSpec), 
               regexp = "All parameters must be optimally fitted. Parameters a_eta, var_mu, r, V0 are not optimally fitted.")
  

  fixed_pars$"r" <- 1
  fixed_pars$"a_eta" <- 1
  fixed_pars$"var_mu" <- 4
  fixed_pars$"V0" <- c(1,0,0,1)
  modelSpec <- spec_volume_model(fixed_pars = fixed_pars)
  expect_error(forecast_volume_model(data, modelSpec, 300), 
               regexp = "out_sample must be smaller than the number of columns in data matrix.")
  
})

test_that("spec_volume_model message", {
  skip_on_cran()
  init_pars <- list()
  init_pars$"a_eta" <- 1
  init_pars$"x0" <- matrix(0, 2, 2)
  init_pars$"V0" <- matrix(1, 4)
  init_pars$"xxx" <- 3
  
  fixed_pars <- list()
  fixed_pars$"a_mu" <- NA
  fixed_pars$"var_eta" <- 4
  fixed_pars$"x0" <- matrix(Inf, 2)
  fixed_pars$"V0" <- matrix(c(1,0,0,1), nrow= 2)
  
  # predefinde_model <- list()
  # predefinde_model$par <- list("a_eta" =  NA, "a_mu" = NA,
  #                              "var_eta" = 4, "var_mu" = NA,
  #                              "r" = NA, "phi" = NA,
  #                              "x0" = rep(NA, 2),
  #                              "V0" = c(1,0,1))
  # predefinde_model$init <- list("a_eta" =  1)
  # predefinde_model$converged <- list("a_eta" =  TRUE, "a_mu" = TRUE,
  #                                      "var_eta" = FALSE, "var_mu" = TRUE,
  #                                      "r" = TRUE, "phi" = TRUE,
  #                                      "x0" = TRUE, "V0" = FALSE)
  
  warning_message <- paste("Warnings in fixed_pars:\n","  Elements a_mu, x0 are invalid [(]check number/dimension/PSD[)].\n",
                           "Warnings in init_pars:\n","  Elements xxx are not allowed in parameter list.\n",
                           "  Elements x0 are invalid [(]check number/dimension/PSD[)].\n","  Elements V0 have already been fixed." ,sep = "")
  # expect_output(spec_volume_model(init_pars = init_pars, fixed_pars = fixed_pars), warning_message)
  expect_warning(spec_volume_model(init_pars = init_pars, fixed_pars = fixed_pars), warning_message)
  
})

test_that("fit_volume message", {
  skip_on_cran()
  data <- volume_aapl
  data_train <- volume_aapl[, 1:104]
  data_error_test <- data_train
  data_error_test[1,1] <- NA
  fixed_pars <- list(
    "x0" = c(0, 0),
    "a_eta" = 1, "a_mu" = 0,
    "r" = 1e-4,
    "var_eta" = 1e-4, "var_mu" = 1e-4,
    "V0" = c(1, 0,0,1),
    "phi" = rep(2,26)
  )
  
  expect_warning(fit_volume(data_train, control = list(maxit = 1)), 
                 regexp = "Warning! Reached maxit before parameters converged. Maxit was 1.\n")
  expect_output(fit_volume(data_train,verbose = 1, control = list(maxit = 1000, acceleration = TRUE)), 
                regexp = "Success! abstol test passed at")
  expect_error(fit_volume(c(1,1)), regexp = "data must be matrix or xts.")
  expect_output(fit_volume(data, fixed_pars = fixed_pars, verbose = 1), "All parameters have already been fixed.")
  
  # modelSpec.fit_acc <- fit_volume(data_train, modelSpec, maxit = 1000, abstol = 1e-4, log_switch = TRUE, acceleration = TRUE, verbose = 0)
  # 
  # expect_output(fit_volume(data_train, modelSpec.fit_acc), "All parameters have already been fixed.")
  # 
  
})

test_that("clean_data message", {
  skip_on_cran()
  data_error_test <- volume_aapl
  data_error_test[1,1] <- NA
  data_error_test[2,3] <- NA
  expect_warning(clean_data(data_error_test),"For input matrix:\n Remove trading days with missing bins: 2019-01-02, 2019-01-04.\n")
  
  data("volume_fdx")
  expect_warning(clean_data(volume_fdx),"For input xts:\n Remove trading days with missing bins: 2019-07-03, 2019-11-29, 2019-12-24.\n")
})
