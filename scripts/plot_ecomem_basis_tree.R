library(ggplot2)
library(rstan)
library(reshape2)
library(mgcv)
library(purrr)
library(dplyr)

#######################################################################################
## spherical decay function
#######################################################################################

spherical <- function(x, phi) {
  
  # if (x <= 0) {
  #   reject("x negative spherical function undefined; found x = ", x)
  # }
  if (x > phi) { g=0 } else {
    g = (1 - 3.0/2.0 * x/phi + 1.0/2.0 * (x/phi)^3) 
  }
  
  return(g)
}


#######################################################################################
## load and extract posterior samples
#######################################################################################
# fit = readRDS('scripts-stan/output/fit_ecomem_basis_imp.RDS')
# 
# suff = 'imp'

fit = readRDS(paste0(path_output, '/', suffix, '/fit_ecomem_tree.RDS'))

plot(fit)

names(fit)
post = extract(fit, inc_warmup=TRUE)

names(post)


#######################################################################################
## load data
#######################################################################################

dat = readRDS(paste0(path_output, '/', suffix, '/data_ecomem_basis_tree.RDS'))

n_basis = dat$n_basis
N_sites = dat$N_sites
lag = dat$lag
mem_var = dat$mem_var

if (mem_var == "stream.yel"){
  mem_name = "streamflow"
} else if (mem_var == "swe.yel"){
  mem_name = "SWE"
} else {
  mem_name = "Cont Mem Var"
}

#######################################################################################
## plot output
#######################################################################################

if (!dir.exists(path_figures)){
  dir.create(path_figures)
}

dir.create(paste0(path_figures, '/', suffix))
path_figures = paste0(path_figures, '/', suffix)
  

## discrete memory

if ((include_outbreak==1)&(include_fire==0)){
  tau_df = post$tau_dmem 
  phi_df = 1/tau_df
  phi_df_mean = mean(phi_df)
  
  tau = data.frame(iter = seq(1, length(tau_df)), tau_df)
  tau_melt = melt(tau, id.vars='iter')
  
  phi = data.frame(iter = seq(1, length(phi_df)), phi_df)
  phi_melt = melt(phi, id.vars='iter')
  
  ggplot(data=tau_melt) + 
    geom_histogram(aes(x=value, y = (..count..)/sum(..count..))) + 
    facet_grid(variable~.) +
    xlab('phi') +
    ylab('frequency') +
    theme_bw()
  ggsave(paste0(path_figures, '/dmem_tau_hist.png'))
  
  ggplot(data=tau_melt) + 
    geom_line(aes(x = iter, y = value)) + 
    facet_grid(variable~., scales = "free_y") +
    xlab('iter') +
    ylab('value') +
    theme_bw()
  ggsave(paste0(path_figures, '/dmem_tau_trace.png'))
  
  
  x = seq(1e-6, 10, by=0.1)
  # mem_d = unlist(lapply(x, function(x){spherical(x, phi_d_mean)}))
  # 
  # plot(x, mem_dmem, xlab="Year", ylab="Antecedent weight")
  
  dfmem_iter = matrix(NA, nrow=length(phi_df), ncol=length(x))
  for (i in 1:length(phi_df)){
    print(i)
    dfmem_iter[i,] = unlist(lapply(x, function(x){spherical(x, phi_df[i])}))
  }
  
  dfmem_quants = apply(dfmem_iter, 2, function(x) quantile(x, c(0.05, 0.5, 0.95)))
  dfmem_dat = data.frame(type = rep('insect', length(x)), x=x, t(dfmem_quants))
  colnames(dfmem_dat) = c('type', 'x', 'q5', 'q50', 'q95')
  
  dmem_dat =dfmem_dat
  
  # ggplot(data=dimem_dat) +
  #   geom_point(aes(x=x, y=q50)) +
  #   # geom_linerange(aes(y=x, xmin=q5, xmax=q95)) +
  #   geom_linerange(aes(x=x, ymin=q5, ymax=q95)) +
  #   theme_bw() + 
  #   xlab#+
  #   #scale_y_discrete(limits=rev)
  
  # ggplot(data=dimem_dat) +
  #   geom_point(aes(x=x, y=q50)) +
  #   # geom_linerange(aes(y=x, xmin=q5, xmax=q95)) +
  #   geom_linerange(aes(x=x, ymin=q5, ymax=q95)) +
  #   theme_bw() +
  #   xlab#+
  #   #scale_y_discrete(limits=rev)
  
  ggplot(data=dmem_dat) + 
    geom_line(aes(x=x, y=q50, color=type), lwd=1) +
    geom_ribbon(aes(x=x, ymin=q5, ymax=q95, fill=type), alpha=0.4) +
    theme_bw() +
    theme(text = element_text(size=14)) + 
    # xlab("Lag") +
    ylab("Discrete Antecedent Weight") +
    scale_x_continuous(name="Lag", breaks=seq(0, 10))
  ggsave(paste0(path_figures, '/dmem_antecedent_weight.png'))
  
}
if ((include_outbreak==0)&(include_fire==1)){
  
  tau_df = post$tau_dmem 
  phi_df = 1/tau_df
  phi_df_mean = mean(phi_df)
  
  tau = data.frame(iter = seq(1, length(tau_df)), tau_df)
  tau_melt = melt(tau, id.vars='iter')
  
  phi = data.frame(iter = seq(1, length(phi_df)), phi_df)
  phi_melt = melt(phi, id.vars='iter')
  
  ggplot(data=tau_melt) + 
    geom_histogram(aes(x=value, y = (..count..)/sum(..count..))) + 
    facet_grid(variable~.) +
    xlab('phi') +
    ylab('frequency') +
    theme_bw()
  ggsave(paste0(path_figures, '/dmem_tau_hist.png'))
  
  ggplot(data=tau_melt) + 
    geom_line(aes(x = iter, y = value)) + 
    facet_grid(variable~., scales = "free_y") +
    xlab('iter') +
    ylab('value') +
    theme_bw()
  ggsave(paste0(path_figures, '/dmem_tau_trace.png'))
  
  
  x = seq(1e-6, lag, by=0.1)
  # mem_d = unlist(lapply(x, function(x){spherical(x, phi_d_mean)}))
  # 
  # plot(x, mem_dmem, xlab="Year", ylab="Antecedent weight")
  
  dfmem_iter = matrix(NA, nrow=length(phi_df), ncol=length(x))
  for (i in 1:length(phi_df)){
    print(i)
    dfmem_iter[i,] = unlist(lapply(x, function(x){spherical(x, phi_df[i])}))
  }
  
  dfmem_quants = apply(dfmem_iter, 2, function(x) quantile(x, c(0.05, 0.5, 0.95)))
  dfmem_dat = data.frame(type = rep('fire', length(x)), x=x, t(dfmem_quants))
  colnames(dfmem_dat) = c('type', 'x', 'q5', 'q50', 'q95')
  
  dmem_dat =dfmem_dat
  
  # ggplot(data=dimem_dat) +
  #   geom_point(aes(x=x, y=q50)) +
  #   # geom_linerange(aes(y=x, xmin=q5, xmax=q95)) +
  #   geom_linerange(aes(x=x, ymin=q5, ymax=q95)) +
  #   theme_bw() + 
  #   xlab#+
  #   #scale_y_discrete(limits=rev)
  
  # ggplot(data=dimem_dat) +
  #   geom_point(aes(x=x, y=q50)) +
  #   # geom_linerange(aes(y=x, xmin=q5, xmax=q95)) +
  #   geom_linerange(aes(x=x, ymin=q5, ymax=q95)) +
  #   theme_bw() +
  #   xlab#+
  #   #scale_y_discrete(limits=rev)
  
  ggplot(data=dmem_dat) + 
    geom_line(aes(x=x, y=q50, color=type), lwd=1) +
    geom_ribbon(aes(x=x, ymin=q5, ymax=q95, fill=type), alpha=0.4) +
    theme_bw() +
    theme(text = element_text(size=14)) + 
    # xlab("Lag") +
    ylab("Discrete Antecedent Weight") +
    scale_x_continuous(name="Lag", breaks=seq(0, 6))
  ggsave(paste0(path_figures, '/dmem_antecedent_weight.png'))

}

if ((include_outbreak)&(include_fire)){
 
  tau_di = post$tau_dimem 
  phi_di = 1/tau_di
  phi_di_mean = mean(phi_di)
  
  tau_df = post$tau_dfmem
  phi_df = 1/tau_df
  phi_df_mean = mean(phi_df)
  
  tau = data.frame(iter = seq(1, length(tau_df)), tau_di, tau_df)
  tau_melt = melt(tau, id.vars='iter')
  
  phi = data.frame(iter = seq(1, length(phi_df)), phi_di, phi_df)
  phi_melt = melt(phi, id.vars='iter')
  
  ggplot(data=tau_melt) + 
    geom_histogram(aes(x=value, y = (..count..)/sum(..count..))) + 
    facet_grid(variable~.) +
    xlab('phi') +
    ylab('frequency') +
    theme_bw()
  ggsave(paste0(path_figures, '/dmem_tau_hist.png'))
  
  ggplot(data=tau_melt) + 
    geom_line(aes(x = iter, y = value)) + 
    facet_grid(variable~., scales = "free_y") +
    xlab('iter') +
    ylab('value') +
    theme_bw()
  ggsave(paste0(path_figures, '/dmem_tau_trace.png'))
  
  
  x = seq(1e-6, lag, by=0.1)
  # mem_d = unlist(lapply(x, function(x){spherical(x, phi_d_mean)}))
  # 
  # plot(x, mem_dmem, xlab="Year", ylab="Antecedent weight")
  
  dimem_iter = matrix(NA, nrow=length(phi_di), ncol=length(x))
  for (i in 1:length(phi_di)){
    print(i)
    dimem_iter[i,] = unlist(lapply(x, function(x){spherical(x, phi_di[i])}))
  }
  
  dimem_quants = apply(dimem_iter, 2, function(x) quantile(x, c(0.05, 0.5, 0.95)))
  dimem_dat = data.frame(type = rep('insect', length(x)), x=x, t(dimem_quants))
  colnames(dimem_dat) = c('type', 'x', 'q5', 'q50', 'q95')
  
  dfmem_iter = matrix(NA, nrow=length(phi_df), ncol=length(x))
  for (i in 1:length(phi_df)){
    print(i)
    dfmem_iter[i,] = unlist(lapply(x, function(x){spherical(x, phi_df[i])}))
  }
  
  dfmem_quants = apply(dfmem_iter, 2, function(x) quantile(x, c(0.05, 0.5, 0.95)))
  dfmem_dat = data.frame(type = rep('fire', length(x)), x=x, t(dfmem_quants))
  colnames(dfmem_dat) = c('type', 'x', 'q5', 'q50', 'q95')
  
  dmem_dat = rbind(dimem_dat, dfmem_dat)
  
  # ggplot(data=dimem_dat) +
  #   geom_point(aes(x=x, y=q50)) +
  #   # geom_linerange(aes(y=x, xmin=q5, xmax=q95)) +
  #   geom_linerange(aes(x=x, ymin=q5, ymax=q95)) +
  #   theme_bw() + 
  #   xlab#+
  #   #scale_y_discrete(limits=rev)
  
  # ggplot(data=dimem_dat) +
  #   geom_point(aes(x=x, y=q50)) +
  #   # geom_linerange(aes(y=x, xmin=q5, xmax=q95)) +
  #   geom_linerange(aes(x=x, ymin=q5, ymax=q95)) +
  #   theme_bw() +
  #   xlab#+
  #   #scale_y_discrete(limits=rev)
  
  ggplot(data=dmem_dat) + 
    geom_line(aes(x=x, y=q50, color=type), lwd=1) +
    geom_ribbon(aes(x=x, ymin=q5, ymax=q95, fill=type), alpha=0.4) +
    theme_bw() +
    theme(text = element_text(size=14)) + 
    # xlab("Lag") +
    ylab("Discrete Antecedent Weight") +
    scale_x_continuous(name="Lag", breaks=seq(0, 6))
  ggsave(paste0(path_figures, '/dmem_antecedent_weight.png'))
}

## continuous memory
w_num = as.character(seq(0,n_basis))
# w_num[which(nchar(w_num)==1)] = paste0('0', w_num[which(nchar(w_num)==1)])

w = post$w
w_min = apply(w, 2, min, na.rm=TRUE)
w_max = apply(w, 2, max, na.rm=TRUE)

w_quants = apply(w, 2, quantile, c(0.025, 0.5, 0.975))
# w_dat = data.frame(par=paste0('w', w_num), t(w_quants))
w_dat = data.frame(par=w_num, t(w_quants))
colnames(w_dat) = c('par', 'q5', 'q50', 'q95')

ggplot(data=w_dat) +
  geom_point(aes(x=par, y=q50)) +
  geom_linerange(aes(x=par, ymin=q5, ymax=q95)) +
  theme_bw() + 
  xlab('Lag') +
  ylab('Antecedent weight')
  #scale_y_discrete(limits=rev)
ggsave(paste0(path_figures, '/antecedent_weight.png'))

vals = seq(0, lag)
w_dat$vals = vals
w_dat = data.frame(w_dat, type=paste(type, era, mem_name))
saveRDS(w_dat, paste0(path_figures, '/w_dat.RDS'))

ggplot(data=w_dat) + 
  geom_line(aes(x=vals, y=q50),) +
  geom_ribbon(aes(x=vals, ymin=q5, ymax=q95), fill='dodgerblue', alpha=0.5) +
  theme_bw() +
  theme(text = element_text(size=16)) +
  ylab(paste0(mem_name, " \n Antecedent Weight")) +
  #ylab("Continuous \n Antecedent Weight") +
  scale_x_continuous(name="Lag", breaks=seq(0, lag))
ggsave(paste0(path_figures, '/antecedent_weight_ribbon.png'))

# # fit GAM model
# m <- gam(q50 ~ s(vals, k=4), data = w_dat, method='REML') 
# mlo <- gam(q5 ~ s(vals, k=4), data = w_dat, method='REML') 
# mhi <- gam(q95 ~ s(vals, k=4), data = w_dat, method='REML') 
# 
# # define finer grid of predictor values
# lag_fine <- seq(0, lag, by = 0.1) 
# 
# # apply predict() function to the fitted GAM model
# # using the finer grid of x values
# p <- predict(m, newdata = data.frame(vals = lag_fine), se = TRUE) 
# plo <- predict(mlo, newdata = data.frame(vals = lag_fine), se = TRUE) 
# phi <- predict(mhi, newdata = data.frame(vals = lag_fine), se = TRUE) 
# 
# 
# # plot the estimated mean values of y (fit) at given x values
# # over the finer grid of x values;
# # superimpose approximate 95% confidence band for the true 
# # mean values of y at given x values in the finer grid
# w_dat_fine <- data.frame(x = lag_fine, 
#                 fit = p$fit,
#                 lwr = plo$fit, 
#                 upr = phi$fit)
# 
# 
# ggplot(data=w_dat_fine) + 
#   geom_line(aes(x=x, y=fit),) +
#   geom_ribbon(aes(x=x, ymin=lwr, ymax=upr), fill='dodgerblue', alpha=0.5) +
#   theme_bw() +
#   theme(text = element_text(size=16)) +
#   ylab("Continuous \n Antecedent Weight") +
#   scale_x_continuous(name="Lag", breaks=seq(0, lag))
# ggsave(paste0(path_figures, '/antecedent-weight-smooth_', suffix, '.png'))

## gamma
gamma_idx = which(substr(names(post), 1, 5) == "gamma")

gamma_dim = rep(NA, length(gamma_idx))
gamma_names = c()
for (i in 1:length(gamma_idx)){
  gamma_dim[i] = ncol(data.frame(post[gamma_idx[i]][[1]] ))
  gamma_name = names(post[gamma_idx[i]])
  if (gamma_dim[i] == 1) {
    gamma_name_rep = gamma_name
  } else {
    gamma_name_rep = paste0(gamma_name, '_', seq(1, gamma_dim[i]))
    #gamma_name_rep = rep(gamma_name, gamma_dim[i])
    
  }
  gamma_names = c(gamma_names, gamma_name_rep)
}

gamma = matrix(unlist(post[gamma_idx]), ncol = sum(gamma_dim), byrow = FALSE)
colnames(gamma) = gamma_names

gamma_melt = melt(gamma)
colnames(gamma_melt) = c('iter', 'variable', 'value')
# gamma_melt$type = substr(gamma_melt$Var2, 1, 6)
# colnames(gamma_melt) = c('iter', 'variable', 'value', 'type')

ggplot(data=gamma_melt) + 
  geom_histogram(aes(x=value, y = (..count..)/sum(..count..))) + 
  geom_vline(xintercept=0, lty=2) +
  facet_wrap(~variable, scales='free_x') +
  xlab('gamma') +
  ylab('frequency') +
  theme_bw() #+ 
  #coord_flip()
ggsave(paste0(path_figures, '/gamma_hist.png'), height=4)

ggplot(data=gamma_melt) + 
  geom_line(aes(x = iter, y = value)) + 
  facet_grid(variable~., scales = "free_y") +
  xlab('iter') +
  ylab('value') +
  theme_bw()
ggsave(paste0(path_figures, '/gamma_trace.png'))


# #quantile(gamma1, c(0.10, 0.5, 0.90))
# gamma.quants = apply(gamma, 2, quantile, c(0.05, 0.5, 0.95))
# gamma.quants
# # coef.dat = data.frame(par=paste0('gamma', seq(0,ncol(gamma)-1)), t(gamma.quants))
# coef.dat = data.frame(par=colnames(gamma.quants), t(gamma.quants))



## beta

beta_idx = which(substr(names(post), 1, 4) == "beta")
beta_dim = ncol(data.frame(post[beta_idx][[1]]))

beta_names = paste0('beta', seq(0, beta_dim-1))

beta = matrix(unlist(post[beta_idx]), ncol = beta_dim, byrow = FALSE)
colnames(beta) = beta_names

beta_melt = melt(beta)
#beta_melt$type = substr(beta_melt$Var2, 1, 6)
colnames(beta_melt) = c('iter', 'variable', 'value')#, 'type')

ggplot(data=beta_melt) + 
  geom_histogram(aes(x=value, y = (..count..)/sum(..count..))) + 
  geom_vline(xintercept=0, lty=2) +
  facet_wrap(~variable, scales='free_x') +
  xlab('beta') +
  ylab('frequency') +
  theme_bw() #+ 
#coord_flip()
ggsave(paste0(path_figures, '/beta_hist.png'), height=6)

ggplot(data=beta_melt) + 
  geom_line(aes(x = iter, y = value)) + 
  facet_grid(variable~., scales = "free_y") +
  xlab('iter') +
  ylab('value') +
  theme_bw()
ggsave(paste0(path_figures, '/beta_trace.png'))



## both gamma and beta
both_melt = rbind(gamma_melt, beta_melt)

level_order = c('gamma0', 'gamma1', 'beta0', 'beta1')

ggplot(data=both_melt,aes(x=value,y=factor(variable, level=rev(level_order)))) + 
  stat_summary(fun.data=function(x) {
    res <- quantile(x,probs=c(0.025,0.5,0.975))
    names(res)<-c("ymin","y","ymax")
    res}) + theme_bw() + 
  geom_vline(xintercept=0, colour="red", linetype="dashed") +
  xlab("value") + 
  ylab("variable")
ggsave(paste0(path_figures, '/gamma_beta_linerange.png'), height=4)



p <- c(0.2, 0.5, 0.8)
p_names <- map_chr(p, ~paste0(.x*100, "%"))

p_funs <- map(p, ~partial(quantile, probs = .x, na.rm = TRUE)) %>% 
  set_names(nm = p_names)

p_funs

old <- options(pillar.max_dec_width=3)
coef_table = both_melt %>% 
  group_by(variable) %>% 
  summarize_at(vars(value), funs(!!!p_funs))

coef_table = data.frame(coef_table, type=paste(type, era, mem_name))

saveRDS(coef_table, paste0(path_figures, '/coef_table.RDS'))

# 
# both_melt %>% 
#   dplyr::group_by(variable) %>% 
#   dplyr::summarize(quants = quantile(value, probs = c(0.05, 0.5, 0.95)))

## sigma

sigma_idx = which(substr(names(post), 1, 5) == "sigma")

sigma_dim = rep(NA, length(sigma_idx))
sigma_names = c()
for (i in 1:length(sigma_idx)){
  sigma_dim[i] = ncol(data.frame(post[sigma_idx[i]][[1]] ))
  sigma_name = names(post[sigma_idx[i]])
  if (sigma_dim[i] == 1) {
    sigma_name_rep = sigma_name
  } else {
    sigma_name_rep = paste0(sigma_name, '_', seq(1, sigma_dim[i]))
    #gamma_name_rep = rep(gamma_name, gamma_dim[i])
    
  }
  sigma_names = c(sigma_names, sigma_name_rep)
}

sigma = matrix(unlist(post[sigma_idx]), ncol = sum(sigma_dim), byrow = FALSE)
colnames(sigma) = sigma_names

sigma_melt = melt(sigma)
#beta_melt$type = substr(beta_melt$Var2, 1, 6)
colnames(sigma_melt) = c('iter', 'variable', 'value')#, 'type')

ggplot(data=sigma_melt) + 
  geom_histogram(aes(x=value, y = (..count..)/sum(..count..))) + 
  #geom_vline(xintercept=0, lty=2) +
  facet_grid(variable~.) + #, scales='free_x') +
  xlab('sigma') +
  ylab('frequency') +
  theme_bw() #+ 
#coord_flip()
ggsave(paste0(path_figures, '/sigma_hist.png'))

ggplot(data=sigma_melt) + 
  geom_line(aes(x = iter, y = value)) + 
  facet_grid(variable~., scales = "free_y") +
  xlab('iter') +
  ylab('value') +
  theme_bw()
ggsave(paste0(path_figures, '/sigma_trace.png'))

## u individual effects

u_idx = which(substr(names(post), 1, 1) == "u")

u_dim = rep(NA, length(u_idx))
u_names = c()
for (i in 1:length(u_idx)){
  u_dim[i] = ncol(data.frame(post[u_idx[i]][[1]] ))
  u_name = names(post[u_idx[i]])
  if (u_dim[i] == 1) {
    u_name_rep = u_name
  } else {
    u_name_rep = paste0(u_name, '_', seq(1, u_dim[i]))
    #gamma_name_rep = rep(gamma_name, gamma_dim[i])
    
  }
  u_names = c(u_names, u_name_rep)
}

u = matrix(unlist(post[u_idx]), ncol = sum(u_dim), byrow = FALSE)
colnames(u) = u_names

u_means = colMeans(u)
hist(u_means, breaks=20)

u_melt = melt(u)
colnames(u_melt) = c('iter', 'variable', 'value')

N_site_u = length(u_means)/3

# u_melt$site = NA
# u_melt$site[1:N_site_u] = 1
# u_melt$site[(N_site_u+1):(2*N_site_u)] = 2
# u_melt$site[(2*N_site_u+1):(3*N_site_u)] = 3
# 
# ggplot(data=u_melt) + 
#   geom_histogram(aes(x=value, y = (..count..)/sum(..count..))) + 
#   #geom_vline(xintercept=0, lty=2) +
#   facet_grid(site~.) + #, scales='free_x') +
#   xlab('u') +
#   ylab('frequency') +
#   theme_bw() #+ 
# #coord_flip()
# ggsave(paste0(path_figures, '/sigma_hist_', suffix, '.png'))

u_mean_dat = data.frame(u_means = u_means, site = NA)
u_mean_dat$site[1:N_site_u] = 1
u_mean_dat$site[(N_site_u+1):(2*N_site_u)] = 2
u_mean_dat$site[(2*N_site_u+1):(3*N_site_u)] = 3

ggplot(data=u_mean_dat) +
  geom_histogram(aes(x=u_means, y = (..count..)/sum(..count..))) +
  #geom_vline(xintercept=0, lty=2) +
  facet_grid(site~.) + #, scales='free_x') +
  xlab('u mean') +
  ylab('frequency') +
  theme_bw() #+
#coord_flip()
ggsave(paste0(path_figures, '/u_hist.png'))
