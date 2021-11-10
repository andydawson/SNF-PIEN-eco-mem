library(rstan)

## continuous memory
n_basis = 6 
lag = 6
w_num = as.character(seq(0,n_basis))
w_num[which(nchar(w_num)==1)] = paste0('0', w_num[which(nchar(w_num)==1)])

vals = seq(0, lag)

#
bi_paleo_swe = readRDS('output/staging/bi-paleo-swe/fit.RDS')
w_bi_paleo_swe = extract(bi_paleo_swe, inc_warmup=TRUE)$w

w_quants = apply(w_bi_paleo_swe, 2, quantile, c(0.025, 0.5, 0.975))
w_bi_swe = data.frame(par=paste0('w', w_num), t(w_quants))
colnames(w_bi_swe) = c('par', 'q5', 'q50', 'q95')
w_bi_swe$vals = vals

w = data.frame(w_bi_swe, type=rep("bi paleo swe"))

#
bi_paleo_stream = readRDS('output/staging/bi-paleo-stream/fit.RDS')
w_bi_paleo_stream = extract(bi_paleo_stream, inc_warmup=TRUE)$w

w_quants = apply(w_bi_paleo_stream, 2, quantile, c(0.025, 0.5, 0.975))
w_bi_stream = data.frame(par=paste0('w', w_num), t(w_quants))
colnames(w_bi_stream) = c('par', 'q5', 'q50', 'q95')
w_bi_stream$vals = vals

w = rbind(w, 
          data.frame(w_bi_stream, type=rep("bi paleo stream")))

#
bi_paleo_tmax = readRDS('output/staging/bi-paleo-tmax/fit.RDS')
w_bi_paleo_tmax = extract(bi_paleo_tmax, inc_warmup=TRUE)$w

w_quants = apply(w_bi_paleo_tmax, 2, quantile, c(0.025, 0.5, 0.975))
w_bi_tmax = data.frame(par=paste0('w', w_num), t(w_quants))
colnames(w_bi_tmax) = c('par', 'q5', 'q50', 'q95')
w_bi_tmax$vals = vals

w = rbind(w, 
          data.frame(w_bi_tmax, type=rep("bi paleo tmax")))

ggplot(data=w) + 
  geom_line(aes(x=vals, y=q50, group=type),) +
  geom_ribbon(aes(x=vals, ymin=q5, ymax=q95, group=type, fill=type), alpha=0.5) +
  theme_bw() +
  theme(text = element_text(size=16)) +
  #ylab(paste0(mem_name, " \n Antecedent Weight")) +
  ylab("Antecedent Weight") +
  scale_x_continuous(name="Lag", breaks=seq(0, lag))


# coef_bi_paleo_stream = readRDS( 'output/01-paleo-three-bi-Spline80-stream.yel-swe.yeltmax.lsum/coef_table_bi_paleo.RDS')
# 
# coef_bi_paleo_swe    = readRDS('output/01-paleo-three-bi-Spline80-swe.yel-stream.yeltmax.lsum/coef_table_bi_paleo.RDS')
# 
# coef_bi_paleo = rbind(coef_bi_paleo_stream,
#                    coef_bi_paleo_swe)


#
rw_paleo_swe = readRDS('output/staging/rw-paleo-swe/fit.RDS')
w_rw_paleo_swe = extract(rw_paleo_swe, inc_warmup=TRUE)$w

w_quants = apply(w_rw_paleo_swe, 2, quantile, c(0.025, 0.5, 0.975))
w_rw_swe = data.frame(par=paste0('w', w_num), t(w_quants))
colnames(w_rw_swe) = c('par', 'q5', 'q50', 'q95')
w_rw_swe$vals = vals

w = rbind(w, 
          data.frame(w_rw_swe, type=rep("rw paleo swe")))

#
rw_paleo_tmax = readRDS('output/staging/rw-paleo-tmax/fit.RDS')
w_rw_paleo_tmax = extract(rw_paleo_tmax, inc_warmup=TRUE)$w

w_quants = apply(w_rw_paleo_tmax, 2, quantile, c(0.025, 0.5, 0.975))
w_rw_tmax = data.frame(par=paste0('w', w_num), t(w_quants))
colnames(w_rw_tmax) = c('par', 'q5', 'q50', 'q95')
w_rw_tmax$vals = vals

w = rbind(w, 
          data.frame(w_rw_tmax, type=rep("rw paleo tmax")))

ggplot(data=w) + 
  geom_line(aes(x=vals, y=q50, group=type),) +
  geom_ribbon(aes(x=vals, ymin=q5, ymax=q95, group=type, fill=type), alpha=0.5) +
  theme_bw() +
  theme(text = element_text(size=16)) +
  #ylab(paste0(mem_name, " \n Antecedent Weight")) +
  ylab("Antecedent Weight") +
  scale_x_continuous(name="Lag", breaks=seq(0, lag))

