
# dataset info
sites            = c("BTP","CBS","TOW")
type             = 'bi'
detrend_method   = 'Spline80'
covars           = c("swe.yel","tmax.lsum")
mem_var          = 'stream.yel'
lag              = 6
sigma            = 0.05

# stan
N_iter           = 1000
model_name       = 'scripts/ecomem_basis_imp_logy_0dmem.stan'
include_outbreak = 0
include_fire     = 0
include_inits    = 1
init_file        = 'data/inits/paleo-stream.yel-lag6.RDS'

# output
serial           = '01'
suffix           = paste0(serial, '-paleo-three-', type, '-', detrend_method, '-', mem_var, '-', paste(covars, collapse='', sep='_'))
path_output      = 'output'
path_figures     = 'output'

# go!
source("scripts/fit_ecomem_basis_imp_ndmem.R")
source("scripts/plot_ecomem_basis_imp.R")
