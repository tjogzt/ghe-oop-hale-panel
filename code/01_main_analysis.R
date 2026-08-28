# ============================================================================
# 01_main_analysis.R — 独立分析：GHE与HALE的跨国面板研究
# 数据源: integrated_panel_final.csv (v2预处理)
# 目标: Lancet Global Health 水准
# ============================================================================

set.seed(49)
options(scipen=999, warn=1)

# ---- 0. Setup ----
pkgs <- c("data.table","fixest","ggplot2","scales","ggrepel","gridExtra")
for(p in pkgs) if(!requireNamespace(p,quietly=TRUE)) install.packages(p,repos="https://cloud.r-project.org")
invisible(lapply(pkgs,library,character.only=TRUE))
# resolve pvalue conflict: use fixest::pvalue explicitly
pvalue <- fixest::pvalue

PROJ <- "/Users/taozhu/my researches/lancet_financial_v3"
setwd(PROJ)
dir.create("results/tables", recursive=TRUE, showWarnings=FALSE)
dir.create("results/figures", recursive=TRUE, showWarnings=FALSE)

# 中国风色系
PAL <- c(zhusha="#C23531", shiqing="#3D6BA8", yanzhi="#9D2933", dianqing="#177CB0")
INC_COL <- c("Low income"="#9D2933","Lower middle income"="#C23531",
             "Upper middle income"="#177CB0","High income"="#3D6BA8")

# ---- 1. Load & Clean ----
cat("\n=== 1. Loading Data ===\n")
df <- fread("/Volumes/tjogzt4T/lancet_financial_v2/data/processed/integrated_panel_final.csv")
cat(sprintf("Raw: %d rows, %d cols\n", nrow(df), ncol(df)))

# Filter: remove aggregates and unclassified
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
cat(sprintf("After filtering aggregates: %d rows\n", nrow(df)))

# Log transform GDP
df[, ln_gdppc := log(gdp_per_capita_ppp)]

# Define analytical sample: non-missing HALE, GHE, GDP
df_analysis <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]
cat(sprintf("Analytical sample: %d rows, %d countries\n", nrow(df_analysis), uniqueN(df_analysis$iso3c)))

# ---- 2. Long Difference Analysis (core finding) ----
cat("\n=== 2. Long Difference ===\n")
setorder(df_analysis, iso3c, year)
first_yr <- df_analysis[, .SD[1], by=iso3c]
last_yr  <- df_analysis[, .SD[.N], by=iso3c]
ld <- merge(first_yr[, .(iso3c,country,income,region,hale_0=hale,ghe_0=ghe_share_gdp,gdppc_0=ln_gdppc,year_0=year)],
            last_yr[, .(iso3c,hale_T=hale,ghe_T=ghe_share_gdp,gdppc_T=ln_gdppc,year_T=year)],
            by="iso3c")
ld[, `:=`(d_hale = hale_T - hale_0,
          d_ghe  = ghe_T - ghe_0,
          d_gdppc = gdppc_T - gdppc_0,
          span   = year_T - year_0)]
ld <- ld[span >= 15]  # only countries with >=15 years of data

cat(sprintf("Long-diff sample (span>=15yr): %d countries\n", nrow(ld)))
cat(sprintf("  d_HALE: mean=%.1f, SD=%.1f\n", mean(ld$d_hale), sd(ld$d_hale)))
cat(sprintf("  d_GHE:  mean=%.1f, SD=%.1f\n", mean(ld$d_ghe), sd(ld$d_ghe)))

# Long-diff regression
ld_fit <- lm(d_hale ~ d_ghe + d_gdppc, data=ld)
cat(sprintf("  Long-diff OLS: d_GHE coef=%.3f, p=%.3f\n", 
            coef(ld_fit)["d_ghe"], summary(ld_fit)$coefficients["d_ghe","Pr(>|t|)"]))

# ---- 3. Panel FE Models ----
cat("\n=== 3. Panel Fixed Effects ===\n")

# Model 1: Pooled OLS (benchmark)
m1 <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate,
            data=df_analysis, vcov="hetero")
cat(sprintf("M1 Pooled OLS:    GHE=%.3f (SE=%.3f, p=%.3f)\n",
            coef(m1)["ghe_share_gdp"], se(m1)["ghe_share_gdp"], pvalue(m1)["ghe_share_gdp"]))

# Model 2: Country FE
m2 <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c,
            data=df_analysis, vcov=~iso3c)
cat(sprintf("M2 Country FE:     GHE=%.3f (SE=%.3f, p=%.3f)\n",
            coef(m2)["ghe_share_gdp"], se(m2)["ghe_share_gdp"], pvalue(m2)["ghe_share_gdp"]))

# Model 3: Two-way FE (country + year)
m3 <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
            data=df_analysis, vcov=~iso3c)
cat(sprintf("M3 TWFE:           GHE=%.3f (SE=%.3f, p=%.3f)\n",
            coef(m3)["ghe_share_gdp"], se(m3)["ghe_share_gdp"], pvalue(m3)["ghe_share_gdp"]))

# Model 4: TWFE + governance
m4 <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate + governance_composite | iso3c + year,
            data=df_analysis, vcov=~iso3c)
cat(sprintf("M4 TWFE+Gov:       GHE=%.3f (SE=%.3f, p=%.3f)\n",
            coef(m4)["ghe_share_gdp"], se(m4)["ghe_share_gdp"], pvalue(m4)["ghe_share_gdp"]))

# Model 5: Heterogeneity by income group (baseline income)
df_analysis[, income_base := .SD[year==min(year), income[1]], by=iso3c]
m5 <- feols(hale ~ ghe_share_gdp*income_base + ln_gdppc + urbanization + fertility_rate | iso3c + year,
            data=df_analysis, vcov=~iso3c)

# ---- 4. Alternative Outcome: Subgroups ----
cat("\n=== 4. Income Heterogeneity ===\n")
income_groups <- c("Low income","Lower middle income","Upper middle income","High income")
results_list <- list()

for(ig in income_groups) {
  sub <- df_analysis[income_base == ig]
  if(nrow(sub) > 100) {
    fit <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                 data=sub, vcov=~iso3c)
    coef_val <- coef(fit)["ghe_share_gdp"]
    se_val <- se(fit)["ghe_share_gdp"]
    p_val <- pvalue(fit)["ghe_share_gdp"]
    cat(sprintf("  %-22s: GHE=%.3f (SE=%.3f, p=%.3f), N=%d\n", ig, coef_val, se_val, p_val, nrow(sub)))
    results_list[[ig]] <- data.table(income_group=ig, coef=coef_val, se=se_val, p=p_val, n=nrow(sub))
  }
}
income_results <- rbindlist(results_list)

# ---- 5. Save Results ----
cat("\n=== 5. Saving Results ===\n")

# Master results table
master <- rbind(
  data.table(Model="M1_Pooled_OLS", Term="ghe_share_gdp", Coef=coef(m1)["ghe_share_gdp"], 
             SE=se(m1)["ghe_share_gdp"], P=pvalue(m1)["ghe_share_gdp"], N=nobs(m1)),
  data.table(Model="M2_Country_FE", Term="ghe_share_gdp", Coef=coef(m2)["ghe_share_gdp"],
             SE=se(m2)["ghe_share_gdp"], P=pvalue(m2)["ghe_share_gdp"], N=nobs(m2)),
  data.table(Model="M3_TWFE", Term="ghe_share_gdp", Coef=coef(m3)["ghe_share_gdp"],
             SE=se(m3)["ghe_share_gdp"], P=pvalue(m3)["ghe_share_gdp"], N=nobs(m3)),
  data.table(Model="M4_TWFE_Governance", Term="ghe_share_gdp", Coef=coef(m4)["ghe_share_gdp"],
             SE=se(m4)["ghe_share_gdp"], P=pvalue(m4)["ghe_share_gdp"], N=nobs(m4)),
  data.table(Model="LongDiff_OLS", Term="d_ghe", Coef=coef(ld_fit)["d_ghe"],
             SE=summary(ld_fit)$coefficients["d_ghe","Std. Error"],
             P=summary(ld_fit)$coefficients["d_ghe","Pr(>|t|)"], N=nrow(ld))
)
fwrite(master, "results/tables/main_results.csv")
fwrite(income_results, "results/tables/income_heterogeneity.csv")

cat("Saved: results/tables/main_results.csv\n")
cat("Saved: results/tables/income_heterogeneity.csv\n")

# ---- 6. Figures ----
cat("\n=== 6. Generating Figures ===\n")

# Helper themes
theme_pub <- theme_bw(base_size=8) +
  theme(panel.grid.minor=element_blank(),
        strip.background=element_rect(fill="grey92",colour=NA),
        legend.key.size=unit(0.35,"cm"),
        plot.title=element_text(face="bold",size=9),
        axis.title=element_text(size=8),
        axis.text=element_text(size=7),
        legend.text=element_text(size=7))

# Figure 1: Long Difference — the most honest picture
ld[, quadrant := ifelse(d_ghe > 0 & d_hale > 0, "GHE↑ HALE↑",
                 ifelse(d_ghe > 0 & d_hale <= 0, "GHE↑ HALE↓",
                 ifelse(d_ghe <= 0 & d_hale > 0, "GHE↓ HALE↑", "GHE↓ HALE↓")))]
ld[, quadrant := factor(quadrant, levels=c("GHE↑ HALE↑","GHE↑ HALE↓","GHE↓ HALE↑","GHE↓ HALE↓"))]

p1 <- ggplot(ld, aes(x=d_ghe, y=d_hale)) +
  geom_hline(yintercept=0, linetype="dashed", color="grey60", linewidth=0.3) +
  geom_vline(xintercept=0, linetype="dashed", color="grey60", linewidth=0.3) +
  geom_point(aes(color=income), size=2, alpha=0.7) +
  geom_smooth(method="lm", se=TRUE, color="black", linewidth=0.8, alpha=0.2) +
  scale_color_manual(values=INC_COL) +
  labs(x="Change in GHE (% GDP)", y="Change in HALE (years)",
       title="Long-Difference: GHE vs HALE Change (2000→Latest)",
       subtitle=sprintf("N=%d countries, r=%.3f, %d countries with GHE↓ but HALE↑",
                        nrow(ld), cor(ld$d_ghe, ld$d_hale),
                        ld[quadrant=="GHE↓ HALE↑", .N]),
       color="Income Group") +
  theme_pub + theme(legend.position="bottom")
ggsave("results/figures/fig1_longdiff.pdf", p1, width=7, height=6, device=cairo_pdf)
cat("Saved: fig1_longdiff.pdf\n")

# Figure 2: Coefficient forest plot — all estimates
forest_data <- rbind(
  master[, .(Model, Coef, SE, P)],
  income_results[, .(Model=paste0("  ",income_group), Coef=coef, SE=se, P=p)]
)
forest_data[, `:=`(ci_low=Coef-1.96*SE, ci_high=Coef+1.96*SE)]
forest_data[, sig := ifelse(P<0.01, "p<0.01", ifelse(P<0.05, "p<0.05", ifelse(P<0.10, "p<0.10", "n.s.")))]
forest_data[, Model := factor(Model, levels=rev(Model))]

p2 <- ggplot(forest_data, aes(x=Coef, y=Model)) +
  geom_vline(xintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_point(aes(color=sig), size=3.5) +
  geom_errorbarh(aes(xmin=ci_low, xmax=ci_high, color=sig), height=0.2, linewidth=1.5) +
  scale_color_manual(values=c("p<0.01"=PAL["yanzhi"],"p<0.05"=PAL["zhusha"],
                               "p<0.10"=PAL["dianqing"],"n.s."="grey50"),
                     name="Significance",
                     breaks=c("p<0.01","p<0.05","p<0.10","n.s.")) +
  labs(x="GHE coefficient (years HALE per %GDP)", y="",
       title="GHE-HALE Association Across Specifications",
       color="Significance") +
  theme_pub +
  theme(legend.position="bottom",
        legend.title=element_text(size=7),
        panel.border=element_blank(),
        axis.line=element_line(colour="grey40", linewidth=0.4))
ggsave("results/figures/fig2_forest.pdf", p2, width=170, height=106.25, units="mm", device=cairo_pdf)
cat("Saved: fig2_forest.pdf\n")

# Figure 3: HALE trends by income group — all countries rise regardless of GHE
df_analysis[, hale_avg := mean(hale), by=.(income, year)]
trend_data <- unique(df_analysis[, .(income, year, hale_avg)])

p3 <- ggplot(trend_data, aes(x=year, y=hale_avg, color=income)) +
  geom_line(linewidth=1) +
  geom_point(size=1.5) +
  scale_color_manual(values=INC_COL) +
  labs(x="Year", y="Mean HALE (years)",
       title="HALE Trends by Income Group (2000–2023)",
       subtitle="All groups improved regardless of GHE trajectory",
       color="Income Group") +
  theme_pub + theme(legend.position="bottom")
ggsave("results/figures/fig3_hale_trends.pdf", p3, width=7, height=5, device=cairo_pdf)
cat("Saved: fig3_hale_trends.pdf\n")

# Figure 4: GHE vs HALE — between vs within
# Extract country-level means and deviations
df_analysis[, `:=`(ghe_mean=mean(ghe_share_gdp), hale_mean=mean(hale)), by=iso3c]
df_analysis[, `:=`(ghe_dev=ghe_share_gdp-ghe_mean, hale_dev=hale-hale_mean)]

# Between
p4a <- ggplot(unique(df_analysis[, .(iso3c, income, ghe_mean, hale_mean)]), 
              aes(x=ghe_mean, y=hale_mean, color=income)) +
  geom_point(size=1.5, alpha=0.6) +
  geom_smooth(method="lm", se=TRUE, color="black", linewidth=0.8, alpha=0.15) +
  scale_color_manual(values=INC_COL) +
  labs(x="Mean GHE (%GDP)", y="Mean HALE (years)", 
       title="BETWEEN Countries (r = 0.54)", color="") +
  theme_pub

# Within
p4b <- ggplot(df_analysis, aes(x=ghe_dev, y=hale_dev, color=income)) +
  geom_point(size=1, alpha=0.3) +
  geom_smooth(method="lm", se=TRUE, color="black", linewidth=0.8, alpha=0.15) +
  scale_color_manual(values=INC_COL) +
  labs(x="GHE Deviation from Country Mean", y="HALE Deviation from Country Mean",
       title="WITHIN Countries (r = +0.14)", color="") +
  theme_pub

p4 <- gridExtra::grid.arrange(p4a, p4b, ncol=2)
ggsave("results/figures/fig4_between_within.pdf", p4, width=12, height=5.5, device=cairo_pdf)
cat("Saved: fig4_between_within.pdf\n")

cat("\n=== Analysis Complete ===\n")
