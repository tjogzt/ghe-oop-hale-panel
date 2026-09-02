#!/usr/bin/env Rscript
# Figure 3 v2 —— 去顶部/右侧边框(保留底/左轴线)
# 只重绘 horse race(p5 逻辑),不重跑 14_unified_figures.R 其他图
suppressMessages({library(data.table); library(ggplot2)})
set.seed(49)

PAL_SIG <- c("p<0.01"="#C23531", "p<0.05"="#177CB0", "p<0.10"="#3D6BA8")

theme_fig3 <- theme_bw(base_size=10) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(linewidth=0.2, color="grey90"),
    legend.key.size = unit(0.4, "cm"),
    legend.key.width = unit(0.6, "cm"),
    plot.title = element_text(face="bold", size=11),
    plot.subtitle = element_text(size=8.5, color="grey40"),
    axis.title = element_text(size=9.5),
    axis.text = element_text(size=8),
    legend.text = element_text(size=8),
    legend.title = element_text(size=8.5),
    plot.margin = margin(8,8,8,8),
    panel.border = element_blank(),               # 去矩形边框(顶/右侧随之消失)
    axis.line = element_line(color="grey30", linewidth=0.4)  # 保留底/左轴线
  )

horse <- fread("results/tables/C4_horse_race_main.csv")
# 标签统一(英式拼写 + log 标注)——先重命名值再设因子顺序
horse[, Variable := fcase(
  Variable == "Urbanization", "Urbanisation",
  Variable == "GDP per capita", "GDP per capita (log)",
  default = Variable)]
horse[, Variable := factor(Variable, levels=c("Fertility","GHE","GDP per capita (log)","Governance","Urbanisation"))]
horse[, sig := ifelse(P<0.01,"p<0.01",ifelse(P<0.05,"p<0.05",ifelse(P<0.10,"p<0.10","n.s.")))]

p5 <- ggplot(horse, aes(x=Coef, y=Variable)) +
  geom_vline(xintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_point(aes(color=sig), size=3.5) +
  geom_errorbarh(aes(xmin=ci_low, xmax=ci_high, color=sig), height=0.25, linewidth=1.2) +
  scale_color_manual(values=PAL_SIG) +
  scale_x_continuous(limits=c(-0.4, 0.6), breaks=seq(-0.4, 0.6, 0.2)) +
  labs(x="Standardised coefficient (SD change in HALE per SD change in predictor)", y="",
       color="") +
  theme_fig3
ggsave("results/figures/C4_horse_race.pdf", p5, width=170, height=97.1, units="mm", device=cairo_pdf)
file.copy("results/figures/C4_horse_race.pdf", "results/figures/fig3_horserace.pdf", overwrite=TRUE)
cat("Saved: fig3_horserace.pdf (no top/right border)\n")
