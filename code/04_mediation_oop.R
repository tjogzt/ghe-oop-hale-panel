# ============================================================================
# 04_mediation_oop.R — 机制分析：GHE → OOP → HALE 中介路径
# 假设：政府卫生支出增加→降低自付费用→改善健康结局
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

# ---- Load & Clean ----
cat("=== 1. Data Loading ===\n")
df <- fread("/Users/taozhu/my researches/lancet_financial_v3/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]
df[, ln_oop := log(oop_expenditure + 0.01)]  # log-transform OOP

cat(sprintf("Raw: %d rows, after filter: %d rows\n", nrow(df), 
            nrow(df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)])))
cat(sprintf("OOP available: %d (%.1f%%)\n", sum(!is.na(df$oop_expenditure)),
            100*sum(!is.na(df$oop_expenditure))/nrow(df)))

# Analytical sample: non-missing HALE, GHE, GDP, OOP
df_a <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc) & !is.na(oop_expenditure)]
cat(sprintf("Analytical sample (with OOP): %d rows, %d countries\n", nrow(df_a), uniqueN(df_a$iso3c)))

# ---- Step 1: GHE → OOP (Path A) ----
cat("\n=== 2. Path A: GHE → OOP ===\n")

# Cross-sectional
a1 <- feols(ln_oop ~ ghe_share_gdp + ln_gdppc, data=df_a, vcov="hetero")
cat(sprintf("Pooled OLS: GHE→ln(OOP) = %.4f (p=%.4f)\n", 
            coef(a1)["ghe_share_gdp"], pvalue(a1)["ghe_share_gdp"]))

# TWFE
a2 <- feols(ln_oop ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
            data=df_a, vcov=~iso3c)
cat(sprintf("TWFE:       GHE→ln(OOP) = %.4f (p=%.4f)\n",
            coef(a2)["ghe_share_gdp"], pvalue(a2)["ghe_share_gdp"]))

# By income group
cat("By income:\n")
df_a[, income_base := .SD[year==min(year), income[1]], by=iso3c]
for(ig in c("Low income","Lower middle income","Upper middle income","High income")) {
  sub <- df_a[income_base == ig]
  if(nrow(sub) > 50) {
    fit <- feols(ln_oop ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                 data=sub, vcov=~iso3c)
    cat(sprintf("  %-22s: GHE→ln(OOP) = %.4f (p=%.3f), N=%d\n",
                ig, coef(fit)["ghe_share_gdp"], pvalue(fit)["ghe_share_gdp"], nobs(fit)))
  }
}

# ---- Step 2: OOP → HALE (Path B) ----
cat("\n=== 3. Path B: OOP → HALE ===\n")

b1 <- feols(hale ~ ln_oop + ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
            data=df_a, vcov=~iso3c)
cat(sprintf("TWFE: ln(OOP)→HALE = %.4f (p=%.4f) [controlling for GHE]\n",
            coef(b1)["ln_oop"], pvalue(b1)["ln_oop"]))

# ---- Step 3: Direct vs Indirect (GHE → HALE, with OOP as mediator) ----
cat("\n=== 4. Mediation: Total, Direct, Indirect Effects ===\n")

# Total effect: GHE → HALE (without OOP)
total <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
               data=df_a, vcov=~iso3c)
total_eff <- coef(total)["ghe_share_gdp"]
total_se  <- se(total)["ghe_share_gdp"]
total_p   <- pvalue(total)["ghe_share_gdp"]
cat(sprintf("Total effect (GHE→HALE, no OOP): %.4f (SE=%.4f, p=%.4f), N=%d\n",
            total_eff, total_se, total_p, nobs(total)))

# Direct effect: GHE → HALE (with OOP controlled)
direct <- feols(hale ~ ghe_share_gdp + ln_oop + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                data=df_a, vcov=~iso3c)
direct_eff <- coef(direct)["ghe_share_gdp"]
direct_se  <- se(direct)["ghe_share_gdp"]
direct_p   <- pvalue(direct)["ghe_share_gdp"]
cat(sprintf("Direct effect (GHE→HALE, +OOP):    %.4f (SE=%.4f, p=%.4f), N=%d\n",
            direct_eff, direct_se, direct_p, nobs(direct)))

# Indirect effect (via OOP) = total - direct
indirect_eff <- total_eff - direct_eff
cat(sprintf("Indirect effect (via OOP):           %.4f\n", indirect_eff))
cat(sprintf("Mediation proportion:                %.1f%%\n", 100*indirect_eff/total_eff))

# ---- OOP also as outcome ----
cat("\n=== 5. OOP as Alternative Outcome ===\n")
oop_out <- feols(oop_expenditure ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                 data=df_a, vcov=~iso3c)
cat(sprintf("TWFE: GHE→OOP(level) = %.4f (p=%.4f)\n",
            coef(oop_out)["ghe_share_gdp"], pvalue(oop_out)["ghe_share_gdp"]))

# ---- Table: Path coefficients ----
cat("\n=== 6. Summary Table ===\n")
mediation_summary <- data.table(
  Pathway = c("A: GHE→OOP","B: OOP→HALE","Total: GHE→HALE","Direct: GHE→HALE|OOP","Indirect: via OOP","OOP as outcome"),
  Coefficient = c(coef(a2)["ghe_share_gdp"], coef(b1)["ln_oop"], total_eff, direct_eff, indirect_eff, coef(oop_out)["ghe_share_gdp"]),
  SE = c(se(a2)["ghe_share_gdp"], se(b1)["ln_oop"], total_se, direct_se, NA, se(oop_out)["ghe_share_gdp"]),
  P = c(pvalue(a2)["ghe_share_gdp"], pvalue(b1)["ln_oop"], total_p, direct_p, NA, pvalue(oop_out)["ghe_share_gdp"]),
  N = c(nobs(a2), nobs(b1), nobs(total), nobs(direct), NA, nobs(oop_out))
)
print(mediation_summary)
fwrite(mediation_summary, "results/tables/mediation_oop.csv")

cat("\n=== Complete ===\n")
