# ============================================================================
# 10b_manual_bootstrap_E5.R — Manual wild cluster bootstrap
# fwildclusterboot not available; implement WCB manually
# ============================================================================
set.seed(49)
options(scipen=999, warn=1)

library(data.table)
library(fixest)
pvalue <- fixest::pvalue

PROJ <- "/Users/taozhu/my researches/lancet_financial_v3"
setwd(PROJ)

df <- fread("/Volumes/tjogzt4T/lancet_financial_v2/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]
df_a <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]
df_a[, income_base := .SD[year==min(year), income[1]], by=iso3c]

df_low <- df_a[income_base == "Low income"]
G <- uniqueN(df_low$iso3c)
cat(sprintf("Low-income: %d obs, G=%d clusters\n", nrow(df_low), G))

# Original FE estimate
fit_low <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                 data=df_low, vcov=~iso3c)
beta_hat <- coef(fit_low)["ghe_share_gdp"]
se_clust <- se(fit_low)["ghe_share_gdp"]
t_orig <- beta_hat / se_clust

cat(sprintf("Standard TWFE: β=%.4f, SE=%.4f, t=%.3f, p=%.4f\n", 
            beta_hat, se_clust, t_orig, pvalue(fit_low)["ghe_share_gdp"]))

# ---- Manual Wild Cluster Bootstrap (Rademacher weights) ----
B <- 9999
clusters <- unique(df_low$iso3c)
N_clust <- length(clusters)
t_boot <- numeric(B)

# Pre-compute: get residuals from model (align with non-NA obs)
df_low_model <- df_low[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc) & 
                        !is.na(urbanization) & !is.na(fertility_rate)]
fit_low2 <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                  data=df_low_model, vcov=~iso3c)
beta_hat <- coef(fit_low2)["ghe_share_gdp"]
se_clust <- se(fit_low2)["ghe_share_gdp"]

df_low_model[, resid := residuals(fit_low2)]
df_low_model[, fitted := fitted.values(fit_low2)]
clusters <- unique(df_low_model$iso3c)
N_clust <- length(clusters)
df_low_model[, cluster_id := match(iso3c, clusters)]

cat(sprintf("Model sample: %d obs, G=%d clusters\n", nrow(df_low_model), N_clust))
cat(sprintf("β=%.4f, SE=%.4f, t=%.3f, p=%.4f\n", beta_hat, se_clust, beta_hat/se_clust, pvalue(fit_low2)["ghe_share_gdp"]))

# For speed: compute cluster-level scores
X <- model.matrix(fit_low, type="rhs")  # RHS variables
y <- df_low$hale

# Simpler approach: wild cluster bootstrap via residual resampling
# For each bootstrap, multiply each cluster's residuals by ±1 (Rademacher)
for(b in 1:B) {
  # Generate Rademacher weights per cluster
  w <- sample(c(-1, 1), N_clust, replace=TRUE)
  df_low[, wt := w[cluster_id]]
  
  # Wild bootstrap y*
  df_low[, y_star := fitted.values(fit_low) + resid * wt]
  
  # Re-estimate
  fit_b <- try(feols(y_star ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                     data=df_low), silent=TRUE)
  
  if(!inherits(fit_b, "try-error")) {
    beta_b <- coef(fit_b)["ghe_share_gdp"]
    # Use clustered SE from original for t-stat (common in WCB)
    # Actually compute t-stat using bootstrap SE
    t_boot[b] <- beta_b
  }
}

# Remove failed iterations
t_boot <- t_boot[t_boot != 0]
B_eff <- length(t_boot)
cat(sprintf("Bootstrap: %d/%d successful iterations\n", B_eff, B))

# Bootstrap p-value (two-sided)
p_boot <- mean(abs(t_boot - mean(t_boot)) >= abs(beta_hat))
# Alternative: percentile method
p_boot_percentile <- 2 * min(mean(t_boot <= 0), mean(t_boot >= 0))
# Standard: fraction of bootstrap estimates that are "more extreme"
p_boot_extreme <- mean(abs(t_boot) >= abs(beta_hat))

cat(sprintf("\nWild Cluster Bootstrap Results (B=%d):\n", B_eff))
cat(sprintf("  Bootstrap mean β: %.4f\n", mean(t_boot)))
cat(sprintf("  Bootstrap SD:     %.4f\n", sd(t_boot)))
cat(sprintf("  Bootstrap p (two-sided abs): %.4f\n", p_boot_extreme))
cat(sprintf("  Bootstrap p (percentile):    %.4f\n", p_boot_percentile))
cat(sprintf("  Standard clustered p:        %.4f\n", pvalue(fit_low)["ghe_share_gdp"]))
cat(sprintf("  Bootstrap 95%% CI: [%.4f, %.4f]\n", quantile(t_boot, 0.025), quantile(t_boot, 0.975)))

# Save
fwrite(data.table(
  Method=c("Standard clustered SE", "Wild cluster bootstrap (Rademacher)"),
  Coefficient=c(beta_hat, mean(t_boot)),
  SE=c(se_clust, sd(t_boot)),
  p_value=c(pvalue(fit_low)["ghe_share_gdp"], p_boot_extreme),
  CI_lower=c(beta_hat-1.96*se_clust, quantile(t_boot, 0.025)),
  CI_upper=c(beta_hat+1.96*se_clust, quantile(t_boot, 0.975)),
  N_clusters=c(G, G),
  N_obs=c(nrow(df_low), nrow(df_low))
), "results/tables/E5_wild_bootstrap_lowincome.csv")

cat("\nSaved: E5_wild_bootstrap_lowincome.csv\n")
cat("=== E5 Complete ===\n")
