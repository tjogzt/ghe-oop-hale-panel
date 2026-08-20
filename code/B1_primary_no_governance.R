# ============================================================================
# B1_primary_no_governance.R
# Re-estimate primary TWFE WITHOUT governance controls
# Addresses over-control concerns (governance may be endogenous to health outcomes)
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
cat("B1: Primary TWFE WITHOUT Governance Controls\n")
cat("========================================================\n")

# ---- Load ----
df <- fread("/Volumes/tjogzt4T/lancet_financial_v2/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]

df_a <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]
cat(sprintf("Analytical sample: %d rows, %d countries\n", nrow(df_a), uniqueN(df_a$iso3c)))

# ---- 1. COMPARE: With vs Without Governance ----
cat("\n--- 1. Primary Model Comparison ---\n")

# Model without governance (primary recommendation)
m1 <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
            data=df_a, vcov=~iso3c)
cat(sprintf("M1 TWFE (no governance): GHE=%.4f (SE=%.4f, p=%.4f), N=%d\n",
            coef(m1)["ghe_share_gdp"], se(m1)["ghe_share_gdp"], pvalue(m1)["ghe_share_gdp"], nobs(m1)))

# Model with governance (original specification)
df_gov <- df_a[!is.na(governance_composite)]
m2 <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate + governance_composite | iso3c + year,
            data=df_gov, vcov=~iso3c)
cat(sprintf("M2 TWFE + governance:   GHE=%.4f (SE=%.4f, p=%.4f), N=%d\n",
            coef(m2)["ghe_share_gdp"], se(m2)["ghe_share_gdp"], pvalue(m2)["ghe_share_gdp"], nobs(m2)))

# Also show governance coefficient
cat(sprintf("  Governance coefficient: %.4f (SE=%.4f, p=%.4f)\n",
            coef(m2)["governance_composite"], se(m2)["governance_composite"],
            pvalue(m2)["governance_composite"]))

# ---- 2. SENSITIVITY: Governance as separate sensitivity table ----
cat("\n--- 2. Sensitivity: Adding Controls Sequentially ---\n")

# Different sensitivity specifications
sens_results <- data.table()

# A: GHE only + FE
s1 <- feols(hale ~ ghe_share_gdp | iso3c + year, data=df_a, vcov=~iso3c)
sens_results <- rbind(sens_results, data.table(
  spec="FE only, no controls", ghe_coef=coef(s1)["ghe_share_gdp"],
  ghe_se=se(s1)["ghe_share_gdp"], ghe_p=pvalue(s1)["ghe_share_gdp"], N=nobs(s1)))

# B: + GDP pc
s2 <- feols(hale ~ ghe_share_gdp + ln_gdppc | iso3c + year, data=df_a, vcov=~iso3c)
sens_results <- rbind(sens_results, data.table(
  spec="+ GDP pc", ghe_coef=coef(s2)["ghe_share_gdp"],
  ghe_se=se(s2)["ghe_share_gdp"], ghe_p=pvalue(s2)["ghe_share_gdp"], N=nobs(s2)))

# C: + urbanization
s3 <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization | iso3c + year, data=df_a, vcov=~iso3c)
sens_results <- rbind(sens_results, data.table(
  spec="+ urbanization", ghe_coef=coef(s3)["ghe_share_gdp"],
  ghe_se=se(s3)["ghe_share_gdp"], ghe_p=pvalue(s3)["ghe_share_gdp"], N=nobs(s3)))

# D: + fertility (full baseline, no gov)
sens_results <- rbind(sens_results, data.table(
  spec="+ fertility (primary)", ghe_coef=coef(m1)["ghe_share_gdp"],
  ghe_se=se(m1)["ghe_share_gdp"], ghe_p=pvalue(m1)["ghe_share_gdp"], N=nobs(m1)))

# E: + governance
sens_results <- rbind(sens_results, data.table(
  spec="+ governance (original)", ghe_coef=coef(m2)["ghe_share_gdp"],
  ghe_se=se(m2)["ghe_share_gdp"], ghe_p=pvalue(m2)["ghe_share_gdp"], N=nobs(m2)))

cat("\nSensitivity to control set:\n")
print(sens_results)

# ---- 3. INCOME HETEROGENEITY without governance ----
cat("\n--- 3. Income Heterogeneity (no governance) ---\n")

df_a[, income_base := .SD[year==min(year), income[1]], by=iso3c]
income_results <- data.table()

for(ig in c("Low income","Lower middle income","Upper middle income","High income")) {
  sub <- df_a[income_base == ig]
  if(nrow(sub) > 100) {
    fit <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                 data=sub, vcov=~iso3c)
    income_results <- rbind(income_results, data.table(
      income_group=ig, ghe_coef=coef(fit)["ghe_share_gdp"],
      ghe_se=se(fit)["ghe_share_gdp"], ghe_p=pvalue(fit)["ghe_share_gdp"], N=nobs(fit)))
  }
}

cat("TWFE without governance, by income group:\n")
print(income_results)

# ---- 4. FOREST PLOT: With vs Without Governance ----
cat("\n--- 4. Figure ---\n")

forest_data <- rbind(
  sens_results[, .(Specification=spec, Coef=ghe_coef, SE=ghe_se, P=ghe_p)],
  income_results[, .(Specification=paste0("  ",income_group), Coef=ghe_coef, SE=ghe_se, P=ghe_p)]
)
forest_data[, `:=`(ci_low=Coef-1.96*SE, ci_high=Coef+1.96*SE)]
forest_data[, sig := ifelse(P<0.01, "p<0.01", ifelse(P<0.05, "p<0.05", ifelse(P<0.10, "p<0.10", "n.s.")))]
forest_data[, Specification := factor(Specification, levels=rev(Specification))]

p_forest <- ggplot(forest_data, aes(x=Coef, y=Specification)) +
  geom_vline(xintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_point(aes(color=sig), size=3) +
  geom_errorbarh(aes(xmin=ci_low, xmax=ci_high, color=sig), height=0.2, linewidth=1) +
  scale_color_manual(values=c("p<0.01"=PAL["yanzhi"],"p<0.05"=PAL["zhusha"],
                               "p<0.10"=PAL["dianqing"],"n.s."="grey50")) +
  labs(x="GHE coefficient (years HALE per %GDP)", y="",
       title="B1: GHE-HALE Association — Without vs With Governance",
       subtitle="Primary specification (no governance) highlighted",
       color="") +
  theme_pub

ggsave("results/figures/B1_primary_no_governance.pdf", p_forest, width=8, height=5, device=cairo_pdf)
cat("Saved: results/figures/B1_primary_no_governance.pdf\n")

# ---- 5. SAVE RESULTS ----
fwrite(sens_results, "results/tables/B1_sensitivity_controls.csv")
fwrite(income_results, "results/tables/B1_income_no_governance.csv")
cat("Saved: results/tables/B1_sensitivity_controls.csv\n")
cat("Saved: results/tables/B1_income_no_governance.csv\n")

cat("\n=== B1 Complete ===\n")
