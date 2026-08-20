# Panel End-Year Rationale (2000–2022)

**Why the analysis panel ends in 2022, not 2023:**

1. **GBD HALE**: GBD 2023 release (published April 2025) contains HALE estimates through 2023. The extraction query covered 2000–2023 (refreshed July 2026).
2. **Exposure (GHE, SH.XPD.GHED.GD.ZS)**: sourced from the WHO Global Health Expenditure Database via the WDI API. At data lock (July 2026) the series was available through 2022; WHO GHED updates propagate with a lag.
3. **Governance (WGI)**: 2025 revision (data through 2024).
4. **Intersection rule**: the panel requires exposure + outcome + covariates per row; the exposure series constrains the full panel to 2000–2022.

**Mounted-drive verification (2026-08-17)** — /Volumes/tjogzt4T/lancet_financial_v2:
- The v2 integrated panel (6,084 rows, 2000–2023) has 58 rows in 2023, of which 56 have non-missing GHE. So 2023 GHE covered only 56 of 190 countries at that time — a full-panel 2023 extension was impossible; the v3 panel therefore ends in 2022 (consistent with the Methods statement).
- As of August 2026 the WDI API serves 2023 GHE for some countries (e.g., USA 2023 = 9.0% GDP), so a one-year extension may become feasible at revision; it would require a full pipeline re-run.

**Reproducibility checks completed after mounting the drive:**
- IMR: log IMR TWFE = −0.0144 (SE 0.0085, p = 0.092, N = 4,304); levels IMR TWFE = +0.554 (p = 0.027). The manuscript's earlier "−0.103 deaths per 1,000, p = 0.041" was not reproducible under any specification and has been replaced by the log-model result in the main text and Table S15.
- Ratio decomposition: GHE per capita (log) = −0.156 (SE 0.233, p = 0.505); GDP per capita (log) = +1.032 (SE 0.322, p = 0.002); N = 4,304. Table S15 updated.
