# Data Provenance

All data used in the manuscript "Government Health Expenditure and Life Expectancy: Evidence from a Global Panel of 190 Countries, 2000–2022."

## Primary Data Sources

### 1. GBD 2023 Results Tool — Health-Adjusted Life Expectancy (HALE)

- **Source:** Global Burden of Disease Study 2023 (GBD 2023), Institute for Health Metrics and Evaluation (IHME)
- **Access URL:** https://vizhub.healthdata.org/gbd-results/
- **Download date:** July 2024 (initial), refreshed July 2026
- **Query parameters:**
  - Measure: Health-Adjusted Life Expectancy (HALE)
  - Metric: Years
  - Age: <1 year (at birth)
  - Sex: Both
  - Year: 2000–2023 (HALE available through 2023; analysis panel constrained to 2000–2022 by the exposure series — see PANEL_END_YEAR_RATIONALE.md)
  - Location: All countries and territories
  - Cause: All causes
- **Version:** GBD 2023 (published April 2025 in The Lancet)
- **License:** Free for academic use; GBD terms of use apply
- **Key reference:** GBD 2023 Demographics Collaborators. Lancet 2025; 406: 1269–1315.

### 2. World Bank World Development Indicators (WDI)

- **Source:** World Bank DataBank
- **Access:** WDI API v2 (`https://api.worldbank.org/v2/`)
- **Download date:** July 15, 2026
- **Indicators used:**

| Variable | Indicator Code | Full Name |
|----------|---------------|-----------|
| GHE/GDP | `SH.XPD.GHED.GD.ZS` | Domestic general government health expenditure (% of GDP) |
| GDP per capita | `NY.GDP.PCAP.PP.KD` | GDP per capita, PPP (constant 2021 international $) |
| Urbanization | `SP.URB.TOTL.IN.ZS` | Urban population (% of total population) |
| Fertility rate | `SP.DYN.TFRT.IN` | Fertility rate, total (births per woman) |
| OOP expenditure | `SH.XPD.OOPC.CH.ZS` | Out-of-pocket expenditure (% of current health expenditure) |
| Infant mortality | `SP.DYN.IMRT.IN` | Mortality rate, infant (per 1,000 live births) |
| Tax revenue | `GC.TAX.TOTL.GD.ZS` | Tax revenue (% of GDP) |
| Population | `SP.POP.TOTL` | Population, total

- **Query:** All countries, 2000–2022, bulk download via API (see PANEL_END_YEAR_RATIONALE.md for why the analysis panel ends in 2022)
- **License:** CC BY 4.0 (World Bank Open Data)
- **API endpoint:** `https://api.worldbank.org/v2/country/all/indicator/{CODE}?format=json&per_page=20000&date=2000:2023`

### 3. Worldwide Governance Indicators (WGI)

- **Source:** World Bank, Kaufmann-Kraay-Mastruzzi
- **Access URL:** https://www.worldbank.org/en/publication/worldwide-governance-indicators
- **Download date:** July 2026
- **Version:** 2025 revision (data through 2024)
- **Indicators:** All 6 dimensions (Voice and Accountability, Political Stability, Government Effectiveness, Regulatory Quality, Rule of Law, Control of Corruption)
- **Composite:** Equal-weighted mean of all 6 indicators (Cronbach's $\alpha = 0.97$)
- **License:** CC BY 4.0
- **Key reference:** Kaufmann D, Kraay A, Mastruzzi M. World Bank Policy Research Working Paper; 2025.

### 4. IMF Government Finance Statistics

- **Source:** IMF Data, Government Finance Statistics
- **Access URL:** https://data.imf.org/gfs
- **Download date:** July 2026
- **Indicator:** Tax revenue (% of GDP)
- **Supplement:** WDI indicator `GC.TAX.TOTL.GD.ZS` used where IMF data missing
- **License:** IMF Data Terms of Use

### 5. WHO Global Health Expenditure Database (GHED)

- **Source:** World Health Organization
- **Access URL:** https://apps.who.int/nha/database
- **Download date:** July 2026 (from project raw data directory)
- **File:** `data/raw/who/GHED_data.XLSX` and `data/raw/who/who_WHOSIS_000001.csv`
- **Content:** Health expenditure by financing scheme and function
- **Coverage:** Variable by country and year, generally 2000–2022
- **License:** WHO data policy

## Data Processing

The integrated panel was constructed by:
1. Merging all source datasets on ISO-3 country code and year
2. Removing World Bank aggregate entities (e.g., "Arab World", "Sub-Saharan Africa")
3. Removing records with missing or unclassified income group
4. Log-transforming all monetary variables
5. Computing baseline (2000) World Bank income classification as time-invariant attribute
6. Computing governance composite as equal-weighted mean of 6 WGI dimensions

### Data Quality Notes

- HALE is a modelled estimate from GBD, not directly observed
- GHE/GDP coverage is sparse before 2005 for many low-income countries
- Tax revenue data has limited coverage in low-income settings (~50% missing)
- OOP expenditure data is more complete but still has ~15% missing
- Governance indicators are survey-based and subject to measurement error
- COVID-19 pandemic (2020-2021) created extreme outliers in both GHE and health outcomes

## Version Tracking

| Date | Event | Description |
|------|-------|-------------|
| 2024-07 | Initial data collection | GBD 2021 results, WDI 2023 |
| 2025-04 | GBD update | Updated to GBD 2023 (published April 2025) |
| 2025-07 | WGI update | Updated to WGI 2025 revision |
| 2026-07 | Full refresh | Added 2023 data; refreshed all WDI indicators |

## Reproducibility

The integrated panel file (`integrated_panel_final.csv`) contains all variables needed to reproduce the analysis. Raw source files are archived in `data/raw/` subdirectories for provenance tracking.
