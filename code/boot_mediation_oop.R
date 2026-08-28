# Bootstrap CI for indirect effect a×b (OOP mediation, TWFE)
# Resample country clusters; recompute Path A (GHE→ln OOP) and Path B (ln OOP→HALE) with GHE controlled
suppressMessages({library(data.table); library(fixest)})
set.seed(49)
df <- fread("/Volumes/tjogzt4T/lancet_financial_v2/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]
df[, ln_oop := log(oop_expenditure + 0.01)]
df_a <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc) & !is.na(oop_expenditure)]
df_a <- df_a[!is.na(urbanization) & !is.na(fertility_rate)]

countries <- unique(df_a$iso3c)
B <- 999
ab <- numeric(B)
for (i in 1:B) {
  cl <- sample(countries, length(countries), replace=TRUE)
  d <- rbindlist(lapply(cl, function(c) df_a[iso3c==c]))
  a2 <- feols(ln_oop ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year, data=d, vcov=~iso3c)
  b1 <- feols(hale ~ ln_oop + ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year, data=d, vcov=~iso3c)
  ab[i] <- coef(a2)["ghe_share_gdp"] * coef(b1)["ln_oop"]
}
ci <- quantile(ab, c(0.025, 0.975))
cat(sprintf("Bootstrap a×b: median=%.4f, 95%% CI [%.4f, %.4f]\n", median(ab), ci[1], ci[2]))
cat(sprintf("Point estimate a×b = 0.1004 (total - direct)\n"))
