# ============================================================================
# C3_temporal_heterogeneity.R
# Temporal Heterogeneity: 2000-2010 vs 2011-2023
# MDG era vs SDG era comparison
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
INC_COL <- c("Low income"="#9D2933","Lower middle income"="#C23531",
             "Upper middle income"="#177CB0","High income"="#3D6BA8")
theme_pub <- theme_bw(base_size=8) +
  theme(panel.grid.minor=element_blank(),
        plot.title=element_text(face="bold",size=9),
        axis.title=element_text(size=8), axis.text=element_text(size=7))

cat("========================================================\n")
cat("C3: Temporal Heterogeneity — MDG era vs SDG era\n")
cat("========================================================\n")

# ---- Load ----
df <- fread("/Volumes/tjogzt4T/lancet_financial_v2/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]

df_a <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]
df_a[, income_base := .SD[year==min(year), income[1]], by=iso3c]

# ---- 1. Split into Periods ----
# MDG era: 2000-2015 | SDG era: 2016-2022 (panel ends 2022)
# Era definitions updated 2026-08-19 to match 2022 panel truncation
periods <- list(
  "2000–2015 (MDG)" = c(2000, 2015),
  "2016–2022 (SDG)" = c(2016, 2022)
)

results_period <- data.table()

for(pname in names(periods)) {
  yrs <- periods[[pname]]
  sub <- df_a[year >= yrs[1] & year <= yrs[2]]

  if(nrow(sub) < 500) {
    cat(sprintf("%s: insufficient data (%d rows)\n", pname, nrow(sub)))
    next
  }

  # TWFE
  fit <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
               data=sub, vcov=~iso3c)

  cat(sprintf("\n%s: N=%d countries, %d obs\n", pname, uniqueN(sub$iso3c), nobs(fit)))
  cat(sprintf("  GHE: %.4f (SE=%.4f, p=%.4f)\n",
              coef(fit)["ghe_share_gdp"], se(fit)["ghe_share_gdp"],
              pvalue(fit)["ghe_share_gdp"]))

  results_period <- rbind(results_period, data.table(
    period=pname, ghe_coef=coef(fit)["ghe_share_gdp"],
    ghe_se=se(fit)["ghe_share_gdp"], ghe_p=pvalue(fit)["ghe_share_gdp"],
    n_countries=uniqueN(sub$iso3c), N=nobs(fit)))

  # Pooled OLS for comparison
  pool <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate,
                data=sub, vcov="hetero")
  cat(sprintf("  Pooled OLS: %.4f (p=%.4f)\n",
              coef(pool)["ghe_share_gdp"], pvalue(pool)["ghe_share_gdp"]))
}

# ---- 2. Income Heterogeneity by Period ----
cat("\n--- 2. Income Heterogeneity by Period ---\n")

income_period <- data.table()
for(pname in c("2000–2015 (MDG)", "2016–2022 (SDG)")) {
  yrs <- periods[[pname]]
  sub <- df_a[year >= yrs[1] & year <= yrs[2]]

  for(ig in c("Low income","Lower middle income","Upper middle income","High income")) {
    sub_ig <- sub[income_base == ig]
    if(nrow(sub_ig) > 50) {
      fit <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                   data=sub_ig, vcov=~iso3c)
      income_period <- rbind(income_period, data.table(
        period=pname, income_group=ig,
        ghe_coef=coef(fit)["ghe_share_gdp"],
        ghe_se=se(fit)["ghe_share_gdp"],
        ghe_p=pvalue(fit)["ghe_share_gdp"],
        N=nobs(fit)
      ))
    }
  }
}

cat("Income heterogeneity by period:\n")
print(income_period)

# ---- 3. Interaction Model: Period × GHE ----
cat("\n--- 3. Interaction Model ---\n")

df_a[, period_mdg := ifelse(year <= 2010, "MDG (2000-2010)", "SDG (2011-2023)")]
df_a[, period_mdg := factor(period_mdg, levels=c("MDG (2000-2010)","SDG (2011-2023)"))]

int_fit <- feols(hale ~ ghe_share_gdp * period_mdg + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                 data=df_a, vcov=~iso3c)
cat("Interaction model results:\n")
cat(sprintf("  GHE main effect (MDG ref): %.4f (SE=%.4f)\n",
            coef(int_fit)["ghe_share_gdp"], se(int_fit)["ghe_share_gdp"]))
cat(sprintf("  GHE × SDG interaction:    %.4f (SE=%.4f, p=%.4f)\n",
            coef(int_fit)["ghe_share_gdp:period_mdgSDG (2011-2023)"],
            se(int_fit)["ghe_share_gdp:period_mdgSDG (2011-2023)"],
            pvalue(int_fit)["ghe_share_gdp:period_mdgSDG (2011-2023)"]))

# ---- 4. GHE Trend Changes Across Periods ----
cat("\n--- 4. GHE Levels by Period ---\n")

for(pname in c("2000–2015 (MDG)", "2016–2022 (SDG)")) {
  yrs <- periods[[pname]]
  sub <- df_a[year >= yrs[1] & year <= yrs[2]]
  cat(sprintf("\n%s:\n", pname))
  cat(sprintf("  Mean GHE: %.2f%% GDP (SD=%.2f)\n", mean(sub$ghe_share_gdp), sd(sub$ghe_share_gdp)))
  cat(sprintf("  Mean HALE: %.2f years (SD=%.2f)\n", mean(sub$hale), sd(sub$hale)))
  # Average annual HALE change within each country for the period
  hale_changes <- sub[, {
    if(.N > 1) {
      (hale[.N] - hale[1]) / (year[.N] - year[1])
    } else NA_real_
  }, by=iso3c]
  avg_change <- mean(hale_changes$V1, na.rm=TRUE)
  cat(sprintf("  Mean HALE delta/year: %.3f years\n", avg_change))
}

# ---- 5. Figure: Period Comparison ----
cat("\n--- 5. Figure ---\n")

# Forest plot of period estimates
forest_period <- rbind(
  results_period[, .(label=period, Coef=ghe_coef, SE=ghe_se, P=ghe_p)],
  income_period[, .(label=paste0("  ",period,": ",income_group), Coef=ghe_coef, SE=ghe_se, P=ghe_p)]
)
forest_period[, `:=`(ci_low=Coef-1.96*SE, ci_high=Coef+1.96*SE)]
forest_period[, sig := ifelse(P<0.01, "p<0.01", ifelse(P<0.05, "p<0.05", ifelse(P<0.10, "p<0.10", "n.s.")))]
forest_period[, label := factor(label, levels=rev(label))]

p <- ggplot(forest_period, aes(x=Coef, y=label)) +
  geom_vline(xintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_point(aes(color=sig), size=3) +
  geom_errorbarh(aes(xmin=ci_low, xmax=ci_high, color=sig), height=0.2, linewidth=1) +
  scale_color_manual(values=c("p<0.01"=PAL["yanzhi"],"p<0.05"=PAL["zhusha"],
                               "p<0.10"=PAL["dianqing"],"n.s."="grey50")) +
  labs(x="GHE coefficient (years HALE per %GDP)", y="",
       title="C3: Temporal Heterogeneity — MDG Era vs SDG Era",
       subtitle="GHE-HALE association across time periods",
       color="") +
  theme_pub

ggsave("results/figures/C3_temporal_heterogeneity.pdf", p, width=8, height=6, device=cairo_pdf)
cat("Saved: results/figures/C3_temporal_heterogeneity.pdf\n")

# ---- 6. Save Results ----
fwrite(results_period, "results/tables/C3_period_results.csv")
fwrite(income_period, "results/tables/C3_income_period.csv")
cat("Saved: results/tables/C3_period_results.csv\n")
cat("Saved: results/tables/C3_income_period.csv\n")

cat("\n=== C3 Complete ===\n")
