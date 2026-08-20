#!/usr/bin/env python3
"""Apply all 6 final manuscript fixes"""
import re

with open('/Users/taozhu/my researches/lancet_financial_v3/manuscript/main_manuscript.tex', 'r') as f:
    content = f.read()

fixes_applied = 0

# Fix 1: Horse race correct numbers
old1 = ('Within countries, fertility\ndecline, GDP growth, and governance improvement all show stronger and more\n'
        'significant associations with HALE than GHE. The unique within-$R^2$\n'
        'contribution of GHE is negligible (0\\textperiodcentered{}004), suggesting that year-to-year\n'
        'variation in the GHE-to-GDP ratio carries almost no independent information\n'
        'about within-country HALE trajectories beyond what is already captured by\n'
        'broader development trends.')
new1 = ('Within countries, standardised coefficients from the horse-race model\n'
        'ranked fertility decline ($\\beta = -0{\\cdot}23$, $p < 0{\\cdot}001$) and urbanisation\n'
        '($\\beta = +0{\\cdot}29$, $p = 0{\\cdot}035$) as the strongest HALE predictors, followed by\n'
        'governance quality ($\\beta = +0{\\cdot}19$, $p < 0{\\cdot}001$) and GDP per capita\n'
        '($\\beta = +0{\\cdot}09$, $p = 0{\\cdot}062$). GHE had the smallest standardised coefficient\n'
        '($\\beta = -0{\\cdot}05$, $p = 0{\\cdot}016$), consistent with a negligible independent\n'
        'contribution to within-country HALE variation beyond broader development trends.')
if old1 in content:
    content = content.replace(old1, new1)
    fixes_applied += 1
    print("Fix 1: Horse race numbers corrected")

# Fix 2: Fix "governance is the strongest" claim
old2 = ('the finding that governance quality is the strongest within-country\n'
        'predictor of HALE---suggests that \\textit{how} health systems are governed\n'
        'matters at least as much as \\textit{how much} is spent.')
new2 = ('the finding that structural determinants (fertility decline, urbanisation)\n'
        'and governance quality are stronger within-country predictors of HALE than\n'
        'GHE---suggests that \\textit{how} health systems are governed and how societies\n'
        'are structured matter at least as much as \\textit{how much} is spent.')
if old2 in content:
    content = content.replace(old2, new2)
    fixes_applied += 1
    print("Fix 2: Governance ranking corrected")

# Fix 3: Add IMR prominence
old3 = ('Infant mortality analyses in the same sample ($N = 4{,}304$) yielded\n'
        'qualitatively identical conclusions.')
new3 = ('Infant mortality analyses --- a directly observed outcome immune to GBD\n'
        'modelling assumptions --- in the same sample ($N = 4{,}304$) yielded\n'
        'qualitatively identical conclusions (TWFE log-IMR $\\beta = -0{\\cdot}014$,\n'
        '$p = 0{\\cdot}092$; Supplementary Table S3).')
if old3 in content:
    content = content.replace(old3, new3)
    fixes_applied += 1
    print("Fix 3: IMR prominence added")

# Fix 4: Add data provenance section before Role of funding
old4 = '\\subsection{Role of the funding source}'
new4 = ('\\subsection{Data and code availability}\n\n'
        'All data are publicly available from the GBD 2023 Results Tool\n'
        '(\\texttt{https://vizhub.healthdata.org/gbd-results/}; accessed July 19, 2026),\n'
        'the World Bank World Development Indicators API\n'
        '(\\texttt{https://api.worldbank.org/v2/}; accessed July 15, 2026), and the\n'
        'Worldwide Governance Indicators (\\texttt{https://www.govindicators.org};\n'
        '2025 revision). A complete data provenance record, including exact API query\n'
        'parameters, indicator codes, download timestamps, and variable construction\n'
        'protocols, is provided in the replication package\n'
        '(\\texttt{data/raw/README.md}). The analytic dataset and all analysis code are\n'
        'archived with the submission. This study was not pre-registered.\n\n'
        '\\subsection{Role of the funding source}')
if old4 in content:
    content = content.replace(old4, new4)
    fixes_applied += 1
    print("Fix 4: Data provenance section added")

# Fix 5: Add SDG attenuation mention in LIC section (Discussion ~line 636)
old5 = ('In low-income countries, the positive HALE signal is exactly where global\n'
        'health financing targets have their strongest rationale.')
new5 = ('In low-income countries, the suggestive positive HALE signal --- concentrated\n'
        'in the MDG era (2000--2010) and attenuating to zero in the SDG era\n'
        '($\\beta = +0{\\cdot}002$, $p = 0{\\cdot}995$) --- is exactly where global\n'
        'health financing targets retain their strongest rationale, though the\n'
        'temporal attenuation warrants caution in extrapolation.')
if old5 in content:
    content = content.replace(old5, new5)
    fixes_applied += 1
    print("Fix 5: SDG attenuation added to Discussion")

# Fix 6: Add matched DiD mention
old6 = 'Synthetic control analyses were conducted for six major health financing reforms'
new6 = ('Synthetic control and matched difference-in-differences analyses were conducted\n'
        'for six major health financing reforms')
if old6 in content:
    content = content.replace(old6, new6)
    fixes_applied += 1
    print("Fix 6: Matched DiD mentioned")

with open('/Users/taozhu/my researches/lancet_financial_v3/manuscript/main_manuscript.tex', 'w') as f:
    f.write(content)

print(f"\nTotal fixes applied: {fixes_applied}/6")
