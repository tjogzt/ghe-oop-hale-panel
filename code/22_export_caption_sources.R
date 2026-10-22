#!/usr/bin/env Rscript
# 补齐图注里四个此前无数据源的数字:
#   1) 治理复合指数的 Cronbach alpha (Figure 1 caption: 0.97)
#   2) 长差分 Pearson r (Figure 3 caption: -0.22)
#   3) 长差分回归 95% CI 下界/上界 (Figure 3 caption: -0.95 ~ -0.18)
#   4) GHE 的 unique within-R2 (Figure 4 caption: 0.007)
suppressMessages({library(data.table); library(fixest)})
BASE <- "/Users/taozhu/my researches/lancet_financial_v3"

# ---------------- 1. Cronbach alpha (6 个 WGI 维度) ----------------
df <- fread(file.path(BASE, "data/processed/integrated_panel_final.csv"))
dims <- c("voice_accountability", "political_stability", "government_effectiveness",
          "regulatory_quality", "rule_of_law", "control_of_corruption")
m <- df[, ..dims]
m <- m[complete.cases(m)]
k <- ncol(m)
item_var <- sapply(m, var)
total_var <- var(rowSums(m))
alpha <- k / (k - 1) * (1 - sum(item_var) / total_var)
cat(sprintf("Cronbach alpha: %.4f  (k=%d 项, N=%d 观测)\n", alpha, k, nrow(m)))
fwrite(data.table(n_items = k, n_obs = nrow(m), cronbach_alpha = alpha),
       file.path(BASE, "results/tables/governance_cronbach_alpha.csv"))

# ---------------- 2 & 3. 长差分 r 与回归 CI ----------------
ld <- fread(file.path(BASE, "results/tables/supplementary/Table_S6_LongDifference.csv"))
ld <- ld[!is.na(d_hale) & !is.na(d_ghe)]
r <- cor(ld$d_hale, ld$d_ghe)
n_ld <- nrow(ld)
cat(sprintf("长差分 Pearson r = %.4f  (N=%d)\n", r, n_ld))

mr <- fread(file.path(BASE, "results/tables/main_results.csv"))
ld_row <- mr[Model == "LongDiff_OLS"]
b <- ld_row$Coef; se <- ld_row$SE; N <- ld_row$N
df_resid <- N - 2                      # 截距 + d_ghe
tcrit <- qt(0.975, df_resid)
lo <- b - tcrit * se; hi <- b + tcrit * se
cat(sprintf("长差分 beta = %.4f (SE %.4f), t(%.0f)=%.4f, 95%% CI [%.4f, %.4f]\n",
            b, se, df_resid, tcrit, lo, hi))

fwrite(data.table(n_countries = n_ld, pearson_r = r,
                  beta = b, se = se, df_resid = df_resid, t_crit = tcrit,
                  ci_low = lo, ci_high = hi),
       file.path(BASE, "results/tables/longdiff_r_and_ci.csv"))

# ---------------- 4. GHE 的 unique within-R2 ----------------
# 与 Figure 4 同一模型:5 个决定因素 z 标准化, TWFE
zs <- c("ghe_share_gdp", "gdp_per_capita_ppp", "urbanization",
        "fertility_rate", "governance_composite")
dd <- df[!(region %in% c("Aggregates", "") | income %in% c("Aggregates", "Not classified", ""))]
dd <- dd[!is.na(hale) & complete.cases(dd[, ..zs])]
for (v in zs) dd[, (paste0("z_", v)) := scale(get(v))]
dd[, ln_gdppc := log(gdp_per_capita_ppp)]
# gdp 用 log 后再标准化(与主稿一致:log GDP pc 进入模型)
dd[, z_gdp_per_capita_ppp := scale(ln_gdppc)]

full_f <- as.formula(paste("hale ~", paste(paste0("z_", zs), collapse = " + "), "| iso3c + year"))
red_f  <- as.formula(paste("hale ~", paste(paste0("z_", setdiff(zs, "ghe_share_gdp")), collapse = " + "), "| iso3c + year"))
m_full <- feols(full_f, data = dd, vcov = ~iso3c)
m_red  <- feols(red_f,  data = dd, vcov = ~iso3c)
# 图注说的是 unique WITHIN-R2(TWFE 下的组内拟合),不是 overall R2。
# 两者差 27 倍(0.0003 vs 0.0090),用错口径会让图注数字看似离谱。
r2_full <- fitstat(m_full, "wr2")$wr2
r2_red  <- fitstat(m_red,  "wr2")$wr2
unique_r2 <- r2_full - r2_red
cat(sprintf("unique within-R2 (GHE) = %.5f  (full R2 %.5f - reduced %.5f, N=%d)\n",
            unique_r2, r2_full, r2_red, nobs(m_full)))

fwrite(data.table(N = nobs(m_full),
                  r2_full = r2_full, r2_reduced = r2_red,
                  unique_r2_ghe = unique_r2,
                  ghe_coef = coef(m_full)["z_ghe_share_gdp"],
                  ghe_p = pvalue(m_full)["z_ghe_share_gdp"]),
       file.path(BASE, "results/tables/horserace_unique_r2.csv"))

cat("\nSaved: governance_cronbach_alpha.csv / longdiff_r_and_ci.csv / horserace_unique_r2.csv\n")
