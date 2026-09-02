#!/usr/bin/env Rscript
# 13_table1_complete.R
# Complete Table 1 estimation: all 8 models with CSV output
# (01_main_analysis.R covered Models 3-7; this script adds Models 1, 2, 8
#  and re-emits the full set for reproducibility)
suppressMessages({ library(fixest); library(data.table) })

df <- fread("/Users/taozhu/my researches/lancet_financial_v3/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]
# Model 1 (raw) and 2 (+GDP) use the exposure/outcome-complete sample (4,314);
# Models 3-8 use the full listwise sample (4,304) as in the primary analysis.
df_4314 <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]
df_a <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc) & !is.na(urbanization) & !is.na(fertility_rate)]
cat("Exposure/outcome-complete sample:", nrow(df_4314), "\n")
cat("Analytical sample:", nrow(df_a), "rows,", uniqueN(df_a$iso3c), "countries\n")

row <- function(name, m, term="ghe_share_gdp") {
  data.table(Model=name, Term=term, Coef=coef(m)[term], SE=se(m)[term], P=pvalue(m)[term], N=nobs(m))
}

# Model 1: Pooled OLS (raw, no controls) — 4,314 sample
m1 <- feols(hale ~ ghe_share_gdp, data=df_4314, vcov="hetero")
# Model 2: Pooled OLS (+GDP) — 4,314 sample
m2 <- feols(hale ~ ghe_share_gdp + ln_gdppc, data=df_4314, vcov="hetero")
# Model 3: Pooled OLS (full)
m3 <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate, data=df_a, vcov="hetero")
# Model 4: Country FE
m4 <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c, data=df_a, vcov=~iso3c)
# Model 5: TWFE
m5 <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year, data=df_a, vcov=~iso3c)
# Model 6: TWFE + governance
d_gov <- df_a[!is.na(governance_composite)]
m6 <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate + governance_composite | iso3c + year, data=d_gov, vcov=~iso3c)
# Model 7: Long-difference (01_main_analysis.R specification: first vs last
# year per country, span >= 15 years, with d_gdppc control)
setorder(df_a, iso3c, year)
fy <- df_a[, .SD[1], by=iso3c]; ly <- df_a[, .SD[.N], by=iso3c]
ld <- merge(fy[, .(iso3c, hale_0=hale, ghe_0=ghe_share_gdp, gdppc_0=ln_gdppc, yr_0=year)],
            ly[, .(iso3c, hale_T=hale, ghe_T=ghe_share_gdp, gdppc_T=ln_gdppc, yr_T=year)], by="iso3c")
ld[, `:=`(d_hale=hale_T-hale_0, d_ghe=ghe_T-ghe_0, d_gdppc=gdppc_T-gdppc_0, span=yr_T-yr_0)]
ld <- ld[span >= 15]
m7 <- lm(d_hale ~ d_ghe + d_gdppc, data=ld)
# Model 8: Pre-COVID TWFE (2000-2019)
d_pc <- df_a[year <= 2019]
m8 <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year, data=d_pc, vcov=~iso3c)

res <- rbind(
  row("M1_Pooled_OLS_raw", m1),
  row("M2_Pooled_OLS_GDP", m2),
  row("M3_Pooled_OLS_full", m3),
  row("M4_Country_FE", m4),
  row("M5_TWFE", m5),
  row("M6_TWFE_Governance", m6),
  data.table(Model="M7_LongDifference", Term="d_ghe", Coef=coef(m7)["d_ghe"], SE=summary(m7)$coefficients["d_ghe","Std. Error"], P=summary(m7)$coefficients["d_ghe","Pr(>|t|)"], N=nrow(ld)),
  row("M8_PreCOVID_TWFE", m8)
)
print(res[, .(Model, Coef=round(Coef,3), SE=round(SE,3), P=round(P,4), N)])
fwrite(res, "results/tables/table1_complete.csv")
cat("Saved: results/tables/table1_complete.csv\n")
