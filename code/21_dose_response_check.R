#!/usr/bin/env Rscript
# 重算 Figure 5B 的两个数:全样本二次项 + 排除卢旺达后的二次项
# 与 code/15_LGH_strengthening.R 的 fit_quad 同设定
suppressMessages({library(data.table); library(fixest)})
BASE <- "/Users/taozhu/my researches/lancet_financial_v3"

df <- fread(file.path(BASE, "data/processed/integrated_panel_final.csv"))
df <- df[!(region %in% c("Aggregates", "") | income %in% c("Aggregates", "Not classified", ""))]
df[, `:=`(ln_gdppc = log(gdp_per_capita_ppp))]
dl <- df[income == "Low income"]
dl <- dl[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc) &
           !is.na(urbanization) & !is.na(fertility_rate)]
setorder(dl, iso3c, year)
dl[, ghe_sq := ghe_share_gdp^2]
cat("低收入样本:", nrow(dl), "行,", uniqueN(dl$iso3c), "国\n")

fit1 <- feols(hale ~ ghe_share_gdp + ghe_sq + ln_gdppc + urbanization + fertility_rate | iso3c + year,
              data = dl, vcov = ~iso3c)
fit2 <- feols(hale ~ ghe_share_gdp + ghe_sq + ln_gdppc + urbanization + fertility_rate | iso3c + year,
              data = dl[iso3c != "RWA"], vcov = ~iso3c)

r <- data.table(
  sample = c("full", "excl_Rwanda"),
  coef_ghe  = c(coef(fit1)["ghe_share_gdp"], coef(fit2)["ghe_share_gdp"]),
  p_ghe     = c(pvalue(fit1)["ghe_share_gdp"], pvalue(fit2)["ghe_share_gdp"]),
  coef_sq   = c(coef(fit1)["ghe_sq"],        coef(fit2)["ghe_sq"]),
  se_sq     = c(se(fit1)["ghe_sq"],          se(fit2)["ghe_sq"]),
  p_sq      = c(pvalue(fit1)["ghe_sq"],      pvalue(fit2)["ghe_sq"]),
  N         = c(nobs(fit1), nobs(fit2)),
  n_iso     = c(uniqueN(dl$iso3c), uniqueN(dl[iso3c != "RWA"]$iso3c))
)
print(r)
fwrite(r, file.path(BASE, "results/tables/LGH2_doseresponse_labelled.csv"))
cat("\nSaved: LGH2_doseresponse_labelled.csv\n")
