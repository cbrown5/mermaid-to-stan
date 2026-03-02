library(rstan)

stan_code <- "
data {
  int N;
  vector[N] x;
  vector[N] y;
}
parameters {
  real alpha;
  real beta;
  real<lower=0> sigma;
}
model {
  vector[N] mu;
  mu = alpha + beta*x;
  alpha ~ normal(0, 10);
  beta ~ normal(0, 10);
  sigma ~ normal(0, 1);  // HalfNormal: truncated via <lower=0> constraint
  y ~ normal(mu, sigma);
}
"

# --- Test: compile the model ---
m <- stan_model(model_code = stan_code)
cat("Model compiled successfully\n")

# --- Test: sample with simulated data ---
set.seed(42)
N <- 50
x <- rnorm(N)
y <- 1.5 + 0.8 * x + rnorm(N, sd = 0.5)

fit <- sampling(m,
  data = list(N = N, x = x, y = y),
  iter = 1000, chains = 2, refresh = 0
)

print(fit, pars = c("alpha", "beta", "sigma"))