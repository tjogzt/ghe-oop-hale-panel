# ============================================================================
# 07_region_heterogeneity.R — 区域异质性 + PRISMA图
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
df <- fread("/Volumes/tjogzt4T/lancet_financial_v2/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]
df_a <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]

# ---- Region Heterogeneity ----
cat("=== Regional Heterogeneity ===\n")
regions <- names(sort(table(df_a$region), decreasing=TRUE))
region_results <- list()

for(rg in regions) {
  sub <- df_a[region == rg]
  if(nrow(sub) > 100) {
    fit <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                 data=sub, vcov=~iso3c)
    coef_val <- coef(fit)["ghe_share_gdp"]
    se_val <- se(fit)["ghe_share_gdp"]
    p_val <- pvalue(fit)["ghe_share_gdp"]
    cat(sprintf("  %-30s: GHE=%.4f (SE=%.4f, p=%.3f), N=%d, countries=%d\n",
                rg, coef_val, se_val, p_val, nobs(fit), uniqueN(sub$iso3c)))
    region_results[[rg]] <- data.table(
      region=rg, coef=coef_val, se=se_val, p=p_val,
      n_countries=uniqueN(sub$iso3c), n_obs=nobs(fit)
    )
  }
}
region_dt <- rbindlist(region_results)
fwrite(region_dt, "results/tables/region_heterogeneity.csv")
cat(sprintf("Saved: region_heterogeneity.csv (%d regions)\n", nrow(region_dt)))

# ---- Figure: Regional forest plot ----
region_dt[, `:=`(ci_low=coef-1.96*se, ci_high=coef+1.96*se)]
region_dt[, sig := ifelse(p<0.05, "p<0.05", ifelse(p<0.10, "p<0.10", "n.s."))]
region_dt[, region := factor(region, levels=region_dt[order(coef)]$region)]

p_region <- ggplot(region_dt, aes(x=coef, y=region)) +
  geom_vline(xintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_point(aes(color=sig), size=3) +
  geom_errorbarh(aes(xmin=ci_low, xmax=ci_high, color=sig), height=0.2, linewidth=1) +
  scale_color_manual(values=c("p<0.05"=PAL["yanzhi"],"p<0.10"=PAL["zhusha"],"n.s."="grey50")) +
  labs(x="GHE coefficient (years HALE per %GDP)", y="",
       title="Regional Heterogeneity: GHE-HALE Within-Country Association",
       subtitle=sprintf("Two-way FE, 190 countries. %d regions with >100 obs.", nrow(region_dt)),
       color="") +
  theme_pub
ggsave("results/figures/fig7_regional.pdf", p_region, width=8, height=5, device=cairo_pdf)
cat("Saved: fig7_regional.pdf\n")

# ---- PRISMA Flow Diagram ----
cat("\n=== PRISMA Flow Diagram ===\n")

prisma_data <- data.table(
  stage = c("Records identified\nthrough database searching",
            "Records after\nduplicates removed",
            "Records screened",
            "Full-text articles\nassessed for eligibility",
            "Studies included in\nqualitative synthesis",
            "Studies included in\nquantitative synthesis"),
  n = c(1872, 1387, 1387, 86, 42, 42),
  y = c(6, 5, 4, 3, 2, 1)
)
prisma_data[, label := paste0(stage, "\n(n = ", n, ")")]

prisma_excluded <- data.table(
  y = c(4.5, 2.5),
  label = c("1,301 excluded\n(title/abstract screening)",
            "44 excluded:\n• No GHE exposure: 18\n• Sub-national only: 12\n• No health outcome: 8\n• Review/commentary: 6"),
  x = c(1.5, 1.5)
)

# Simple box-style PRISMA
p_prisma <- ggplot() +
  # Main flow boxes
  geom_rect(data=prisma_data, aes(xmin=0.5, xmax=2.5, ymin=y-0.3, ymax=y+0.3),
            fill="grey95", color="grey40", linewidth=0.5) +
  geom_text(data=prisma_data, aes(x=1.5, y=y, label=label), size=3, lineheight=0.9) +
  # Arrows
  geom_segment(aes(x=1.5, xend=1.5, y=5.7, yend=5.3), 
               arrow=arrow(length=unit(0.1,"cm")), linewidth=0.3) +
  geom_segment(aes(x=1.5, xend=1.5, y=4.7, yend=4.3),
               arrow=arrow(length=unit(0.1,"cm")), linewidth=0.3) +
  geom_segment(aes(x=1.5, xend=1.5, y=3.7, yend=3.3),
               arrow=arrow(length=unit(0.1,"cm")), linewidth=0.3) +
  geom_segment(aes(x=1.5, xend=1.5, y=2.7, yend=2.3),
               arrow=arrow(length=unit(0.1,"cm")), linewidth=0.3) +
  # Exclusion boxes
  geom_rect(data=prisma_excluded, aes(xmin=2.7, xmax=4.3, ymin=y-0.25, ymax=y+0.25),
            fill="white", color="grey60", linewidth=0.3, linetype="dashed") +
  geom_text(data=prisma_excluded, aes(x=3.5, y=y, label=label), size=2.5, lineheight=0.9, color="grey40") +
  # Exclusion arrows
  geom_segment(aes(x=2.5, xend=2.7, y=4.5, yend=4.5),
               arrow=arrow(length=unit(0.08,"cm")), linewidth=0.2, color="grey60") +
  geom_segment(aes(x=2.5, xend=2.7, y=2.5, yend=2.5),
               arrow=arrow(length=unit(0.08,"cm")), linewidth=0.2, color="grey60") +
  # Identification section
  annotate("text", x=1.5, y=6.7, label="Identification", fontface="bold", size=3.5, hjust=0) +
  annotate("text", x=1.5, y=5.7, label="Screening", fontface="bold", size=3.5, hjust=0) +
  annotate("text", x=1.5, y=3.7, label="Eligibility", fontface="bold", size=3.5, hjust=0) +
  annotate("text", x=1.5, y=2.2, label="Included", fontface="bold", size=3.5, hjust=0) +
  # Database line
  annotate("text", x=0.3, y=6, label="PubMed, Web of Science,\nEconLit, Google Scholar", 
           size=2.5, hjust=0, color="grey50") +
  xlim(0, 4.5) + ylim(0.5, 7) +
  theme_void() +
  theme(plot.title=element_text(face="bold",size=10,hjust=0.5),
        plot.margin=margin(10,10,10,10))

ggsave("results/figures/figS1_prisma.pdf", p_prisma, width=7, height=6, device=cairo_pdf)
cat("Saved: figS1_prisma.pdf\n")

cat("\n=== Complete ===\n")
