# Government Health Expenditure, Out-of-Pocket Spending, and Healthy Life Expectancy in 190 Countries, 2000–2022

[![DOI](https://img.shields.io/badge/DOI-10.5281%2Fzenodo.22028177-003399.svg)](https://doi.org/10.5281/zenodo.22028177)

## A Global Country-Year Panel Analysis

### Authors
Tao Zhu¹²✉  (and co-authors; see manuscript title page)

¹ Department of Obstetrics and Gynecology, Tongji Hospital, Tongji Medical College, Huazhong University of Science and Technology, Wuhan, China
² Key Laboratory of Cancer Invasion and Metastasis, Ministry of Education, Tongji Hospital, HUST, Wuhan, China
✉ zhutao@tjh.tjmu.edu.cn

---

## Overview

This repository contains the complete replication package for the manuscript *"Domestic Government Health Expenditure, Out-of-Pocket Spending, and Healthy Life Expectancy in 190 Countries, 2000–2022"* (target journal: The Lancet Global Health). All tables, figures, and statistical outputs can be reproduced from publicly available data using the scripts provided.

### Key findings
- The within-country association between domestic government health expenditure (GHE) and healthy life expectancy (HALE) is near zero overall (two-way fixed-effects β = −0.12, p = 0.077), in sharp contrast to the large positive cross-sectional association (+1.47).
- The low-income stratum shows a positive association (β = +0.85; wild cluster bootstrap-t p = 0.065), robust to leave-one-out re-estimation (+0.66 to +1.02), concentrated in the MDG era (+1.27, p = 0.038) and attenuated to null in the SDG era (+0.03, p = 0.928).
- GHE is associated with improved financial protection: each percentage point of GDP shifted into public financing corresponds to an ≈11% relative reduction in out-of-pocket spending (indirect effect a×b = +0.10; bootstrap 95% CI +0.02 to +0.24).

---

## Repository Structure

```
ghe-oop-hale-panel/
├── code/                          # 43 analysis scripts (R 4.5.0 primary; Python 3.9+ utilities)
│   ├── 01_main_analysis.R         # Primary TWFE analysis
│   ├── 03_event_study.R           # Event study around GHE spikes (ref k = −5)
│   ├── 04_mediation_oop.R         # OOP pathway decomposition
│   ├── 10_wild_bootstrap_E5.R     # Low-income wild cluster bootstrap
│   ├── A2_synthetic_control_reforms.R  # SCM case studies
│   └── ...                        # Full pipeline, see README below
├── results/
│   ├── tables/                    # All analysis tables (CSV)
│   └── figures/                   # Publication figures (PDF, Wong colour-blind palette)
├── results_codex/                 # Model objects and processed panel (RDS)
├── manuscript/                    # LaTeX source + compiled PDFs
├── submission/                    # STROBE/GATHER checklists, screening records
└── data/                          # Data dictionary and processing notes
```

## Reproducibility

- **Environment**: R 4.5.0 (fixest 0.13.1, data.table 1.16.4, tidysynth 0.2.0, mice 3.17.3, ggplot2 3.5.1, fwildclusterboot 0.13.0), Python 3.9+.
- **Random seed**: 49 for all stochastic procedures.
- **Data sources** (all public): GBD 2023 Results Tool (HALE), World Bank WDI API (GHE, GDP, OOP, covariates), WGI 2025 (governance), IMF GFS (tax revenue).
- **Pipeline order**: 01 → 02 → … → 15, then A1–C4 supplementary scripts.
- Compiled manuscripts: `manuscript/main_manuscript.pdf`, `supplementary_materials.pdf`, `cover_letter.pdf`.

## License

MIT License (see LICENSE). Data are from public sources (GBD, World Bank, WGI, IMF) subject to their respective terms.
