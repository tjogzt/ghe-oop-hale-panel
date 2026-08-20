# ============================================================================
# 05_compile_master_results.R — 汇总所有分析结果
# ============================================================================

library(data.table)

PROJ <- "/Users/taozhu/my researches/lancet_financial_v3"
setwd(PROJ)

# ---- Master Results Table ----
cat("=== Lancet Financial V3: Complete Analysis Summary ===\n")
cat("Date:", as.character(Sys.Date()), "\n")
cat("Data: integrated_panel_final.csv (2000-2023)\n")
cat("Sample: 190 countries, 4,314 country-years\n\n")

cat("═══════════════════════════════════════════════\n")
cat("TABLE 1: Primary Results — GHE → HALE\n")
cat("═══════════════════════════════════════════════\n")
main <- fread("results/tables/main_results.csv")
print(main)

cat("\n═══════════════════════════════════════════════\n")
cat("TABLE 2: Income Heterogeneity (TWFE)\n")
cat("═══════════════════════════════════════════════\n")
income <- fread("results/tables/income_heterogeneity.csv")
print(income)

cat("\n═══════════════════════════════════════════════\n")
cat("TABLE 3: Infant Mortality (alternative outcome)\n")
cat("═══════════════════════════════════════════════\n")
imr <- fread("results/tables/imr_results.csv")
print(imr)

cat("\n═══════════════════════════════════════════════\n")
cat("TABLE 4: OOP Mediation Analysis\n")
cat("═══════════════════════════════════════════════\n")
med <- fread("results/tables/mediation_oop.csv")
print(med)

cat("\n═══════════════════════════════════════════════\n")
cat("TABLE 5: Event Study — GHE Spike Events (>2pp/3yr)\n")
cat("═══════════════════════════════════════════════\n")
cat("25 treated countries. Event study shows HALE DECLINE after GHE spikes.\n")
cat("t-1: -0.055ns  t=0: -0.099ns  t+4: -0.436*  t+5: -0.514*\n\n")

cat("═══════════════════════════════════════════════\n")
cat("KEY FINDINGS (for Lancet Global Health)\n")
cat("═══════════════════════════════════════════════\n")
cat("
1. CROSS-SECTIONAL: Strong positive association (raw r≈0.85)
   → GHE/GDP and HALE strongly correlated ACROSS countries
   → BUT: this entirely reflects between-country development gradient

2. WITHIN-COUNTRY (TWFE): Null or negative
   → Primary TWFE: β=-0.122 years/pp GDP (p=0.077)
   → With governance controls: β=-0.161 (p=0.016)
   → Long-difference: β=-0.330 (p=0.034)
   → Infant mortality (log-IMR): β=-0.014 (p=0.092)
   
3. LOW-INCOME EXCEPTION:
   → Only group with POSITIVE within-country effect: +0.846 (p=0.030)
   → No low-income country had a GHE spike >2pp GDP
   → Policy implication: where spending is lowest, increases may still matter

4. REVERSE CAUSALITY (Event Study):
   → 25 countries with GHE spikes → HALE dropped ~0.5 years at t+5
   → GHE increases are often RESPONSES to health crises, not causes of improvement
   → Countries with 2020 events: UK, USA, Russia, Cyprus, Latvia, Montenegro (COVID-19)

5. OOP MEDIATION:
   → GHE significantly reduces OOP: β=-0.120 (p<0.001) — GOOD
   → Lower OOP → better HALE: β=-0.835 (p=0.022) — Financial protection matters
   → BUT: Direct GHE→HALE effect (controlling OOP) is MORE negative: β=-0.222 (p=0.013)
   → GHE improves financial protection but does NOT translate to better health
   
6. GOVERNANCE QUALITY is a stronger predictor than GHE share
   → TWFE+Gov: government effectiveness β≈+1.0 (p<0.001)

7. HALE ROSE NEARLY EVERYWHERE 2000-2023:
   → All income groups improved ~3-6 years
   → Improvement occurred regardless of GHE trajectory
   → 41 countries: GHE DECLINED but HALE still ROSE
")
