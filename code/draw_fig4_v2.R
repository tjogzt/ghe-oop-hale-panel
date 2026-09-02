# Figure 4 v2 — 低收入 3-panel 组合(字号 >=8pt 修复)
# 输出 fig_lic_summary_v2.pdf(不覆盖主稿)
suppressMessages({library(data.table); library(ggplot2); library(fixest); library(patchwork)})
set.seed(49)

PAL <- c(zhusha="#C23531", shiqing="#3D6BA8", yanzhi="#9D2933", dianqing="#177CB0")
theme_pub2 <- theme_bw(base_size=10) +
  theme(panel.grid.minor=element_blank(),
        panel.grid.major=element_line(linewidth=0.2, color="grey90"),
        axis.title=element_text(size=10), axis.text=element_text(size=8.5),
        legend.text=element_text(size=8.5), legend.title=element_text(size=9),
        plot.margin=margin(8,8,8,8),
        panel.border=element_blank(),
        axis.line=element_line(color="grey50", linewidth=0.3))

df <- fread("/Users/taozhu/my researches/lancet_financial_v3/data/processed/integrated_panel_final.csv")
df <- df[!(region %in% c("Aggregates","") | income %in% c("Aggregates","Not classified",""))]
df <- df[income=="Low income" & !is.na(hale) & !is.na(ghe_share_gdp) & !is.na(urbanization) & !is.na(fertility_rate)]
df[, ln_gdppc := log(gdp_per_capita_ppp)]

# ---- Panel A: LOO(1 列 23 国,紧凑行距) ----
loo_res <- fread("results/tables/LGH1_lic_loo.csv")
loo_res[, country := fcase(
  iso3c=="RWA","Rwanda",iso3c=="YEM","Yemen",iso3c=="MWI","Malawi",iso3c=="BFA","Burkina Faso",
  iso3c=="BDI","Burundi",iso3c=="TCD","Chad",iso3c=="MOZ","Mozambique",iso3c=="SYR","Syria",
  iso3c=="MDG","Madagascar",iso3c=="ERI","Eritrea",iso3c=="COD","DR Congo",iso3c=="SLE","Sierra Leone",
  iso3c=="AFG","Afghanistan",iso3c=="GNB","Guinea-Bissau",iso3c=="MLI","Mali",iso3c=="NER","Niger",
  iso3c=="TGO","Togo",iso3c=="CAF","Central African Republic",iso3c=="LBR","Liberia",iso3c=="ETH","Ethiopia",
  iso3c=="UGA","Uganda",iso3c=="SDN","Sudan",iso3c=="GMB","Gambia",default=iso3c)]
setorderv(loo_res, "coef")
loo_res[, country := factor(country, levels=rev(country))]
pa <- ggplot(loo_res, aes(x=coef, y=country)) +
  geom_vline(xintercept=0.846, linetype="dashed", color=PAL["zhusha"], linewidth=0.5) +
  geom_errorbarh(aes(xmin=ci_low, xmax=ci_high), height=0.3, color="grey45", linewidth=0.8) +
  geom_point(color=PAL["shiqing"], size=2.4) +
  scale_y_discrete(expand = expansion(add = c(0.4, 1.5))) +  # 顶部多留 1.5 单元——红字完整显示
  annotate("text", x=0.1, y=nrow(loo_res)+0.9, label="Full LIC: +0.846",
           color=PAL["zhusha"], size=3.5, hjust=0, fontface="bold") +
  labs(x="GHE coefficient (HALE yrs per %GDP)", y="", subtitle="A.  Leave-one-out (23 LICs)") +
  theme_pub2 +
  theme(axis.text.y=element_text(size=8.5, margin=margin(r=2)),
        plot.margin=margin(6,6,6,6))

# ---- Panel B: dose-response ----
fit_quad <- feols(hale ~ ghe_share_gdp + I(ghe_share_gdp^2) + ln_gdppc + urbanization + fertility_rate | iso3c + year,
                  data=df, vcov=~iso3c)
grid_x <- seq(0, 3.5, length.out=100)
b <- coef(fit_quad)
b_main <- c(ghe=unname(b["ghe_share_gdp"]), ghe2=unname(b["I(I(ghe_share_gdp^2))"]),
            gdppc=unname(b["ln_gdppc"]), urban=unname(b["urbanization"]), fert=unname(b["fertility_rate"]))
pred <- b_main["gdppc"]*mean(df$ln_gdppc, na.rm=TRUE) + b_main["urban"]*mean(df$urbanization, na.rm=TRUE) +
        b_main["fert"]*mean(df$fertility_rate, na.rm=TRUE) + grid_x*b_main["ghe"] + grid_x^2*b_main["ghe2"] +
        mean(fit_quad$sumFE)  # 加 FE 均值——否则曲线画在散点下方(缺固定效应水平)
dose_dt <- data.table(ghe=grid_x, hale=pred)
pb <- ggplot(df, aes(x=ghe_share_gdp, y=hale)) +
  geom_point(color="grey60", alpha=0.25, size=1.2) +
  geom_line(data=dose_dt, aes(x=ghe, y=hale), color=PAL["shiqing"], linewidth=1.2) +
  labs(x="GHE (% GDP)", y="HALE (years)",
       subtitle="B.  Dose-response") +
  theme_pub2

# ---- Panel C: lag structure ----
lag_res <- fread("results/tables/LGH3_lagstructure.csv")
lag_res <- lag_res[lag != "lag"]  # 删重复表头行
lag_res[, `:=`(lag=as.integer(lag), coef=as.numeric(coef), se=as.numeric(se),
               ci_low=as.numeric(ci_low), ci_high=as.numeric(ci_high))]
lag_res[, lag_lab := c("t (contemporaneous)", "t-1", "t-2", "t-3")]
lag_res[, lag_lab := factor(lag_lab, levels=rev(lag_lab))]
pc <- ggplot(lag_res, aes(x=coef, y=lag_lab)) +
  geom_vline(xintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_errorbarh(aes(xmin=ci_low, xmax=ci_high), height=0.25, color="grey45", linewidth=0.8) +
  geom_point(color=PAL["dianqing"], size=2.8) +
  labs(x="GHE coefficient (HALE yrs per %GDP)", y="",
       subtitle="C.  Lag structure (G = 23 LICs)") +
  theme_pub2

# ---- Panel D: reverse causality ----
rev_res <- fread("results/tables/LGH4_reversecausality.csv")
rev_res <- rev_res[hale_lag != "hale_lag"]  # 删重复表头(如有)
rev_res[, `:=`(hale_lag=as.numeric(hale_lag), coef=as.numeric(coef),
               ci_low=as.numeric(ci_low), ci_high=as.numeric(ci_high))]
pd <- ggplot(rev_res, aes(x=hale_lag, y=coef)) +
  geom_hline(yintercept=0, linetype="dashed", color="grey50", linewidth=0.3) +
  geom_ribbon(aes(ymin=ci_low, ymax=ci_high), fill=PAL["zhusha"], alpha=0.15) +
  geom_line(color=PAL["zhusha"], linewidth=0.9) +
  geom_point(size=2.8, color=PAL["zhusha"]) +
  scale_x_reverse(breaks=0:2, labels=c("t","t-1","t-2")) +
  labs(x="HALE lag (years)", y="Coefficient (GHE %GDP per HALE year)",
       subtitle="D.  Reverse causality") +
  theme_pub2 + theme(legend.position="none")

# ---- 组合:2x2 布局(A/B 上排高,C/D 下排矮——C/D 近正方形) ----
library(patchwork)
p_fig4 <- (pa | pb) / (pc | pd) + plot_layout(heights=c(1.35, 1))
ggsave("results/figures/fig_lic_summary_v3.pdf", p_fig4, width=170, height=188, units="mm", device=cairo_pdf)
cat("Saved: fig_lic_summary_v3.pdf\n")
