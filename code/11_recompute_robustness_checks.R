#!/usr/bin/env Rscript
# 11_recompute_robustness_checks.R
# Recompute population-weighted TWFE and GHE x income-group joint test
# (Results "Income-group heterogeneity" / Methods Layer 5)
# Same data and variable construction as 01_main_analysis.R
suppressMessages({
  library(fixest); library(data.table)
})

df <- fread("/Users/taozhu/my researches/lancet_financial_v3/data/processed/integrated_panel_final.csv")

# Same filters as 01_main_analysis.R
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]
df[, income_base := .SD[year==min(year), income[1]], by=iso3c]
df <- df[!is.na(urbanization) & !is.na(fertility_rate) & !is.na(ln_gdppc) & !is.na(ghe_share_gdp) & !is.na(hale)]
cat("Complete-case rows:", nrow(df), "\n")

# (1) Population-weighted TWFE
m_w <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
             data = df, weights = ~population, cluster = ~iso3c)
cat(sprintf("Population-weighted TWFE: coef=%.4f SE=%.4f p=%.4f N=%d\n",
            coef(m_w)["ghe_share_gdp"], se(m_w)["ghe_share_gdp"],
            pvalue(m_w)["ghe_share_gdp"], m_w$nobs))

# (2) GHE x income-group interaction + Wald joint test
df[, income_base := factor(income_base, levels = c("Low income","Lower middle income","Upper middle income","High income"))]
m_i <- feols(hale ~ ghe_share_gdp * income_base + ln_gdppc + urbanization + fertility_rate | iso3c + year,
             data = df, cluster = ~iso3c)
w <- wald(m_i, keep = "ghe_share_gdp:income_base")
cat(sprintf("Joint test: stat=%.4f p=%.4f df1=%d df2=%d\n", w$stat, w$p, w$df1, w$df2))

# Save outputs for the manuscript record
out <- data.table(
  check = c("population_weighted_twfe", "joint_test_income_interactions"),
  coef = c(coef(m_w)["ghe_share_gdp"], NA),
  se = c(se(m_w)["ghe_share_gdp"], NA),
  p = c(pvalue(m_w)["ghe_share_gdp"], w$p),
  stat = c(NA, w$stat),
  n = c(m_w$nobs, m_i$nobs)
)
fwrite(out, "results/tables/robustness_checks_recomputed.csv")
cat("Saved: results/tables/robustness_checks_recomputed.csv\n")
