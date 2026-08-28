# Figure 2 v2 — 3-panel 彩色重绘(边际直方图 + Wong 色 + 真实 r 值)
# 输出 fig1_longdiff_v2.pdf(不覆盖主稿 bw 版)
suppressMessages({library(data.table); library(ggplot2)})
set.seed(49)

PAL_INCOME <- c("Low income"="#9D2933","Lower middle income"="#C23531",
                "Upper middle income"="#177CB0","High income"="#3D6BA8")
SHAPE_INCOME <- c("Low income"=16,"Lower middle income"=17,
                  "Upper middle income"=15,"High income"=18)

df <- fread("/Volumes/tjogzt4T/lancet_financial_v2/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
# 与 01_main_analysis.R 的 df_analysis 同口径(含 ln_gdppc 非缺失)——确保 N 与 Table 1 Model 7 一致
df <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(urbanization) & !is.na(fertility_rate) & !is.na(gdp_per_capita_ppp)]
setorder(df, iso3c, year)

# ---- Panel A: long difference (span >= 15, 与主稿一致) ----
first <- df[, .SD[1], by=iso3c]
last  <- df[, .SD[.N], by=iso3c]
ld <- merge(first[, .(iso3c, country, income, hale_0=hale, ghe_0=ghe_share_gdp, year_0=year)],
            last[, .(iso3c, hale_T=hale, ghe_T=ghe_share_gdp, year_T=year)], by="iso3c")
ld[, `:=`(d_hale=hale_T-hale_0, d_ghe=ghe_T-ghe_0, span=year_T-year_0)]
ld <- ld[span >= 15]
ld <- ld[abs(d_hale) < 25]  # 排除异常
rA <- cor(ld$d_ghe, ld$d_hale)
nA <- nrow(ld)
cat(sprintf("Panel A: N=%d, r=%.3f\n", nA, rA))

# ---- Panel B: between-country means ----
df[, `:=`(ghe_mean=mean(ghe_share_gdp), hale_mean=mean(hale)), by=iso3c]
between_data <- unique(df[, .(iso3c, income, ghe_mean, hale_mean)])
rB <- cor(between_data$ghe_mean, between_data$hale_mean)
cat(sprintf("Panel B: N=%d, r=%.3f\n", nrow(between_data), rB))

# ---- Panel C: within-country residuals (partial r, primary-model covariates) ----
library(fixest)
df[, ln_gdppc := log(gdp_per_capita_ppp)]
fit_g <- feols(ghe_share_gdp ~ ln_gdppc + urbanization + fertility_rate | iso3c + year, data=df, vcov=~iso3c)
fit_h <- feols(hale ~ ln_gdppc + urbanization + fertility_rate | iso3c + year, data=df, vcov=~iso3c)
resid_data <- data.table(ghe_r=resid(fit_g), hale_r=resid(fit_h))
rC <- cor(resid_data$ghe_r, resid_data$hale_r)
cat(sprintf("Panel C: N=%d, partial r=%.3f\n", nrow(resid_data), rC))

theme_pub2 <- theme_bw(base_size=10) +
  theme(panel.grid.minor=element_blank(),
        panel.grid.major=element_line(linewidth=0.2, color="grey90"),
        axis.title=element_text(size=10), axis.text=element_text(size=8.5),
        legend.text=element_text(size=8.5), legend.title=element_text(size=9),
        plot.margin=margin(8,8,8,8))

# ---- Panel A 带边际直方图 ----
pa <- ggplot(ld, aes(x=d_ghe, y=d_hale)) +
  geom_hline(yintercept=0, linetype="dashed", color="grey60", linewidth=0.3) +
  geom_vline(xintercept=0, linetype="dashed", color="grey60", linewidth=0.3) +
  geom_point(aes(color=income, shape=income), size=2.2, alpha=0.8) +
  geom_smooth(method="lm", se=TRUE, color="grey30", linewidth=0.8, alpha=0.15, fill="grey70") +
  scale_color_manual(values=PAL_INCOME, name="Income group") +
  scale_shape_manual(values=SHAPE_INCOME, name="Income group") +
  labs(x="Change in GHE share (pp GDP, first to last year)", y="Change in HALE (years)",
       subtitle=sprintf("A.  Long difference:  r = %.2f  (N = %d countries)", rA, nA)) +
  ggside::geom_xsidehistogram(aes(fill=income), bins=24, alpha=0.5, position="identity") +
  ggside::geom_ysidehistogram(aes(fill=income), bins=24, alpha=0.5, position="identity") +
  scale_fill_manual(values=PAL_INCOME, guide="none") +
  theme_pub2 + theme(legend.position="bottom",
                     ggside.panel.scale=0.20) +
  guides(color=guide_legend(nrow=1))

# ---- Panel B ----
pb <- ggplot(between_data, aes(x=ghe_mean, y=hale_mean)) +
  geom_point(aes(color=income, shape=income), size=3, alpha=0.7) +
  geom_smooth(method="lm", se=TRUE, color="grey30", linewidth=0.8, alpha=0.15, fill="grey70") +
  scale_color_manual(values=PAL_INCOME, name="Income group") +
  scale_shape_manual(values=SHAPE_INCOME, name="Income group") +
  labs(x="Country mean GHE (% GDP)", y="Country mean HALE (years)",
       subtitle=sprintf("B.  Between-country means:  r = %.2f\n(N = %d countries)", rB, nrow(between_data))) +
  theme_pub2 + theme(legend.position="none")

# ---- Panel C ----
pc <- ggplot(resid_data, aes(x=ghe_r, y=hale_r)) +
  geom_point(color="#0072B2", size=1.5, alpha=0.25) +
  geom_smooth(method="lm", se=TRUE, color="grey30", linewidth=0.8, alpha=0.15, fill="grey70") +
  labs(x="Residualised within-country\nGHE deviation (pp GDP)",
       y="Residualised within-country\nHALE deviation (years)",
       subtitle="C.  Within-country:  partial r = -0.07") +
  theme_pub2 + theme(legend.position="none")

# ---- 组合:2 行 2 列(A 独占第一行,B/C 并排第二行) ----
library(patchwork)
p_fig2 <- (pa / (pb | pc)) + plot_layout(heights=c(1.25, 1))
ggsave("results/figures/fig2_longdiff_v2.pdf", p_fig2, width=170, height=200, units="mm", device=cairo_pdf)
cat("Saved: fig2_longdiff_v2.pdf\n")
