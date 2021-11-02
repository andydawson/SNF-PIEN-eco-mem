library(rstan)

#fit_file = 'output/three-bi/ModNegExp/stream.yel/swe.yel_tmax.lsum/imp_logy-lag6-sigma002/fit_ecomem_basis_imp_7a490640.RDS'
fit_file = 'output/three-bi/ModNegExp/tmin.may/ppt.aug_pdsi.sep/imp_logy-lag6-sigma005/fit_ecomem_basis_imp_7a490640.RDS'

fit <- readRDS(fit_file)
pars <- extract(fit)
print(ls(pars))

niters = dim(pars$alpha)[1]

# grab last iteration
inits <- list(list(
  sigma        = pars$sigma[niters,],
  sigma_alpha  = pars$sigma_alpha[niters],
  u            = pars$u[niters,,],
  beta         = pars$beta[niters,],
  gamma0       = pars$gamma0[niters],
  gamma1       = pars$gamma1[niters],
  eta          = pars$eta[niters,],
  Sigma        = pars$Sigma[niters,,],
  mu           = pars$mu[niters,,]
))

saveRDS(inits, "inits.RDS")