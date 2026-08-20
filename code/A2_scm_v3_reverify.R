# ============================================================================
# A2_synthetic_control_reforms.R — Synthetic Control Method (SCM) for 6
# health financing reforms, replacing simple TWFE DiD.
# Donor pool: same-baseline-income-group countries with complete data in the
# estimation window. In-space placebo tests with MSPE-ratio rank p-values.
# Pre-treatment window: 2000 to reform year (data start 2000).
# ============================================================================

set.seed(49)
options(scipen=999, warn=1)

pkgs <- c("data.table","ggplot2","tidysynth","dplyr","tidyr")
for(p in pkgs) if(!requireNamespace(p,quietly=TRUE)) install.packages(p,repos="https://cloud.r-project.org")
invisible(lapply(pkgs,library,character.only=TRUE))

PROJ <- "/Users/taozhu/my researches/lancet_financial_v3"
setwd(PROJ)
dir.create("results/tables", recursive=TRUE, showWarnings=FALSE)
dir.create("results/figures", recursive=TRUE, showWarnings=FALSE)

PAL <- c(zhusha="#C23531", shiqing="#3D6BA8", yanzhi="#9D2933", dianqing="#177CB0")
theme_pub <- theme_bw(base_size=8) +
  theme(panel.grid.minor=element_blank(),
        strip.background=element_rect(fill="grey92",colour=NA),
        plot.title=element_text(face="bold",size=9),
        axis.title=element_text(size=8), axis.text=element_text(size=7))

# ---- Load ----
dt <- as.data.table(readRDS("results/panel/panel_analysis.rds"))
dt[, ln_gdppc := log(gdp_per_capita_ppp)]
dt[, income_base := as.character(income_base)]
dt[, region := NULL]

reforms <- data.table(
  iso3c = c("RWA","CHN","THA","TUR","GHA","MEX"),
  country = c("Rwanda","China","Thailand","Turkey","Ghana","Mexico"),
  reform_year = c(2005, 2009, 2002, 2003, 2003, 2004),
  reform_name = c("CBHI","Health Reform","UCS","HTP","NHIS","Seguro Popular")
)

run_scm <- function(iso, ryear, label) {
  ig <- unique(dt[iso3c==iso, income_base])
  pre_years <- 2000:(ryear-1)          # full available pre-period (data start 2000)
  end_year  <- min(ryear + 15, 2022)   # post window capped at data end
  win_years <- c(pre_years, ryear:end_year)

  pool <- dt[income_base==ig & iso3c!=iso & !(iso3c %in% reforms$iso3c)]
  # donors with complete outcome + predictors over the whole window
  ok_ids <- pool[year %in% win_years,
    .(ok = .N == length(win_years) &&
        all(!is.na(hale)) & all(!is.na(ln_gdppc)) & all(!is.na(urbanization)) &
        all(!is.na(fertility_rate)) & all(!is.na(ghe_share_gdp))), by=iso3c][ok==TRUE, iso3c]

  sub <- dt[iso3c %in% c(iso, ok_ids) & year %in% win_years]
  sdf <- as.data.frame(sub[, .(iso3c, year, hale, ghe_share_gdp, ln_gdppc, urbanization, fertility_rate)])

  sc <- synthetic_control(data=sdf, outcome=hale, unit=iso3c, time=year,
                          i_unit=iso, i_time=ryear, generate_placebos=TRUE) %>%
    generate_predictor(time_window=pre_years,
                       mean_hale = mean(hale, na.rm=TRUE),
                       mean_gdppc = mean(ln_gdppc, na.rm=TRUE),
                       mean_urb = mean(urbanization, na.rm=TRUE),
                       mean_fert = mean(fertility_rate, na.rm=TRUE),
                       mean_ghe = mean(ghe_share_gdp, na.rm=TRUE)) %>%
    generate_weights(optimization_window=pre_years,
                     margin_ipop=0.02, sigf_ipop=7, bound_ipop=6) %>%
    generate_control()

  # MSPE from gap series (treated + placebos)
  gaps_all <- grab_synthetic_control(sc, placebo=TRUE) %>% mutate(gap = real_y - synth_y)
  mspe_df <- gaps_all %>%
    group_by(.id, .placebo) %>%
    summarise(pre_mspe  = mean(gap[time_unit <  ryear]^2, na.rm=TRUE),
              post_mspe = mean(gap[time_unit >= ryear]^2, na.rm=TRUE), .groups="drop") %>%
    mutate(mspe_ratio = post_mspe / pre_mspe)
  tr <- mspe_df %>% filter(.placebo==0)
  gap <- gaps_all %>% filter(.placebo==0)
  post_att <- mean(gap$gap[gap$time_unit >= ryear], na.rm=TRUE)
  pre_att  <- mean(gap$gap[gap$time_unit <  ryear], na.rm=TRUE)

  pl_ratios <- mspe_df$mspe_ratio[mspe_df$.placebo==1 & is.finite(mspe_df$mspe_ratio)]
  p_rank <- (sum(pl_ratios >= tr$mspe_ratio) + 1) / (length(pl_ratios) + 1)

  keep <- mspe_df$.id[mspe_df$.placebo==1 & mspe_df$pre_mspe <= 5*tr$pre_mspe]
  gaps_filt <- gaps_all %>% filter(.placebo==0 | .id %in% keep)

  list(gap=gap, gaps_filt=gaps_filt, country=label, iso=iso, ryear=ryear, income=ig,
       pre_rmspe=sqrt(tr$pre_mspe), post_rmspe=sqrt(tr$post_mspe),
       mspe_ratio=tr$mspe_ratio, post_att=post_att, pre_att=pre_att,
       n_donors=length(ok_ids), n_placebo=length(pl_ratios), p_rank=p_rank,
       n_pre=length(pre_years))
}

cat("=== SCM for 6 reforms ===\n")
results <- list()
for(i in 1:nrow(reforms)) {
  r <- reforms[i]
  cat(sprintf("\n--- %s (%s, %d) ---\n", r$country, r$reform_name, r$reform_year))
  res <- tryCatch(
    run_scm(r$iso3c, r$reform_year, paste0(r$country, " (", r$reform_name, ")")),
    error=function(e){cat("ERROR:", conditionMessage(e), "\n"); NULL})
  if(!is.null(res)) {
    results[[r$iso3c]] <- res
    cat(sprintf("pre-years=%d donors=%d | pre-RMSPE=%.3f | post-ATT=%+.3f | MSPE ratio=%.2f | placebo p=%.3f (n=%d)\n",
                res$n_pre, res$n_donors, res$pre_rmspe, res$post_att, res$mspe_ratio, res$p_rank, res$n_placebo))
  }
}

sumdt <- rbindlist(lapply(results, function(x) data.table(
  Country=x$country, ISO=x$iso, ReformYear=x$ryear, Income=x$income,
  N_pre_years=x$n_pre, N_donors=x$n_donors, PreRMSPE=round(x$pre_rmspe,3),
  PostATT=round(x$post_att,3), MSPE_ratio=round(x$mspe_ratio,2),
  Placebo_p=round(x$p_rank,3), N_placebo=x$n_placebo)))
print(sumdt)
fwrite(sumdt, "results/tables/A2_scm_reforms_summary.csv")

# ---- Figure 1: treated vs synthetic ----
trend_df <- do.call(rbind, lapply(results, function(x)
  data.frame(Country=x$country, year=x$gap$time_unit,
             Treated=x$gap$real_y, Synthetic=x$gap$synth_y, ryear=x$ryear)))
trend_long <- tidyr::pivot_longer(as.data.frame(trend_df), cols=c("Treated","Synthetic"),
                                  names_to="series", values_to="hale")

p1 <- ggplot(trend_long, aes(x=year, y=hale, color=series, linetype=series)) +
  geom_line(linewidth=0.8) +
  geom_vline(data=unique(as.data.frame(trend_df)[,c("Country","ryear")]),
             aes(xintercept=ryear), linetype="dashed", color=PAL["yanzhi"], linewidth=0.4) +
  facet_wrap(~Country, scales="free_y", ncol=2) + theme_bw(base_size=10) + theme(panel.grid.minor=element_blank(), axis.text=element_text(size=10), strip.text=element_text(size=12, face="bold"), axis.title=element_text(size=10), legend.position="bottom", aspect.ratio=1) +
  scale_color_manual(values=c("Treated"=PAL["zhusha"], "Synthetic"=PAL["shiqing"])) +
  labs(x="Year", y="HALE (years)",
       title="Synthetic Control: Health Financing Reforms",
       subtitle="Treated country vs synthetic\ncounterfactual (donor pool: same income group)",
       color="", linetype="")
ggsave("results/figures/figA2_scm_trends.pdf", p1, width=170, height=100, units="mm", device=cairo_pdf)
cat("Saved: results/figures/figA2_scm_trends.pdf\n")

# ---- Figure 2: placebo gaps (p in facet labels) ----
plabs <- sumdt[, .(Country, Placebo_p)]
plabs[, flabel := sprintf("%s\n(placebo p=%.2f)", Country, Placebo_p)]
gap_df <- do.call(rbind, lapply(results, function(x) {
  g <- x$gaps_filt
  data.frame(Country=x$country, id=g$.id, placebo=g$.placebo,
             year=g$time_unit, gap=g$gap, ryear=x$ryear)
}))
gap_df <- as.data.frame(gap_df)
gap_df$Country <- plabs$flabel[match(gap_df$Country, plabs$Country)]
p_vals_text <- paste(sprintf("%s: p=%.2f", sumdt$Country, sumdt$Placebo_p), collapse="; ")

p2 <- ggplot(gap_df, aes(x=year, y=gap, group=id)) +
  geom_line(data=gap_df[gap_df$placebo==1,], color="grey75", linewidth=0.4, alpha=0.7) +
  geom_line(data=gap_df[gap_df$placebo==0,], color=PAL["zhusha"], linewidth=0.9) +
  geom_hline(yintercept=0, linetype="dashed", color="grey40", linewidth=0.3) +
  geom_vline(data=unique(gap_df[,c("Country","ryear")]), aes(xintercept=ryear),
             linetype="dashed", color=PAL["yanzhi"], linewidth=0.4) +
  facet_wrap(~Country, ncol=3) +
  labs(x="Year", y="Gap in HALE (treated - synthetic)",
       title="In-Space Placebo Tests: Gap in HALE",
       subtitle="Red = treated; grey = placebos (pre-MSPE < 5\u00d7 treated).") +
  theme_pub
ggsave("results/figures/figA2_scm_placebos.pdf", p2, width=170, height=100, units="mm", device=cairo_pdf)
cat("Saved: results/figures/figA2_scm_placebos.pdf\n")

cat("\n=== A2 Complete ===\n")
