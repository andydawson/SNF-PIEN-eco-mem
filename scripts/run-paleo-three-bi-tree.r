
# dataset info
sites            = c("BTP","CBS","TOW")
type             = 'bi'
# detrend_method   = 'Spline80'
covars           = c("swe.yel","tmax.lsum")
mem_var          = 'stream.yel'
# covars           = c("stream.yel","tmax.lsum")
# mem_var          = 'swe.yel'
lag              = 6
sigma            = 0.05
era = "paleo"

# stan
N_iter           = 1000
N_warmup         = 500
model_name       = 'scripts/ecomem_logy_0dmem_tree.stan'
include_outbreak = 0
include_fire     = 0
include_inits    = 0
init_file        = 'data/inits/paleo-stream.yel-lag6.RDS'

# output
serial           = '01'
suffix           = paste0(serial, '-paleo-three-ind-', type, '-', detrend_method, '-', mem_var, '-', paste(covars, collapse='', sep='_'))
path_output      = 'output'
path_figures     = 'output'

# go!
source("scripts/fit_ecomem_basis_ndmem_tree.R")
source("scripts/plot_ecomem_basis_tree.R")
