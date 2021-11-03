#
# MODERN THREE BI
#
# detrend_method: both ModNegExp and Spline80 work well
# sigma: from 0.01 to 0.05 appear to work well

# dataset info
sites            = c("BTP","CBS","TOW")
type             = 'bi'
detrend_method   = 'Spline80'
covars           = c("ppt.aug","pdsi.sep")
mem_var          = 'tmin.may'
lag              = 6
sigma            = 0.01

# stan
N_iter           = 1000
model_name       = 'scripts/ecomem_basis_imp_logy_0dmem.stan'
include_outbreak = 0
include_fire     = 0
include_inits    = 1
init_file        = 'data/inits/modern-tmin.may-lag6.RDS'

# output
serial           = '01'
suffix           = paste0(serial, '-modern-three-', type, '-', detrend_method, '-', mem_var, '-', paste(covars, collapse='', sep='_'))
path_output      = 'output'
path_figures     = 'output'

# go!
source("scripts/fit_ecomem_basis_imp_ndmem.R")
source("scripts/plot_ecomem_basis_imp.R")
