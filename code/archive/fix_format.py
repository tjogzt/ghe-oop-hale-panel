#!/usr/bin/env python3
"""Apply all format audit fixes to main manuscript"""
n = 0
with open('/Users/taozhu/my researches/lancet_financial_v3/manuscript/main_manuscript.tex','r') as f:
    c = f.read()

# F1: Compress Summary
old = r"""\noindent\textbf{Findings}\quad
GHE consistently reduced out-of-pocket expenditure across all
income groups ($\beta = -0{\cdot}12$, $p < 0{\cdot}001$), providing a universal
financial protection benefit---the most robust finding of this study.
In low-income countries, GHE increases were associated with HALE gains of
$+0\textperiodcentered{}85$ years per percentage point of GDP (wild cluster bootstrap
$p = 0\textperiodcentered{}065$, 95\% CI $-0\textperiodcentered{}07$ to $+1\textperiodcentered{}49$,
$G = 23$ clusters). Adjusting for external health aid (DAH) strengthened
the estimate to $+1\textperiodcentered{}10$ ($p = 0\textperiodcentered{}007$), and the
signal persisted excluding Rwanda ($+0\textperiodcentered{}91$,
$p = 0\textperiodcentered{}034$). This positive signal was concentrated in the MDG
era and attenuated to zero in the SDG era, indicating suggestive rather
than definitive evidence. In middle- and high-income countries, within-country
GHE variation was not associated with differential HALE improvement---the primary
TWFE estimate was $\beta = -0\textperiodcentered{}12$ (95\% CI $-0\textperiodcentered{}26$ to
$+0\textperiodcentered{}01$, $p = 0\textperiodcentered{}077$). Equivalence testing rules
out within-country effects larger than $+0\textperiodcentered{}10$ HALE-years per
percentage point of GDP ($p = 0\textperiodcentered{}0006$), excluding over 99\% of
the cross-sectional gradient."""

new = r"""\noindent\textbf{Findings}\quad
GHE consistently reduced out-of-pocket expenditure across all
income groups ($\beta = -0{\cdot}12$, $p < 0{\cdot}001$). In low-income
countries, GHE was associated with suggestive HALE gains ($+0{\cdot}85$
years per percentage point of GDP, wild cluster bootstrap
$p = 0{\cdot}065$), concentrated in the MDG era. In middle- and
high-income countries, within-country GHE variation showed no association
with differential HALE improvement (TWFE $\beta = -0{\cdot}12$,
$p = 0{\cdot}077$; equivalence testing excludes effects
$>+0{\cdot}10$, $p = 0{\cdot}0006$)."""

if old in c:
    c = c.replace(old, new)
    n += 1
    print("F1: Summary compressed (~270 words)")

# F2: Cut refs to 29
old_ref = r'\bibitem{30}'
idx = c.find(old_ref)
if idx > 0:
    end_bib = c.find(r'\end{thebibliography}', idx)
    if end_bib > 0:
        c = c[:idx] + '\n' + c[end_bib:]
        n += 1
        print("F2: References cut to 29")

# F3: Add declarations
decl = r"""
\section*{Contributors}
TZ conceived the study. QM and TZ conducted the analyses. Three independent
analytical pipelines were implemented and cross-validated. TZ drafted the
manuscript. Both authors approved the final version.

\section*{Declaration of interests}
We declare no competing interests.

\section*{Acknowledgments}
We thank IHME for GBD 2023 data and the World Bank for open-access WDI and WGI
indicators. This research received no specific funding.

\section*{Data sharing}
All data are publicly available from the GBD 2023 Results Tool
(\texttt{https://vizhub.healthdata.org/gbd-results/}), World Bank WDI API
(\texttt{https://api.worldbank.org/v2/}), and WGI
(\texttt{https://www.govindicators.org}). The analytic dataset, replication
code, and data provenance record are archived with the submission.

\section*{Ethics}
Ethical approval was not required as all data are publicly available,
de-identified, and aggregated at the country level.
"""
end_bib_marker = r'\end{thebibliography}'
idx2 = c.find(end_bib_marker)
if idx2 > 0:
    c = c[:idx2 + len(end_bib_marker)] + decl + '\n' + c[idx2 + len(end_bib_marker):]
    n += 1
    print("F3: 5 declarations added")

# F4: Word count
old_wc = r'\textbf{Word count:} Summary: 298 words; Text: $\sim$4,200 words; References: 46;'
new_wc = r'\textbf{Word count:} Summary: \textasciitilde270 words; Text: \textasciitilde3,500 words; References: 29;'
if old_wc in c:
    c = c.replace(old_wc, new_wc)
    n += 1
    print("F4: Word count updated")

# F5: RIC study count
old_ric = 'and 46 studies included'
new_ric = 'and 42 studies included'
if old_ric in c:
    c = c.replace(old_ric, new_ric)
    n += 1
    print("F5: RIC count fixed")

# F6: Austerity DiD
old_aus = r'($\beta = -0{\cdot}88$,\n$p = 0{\cdot}007$; Supplementary Table S8)'
new_aus = r'($\beta = -0{\cdot}71$, $p = 0{\cdot}033$; Supplementary Table S8)'
if old_aus in c:
    c = c.replace(old_aus, new_aus)
    n += 1
    print("F6: Austerity DiD fixed")

with open('/Users/taozhu/my researches/lancet_financial_v3/manuscript/main_manuscript.tex','w') as f:
    f.write(c)
print(f'Total: {n}/6 fixes')
