functions {
  real spherical(real x, real phi) {
    real g;
    
    if (x <= 0) {
      reject("x negative spherical function undefined; found x = ", x);
    }
    else if (x > phi) g=0;
    else {
        g = (1 - 3.0/2.0 * x/phi + 1.0/2.0 * (x/phi)^3); 
    }
    
    return g;
  }
  
}

data { 
  int<lower=0> N_years; 
  int<lower=0> N_sites;
  int<lower=0> N_trees_max;
  int<lower=0> N_trees[N_sites];
  
  int<lower=0> lag;
  int<lower=0> N_covars;
  int<lower=0> n_basis;
  int<lower=0> n_knots;
  real sigma_eta;
  
  //vector[N_years] Y[N_sites];
  matrix[N_years, N_trees_max] Y[N_sites];

  int tree_years[N_sites, N_trees_max, 2];

  matrix[N_years, N_covars] X[N_sites];
  vector[N_years] cmem[N_sites];

  matrix[n_knots, n_basis] B;
  matrix[n_basis, n_basis] S_inv;

  // int X_nmiss;
  // int d_nmiss;

  // int X_index[X_nmiss];
  // int d_index[d_nmiss];
  
} 
transformed data {
  //vector[N_years] logY[N_sites];
  matrix[N_years, N_trees_max] logY[N_sites];

  for (site in 1:N_sites){
    for (tree in 1:N_trees[site]) {
      for (year in tree_years[site][tree,1]:tree_years[site][tree,2]) {
        logY[site][year,tree] = log(Y[site][year,tree]);
      }
    }
  }
}

parameters { 
  //vector<lower=1e-6>[N_sites] sigma_site;
  real<lower=1e-6> sigma_site;
  real<lower=1e-6> sigma;
  real<lower=1e-6> sigma_tree;
  matrix[N_years-lag, N_trees_max] u_tree[N_sites];
  vector[N_years-lag] u_site[N_sites];

  
  vector[N_covars] beta;

  real gamma0;
  real gamma1;

  vector[n_basis] eta;

  //vector[N_years-lag] alpha[N_sites];
  
  // MVN covariates; for imputation
  cholesky_factor_cov[N_covars+2] Sigma;
  //vector[N_covars+2] mu[N_sites];

  // // Missings
  // vector[X_nmiss] X1_imp[N_sites];
  // vector[X_nmiss] X2_imp[N_sites];
  // vector[d_nmiss] d_imp[N_sites];
}

transformed parameters { 
  vector[N_years] z[N_sites];
  vector[N_years] f;
  vector[N_years-lag] alpha[N_sites];
  
  //matrix[N_years, N_covars+2] dat[N_sites];
  
  vector[lag+1] exp_B_eta;
  real sum_exp_B_eta;

  vector[lag+1] w;
  real w_sum;
  
  //logX2_imp = log(X2_imp);
  
  // for (site in 1:N_sites){
  //   dat[site][, 1] = logY[site];
  //   dat[site][, 2:(N_covars+1)] = X[site];
  //   dat[site][, N_covars+2] = cmem[site];
  //   dat[site][X_index, 2] = X1_imp[site];
  //   dat[site][X_index, 3] = X2_imp[site];
  //   dat[site][d_index, N_covars+2] = d_imp[site];
  // }

  exp_B_eta = exp(B * eta);
  sum_exp_B_eta = sum(exp_B_eta);

  w = exp_B_eta / sum_exp_B_eta;

  for (site in 1:N_sites) {
    z[site] = rep_vector(0, N_years);
    for (year in (lag+1):N_years) {
      for (l in 0:lag){
	z[site][year] = z[site][year] + cmem[site][year-l] * w[l+1];
      }
    }
  }

 for (site in 1:N_sites) {
    alpha[site] = gamma0 + z[site][(lag+1):N_years] * gamma1;
   //alpha[site] ~ normal(gamma0 + z[site][(lag+1):N_years] * gamma1, sigma_site);
 }
  
}

model {
  int idx_start;
  int idx_end;
  
  // priors
  sigma ~ cauchy(1e-6, 5);
  sigma_tree ~ cauchy(1e-6, 5);
  sigma_site ~ cauchy(1e-6, 5);
  
  beta ~ normal(0, 10);
  
  gamma0 ~ normal(0, 2);
  gamma1 ~ normal(0, 1e5);

  // for (site in 1:N_sites){
  //   mu[site] ~ normal(0,2);
  // }

  // // MVN imputation
  // for (site in 1:N_sites){
  //   for(year in 1:N_years){
  //     dat[site][year,] ~ multi_normal_cholesky(mu[site],Sigma);
  //   }
  // }

  for (site in 1:N_sites){
    for (tree in 1:N_trees[site]) {
      idx_start = tree_years[site,tree,1] + lag;
      idx_end   = tree_years[site,tree,2];
      //u[site] ~ normal(0, sigma_alpha);
      u_tree[site][(idx_start-lag):(idx_end-lag),tree] ~ normal(0, sigma_tree);
    }
    u_site[site][1:(N_years-lag)] ~ normal(0, sigma_site);
  }

  // for (site in 1:N_sites) {
  //   //alpha[site] = gamma0 + z[site][(lag+1):N_years] * gamma1;
  //   alpha[site] ~ normal(gamma0 + z[site][(lag+1):N_years] * gamma1, sigma_site);
  // }

  eta ~ multi_normal(rep_vector(0, n_basis), sigma_eta^2 * S_inv);

  for (site in 1:N_sites){
    for (tree in 1:N_trees[site]) {
      idx_start = tree_years[site,tree,1] + lag;
      idx_end   = tree_years[site,tree,2];
      //print(idx_start);
      //print(idx_end);
      //logY[site][idx_start:idx_end,tree]  ~ normal(alpha[site] + dat[site][(lag+1):N_years,2:(N_covars+1)] * beta + u[site], sigma[site]);
      logY[site][idx_start:idx_end,tree]  ~ normal(alpha[site][(idx_start-lag):(idx_end-lag)] +
      						   X[site][idx_start:idx_end,] * beta +
      						   u_tree[site][(idx_start-lag):(idx_end-lag),tree] +
      					           u_site[site][(idx_start-lag):(idx_end-lag)], sigma);
            // logY[site][idx_start:idx_end,tree]  ~ normal(alpha[site][(idx_start-lag):(idx_end-lag)] +
	    // 					   X[site][idx_start:idx_end,] * beta +
	    // 					   u_tree[site][(idx_start-lag):(idx_end-lag),tree], sigma_site[site]);

    }
  }
} 
