# Panel Period and Data Versions

**Panel period: 2000–2023** (analysis sample 4,499 country-years, 190 countries).

## Why the panel now runs to 2023

An earlier version of this package (v1–v9) stopped in 2022 because the World Bank WDI API served
government health expenditure (GHE, `SH.XPD.GHED.GD.ZS`) for only 56 of 190 countries in 2023 at
the July 2026 data lock. The **WDI release of 8 October 2026** changed that:

1. **2023 GHE coverage**: 191 of 191 panel countries now have 2023 values.
2. **Historical revision**: the 2026 release also revised historical GHE. Of 707 overlapping
   observations, **430 changed by more than 0.01 pp**, 188 by more than 0.1 pp, and the largest
   single change was **4.95 pp** (Timor-Leste 2022, from 10.31 to 5.36 % of GDP).

Because the historical values themselves changed, the panel was **rebuilt in full** rather than
extended. Mixing old historical values with a new 2023 observation would have produced an
internally inconsistent series. All six WDI indicators (GHE, OOP, GDP per capita, urbanisation,
fertility, population) were re-downloaded in a single vintage.

## Data versions (all locked 2026-10-08 to 2026-10-20)

| Component | Source | Vintage |
|---|---|---|
| HALE at birth | GBD 2023 Results Tool (IHME) | 1990–2023 back-estimation, released 2025 |
| GHE (% GDP), OOP, GDP pc, urbanisation, fertility, population | World Bank WDI | 2026-10-08 release |
| Governance composite (6 WGI dimensions, Cronbach α = 0.97) | Worldwide Governance Indicators | 2025 revision (data to 2024) |
| Income groups | World Bank FY2026 classification | Togo reclassified to lower-middle income |
| Tax revenue (instrument) | IMF Government Finance Statistics + WDI | latest available |

**Income-group note.** The FY2026 classification moved Togo from low to lower-middle income, leaving
25 low-income economies in the World Bank list. Our low-income estimation sample contains **24**
countries (547 country-years), because Somalia enters the panel only from 2013. The main analysis uses
the current FY2026 grouping; the pre-revision grouping is reported as a sensitivity analysis, and all
24 leave-one-out estimates are reported so that the result cannot be read as driven by any single
country.

## What changed relative to the 2000–2022 panel

| Quantity | 2000–2022 (v9) | 2000–2023 (v10) |
|---|---|---|
| Analysis sample | 4,304 country-years, 189 countries | **4,499 country-years, 190 countries** |
| TWFE coefficient | −0.122 (p = 0.077) | **−0.148 (p = 0.030)** |
| Low-income coefficient | +0.846 (p = 0.030), 23 countries | **+0.806 (p = 0.040), 24 countries** |
| Long difference | −0.564 (p = 0.004) | −0.564 (p = 0.004), 186 countries |

The direction of both headline estimates is unchanged; the pooled coefficient crosses conventional
significance only because the sample is larger and the historical exposure values were revised.

## Specifications reported in the manuscript

The pooled TWFE coefficient is **not robust across prespecified specifications**, and the manuscript
reports this explicitly rather than selecting one:

| Specification | β (HALE years per pp of GDP) | p |
|---|---|---|
| TWFE, country + year FE (primary) | −0.148 | 0.030 |
| + country-specific linear trends | −0.036 | 0.351 |
| Restricted to 2000–2019 | −0.087 | 0.198 |
| Complete case vs multiple imputation | −0.148 / −0.074 | 0.030 / 0.086 |

Only one of these four prespecified specifications reaches conventional significance. Complete-case
exclusions are concentrated among high-income country-years before 2011, the stratum in which the
association is null.

## Reproducibility

- `code/00_lit_search_v2.sh` — literature search (PRISMA ledger in `submission/`)
- `code/01_main_analysis.R` — panel construction checks and primary models
- `code/` — all remaining analyses in the order they appear in the manuscript
- `results/tables/` — every number in the manuscript and supplement traces to a CSV here
- `results/figures/` — the 14 figures exactly as they appear (PDF + PNG)

Every table cell in the supplement was machine-checked against its source CSV
(396 cells, 0 mismatches, sign-checked) before release.
