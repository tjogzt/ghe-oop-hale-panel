# ============================================================================
# C4_horse_race.R
# "Horse Race" Model: benchmark GHE against other determinants
# Standardized coefficients (beta weights) to compare magnitude
# Which factor matters most for HALE within countries?
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
theme_pub <- theme_bw(base_size=10) +
  theme(panel.grid.minor=element_blank(),
        plot.title=element_text(face="bold",size=9),
        axis.title=element_text(size=8), axis.text=element_text(size=9))

cat("========================================================\n")
cat("C4: Horse Race — Standardized Coefficients\n")
cat("========================================================\n")

# ---- Load ----
df <- fread("/Users/taozhu/my researches/lancet_financial_v3/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]

# ---- 1. Prepare Standardized Variables ----
# Standardize within full sample for beta-weight regression
df[, `:=`(
  hale_z = (hale - mean(hale, na.rm=TRUE)) / sd(hale, na.rm=TRUE),
  ghe_z = (ghe_share_gdp - mean(ghe_share_gdp, na.rm=TRUE)) / sd(ghe_share_gdp, na.rm=TRUE),
  gdppc_z = (ln_gdppc - mean(ln_gdppc, na.rm=TRUE)) / sd(ln_gdppc, na.rm=TRUE),
  urban_z = (urbanization - mean(urbanization, na.rm=TRUE)) / sd(urbanization, na.rm=TRUE),
  fertility_z = (fertility_rate - mean(fertility_rate, na.rm=TRUE)) / sd(fertility_rate, na.rm=TRUE),
  gov_z = (governance_composite - mean(governance_composite, na.rm=TRUE)) / sd(governance_composite, na.rm=TRUE),
  tax_z = (tax_revenue_gdp - mean(tax_revenue_gdp, na.rm=TRUE)) / sd(tax_revenue_gdp, na.rm=TRUE)
)]

df_a <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]
cat(sprintf("Analytical sample: %d rows, %d countries\n", nrow(df_a), uniqueN(df_a$iso3c)))

# ---- 2. Pooled OLS — Full Horse Race ----
cat("\n--- 2. Pooled OLS: All Determinants ---\n")

hr_pooled <- feols(hale_z ~ ghe_z + gdppc_z + urban_z + fertility_z + gov_z,
                   data=df_a[!is.na(governance_composite)], vcov="hetero")
cat("Pooled OLS (standardized):\n")
cat(sprintf("  GHE:         β=%.4f (SE=%.4f, p=%.4f)\n",
            coef(hr_pooled)["ghe_z"], se(hr_pooled)["ghe_z"], pvalue(hr_pooled)["ghe_z"]))
cat(sprintf("  GDP pc:      β=%.4f (SE=%.4f, p=%.4f)\n",
            coef(hr_pooled)["gdppc_z"], se(hr_pooled)["gdppc_z"], pvalue(hr_pooled)["gdppc_z"]))
cat(sprintf("  Urbanization: β=%.4f (SE=%.4f, p=%.4f)\n",
            coef(hr_pooled)["urban_z"], se(hr_pooled)["urban_z"], pvalue(hr_pooled)["urban_z"]))
cat(sprintf("  Fertility:    β=%.4f (SE=%.4f, p=%.4f)\n",
            coef(hr_pooled)["fertility_z"], se(hr_pooled)["fertility_z"], pvalue(hr_pooled)["fertility_z"]))
cat(sprintf("  Governance:   β=%.4f (SE=%.4f, p=%.4f)\n",
            coef(hr_pooled)["gov_z"], se(hr_pooled)["gov_z"], pvalue(hr_pooled)["gov_z"]))

# ---- 3. TWFE — Within-Country Horse Race ----
cat("\n--- 3. TWFE: Within-Country Determinants ---\n")

hr_twfe <- feols(hale_z ~ ghe_z + gdppc_z + urban_z + fertility_z + gov_z | iso3c + year,
                 data=df_a[!is.na(governance_composite)], vcov=~iso3c)
cat("TWFE (standardized, within-country):\n")
cat(sprintf("  GHE:         β=%.4f (SE=%.4f, p=%.4f)\n",
            coef(hr_twfe)["ghe_z"], se(hr_twfe)["ghe_z"], pvalue(hr_twfe)["ghe_z"]))
cat(sprintf("  GDP pc:      β=%.4f (SE=%.4f, p=%.4f)\n",
            coef(hr_twfe)["gdppc_z"], se(hr_twfe)["gdppc_z"], pvalue(hr_twfe)["gdppc_z"]))
cat(sprintf("  Urbanization: β=%.4f (SE=%.4f, p=%.4f)\n",
            coef(hr_twfe)["urban_z"], se(hr_twfe)["urban_z"], pvalue(hr_twfe)["urban_z"]))
cat(sprintf("  Fertility:    β=%.4f (SE=%.4f, p=%.4f)\n",
            coef(hr_twfe)["fertility_z"], se(hr_twfe)["fertility_z"], pvalue(hr_twfe)["fertility_z"]))
cat(sprintf("  Governance:   β=%.4f (SE=%.4f, p=%.4f)\n",
            coef(hr_twfe)["gov_z"], se(hr_twfe)["gov_z"], pvalue(hr_twfe)["gov_z"]))

# ---- 4. TWFE without Governance (no over-control) ----
hr_twfe2 <- feols(hale_z ~ ghe_z + gdppc_z + urban_z + fertility_z | iso3c + year,
                  data=df_a, vcov=~iso3c)
cat("\nTWFE without governance:\n")
cat(sprintf("  GHE:         β=%.4f (SE=%.4f, p=%.4f)\n",
            coef(hr_twfe2)["ghe_z"], se(hr_twfe2)["ghe_z"], pvalue(hr_twfe2)["ghe_z"]))
cat(sprintf("  GDP pc:      β=%.4f (SE=%.4f, p=%.4f)\n",
            coef(hr_twfe2)["gdppc_z"], se(hr_twfe2)["gdppc_z"], pvalue(hr_twfe2)["gdppc_z"]))
cat(sprintf("  Urbanization: β=%.4f (SE=%.4f, p=%.4f)\n",
            coef(hr_twfe2)["urban_z"], se(hr_twfe2)["urban_z"], pvalue(hr_twfe2)["urban_z"]))
cat(sprintf("  Fertility:    β=%.4f (SE=%.4f, p=%.4f)\n",
            coef(hr_twfe2)["fertility_z"], se(hr_twfe2)["fertility_z"], pvalue(hr_twfe2)["fertility_z"]))

# ---- 5. Income-Stratified Horse Race ----
cat("\n--- 5. Income-Stratified Horse Race (TWFE) ---\n")

df_a[, income_base := .SD[year==min(year), income[1]], by=iso3c]
hr_income <- data.table()

for(ig in c("Low income","Lower middle income","Upper middle income","High income")) {
  sub <- df_a[income_base == ig]
  if(nrow(sub) > 100) {
    fit <- feols(hale_z ~ ghe_z + gdppc_z + urban_z + fertility_z | iso3c + year,
                 data=sub, vcov=~iso3c)
    hr_income <- rbind(hr_income,
      data.table(income_group=ig, var="GHE", coef=coef(fit)["ghe_z"], se=se(fit)["ghe_z"],
                 p=pvalue(fit)["ghe_z"]),
      data.table(income_group=ig, var="GDP pc", coef=coef(fit)["gdppc_z"], se=se(fit)["gdppc_z"],
                 p=pvalue(fit)["gdppc_z"]),
      data.table(income_group=ig, var="Urban", coef=coef(fit)["urban_z"], se=se(fit)["urban_z"],
                 p=pvalue(fit)["urban_z"]),
      data.table(income_group=ig, var="Fertility", coef=coef(fit)["fertility_z"], se=se(fit)["fertility_z"],
                 p=pvalue(fit)["fertility_z"])
    )
  }
}

cat("\nIncome-stratified standardized coefficients:\n")
print(hr_income)

# ---- 6. R-squared Decomposition ----
cat("\n--- 6. R-squared Decomposition ---\n")

# Unique R2 contributions (governance-complete sample, matching the reported model)
df_a_cc <- df_a[!is.na(governance_composite)]
# GHE only
r2_ghe <- feols(hale_z ~ ghe_z | iso3c + year, data=df_a_cc, vcov=~iso3c)
# Full
r2_full <- feols(hale_z ~ ghe_z + gdppc_z + urban_z + fertility_z + gov_z | iso3c + year, data=df_a_cc, vcov=~iso3c)
# Without GHE
r2_others <- feols(hale_z ~ gdppc_z + urban_z + fertility_z + gov_z | iso3c + year, data=df_a_cc, vcov=~iso3c)

cat(sprintf("Within R² (GHE only):     %.4f\n", r2(r2_ghe, "wr2")))
cat(sprintf("Within R² (all vars):     %.4f\n", r2(r2_full, "wr2")))
cat(sprintf("Within R² (without GHE):  %.4f\n", r2(r2_others, "wr2")))
cat(sprintf("GHE unique contribution:  %.4f\n", r2(r2_full, "wr2") - r2(r2_others, "wr2")))

# ---- 7. Figure: Horse Race Coefficient Comparison ----
cat("\n--- 7. Figure ---\n")

# Main TWFE standardized coefficients
horse_data <- data.table(
  Variable = c("GHE","GDP per capita","Urbanization","Fertility","Governance"),
  Coef = c(coef(hr_twfe)["ghe_z"], coef(hr_twfe)["gdppc_z"],
           coef(hr_twfe)["urban_z"], coef(hr_twfe)["fertility_z"],
           coef(hr_twfe)["gov_z"]),
  SE = c(se(hr_twfe)["ghe_z"], se(hr_twfe)["gdppc_z"],
         se(hr_twfe)["urban_z"], se(hr_twfe)["fertility_z"],
         se(hr_twfe)["gov_z"]),
  P = c(pvalue(hr_twfe)["ghe_z"], pvalue(hr_twfe)["gdppc_z"],
        pvalue(hr_twfe)["urban_z"], pvalue(hr_twfe)["fertility_z"],
        pvalue(hr_twfe)["gov_z"])
)
horse_data[, `:=`(ci_low=Coef-1.96*SE, ci_high=Coef+1.96*SE)]
horse_data[, sig := ifelse(P<0.01, "p<0.01", ifelse(P<0.05, "p<0.05", ifelse(P<0.10, "p<0.10", "n.s.")))]
horse_data[, Variable := factor(Variable, levels=rev(Variable))]

p_horse <- ggplot(horse_data, aes(x=Coef, y=Variable)) +
  geom_vline(xintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_point(aes(color=sig), size=4) +
  geom_errorbarh(aes(xmin=ci_low, xmax=ci_high, color=sig), height=0.3, linewidth=1.2) +
  scale_color_manual(values=c("p<0.01"=PAL["yanzhi"],"p<0.05"=PAL["zhusha"],
                               "p<0.10"=PAL["dianqing"],"n.s."="grey60")) +
  labs(x="Standardized Coefficient (β)", y="",
       title="C4: Horse Race — Which Factor Matters Most for HALE?",
       subtitle="Standardized coefficients from TWFE model | Within-country variation only",
       color="") +
  theme_pub

ggsave("results/figures/C4_horse_race_china_alt.pdf", p_horse, width=7, height=4, device=cairo_pdf)
cat("Saved: results/figures/C4_horse_race_china_alt.pdf (alt; primary figure from 14_unified_figures.R)\n")

# Income-stratified heat map
hr_income[, income_group := factor(income_group, levels=c("Low income","Lower middle income","Upper middle income","High income"))]
hr_income[, siglab := ifelse(p<0.05, paste0(sprintf("%.3f", coef), "*"),
                      ifelse(p<0.10, paste0(sprintf("%.3f", coef), "†"), sprintf("%.3f", coef)))]
p_income <- ggplot(hr_income, aes(x=var, y=income_group, fill=coef)) +
  geom_tile(color="white", linewidth=0.5) +
  geom_text(aes(label=siglab), size=3) +
  scale_fill_gradient2(low=PAL["zhusha"], mid="white", high=PAL["shiqing"], midpoint=0,
                       limits=c(-0.6, 0.6)) +
  labs(x="", y="", fill="Std. β") +
  theme_pub + theme(axis.text=element_text(size=9))

ggsave("results/figures/figS8_income_std.pdf", p_income, width=170, height=97.1, units="mm", device=cairo_pdf)
cat("Saved: results/figures/figS8_income_std.pdf\n")

# ---- 8. Save Results ----
fwrite(horse_data, "results/tables/C4_horse_race_main.csv")
fwrite(hr_income, "results/tables/C4_horse_race_income.csv")
cat("Saved: results/tables/C4_horse_race_main.csv\n")
cat("Saved: results/tables/C4_horse_race_income.csv\n")

cat("\n=== C4 Complete ===\n")
