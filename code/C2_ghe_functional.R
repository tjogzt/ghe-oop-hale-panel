# ============================================================================
# C2_ghe_functional.R
# GHE Functional Classification: analyze composition and trends
# Checks WHO GHED data, analyzes GHE vs OOP patterns by income group
# ============================================================================

set.seed(49)
options(scipen=999, warn=1)

pkgs <- c("data.table","fixest","ggplot2","readxl")
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
        axis.title=element_text(size=8), axis.text=element_text(size=7))

cat("========================================================\n")
cat("C2: GHE Functional Classification\n")
cat("========================================================\n")

DATA_DIR <- "/Volumes/tjogzt4T/lancet_financial_v2/data/raw"

# ---- 1. Check WHO GHED Data ----
cat("\n--- 1. WHO GHED Data ---\n")
ghed_path <- file.path(DATA_DIR, "who", "GHED_data.XLSX")
who_csv_path <- file.path(DATA_DIR, "who", "who_WHOSIS_000001.csv")

ghed_available <- FALSE
if(file.exists(ghed_path)) {
  ghed <- tryCatch(as.data.table(read_excel(ghed_path)), error=function(e) NULL)
  if(!is.null(ghed)) {
    cat(sprintf("GHED Excel found: %d rows x %d cols\n", nrow(ghed), ncol(ghed)))
    cat("Columns:", paste(names(ghed), collapse=", "), "\n")
    ghed_available <- TRUE
  }
} else {
  cat("GHED Excel NOT found.\n")
}

who_available <- FALSE
if(file.exists(who_csv_path)) {
  who_data <- tryCatch(fread(who_csv_path), error=function(e) NULL)
  if(!is.null(who_data)) {
    cat(sprintf("WHO CSV found: %d rows x %d cols\n", nrow(who_data), ncol(who_data)))
    cat("Columns:", paste(names(who_data), collapse=", "), "\n")
    who_available <- TRUE
  }
} else {
  cat("WHO CSV NOT found.\n")
}

# ---- 2. WDI Panel Check ----
cat("\n--- 2. WDI Health Indicators ---\n")
wdi_panel_path <- file.path(DATA_DIR, "wb_wdi_panel_2000_2023.csv")
if(file.exists(wdi_panel_path)) {
  wdi_cols <- names(fread(wdi_panel_path, nrows=2))
  health_cols <- grep("health|mortality|physician|hospital|SH\\.", wdi_cols,
                      ignore.case=TRUE, value=TRUE)
  cat("Health-related WDI columns:", paste(health_cols, collapse=", "), "\n")
}

# ---- 3. GHE Composition Analysis ----
cat("\n--- 3. GHE Summary Statistics ---\n")

df <- fread("/Volumes/tjogzt4T/lancet_financial_v2/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df[, ln_gdppc := log(gdp_per_capita_ppp)]
df[, income_base := .SD[year==min(year), income[1]], by=iso3c]

ghe_m <- mean(df$ghe_share_gdp, na.rm=TRUE)
ghe_s <- sd(df$ghe_share_gdp, na.rm=TRUE)
oop_m <- mean(df$oop_expenditure, na.rm=TRUE)
oop_s <- sd(df$oop_expenditure, na.rm=TRUE)
cat(sprintf("GHE (pct GDP): mean=%.2f, SD=%.2f\n", ghe_m, ghe_s))
cat(sprintf("OOP (pct CHE): mean=%.2f, SD=%.2f\n", oop_m, oop_s))

# ---- 4. GHE Trends by Income Group ----
cat("\n--- 4. GHE Trends by Income Group ---\n")

ghe_trends <- df[!is.na(ghe_share_gdp), .(
  ghe_mean = mean(ghe_share_gdp, na.rm=TRUE),
  ghe_sd = sd(ghe_share_gdp, na.rm=TRUE),
  oop_mean = mean(oop_expenditure, na.rm=TRUE),
  n = .N
), by=.(income_base, year)]

for(ig in c("Low income","Lower middle income","Upper middle income","High income")) {
  g00 <- ghe_trends[income_base==ig & year==2000, ghe_mean]
  g23 <- ghe_trends[income_base==ig & year==2023, ghe_mean]
  oop00 <- ghe_trends[income_base==ig & year==2000, oop_mean]
  oop23 <- ghe_trends[income_base==ig & year==2023, oop_mean]
  if(length(g00)>0 && length(g23)>0) {
    cat(sprintf("  %-22s: GHE %.2f -> %.2f | OOP %.1f -> %.1f\n", ig, g00, g23, oop00, oop23))
  }
}

# ---- 5. Figure: GHE and OOP Trends ----
p_ghe <- ggplot(ghe_trends, aes(x=year, y=ghe_mean, color=income_base)) +
  geom_line(linewidth=1) +
  scale_color_manual(values=INC_COL) +
  labs(x="Year", y="Mean GHE (pct GDP)", color="Income Group",
       title="C2: GHE as Share of GDP by Income Group (2000-2023)") +
  theme_pub + theme(legend.position="bottom")
ggsave("results/figures/C2_ghe_trends.pdf", p_ghe, width=7, height=5, device=cairo_pdf)

p_oop <- ggplot(ghe_trends, aes(x=year, y=oop_mean, color=income_base)) +
  geom_line(linewidth=1) +
  scale_color_manual(values=INC_COL) +
  labs(x="Year", y="Mean OOP (pct CHE)", color="Income Group",
       title="C2: Out-of-Pocket Expenditure by Income Group (2000-2023)",
       subtitle="Financial protection improved most in low/lower-middle income countries") +
  theme_pub + theme(legend.position="bottom")
ggsave("results/figures/C2_oop_trends.pdf", p_oop, width=7, height=5, device=cairo_pdf)
cat("Saved: results/figures/C2_ghe_trends.pdf, C2_oop_trends.pdf\n")

# ---- 6. TWFE: GHE vs GHE_pct_CHE ----
cat("\n--- 6. GHE vs OOP within-country ---\n")

# GHE as share of GDP
m_gdp <- feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
               data=df[!is.na(hale) & !is.na(ghe_share_gdp)], vcov=~iso3c)
cat(sprintf("TWFE GHE(pct GDP): %.4f (SE=%.4f, p=%.4f)\n",
            coef(m_gdp)["ghe_share_gdp"], se(m_gdp)["ghe_share_gdp"],
            pvalue(m_gdp)["ghe_share_gdp"]))

# OOP as outcome (GHE reduces OOP)
m_oop <- feols(oop_expenditure ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate | iso3c + year,
               data=df[!is.na(oop_expenditure) & !is.na(ghe_share_gdp)], vcov=~iso3c)
cat(sprintf("TWFE GHE -> OOP:     %.4f (SE=%.4f, p=%.4f)\n",
            coef(m_oop)["ghe_share_gdp"], se(m_oop)["ghe_share_gdp"],
            pvalue(m_oop)["ghe_share_gdp"]))

# ---- 7. Save Results ----
func_results <- data.table(
  indicator = c("mean_ghe_gdp","sd_ghe_gdp","mean_oop","sd_oop",
                "ghe_gdp_coef","ghe_gdp_p","ghe_oop_coef","ghe_oop_p"),
  value = c(ghe_m, ghe_s, oop_m, oop_s,
            coef(m_gdp)["ghe_share_gdp"], pvalue(m_gdp)["ghe_share_gdp"],
            coef(m_oop)["ghe_share_gdp"], pvalue(m_oop)["ghe_share_gdp"])
)
fwrite(func_results, "results/tables/C2_functional_summary.csv")
fwrite(ghe_trends, "results/tables/C2_ghe_trends.csv")
cat("Saved: results/tables/C2_functional_summary.csv, C2_ghe_trends.csv\n")

cat("\n=== C2 Complete ===\n")
