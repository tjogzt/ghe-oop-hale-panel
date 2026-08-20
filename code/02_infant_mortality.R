# ============================================================================
# 02_infant_mortality.R — 替代结局：婴儿死亡率(IMR)
# 数据：wb_global_health_data.csv + integrated_panel_final.csv 合并
# ============================================================================

set.seed(49)
options(scipen=999, warn=1)

pkgs <- c("data.table","fixest","ggplot2")
for(p in pkgs) if(!requireNamespace(p,quietly=TRUE)) install.packages(p,repos="https://cloud.r-project.org")
invisible(lapply(pkgs,library,character.only=TRUE))
pvalue <- fixest::pvalue

PROJ <- "/Users/taozhu/my researches/lancet_financial_v3"
setwd(PROJ)

PAL <- c(zhusha="#C23531", shiqing="#3D6BA8", yanzhi="#9D2933", dianqing="#177CB0")
INC_COL <- c("Low income"="#9D2933","Lower middle income"="#C23531",
             "Upper middle income"="#177CB0","High income"="#3D6BA8")
theme_pub <- theme_bw(base_size=8) +
  theme(panel.grid.minor=element_blank(),
        legend.key.size=unit(0.35,"cm"),
        plot.title=element_text(face="bold",size=9),
        axis.title=element_text(size=8),
        axis.text=element_text(size=7))

# ---- Load & Merge ----
cat("=== Loading Data ===\n")
df_main <- fread("/Volumes/tjogzt4T/lancet_financial_v2/data/processed/integrated_panel_final.csv")
df_imr  <- fread("/Volumes/tjogzt4T/lancet_financial_v2/data/raw/wb_global_health_data.csv")

# Rename for clarity: SP.DYN.IMRT.IN = infant mortality (per 1000 live births)
setnames(df_imr, "SP.DYN.IMRT.IN", "imr")
setnames(df_imr, "SP.DYN.LE00.IN", "life_exp_wdi")
setnames(df_imr, "NY.GDP.PCAP.CD", "gdp_pc_current")

cat(sprintf("Main panel: %d rows, IMR data: %d rows\n", nrow(df_main), nrow(df_imr)))

# Merge on iso3c + year
df <- merge(df_main, df_imr[, .(iso3c, year, imr, life_exp_wdi, gdp_pc_current)], 
            by=c("iso3c","year"), all.x=TRUE)

# Filter aggregates
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]
df[, ln_imr := log(imr)]  # log-transform IMR for normality

cat(sprintf("After merge+filter: %d rows, %d countries\n", nrow(df), uniqueN(df$iso3c)))
cat(sprintf("IMR available: %d (%.1f%%)\n", sum(!is.na(df$imr)), 100*sum(!is.na(df$imr))/nrow(df)))

# ---- Analysis: IMR as outcome ----
cat("\n=== IMR Analysis ===\n")

# Model 1: Pooled OLS on log-IMR
m1_imr <- feols(ln_imr ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate,
                data=df[!is.na(imr)], vcov="hetero")
cat(sprintf("M1 Pooled OLS (log IMR):    GHE=%.4f (p=%.3f)\n",
            coef(m1_imr)["ghe_share_gdp"], pvalue(m1_imr)["ghe_share_gdp"]))

# Model 2: TWFE on log-IMR
m2_imr <- feols(ln_imr ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                data=df[!is.na(imr)], vcov=~iso3c)
cat(sprintf("M2 TWFE (log IMR):          GHE=%.4f (p=%.3f)\n",
            coef(m2_imr)["ghe_share_gdp"], pvalue(m2_imr)["ghe_share_gdp"]))

# Model 3: Compare HALE vs IMR in same sample
df_both <- df[!is.na(hale) & !is.na(imr) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]

# HALE in this sample
m3_hale <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                 data=df_both, vcov=~iso3c)
cat(sprintf("M3 TWFE (HALE, same sample): GHE=%.4f (p=%.3f), N=%d\n",
            coef(m3_hale)["ghe_share_gdp"], pvalue(m3_hale)["ghe_share_gdp"], nobs(m3_hale)))

# IMR in this sample (log)
m3_imr <- feols(ln_imr ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                data=df_both, vcov=~iso3c)
cat(sprintf("M3 TWFE (log IMR, same samp): GHE=%.4f (p=%.3f), N=%d\n",
            coef(m3_imr)["ghe_share_gdp"], pvalue(m3_imr)["ghe_share_gdp"], nobs(m3_imr)))

# ---- Heterogeneity: IMR by income group ----
cat("\n=== IMR Income Heterogeneity ===\n")
df_both[, income_base := .SD[year==min(year), income[1]], by=iso3c]
for(ig in c("Low income","Lower middle income","Upper middle income","High income")) {
  sub <- df_both[income_base == ig]
  if(nrow(sub) > 100) {
    fit <- feols(ln_imr ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                 data=sub, vcov=~iso3c)
    cat(sprintf("  %-22s: GHE=%.4f (SE=%.4f, p=%.3f), N=%d\n", 
                ig, coef(fit)["ghe_share_gdp"], se(fit)["ghe_share_gdp"],
                pvalue(fit)["ghe_share_gdp"], nobs(fit)))
  }
}

# ---- Long Difference: IMR ----
setorder(df_both, iso3c, year)
first_yr <- df_both[!is.na(imr), .SD[1], by=iso3c]
last_yr  <- df_both[!is.na(imr), .SD[.N], by=iso3c]
ld_imr <- merge(first_yr[, .(iso3c,country,income,imr_0=imr,ghe_0=ghe_share_gdp,year_0=year)],
                last_yr[, .(iso3c,imr_T=imr,ghe_T=ghe_share_gdp,year_T=year)],
                by="iso3c")
ld_imr[, `:=`(d_imr=imr_T-imr_0, d_ghe=ghe_T-ghe_0, span=year_T-year_0)]
ld_imr <- ld_imr[span>=15]
cat(sprintf("\nLong-diff IMR (N=%d): corr(d_GHE,d_IMR)=%.3f\n", nrow(ld_imr),
            cor(ld_imr$d_ghe, ld_imr$d_imr)))

# ---- Figure: Head-to-head HALE vs IMR comparison ----
# Extract coefficients
hale_coef <- coef(m3_hale)["ghe_share_gdp"]; hale_se <- se(m3_hale)["ghe_share_gdp"]
imr_coef  <- coef(m3_imr)["ghe_share_gdp"];  imr_se  <- se(m3_imr)["ghe_share_gdp"]

comp_dt <- data.table(
  Outcome = c("HALE (years)", "log(IMR)"),
  Coef = c(hale_coef, imr_coef),
  SE = c(hale_se, imr_se)
)
comp_dt[, `:=`(ci_low=Coef-1.96*SE, ci_high=Coef+1.96*SE)]

cat(sprintf("\n=== Head-to-Head Comparison (same sample, N=%d) ===\n", nobs(m3_hale)))
cat(sprintf("HALE:      GHE coef=%.4f (SE=%.4f, p=%.3f)\n", hale_coef, hale_se, pvalue(m3_hale)["ghe_share_gdp"]))
cat(sprintf("log(IMR):  GHE coef=%.4f (SE=%.4f, p=%.3f)\n", imr_coef, imr_se, pvalue(m3_imr)["ghe_share_gdp"]))
cat(sprintf("Interpretation: negative GHE→IMR would mean more spending = less mortality.\n"))

# Save results
fwrite(data.table(
  Model=c("Pooled_OLS_logIMR","TWFE_logIMR","TWFE_HALE_same","TWFE_logIMR_same"),
  Coef=c(coef(m1_imr)["ghe_share_gdp"],coef(m2_imr)["ghe_share_gdp"],
         coef(m3_hale)["ghe_share_gdp"],coef(m3_imr)["ghe_share_gdp"]),
  SE=c(se(m1_imr)["ghe_share_gdp"],se(m2_imr)["ghe_share_gdp"],
       se(m3_hale)["ghe_share_gdp"],se(m3_imr)["ghe_share_gdp"]),
  P=c(pvalue(m1_imr)["ghe_share_gdp"],pvalue(m2_imr)["ghe_share_gdp"],
      pvalue(m3_hale)["ghe_share_gdp"],pvalue(m3_imr)["ghe_share_gdp"]),
  N=c(nobs(m1_imr),nobs(m2_imr),nobs(m3_hale),nobs(m3_imr))
), "results/tables/imr_results.csv")

cat("\n=== Complete ===\n")
