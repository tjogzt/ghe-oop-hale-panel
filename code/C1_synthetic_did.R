# ============================================================================
# C1_synthetic_did.R
# Synthetic DiD for the GHE spike events
# Uses did2 package if installable; falls back to manual implementation
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
        axis.title=element_text(size=8), axis.text=element_text(size=7))

cat("========================================================\n")
cat("C1: Synthetic DiD for GHE Spike Events\n")
cat("========================================================\n")

# ---- Try installing did2 package ----
did2_available <- FALSE
tryCatch({
  if(!requireNamespace("did2", quietly=TRUE)) {
    install.packages("did2", repos="https://cloud.r-project.org")
  }
  library(did2)
  did2_available <- TRUE
  cat("did2 package is available.\n")
}, error = function(e) {
  cat(sprintf("did2 NOT available: %s\n", e$message))
  cat("Will use manual implementation with matching.\n")
})

# ---- Load Data ----
df <- fread("/Users/taozhu/my researches/lancet_financial_v3/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]

setorder(df, iso3c, year)
df[, ghe_lag3 := shift(ghe_share_gdp, 3), by=iso3c]
df[, ghe_chg3 := ghe_share_gdp - ghe_lag3]

# ---- Identify GHE Spike Events (full sample) ----
spike_events <- df[ghe_chg3 > 2, .(event_year=min(year)), by=iso3c]
treated_isos <- spike_events$iso3c
cat(sprintf("Treated countries: %d\n", length(treated_isos)))
cat(sprintf("Spike events: %d\n", nrow(spike_events)))

# ========================================================================
# Option 1: Use did2 if available
# ========================================================================
if(did2_available) {
  cat("\n=== Using did2 for Synthetic DiD ===\n")

  # Prepare data for did2
  df_did <- copy(df)
  df_did[, first_treat := 0]
  for(i in 1:nrow(spike_events)) {
    df_did[iso3c == spike_events$iso3c[i], first_treat := spike_events$event_year[i]]
  }

  tryCatch({
    # Bootstrap-based aggregation with universal comparison group
    # Using not-yet-treated units as controls
    did2_result <- did2::did2(
      data = df_did,
      yname = "hale",
      idname = "iso3c",
      tname = "year",
      gname = "first_treat",
      control_group = "notyettreated",
      anticipation = 0,
      base_period = "universal",
      boot = TRUE,
      boot_type = "multiplier",
      n_boot = 200
    )

    # Aggregate: overall ATT
    agg_overall <- did2::agg_gt(did2_result)
    cat("\nOverall ATT from did2:\n")
    print(agg_overall)

    # Event study plot
    es_did2 <- data.table(
      t_rel = did2_result$event_time,
      att = did2_result$att.egt,
      se = did2_result$se.egt
    )

    p_did2 <- ggplot(es_did2[!is.na(att)], aes(x=t_rel, y=att)) +
      geom_hline(yintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
      geom_vline(xintercept=0, linetype="dashed", color=PAL["yanzhi"], linewidth=0.5) +
      geom_ribbon(aes(ymin=att-1.96*se, ymax=att+1.96*se), fill=PAL["shiqing"], alpha=0.15) +
      geom_line(color=PAL["shiqing"], linewidth=0.8) +
      geom_point(size=2, color=PAL["shiqing"]) +
      labs(x="Years Relative to GHE Spike", y="ATT (HALE years)",
           title="C1: Synthetic DiD — GHE Spike Events (did2)") +
      theme_pub

    ggsave("results/figures/C1_synthetic_did.pdf", p_did2, width=7, height=5, device=cairo_pdf)
    cat("Saved: results/figures/C1_synthetic_did.pdf\n")

    fwrite(es_did2, "results/tables/C1_synthetic_did.csv")
    cat("Saved: results/tables/C1_synthetic_did.csv\n")

  }, error = function(e) {
    cat(sprintf("did2 estimation failed: %s\n", e$message))
    cat("Falling back to manual approach.\n")
    did2_available <- FALSE
  })
}

# ========================================================================
# Option 2: Manual propensity-score matched DiD as fallback
# ========================================================================
if(!did2_available) {
  cat("\n=== Manual Propensity-Score Matched DiD ===\n")

  # Build treatment indicator: country has a spike in event_year
  df_ps <- copy(df)
  df_ps[, ln_gdppc := log(gdp_per_capita_ppp)]
  df_ps[, ever_treated := iso3c %in% treated_isos]

  # For each treated country, match 3 nearest neighbors on pre-spike characteristics
  matched_sample <- data.table()

  for(i in 1:nrow(spike_events)) {
    iso <- spike_events$iso3c[i]
    evt <- spike_events$event_year[i]

    # Pre-spike data for this country
    treated_pre <- df_ps[iso3c == iso & year >= evt - 5 & year < evt]
    if(nrow(treated_pre) < 2) next

    # Potential controls: never-treated, same income group, data available
    ig <- unique(df_ps[iso3c == iso, income])
    controls <- df_ps[!iso3c %in% treated_isos & income == ig &
                       year >= evt - 5 & year < evt]
    control_isos <- unique(controls$iso3c)

    # Compute pre-spike means for matching
    treated_means <- treated_pre[, .(hale_mean=mean(hale, na.rm=TRUE),
                                      ghe_mean=mean(ghe_share_gdp, na.rm=TRUE),
                                      gdppc_mean=mean(ln_gdppc, na.rm=TRUE))]

    control_means <- df_ps[iso3c %in% control_isos & year >= evt - 5 & year < evt,
                           .(hale_mean=mean(hale, na.rm=TRUE),
                             ghe_mean=mean(ghe_share_gdp, na.rm=TRUE),
                             gdppc_mean=mean(ln_gdppc, na.rm=TRUE)), by=iso3c]

    if(nrow(control_means) < 2) next

    # Euclidean distance matching
    control_means[, distance := sqrt((hale_mean - treated_means$hale_mean)^2 +
                                      (ghe_mean - treated_means$ghe_mean)^2 +
                                      (gdppc_mean - treated_means$gdppc_mean)^2)]

    matched_controls <- control_means[order(distance)][1:min(3, .N)]$iso3c

    # Extract data for treated + matched controls
    window_data <- df_ps[iso3c %in% c(iso, matched_controls) &
                          year >= evt - 5 & year <= evt + 10]
    window_data[, `:=`(event_year=evt, treated=ifelse(iso3c==iso, 1, 0),
                        t_rel=year-evt, group=iso)]
    matched_sample <- rbind(matched_sample, window_data, fill=TRUE)
  }

  if(nrow(matched_sample) > 0) {
    cat(sprintf("Matched sample: %d rows, %d treated units matched\n",
                nrow(matched_sample), uniqueN(matched_sample[treated==1]$iso3c)))

    # DiD on matched sample
    matched_sample[, post := ifelse(treated==1 & t_rel >= 0, 1, 0)]
    matched_sample[treated==0, post := 0]

    did_matched <- feols(hale ~ post + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                         data=matched_sample, vcov=~iso3c)
    cat(sprintf("Matched DiD: post coef=%.4f (SE=%.4f, p=%.4f)\n",
                coef(did_matched)["post"], se(did_matched)["post"],
                pvalue(did_matched)["post"]))

    # Event study on matched sample
    matched_sample[, t_rel_f := factor(t_rel)]
    es_matched <- feols(hale ~ i(t_rel_f, ref="-5") + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                        data=matched_sample, vcov=~iso3c)

    es_m_coefs <- data.table(
      t_rel = as.numeric(gsub("t_rel_f::","",names(coef(es_matched)))),
      coef = coef(es_matched),
      se = se(es_matched)
    )
    es_m_coefs <- es_m_coefs[!is.na(t_rel)]
    es_m_coefs[, `:=`(ci_low=coef-1.96*se, ci_high=coef+1.96*se)]

    p_matched <- ggplot(es_m_coefs, aes(x=t_rel, y=coef)) +
      geom_hline(yintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
      geom_vline(xintercept=0, linetype="dashed", color=PAL["yanzhi"], linewidth=0.5) +
      geom_ribbon(aes(ymin=ci_low, ymax=ci_high), fill=PAL["shiqing"], alpha=0.15) +
      geom_line(color=PAL["shiqing"], linewidth=0.8) +
      geom_point(size=2, color=PAL["shiqing"]) +
      labs(x="Years Relative to GHE Spike", y="HALE Change (vs t-5)",
           title="C1: Matched DiD — GHE Spike Events",
           subtitle=sprintf("Propensity-score matched on pre-spike HALE, GHE, GDPpc")) +
      theme_pub

    ggsave("results/figures/C1_synthetic_did.pdf", p_matched, width=7, height=5, device=cairo_pdf)
    cat("Saved: results/figures/C1_synthetic_did.pdf\n")

    fwrite(es_m_coefs, "results/tables/C1_matched_did.csv")
    cat("Saved: results/tables/C1_matched_did.csv\n")
  }
}

cat("\n=== C1 Complete ===\n")
