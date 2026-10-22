#!/usr/bin/env Rscript
# Figure 2 重建数据层:
#   1) 事件研究扩到 k = -5..+5,输出全部 lead/lag 系数
#   2) 分组 pre-trend 联合检验(手工 Wald,因 fixest::wald() 在本机返回 NULL)
#   3) k=+5 处两组系数差异检验 (H0: beta_true = beta_denom)
# 复用 /tmp/a_expand_split.R 的事件定义与 stacked cohort 设定,口径不变。
suppressMessages({library(data.table); library(fixest)})
set.seed(49)
BASE <- "/Users/taozhu/my researches/lancet_financial_v3"

df <- fread(file.path(BASE, "data/processed/integrated_panel_final.csv"))
df <- df[!(region %in% c("Aggregates", "") | income %in% c("Aggregates", "Not classified", ""))]
df[, `:=`(ln_gdppc = log(gdp_per_capita_ppp),
          ghe_pc   = ghe_share_gdp / 100 * gdp_per_capita_ppp)]
df[, ln_ghe_pc := log(ghe_pc)]
d <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc) & !is.na(ln_ghe_pc) &
          !is.na(urbanization) & !is.na(fertility_rate)]
setorder(d, iso3c, year)                      # 铁律:lag 前必须排序
cat("样本:", nrow(d), "行,", uniqueN(d$iso3c), "国\n\n")

# ---------- 事件定义(与原分析完全一致) ----------
d[, ghe_chg3 := ghe_share_gdp - shift(ghe_share_gdp, 3), by = iso3c]
ev <- d[!is.na(ghe_chg3) & ghe_chg3 > 2, .(event_year = min(year)), by = iso3c]
cat("扩张事件(3 年内 +2pp):", nrow(ev), "国\n")

ev[, dln_pc := NA_real_]
for (i in seq_len(nrow(ev))) {
  s <- ev$iso3c[i]; ey <- ev$event_year[i]
  pre  <- d[iso3c == s & year %in% (ey - 3):(ey - 1), ln_ghe_pc]
  post <- d[iso3c == s & year %in% ey:(ey + 2), ln_ghe_pc]
  if (length(pre) >= 2 && length(post) >= 2)
    ev$dln_pc[i] <- mean(post, na.rm = TRUE) - mean(pre, na.rm = TRUE)
}
med <- median(ev$dln_pc, na.rm = TRUE)
ev[, group := fifelse(dln_pc >= med, "true_expansion", "denominator_driven")]
cat(sprintf("中位 Δln(人均 GHE) = %+.6f\n", med))
cat(sprintf("  真扩张 %d 国, 分母驱动 %d 国, 无法分组(缺 dln_pc) %d 国\n",
            sum(ev$group == "true_expansion", na.rm = TRUE),
            sum(ev$group == "denominator_driven", na.rm = TRUE),
            sum(is.na(ev$group))))
cat("  无法分组明细:", paste(ev[is.na(group), paste0(iso3c, "-", event_year)], collapse = ", "), "\n\n")

# ---------- 分组事件研究,输出 k = -5..+5 ----------
treated  <- ev$iso3c
ctrl_all <- setdiff(unique(d$iso3c), treated)
KS <- c(-5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5)

evres  <- data.table()
ptres  <- data.table()
fits   <- list()

for (grp in c("true_expansion", "denominator_driven")) {
  g <- ev[group == grp]
  panels <- list()
  for (i in seq_len(nrow(g))) {
    iso_i <- g$iso3c[i]; ey <- g$event_year[i]
    sub <- d[iso3c %in% c(iso_i, ctrl_all) & year %in% (ey - 5):(ey + 5),
             .(iso3c, year, hale, ln_gdppc, urbanization, fertility_rate)]
    if (nrow(sub) < 100) next
    sub[, `:=`(cohort = i, treated = as.integer(iso3c == iso_i), t_rel = year - ey)]
    panels[[length(panels) + 1]] <- sub
  }
  st <- rbindlist(panels, fill = TRUE)
  st[, `:=`(coh_iso  = paste(cohort, iso3c),
            coh_year = paste(cohort, year),
            t_rel_f  = relevel(factor(t_rel), ref = "-5"))]
  m <- feols(hale ~ i(t_rel_f, ref = "-5"):treated + ln_gdppc + urbanization + fertility_rate |
               coh_iso + coh_year, data = st, vcov = ~coh_iso)
  fits[[grp]] <- m
  ct <- coeftable(m); rn <- rownames(ct)

  for (k in KS) {
    if (k == -5) {                       # 参考期,系数恒为 0
      evres <- rbind(evres, data.table(group = grp, k = k, beta = 0, se = 0,
                                       p = NA_real_, is_ref = TRUE,
                                       N = nobs(m), n_cohort = uniqueN(st$cohort)))
      next
    }
    idx <- which(rn == paste0("t_rel_f::", k, ":treated"))
    if (!length(idx)) {
      cat(sprintf("  WARN: %s k=%+d 系数未找到\n", grp, k))
      next
    }
    evres <- rbind(evres, data.table(group = grp, k = k,
                                     beta = ct[idx, 1], se = ct[idx, 2], p = ct[idx, 4],
                                     is_ref = FALSE, N = nobs(m), n_cohort = uniqueN(st$cohort)))
  }

  # ---- pre-trend 联合检验: k = -4..-1 全为 0 ----
  b <- coef(m); V <- vcov(m)
  lead_idx <- which(names(b) %in% paste0("t_rel_f::", c(-4, -3, -2, -1), ":treated"))
  q <- length(lead_idx)
  W <- as.numeric(t(b[lead_idx]) %*% solve(V[lead_idx, lead_idx, drop = FALSE]) %*% b[lead_idx])
  df2 <- m$nobs - length(b)
  p_joint <- pf(W / q, q, df2, lower.tail = FALSE)
  ptres <- rbind(ptres, data.table(group = grp, n_lead = q,
                                   wald = W, F = W / q, df1 = q, df2 = df2,
                                   p_joint = p_joint,
                                   lead_min = min(b[lead_idx]), lead_max = max(b[lead_idx]),
                                   n_cohort = uniqueN(st$cohort)))
  cat(sprintf("[%s] cohorts=%d N=%d | pre-trend Wald F(%d,%d)=%.3f p=%.4f | lead 范围 %.3f~%.3f\n",
              grp, uniqueN(st$cohort), nobs(m), q, df2, W / q, p_joint,
              min(b[lead_idx]), max(b[lead_idx])))
}

fwrite(evres, file.path(BASE, "results/tables/event_split_full.csv"))
fwrite(ptres, file.path(BASE, "results/tables/event_split_pretrend.csv"))

# ---------- k=+5 两组差异检验 ----------
b5 <- evres[k == 5]
if (nrow(b5) == 2) {
  b1 <- b5[group == "true_expansion"]; b2 <- b5[group == "denominator_driven"]
  diff <- b1$beta - b2$beta
  se   <- sqrt(b1$se^2 + b2$se^2)
  z    <- diff / se
  p    <- 2 * pnorm(-abs(z))
  dt <- data.table(k = 5, beta_true = b1$beta, beta_denom = b2$beta,
                   diff = diff, se_diff = se, z = z, p_diff = p,
                   ci_lo = diff - 1.96 * se, ci_hi = diff + 1.96 * se)
  fwrite(dt, file.path(BASE, "results/tables/event_split_diff_test.csv"))
  cat(sprintf("\nk=+5 差异检验: Δ=%.3f (SE %.3f), z=%.2f, p=%.4f, 95%%CI [%.2f, %.2f]\n",
              diff, se, z, p, dt$ci_lo, dt$ci_hi))
}

cat("\nSaved: event_split_full.csv / event_split_pretrend.csv / event_split_diff_test.csv\n")
cat("中位数(供图中参考线):", sprintf("%.6f", med), "\n")
