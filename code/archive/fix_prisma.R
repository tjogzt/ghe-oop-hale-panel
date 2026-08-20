# Fix PRISMA diagram — better spacing, no overlaps
library(data.table)
library(ggplot2)

PROJ <- "/Users/taozhu/my researches/lancet_financial_v3"
setwd(PROJ)

# Wider spacing: boxes at y positions with more room
prisma_data <- data.table(
  stage = c("Records identified through\ndatabase searching\n(n = 1,872)",
            "Records after duplicates removed\n(n = 1,387)",
            "Records screened\n(n = 1,387)",
            "Full-text articles assessed\nfor eligibility\n(n = 86)",
            "Studies included in\nqualitative synthesis\n(n = 42)",
            "Studies included in\nquantitative synthesis\n(n = 42)"),
  y = c(9, 7.5, 6, 4, 2, 0.5)
)

# Exclusion annotations
prisma_excluded <- data.table(
  y = c(5, 1.5),
  label = c("Records excluded\n(title/abstract screening)\n(n = 1,301)",
            "Full-text articles excluded:\n- No GHE exposure: 18\n- Sub-national only: 12\n- No health outcome: 8\n- Review/commentary: 6\n(n = 44)"),
  x = c(2.3, 2.3)
)

p_prisma <- ggplot() +
  # Main flow boxes — taller for multiline text
  geom_rect(data=prisma_data, aes(xmin=0.3, xmax=2.1, ymin=y-0.65, ymax=y+0.65),
            fill="grey97", color="grey40", linewidth=0.4) +
  geom_text(data=prisma_data, aes(x=1.2, y=y, label=stage), size=2.8, lineheight=1.05) +
  # Vertical arrows between boxes
  geom_segment(aes(x=1.2, xend=1.2, y=8.35, yend=8.15),
               arrow=arrow(length=unit(0.12,"cm")), linewidth=0.3) +
  geom_segment(aes(x=1.2, xend=1.2, y=6.85, yend=6.65),
               arrow=arrow(length=unit(0.12,"cm")), linewidth=0.3) +
  geom_segment(aes(x=1.2, xend=1.2, y=5.35, yend=4.65),
               arrow=arrow(length=unit(0.12,"cm")), linewidth=0.3) +
  geom_segment(aes(x=1.2, xend=1.2, y=3.35, yend=2.65),
               arrow=arrow(length=unit(0.12,"cm")), linewidth=0.3) +
  # Exclusion boxes (right side, dashed)
  geom_rect(data=prisma_excluded, aes(xmin=2.5, xmax=4.5, ymin=y-0.55, ymax=y+0.55),
            fill="white", color="grey55", linewidth=0.3, linetype="dashed") +
  geom_text(data=prisma_excluded, aes(x=3.5, y=y, label=label), size=2.4, lineheight=1.05, color="grey40") +
  # Exclusion arrows (horizontal, from right edge of main box to left edge of exclusion)
  geom_segment(aes(x=2.1, xend=2.5, y=5, yend=5),
               arrow=arrow(length=unit(0.08,"cm")), linewidth=0.2, color="grey55") +
  geom_segment(aes(x=2.1, xend=2.5, y=1.5, yend=1.5),
               arrow=arrow(length=unit(0.08,"cm")), linewidth=0.2, color="grey55") +
  # Section labels (left side)
  annotate("text", x=0.1, y=9.7, label="Identification", fontface="bold", size=3.2, hjust=0) +
  annotate("text", x=0.1, y=8.2, label="Screening", fontface="bold", size=3.2, hjust=0) +
  annotate("text", x=0.1, y=5.2, label="Eligibility", fontface="bold", size=3.2, hjust=0) +
  annotate("text", x=0.1, y=2.2, label="Included", fontface="bold", size=3.2, hjust=0) +
  # Database source
  annotate("text", x=0.1, y=10.2, label="Databases: PubMed, Web of Science, EconLit, Google Scholar",
           size=2.3, hjust=0, color="grey45") +
  xlim(-0.2, 5) + ylim(-0.5, 10.8) +
  theme_void() +
  theme(plot.title=element_text(face="bold",size=10,hjust=0.5),
        plot.margin=margin(15,15,15,15))

ggsave("results/figures/figS1_prisma.pdf", p_prisma, width=8, height=7, device=cairo_pdf)
cat("Saved: figS1_prisma.pdf (fixed layout)\n")
