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
main[, Label := c("Pooled OLS (full controls)", "Country FE only", "TWFE (primary)",
                  "TWFE + governance", "Long-difference OLS")[match(Model,
                  c("M1_Pooled_OLS","M2_Country_FE","M3_TWFE","M4_TWFE_Governance","LongDiff_OLS"))]]
# Pre-COVID TWFE from B4 (Table 1 Model 8 counterpart)
b4 <- fread("results/tables/B4_precovid_comparison.csv")
main <- rbind(main,
              data.table(Model="Pre-COVID TWFE", Label="Pre-COVID TWFE", Term="ghe_share_gdp",
                         Coef=b4[Model=="TWFE (primary)", PreCOVID_coef],
                         SE=b4[Model=="TWFE (primary)", PreCOVID_se],
                         P=b4[Model=="TWFE (primary)", PreCOVID_p], N=3743),
              fill=TRUE)

income <- fread("results/tables/income_heterogeneity.csv")

forest <- rbind(
  main[, .(Model=Label, Coef=Coef, SE=SE, P=P)],
  income[, .(Model=paste0("  ",income_group), Coef=coef, SE=se, P=p)]
)
# Low-income colour: use the cluster-bootstrap p (0.065; primary inference, 23 clusters)
# rather than the conventional clustered p (0.030), consistent with the main text.
forest[Model=="  Low income", P := 0.065]
forest[, `:=`(ci_low=Coef-1.96*SE, ci_high=Coef+1.96*SE)]
forest[, sig := ifelse(P<0.01,"p<0.01",ifelse(P<0.05,"p<0.05",ifelse(P<0.10,"p<0.10","n.s.")))]
forest[, Model := factor(Model, levels=rev(unique(Model)))]

p_forest <- ggplot(forest, aes(x=Coef, y=Model)) +
  geom_vline(xintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_hline(yintercept=6.5, linetype="dotted", color="grey60", linewidth=0.4) +
  geom_point(aes(color=sig), size=3.5) +
  geom_errorbarh(aes(xmin=ci_low, xmax=ci_high, color=sig), height=0.25, linewidth=1.0) +
  scale_color_manual(values=PAL_SIG, breaks=c("p<0.05","p<0.10","n.s.")) +
  scale_x_continuous(limits=c(-0.7, 1.7), breaks=seq(-0.5, 1.5, 0.5)) +
  labs(x="GHE coefficient (years HALE per %GDP)", y="",
       color="Significance") +
  theme_lancet
ggsave("results/figures/figS3_forest.pdf", p_forest, width=8, height=5.5, device=cairo_pdf)
cat("Saved: figS3_forest.pdf\n")

# ---- S4: Temporal Aggregation ----
cat("=== Figure S4: Temporal Aggregation ===\n")

comp <- fread("results/tables/advanced_analyses_summary.csv")
comp <- comp[1:6]  # 5yr GHE/GDP, 5yr pc, 10yr GHE/GDP, 10yr pc, Annual GHE/GDP, Annual pc
# Reorder to match specification labels (CSV order differs from display order)
comp <- comp[match(c("Annual TWFE (GHE/GDP)","Annual TWFE (GHE pc PPP)",
                     "5yr TWFE (GHE/GDP)","5yr TWFE (GHE pc PPP)",
                     "10yr TWFE (GHE/GDP)","10yr TWFE (GHE pc PPP)"),
                   Analysis)]

comp[, Specification := c(
  "Annual TWFE\n(GHE/GDP)","Annual TWFE\n(GHE pc PPP)",
  "5-year TWFE\n(GHE/GDP)","5-year TWFE\n(GHE pc PPP)",
  "10-year TWFE\n(GHE/GDP)","10-year TWFE\n(GHE pc PPP)"
)]
comp[, `:=`(ci_low=Coefficient-1.96*SE, ci_high=Coefficient+1.96*SE)]
comp[, sig := ifelse(P<0.05,"p<0.05",ifelse(P<0.10,"p<0.10","n.s."))]
comp[, Specification := factor(Specification, levels=rev(Specification))]

p_temp <- ggplot(comp, aes(x=Coefficient, y=Specification)) +
  geom_vline(xintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_hline(yintercept=4.5, linetype="dotted", color="grey60", linewidth=0.4) +
  geom_hline(yintercept=2.5, linetype="dotted", color="grey60", linewidth=0.4) +
  geom_point(aes(color=sig), size=3.5) +
  geom_errorbarh(aes(xmin=ci_low, xmax=ci_high, color=sig), height=0.25, linewidth=1.0) +
  scale_color_manual(values=PAL_SIG, breaks=c("p<0.05","p<0.10","n.s.")) +
  scale_x_continuous(limits=c(-0.8, 0.6), breaks=seq(-0.8, 0.6, 0.4)) +
  labs(x="GHE coefficient (years HALE per %GDP)", y="",
       color="Significance") +
  theme_lancet
ggsave("results/figures/figS4_temporal_aggregation.pdf", p_temp, width=7.5, height=4, device=cairo_pdf)
cat("Saved: figS4_temporal_aggregation.pdf\n")

cat("=== Done ===\n")
