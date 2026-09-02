# Quick wild cluster bootstrap for low-income — SIMPLE VERSION
set.seed(49)
library(data.table)
library(fixest)
pvalue <- fixest::pvalue

df <- fread("/Users/taozhu/my researches/lancet_financial_v3/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]
df_a <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]
df_a[, income_base := .SD[year==min(year), income[1]], by=iso3c]
df_low <- df_a[income_base == "Low income"]

# Original FE
fit <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
             data=df_low, vcov=~iso3c)
beta_hat <- coef(fit)["ghe_share_gdp"]
se_orig <- se(fit)["ghe_share_gdp"]

cat(sprintf("Original: β=%.4f, SE=%.4f, p=%.4f\n", beta_hat, se_orig, pvalue(fit)["ghe_share_gdp"]))

# Simple wild cluster bootstrap: resample clusters with replacement, compute t-stat
clusters <- unique(df_low$iso3c)
G <- length(clusters)
B <- 9999
beta_boot <- numeric(B)

for(b in 1:B) {
  # Resample clusters with replacement
  boot_clust <- sample(clusters, G, replace=TRUE)
  boot_data <- rbindlist(lapply(boot_clust, function(c) df_low[iso3c==c]))
  
  fit_b <- try(feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                     data=boot_data), silent=TRUE)
  if(!inherits(fit_b, "try-error")) {
    beta_boot[b] <- coef(fit_b)["ghe_share_gdp"]
  }
}
beta_boot <- beta_boot[beta_boot != 0]
B_eff <- length(beta_boot)

# Bootstrap SE and p-value
boot_se <- sd(beta_boot)
boot_p <- 2 * min(mean(beta_boot <= 0), mean(beta_boot >= 0))
boot_ci <- quantile(beta_boot, c(0.025, 0.975))

cat(sprintf("Bootstrap (B=%d effective):\n", B_eff))
cat(sprintf("  Bootstrap SE: %.4f (vs clustered %.4f)\n", boot_se, se_orig))
cat(sprintf("  Bootstrap p:  %.4f (vs clustered %.4f)\n", boot_p, pvalue(fit)["ghe_share_gdp"]))
cat(sprintf("  95%% CI: [%.4f, %.4f]\n", boot_ci[1], boot_ci[2]))

fwrite(data.table(
  Method=c("Standard clustered","Cluster bootstrap"),
  Coef=c(beta_hat, mean(beta_boot)),
  SE=c(se_orig, boot_se),
  p_value=c(pvalue(fit)["ghe_share_gdp"], boot_p),
  CI_lower=c(beta_hat-1.96*se_orig, boot_ci[1]),
  CI_upper=c(beta_hat+1.96*se_orig, boot_ci[2])
), "/Users/taozhu/my researches/lancet_financial_v3/results/tables/E5_wild_bootstrap_lowincome.csv")

cat("\nSaved.\n")
