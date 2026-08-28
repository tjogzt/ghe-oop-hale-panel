# ============================================================================
# 15_LGH_strengthening.R — 4 LIC robustness analyses for Lancet GH submission
# ============================================================================
set.seed(49)
options(scipen=999, warn=1)

library(data.table)
library(ggplot2)
library(fixest)
pvalue <- fixest::pvalue

PROJ <- "/Users/taozhu/my researches/lancet_financial_v3"
setwd(PROJ)
dir.create("results/figures", recursive=TRUE, showWarnings=FALSE)
dir.create("results/tables", recursive=TRUE, showWarnings=FALSE)

PAL <- c(zhusha="#C23531", shiqing="#3D6BA8", yanzhi="#9D2933", dianqing="#177CB0")
theme_lancet <- theme_bw(base_size=10) + theme(
  panel.grid.minor=element_blank(),
  panel.grid.major=element_line(linewidth=0.2, color="grey90"),
  plot.title=element_text(face="bold",size=11),
  axis.title=element_text(size=9.5), axis.text=element_text(size=8),
  legend.text=element_text(size=8), legend.title=element_text(size=9))

# ---- Load data ----
df <- fread("/Volumes/tjogzt4T/lancet_financial_v2/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]
df_a <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc) & !is.na(urbanization) & !is.na(fertility_rate)]
df_a[, income_base := .SD[year==min(year), income[1]], by=iso3c]
df_low <- df_a[income_base == "Low income"]
cat(sprintf("Full N=%d, Low-income N=%d, G=%d\n", nrow(df_a), nrow(df_low), uniqueN(df_low$iso3c)))

# ========================================================================
# 1. LIC Leave-One-Out Forest Plot
# ========================================================================
cat("\n=== 1. LIC Leave-One-Out ===\n")
lic_countries <- unique(df_low$iso3c)
loo_results <- list()
for(cc in lic_countries) {
  sub <- df_low[iso3c != cc]
  fit <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
               data=sub, vcov=~iso3c)
  coef_val <- coef(fit)["ghe_share_gdp"]
  se_val <- se(fit)["ghe_share_gdp"]
  loo_results[[cc]] <- data.table(iso3c=cc, coef=coef_val, se=se_val,
                                   ci_low=coef_val-1.96*se_val, ci_high=coef_val+1.96*se_val)
}
loo_dt <- rbindlist(loo_results)
# Add country names
country_map <- unique(df_low[, .(iso3c, country)])
loo_dt <- merge(loo_dt, country_map, by="iso3c", all.x=TRUE)
loo_dt[, label := sprintf("%s (%s)", country, iso3c)]
loo_dt <- loo_dt[order(coef)]
loo_dt[, label := factor(label, levels=label)]
# Full LIC baseline
fit_full <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                  data=df_low, vcov=~iso3c)
full_coef <- coef(fit_full)["ghe_share_gdp"]
full_se <- se(fit_full)["ghe_share_gdp"]
full_n <- uniqueN(df_low$iso3c)

p_loo <- ggplot(loo_dt, aes(x=coef, y=label)) +
  geom_vline(xintercept=full_coef, linetype="dashed", color=PAL["zhusha"], linewidth=0.5) +
  geom_vline(xintercept=0, linetype="dotted", color="grey50", linewidth=0.3) +
  geom_point(size=2.5, color=PAL["shiqing"]) +
  geom_errorbar(aes(xmin=ci_low, xmax=ci_high, y=label), color=PAL["shiqing"], width=0.2, linewidth=0.8, orientation="y") +
  annotate("text", x=full_coef + 0.06, y=nrow(loo_dt)+0.8, 
           label=sprintf("Full LIC: +%.3f (SE=%.3f, p=%.3f)", full_coef, full_se, pvalue(fit_full)["ghe_share_gdp"]),
           size=3, color=PAL["zhusha"], hjust=0) +
  scale_y_discrete(expand=expansion(mult=c(0, 0), add=c(0.6, 1.0))) +
  labs(x="GHE coefficient (excluded country)", y="") +
  theme_lancet
ggsave("results/figures/figS9_lic_loo.pdf", p_loo, width=168, height=126, units="mm", device=cairo_pdf)
fwrite(loo_dt, "results/tables/LGH1_lic_loo.csv")
cat(sprintf("LOO range: [%.4f, %.4f]\n", min(loo_dt$coef), max(loo_dt$coef)))

# ========================================================================
# 2. LIC Dose-Response (continuous GHE → HALE, restricted cubic spline)
# ========================================================================
cat("\n=== 2. Dose-Response ===\n")
# Quadratic: GHE + GHE^2
df_low[, ghe_sq := ghe_share_gdp^2]
fit_quad <- feols(hale ~ ghe_share_gdp + ghe_sq + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                  data=df_low, vcov=~iso3c)
cat(sprintf("Quadratic: linear=%.4f (p=%.3f), squared=%.4f (p=%.3f)\n",
            coef(fit_quad)["ghe_share_gdp"], pvalue(fit_quad)["ghe_share_gdp"],
            coef(fit_quad)["ghe_sq"], pvalue(fit_quad)["ghe_sq"]))

# Predicted values for visualization
ghe_seq <- seq(min(df_low$ghe_share_gdp, na.rm=TRUE), max(df_low$ghe_share_gdp, na.rm=TRUE), length.out=50)
# Use a simpler scatter + loess approach for visualization
p_dose <- ggplot(df_low, aes(x=ghe_share_gdp, y=hale)) +
  geom_point(alpha=0.3, size=1.5, color="grey60") +
  geom_smooth(method="lm", formula=y~x+I(x^2), se=TRUE,
              fill=PAL["shiqing"], alpha=0.15, color=PAL["shiqing"], linewidth=1) +
  labs(x="GHE (% GDP)", y="HALE (years)") +
  theme_lancet
ggsave("results/figures/figS10_lic_doseresponse.pdf", p_dose, width=170, height=121.4, units="mm", device=cairo_pdf)
fwrite(data.table(coef=coef(fit_quad), se=se(fit_quad), p=pvalue(fit_quad)), 
       "results/tables/LGH2_doseresponse.csv")
cat("Dose-response saved\n")

# ========================================================================
# 3. Lag Structure (lag 0–3 years)
# ========================================================================
cat("\n=== 3. Lag Structure ===\n")
df_low[, `:=`(ghe_lag1=shift(ghe_share_gdp,1), ghe_lag2=shift(ghe_share_gdp,2), ghe_lag3=shift(ghe_share_gdp,3)),
       by=iso3c]
df_low[, `:=`(hale_lead1=shift(hale,1,type="lead")), by=iso3c]  # for reverse causality

lag_results <- list()
for(k in 0:3) {
  ghe_var <- if(k==0) "ghe_share_gdp" else paste0("ghe_lag", k)
  sub <- df_low[!is.na(get(ghe_var))]
  fit <- feols(as.formula(paste("hale ~", ghe_var, "+ ln_gdppc + urbanization + fertility_rate | iso3c + year")),
               data=sub, vcov=~iso3c)
  lag_results[[k+1]] <- data.table(lag=k, coef=coef(fit)[ghe_var], 
                                    se=se(fit)[ghe_var], p=pvalue(fit)[ghe_var], N=nobs(fit))
}
lag_dt <- rbindlist(lag_results)
lag_dt[, `:=`(ci_low=coef-1.96*se, ci_high=coef+1.96*se)]
cat(sprintf("Lag0: %.4f (p=%.3f), Lag1: %.4f (p=%.3f), Lag2: %.4f (p=%.3f), Lag3: %.4f (p=%.3f)\n",
            lag_dt$coef[1], lag_dt$p[1], lag_dt$coef[2], lag_dt$p[2],
            lag_dt$coef[3], lag_dt$p[3], lag_dt$coef[4], lag_dt$p[4]))

p_lag <- ggplot(lag_dt, aes(x=lag, y=coef)) +
  geom_hline(yintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_ribbon(aes(ymin=ci_low, ymax=ci_high), fill=PAL["shiqing"], alpha=0.15) +
  geom_line(color=PAL["shiqing"], linewidth=0.9) +
  geom_point(size=3, color=PAL["shiqing"]) +
  scale_x_reverse(breaks=0:3, labels=c("t","t-1","t-2","t-3")) +
  labs(x="GHE lag (years)", y="GHE coefficient (HALE yrs per %GDP)") +
  theme_lancet
ggsave("results/figures/figS11_lic_lagstructure.pdf", p_lag, width=168, height=126, units="mm", device=cairo_pdf)
fwrite(lag_dt, "results/tables/LGH3_lagstructure.csv")
cat("Lag structure saved\n")

# ========================================================================
# 4. Reverse Causality: lag(HALE) → GHE
# ========================================================================
cat("\n=== 4. Reverse Causality ===\n")
df_low[, hale_lag1 := shift(hale, 1), by=iso3c]
df_low[, hale_lag2 := shift(hale, 2), by=iso3c]
rev_results <- list()
for(k in 0:2) {
  hale_var <- if(k==0) "hale" else paste0("hale_lag", k)
  sub <- df_low[!is.na(get(hale_var))]
  fit <- feols(as.formula(paste("ghe_share_gdp ~", hale_var, "+ ln_gdppc + urbanization + fertility_rate | iso3c + year")),
               data=sub, vcov=~iso3c)
  rev_results[[k+1]] <- data.table(hale_lag=k, coef=coef(fit)[hale_var],
                                    se=se(fit)[hale_var], p=pvalue(fit)[hale_var])
}
rev_dt <- rbindlist(rev_results)
rev_dt[, `:=`(ci_low=coef-1.96*se, ci_high=coef+1.96*se)]
cat(sprintf("HALE→GHE: Lead0: %.4f (p=%.3f), Lead1: %.4f (p=%.3f), Lead2: %.4f (p=%.3f)\n",
            rev_dt$coef[1], rev_dt$p[1], rev_dt$coef[2], rev_dt$p[2], rev_dt$coef[3], rev_dt$p[3]))

# Interpretation: if reverse causality were driving the result, we should see
# past HALE predicting future GHE (i.e., countries with worse health increase spending)
# If these coefficients are not significant, it supports the forward-causality interpretation

cat(sprintf("\nReverse causality check: %s\n",
            ifelse(all(rev_dt$p > 0.10), 
                   "PASSED — past HALE does not predict future GHE (all p>0.10). Supports forward causality.",
                   "MIXED — some lagged HALE predicts GHE. Reverse causality cannot be ruled out.")))

# Visualization
p_rev <- ggplot(rev_dt, aes(x=hale_lag, y=coef)) +
  geom_hline(yintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_ribbon(aes(ymin=ci_low, ymax=ci_high), fill=PAL["zhusha"], alpha=0.15) +
  geom_line(color=PAL["zhusha"], linewidth=0.9) +
  geom_point(size=3, color=PAL["zhusha"]) +
  scale_x_reverse(breaks=0:2, labels=c("t","t-1","t-2")) +
  labs(x="HALE lag (years)", y="Coefficient (GHE %GDP per HALE year)") +
  theme_lancet
ggsave("results/figures/figS12_lic_reversecausality.pdf", p_rev, width=168, height=126, units="mm", device=cairo_pdf)
fwrite(rev_dt, "results/tables/LGH4_reversecausality.csv")
cat("Reverse causality saved\n")

cat("\n=== All 4 LGH strengthening analyses complete ===\n")
