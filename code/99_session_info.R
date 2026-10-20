#!/usr/bin/env Rscript
# Generate session information for the main analytical pipeline
# (reproducibility record referenced in Supplementary Methods)
suppressMessages({
  library(fixest); library(data.table); library(ggplot2)
  if (requireNamespace("tidysynth", quietly=TRUE)) library(tidysynth)
  if (requireNamespace("mice", quietly=TRUE)) library(mice)
  if (requireNamespace("fwildclusterboot", quietly=TRUE)) library(fwildclusterboot)
})
sink("/Users/taozhu/my researches/lancet_financial_v3/results/sessioninfo_main.txt")
cat("Main analytical pipeline session information\n")
cat("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), "\n\n")
cat(capture.output(sessionInfo()), sep="\n")
sink()
cat("Saved: results/sessioninfo_main.txt\n")
