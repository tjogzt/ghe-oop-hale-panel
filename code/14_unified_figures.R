# ============================================================================
# 14_unified_figures.R — Lancet色盲友好 + B&W可辨 + ≥7pt
# ============================================================================
set.seed(49)
options(scipen=999, warn=1)

library(data.table)
library(ggplot2)
library(scales)

PROJ <- "/Users/taozhu/my researches/lancet_financial_v3"
setwd(PROJ)

# ---- UNIFIED PALETTE (Wong 2011, colorblind-optimized) ----
PAL_INCOME <- c(
  "Low income"          = "#E69F00",  # orange
  "Lower middle income" = "#56B4E9",  # sky blue
  "Upper middle income" = "#009E73",  # bluish green
  "High income"         = "#CC79A7"   # reddish purple
)
SHAPE_INCOME <- c(
  "Low income"          = 17,  # triangle
  "Lower middle income" = 15,  # square
  "Upper middle income" = 18,  # diamond
  "High income"         = 16   # circle
)
PAL_SIG <- c("p<0.01"="#D55E00","p<0.05"="#E69F00","p<0.10"="#56B4E9","n.s."="grey50")

# ---- UNIFIED THEME (≥7pt, clean) ----
theme_lancet <- theme_bw(base_size=10) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(linewidth=0.2, color="grey90"),
    strip.background = element_rect(fill="grey95", colour=NA),
    legend.key.size = unit(0.4, "cm"),
    legend.key.width = unit(0.6, "cm"),
    plot.title = element_text(face="bold", size=11),
    plot.subtitle = element_text(size=8.5, color="grey40"),
    axis.title = element_text(size=9.5),
    axis.text = element_text(size=8),
    legend.text = element_text(size=8),
    legend.title = element_text(size=8.5),
    plot.margin = margin(8,8,8,8)
  )

# ---- Load data ----
df <- fread("/Volumes/tjogzt4T/lancet_financial_v2/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]
df_a <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]
df_a[, income_base := .SD[year==min(year), income[1]], by=iso3c]
df_a[, income_base := factor(income_base, levels=names(PAL_INCOME))]

cat("Data loaded:", nrow(df_a), "rows\n")

# ========================================================================
# MAIN FIGURE 1: Long Difference
# ========================================================================
setorder(df_a, iso3c, year)
first <- df_a[, .SD[1], by=iso3c]
last  <- df_a[, .SD[.N], by=iso3c]
ld <- merge(first[, .(iso3c,country,income=income_base,hale_0=hale,ghe_0=ghe_share_gdp,year_0=year)],
            last[, .(iso3c,hale_T=hale,ghe_T=ghe_share_gdp,year_T=year)], by="iso3c")
ld[, `:=`(d_hale=hale_T-hale_0, d_ghe=ghe_T-ghe_0, span=year_T-year_0)]
ld <- ld[span >= 15]

p1 <- ggplot(ld, aes(x=d_ghe, y=d_hale)) +
  geom_hline(yintercept=0, linetype="dashed", color="grey60", linewidth=0.3) +
  geom_vline(xintercept=0, linetype="dashed", color="grey60", linewidth=0.3) +
  geom_point(aes(color=income, shape=income), size=2.2, alpha=0.8) +
  geom_smooth(method="lm", se=TRUE, color="grey30", linewidth=0.7, alpha=0.15, fill="grey70") +
  scale_color_manual(values=PAL_INCOME, name="Income group") + theme(legend.text=element_text(size=8)) +
  scale_shape_manual(values=SHAPE_INCOME, name="Income group") +
  labs(x="Change in GHE (% GDP)", y="Change in HALE (years)",
       title="Long-difference: GHE vs HALE change (2000 to latest)",
       subtitle=paste0(sprintf("N=%d countries, r=%.2f, ", nrow(ld), cor(ld$d_ghe,ld$d_hale)),
                       sprintf("%d countries with GHE decline but HALE increase",
                               ld[d_ghe<=0 & d_hale>0, .N]))) +
  theme_lancet + theme(legend.position="bottom")
ggsave("results/figures/fig1_longdiff.pdf", p1, width=7, height=6, device=cairo_pdf)
cat("Fig1 saved\n")

# ========================================================================
# MAIN FIGURE 2: Event Study (GHE spikes)
# ========================================================================
df_a[, ghe_lag3 := shift(ghe_share_gdp, 3), by=iso3c]
df_a[, ghe_chg3 := ghe_share_gdp - ghe_lag3]
spike_events <- df_a[ghe_chg3 > 2, .(event_year=min(year)), by=iso3c]
df_a <- merge(df_a, spike_events, by="iso3c", all.x=TRUE)
df_a[!is.na(event_year), t_rel := year - event_year]
es_data <- df_a[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]
es_data <- es_data[!is.na(event_year) & t_rel >= -5 & t_rel <= 10]
es_data[, t_rel_f := factor(t_rel)]
es_data[, t_rel_f := relevel(t_rel_f, ref="-5")]

library(fixest)
es_fit <- feols(hale ~ i(t_rel_f, ref="-5") + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                data=es_data, vcov=~iso3c)
es_coefs <- data.table(
  t_rel = as.numeric(gsub("t_rel_f::","",names(coef(es_fit)))),
  coef = coef(es_fit), se = se(es_fit)
)
es_coefs <- es_coefs[!is.na(t_rel)]
es_coefs[, `:=`(ci_low=coef-1.96*se, ci_high=coef+1.96*se)]

p2 <- ggplot(es_coefs, aes(x=t_rel, y=coef)) +
  geom_hline(yintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_vline(xintercept=0, linetype="solid", color="#D55E00", linewidth=0.5) +
  geom_ribbon(aes(ymin=ci_low, ymax=ci_high), fill="#0072B2", alpha=0.12) +
  geom_line(color="#0072B2", linewidth=0.9) +
  geom_point(size=2.5, color="#0072B2") +
  annotate("text", x=0.3, y=max(es_coefs$ci_high,na.rm=TRUE)*0.9,
           label="GHE spike", color="#D55E00", size=3.5, fontface="italic", hjust=0) +
  labs(x="Years relative to GHE spike", y="HALE change (vs t-5)",
       title="Event study: HALE trajectory around GHE spike episodes",
       subtitle=paste0("N=", uniqueN(es_data$iso3c), " treated countries, TWFE with country+year FE")) +
  scale_x_continuous(breaks=seq(-5,10,2)) +
  theme_lancet
ggsave("results/figures/fig5_event_study.pdf", p2, width=7, height=5, device=cairo_pdf)
cat("Fig2 (event study) saved\n")

# ========================================================================
# MAIN FIGURE 3: Between vs Within
# ========================================================================
df_a[, `:=`(ghe_mean=mean(ghe_share_gdp), hale_mean=mean(hale)), by=iso3c]
df_a[, `:=`(ghe_dev=ghe_share_gdp-ghe_mean, hale_dev=hale-hale_mean)]

between_data <- unique(df_a[, .(iso3c, income=income_base, ghe_mean, hale_mean)])

theme_lancet_big <- theme_bw(base_size=10) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(linewidth=0.2, color="grey90"),
    plot.title = element_text(face="bold", size=12),
    axis.title = element_text(size=10),
    axis.text = element_text(size=8.5),
    legend.text = element_text(size=8.5),
    legend.title = element_text(size=9),
    plot.margin = margin(10,10,10,10)
  )

p3a <- ggplot(between_data, aes(x=ghe_mean, y=hale_mean)) +
  geom_point(aes(color=income, shape=income), size=3, alpha=0.7) +
  geom_smooth(method="lm", se=TRUE, color="grey30", linewidth=0.8, alpha=0.15, fill="grey70") +
  scale_color_manual(values=PAL_INCOME, name="Income group") + theme(legend.text=element_text(size=8)) +
  scale_shape_manual(values=SHAPE_INCOME, name="Income group") +
  labs(x="Mean GHE (%GDP)", y="Mean HALE (years)",
       title="BETWEEN countries  (r = 0.85)") +
  theme_lancet_big + theme(legend.position="bottom",
                            axis.text=element_text(size=9),
                            axis.title=element_text(size=10.5)) +
  guides(color=guide_legend(nrow=1))

p3b <- ggplot(df_a, aes(x=ghe_dev, y=hale_dev)) +
  geom_point(aes(color=income_base, shape=income_base), size=1.8, alpha=0.35) +
  geom_smooth(method="lm", se=TRUE, color="grey30", linewidth=0.8, alpha=0.15, fill="grey70") +
  scale_color_manual(values=PAL_INCOME) +
  scale_shape_manual(values=SHAPE_INCOME) +
  labs(x="GHE deviation from country mean", y="HALE deviation from country mean",
       title="WITHIN countries  (r = -0.02)") +
  theme_lancet_big + theme(legend.position="none",
                            axis.text=element_text(size=9),
                            axis.title=element_text(size=10.5))

# Extract shared legend from left panel
library(gtable)
tmp <- ggplot_gtable(ggplot_build(p3a))
leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
legend_grob <- tmp$grobs[[leg]]

# Arrange: two panels + shared legend below
p3 <- gridExtra::grid.arrange(
  gridExtra::arrangeGrob(p3a + theme(legend.position="none"), p3b, ncol=2),
  legend_grob, ncol=1, heights=c(10, 1)
)
ggsave("results/figures/fig4_between_within.pdf", p3, width=10, height=5, device=cairo_pdf)
cat("Fig3 (between/within) saved\n")

# ========================================================================
# MAIN FIGURE 4: Austerity Mirror
# ========================================================================
df_a[, ghe_chg3_neg := ghe_share_gdp - shift(ghe_share_gdp,3), by=iso3c]
aust_events <- df_a[ghe_chg3_neg < -1.5, .(event_year=min(year)), by=iso3c]
df_a <- merge(df_a, aust_events, by="iso3c", all.x=TRUE, suffixes=c("","_aust"))
df_a[!is.na(event_year_aust), aust_t_rel := year - event_year_aust]

aust_es_data <- df_a[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]
aust_es_data <- aust_es_data[!is.na(event_year_aust) & aust_t_rel >= -5 & aust_t_rel <= 10]
aust_es_data[, aust_f := factor(aust_t_rel)]
aust_es_data[, aust_f := relevel(aust_f, ref="-5")]

aust_fit <- feols(hale ~ i(aust_f, ref="-5") + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                  data=aust_es_data, vcov=~iso3c)
aust_coefs <- data.table(
  t_rel = as.numeric(gsub("aust_f::","",names(coef(aust_fit)))),
  coef = coef(aust_fit), se = se(aust_fit)
)
aust_coefs <- aust_coefs[!is.na(t_rel)]
aust_coefs[, `:=`(ci_low=coef-1.96*se, ci_high=coef+1.96*se, type="Austerity (>1.5pp decrease)")]
es_coefs[, type := "Spike (>2pp increase)"]
mirror_data <- rbind(es_coefs, aust_coefs)

p4 <- ggplot(mirror_data, aes(x=t_rel, y=coef, color=type, fill=type)) +
  geom_hline(yintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_vline(xintercept=0, linetype="solid", color="grey40", linewidth=0.5) +
  geom_ribbon(aes(ymin=ci_low, ymax=ci_high), alpha=0.1, color=NA) +
  geom_line(linewidth=0.9) +
  geom_point(size=2.2) +
  scale_color_manual(values=c("Spike (>2pp increase)"="#D55E00","Austerity (>1.5pp decrease)"="#0072B2")) +
  scale_fill_manual(values=c("Spike (>2pp increase)"="#D55E00","Austerity (>1.5pp decrease)"="#0072B2")) +
  labs(x="Years relative to event", y="HALE change (vs t-5)",
       title="GHE spike and austerity mirror analysis",
       subtitle=paste0("Spike: N=", uniqueN(es_data$iso3c), " countries; Austerity: N=", uniqueN(aust_es_data$iso3c)),
       color="", fill="") +
  scale_x_continuous(breaks=seq(-5,10,2)) +
  theme_lancet + theme(legend.position=c(0.15,0.12), 
                        legend.background=element_rect(fill=NA, color=NA),
                        legend.key=element_rect(fill=NA, color=NA))
ggsave("results/figures/B3_austerity_mirror.pdf", p4, width=7, height=5, device=cairo_pdf)
cat("Fig4 (austerity mirror) saved\n")

# ========================================================================
# SUPPLEMENTARY FIGURE S14: Dual-panel event studies (spikes | austerity)
# ========================================================================
mirror_data[, type_lab := ifelse(grepl("Spike", type),
                                 sprintf("A: GHE spikes (N = %d)", uniqueN(es_data$iso3c)),
                                 sprintf("B: Austerity episodes (N = %d)", uniqueN(aust_es_data$iso3c)))]
p_s14 <- ggplot(mirror_data, aes(x=t_rel, y=coef, color=type, fill=type)) +
  geom_hline(yintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_vline(xintercept=0, linetype="solid", color="grey40", linewidth=0.5) +
  geom_ribbon(aes(ymin=ci_low, ymax=ci_high), alpha=0.12, color=NA) +
  geom_line(linewidth=0.9) +
  geom_point(size=2.2) +
  facet_wrap(~type_lab, ncol=2, scales="fixed") +
  scale_color_manual(values=c("Spike (>2pp increase)"="#D55E00",
                              "Austerity (>1.5pp decrease)"="#0072B2")) +
  scale_fill_manual(values=c("Spike (>2pp increase)"="#D55E00",
                             "Austerity (>1.5pp decrease)"="#0072B2")) +
  scale_x_continuous(breaks=seq(-5, 10, 2)) +
  labs(x="Years since event", y="HALE change (years)") +
  theme_lancet + theme(legend.position="none")
ggsave("results/figures/figS14_event_austerity.pdf", p_s14, width=170, height=80, units="mm", device=cairo_pdf)
cat("FigS14 (dual-panel event studies) saved\n")

# ========================================================================
# MAIN FIGURE 5: Horse Race (standardized coefficients)
# ========================================================================
horse <- fread("results/tables/C4_horse_race_main.csv")
# 按绝对量级降序(顶部=最大):Urbanization > Fertility > Governance > GDP per capita > GHE
horse[, Variable := factor(Variable, levels=c("Fertility","GHE","GDP per capita","Governance","Urbanization"))]
horse[, sig := ifelse(P<0.01,"p<0.01",ifelse(P<0.05,"p<0.05",ifelse(P<0.10,"p<0.10","n.s.")))]

p5 <- ggplot(horse, aes(x=Coef, y=Variable)) +
  geom_vline(xintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_point(aes(color=sig), size=3.5) +
  geom_errorbarh(aes(xmin=ci_low, xmax=ci_high, color=sig), height=0.25, linewidth=1.2) +
  scale_color_manual(values=PAL_SIG) +
  scale_x_continuous(limits=c(-0.4, 0.6), breaks=seq(-0.4, 0.6, 0.2)) +
  labs(x="Standardised coefficient (SD change in HALE per SD change in predictor)", y="",
       color="") +
  theme_lancet
ggsave("results/figures/C4_horse_race.pdf", p5, width=170, height=97.1, units="mm", device=cairo_pdf)
cat("Fig5 (horse race) saved\n")

# ========================================================================
# SUPPLEMENTARY FIGURES — key ones that need color upgrade
# ========================================================================

# S2: Event study no-COVID (use same style as Fig2)
cat("\nSupplementary figures already use unified palette from main scripts.\n")
cat("Key figures regenerated: fig1, fig5 (event), fig4 (B/W), B3 (mirror), C4 (horse)\n")

# S5: Regional heterogeneity — already uses PAL_SIG
# S8: Horse race by income — already uses PAL_INCOME
# Others: PRISMA (B&W by design), SCM gaps, placebo — these are fine

cat("\n=== All figures regenerated with Lancet-compatible palette ===\n")
