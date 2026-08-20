# ============================================================================
# 13_DAH_adjustment.R — DAH校正LIC估计
# ============================================================================
set.seed(49)
library(data.table)
library(fixest)
pvalue <- fixest::pvalue

PROJ <- "/Users/taozhu/my researches/lancet_financial_v3"
setwd(PROJ)

# Load main panel
df <- fread("/Volumes/tjogzt4T/lancet_financial_v2/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]
df_a <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]

# Load DAH data
dah <- fread("/Volumes/tjogzt4T/lancet_financial_v2/data/raw/wb_external_health_aid.csv")
dah <- dah[, .(iso3c, year, dah_pct_che = SH.XPD.EHEX.CH.ZS)]

# Merge
df_merged <- merge(df_a, dah, by=c("iso3c","year"), all.x=TRUE)
cat(sprintf("Merged: %d rows, DAH non-missing: %d (%.1f%%)\n",
            nrow(df_merged), sum(!is.na(df_merged$dah_pct_che)),
            100*sum(!is.na(df_merged$dah_pct_che))/nrow(df_merged)))

# Baseline income
df_merged[, income_base := .SD[year==min(year), income[1]], by=iso3c]
df_low <- df_merged[income_base == "Low income"]

# ---- 1. Original LIC estimate (reference) ----
fit_orig <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                  data=df_low, vcov=~iso3c)
cat(sprintf("\nOriginal LIC: β=%.4f, SE=%.4f, p=%.4f\n",
            coef(fit_orig)["ghe_share_gdp"], se(fit_orig)["ghe_share_gdp"],
            pvalue(fit_orig)["ghe_share_gdp"]))

# ---- 2. DAH-adjusted: control for external aid ----
df_low_dah <- df_low[!is.na(dah_pct_che)]
fit_dah <- feols(hale ~ ghe_share_gdp + dah_pct_che + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                 data=df_low_dah, vcov=~iso3c)
cat(sprintf("\nDAH-adjusted LIC: β=%.4f, SE=%.4f, p=%.4f, N=%d\n",
            coef(fit_dah)["ghe_share_gdp"], se(fit_dah)["ghe_share_gdp"],
            pvalue(fit_dah)["ghe_share_gdp"], nobs(fit_dah)))
cat(sprintf("  DAH coef: β=%.4f, p=%.4f\n",
            coef(fit_dah)["dah_pct_che"], pvalue(fit_dah)["dah_pct_che"]))

# ---- 3. LIC excluding Rwanda ----
df_low_noRWA <- df_low[iso3c != "RWA"]
fit_noRWA <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                   data=df_low_noRWA, vcov=~iso3c)
cat(sprintf("\nLIC excluding Rwanda: β=%.4f, SE=%.4f, p=%.4f, G=%d\n",
            coef(fit_noRWA)["ghe_share_gdp"], se(fit_noRWA)["ghe_share_gdp"],
            pvalue(fit_noRWA)["ghe_share_gdp"], uniqueN(df_low_noRWA$iso3c)))

# ---- 4. DAH-adjusted + excluding Rwanda ----
df_low_dah_noRWA <- df_low_dah[iso3c != "RWA"]
fit_dah_noRWA <- feols(hale ~ ghe_share_gdp + dah_pct_che + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                       data=df_low_dah_noRWA, vcov=~iso3c)
cat(sprintf("\nDAH-adjusted LIC excluding Rwanda: β=%.4f, SE=%.4f, p=%.4f, N=%d\n",
            coef(fit_dah_noRWA)["ghe_share_gdp"], se(fit_dah_noRWA)["ghe_share_gdp"],
            pvalue(fit_dah_noRWA)["ghe_share_gdp"], nobs(fit_dah_noRWA)))

# ---- Summary Table ----
summary_dah <- data.table(
  Specification = c("Original LIC","DAH-adjusted","Excl. Rwanda","DAH-adj + Excl. Rwanda"),
  Beta = c(coef(fit_orig)["ghe_share_gdp"], coef(fit_dah)["ghe_share_gdp"],
           coef(fit_noRWA)["ghe_share_gdp"], coef(fit_dah_noRWA)["ghe_share_gdp"]),
  SE = c(se(fit_orig)["ghe_share_gdp"], se(fit_dah)["ghe_share_gdp"],
         se(fit_noRWA)["ghe_share_gdp"], se(fit_dah_noRWA)["ghe_share_gdp"]),
  P = c(pvalue(fit_orig)["ghe_share_gdp"], pvalue(fit_dah)["ghe_share_gdp"],
        pvalue(fit_noRWA)["ghe_share_gdp"], pvalue(fit_dah_noRWA)["ghe_share_gdp"]),
  N = c(nobs(fit_orig), nobs(fit_dah), nobs(fit_noRWA), nobs(fit_dah_noRWA)),
  G = c(uniqueN(df_low$iso3c), uniqueN(df_low_dah$iso3c), 
        uniqueN(df_low_noRWA$iso3c), uniqueN(df_low_dah_noRWA$iso3c))
)
print(summary_dah)
fwrite(summary_dah, "results/tables/DAH_adjusted_LIC.csv")
cat("\nSaved: DAH_adjusted_LIC.csv\n")
