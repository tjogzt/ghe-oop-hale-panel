#!/usr/bin/env python3
# S13 OOP mediation pathway — matplotlib 矢量重绘(v2:ASCII 负号/prime、居中点、3.3in 高)
# 数字源:04_mediation_oop.R 重跑(mediation_oop.csv)
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

ZHUSHA, SHIQING, GREY = "#C23531", "#3D6BA8", "#737373"
B = "\u00b7"  # Lancet middle dot

fig, ax = plt.subplots(figsize=(6.61, 3.3), dpi=300)  # 168mm 宽
ax.set_xlim(0, 10); ax.set_ylim(0, 5.0)
ax.axis("off")

def node(x, y, w, h, text, fs=10.5, bold=False):
    box = FancyBboxPatch((x-w/2, y-h/2), w, h, boxstyle="round,pad=0.08,rounding_size=0.12",
                         linewidth=1.2, edgecolor="black", facecolor="white")
    ax.add_patch(box)
    ax.text(x, y, text, ha="center", va="center", fontsize=fs,
            fontweight="bold" if bold else "normal")

def arrow(x1, y1, x2, y2, color, lw=1.8, rad=0.0):
    a = FancyArrowPatch((x1, y1), (x2, y2), arrowstyle="-|>", mutation_scale=16,
                        linewidth=lw, color=color, connectionstyle=f"arc3,rad={rad}")
    ax.add_patch(a)

node(1.6, 2.9, 1.7, 1.1, "GHE\n(% of GDP)", fs=10.5, bold=True)
node(5.0, 2.9, 2.0, 1.1, "ln OOP\n(share of CHE)", fs=10.5, bold=True)
node(8.4, 2.9, 1.7, 1.1, "HALE\n(years)", fs=10.5, bold=True)

arrow(2.55, 3.35, 3.95, 3.35, ZHUSHA, lw=2.0)
ax.text(3.25, 3.75, f"a = -0{B}120***", ha="center", fontsize=10, color=ZHUSHA)

arrow(6.05, 3.35, 7.45, 3.35, ZHUSHA, lw=2.0)
ax.text(6.75, 3.75, f"b = -0{B}835*", ha="center", fontsize=10, color=ZHUSHA)

arrow(2.2, 1.9, 7.8, 1.9, SHIQING, lw=1.6)
ax.text(5.0, 1.55, f"c' = -0{B}222* (direct)", ha="center", fontsize=10, color=SHIQING)

ax.text(5.0, 0.70, f"Total effect c = -0{B}122  (indirect a\u00d7b = +0{B}100, bootstrap 95% CI +0{B}02 to +0{B}23)",
        ha="center", fontsize=9.5, style="italic")
ax.text(9.9, 0.25, "*p < 0.05, **p < 0.01, ***p < 0.001", ha="right", fontsize=8, color=GREY)

plt.tight_layout(pad=0.3)
plt.savefig("/Users/taozhu/my researches/lancet_financial_v3/results/figures/figS13_oop_pathway.pdf",
            format="pdf")
print("Saved: figS13_oop_pathway.pdf (v2)")
