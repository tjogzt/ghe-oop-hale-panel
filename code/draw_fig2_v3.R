#!/usr/bin/env Rscript
# Figure 2 v3 — 按 MoA 评审重建
#   A 面板: 28 个可分组事件的双行 strip plot + 中位数分组线 + jitter + 彩色类别标签(n)
#   B 面板: 事件研究分面(左右各一栏,共享 y 轴),消除 CI 重叠
#   全部字体 >= 8pt(印刷尺寸 180mm 宽,1:1 插入)
suppressMessages({library(data.table); library(ggplot2); library(patchwork)})
BASE <- "/Users/taozhu/my researches/lancet_financial_v3"

full <- fread(file.path(BASE, "results/tables/event_split_full.csv"))
pt   <- fread(file.path(BASE, "results/tables/event_split_pretrend.csv"))
grp  <- fread(file.path(BASE, "results/tables/event_groups.csv"))
diff <- fread(file.path(BASE, "results/tables/event_split_diff_test.csv"))

MEDIAN <- median(grp$dln_pc, na.rm = TRUE)   # 0.411377
N_GRP  <- grp[!is.na(dln_pc), .N, by = group]
n_true <- N_GRP[group == "true_expansion", N]
n_den  <- N_GRP[group == "denominator_driven", N]
N_ALL  <- nrow(grp)

ZHU <- "#C23531"; SHI <- "#3D6BA8"; GREY <- "grey45"

full[, grp_lab := factor(fifelse(group == "true_expansion",
                                 sprintf("Real spending rose (n = %d)", n_true),
                                 sprintf("Ratio rose, GDP fell (n = %d)", n_den)),
                         levels = c(sprintf("Real spending rose (n = %d)", n_true),
                                    sprintf("Ratio rose, GDP fell (n = %d)", n_den)))]
full[, `:=`(lo = beta - 1.96 * se, hi = beta + 1.96 * se)]
full[is_ref == TRUE, `:=`(lo = 0, hi = 0)]

p_pt <- function(g) pt[group == g, p_joint]
lab_true <- sprintf("Real spending rose (n = %d)\npre-trend joint p = %.2f", n_true, p_pt("true_expansion"))
lab_den  <- sprintf("Ratio rose, GDP fell (n = %d)\npre-trend joint p = %.2f", n_den,  p_pt("denominator_driven"))
full[, facet_lab := factor(fifelse(group == "true_expansion", lab_true, lab_den),
                           levels = c(lab_true, lab_den))]

# ---------------- B 面板: 分面事件研究 ----------------
pb <- ggplot(full, aes(x = k, y = beta, colour = grp_lab, fill = grp_lab)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey55", linewidth = 0.45) +
  geom_vline(xintercept = -0.5, linetype = "dotted", colour = "grey55", linewidth = 0.45) +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.16, colour = NA) +
  geom_line(linewidth = 0.85) +
  geom_point(size = 2.1, shape = 21, stroke = 0.55, colour = "white") +
  facet_wrap(~ facet_lab, nrow = 1) +
  scale_colour_manual(values = c(ZHU, SHI), guide = "none") +
  scale_fill_manual(values = c(ZHU, SHI), guide = "none") +
  scale_x_continuous(breaks = c(-5, -3, 0, 2, 5), limits = c(-5.6, 5.6)) +
  scale_y_continuous(breaks = seq(-1.5, 1.5, 0.5), limits = c(-1.55, 1.55)) +
  labs(x = "Years relative to spending surge", y = "Change in HALE (years)",
       title = "B.  Post-surge HALE change by spending type") +
  theme_classic(base_size = 9, base_family = "Arial") +
  theme(strip.background = element_blank(),
        strip.text = element_text(size = 8.5, face = "bold", lineheight = 1.15),
        axis.text = element_text(size = 8),
        axis.title = element_text(size = 9),
        panel.spacing = unit(5, "mm"),
        plot.title = element_text(size = 9.5, face = "bold", margin = margin(b = 2)),
        plot.margin = margin(2, 3, 1, 1, "mm"))

# ---------------- A 面板: 分组散点 ----------------
gj <- grp[!is.na(dln_pc)]
gj[, grp_lab := factor(fifelse(group == "true_expansion",
                               sprintf("Real increase (n = %d)", n_true),
                               sprintf("Denominator-driven (n = %d)", n_den)),
                       levels = c(sprintf("Real increase (n = %d)", n_true),
                                  sprintf("Denominator-driven (n = %d)", n_den)))]

gj[, ypos := fifelse(group == "true_expansion", 2, 1)]
pa <- ggplot(gj, aes(x = dln_pc, y = ypos, colour = grp_lab)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey65", linewidth = 0.45) +
  geom_vline(xintercept = MEDIAN, linetype = "twodash", colour = "black", linewidth = 0.6) +
  annotate("text", x = MEDIAN, y = 2.60, label = sprintf("median split = %+.2f", MEDIAN),
           size = 2.9, hjust = -0.05, vjust = 0.5, colour = "black") +
  geom_point(size = 2.0, alpha = 0.85,
             position = position_jitter(height = 0.10, width = 0, seed = 49)) +
  scale_colour_manual(values = c(ZHU, SHI), guide = "none") +
  scale_x_continuous(breaks = c(-0.5, 0, 0.5, 1.0), limits = c(-0.55, 1.25)) +
  scale_y_continuous(breaks = c(1, 2), limits = c(0.45, 2.80),
                     labels = c(sprintf("Denominator-driven (n = %d)", n_den),
                                sprintf("Real increase (n = %d)", n_true))) +
  labs(x = "Change in log real per-capita spending", y = NULL,
       title = sprintf("A.  How the %d classifiable surges were split (n = %d each)", N_ALL - 1, n_true)) +
  theme_classic(base_size = 9, base_family = "Arial") +
  theme(plot.title = element_text(size = 9.5, face = "bold"),
        axis.text = element_text(size = 8),
        axis.title = element_text(size = 9),
        axis.text.y = element_text(colour = c(SHI, ZHU), size = 8, face = "bold"),
        plot.margin = margin(2, 3, 1, 1, "mm"))

# ---------------- 组装 ----------------
fig <- pa / pb + plot_layout(heights = c(0.62, 1.55)) +
  plot_annotation(
    caption = "Reference period k = -5. Bands are 95% CIs from cluster-robust SEs (clustered on country within cohort).",
    theme = theme(
      plot.caption = element_text(size = 8, family = "Arial", colour = GREY, hjust = 0,
                                  margin = margin(t = 2, unit = "mm")),
      plot.margin = margin(2, 3, 2, 3, "mm")))

W <- 168 / 25.4; H <- 142 / 25.4   # match journal text width
ggsave(file.path(BASE, "results/figures/fig2b_event_split_v3.pdf"), fig,
       width = W, height = H, device = cairo_pdf)
ggsave(file.path(BASE, "results/figures/png/fig2b_event_split_v3.png"), fig,
       width = W, height = H, dpi = 300)
cat(sprintf("Saved: fig2b_event_split_v3.pdf  (%.0f x %.0f mm)\n", W * 25.4, H * 25.4))
cat(sprintf("中位数线 = %.4f | 可分组 %d | 每组 %d / %d\n", MEDIAN, N_ALL - 1, n_true, n_den))
