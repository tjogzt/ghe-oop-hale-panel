# ============================================================================
# 06_supplementary_tables.R — 生成Supplementary所需全部表格
# ============================================================================

set.seed(49)
options(scipen=999, warn=1)

library(data.table)

PROJ <- "/Users/taozhu/my researches/lancet_financial_v3"
setwd(PROJ)
dir.create("results/tables/supplementary", recursive=TRUE, showWarnings=FALSE)

# ---- Load Data ----
df <- fread("/Volumes/tjogzt4T/lancet_financial_v2/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]
df_a <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]

# ---- Table S1: Descriptive Statistics by Income Group ----
cat("=== Table S1: Descriptive Statistics ===\n")

calc_stats <- function(x) {
  x <- x[!is.na(x)]
  if(length(x)==0) return(c(NA,NA,NA,NA,NA))
  c(mean=mean(x), sd=sd(x), min=min(x), median=median(x), max=max(x), n=length(x))
}

vars <- c("hale","ghe_share_gdp","gdp_per_capita_ppp","urbanization","fertility_rate",
          "oop_expenditure","governance_composite","tax_revenue_gdp")
varnames <- c("HALE (years)","GHE (%GDP)","GDP pc PPP","Urbanization (%)","Fertility rate",
              "OOP (%CHE)","Governance composite","Tax revenue (%GDP)")

income_groups <- c("Low income","Lower middle income","Upper middle income","High income")

s1_list <- list()
for(ig in income_groups) {
  sub <- df_a[income == ig]
  for(j in seq_along(vars)) {
    v <- vars[j]
    stats <- calc_stats(sub[[v]])
    s1_list[[length(s1_list)+1]] <- data.table(
      Income=ig, Variable=varnames[j], Mean=stats[1], SD=stats[2],
      Min=stats[3], Median=stats[4], Max=stats[5], N=stats[6]
    )
  }
}
s1 <- rbindlist(s1_list)
fwrite(s1, "results/tables/supplementary/Table_S1_Descriptives.csv")
cat("Saved: Table_S1_Descriptives.csv\n")

# Also overall
s1_all_list <- list()
sub <- df_a
for(j in seq_along(vars)) {
  v <- vars[j]
  stats <- calc_stats(sub[[v]])
  s1_all_list[[length(s1_all_list)+1]] <- data.table(
    Income="All", Variable=varnames[j], Mean=stats[1], SD=stats[2],
    Min=stats[3], Median=stats[4], Max=stats[5], N=stats[6]
  )
}
s1_all <- rbindlist(s1_all_list)
s1_full <- rbind(s1_all, s1)
fwrite(s1_full, "results/tables/supplementary/Table_S1_Descriptives_Full.csv")

# ---- Table S2: Country Coverage ----
cat("\n=== Table S2: Country Coverage ===\n")
coverage <- df_a[, .(n_years=.N, first_year=min(year), last_year=max(year)), by=.(iso3c, country, income)]
coverage[, span := last_year - first_year + 1]
fwrite(coverage, "results/tables/supplementary/Table_S2_CountryCoverage.csv")
cat(sprintf("Countries: %d, Mean years: %.1f\n", nrow(coverage), mean(coverage$n_years)))

# ---- Table S3: Correlation Matrix ----
cat("\n=== Table S3: Correlation Matrix ===\n")
cor_vars <- c("hale","ghe_share_gdp","ln_gdppc","urbanization","fertility_rate",
              "oop_expenditure","governance_composite")
cor_data <- df_a[, ..cor_vars]
cor_data <- na.omit(cor_data)
cor_matrix <- cor(cor_data)
cor_dt <- as.data.table(cor_matrix, keep.rownames="Variable")
fwrite(cor_dt, "results/tables/supplementary/Table_S3_CorrelationMatrix.csv")

# ---- Table S4: Robustness from Claude pipeline ----
cat("\n=== Table S4: Claude Robustness ===\n")
if(file.exists("results_claude/tables/robustness_checks_summary.csv")) {
  rob_claude <- fread("results_claude/tables/robustness_checks_summary.csv")
  fwrite(rob_claude, "results/tables/supplementary/Table_S4_Robustness_Claude.csv")
  cat(sprintf("Claude: %d robustness checks\n", nrow(rob_claude)))
}

# ---- Table S5: Robustness from Alt pipeline ----
cat("\n=== Table S5: Alt Robustness ===\n")
if(file.exists("results/panel/tables/table4_robustness_ghe.csv")) {
  rob_alt <- fread("results/panel/tables/table4_robustness_ghe.csv")
  fwrite(rob_alt, "results/tables/supplementary/Table_S5_Robustness_Alt.csv")
  cat(sprintf("Alt pipeline: %d robustness checks\n", nrow(rob_alt)))
}

# ---- Table S6: Long Difference by Country ----
cat("\n=== Table S6: Long Difference ===\n")
setorder(df_a, iso3c, year)
first <- df_a[, .SD[1], by=iso3c]
last  <- df_a[, .SD[.N], by=iso3c]
ld <- merge(first[, .(iso3c,country,income,hale_0=hale,ghe_0=ghe_share_gdp,gdppc_0=ln_gdppc,year_0=year)],
            last[, .(iso3c,hale_T=hale,ghe_T=ghe_share_gdp,gdppc_T=ln_gdppc,year_T=year)], by="iso3c")
ld[, `:=`(d_hale=round(hale_T-hale_0,2), d_ghe=round(ghe_T-ghe_0,2), span=year_T-year_0)]
ld <- ld[span >= 10]
fwrite(ld[order(-d_hale)], "results/tables/supplementary/Table_S6_LongDifference.csv")
cat(sprintf("Long-diff: %d countries\n", nrow(ld)))

# ---- Table S7: GHE Spike Events ----
if(file.exists("results/tables/ghe_spike_events.csv")) {
  file.copy("results/tables/ghe_spike_events.csv", 
            "results/tables/supplementary/Table_S7_GHE_SpikeEvents.csv", overwrite=TRUE)
}

cat("\n=== Complete ===\n")
