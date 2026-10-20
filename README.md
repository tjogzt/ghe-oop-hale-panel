# Government health expenditure and healthy life expectancy in 190 countries, 2000–2023: a within–between panel analysis

[![DOI](https://img.shields.io/badge/DOI-10.5281%2Fzenodo.22028176-003399.svg)](https://doi.org/10.5281/zenodo.22028176)

[English](README.md) | [简体中文](README_zh.md)

## A Global Country-Year Panel Analysis

### Authors
Qingqing Mo¹², Pingbo Chen¹², Cheng Xu¹², Ya Wang¹², Ting Hu¹², Qian Sun¹², Tao Zhu¹²✉

¹ Department of Obstetrics and Gynecology, National Clinical Research Center for Obstetrics and Gynecology, Tongji Hospital, Tongji Medical College, Huazhong University of Science and Technology, Wuhan, China
² Key Laboratory of Cancer Invasion and Metastasis (Ministry of Education), Tongji Hospital, Tongji Medical College, Huazhong University of Science and Technology, Wuhan, China

Correspondence: Tao Zhu, zhutao@tjh.tjmu.edu.cn

---

## Overview

This repository is the complete replication package for the manuscript *"Government health expenditure and healthy life expectancy in 190 countries, 2000–2023: a within–between panel analysis"*.

The study asks a narrow question: **once a country's own level of development is held constant, does moving more of its economy into government health spending buy additional years of healthy life?** The answer differs sharply depending on how the question is posed, and that difference is the paper's main finding.

### Key findings

**Between countries**, the association is large and positive: each additional percentage point of GDP spent by government on health is associated with 1.42 more HALE years (95% CI 1.29–1.56). But this gradient is almost entirely a development gradient — once log GDP per capita, urbanisation and fertility are adjusted for, it collapses to −0.04 (p = 0.17).

**Within countries**, the association is small and **not robust**:

| Specification | β (HALE years per pp of GDP) | p |
|---|---|---|
| Country + year fixed effects (primary) | −0.148 | 0.030 |
| + country-specific linear trends | −0.036 | 0.351 |
| Restricted to 2000–2019 | −0.087 | 0.198 |
| Complete case vs multiple imputation | −0.148 / −0.074 | 0.030 / 0.086 |

Only one of four prespecified specifications reaches conventional significance. We report the full set rather than the significant one.

**Where a negative association does appear, it is concentrated in the wrong place for a causal story.** Splitting the 29 spending-spike episodes by whether real per-capita government spending actually rose shows that the post-spike decline occurs only in the 14 countries where spending genuinely increased (−0.86 HALE years five years later, 95% CI −1.36 to −0.36, with a clean pre-trend), while episodes in which the ratio rose only because GDP fell show nothing (all p > 0.70). This is the signature of spending responding to deteriorating health, not of spending harming health.

**Low-income countries** are the one place with a positive point estimate: +0.81 HALE years per percentage point (clustered p = 0.040, cluster bootstrap p = 0.065, 24 countries). It is directionally robust across all 24 leave-one-out estimates but too imprecise to support a financing target.

**Financial protection behaves differently from health outcomes.** GHE is consistently associated with a lower out-of-pocket share (13% per percentage point of GDP, 95% CI 8–18%), but the indirect path through OOP carries the *opposite* sign to the total association (+0.116 vs −0.148). It is a suppression pattern, not a mediating mechanism, and cannot explain the negative estimate.

**Austerity episodes** are followed by a decline of roughly 0.7–1.4 HALE years under five different estimators (stacked clean controls, pooled DiD, Sun–Abraham, Callaway–Sant'Anna, imputation). The estimators disagree about pre-trends depending on the pre-period window used, so we do not read this causally — but a genuine post-austerity decline cannot be excluded either.

### What this study does not show

It does **not** show that public health spending harms health. It does show that cross-country panels cannot identify the marginal value of additional public spending, and that the negative point estimates that do appear are consistent with spending rising in response to crisis.

## Repository contents

```
code/               analysis scripts, in manuscript order
data/processed/     integrated panel (2000-2023) + variable dictionary
data/raw/           data provenance, vintage record, panel-period rationale
results/tables/     every number in the manuscript and supplement (CSV)
results/figures/    14 figures as published (PDF + PNG)
submission/         literature screening ledger and PRISMA inputs
docs/               supplementary documentation
```

### Data sources
| Component | Source | Vintage |
|---|---|---|
| HALE at birth | GBD 2023 Results Tool (IHME) | 1990-2023 back-estimation |
| GHE, OOP, GDP pc, urbanisation, fertility, population | World Bank WDI | 2026-10-08 release |
| Governance composite | Worldwide Governance Indicators | 2025 revision |
| Income groups | World Bank FY2026 classification | - |
| Literature search | PubMed E-utilities + OpenAlex | 2026-08-14 |

The WDI release of 8 October 2026 both extended GHE coverage to 2023 for all 191 panel countries and revised historical values (430 of 707 overlapping observations changed, largest 4.95 pp). The panel was therefore rebuilt in full rather than extended — see `data/raw/PANEL_PERIOD_AND_DATA_VERSIONS.md`.

### Reproducibility
Run scripts from the repository root. All analyses use R 4.x with `fixest`, `data.table`, `mice`, `did`, and `tidysynth`; figure generation uses R and Python (matplotlib).

Every table cell in the supplementary materials was machine-checked against its source CSV before release: **396 numeric cells, 0 mismatches, sign-checked**.

## Ethics

This study uses only publicly available, country-level aggregate data. No individual-level or identifiable information is included, and no ethics approval was required.

## License

Code: MIT. Data derivatives: CC BY 4.0 (consistent with the source databases' terms).

## Citation

Mo Q, Chen P, Xu C, Wang Y, Hu T, Sun Q, Zhu T. Government health expenditure and healthy life expectancy in 190 countries, 2000-2023: a within-between panel analysis. Replication package, Zenodo. https://doi.org/10.5281/zenodo.22028176
