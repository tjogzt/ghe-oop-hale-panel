# ============================================================================
# 10_wild_bootstrap_E5.R — Wild cluster bootstrap for low-income subgroup
# ============================================================================
set.seed(49)
options(scipen=999, warn=1)

library(data.table)
library(fixest)
pvalue <- fixest::pvalue

PROJ <- "/Users/taozhu/my researches/lancet_financial_v3"
setwd(PROJ)

# Check if fwildclusterboot is available
has_boot <- requireNamespace("fwildclusterboot", quietly=TRUE)
if(!has_boot) {
  install.packages("fwildclusterboot", repos="https://cloud.r-project.org")
  library(fwildclusterboot)
}
cat("fwildclusterboot loaded:", has_boot || requireNamespace("fwildclusterboot", quietly=TRUE), "\n")

# ---- Load ----
df <- fread("/Volumes/tjogzt4T/lancet_financial_v2/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]
df_a <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]
df_a[, income_base := .SD[year==min(year), income[1]], by=iso3c]

# Low-income subsample
df_low <- df_a[income_base == "Low income"]
cat(sprintf("Low-income: %d obs, %d countries\n", nrow(df_low), uniqueN(df_low$iso3c)))

# Standard TWFE (reference)
fit_low <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                 data=df_low, vcov=~iso3c)
cat(sprintf("\nStandard TWFE (low-income):\n"))
cat(sprintf("  GHE: β=%.4f, SE=%.4f, t=%.3f, p=%.4f\n",
            coef(fit_low)["ghe_share_gdp"], se(fit_low)["ghe_share_gdp"],
            coef(fit_low)["ghe_share_gdp"]/se(fit_low)["ghe_share_gdp"],
            pvalue(fit_low)["ghe_share_gdp"]))

# Wild cluster bootstrap
cat("\nRunning wild cluster bootstrap (B=9999)...\n")
boot_low <- boottest(fit_low, param="ghe_share_gdp", B=9999, clustid="iso3c",
                     type="rademacher", seed=49)

cat(sprintf("\nWild Cluster Bootstrap Results:\n"))
cat(sprintf("  Bootstrap p-value: %.4f\n", boot_low$p_val))
cat(sprintf("  Bootstrap t-stat:  %.3f\n", boot_low$t_stat))
cat(sprintf("  95%% CI: [%.4f, %.4f]\n", boot_low$conf_int[1], boot_low$conf_int[2]))
cat(sprintf("  Standard (clustered) p: %.4f\n", pvalue(fit_low)["ghe_share_gdp"]))
cat(sprintf("  Difference: standard p - bootstrap p = %.4f\n",
            pvalue(fit_low)["ghe_share_gdp"] - boot_low$p_val))

# Also test with WCR (wild cluster restricted) for robustness
boot_wcr <- boottest(fit_low, param="ghe_share_gdp", B=9999, clustid="iso3c",
                     type="rademacher", seed=49, bootcluster="iso3c")

# Save results
fwrite(data.table(
  Method=c("Standard clustered SE","Wild cluster bootstrap (Rademacher)","WCR bootstrap"),
  Coefficient=c(coef(fit_low)["ghe_share_gdp"], coef(fit_low)["ghe_share_gdp"], coef(fit_low)["ghe_share_gdp"]),
  SE=c(se(fit_low)["ghe_share_gdp"], NA, NA),
  p_value=c(pvalue(fit_low)["ghe_share_gdp"], boot_low$p_val, boot_wcr$p_val),
  CI_lower=c(coef(fit_low)["ghe_share_gdp"]-1.96*se(fit_low)["ghe_share_gdp"],
             boot_low$conf_int[1], boot_wcr$conf_int[1]),
  CI_upper=c(coef(fit_low)["ghe_share_gdp"]+1.96*se(fit_low)["ghe_share_gdp"],
             boot_low$conf_int[2], boot_wcr$conf_int[2]),
  N_countries=c(uniqueN(df_low$iso3c), uniqueN(df_low$iso3c), uniqueN(df_low$iso3c)),
  N_obs=c(nrow(df_low), nrow(df_low), nrow(df_low))
), "results/tables/E5_wild_bootstrap_lowincome.csv")

cat("\nSaved: E5_wild_bootstrap_lowincome.csv\n")
cat("\n=== E5 Complete ===\n")
