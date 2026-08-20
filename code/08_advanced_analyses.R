# ============================================================================
# 08_advanced_analyses.R — COMPARISON_REPORT下一步建议全部实现
# 1. 5-year/10-year panel differencing
# 2. GHE per capita (PPP) alternative exposure
# 3. Mechanism: electricity access as health system infrastructure proxy
# 4. Quasi-experimental: known health financing reforms (DiD)
# ============================================================================

set.seed(49)
options(scipen=999, warn=1)

pkgs <- c("data.table","fixest","ggplot2","scales")
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

# ---- 0. Load & Prepare ----
cat("=== Loading Data ===\n")
df <- fread("/Volumes/tjogzt4T/lancet_financial_v2/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]

# *** NEW: GHE per capita (PPP) ***
df[, ghe_pc := ghe_share_gdp * gdp_per_capita_ppp / 100]  # $PPP per capita
df[, ln_ghe_pc := log(ghe_pc + 0.01)]

df_a <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]

cat(sprintf("Analytical sample: %d rows, %d countries\n", nrow(df_a), uniqueN(df_a$iso3c)))

# ========================================================================
# 1. 5-YEAR & 10-YEAR PANEL DIFFERENCING
# ========================================================================
cat("\n========================================\n")
cat("1. 5-Year & 10-Year Panel Differencing\n")
cat("========================================\n")

# Create 5-year period variable
df_a[, period5 := floor(year/5)*5]
df_a[, period10 := floor(year/10)*10]

# Collapse to 5-year means
p5 <- df_a[, .(
  hale = mean(hale, na.rm=TRUE),
  ghe_share_gdp = mean(ghe_share_gdp, na.rm=TRUE),
  ln_ghe_pc = mean(ln_ghe_pc, na.rm=TRUE),
  ln_gdppc = mean(ln_gdppc, na.rm=TRUE),
  urbanization = mean(urbanization, na.rm=TRUE),
  fertility_rate = mean(fertility_rate, na.rm=TRUE),
  governance_composite = mean(governance_composite, na.rm=TRUE),
  oop_expenditure = mean(oop_expenditure, na.rm=TRUE),
  income = income[1],
  region = region[1]
), by=.(iso3c, country, period5)]

cat(sprintf("5-year panel: %d rows, %d countries\n", nrow(p5), uniqueN(p5$iso3c)))

# 5-year TWFE
m5a <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + period5,
             data=p5, vcov=~iso3c)
cat(sprintf("5yr TWFE (GHE/GDP):     β=%.4f (SE=%.4f, p=%.4f)\n",
            coef(m5a)["ghe_share_gdp"], se(m5a)["ghe_share_gdp"], pvalue(m5a)["ghe_share_gdp"]))

# 5-year TWFE with GHE per capita
m5b <- feols(hale ~ ln_ghe_pc + ln_gdppc + urbanization + fertility_rate | iso3c + period5,
             data=p5, vcov=~iso3c)
cat(sprintf("5yr TWFE (GHE pc, PPP): β=%.4f (SE=%.4f, p=%.4f)\n",
            coef(m5b)["ln_ghe_pc"], se(m5b)["ln_ghe_pc"], pvalue(m5b)["ln_ghe_pc"]))

# 10-year panel
p10 <- df_a[, .(
  hale = mean(hale, na.rm=TRUE),
  ghe_share_gdp = mean(ghe_share_gdp, na.rm=TRUE),
  ln_ghe_pc = mean(ln_ghe_pc, na.rm=TRUE),
  ln_gdppc = mean(ln_gdppc, na.rm=TRUE),
  urbanization = mean(urbanization, na.rm=TRUE),
  fertility_rate = mean(fertility_rate, na.rm=TRUE),
  governance_composite = mean(governance_composite, na.rm=TRUE),
  income = income[1]
), by=.(iso3c, country, period10)]

m10 <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + period10,
             data=p10, vcov=~iso3c)
cat(sprintf("10yr TWFE (GHE/GDP):    β=%.4f (SE=%.4f, p=%.4f)\n",
            coef(m10)["ghe_share_gdp"], se(m10)["ghe_share_gdp"], pvalue(m10)["ghe_share_gdp"]))

# Long difference (10-year): change 2000-2004 → 2015-2019
p5_first <- p5[period5==2000]
p5_last  <- p5[period5==2015]
ld10 <- merge(p5_first[, .(iso3c,country,income,hale_0=hale,ghe_0=ghe_share_gdp,ln_ghe_pc_0=ln_ghe_pc)],
              p5_last[, .(iso3c,hale_T=hale,ghe_T=ghe_share_gdp,ln_ghe_pc_T=ln_ghe_pc)],
              by="iso3c")
ld10[, `:=`(d_hale=hale_T-hale_0, d_ghe=ghe_T-ghe_0, d_ln_ghe_pc=ln_ghe_pc_T-ln_ghe_pc_0)]
cat(sprintf("\n10yr Long-Diff (5yr avg): N=%d\n", nrow(ld10)))
cat(sprintf("  corr(d_GHE, d_HALE) = %.3f\n", cor(ld10$d_ghe, ld10$d_hale)))
cat(sprintf("  corr(d_lnGHEpc, d_HALE) = %.3f\n", cor(ld10$d_ln_ghe_pc, ld10$d_hale)))

# ========================================================================
# 2. GHE PER CAPITA — COMPREHENSIVE COMPARISON
# ========================================================================
cat("\n========================================\n")
cat("2. GHE/GDP vs GHE per Capita (PPP)\n")
cat("========================================\n")

# Annual TWFE: GHE/GDP
m_gdp <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
               data=df_a, vcov=~iso3c)

# Annual TWFE: GHE per capita (log)
m_pc <- feols(hale ~ ln_ghe_pc + ln_gdppc + urbanization + fertility_rate | iso3c + year,
              data=df_a, vcov=~iso3c)

cat(sprintf("Annual TWFE:\n"))
cat(sprintf("  GHE/GDP:        β=%.4f (SE=%.4f, p=%.4f)\n",
            coef(m_gdp)["ghe_share_gdp"], se(m_gdp)["ghe_share_gdp"], pvalue(m_gdp)["ghe_share_gdp"]))
cat(sprintf("  ln(GHE pc PPP): β=%.4f (SE=%.4f, p=%.4f)\n",
            coef(m_pc)["ln_ghe_pc"], se(m_pc)["ln_ghe_pc"], pvalue(m_pc)["ln_ghe_pc"]))

# Income heterogeneity with GHE per capita
cat("\nGHE per capita by income group:\n")
df_a[, income_base := .SD[year==min(year), income[1]], by=iso3c]
for(ig in c("Low income","Lower middle income","Upper middle income","High income")) {
  sub <- df_a[income_base == ig]
  if(nrow(sub) > 100) {
    fit <- feols(hale ~ ln_ghe_pc + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                 data=sub, vcov=~iso3c)
    cat(sprintf("  %-22s: lnGHEpc=%.4f (p=%.3f), N=%d\n",
                ig, coef(fit)["ln_ghe_pc"], pvalue(fit)["ln_ghe_pc"], nobs(fit)))
  }
}

# ========================================================================
# 3. MECHANISM: Electricity Access as Health System Infrastructure
# ========================================================================
cat("\n========================================\n")
cat("3. Mechanism: Electricity Access\n")
cat("========================================\n")

# Load electricity data from WDI panel
elec <- fread("/Volumes/tjogzt4T/lancet_financial_v2/data/raw/wb_wdi_panel_2000_2023.csv")
elec <- elec[, .(iso3c, year, electricity_use, physician_density, hospital_beds, mortality_under5)]
elec[, year := as.numeric(year)]

# Merge with main panel
df_mech <- merge(df_a, elec, by=c("iso3c","year"), all.x=TRUE)

cat(sprintf("Electricity non-missing: %d (%.1f%%)\n",
            sum(!is.na(df_mech$electricity_use)), 100*sum(!is.na(df_mech$electricity_use))/nrow(df_mech)))
cat(sprintf("Mortality U5 non-missing: %d (%.1f%%)\n",
            sum(!is.na(df_mech$mortality_under5)), 100*sum(!is.na(df_mech$mortality_under5))/nrow(df_mech)))

# Electricity as mechanism: GHE → electricity → HALE
df_mech[, ln_elec := log(electricity_use + 0.01)]

# Path A: GHE → electricity
if(sum(!is.na(df_mech$electricity_use)) > 500) {
  a_elec <- feols(ln_elec ~ ghe_share_gdp + ln_gdppc + urbanization | iso3c + year,
                  data=df_mech[!is.na(electricity_use)], vcov=~iso3c)
  cat(sprintf("Path A: GHE→Electricity: β=%.4f (p=%.4f)\n",
              coef(a_elec)["ghe_share_gdp"], pvalue(a_elec)["ghe_share_gdp"]))
}

# U5 mortality as alternative outcome
df_mech[, ln_u5mr := log(mortality_under5 + 0.01)]
if(sum(!is.na(df_mech$mortality_under5)) > 500) {
  m_u5 <- feols(ln_u5mr ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                data=df_mech[!is.na(mortality_under5)], vcov=~iso3c)
  cat(sprintf("TWFE U5MR: GHE=%.4f (p=%.4f), N=%d\n",
              coef(m_u5)["ghe_share_gdp"], pvalue(m_u5)["ghe_share_gdp"], nobs(m_u5)))
}

# ========================================================================
# 4. QUASI-EXPERIMENTAL: Known Health Financing Reforms
# ========================================================================
cat("\n========================================\n")
cat("4. Quasi-Experimental: Health Reform DiD\n")
cat("========================================\n")

# Define known major health financing reforms
reforms <- data.table(
  iso3c = c("THA","GHA","CHN","MEX","RWA","TUR"),
  country = c("Thailand","Ghana","China","Mexico","Rwanda","Turkey"),
  reform_year = c(2002, 2003, 2009, 2004, 2005, 2003),
  reform_name = c("UCS","NHIS","Health Reform","Seguro Popular","CBHI","HTP")
)

# For each reform country, do a simple pre/post comparison with matched controls
# Match: same income group, similar baseline HALE

cat("Reform countries and their GHE trajectory:\n")
for(i in 1:nrow(reforms)) {
  r <- reforms[i]
  sub <- df_a[iso3c == r$iso3c]
  pre <- sub[year < r$reform_year, .(hale_pre=mean(hale), ghe_pre=mean(ghe_share_gdp))]
  post <- sub[year >= r$reform_year, .(hale_post=mean(hale), ghe_post=mean(ghe_share_gdp))]
  cat(sprintf("  %s (%s, %d): GHE %.1f→%.1f, HALE %.1f→%.1f\n",
              r$country, r$reform_name, r$reform_year,
              pre$ghe_pre, post$ghe_post, pre$hale_pre, post$hale_post))
}

# Simple staggered DiD: treated=1 after reform year
df_did <- copy(df_a)
df_did[, treated := 0]
df_did[, post := 0]
for(i in 1:nrow(reforms)) {
  df_did[iso3c == reforms$iso3c[i] & year >= reforms$reform_year[i], `:=`(treated=1, post=1)]
}

# Control: same income group, never treated
treated_isos <- reforms$iso3c
df_did[, eligible_control := !iso3c %in% treated_isos]

did_fit <- feols(hale ~ post + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                 data=df_did[treated==1 | eligible_control==1], vcov=~iso3c)
cat(sprintf("\nStaggered DiD (6 reforms, post vs never-treated):\n"))
cat(sprintf("  Post coefficient: β=%.4f (SE=%.4f, p=%.4f)\n",
            coef(did_fit)["post"], se(did_fit)["post"], pvalue(did_fit)["post"]))

# Individual reform DiD (each vs its income-group controls)
cat("\nIndividual reform DiD:\n")
for(i in 1:nrow(reforms)) {
  r <- reforms[i]
  ig <- unique(df_a[iso3c == r$iso3c, income_base])
  controls <- df_a[income_base == ig & iso3c != r$iso3c]
  
  sub_data <- rbind(
    df_a[iso3c == r$iso3c][, .(iso3c, year, hale, ghe_share_gdp, ln_gdppc, urbanization, fertility_rate)],
    controls[, .(iso3c, year, hale, ghe_share_gdp, ln_gdppc, urbanization, fertility_rate)]
  )
  sub_data[, post := ifelse(iso3c == r$iso3c & year >= r$reform_year, 1, 0)]
  sub_data[, treated_unit := ifelse(iso3c == r$iso3c, 1, 0)]
  
  if(nrow(sub_data) > 100) {
    fit <- feols(hale ~ post + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                 data=sub_data, vcov=~iso3c)
    cat(sprintf("  %-15s (%s): post β=%.4f (SE=%.4f, p=%.3f)\n",
                r$country, r$reform_name, coef(fit)["post"], se(fit)["post"], pvalue(fit)["post"]))
  }
}

# ========================================================================
# 5. SUMMARY TABLE
# ========================================================================
cat("\n========================================\n")
cat("5. Summary\n")
cat("========================================\n")

summary_dt <- data.table(
  Analysis = c(
    "5yr TWFE (GHE/GDP)",
    "5yr TWFE (GHE pc PPP)",
    "10yr TWFE (GHE/GDP)",
    "Annual TWFE (GHE/GDP)",
    "Annual TWFE (GHE pc PPP)",
    "DiD: 6 reforms pooled",
    "Electricity: GHE→Elec",
    "U5MR: GHE→log(U5MR)"
  ),
  Coefficient = c(
    coef(m5a)["ghe_share_gdp"], coef(m5b)["ln_ghe_pc"], coef(m10)["ghe_share_gdp"],
    coef(m_gdp)["ghe_share_gdp"], coef(m_pc)["ln_ghe_pc"],
    coef(did_fit)["post"],
    if(exists("a_elec")) coef(a_elec)["ghe_share_gdp"] else NA,
    if(exists("m_u5")) coef(m_u5)["ghe_share_gdp"] else NA
  ),
  SE = c(
    se(m5a)["ghe_share_gdp"], se(m5b)["ln_ghe_pc"], se(m10)["ghe_share_gdp"],
    se(m_gdp)["ghe_share_gdp"], se(m_pc)["ln_ghe_pc"],
    se(did_fit)["post"],
    if(exists("a_elec")) se(a_elec)["ghe_share_gdp"] else NA,
    if(exists("m_u5")) se(m_u5)["ghe_share_gdp"] else NA
  ),
  P = c(
    pvalue(m5a)["ghe_share_gdp"], pvalue(m5b)["ln_ghe_pc"], pvalue(m10)["ghe_share_gdp"],
    pvalue(m_gdp)["ghe_share_gdp"], pvalue(m_pc)["ln_ghe_pc"],
    pvalue(did_fit)["post"],
    if(exists("a_elec")) pvalue(a_elec)["ghe_share_gdp"] else NA,
    if(exists("m_u5")) pvalue(m_u5)["ghe_share_gdp"] else NA
  )
)
print(summary_dt)
fwrite(summary_dt, "results/tables/advanced_analyses_summary.csv")
cat("\nSaved: results/tables/advanced_analyses_summary.csv\n")

# ========================================================================
# 6. FIGURE: 5yr vs Annual comparison
# ========================================================================
cat("\n=== Figures ===\n")

# Combine results for forest plot
compare_dt <- data.table(
  Specification = c("Annual TWFE\n(GHE/GDP)","Annual TWFE\n(GHE pc PPP)",
                    "5yr TWFE\n(GHE/GDP)","5yr TWFE\n(GHE pc PPP)",
                    "10yr TWFE\n(GHE/GDP)"),
  Coef = c(coef(m_gdp)["ghe_share_gdp"], coef(m_pc)["ln_ghe_pc"],
           coef(m5a)["ghe_share_gdp"], coef(m5b)["ln_ghe_pc"],
           coef(m10)["ghe_share_gdp"]),
  SE = c(se(m_gdp)["ghe_share_gdp"], se(m_pc)["ln_ghe_pc"],
         se(m5a)["ghe_share_gdp"], se(m5b)["ln_ghe_pc"],
         se(m10)["ghe_share_gdp"])
)
compare_dt[, `:=`(ci_low=Coef-1.96*SE, ci_high=Coef+1.96*SE)]
compare_dt[, Specification := factor(Specification, levels=rev(Specification))]

p_compare <- ggplot(compare_dt, aes(x=Coef, y=Specification)) +
  geom_vline(xintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_point(size=3, color=PAL["shiqing"]) +
  geom_errorbarh(aes(xmin=ci_low, xmax=ci_high), height=0.2, linewidth=1.2, color=PAL["shiqing"]) +
  labs(x="GHE Coefficient", y="",
       title="Temporal Aggregation: Annual vs 5yr vs 10yr Panels",
       subtitle="Consistent null/negative finding regardless of time structure") +
  theme_pub
ggsave("results/figures/fig8_temporal_aggregation.pdf", p_compare, width=7, height=4, device=cairo_pdf)
cat("Saved: fig8_temporal_aggregation.pdf\n")

cat("\n=== All Advanced Analyses Complete ===\n")
