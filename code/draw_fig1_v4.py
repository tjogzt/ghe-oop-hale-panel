#!/usr/bin/env python3
"""Figure 1 v4 — drawn at final print size 180 x 115 mm (double column), 1:1 scale.
Adopts MoA rulings: no source-to-source arrows, 12 framework items (3 per box),
list text 8 pt, box titles 9 pt, section titles 10 pt, FancyArrowPatch -|> arrows.
"""
import matplotlib
matplotlib.use("Agg")
matplotlib.rcParams["pdf.fonttype"] = 42
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

MM_W, MM_H = 180.0, 115.0
GREY_D = "#4D4D4D"
FILL_A = "#F0C4C2"; FILL_B = "#C2D9EE"; FILL_C = "#E6C4CC"
FILL_D = "#BBD9EA"; FILL_K = "#F0E8D8"
SHIQING = "#3D6BA8"; YANZHI = "#9D2933"; ZHUSHA = "#C23531"; DIANQING = "#177CB0"

fig, ax = plt.subplots(figsize=(MM_W / 25.4, MM_H / 25.4), dpi=300)
ax.set_xlim(0, MM_W); ax.set_ylim(0, MM_H)
ax.axis("off"); ax.set_aspect("equal")

def box(x, y, w, h, fc="white", ec="black", lw=1.0, r=1.2):
    ax.add_patch(FancyBboxPatch((x + r, y + r), w - 2*r, h - 2*r,
                                boxstyle=f"round,pad={r}", fc=fc, ec=ec, lw=lw))

def txt(x, y, s, fs=8.0, bold=False, color="black", style="normal", ha="center"):
    ax.text(x, y, s, fontsize=fs, fontweight="bold" if bold else "normal",
            ha=ha, va="center", color=color, fontstyle=style, fontfamily="DejaVu Sans")

def arr_v(x, y_from, y_to, main=True):
    ms = 20 if main else 14
    lw = 1.6 if main else 1.2
    ax.add_patch(FancyArrowPatch((x, y_from), (x, y_to), arrowstyle="-|>",
                                 mutation_scale=ms, lw=lw, color=GREY_D,
                                 shrinkA=0, shrinkB=0))

def sect(x, y, s):
    ax.text(x, y, s, fontsize=10, fontweight="bold", color=GREY_D,
            ha="left", va="center", fontfamily="DejaVu Sans")

# ---------------- A. Data sources ----------------
sect(3, 110.5, "A.  Data sources")
src = [
    ("GBD 2023\nResults Tool", "HALE at birth", 3),
    ("World Bank WDI", "GHE, GDP pc, OOP,\nurbanisation, fertility", 48),
    ("WGI 2025", "governance composite\n(\u03b1 = 0.97)", 93),
    ("IMF GFS + WDI", "tax revenue\n(instrument)", 138),
]
for title, sub, x in src:
    box(x, 89, 39, 16, fc=FILL_B, ec=SHIQING, lw=1.0)
    txt(x + 19.5, 100.0, title, fs=9, bold=True)
    txt(x + 19.5, 93.2, sub, fs=8, color=GREY_D)

arr_v(90, 89, 84.5, main=True)

# ---------------- Panel construction ----------------
box(3, 66, 174, 18, fc=FILL_A, ec=YANZHI, lw=1.5)
txt(90, 81.4, "Panel construction", fs=9, bold=True)
txt(90, 77.2, "190 countries \u00d7 24 years (2000\u20132023) = 4,560 country-years", fs=8)
# sample flow as a horizontal funnel
flow = [("4,560", "country-years"), ("4,499", "complete case"), ("4,292", "+ governance"), ("2,869", "IV-2SLS")]
fx = [26, 68, 112, 154]
for i, ((num, lab), x) in enumerate(zip(flow, fx)):
    txt(x, 72.0, num, fs=9, bold=True)
    txt(x, 68.2, lab, fs=8, color=GREY_D)
    if i < 3:
        ax.add_patch(FancyArrowPatch((x + 12, 70.1), (fx[i+1] - 12, 70.1), arrowstyle="-|>",
                                     mutation_scale=12, lw=1.0, color=GREY_D, shrinkA=0, shrinkB=0))

arr_v(90, 66, 61.5, main=True)

# ---------------- B. Analytical framework ----------------
sect(3, 58.8, "B.  Analytical framework")
cols = [
    ("Primary", ["Country FE", "TWFE  \u03b2 = \u22120.15", "Long-difference"], 3, FILL_B, SHIQING),
    ("Triangulation", ["Event study (spikes)", "Synthetic control", "OOP pathway"], 48, FILL_C, YANZHI),
    ("Low-income", ["Wild bootstrap (G = 24)", "Dose-response", "Reverse-causality"], 93, FILL_A, ZHUSHA),
    ("Policy", ["Income groups", "MDG vs SDG eras", "Exclusion bounds"], 138, FILL_D, DIANQING),
]
for name, items, x, fc, ec in cols:
    box(x, 21, 39, 35, fc=fc, ec=ec, lw=1.2)
    txt(x + 19.5, 51.0, name, fs=9, bold=True)
    for i, it in enumerate(items):
        txt(x + 19.5, 42.0 - i * 8.4, it, fs=8)

arr_v(90, 21, 18.0, main=True)

# ---------------- Key findings ----------------
box(3, 2, 174, 15, fc=FILL_K, ec=GREY_D, lw=1.2)
txt(90, 13.8, "Key findings", fs=9, bold=True)
txt(90, 9.2, "TWFE  \u03b2 = \u22120.15 (p = 0.030);   \u22120.04 (p = 0.351) with country-specific trends",
    fs=8.5, bold=True)
txt(90, 5.2, "Low-income  \u03b2 = +0.81 (bootstrap p = 0.065)   |   Out-of-pocket share down 13% per pp GHE",
    fs=8.5, bold=True)

plt.subplots_adjust(left=0.004, right=0.996, top=0.996, bottom=0.004)
out = "/Users/taozhu/my researches/lancet_financial_v3/results/figures/fig0_study_design_v4.pdf"
fig.savefig(out, format="pdf", facecolor="white")
fig.savefig(out.replace(".pdf", ".png"), dpi=300, facecolor="white")
print("Saved:", out)
print("print size: %.0f x %.0f mm (1:1)" % (MM_W, MM_H))

# ---- automated checks ----
from matplotlib.text import Text
fig.canvas.draw()
exts = []
for t in ax.texts:
    if t.get_text().strip():
        bb = t.get_window_extent(fig.canvas.get_renderer())
        exts.append((t.get_text()[:28], t.get_fontsize(), bb))
minsz = min(e[1] for e in exts)
print("minimum font size in figure: %.1f pt" % minsz)
overlaps = 0
for i in range(len(exts)):
    for j in range(i + 1, len(exts)):
        a, b = exts[i][2], exts[j][2]
        if a.overlaps(b):
            # ignore tiny intersections
            ox = min(a.x1, b.x1) - max(a.x0, b.x0)
            oy = min(a.y1, b.y1) - max(a.y0, b.y0)
            if ox > 1 and oy > 1:
                overlaps += 1
                print("  OVERLAP:", exts[i][0], "<->", exts[j][0])
print("text overlaps: %d" % overlaps)

# ---- box-title overflow check: title width vs box width (39 mm) ----
BOX_W_MM = 39.0
bad = 0
for t in ax.texts:
    if t.get_fontsize() >= 9 and t.get_fontweight() == "bold" and not t.get_text().startswith(("A.", "B.")):
        bb = t.get_window_extent(fig.canvas.get_renderer())
        w_mm = bb.width / fig.dpi * 25.4
        if w_mm > BOX_W_MM - 2.0:
            bad += 1
            print("  TITLE WIDE: '%s' = %.1f mm (box %.0f mm)" % (t.get_text()[:28], w_mm, BOX_W_MM))
print("box-title overflow: %d" % bad)
