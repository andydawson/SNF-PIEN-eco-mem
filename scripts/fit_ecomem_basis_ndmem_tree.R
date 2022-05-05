library(rstan)
library(mgcv)
library(dplR)


source("scripts/read.tre.r")

dir.create(paste0(path_figures, '/', suffix))
# path_figures = paste0(path_figures, '/', suffix)
# tmp <- read.tre('data/tree/TrwARS.TRE')
# 
# sites            = c("BTP","CBS","TOW")
# type             = 'bi'

N_sites = length(sites)

raw_tree = list()
raw_clim = list()
for (nsite in 1:N_sites){
  site = sites[nsite]
  tree = read.tre(paste0('data/tree/', site,  type, 'ARS.TRE'))

  raw_tree[[site]] = tree
  
  climate = read.csv(paste0('data/raw/', site, '-climate.csv'), header=TRUE)
  raw_clim[[site]] = climate
  
  # chron_df = data.frame(year = rownames(chron), chron = chron[,1], sdepth = chron[,2])
#  chron_df = chron_df[which(chron_df$sdepth<2),]


  # raw[[site]] = merge(chron_df, climate, by.x = 'year')
}
names(raw_tree) = sites
names(raw_clim) = sites


## find the start year and end year
## for now require that chronologies and fire record all be the same length with no NA values
## climate data of shorter length NA values will be imputed
N_trees_max = NA

year_upper = NA
year_lower = NA

for (site in 1:N_sites){
  N_trees_max = max(N_trees_max, ncol(raw_tree[[site]]), na.rm=TRUE)
  
  tree_years = as.numeric(rownames(raw_tree[[site]]))
  
  year_upper = min(year_upper, max(tree_years, na.rm=TRUE), na.rm=TRUE)
  year_lower = max(year_lower, min(tree_years, na.rm=TRUE), na.rm=TRUE)
  
  raw_clim_sub = raw_clim[[site]][which(!is.na(raw_clim[[site]][,mem_var])),]
  clim_years = raw_clim_sub$year
  
  year_upper = min(year_upper, max(clim_years, na.rm=TRUE), na.rm=TRUE)
  year_lower = max(year_lower, min(clim_years, na.rm=TRUE), na.rm=TRUE)
}

years = seq(year_lower, year_upper)
N_years = length(years)

# subset site and fire data to selected years
for (site in 1:N_sites){ 
 raw_tree[[site]] = raw_tree[[site]][which(as.numeric(rownames(raw_tree[[site]])) %in% years),]
 raw_clim[[site]] = raw_clim[[site]][which(raw_clim[[site]]$year %in% years),]
}

## define data objects

# tree data
# Y = t(matrix(unlist(lapply(raw_tree, function(x) x)), ncol=N_sites, byrow=FALSE))

Y = array(NA, c(N_sites, N_years, N_trees_max))
N_trees = rep(NA, N_sites)
for (site in 1:N_sites){ 
  N_trees[site] = ncol(raw_tree[[site]])
  Y[site, , 1:N_trees[site]] = as.matrix(raw_tree[[site]])
}

tree_years = array(NA, c(N_sites, N_trees_max, 2))
for (site in 1:N_sites){
  tree_years[site, 1:N_trees[site], ] = t(apply(Y[site,,1:N_trees[site]], 2, function(x) c(min(which(!is.na(x))), max(which(!is.na(x))))))
}

# continuous memory var
d = t(matrix(unlist(lapply(raw_clim, function(x) x[,mem_var])), ncol=N_sites, byrow=FALSE))

# covars

N_covars = length(covars)

X = array(NA, c(N_sites, N_years, N_covars))
for (i in 1:N_covars){
  X[,,i] = t(matrix(unlist(lapply(raw_clim, function(x) x[,covars[i]])), ncol=N_sites, byrow=FALSE))
}

# idx.short.na  = which(apply(X, 2, function(x) any(is.na(x))))
# 
# for (i in 1:N_covars){
#   if (N_sites != 1){
#     X[,idx.short.na,i] =  matrix(rowMeans(X[,,i], na.rm=TRUE))[,rep(1, length(idx.short.na))]
#     d[,idx.short.na]  = matrix(rowMeans(d, na.rm=TRUE))[,rep(1, length(idx.short.na))]
#   } else if (N_sites == 1){
#     X[,idx.short.na,i] =  rep(mean(X[,,i], na.rm=TRUE), length(idx.short.na))
#     d[,idx.short.na]  = rep(mean(d, na.rm=TRUE), length(idx.short.na))
#   }
#   #X[,,i] = X[,,i] - rowMeans(X[,,i], na.rm=TRUE)
#   #d = d - rowMeans(d)
# }
# 
# 
# X_nmiss = length(idx.short.na)
# d_nmiss = length(idx.short.na)
# 
# X_index = array(idx.short.na)
# d_index = array(idx.short.na)

#######################################################################################
## splines
#######################################################################################

t.s = (0:lag)/lag
time = data.frame(t=0:lag,t.s=t.s)
n.knots = lag + 1
foo = mgcv::s(t.s,k=n.knots,bs="cr")

CRbasis = mgcv::smoothCon(foo,
                          data=time,
                          knots=NULL,
                          absorb.cons=TRUE,
                          scale.penalty=TRUE)

RE = diag(ncol(CRbasis[[1]]$S[[1]]))
B = CRbasis[[1]]$X
S = CRbasis[[1]]$S[[1]] +(1E-07)*RE
S_inv = solve(S)

n_basis = ncol(B)
n_knots = nrow(B)


#######################################################################################
## compile data as a list; save data as RDS object
#######################################################################################

# dat = list(N_years = N_years,
#            N_sites = N_sites,
#            lag = lag,
#            N_covars = N_covars,
#            Y = Y,
#            X = X,
#            d = d,
#            B = B,
#            S_inv = S_inv,
#            n_basis = n_basis,
#            n_knots = n_knots,
#            X_nmiss = X_nmiss,
#            d_nmiss = d_nmiss,
#            X_index = X_index,
#            d_index = d_index,
#            include_fire = include_fire,
#            include_outbreak = include_outbreak)

Y[which(is.na(Y))] = 0
tree_years[which(is.na(tree_years))] = 0


dat = list(N_years = N_years,
           N_sites = N_sites,
           N_trees_max = N_trees_max,
           N_trees = N_trees,
           tree_years = tree_years,
           lag = lag,
           sigma_eta = sigma,
           N_covars = N_covars,
           n_basis = n_basis,
           n_knots = n_knots,
           Y = Y,
           X = X,
           cmem = d,
           B = B,
           S_inv = S_inv,
           # X_nmiss = X_nmiss,
           # d_nmiss = d_nmiss,
           # X_index = X_index,
           # d_index = d_index,
           mem_var = mem_var
           )

if (!dir.exists(path_output)){
  dir.create(path_output)
}

saveRDS(dat, paste0(path_figures, '/', suffix, '/data_ecomem_basis_tree.RDS'))

if (include_inits) {
  inits = readRDS(init_file)
} else {
  inits = list()
}

#######################################################################################
## meta data save
#######################################################################################

# # dataset info
# sites            = c("BTP","CBS","TOW")
# type             = 'bi'
# era              = 'paleo'
# detrend_method   = 'Spline80'
# covars           = c("swe.yel","tmax.lsum")
# mem_var          = 'stream.yel'
# lag              = 6
# sigma            = 0.05
# 
# meta = list(sites=sites,
#             type=type,
#             era=era,
#             detrend_method,
#             covars=covars,
#             mem_var=mem_var,
#             lag=lag, 
#             sigma=sigma)
# 
# saveRDS(meta, paste0(path_output, '/meta_ecomem_basis_imp_', suffix, '.RDS'))

#######################################################################################
## compile model and perform sampling
#######################################################################################

sm<-stan_model(model_name)

# parameter estimation
fit<-sampling(sm,
              data = dat,
              iter = N_iter,
              warmup = N_warmup,
              chains = 1, 
              cores = 1,
              init = ifelse(include_inits, inits, 'random'))

# save stan fit object for subsequent analysis


saveRDS(fit, paste0(path_figures, '/', suffix, '/fit_ecomem_tree.RDS'))

