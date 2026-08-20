# Quick fix: re-run electricity and DiD with correct types
library(data.table)
library(fixest)
pvalue <- fixest::pvalue

PROJ <- "/Users/taozhu/my researches/lancet_financial_v3"
setwd(PROJ)

df <- fread("/Volumes/tjogzt4T/lancet_financial_v2/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]
df_a <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]

# ---- Electricity merge fix ----
elec <- fread("/Volumes/tjogzt4T/lancet_financial_v2/data/raw/wb_wdi_panel_2000_2023.csv")
elec <- elec[, .(iso3c, year=as.numeric(year), electricity_use, physician_density, hospital_beds, mortality_under5)]

df_mech <- merge(df_a, elec, by=c("iso3c","year"), all.x=TRUE)
cat(sprintf("Electricity: %d non-missing (%.1f%%)\n",
            sum(!is.na(df_mech$electricity_use)), 100*sum(!is.na(df_mech$electricity_use))/nrow(df_mech)))

df_mech[, ln_elec := log(electricity_use + 0.01)]

# Path A: GHE → Electricity
a_elec <- feols(ln_elec ~ ghe_share_gdp + ln_gdppc + urbanization | iso3c + year,
                data=df_mech[!is.na(electricity_use)], vcov=~iso3c)
cat(sprintf("GHE→Electricity: β=%.4f (SE=%.4f, p=%.4f), N=%d\n",
            coef(a_elec)["ghe_share_gdp"], se(a_elec)["ghe_share_gdp"], 
            pvalue(a_elec)["ghe_share_gdp"], nobs(a_elec)))

# Path B: Electricity → HALE
b_elec <- feols(hale ~ ln_elec + ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                data=df_mech[!is.na(electricity_use)], vcov=~iso3c)
cat(sprintf("Electricity→HALE: β=%.4f (SE=%.4f, p=%.4f), N=%d\n",
            coef(b_elec)["ln_elec"], se(b_elec)["ln_elec"], 
            pvalue(b_elec)["ln_elec"], nobs(b_elec)))

# U5MR
df_mech[, ln_u5mr := log(mortality_under5 + 0.01)]
m_u5 <- feols(ln_u5mr ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
              data=df_mech[!is.na(mortality_under5)], vcov=~iso3c)
cat(sprintf("U5MR TWFE: GHE=%.4f (SE=%.4f, p=%.4f), N=%d\n",
            coef(m_u5)["ghe_share_gdp"], se(m_u5)["ghe_share_gdp"],
            pvalue(m_u5)["ghe_share_gdp"], nobs(m_u5)))

# ---- Pooled DiD fix ----
reforms <- data.table(
  iso3c = c("THA","GHA","CHN","MEX","RWA","TUR"),
  country = c("Thailand","Ghana","China","Mexico","Rwanda","Turkey"),
  reform_year = c(2002, 2003, 2009, 2004, 2005, 2003),
  reform_name = c("UCS","NHIS","Health Reform","Seguro Popular","CBHI","HTP")
)

df_did <- copy(df_a)
df_did[, treated := 0L]
df_did[, post := 0L]
for(i in 1:nrow(reforms)) {
  df_did[iso3c == reforms$iso3c[i] & year >= reforms$reform_year[i], treated := 1L]
  df_did[iso3c == reforms$iso3c[i] & year >= reforms$reform_year[i], post := 1L]
}
# Only use treated + controls (same income groups)
treated_isos <- reforms$iso3c
ig_treated <- unique(df_did[iso3c %in% treated_isos, income])
controls <- df_did[!iso3c %in% treated_isos & income %in% ig_treated]
df_did_sub <- rbind(df_did[iso3c %in% treated_isos], controls)

did_fit <- feols(hale ~ post + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                 data=df_did_sub, vcov=~iso3c)
cat(sprintf("\nPooled DiD (income-matched): post β=%.4f (SE=%.4f, p=%.4f), N=%d\n",
            coef(did_fit)["post"], se(did_fit)["post"], pvalue(did_fit)["post"], nobs(did_fit)))

# ---- Updated summary ----
updated <- data.table(
  Analysis = c("Electricity: GHE→Elec","Electricity: Elec→HALE","U5MR TWFE","Pooled DiD (6 reforms, income-matched)"),
  Coefficient = c(coef(a_elec)["ghe_share_gdp"], coef(b_elec)["ln_elec"], 
                  coef(m_u5)["ghe_share_gdp"], coef(did_fit)["post"]),
  SE = c(se(a_elec)["ghe_share_gdp"], se(b_elec)["ln_elec"],
         se(m_u5)["ghe_share_gdp"], se(did_fit)["post"]),
  P = c(pvalue(a_elec)["ghe_share_gdp"], pvalue(b_elec)["ln_elec"],
        pvalue(m_u5)["ghe_share_gdp"], pvalue(did_fit)["post"]),
  N = c(nobs(a_elec), nobs(b_elec), nobs(m_u5), nobs(did_fit))
)
print(updated)
fwrite(updated, "results/tables/advanced_fix_results.csv")
cat("\nSaved.\n")
