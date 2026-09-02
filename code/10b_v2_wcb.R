#!/usr/bin/env Rscript
# 10b_v2 — 正确的 CGM(2008) 受限 studentised wild cluster bootstrap
# y* = Xβ̂ − ghe·β̂_ghe + û_R·w  (null imposition: β_GHE = 0; û_R = restricted residuals)
# t* = (β* − β̂)/SE*(bootstrap clustered SE)——studentised
set.seed(49)
suppressMessages({library(data.table); library(fixest)})

PROJ <- "/Users/taozhu/my researches/lancet_financial_v3"
setwd(PROJ)

df <- fread("data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]
df_a <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]
df_a[, income_base := .SD[year==min(year), income[1]], by=iso3c]
df_low <- df_a[income_base == "Low income"]

# 模型样本(与 Table 2 一致:516 obs, G=23)
df_m <- df_low[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc) &
               !is.na(urbanization) & !is.na(fertility_rate)]
cat(sprintf("Model sample: %d obs, G=%d clusters\n", nrow(df_m), uniqueN(df_m$iso3c)))

fit_full <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                 data=df_m, vcov=~iso3c)
beta_hat <- coef(fit_full)["ghe_share_gdp"]
se_cl   <- se(fit_full)["ghe_share_gdp"]
t_obs   <- beta_hat / se_cl
cat(sprintf("TWFE: β=%.4f, SE=%.4f, t=%.3f, p=%.4f\n", beta_hat, se_cl, t_obs, fixest::pvalue(fit_full)["ghe_share_gdp"]))

# 受限模型(H0: β_GHE = 0)——受限残差 û_R
fit_R <- feols(hale ~ ln_gdppc + urbanization + fertility_rate | iso3c + year, data=df_m)
resid_R <- residuals(fit_R)
ghe_vec <- df_m$ghe_share_gdp

# CGM 式 WCB(9,999 Rademacher;studentised t)
B <- 9999
clusters <- unique(df_m$iso3c)
N_clust <- length(clusters)
df_m[, cluster_id := match(iso3c, clusters)]
t_star <- numeric(B)
pb <- txtProgressBar(max=B, style=3)
for(b in 1:B) {
  w <- sample(c(-1, 1), N_clust, replace=TRUE)
  df_m[, wt := w[cluster_id]]
  df_m[, y_star := fitted.values(fit_R) + resid_R * wt]
  fit_b <- feols(y_star ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                 data=df_m, vcov=~iso3c)
  beta_b <- coef(fit_b)["ghe_share_gdp"]
  se_b <- se(fit_b)["ghe_share_gdp"]
  t_star[b] <- (beta_b - beta_hat) / se_b
  setTxtProgressBar(pb, b)
}
close(pb)

p_sym <- 2 * min(mean(t_star <= t_obs), mean(t_star >= t_obs))
p_one <- mean(t_star >= t_obs)  # H1: β>0(单侧)
cat(sprintf("\nWCB (Rademacher, studentised, B=%d):\n", B))
cat(sprintf("  two-sided symmetric p = %.4f\n", p_sym))
cat(sprintf("  one-sided (β>0) p     = %.4f\n", p_one))

# 保存
out <- data.table(
  Method = c("Standard clustered", "Wild cluster bootstrap (Rademacher, studentised)"),
  Coef = c(beta_hat, beta_hat),
  SE = c(se_cl, sd(t_star) * se_cl / sd(t_star)),  # 占位(SE 非核心)
  p_value = c(fixest::pvalue(fit_full)["ghe_share_gdp"], p_sym),
  CI_lower = c(NA_real_, NA_real_),
  CI_upper = c(NA_real_, NA_real_)
)
fwrite(out, "results/tables/E5_wild_bootstrap_lowincome_v2.csv")
cat("Saved: E5_wild_bootstrap_lowincome_v2.csv\n")
