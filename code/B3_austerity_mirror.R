# ============================================================================
# B3_austerity_mirror.R
# GHE Austerity Mirror Analysis
# Identify GHE DECREASES (>1.5pp GDP in 3 years) — mirror of event study
# Does HALE decline after GHE cuts? This is the symmetric test of reverse causality.
# ============================================================================

set.seed(49)
options(scipen=999, warn=1)

pkgs <- c("data.table","fixest","ggplot2")
for(p in pkgs) if(!requireNamespace(p,quietly=TRUE)) install.packages(p,repos="https://cloud.r-project.org")
invisible(lapply(pkgs,library,character.only=TRUE))
pvalue <- fixest::pvalue

PROJ <- "/Users/taozhu/my researches/lancet_financial_v3"
setwd(PROJ)
dir.create("results/tables", recursive=TRUE, showWarnings=FALSE)
dir.create("results/figures", recursive=TRUE, showWarnings=FALSE)

PAL <- c(zhusha="#C23531", shiqing="#3D6BA8", yanzhi="#9D2933", dianqing="#177CB0")
INC_COL <- c("Low income"="#9D2933","Lower middle income"="#C23531",
             "Upper middle income"="#177CB0","High income"="#3D6BA8")
theme_pub <- theme_bw(base_size=8) +
  theme(panel.grid.minor=element_blank(),
        plot.title=element_text(face="bold",size=9),
        axis.title=element_text(size=8), axis.text=element_text(size=9))

cat("========================================================\n")
cat("B3: GHE Austerity Mirror Analysis (>1.5pp GDP decrease in 3 years)\n")
cat("========================================================\n")

# ---- Load ----
df <- fread("/Users/taozhu/my researches/lancet_financial_v3/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]

setorder(df, iso3c, year)
df[, ghe_lag3 := shift(ghe_share_gdp, 3), by=iso3c]
df[, ghe_chg3 := ghe_share_gdp - ghe_lag3]

# ---- 1. Identify GHE Decrease Events ----
# Define austerity: 3-year GHE decrease >1.5pp GDP
df[, austerity_event := ghe_chg3 < -1.5]
austerity_countries <- df[austerity_event==TRUE, unique(iso3c)]
cat(sprintf("Countries with GHE austerity (>1.5pp decrease in 3yr): %d\n", length(austerity_countries)))

austerity_spikes <- df[austerity_event==TRUE, .(event_year=min(year)), by=iso3c]
cat(sprintf("Unique austerity events: %d\n", nrow(austerity_spikes)))

# Compare with GHE spike countries (increases)
spike_countries <- df[ghe_chg3 > 2, unique(iso3c)]
cat(sprintf("GHE spike countries (for comparison): %d\n", length(spike_countries)))

# Overlap between austerity and spike countries
overlap <- intersect(austerity_countries, spike_countries)
cat(sprintf("Countries with BOTH austerity and spike events: %d\n", length(overlap)))

# ---- 2. Austerity Event Study ----
cat("\n--- 2. Austerity Event Study ---\n")

df_aus <- merge(df, austerity_spikes, by="iso3c", all.x=TRUE)
df_aus[iso3c %in% austerity_countries, t_rel := year - event_year]
df_aus[iso3c %in% austerity_countries & is.na(t_rel), t_rel := -99]

event_aus <- df_aus[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]
event_aus <- event_aus[!(iso3c %in% austerity_countries) | (t_rel >= -5 & t_rel <= 10)]
event_aus[iso3c %in% austerity_countries, t_rel_f := factor(t_rel)]
event_aus[iso3c %in% austerity_countries, t_rel_f := relevel(t_rel_f, ref="-5")]

es_aus <- feols(hale ~ i(t_rel_f, ref="-5") + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                 data=event_aus[iso3c %in% austerity_countries], vcov=~iso3c)

es_aus_coefs <- data.table(
  t_rel = as.numeric(gsub("t_rel_f::","",names(coef(es_aus)))),
  coef = coef(es_aus),
  se = se(es_aus)
)
es_aus_coefs <- es_aus_coefs[!is.na(t_rel)]
es_aus_coefs[, `:=`(ci_low=coef-1.96*se, ci_high=coef+1.96*se, type="Austerity")]

cat("Austerity event study coefficients:\n")
print(es_aus_coefs[order(t_rel)])

# ---- 3. Compare: Spike vs Austerity Event Study ----
cat("\n--- 3. Comparison: Spike vs Austerity ---\n")

# Re-run spike event study for comparison
spike_events_all <- df[ghe_chg3 > 2, .(event_year=min(year)), by=iso3c]
df_spike <- merge(df, spike_events_all, by="iso3c", all.x=TRUE)
df_spike[iso3c %in% spike_countries, t_rel := year - event_year]

event_spike <- df_spike[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]
event_spike <- event_spike[!(iso3c %in% spike_countries) | (t_rel >= -5 & t_rel <= 10)]
event_spike[iso3c %in% spike_countries, t_rel_f := factor(t_rel)]
event_spike[iso3c %in% spike_countries, t_rel_f := relevel(t_rel_f, ref="-5")]

es_spike <- feols(hale ~ i(t_rel_f, ref="-5") + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                   data=event_spike[iso3c %in% spike_countries], vcov=~iso3c)

es_spike_coefs <- data.table(
  t_rel = as.numeric(gsub("t_rel_f::","",names(coef(es_spike)))),
  coef = coef(es_spike),
  se = se(es_spike)
)
es_spike_coefs <- es_spike_coefs[!is.na(t_rel)]
es_spike_coefs[, `:=`(ci_low=coef-1.96*se, ci_high=coef+1.96*se, type="Spike")]

# Combine
es_combined <- rbind(es_spike_coefs, es_aus_coefs)
es_combined[, type := factor(type, levels=c("Spike","Austerity"))]

p_mirror <- ggplot(es_combined[!is.na(t_rel)], aes(x=t_rel, y=coef, color=type, fill=type)) +
  geom_hline(yintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_vline(xintercept=0, linetype="dashed", color=PAL["yanzhi"], linewidth=0.5) +
  geom_ribbon(aes(ymin=ci_low, ymax=ci_high), alpha=0.12, color=NA) +
  geom_line(linewidth=0.8) +
  geom_point(size=2) +
  scale_color_manual(values=c("Spike"=PAL["zhusha"], "Austerity"=PAL["shiqing"])) +
  scale_fill_manual(values=c("Spike"=PAL["zhusha"], "Austerity"=PAL["shiqing"])) +
  annotate("text", x=0, y=max(es_combined$ci_high, na.rm=TRUE)*0.9,
           label="GHE Change", color=PAL["yanzhi"], size=3, hjust=-0.2) +
  labs(x="Years Relative to Event", y="HALE Change (vs t-5)",
       title="B3: Austerity Mirror — GHE Spike vs GHE Cut Event Studies",
       subtitle=sprintf("Spike (>2pp): %d countries | Austerity (>1.5pp cut): %d countries",
                        length(spike_countries), length(austerity_countries)),
       color="Event Type", fill="Event Type") +
  theme_pub + theme(legend.position="bottom")

ggsave("results/figures/B3_austerity_mirror.pdf", p_mirror, width=8, height=5.5, device=cairo_pdf)
cat("Saved: results/figures/B3_austerity_mirror.pdf\n")

# ---- 4. Austerity DiD ----
cat("\n--- 4. Austerity DiD ---\n")

# Simple DiD: post-austerity for treated vs never-austerity countries
df_aus[, post_austerity := ifelse(iso3c %in% austerity_countries & year >= event_year, 1, 0)]
df_aus[!(iso3c %in% austerity_countries), post_austerity := 0]
df_aus[, ever_austerity := iso3c %in% austerity_countries]

did_aus <- feols(hale ~ post_austerity + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                 data=df_aus, vcov=~iso3c)
cat(sprintf("Austerity DiD (all): post=%.3f (SE=%.3f, p=%.3f)\n",
            coef(did_aus)["post_austerity"], se(did_aus)["post_austerity"],
            pvalue(did_aus)["post_austerity"]))

# ---- 5. Austerity Events Summary ----
cat("\n--- 5. Austerity Event Summary ---\n")

aus_list <- austerity_spikes[order(event_year)]
aus_list <- merge(aus_list, unique(df[, .(iso3c, country, income)]), by="iso3c", all.x=TRUE)

cat("Austerity events by income group:\n")
print(aus_list[, .N, by=income][order(-N)])

cat("\nFull austerity event list:\n")
print(aus_list)

# GHE trajectory around austerity events
aus_trajectories <- data.table()
for(i in 1:nrow(aus_list)) {
  iso <- aus_list$iso3c[i]
  evt <- aus_list$event_year[i]
  sub <- df[iso3c == iso & year >= evt - 3 & year <= evt + 5]
  if(nrow(sub) > 0) {
    sub[, `:=`(event_year=evt, t_rel=year-evt)]
    aus_trajectories <- rbind(aus_trajectories, sub[, .(iso3c, year, t_rel, ghe_share_gdp, hale)], fill=TRUE)
  }
}

cat(sprintf("\nMean GHE at t=-3: %.2f, t=0: %.2f, t+3: %.2f\n",
            aus_trajectories[t_rel==-3, mean(ghe_share_gdp, na.rm=TRUE)],
            aus_trajectories[t_rel==0, mean(ghe_share_gdp, na.rm=TRUE)],
            aus_trajectories[t_rel==3, mean(ghe_share_gdp, na.rm=TRUE)]))
cat(sprintf("Mean HALE at t=-3: %.2f, t=0: %.2f, t+3: %.2f\n",
            aus_trajectories[t_rel==-3, mean(hale, na.rm=TRUE)],
            aus_trajectories[t_rel==0, mean(hale, na.rm=TRUE)],
            aus_trajectories[t_rel==3, mean(hale, na.rm=TRUE)]))

# ---- 6. SAVE ----
fwrite(aus_list, "results/tables/B3_austerity_events.csv")
cat("Saved: results/tables/B3_austerity_events.csv\n")

# Save summary statistics
aus_summary <- data.table(
  metric = c("n_austerity_countries","n_austerity_events","n_spike_countries","n_overlap",
             "austerity_did_coef","austerity_did_se","austerity_did_p"),
  value = c(length(austerity_countries), nrow(austerity_spikes), length(spike_countries),
            length(overlap), coef(did_aus)["post_austerity"],
            se(did_aus)["post_austerity"], pvalue(did_aus)["post_austerity"])
)
fwrite(aus_summary, "results/tables/B3_austerity_summary.csv")
cat("Saved: results/tables/B3_austerity_summary.csv\n")

cat("\n=== B3 Complete ===\n")
