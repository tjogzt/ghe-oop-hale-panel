# Fix S3 (forest plot) and S4 (temporal aggregation) with Wong palette
library(data.table)
library(ggplot2)

PROJ <- "/Users/taozhu/my researches/lancet_financial_v3"
setwd(PROJ)

PAL_SIG <- c("p<0.01"="#D55E00","p<0.05"="#E69F00","p<0.10"="#0072B2","n.s."="grey50")
PAL_INCOME <- c(
  "Low income"="#E69F00","Lower middle income"="#56B4E9",
  "Upper middle income"="#009E73","High income"="#CC79A7"
)

theme_lancet <- theme_bw(base_size=10) + theme(
  panel.grid.minor=element_blank(),
  plot.title=element_text(face="bold",size=11),
  axis.title=element_text(size=9.5),
  axis.text=element_text(size=8),
  legend.text=element_text(size=8),
  legend.position="bottom"
)

# ---- S3: Coefficient Forest Plot ----
cat("=== Figure S3: Forest Plot ===\n")

main <- fread("results/tables/main_results.csv")
income <- fread("results/tables/income_heterogeneity.csv")

forest <- rbind(
  main[, .(Model=Model, Coef=Coef, SE=SE, P=P)],
  income[, .(Model=paste0("  ",income_group), Coef=coef, SE=se, P=p)]
)
forest[, `:=`(ci_low=Coef-1.96*SE, ci_high=Coef+1.96*SE)]
forest[, sig := ifelse(P<0.01,"p<0.01",ifelse(P<0.05,"p<0.05",ifelse(P<0.10,"p<0.10","n.s.")))]
forest[, Model := factor(Model, levels=rev(unique(Model)))]

p_forest <- ggplot(forest, aes(x=Coef, y=Model)) +
  geom_vline(xintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_point(aes(color=sig), size=3.5) +
  geom_errorbarh(aes(xmin=ci_low, xmax=ci_high, color=sig), height=0.25, linewidth=1.2) +
  scale_color_manual(values=PAL_SIG) +
  labs(x="GHE coefficient (years HALE per %GDP)", y="",
       title="GHE-HALE Association Across Specifications",
       color="") +
  theme_lancet
ggsave("results/figures/fig2_forest.pdf", p_forest, width=8, height=5.5, device=cairo_pdf)
cat("Saved: fig2_forest.pdf\n")

# ---- S4: Temporal Aggregation ----
cat("=== Figure S4: Temporal Aggregation ===\n")

comp <- fread("results/tables/advanced_analyses_summary.csv")
comp <- comp[1:5]  # first 5 rows: annual GHE/GDP, annual GHE pc, 5yr GHE/GDP, 5yr GHE pc, 10yr GHE/GDP

comp[, Specification := c(
  "Annual TWFE\n(GHE/GDP)","Annual TWFE\n(GHE pc PPP)",
  "5-year TWFE\n(GHE/GDP)","5-year TWFE\n(GHE pc PPP)",
  "10-year TWFE\n(GHE/GDP)"
)]
comp[, `:=`(ci_low=Coefficient-1.96*SE, ci_high=Coefficient+1.96*SE)]
comp[, sig := ifelse(P<0.05,"p<0.05",ifelse(P<0.10,"p<0.10","n.s."))]
comp[, Specification := factor(Specification, levels=rev(Specification))]

p_temp <- ggplot(comp, aes(x=Coefficient, y=Specification)) +
  geom_vline(xintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_point(aes(color=sig), size=3.5) +
  geom_errorbarh(aes(xmin=ci_low, xmax=ci_high, color=sig), height=0.25, linewidth=1.2) +
  scale_color_manual(values=PAL_SIG) +
  labs(x="GHE Coefficient", y="",
       title="Temporal Aggregation: Annual vs 5yr vs 10yr Panels",
       subtitle="Consistent null/negative finding regardless of time structure",
       color="") +
  theme_lancet
ggsave("results/figures/fig8_temporal_aggregation.pdf", p_temp, width=7.5, height=4, device=cairo_pdf)
cat("Saved: fig8_temporal_aggregation.pdf\n")

cat("=== Done ===\n")
