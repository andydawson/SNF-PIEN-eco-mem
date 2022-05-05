library(rstan)

#fit_file = 'output/three-bi/ModNegExp/stream.yel/swe.yel_tmax.lsum/imp_logy-lag6-sigma002/fit_ecomem_basis_imp_7a490640.RDS'
#fit_file = 'output/three-bi/ModNegExp/tmin.may/ppt.aug_pdsi.sep/imp_logy-lag6-sigma005/fit_ecomem_basis_imp_7a490640.RDS'
# fit_file = 'output/three-rw/ModNegExp/swe.yel/stream.yel_tmax.lsum/imp_logy-lag6-sigma001/fit_ecomem_basis_imp_ac98ce08-01.RDS'

if (type=="bi"){
fit_file = "output/fit_ecomem_ind_01-modern-three-ind-bi-tmin.may-ppt.augpdsi.sep.RDS"
} else {
# fit_file = "output/fit_ecomem_ind_07-modern-three-ind-rw-tmin.may-ppt.augpdsi.sep.RDS"
  fit_file = "output/fit_ecomem_ind_08-modern-three-ind-rw-tmin.may-ppt.augpdsi.sep.RDS"
}

fit <- readRDS(fit_file)
pars <- extract(fit)
print(ls(pars))

niters = dim(pars$alpha)[1]

# grab last iteration
inits <- list(list(
  sigma        = pars$sigma[niters],
  sigma_site   = pars$sigma_site[niters],
  sigma_tree   = pars$sigma_tree[niters],
  # sigma        = pars$sigma[niters,],
  # sigma_alpha  = pars$sigma_alpha[niters],
  u_site       = pars$u_site[niters,,],
  u_tree       = pars$u_tree[niters,,,],
  beta         = pars$beta[niters,],
  gamma0       = pars$gamma0[niters],
  gamma1       = pars$gamma1[niters],
  eta          = pars$eta[niters,],
  Sigma        = pars$Sigma[niters,,]#,
  #mu           = pars$mu[niters,,]
))

saveRDS(inits, paste0("inits_ind_", type, ".RDS"))
