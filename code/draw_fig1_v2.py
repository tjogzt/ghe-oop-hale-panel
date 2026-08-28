#!/usr/bin/env python3
# Figure 1 (Study design) — matplotlib 矢量重绘 v3
# 修复:长行拆分、框加高、ASCII 符号、年份写全
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
import matplotlib.font_manager as fm

for f in ["/Library/Fonts/Arial.ttf", "/System/Library/Fonts/Supplemental/Arial.ttf"]:
    try:
        fm.fontManager.addfont(f)
        plt.rcParams["font.family"] = "Arial"
        break
    except Exception:
        pass

GREY_D = "#4D4D4D"
B = "\u00b7"  # middle dot only
# 调色板统一:区块填充浅灰(与全稿 theme_bw 白底一致),关键数字用朱砂/石青点缀
# 中国风色系加深版(对比强烈):填充 + 同色系边框双编码
FILL_A = "#F0C4C2"   # 朱砂淡(数据源/面板/低收入列)
FILL_B = "#C2D9EE"   # 石青淡(Primary 列/数据源)
FILL_C = "#E6C4CC"   # 胭脂淡(Triangulation 列)
FILL_D = "#BBD9EA"   # 靛青淡(Policy 列)
FILL_K = "#F0E8D8"   # 浅暖灰(关键发现)
ZHUSHA, SHIQING = "#C23531", "#3D6BA8"
YANZHI, DIANQING = "#9D2933", "#177CB0"

fig, ax = plt.subplots(figsize=(9.2, 6.0), dpi=300)
ax.set_xlim(0, 18.4); ax.set_ylim(0, 12.0)
ax.axis("off")

def box(x, y, w, h, fc="white", ec="black", lw=1.0):
    b = FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.06,rounding_size=0.08",
                       linewidth=lw, edgecolor=ec, facecolor=fc)
    ax.add_patch(b)
    return b

def txt(x, y, s, fs=8.5, bold=False, ha="center", va="center", color="black"):
    ax.text(x, y, s, ha=ha, va=va, fontsize=fs,
            fontweight="bold" if bold else "normal", color=color, linespacing=1.4)

def arrow(x1, y1, x2, y2, color="black", lw=1.2):
    a = FancyArrowPatch((x1, y1), (x2, y2), arrowstyle="-|>", mutation_scale=13,
                        linewidth=lw, color=color)
    ax.add_patch(a)

def sect_title(x, y, s):
    ax.text(x, y, s, fontsize=11.5, fontweight="bold", color=GREY_D, ha="left")

# ===== A: Data sources & panel construction =====
sect_title(0.4, 11.6, "A.  Data sources, panel construction, and sample flow")

srcs = [
    (0.4, 9.9, "GBD 2023", "Results Tool", "HALE at birth", FILL_B),
    (5.0, 9.9, "World Bank WDI", "", "GHE, GDP pc, OOP, covariates", FILL_B),
    (9.6, 9.9, "WGI 2025", "", "governance composite (α=0.97)", FILL_B),
    (14.2, 9.9, "IMF GFS + WDI", "", "tax revenue (IV)", FILL_B),
]
for x, y, t1, t2, s, fc in srcs:
    box(x, y, 3.4, 1.35, fc=fc, ec=SHIQING, lw=1.2)
    txt(x+1.7, y+0.95, t1, fs=9.5, bold=True)
    if t2: txt(x+1.7, y+0.62, t2, fs=9)
    txt(x+1.7, y+0.3, s, fs=8.5)
    if x < 14:
        arrow(x+3.4, y+0.68, x+4.28, y+0.68)

# Panel construction(两行,加高)
box(0.4, 7.4, 17.2, 1.6, fc=FILL_A, ec=ZHUSHA, lw=1.2)
txt(9.0, 8.55, "Panel construction:  190 countries × 23 years (2000-2022) = 4,370 country-years", fs=9.5, bold=True)
txt(9.0, 8.05, "Sample flow:  exclude aggregate entities  →  4,304 complete-case country-years", fs=8)
txt(9.0, 7.68, "(189 countries; Somalia excluded)  →  +governance controls 4,098  →  non-missing tax revenue (IV-2SLS) 2,753", fs=8)
arrow(9.0, 7.4, 9.0, 6.6)

# ===== B: Analytical framework =====
sect_title(0.4, 6.5, "B.  Analytical framework")
cols = [
    ("Primary", 0.4, ["Pooled OLS (descriptive)", "Country FE",
                      "TWFE  β = -0.12 (p = 0.077)", "Long-difference"], FILL_A),
    ("Triangulation", 4.9, ["Event study (GHE spikes, ref k = -5)", "Synthetic control (6 reforms)",
                            "OOP pathway decomposition", "Temporal aggregation (5/10-yr)"], FILL_A),
    ("Low-income deepening", 9.4, ["Wild cluster bootstrap (G = 23)", "Leave-one-out",
                                   "Dose-response & lag structure", "Reverse-causality check"], FILL_A),
    ("Policy & heterogeneity", 13.9, ["Income groups (LIC/LMIC/UMIC/HIC)", "Population-weighted TWFE",
                                      "MDG (2000-15) vs SDG (2016-22)", "Exclusion bounds (+0.10/+0.20)"], FILL_A),
]
for i_col, (name, x, items) in enumerate([(c[0], c[1], c[2]) for c in cols]):
    fc = [FILL_B, FILL_C, FILL_A, FILL_D][i_col]
    ec = [SHIQING, YANZHI, ZHUSHA, DIANQING][i_col]
    box(x, 3.3, 4.1, 2.9, fc=fc, ec=ec, lw=1.4)
    txt(x+2.05, 5.85, name, fs=9.5, bold=True)
    for i, it in enumerate(items):
        txt(x+2.05, 5.3 - i*0.62, it, fs=8.5)
arrow(9.0, 3.3, 9.0, 2.5)

# ===== Key findings =====
box(0.4, 0.5, 17.2, 1.7, fc=FILL_K, ec=GREY_D, lw=1.2)
txt(9.0, 1.7, "Key findings:", fs=9.5, bold=True)
txt(9.0, 1.25, "LIC  B = +0.85 (bootstrap-t p = 0.065)      |      OOP down 11% per pp GHE (path a B = -0.120)      |      Overall TWFE ~ 0 (-0.12)",
    fs=9.5, bold=True)

plt.tight_layout(pad=0.3)
plt.savefig("/Users/taozhu/my researches/lancet_financial_v3/results/figures/fig0_study_design_v2.pdf", format="pdf")
print("Saved: fig0_study_design_v2.pdf (v3)")
