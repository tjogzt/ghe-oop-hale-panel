# ============================================================================
# B4_precovid_robustness.R
# Re-run ALL primary models on 2000-2019 data (exclude 2020-2023)
# Report as robustness table
# ============================================================================

set.seed(49)
options(scipen=999, warn=1)

pkgs <- c("data.table","fixest","ggplot2")
for(p in pkgs) if(!requireNamespace(p,quietly=TRUE)) install.packages(p,repos="https://cloud.r-project.org")
invisible(lapply(pkgs,library,character.only=TRUE))
pvalue <- fixest::pvalue

PROJ <- "/Users/taozhu/my researches/lancet_financial_v3"
setwd(PROJ)
dir.create("results/tables", recursive=TRUE, showWarnings=FALSE)
dir.create("results/figures", recursive=TRUE, showWarnings=FALSE)

PAL <- c(zhusha="#C23531", shiqing="#3D6BA8", yanzhi="#9D2933", dianqing="#177CB0")
theme_pub <- theme_bw(base_size=8) +
  theme(panel.grid.minor=element_blank(),
        plot.title=element_text(face="bold",size=9),
        axis.title=element_text(size=8), axis.text=element_text(size=7))

cat("========================================================\n")
cat("B4: Pre-COVID Only (2000-2019) — Full Model Replication\n")
cat("========================================================\n")

# ---- Load ----
df <- fread("/Users/taozhu/my researches/lancet_financial_v3/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]

# Restrict to pre-COVID
df_pre <- df[year <= 2019]
df_pre_a <- df_pre[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]

cat(sprintf("Full sample (2000-2023): %d rows\n", nrow(df[!is.na(hale) & !is.na(ghe_share_gdp)])))
cat(sprintf("Pre-COVID sample (2000-2019): %d rows, %d countries\n",
            nrow(df_pre_a), uniqueN(df_pre_a$iso3c)))

# ---- 1. PRIMARY TWFE ----
cat("\n--- 1. Primary TWFE (pre-COVID) ---\n")

m1 <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
            data=df_pre_a, vcov=~iso3c)
cat(sprintf("TWFE (pre-COVID): GHE=%.4f (SE=%.4f, p=%.4f), N=%d\n",
            coef(m1)["ghe_share_gdp"], se(m1)["ghe_share_gdp"], pvalue(m1)["ghe_share_gdp"], nobs(m1)))

# For comparison, full sample
df_full_a <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]
m1_full <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                 data=df_full_a, vcov=~iso3c)

# ---- 2. TWFE + GOVERNANCE ----
cat("\n--- 2. TWFE + Governance (pre-COVID) ---\n")
df_pre_gov <- df_pre_a[!is.na(governance_composite)]
m2 <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate + governance_composite | iso3c + year,
            data=df_pre_gov, vcov=~iso3c)
cat(sprintf("TWFE+Gov (pre-COVID): GHE=%.4f (SE=%.4f, p=%.4f)\n",
            coef(m2)["ghe_share_gdp"], se(m2)["ghe_share_gdp"], pvalue(m2)["ghe_share_gdp"]))

# ---- 3. POOLED OLS (FULL COVARIATES) ----
cat("\n--- 3. Pooled OLS (pre-COVID) ---\n")

m3_pooled <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate,
                   data=df_pre_a, vcov="hetero")
cat(sprintf("Pooled OLS (pre-COVID): GHE=%.4f (SE=%.4f, p=%.4f)\n",
            coef(m3_pooled)["ghe_share_gdp"], se(m3_pooled)["ghe_share_gdp"],
            pvalue(m3_pooled)["ghe_share_gdp"]))

# Raw pooled OLS
m3_raw <- feols(hale ~ ghe_share_gdp, data=df_pre_a, vcov="hetero")
cat(sprintf("Raw Pooled OLS (pre-COVID): GHE=%.4f (p=%.4f)\n",
            coef(m3_raw)["ghe_share_gdp"], pvalue(m3_raw)["ghe_share_gdp"]))

# ---- 4. LONG DIFFERENCE (pre-COVID) ----
cat("\n--- 4. Long Difference (pre-COVID) ---\n")

setorder(df_pre_a, iso3c, year)
first_yr <- df_pre_a[, .SD[1], by=iso3c]
last_yr <- df_pre_a[, .SD[.N], by=iso3c]
ld_pre <- merge(first_yr[, .(iso3c,country,income,hale_0=hale,ghe_0=ghe_share_gdp,gdppc_0=ln_gdppc,year_0=year)],
                last_yr[, .(iso3c,hale_T=hale,ghe_T=ghe_share_gdp,gdppc_T=ln_gdppc,year_T=year)],
                by="iso3c")
ld_pre[, `:=`(d_hale=hale_T-hale_0, d_ghe=ghe_T-ghe_0, d_gdppc=gdppc_T-gdppc_0, span=year_T-year_0)]
ld_pre <- ld_pre[span >= 10]

ld_fit_pre <- lm(d_hale ~ d_ghe + d_gdppc, data=ld_pre)
cat(sprintf("Long-diff (pre-COVID): d_GHE=%.4f (p=%.4f), N=%d\n",
            coef(ld_fit_pre)["d_ghe"],
            summary(ld_fit_pre)$coefficients["d_ghe","Pr(>|t|)"], nrow(ld_pre)))

# Full sample long-diff for comparison
setorder(df_full_a, iso3c, year)
first_full <- df_full_a[, .SD[1], by=iso3c]
last_full <- df_full_a[, .SD[.N], by=iso3c]
ld_full <- merge(first_full[, .(iso3c,hale_0=hale,ghe_0=ghe_share_gdp,gdppc_0=ln_gdppc,y0=year)],
                 last_full[, .(iso3c,hale_T=hale,ghe_T=ghe_share_gdp,gdppc_T=ln_gdppc,yT=year)], by="iso3c")
ld_full[, `:=`(d_hale=hale_T-hale_0, d_ghe=ghe_T-ghe_0, d_gdppc=gdppc_T-gdppc_0, span=yT-y0)]
ld_full <- ld_full[span >= 12]
ld_fit_full <- lm(d_hale ~ d_ghe + d_gdppc, data=ld_full)

# ---- 5. INCOME HETEROGENEITY (pre-COVID) ----
cat("\n--- 5. Income Heterogeneity (pre-COVID) ---\n")

df_pre_a[, income_base := .SD[year==min(year), income[1]], by=iso3c]
income_pre <- data.table()

for(ig in c("Low income","Lower middle income","Upper middle income","High income")) {
  sub <- df_pre_a[income_base == ig]
  if(nrow(sub) > 100) {
    fit <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                 data=sub, vcov=~iso3c)
    income_pre <- rbind(income_pre, data.table(
      income_group=ig, ghe_coef=coef(fit)["ghe_share_gdp"],
      ghe_se=se(fit)["ghe_share_gdp"], ghe_p=pvalue(fit)["ghe_share_gdp"], N=nobs(fit)))
  }
}
cat("Income heterogeneity (pre-COVID):\n")
print(income_pre)

# ---- 6. MEDIATION (pre-COVID) ----
cat("\n--- 6. Mediation (pre-COVID) ---\n")

df_pre_med <- df_pre_a[!is.na(oop_expenditure)]
df_pre_med[, ln_oop := log(oop_expenditure + 0.01)]

# Path A
path_a <- feols(ln_oop ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                data=df_pre_med, vcov=~iso3c)
cat(sprintf("Path A (GHE→OOP): %.4f (p=%.4f)\n",
            coef(path_a)["ghe_share_gdp"], pvalue(path_a)["ghe_share_gdp"]))

# Total effect
total_pre <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                   data=df_pre_med, vcov=~iso3c)

# Direct effect
direct_pre <- feols(hale ~ ghe_share_gdp + ln_oop + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                    data=df_pre_med, vcov=~iso3c)

cat(sprintf("Total effect: %.4f (p=%.4f)\n",
            coef(total_pre)["ghe_share_gdp"], pvalue(total_pre)["ghe_share_gdp"]))
cat(sprintf("Direct effect (+OOP): %.4f (p=%.4f)\n",
            coef(direct_pre)["ghe_share_gdp"], pvalue(direct_pre)["ghe_share_gdp"]))
cat(sprintf("Indirect (via OOP): %.4f\n",
            coef(total_pre)["ghe_share_gdp"] - coef(direct_pre)["ghe_share_gdp"]))

# ---- 7. COMPARISON TABLE: Full vs Pre-COVID ----
cat("\n--- 7. Comparison Table: Full Sample vs Pre-COVID ---\n")

comparison <- data.table(
  Model = c("Pooled OLS (raw)","Pooled OLS (full controls)","TWFE (primary)",
            "TWFE + governance","Long-difference","Low income","Lower-middle income",
            "Upper-middle income","High income","Mediation: Path A","Mediation: Total",
            "Mediation: Direct","Mediation: Indirect"),
  Full_coef = c(
    coef(m3_raw)["ghe_share_gdp"], NA, coef(m1_full)["ghe_share_gdp"],
    NA, coef(ld_fit_full)["d_ghe"],
    NA, NA, NA, NA, NA, NA, NA, NA
  ),
  Full_p = rep(NA_real_, 13),
  PreCOVID_coef = c(
    coef(m3_raw)["ghe_share_gdp"], coef(m3_pooled)["ghe_share_gdp"], coef(m1)["ghe_share_gdp"],
    coef(m2)["ghe_share_gdp"], coef(ld_fit_pre)["d_ghe"],
    income_pre[income_group=="Low income", ghe_coef],
    income_pre[income_group=="Lower middle income", ghe_coef],
    income_pre[income_group=="Upper middle income", ghe_coef],
    income_pre[income_group=="High income", ghe_coef],
    coef(path_a)["ghe_share_gdp"],
    coef(total_pre)["ghe_share_gdp"],
    coef(direct_pre)["ghe_share_gdp"],
    coef(total_pre)["ghe_share_gdp"] - coef(direct_pre)["ghe_share_gdp"]
  ),
  PreCOVID_se = c(
    se(m3_raw)["ghe_share_gdp"], se(m3_pooled)["ghe_share_gdp"], se(m1)["ghe_share_gdp"],
    se(m2)["ghe_share_gdp"],
    summary(ld_fit_pre)$coefficients["d_ghe","Std. Error"],
    income_pre[income_group=="Low income", ghe_se],
    income_pre[income_group=="Lower middle income", ghe_se],
    income_pre[income_group=="Upper middle income", ghe_se],
    income_pre[income_group=="High income", ghe_se],
    se(path_a)["ghe_share_gdp"],
    se(total_pre)["ghe_share_gdp"],
    se(direct_pre)["ghe_share_gdp"],
    NA
  ),
  PreCOVID_p = c(
    pvalue(m3_raw)["ghe_share_gdp"], pvalue(m3_pooled)["ghe_share_gdp"], pvalue(m1)["ghe_share_gdp"],
    pvalue(m2)["ghe_share_gdp"],
    summary(ld_fit_pre)$coefficients["d_ghe","Pr(>|t|)"],
    income_pre[income_group=="Low income", ghe_p],
    income_pre[income_group=="Lower middle income", ghe_p],
    income_pre[income_group=="Upper middle income", ghe_p],
    income_pre[income_group=="High income", ghe_p],
    pvalue(path_a)["ghe_share_gdp"],
    pvalue(total_pre)["ghe_share_gdp"],
    pvalue(direct_pre)["ghe_share_gdp"],
    NA
  ),
  PreCOVID_N = c(
    nobs(m3_raw), nobs(m3_pooled), nobs(m1),
    nobs(m2), nrow(ld_pre),
    income_pre[income_group=="Low income", N],
    income_pre[income_group=="Lower middle income", N],
    income_pre[income_group=="Upper middle income", N],
    income_pre[income_group=="High income", N],
    nobs(path_a), nobs(total_pre), nobs(direct_pre), NA
  )
)

cat("\nFull comparison:\n")
print(comparison)

# ---- 8. SAVE ----
fwrite(comparison, "results/tables/B4_precovid_comparison.csv")
fwrite(income_pre, "results/tables/B4_income_precovid.csv")
cat("Saved: results/tables/B4_precovid_comparison.csv\n")
cat("Saved: results/tables/B4_income_precovid.csv\n")

cat("\n=== B4 Complete ===\n")
