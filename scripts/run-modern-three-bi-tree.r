#
# MODERN THREE BI
#
# detrend_method: both ModNegExp and Spline80 work well
# sigma: from 0.01 to 0.05 appear to work well

# dataset info
sites            = c("BTP","CBS","TOW")
type             = 'rw'
# detrend_method   = 'Spline80'
covars           = c("ppt.aug","pdsi.sep")
# covars           = c("tmin.may", "ppt.aug")
# covars           = c("tmin.may", "pdsi.sep")
mem_var          = 'tmin.may'
# mem_var          = "pdsi.sep"
# mem_var          = "ppt.aug"
lag              = 6
sigma            = 0.05#0.1
era = "modern"

# stan
N_iter           = 1000
N_warmup         = 500
model_name       = 'scripts/ecomem_logy_0dmem_tree.stan'
include_outbreak = 0
include_fire     = 0
include_inits    = 0
# init_file        = 'data/inits/modern-tmin.may-lag6.RDS'
init_file        = 'inits.RDS'

# output
serial           = '02'
suffix           = paste0(serial, '-modern-three-ind-', type, '-', mem_var, '-', paste(covars, collapse='', sep='_'))
path_output      = 'output'
path_figures     = 'output'

# go!
source("scripts/fit_ecomem_basis_ndmem_tree.R")
source("scripts/plot_ecomem_basis_tree.R")
