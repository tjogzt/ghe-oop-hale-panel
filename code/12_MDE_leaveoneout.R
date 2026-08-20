# ============================================================================
# 12_MDE_leaveoneout.R — MDE框架 + leave-one-out jackknife + sensitivity
# ============================================================================
set.seed(49)
options(scipen=999, warn=1)

library(data.table)
library(fixest)
pvalue <- fixest::pvalue

PROJ <- "/Users/taozhu/my researches/lancet_financial_v3"
setwd(PROJ)

df <- fread("/Volumes/tjogzt4T/lancet_financial_v2/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]
df_a <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]

# ========================================================================
# 1. MDE / EQUIVALENCE FRAMEWORK
# ========================================================================
cat("========================================\n")
cat("1. MDE / Equivalence Framework\n")
cat("========================================\n")

# Re-run primary TWFE
m_twfe <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                data=df_a, vcov=~iso3c)

beta <- coef(m_twfe)["ghe_share_gdp"]
se_beta <- se(m_twfe)["ghe_share_gdp"]
ci95_upper <- beta + 1.96 * se_beta
ci95_lower <- beta - 1.96 * se_beta
N <- nobs(m_twfe)

cat(sprintf("Primary TWFE: β=%.4f, SE=%.4f, 95%% CI [%.4f, %.4f], N=%d\n",
            beta, se_beta, ci95_lower, ci95_upper, N))

# What effect size can we RULE OUT?
# 95% CI upper bound tells us the maximum positive effect compatible with our data
cat(sprintf("\n--- Evidence of Absence Framework ---\n"))
cat(sprintf("95%% CI upper bound: +%.4f years HALE per pp GDP\n", ci95_upper))
cat(sprintf("This RULES OUT effects larger than +%.4f at α=0.05\n", ci95_upper))
cat(sprintf("Cross-sectional naive estimate: +1.47 years/pp\n"))
cat(sprintf("Within-country estimate: 95%% CI rules out >%.1f%% of the cross-sectional gradient\n",
            100 * (1 - ci95_upper/1.47)))

# Minimal Detectable Effect (MDE) — what effect could we have detected with 80% power?
# MDE = (t_α/2 + t_β) × SE
t_alpha <- 1.96  # two-sided 0.05
t_beta <- 0.84   # 80% power
MDE <- (t_alpha + t_beta) * se_beta
cat(sprintf("\nMinimal Detectable Effect (80%% power, α=0.05): %.4f years/pp GDP\n", MDE))
cat(sprintf("We had 80%% power to detect an effect of %.4f or larger.\n", MDE))
cat(sprintf("The cross-sectional estimate (+1.47) is %.1f× the MDE.\n", 1.47/MDE))

# Equivalence bounds: can we reject effects > 0.2 years/pp?
equiv_bound <- 0.2
t_equiv <- (beta - equiv_bound) / se_beta
p_equiv_upper <- pt(t_equiv, df=N-5, lower.tail=TRUE)
cat(sprintf("\nEquivalence test (H0: β ≥ +0.2 vs H1: β < +0.2):\n"))
cat(sprintf("  t = %.3f, one-sided p = %.4f\n", t_equiv, p_equiv_upper))
if(p_equiv_upper < 0.05) {
  cat(sprintf("  REJECT H0: we can conclude β < +0.2 at α=0.05\n"))
} else {
  cat(sprintf("  Cannot reject H0 at α=0.05\n"))
}

# Also for tighter bound
equiv_bound2 <- 0.1
t_equiv2 <- (beta - equiv_bound2) / se_beta
p_equiv2 <- pt(t_equiv2, df=N-5, lower.tail=TRUE)
cat(sprintf("\nEquivalence test (H0: β ≥ +0.1): t=%.3f, p=%.4f\n", t_equiv2, p_equiv2))
if(p_equiv2 < 0.05) {
  cat(sprintf("  REJECT H0 at α=0.05 — evidence that effect is < +0.1\n"))
}

# ========================================================================
# 2. LEAVE-ONE-OUT JACKKNIFE (Country-level)
# ========================================================================
cat("\n========================================\n")
cat("2. Leave-One-Out Jackknife\n")
cat("========================================\n")

# (a) Overall TWFE — leave one country out
all_countries <- unique(df_a$iso3c)
n_countries <- length(all_countries)
loo_results <- data.table()

for(i in seq_along(all_countries)) {
  ctry <- all_countries[i]
  sub <- df_a[iso3c != ctry]
  fit <- try(feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                   data=sub, vcov=~iso3c), silent=TRUE)
  if(!inherits(fit, "try-error")) {
    loo_results <- rbind(loo_results, data.table(
      excluded=ctry, beta=coef(fit)["ghe_share_gdp"], se=se(fit)["ghe_share_gdp"]
    ))
  }
}
cat(sprintf("Leave-one-out: %d countries\n", nrow(loo_results)))
cat(sprintf("  β range: [%.4f, %.4f]\n", min(loo_results$beta), max(loo_results$beta)))
cat(sprintf("  Original β = %.4f\n", beta))
cat(sprintf("  Max deviation: %.4f\n", max(abs(loo_results$beta - beta))))

# Top 5 most influential
loo_results[, deviation := abs(beta - beta)]
setorder(loo_results, -deviation)
cat("\nTop 5 most influential countries:\n")
print(loo_results[1:5])

# (b) Low-income leave-one-out
df_a[, income_base := .SD[year==min(year), income[1]], by=iso3c]
df_low <- df_a[income_base == "Low income"]
low_countries <- unique(df_low$iso3c)
cat(sprintf("\nLow-income LOO: G=%d countries\n", length(low_countries)))

loo_low <- data.table()
for(ctry in low_countries) {
  sub <- df_low[iso3c != ctry]
  fit <- try(feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                   data=sub, vcov=~iso3c), silent=TRUE)
  if(!inherits(fit, "try-error")) {
    loo_low <- rbind(loo_low, data.table(
      excluded=ctry, beta=coef(fit)["ghe_share_gdp"], se=se(fit)["ghe_share_gdp"]
    ))
  }
}

# Original low-income estimate
fit_low_full <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                      data=df_low, vcov=~iso3c)
beta_low <- coef(fit_low_full)["ghe_share_gdp"]

cat(sprintf("  Original low-income β = %.4f\n", beta_low))
cat(sprintf("  LOO β range: [%.4f, %.4f]\n", min(loo_low$beta), max(loo_low$beta)))
loo_low[, deviation := abs(beta - beta_low)]
setorder(loo_low, -deviation)
cat("  Top 5 most influential low-income countries:\n")
print(loo_low[1:min(5, nrow(loo_low))])

# ========================================================================
# 3. SAVE RESULTS
# ========================================================================
cat("\n========================================\n")
cat("3. Saving\n")
cat("========================================\n")

mde_results <- data.table(
  Metric = c("TWFE beta","SE","95% CI lower","95% CI upper","MDE (80% power)",
             "Equiv test: β<0.2 (p)","Equiv test: β<0.1 (p)",
             "% cross-sectional ruled out","LOO beta range (min)","LOO beta range (max)",
             "Low-income full β","Low-income LOO beta range min","Low-income LOO beta range max",
             "Low-income n clusters"),
  Value = c(beta, se_beta, ci95_lower, ci95_upper, MDE,
            p_equiv_upper, p_equiv2,
            100*(1-ci95_upper/1.47), min(loo_results$beta), max(loo_results$beta),
            beta_low, min(loo_low$beta), max(loo_low$beta), length(low_countries))
)
fwrite(mde_results, "results/tables/MDE_equivalence.csv")
fwrite(loo_low, "results/tables/LOO_low_income.csv")
cat("Saved: MDE_equivalence.csv, LOO_low_income.csv\n")

cat("\n=== Complete ===\n")
