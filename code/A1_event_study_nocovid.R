# ============================================================================
# A1_event_study_nocovid.R — Event study EXCLUDING COVID-19 years (2020-2021)
# from the GHE spike definition. Addresses critique that spike events are
# crisis-driven (COVID pandemic responses).
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
theme_pub <- theme_bw(base_size=8) +
  theme(panel.grid.minor=element_blank(),
        plot.title=element_text(face="bold",size=9),
        axis.title=element_text(size=8),
        axis.text=element_text(size=9))

# ---- Load ----
df <- fread("/Volumes/tjogzt4T/lancet_financial_v2/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]

setorder(df, iso3c, year)
df[, ghe_lag3 := shift(ghe_share_gdp, 3), by=iso3c]
df[, ghe_chg3 := ghe_share_gdp - ghe_lag3]

# ---- Full-sample spikes (reference) ----
spike_all <- df[ghe_chg3 > 2, .(event_year=min(year)), by=iso3c]
# COVID-era spikes: event year in 2020-2021 (spike measured as 3-yr change ending in that year)
spike_covid <- spike_all[event_year %in% 2020:2021]
cat(sprintf("Full sample spikes: %d countries; COVID-era (2020-21) spikes: %d\n",
            nrow(spike_all), nrow(spike_covid)))

# ---- No-COVID spikes: exclude event years 2020-2021 ----
spike_nc <- spike_all[!(event_year %in% 2020:2021)]
cat(sprintf("No-COVID spike events: %d\n", nrow(spike_nc)))

run_event_study <- function(df, spike_events, label) {
  dd <- merge(df, spike_events, by="iso3c", all.x=TRUE)
  dd[, ever_treated := !is.na(event_year)]
  dd[ever_treated==TRUE, t_rel := year - event_year]
  dd <- dd[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]
  dd <- dd[ever_treated==FALSE | (t_rel >= -5 & t_rel <= 10)]
  dd[, t_rel_f := factor(t_rel)]
  es_fit <- feols(hale ~ i(t_rel_f, ref="-5") + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                  data=dd[ever_treated==TRUE], vcov=~iso3c)
  es <- data.table(t_rel=as.numeric(gsub("t_rel_f::","",names(coef(es_fit)))),
                   coef=coef(es_fit), se=se(es_fit))
  es <- es[!is.na(t_rel)]
  es[, `:=`(ci_low=coef-1.96*se, ci_high=coef+1.96*se, p=2*pnorm(-abs(coef/se)))]
  es[, sample := label]
  list(fit=es_fit, coefs=es, n_treated=uniqueN(dd[ever_treated==TRUE]$iso3c))
}

es_full <- run_event_study(df, spike_all, "Full (incl. COVID-era spikes)")
es_nc   <- run_event_study(df, spike_nc,  "Excl. COVID-era spikes (2020-21)")

cat("\n=== Event study: FULL sample ===\n")
print(es_full$coefs[order(t_rel)])
cat("\n=== Event study: NO-COVID spikes ===\n")
print(es_nc$coefs[order(t_rel)])

# Key comparison at t+4, t+5
for(tt in c(3,4,5)) {
  f <- es_full$coefs[t_rel==tt]; n <- es_nc$coefs[t_rel==tt]
  if(nrow(f)) cat(sprintf("t+%d: full beta=%.3f (p=%.3f) | noCOVID beta=%.3f (p=%.3f)\n",
      tt, f$coef, f$p, ifelse(nrow(n),n$coef,NA), ifelse(nrow(n),n$p,NA)))
}

allc <- rbind(es_full$coefs, es_nc$coefs)
fwrite(allc, "results/tables/A1_event_study_nocovid_coefs.csv")

# Spike event lists with sample flags
sl <- merge(spike_all[, .(iso3c, event_year)],
            unique(df[, .(iso3c, country, income)]), by="iso3c")
sl[, sample := ifelse(event_year %in% 2020:2021, "Excluded (COVID-era)", "Retained (pre-2020)")]
fwrite(sl[order(event_year)], "results/tables/A1_spike_events_comparison.csv")

# ---- Figure: overlay of two event studies ----
p <- ggplot(allc, aes(x=t_rel, y=coef, color=sample, fill=sample)) +
  geom_hline(yintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_vline(xintercept=0, linetype="dashed", color=PAL["yanzhi"], linewidth=0.5) +
  geom_ribbon(aes(ymin=ci_low, ymax=ci_high), alpha=0.10, color=NA) +
  geom_line(linewidth=0.8, position=position_dodge(width=0.15)) +
  geom_point(size=1.8, position=position_dodge(width=0.15)) +
  scale_color_manual(values=c("Full (incl. COVID-era spikes)"="#D55E00",
                              "Excl. COVID-era spikes (2020-21)"="#0072B2")) +
  scale_fill_manual(values=c("Full (incl. COVID-era spikes)"="#D55E00",
                             "Excl. COVID-era spikes (2020-21)"="#0072B2")) +
  labs(x="Years Relative to GHE Spike", y="HALE Change (vs t-5)",
       title="Event Study Around GHE Spikes: Full vs COVID-Excluded Samples",
       subtitle=sprintf("Treated (non-COVID): N=%d countries",
                        es_nc$n_treated),
       color="", fill="") +
  theme_bw(base_size=10) + theme(
    panel.grid.minor=element_blank(),
    legend.position="bottom",
    axis.text=element_text(size=8),
    axis.title=element_text(size=9.5),
    plot.title=element_text(face="bold", size=11))

ggsave("results/figures/figA1_event_study_nocovid.pdf", p, width=7.5, height=5, device=cairo_pdf)
cat("Saved: results/figures/figA1_event_study_nocovid.pdf\n")

# Distribution of spike years in retained sample
cat("\nRetained spike years:\n"); print(table(spike_nc$event_year))
cat("\n=== A1 Complete ===\n")
