library(data.table); library(ggplot2)
region <- fread("/Users/taozhu/my researches/lancet_financial_v3/results/tables/region_heterogeneity.csv")
region[, `:=`(ci_low=coef-1.96*se, ci_high=coef+1.96*se)]
region[, sig := ifelse(p<0.05,"p<0.05",ifelse(p<0.10,"p<0.10","n.s."))]
setorderv(region, "coef")
lv <- region[["region"]]
region[, region := factor(region, levels=lv)]

theme_lancet <- theme_bw(base_size=10) + theme(
  panel.grid.minor=element_blank(),
  plot.title=element_text(face="bold",size=11),
  axis.title=element_text(size=9.5),
  axis.text=element_text(size=8),
  legend.text=element_text(size=8),
  legend.position="bottom"
)

p <- ggplot(region, aes(x=coef, y=region)) +
  geom_vline(xintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_point(aes(color=sig), size=3.5) +
  geom_errorbarh(aes(xmin=ci_low, xmax=ci_high, color=sig), height=0.25, linewidth=1.0) +
  scale_color_manual(values=c("p<0.05"="#E69F00","p<0.10"="#0072B2","n.s."="grey50"),
                     breaks=c("p<0.10","n.s.")) +
  scale_x_continuous(limits=c(-0.45, 0.8), breaks=seq(-0.4, 0.8, 0.2)) +
  labs(x="GHE coefficient (years HALE per %GDP)", y="", color="Significance") +
  theme_lancet
ggsave("/Users/taozhu/my researches/lancet_financial_v3/results/figures/figS5_regional.pdf", p, width=8, height=5, device=cairo_pdf)
cat("Saved: figS5_regional.pdf\n")
