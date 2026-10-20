# ============================================================================
# _tmp_license_check.R — 临时验证脚本
# 目标: 在外置卷数据缺失的情况下, 用 archived 的整合面板(02_integrated_panel_data.rds)
#       尽可能复现低收入组 TWFE 的 N 与 G, 验证 516 vs 526(以及 Somalia 机制)。
# 注意: archived 版本可能与 v3 用的 integrated_panel_final.csv 有差异, 结论需谨慎,
#       并与已落盘的 results/tables/* 交叉核对。
# ============================================================================
suppressMessages({ library(data.table); library(fixest) })

# 候选数据源: v3 期望文件 + archived v2前身(变量名不同, 仅作机制辅助)
PRIMARY <- "/Users/taozhu/my researches/lancet_financial_v3/data/processed/integrated_panel_final.csv"
cand_rds <- c(
  "/Users/taozhu/my researches/archived_repos_20260820/ghe-life-expectancy/data/processed/02_integrated_panel_data_countries_only.rds",
  "/Users/taozhu/my researches/archived_repos_20260820/ghe-life-expectancy/data/processed/02_integrated_panel_data.rds"
)

df <- NULL; used_path <- NA; src_kind <- NA
if (file.exists(PRIMARY)) {
  cat("找到主数据(外置卷已挂载):", PRIMARY, "\n")
  suppressMessages(df <- fread(PRIMARY))
  used_path <- PRIMARY; src_kind <- "primary"
} else {
  cat("主数据不可用 (tjogzt4T 未挂载), 尝试 archived rds (变量名不同, 仅机制辅助)\n")
  for (p in cand_rds) {
    if (file.exists(p)) {
      obj <- tryCatch(readRDS(p), error = function(e) { cat("  读取失败:", conditionMessage(e), "\n"); NULL })
      if (!is.null(obj)) {
        if (!is.data.table(obj)) obj <- as.data.table(obj)
        df <- obj; used_path <- p; src_kind <- "archived"
        cat("  读取 archived:", p, "\n  维度:", nrow(df), "x", ncol(df), "\n")
        break
      }
    }
  }
}

if (is.null(df)) {
  cat("\n[STOP] 无任何可用数据, 无法运行回归复现。\n")
  cat("       需要挂载外置卷 tjogzt4T 提供 integrated_panel_final.csv。\n")
} else if (src_kind == "archived") {
  cat("\n=== [archived 机制辅助] 变量名不同, 无法跑 hale TWFE ===\n")
  cat("archived rds 用 life_exp/ghe_gdp/log_gdp_pc, 缺 hale/urbanization/fertility_rate 列。\n")
  cat("仅验证 Somalia 的收入分组 baseline 与时间覆盖(辅助机制判定):\n\n")
  df[, region := as.character(region)]; df[, income := as.character(income)]
  df <- df[!(region %in% c("Aggregates","")) & !(income %in% c("Aggregates","Not classified",""))]
  # income_base (复刻第94行): 每国最早年份 income
  setorder(df, iso3c, year)
  df[, income_base := .SD[year==min(year), income[1]], by=iso3c]
  li <- df[income_base == "Low income"]
  cat("Low income (archived) 国家数:", uniqueN(li$iso3c),
      " 行数:", nrow(li), " 年份:", range(li$year), "\n")
  cat("含 SOM?", "SOM" %in% li$iso3c, "\n")
  if ("SOM" %in% li$iso3c) {
    som <- li[iso3c == "SOM"]
    cat("\nSomalia (archived):\n")
    cat("  行数:", nrow(som), " 年份:", paste(range(som$year), collapse="-"), "\n")
    cat("  income baseline:", unique(som$income_base), "\n")
  }
  cat("\n[注] archived 缺关键变量, 无法给出 516/526 的精确判定。\n")
  cat("     精确复现必须挂载 tjogzt4T 跑 integrated_panel_final.csv。\n")
} else {
  cat("\n=== 数据探查 (primary) ===\n")
  cat("使用文件:", used_path, "\n")
  cat("维度:", nrow(df), "行 x", ncol(df), "列\n")
  cat("列名:", paste(names(df), collapse=", "), "\n\n")

  # 变量存在性
  need <- c("iso3c","year","country","income","region","hale","ghe_share_gdp",
            "gdp_per_capita_ppp","urbanization","fertility_rate")
  have <- need %in% names(df)
  cat("所需变量存在性:\n"); print(data.frame(var=need, present=have))
  miss_vars <- need[!have]
  if (length(miss_vars)) cat("缺失变量:", paste(miss_vars, collapse=", "), "\n")

  # 若关键变量齐备, 复刻 df_analysis 构建
  ok <- all(c("iso3c","year","income","region","hale","ghe_share_gdp","gdp_per_capita_ppp") %in% names(df))
  if (ok) {
    # 复刻 01_main_analysis.R 第33/37/39-40 行的清洗
    df[, region := as.character(region)]; df[, income := as.character(income)]
    df <- df[!(region %in% c("Aggregates","")) & !(income %in% c("Aggregates","Not classified",""))]
    df[, ln_gdppc := log(gdp_per_capita_ppp)]
    df_analysis <- df[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc)]
    cat(sprintf("\ndf_analysis (hale&ghe&gdp 非缺失): %d 行, %d 国\n",
                nrow(df_analysis), uniqueN(df_analysis$iso3c)))

    # income_base: 每国最早年份的 income
    setorder(df_analysis, iso3c, year)
    df_analysis[, income_base := .SD[year==min(year), income[1]], by=iso3c]

    # ---- (a) Low income 子集 ----
    sub <- df_analysis[income_base == "Low income"]
    cat("\n=== (a) Low income 子集 (df_analysis 层, 含所有变量含缺失的观测) ===\n")
    cat("nrow =", nrow(sub), "\n")
    cat("唯一国家数 G_sub =", uniqueN(sub$iso3c), "\n")
    cat("国家列表:", paste(sub[, unique(iso3c)], collapse=", "), "\n")
    cat("含 SOM?", "SOM" %in% sub$iso3c, "\n")
    cat("年份范围:", sub[, min(year)], "-", sub[, max(year)], "\n")

    # ---- (c) urbanization / fertility 缺失情况 ----
    cat("\n=== (c) Low income 子集 urbanization/fertility 缺失情况 ===\n")
    cat("urbanization 缺失数:", sub[is.na(urbanization), .N], "/ ", nrow(sub), "\n")
    cat("fertility_rate 缺失数:", sub[is.na(fertility_rate), .N], "/ ", nrow(sub), "\n")
    if ("SOM" %in% sub$iso3c) {
      som <- sub[iso3c=="SOM"]
      cat("\nSomalia(SOM) 子集:\n")
      cat("  行数:", nrow(som), " 年份:", paste(range(som$year), collapse="-"), "\n")
      cat("  urbanization 全缺失?", all(is.na(som$urbanization)),
          " (非缺失:", sum(!is.na(som$urbanization)), ")\n")
      cat("  fertility_rate 全缺失?", all(is.na(som$fertility_rate)),
          " (非缺失:", sum(!is.na(som$fertility_rate)), ")\n")
      cat("  hale 非缺失:", sum(!is.na(som$hale)),
          " ghe_share_gdp 非缺失:", sum(!is.na(som$ghe_share_gdp)), "\n")
    }

    # ---- (b) 跑 TWFE 回归 ----
    cat("\n=== (b) Low income TWFE 回归 ===\n")
    fit <- tryCatch(
      feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate |
              iso3c + year, data=sub, vcov=~iso3c),
      error = function(e) { cat("回归报错:", conditionMessage(e), "\n"); NULL }
    )
    if (!is.null(fit)) {
      cat("nobs(fit) =", nobs(fit), "\n")
      # 实际进入回归的数据: 去掉所有回归变量缺失的观测
      used_rows <- sub[!is.na(hale) & !is.na(ghe_share_gdp) & !is.na(ln_gdppc) &
                         !is.na(urbanization) & !is.na(fertility_rate)]
      cat("实际进入回归的观测数(手动 listwise) :", nrow(used_rows), "\n")
      cat("实际进入回归的唯一国家数 G_fit=", uniqueN(used_rows$iso3c), "\n")
      cat("实际进入回归的唯一年份数:", uniqueN(used_rows$year), "\n")
      cat("SOM 是否仍在回归样本?", "SOM" %in% used_rows$iso3c, "\n")
    }

    # ---- (d) 剔除 SOM 后 ----
    cat("\n=== (d) 剔除 Somalia 后 ===\n")
    sub_noSOM <- sub[iso3c != "SOM"]
    cat("剔除SOM后子集行数:", nrow(sub_noSOM),
        " (原:", nrow(sub), ", 差:", nrow(sub)-nrow(sub_noSOM), ")\n")
    fit2 <- tryCatch(
      feols(hale ~ ghe_share_gdp + ln_gdppc + urbanization + fertility_rate |
              iso3c + year, data=sub_noSOM, vcov=~iso3c),
      error = function(e) { cat("回归报错:", conditionMessage(e), "\n"); NULL }
    )
    if (!is.null(fit2)) cat("剔除SOM后 nobs =", nobs(fit2), "\n")

    # ---- 对照: SOM 是否因 urbanization/fertility 全缺失而被回归自动剔除 ----
    cat("\n=== 关键判定 ===\n")
    cat("Sub-sample 行数(含缺失):", nrow(sub), "\n")
    cat("回归 nobs(fit)            :", if(!is.null(fit)) nobs(fit) else NA, "\n")
    cat("差额 = SOM 行数?", if(!is.null(fit)) nrow(sub)-nobs(fit), "vs SOM行数",
        if("SOM"%in%sub$iso3c) sub[iso3c=="SOM",.N] else 0, "\n")
    cat("\n[判定依据] nobs(fit) 应等于主稿 Table 2 的 N; G_fit 应等于簇数 G。\n")
  }
}
