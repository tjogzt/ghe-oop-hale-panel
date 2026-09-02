# ============================================================================
# B2_placebo_event_study.R
# Placebo event study: randomly assign pseudo-event years to untreated countries
# 100 iterations. What fraction produces "significant" post-spike decline?
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
theme_pub <- theme_classic(base_size=7) +
  theme(panel.grid.minor=element_blank(),
        panel.grid.major=element_line(colour="grey92", linewidth=0.3),
        panel.border=element_blank(),
        plot.title=element_text(face="bold",size=9),
        axis.title=element_text(size=7),
        axis.text=element_text(size=7),
        legend.text=element_text(size=7),
        legend.title=element_text(size=7))

cat("========================================================\n")
cat("B2: Placebo Event Study (100 iterations)\n")
cat("========================================================\n")

# ---- Load ----
df <- fread("/Users/taozhu/my researches/lancet_financial_v3/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]

setorder(df, iso3c, year)
df[, ghe_lag3 := shift(ghe_share_gdp, 3), by=iso3c]
df[, ghe_chg3 := ghe_share_gdp - ghe_lag3]

# ---- 1. Identify Real Spikes and Untreated Countries ----
treated_isos <- df[ghe_chg3 > 2, unique(iso3c)]
n_treated <- length(treated_isos)
cat(sprintf("Real treated countries: %d\n", n_treated))

untreated_isos <- setdiff(df[!is.na(hale) & !is.na(ghe_share_gdp), unique(iso3c)], treated_isos)
cat(sprintf("Untreated countries available: %d\n", length(untreated_isos)))

# Real spike event years for distribution
real_spike_years <- df[ghe_chg3 > 2, .(event_year=min(year)), by=iso3c]$event_year
cat(sprintf("Real spike years range: %d - %d\n", min(real_spike_years), max(real_spike_years)))
cat(sprintf("Real spike years: %s\n", paste(sort(real_spike_years), collapse=", ")))

# ---- 2. REAL EVENT STUDY (benchmark) ----
spike_events_real <- df[ghe_chg3 > 2, .(event_year=min(year)), by=iso3c]

df_real <- merge(df, spike_events_real, by="iso3c", all.x=TRUE)
df_real[iso3c %in% treated_isos, t_rel := year - event_year]
df_real[iso3c %in% treated_isos & is.na(t_rel), t_rel := -99]

event_real <- df_real[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]
event_real <- event_real[!(iso3c %in% treated_isos) | (t_rel >= -5 & t_rel <= 10)]
event_real[iso3c %in% treated_isos, t_rel_f := factor(t_rel)]
event_real[iso3c %in% treated_isos, t_rel_f := relevel(t_rel_f, ref="-5")]

es_real <- feols(hale ~ i(t_rel_f, ref="-5") + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                  data=event_real[iso3c %in% treated_isos], vcov=~iso3c)

# Real post-spike coefficients at t+4 and t+5
real_beta_t4 <- tryCatch(coef(es_real)["t_rel_f::4"], error=function(e) NA)
real_beta_t5 <- tryCatch(coef(es_real)["t_rel_f::5"], error=function(e) NA)
real_p_t4 <- tryCatch(pvalue(es_real)["t_rel_f::4"], error=function(e) NA)
real_p_t5 <- tryCatch(pvalue(es_real)["t_rel_f::5"], error=function(e) NA)

cat(sprintf("\nReal event study: t+4 = %.3f (p=%.3f), t+5 = %.3f (p=%.3f)\n",
            real_beta_t4, real_p_t4, real_beta_t5, real_p_t5))

# ---- 3. PLACEBO ITERATIONS ----
cat("\n--- Running 100 Placebo Iterations ---\n")

n_iter <- 100
placebo_results <- data.table(
  iter=1:n_iter, n_treated=n_treated,
  beta_t4=numeric(n_iter), p_t4=numeric(n_iter),
  beta_t5=numeric(n_iter), p_t5=numeric(n_iter),
  beta_t0=numeric(n_iter), p_t0=numeric(n_iter)
)

# Available years for pseudo-events (avoid edges)
available_years <- sort(unique(df[!is.na(hale), year]))
valid_event_years <- available_years[available_years >= min(available_years) + 5 &
                                     available_years <= max(available_years) - 5]

for(i in 1:n_iter) {
  if(i %% 10 == 0) cat(sprintf("  Iteration %d/%d...\n", i, n_iter))

  # Randomly select n_treated untreated countries
  placebo_isos <- sample(untreated_isos, n_treated)
  # Randomly assign event years (matching real distribution)
  placebo_years <- data.table(
    iso3c = placebo_isos,
    event_year = sample(real_spike_years, n_treated, replace=TRUE)
  )

  df_placebo <- merge(df, placebo_years, by="iso3c", all.x=TRUE)
  df_placebo[iso3c %in% placebo_isos, t_rel := year - event_year]
  df_placebo[iso3c %in% placebo_isos & is.na(t_rel), t_rel := -99]

  event_pb <- df_placebo[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]
  event_pb <- event_pb[!(iso3c %in% placebo_isos) | (t_rel >= -5 & t_rel <= 10)]
  event_pb[iso3c %in% placebo_isos, t_rel_f := factor(t_rel)]
  event_pb[iso3c %in% placebo_isos, t_rel_f := relevel(t_rel_f, ref="-5")]

  # Fit event study on placebo sample
  es_pb <- tryCatch({
    feols(hale ~ i(t_rel_f, ref="-5") + ln_gdppc + urbanization + fertility_rate | iso3c + year,
          data=event_pb[iso3c %in% placebo_isos], vcov=~iso3c)
  }, error = function(e) NULL)

  if(!is.null(es_pb)) {
    placebo_results[i, beta_t4 := tryCatch(coef(es_pb)["t_rel_f::4"], error=function(e) NA)]
    placebo_results[i, p_t4 := tryCatch(pvalue(es_pb)["t_rel_f::4"], error=function(e) NA)]
    placebo_results[i, beta_t5 := tryCatch(coef(es_pb)["t_rel_f::5"], error=function(e) NA)]
    placebo_results[i, p_t5 := tryCatch(pvalue(es_pb)["t_rel_f::5"], error=function(e) NA)]
    placebo_results[i, beta_t0 := tryCatch(coef(es_pb)["t_rel_f::0"], error=function(e) NA)]
    placebo_results[i, p_t0 := tryCatch(pvalue(es_pb)["t_rel_f::0"], error=function(e) NA)]
  }
}

# ---- 4. RESULTS ----
cat("\n--- Placebo Results ---\n")

# How many placebos produced a "significant" (p<0.05) negative coefficient at t+5?
sig_negative_t5 <- placebo_results[beta_t5 < 0 & p_t5 < 0.05, .N]
sig_positive_t5 <- placebo_results[beta_t5 > 0 & p_t5 < 0.05, .N]
sig_negative_t4 <- placebo_results[beta_t4 < 0 & p_t4 < 0.05, .N]
sig_any_negative_t5 <- placebo_results[beta_t5 < 0 & p_t5 < 0.10, .N]

cat(sprintf("Placebo iterations with significant (p<0.05) negative t+5: %d/%d (%.1f%%)\n",
            sig_negative_t5, n_iter, 100*sig_negative_t5/n_iter))
cat(sprintf("Placebo iterations with significant (p<0.05) negative t+4: %d/%d (%.1f%%)\n",
            sig_negative_t4, n_iter, 100*sig_negative_t4/n_iter))
cat(sprintf("Placebo iterations with marginally significant (p<0.10) negative t+5: %d/%d (%.1f%%)\n",
            sig_any_negative_t5, n_iter, 100*sig_any_negative_t5/n_iter))

# Distribution summary
cat(sprintf("\nCoefficient distribution at t+5:\n"))
cat(sprintf("  Mean: %.3f (SD=%.3f)\n", mean(placebo_results$beta_t5, na.rm=TRUE), sd(placebo_results$beta_t5, na.rm=TRUE)))
cat(sprintf("  Real: %.3f\n", real_beta_t5))
cat(sprintf("  Real percentile: %.1f\n",
            100*mean(placebo_results$beta_t5 <= real_beta_t5, na.rm=TRUE)))

# ---- 5. FIGURE: Placebo Distribution vs Real ----
cat("\n--- 5. Figure ---\n")

# Histogram of placebo t+5 coefficients
placebo_clean <- placebo_results[!is.na(beta_t5)]

p_dist <- ggplot(placebo_clean, aes(x=beta_t5)) +
  geom_histogram(fill=PAL["shiqing"], alpha=0.6, bins=15, color="white", linewidth=0.3) +
  geom_vline(xintercept=real_beta_t5, color=PAL["yanzhi"], linewidth=1.2, linetype="dashed") +
  geom_vline(xintercept=0, color="grey50", linewidth=0.5) +
  annotate("text", x=real_beta_t5, y=max(ggplot2::ggplot_build(
    ggplot(placebo_clean, aes(x=beta_t5)) + geom_histogram(bins=15)
  )$data[[1]]$count)*0.9,
           label=sprintf("Real: %.2f", real_beta_t5),
           color=PAL["yanzhi"], size=3, hjust=-0.1) +
  scale_y_continuous(limits=c(0, max(ggplot2::ggplot_build(
    ggplot(placebo_clean, aes(x=beta_t5)) + geom_histogram(bins=15)
  )$data[[1]]$count)*1.25), expand=c(0,0)) +
  scale_x_continuous(breaks=seq(-0.5, 1.0, 0.5)) +
  labs(x="Placebo t+5 Coefficient", y="Count",
       subtitle=sprintf("%d placebo iterations | significant (two-tailed p<0.05): %.1f%% negative, %.1f%% positive",
                        n_iter, 100*sig_negative_t5/n_iter, 100*sig_positive_t5/n_iter)) +
  theme_pub

ggsave("results/figures/figS7_placebo_distribution.pdf", p_dist, width=168, height=120, units="mm", device=cairo_pdf)
cat("Saved: results/figures/figS7_placebo_distribution.pdf\n")

# P-value distribution
p_pvals <- ggplot(placebo_clean, aes(x=p_t5)) +
  geom_histogram(fill=PAL["zhusha"], alpha=0.6, bins=20, color="white", linewidth=0.3) +
  geom_vline(xintercept=0.05, color=PAL["yanzhi"], linewidth=0.8, linetype="dashed") +
  geom_vline(xintercept=real_p_t5, color=PAL["shiqing"], linewidth=0.8) +
  annotate("text", x=0.05, y=max(ggplot2::ggplot_build(
    ggplot(placebo_clean, aes(x=p_t5)) + geom_histogram(bins=20)
  )$data[[1]]$count)*0.9,
           label=sprintf("α=0.05"), color=PAL["yanzhi"], size=3, hjust=-0.2) +
  labs(x="P-value at t+5", y="Count",
       title="B2: Placebo Event Study — P-value Distribution at t+5",
       subtitle=sprintf("Real p=%.3f", real_p_t5)) +
  theme_pub

ggsave("results/figures/B2_placebo_pvalues.pdf", p_pvals, width=7, height=5, device=cairo_pdf)
cat("Saved: results/figures/B2_placebo_pvalues.pdf\n")

# ---- 6. SAVE ----
placebo_summary <- data.table(
  metric = c("n_iterations","n_treated_each","real_beta_t5","real_p_t5",
             "real_beta_t4","real_p_t4","placebo_mean_beta_t5","placebo_sd_beta_t5",
             "pct_sig_neg_t5","pct_sig_neg_t4","pct_sig_neg_t5_p10",
             "real_percentile_t5"),
  value = c(n_iter, n_treated, real_beta_t5, real_p_t5,
            real_beta_t4, real_p_t4, mean(placebo_results$beta_t5, na.rm=TRUE),
            sd(placebo_results$beta_t5, na.rm=TRUE),
            100*sig_negative_t5/n_iter, 100*sig_negative_t4/n_iter,
            100*sig_any_negative_t5/n_iter,
            100*mean(placebo_results$beta_t5 <= real_beta_t5, na.rm=TRUE))
)
fwrite(placebo_summary, "results/tables/B2_placebo_summary.csv")
fwrite(placebo_results, "results/tables/B2_placebo_iterations.csv")
cat("Saved: results/tables/B2_placebo_summary.csv\n")
cat("Saved: results/tables/B2_placebo_iterations.csv\n")

cat("\n=== B2 Complete ===\n")
