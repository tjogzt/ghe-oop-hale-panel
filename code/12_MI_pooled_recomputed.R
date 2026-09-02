#!/usr/bin/env Rscript
# 12_MI_pooled_recomputed.R
# Authoritative multiple-imputation pooled estimates (Rubin's rules)
# Replicates the MICE setup of code_pipeline_a/03_prepare_data_and_table1.R
# (m = 20, maxit = 20, predictive mean matching) and pools the primary
# TWFE specification across imputed datasets.
# Output: results/tables/MI_pooled_recomputed.csv (used for Results
# "Robustness" and Supplementary Table S11, Pipeline A)
suppressMessages({ library(fixest); library(data.table); library(mice); library(countrycode) })

df_raw <- fread("/Users/taozhu/my researches/lancet_financial_v3/data/processed/integrated_panel_final.csv")
df_raw[, is_sovereign := !is.na(countrycode(iso3c, "iso3c", "country.name"))]
df <- df_raw[is_sovereign == TRUE]
df <- df[income %in% c("Low income","Lower middle income","Upper middle income","High income")]
df[, ln_gdp_pc := log(gdp_per_capita_ppp)]
df[, income_base := .SD[year==min(year), income[1]], by=iso3c]

all_model_vars <- c("hale","ghe_share_gdp","ln_gdp_pc","urbanization","fertility_rate",
                    "governance_composite","oop_expenditure","tax_revenue_gdp","government_effectiveness")
miss <- sapply(df[, ..all_model_vars], function(x) mean(is.na(x)))
impute_vars <- names(miss[miss > 0 & miss < 0.4])

set.seed(49)
imp <- mice(df[, c("iso3c","year", impute_vars), with=FALSE], m=20, maxit=20, method="pmm", printFlag=FALSE)

fit_once <- function(k, subset_expr = NULL) {
  dk <- as.data.table(complete(imp, k))
  dk[, income_base := df$income_base[match(dk$iso3c, df$iso3c)]]
  if (!is.null(subset_expr)) dk <- dk[eval(parse(text = subset_expr))]
  m <- feols(hale ~ ghe_share_gdp + ln_gdp_pc + urbanization + fertility_rate | iso3c + year,
             data = dk, vcov = ~iso3c)
  c(beta = coef(m)["ghe_share_gdp"], se = se(m)["ghe_share_gdp"])
}
rubin <- function(mat) {
  qbar <- mean(mat[1, ]); ubar <- mean(mat[2, ]^2); b <- var(mat[1, ])
  se <- sqrt(ubar + (1 + 1/ncol(mat)) * b)
  c(beta = qbar, se = se, p = 2 * pnorm(-abs(qbar / se)))
}

r_all <- rubin(sapply(1:20, fit_once))
r_lic <- rubin(sapply(1:20, fit_once, 'income_base=="Low income"'))
cat(sprintf("Pooled TWFE (all):     beta = %.4f (SE = %.4f, p = %.4f)\n", r_all[1], r_all[2], r_all[3]))
cat(sprintf("Pooled TWFE (low-inc): beta = %.4f (SE = %.4f, p = %.4f)\n", r_lic[1], r_lic[2], r_lic[3]))

out <- data.table(metric = c("mi_pooled_twfe_all", "mi_pooled_twfe_lowincome"),
                  beta = c(r_all[1], r_lic[1]), se = c(r_all[2], r_lic[2]), p = c(r_all[3], r_lic[3]))
fwrite(out, "results/tables/MI_pooled_recomputed.csv")
cat("Saved: results/tables/MI_pooled_recomputed.csv\n")
