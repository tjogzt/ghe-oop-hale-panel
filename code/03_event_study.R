# ============================================================================
# 03_event_study.R — 准实验：GHE大幅增长前后HALE轨迹
# 识别"treatment events": 3年内GHE增长>2pp GDP的国家
# ============================================================================

set.seed(49)
options(scipen=999, warn=1)

pkgs <- c("data.table","fixest","ggplot2")
for(p in pkgs) if(!requireNamespace(p,quietly=TRUE)) install.packages(p,repos="https://cloud.r-project.org")
invisible(lapply(pkgs,library,character.only=TRUE))
pvalue <- fixest::pvalue

PROJ <- "/Users/taozhu/my researches/lancet_financial_v3"
setwd(PROJ)

PAL <- c(zhusha="#C23531", shiqing="#3D6BA8", yanzhi="#9D2933", dianqing="#177CB0")
theme_pub <- theme_bw(base_size=8) +
  theme(panel.grid.minor=element_blank(),
        plot.title=element_text(face="bold",size=9),
        axis.title=element_text(size=8),
        axis.text=element_text(size=7))

# ---- Load ----
cat("=== Loading Data ===\n")
df <- fread("/Users/taozhu/my researches/lancet_financial_v3/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]

# ---- Identify GHE Spike Events ----
# For each country, find years where GHE increased by >2pp over 3 years
setorder(df, iso3c, year)
df[, ghe_lag3 := shift(ghe_share_gdp, 3), by=iso3c]
df[, ghe_chg3 := ghe_share_gdp - ghe_lag3]

# Define "treated": any country that had at least one 3-year GHE increase >2pp
treated_countries <- df[ghe_chg3 > 2, unique(iso3c)]
df[, ever_treated := iso3c %in% treated_countries]

cat(sprintf("Countries with GHE spike (>2pp in 3yr): %d\n", length(treated_countries)))

# For each treated country, find the FIRST year of spike
spike_events <- df[ghe_chg3 > 2, .(event_year=min(year)), by=iso3c]
cat(sprintf("Unique spike events: %d\n", nrow(spike_events)))

# ---- Event Study Window ----
# For treated countries, create relative time: t-rel = year - event_year
df <- merge(df, spike_events, by="iso3c", all.x=TRUE)
df[ever_treated==TRUE, t_rel := year - event_year]
df[ever_treated==TRUE & is.na(t_rel), t_rel := -99]  # never treated

# Define pre/post
df[, post := ifelse(ever_treated & year >= event_year, 1, 0)]
df[ever_treated==FALSE, post := 0]

# ---- Simple DiD: Before/After for treated vs never-treated ----
cat("\n=== Simple DiD ===\n")
# Keep window: 5 years before to 10 years after
event_window <- df[ever_treated==FALSE | (t_rel >= -5 & t_rel <= 10)]
event_window <- event_window[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]

did_fit <- feols(hale ~ post + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                 data=event_window[ever_treated==TRUE | ever_treated==FALSE],
                 vcov=~iso3c)
cat(sprintf("DiD (treated vs never-treated): post coef=%.3f (p=%.3f)\n",
            coef(did_fit)["post"], pvalue(did_fit)["post"]))

# ---- Event Study with Relative Time Dummies ----
cat("\n=== Event Study ===\n")
event_data <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]
event_data <- event_data[ever_treated==FALSE | (t_rel >= -5 & t_rel <= 10)]

# Create relative time factors (t=-5 as reference)
event_data[, t_rel_f := factor(t_rel)]
event_data[, t_rel_f := relevel(t_rel_f, ref="-5")]

es_fit <- feols(hale ~ i(t_rel_f, ref="-5") + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                data=event_data[ever_treated==TRUE], vcov=~iso3c)

# Extract coefficients
es_coefs <- data.table(
  t_rel = as.numeric(gsub("t_rel_f::","",names(coef(es_fit)))),
  coef = coef(es_fit),
  se = se(es_fit)
)
es_coefs <- es_coefs[!is.na(t_rel)]
es_coefs[, `:=`(ci_low=coef-1.96*se, ci_high=coef+1.96*se)]

cat("Event study coefficients (ref=t-5):\n")
print(es_coefs[order(t_rel)][1:min(10,.N)])

# ---- Figure: Event Study Plot ----
p_es <- ggplot(es_coefs, aes(x=t_rel, y=coef)) +
  geom_hline(yintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_vline(xintercept=0, linetype="dashed", color=PAL["yanzhi"], linewidth=0.5) +
  geom_ribbon(aes(ymin=ci_low, ymax=ci_high), fill=PAL["shiqing"], alpha=0.15) +
  geom_line(color=PAL["shiqing"], linewidth=0.8) +
  geom_point(size=2, color=PAL["shiqing"]) +
  annotate("text", x=0, y=max(es_coefs$ci_high, na.rm=TRUE)*0.95, 
           label="GHE Spike", color=PAL["yanzhi"], size=3, hjust=-0.2) +
  labs(x="Years Relative to GHE Spike", y="HALE Change (vs t-5)",
       title=sprintf("Event Study: HALE Trajectory Around GHE Spikes (>2pp/3yr)"),
       subtitle=sprintf("N=%d treated countries", length(unique(event_data[ever_treated==TRUE]$iso3c)))) +
  theme_pub

ggsave("results/figures/fig5_event_study.pdf", p_es, width=7, height=5, device=cairo_pdf)
cat("Saved: fig5_event_study.pdf\n")

# ---- Figure: GHE Spikes by Income Group ----
df_spike <- df[ghe_chg3 > 2]
spike_summary <- df_spike[, .N, by=.(income, year)]
spike_summary <- spike_summary[income %in% c("Low income","Lower middle income","Upper middle income","High income")]

p_spike <- ggplot(spike_summary, aes(x=year, y=N, fill=income)) +
  geom_col(position="stack", width=0.8) +
  scale_fill_manual(values=c("Low income"="#9D2933","Lower middle income"="#C23531",
                              "Upper middle income"="#177CB0","High income"="#3D6BA8")) +
  labs(x="Year", y="Number of Countries with GHE Spike",
       title="GHE Spikes (>2pp GDP increase in 3 years) by Year and Income Group",
       fill="Income Group") +
  theme_pub + theme(legend.position="bottom")

ggsave("results/figures/fig6_ghe_spikes.pdf", p_spike, width=7, height=5, device=cairo_pdf)
cat("Saved: fig6_ghe_spikes.pdf\n")

# ---- Summary Statistics ----
cat("\n=== Spike Event Summary ===\n")
cat(sprintf("Total spike events: %d\n", nrow(df_spike)))
cat(sprintf("Unique treated countries: %d\n", length(treated_countries)))
cat(sprintf("By income group:\n"))
for(ig in c("Low income","Lower middle income","Upper middle income","High income")) {
  n <- df_spike[income==ig, uniqueN(iso3c)]
  cat(sprintf("  %-22s: %d countries\n", ig, n))
}

# Save events list
spike_list <- spike_events[order(event_year)]
spike_list <- merge(spike_list, unique(df[, .(iso3c, country, income)]), by="iso3c")
fwrite(spike_list, "results/tables/ghe_spike_events.csv")
cat("Saved: results/tables/ghe_spike_events.csv\n")

cat("\n=== Complete ===\n")
