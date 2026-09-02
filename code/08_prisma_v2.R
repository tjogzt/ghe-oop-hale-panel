# PRISMA flow diagram v3 — 双库检索(PubMed + OpenAlex),2026-08-24
suppressMessages(library(grDevices))
out <- "/Users/taozhu/my researches/lancet_financial_v3/results/figures/figS1_prisma.pdf"
cairo_pdf(out, width = 7, height = 8.6, family = "Arial")

par(mar = c(0.5, 0.5, 0.5, 0.5))
plot(NA, xlim = c(0, 10), ylim = c(0, 13), axes = FALSE, xlab = "", ylab = "")

box <- function(x1, y1, x2, y2) rect(x1, y1, x2, y2, border = "black", lwd = 1.2)
lab <- function(x, y, txt, cex = 0.75, font = 1) text(x, y, txt, adj = 0.5, cex = cex, font = font)

# Identification: two databases
box(1, 11.3, 9, 12.9)
lab(5, 12.4, "PubMed (MEDLINE) via E-utilities", cex = 0.72)
lab(5, 12.0, "n = 464", cex = 0.8, font = 2)
box(1, 9.6, 9, 11.0)
lab(5, 10.6, "OpenAlex (supplementary search)", cex = 0.72)
lab(5, 10.2, "n = 1,340", cex = 0.8, font = 2)

arrows(5, 11.25, 5, 11.05, length = 0.08, lwd = 1.2)
arrows(5, 9.55, 5, 9.25, length = 0.08, lwd = 1.2)

# After dedup
box(1, 7.8, 9, 9.2)
lab(5, 8.75, "Records after duplicates removed", cex = 0.72)
lab(5, 8.35, "n = 1,394 (410 duplicates removed)", cex = 0.8, font = 2)

arrows(5, 7.75, 5, 7.25, length = 0.08, lwd = 1.2)

# Screening
box(1, 5.9, 9, 7.2)
lab(5, 6.8, "Records screened (title and abstract)", cex = 0.72)
lab(5, 6.4, "n = 1,394", cex = 0.8, font = 2)

arrows(5, 5.85, 5, 5.35, length = 0.08, lwd = 1.2)

# Excluded box (right, PRISMA 2020 standard)
box(5.3, 2.6, 9.5, 5.3)
lab(7.4, 4.95, "Records excluded", cex = 0.75, font = 2)
lab(7.4, 4.45, "n = 1,106", cex = 0.8, font = 2)
lab(7.4, 3.95, "Non-peer-reviewed grey literature (n = 159)", cex = 0.65)
lab(7.4, 3.65, "Sub-national units (n = 54)", cex = 0.65)
lab(7.4, 3.35, "Individual- or facility-level design (n = 48)", cex = 0.65)
lab(7.4, 3.05, "Non-quantitative design (n = 353)", cex = 0.65)
lab(7.4, 2.8, "No country-level financing\u2013health (n = 492)", cex = 0.65)

arrows(5, 5.3, 5.25, 5.3, length = 0.08, lwd = 1.2)

# Included
box(1, 0.8, 9, 2.2)
lab(5, 1.8, "Country-level studies included in the evidence synthesis", cex = 0.72)
lab(5, 1.3, "n = 288 (PubMed 105, OpenAlex 183)", cex = 0.8, font = 2)

arrows(5, 2.6, 5, 2.25, length = 0.08, lwd = 1.2)

# Labels
text(0.15, 12.2, "Identification", srt = 90, cex = 0.75, font = 2)
text(0.15, 6.55, "Screening", srt = 90, cex = 0.75, font = 2)
text(0.15, 1.5, "Included", srt = 90, cex = 0.75, font = 2)

dev.off()
cat("done:", out, "\n")
