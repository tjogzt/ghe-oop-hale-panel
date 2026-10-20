#!/usr/bin/env python3
"""Restore expanded methods text without touching tables"""
path = '/Users/taozhu/my recherches/lancet_financial_v3/manuscript/supplementary_materials.tex'
with open(path, 'r') as f: c=f.read()

# Only replace the shortened methods sections with expanded versions

# MDE section
old1 = '\\subsection{MDE and Equivalence Testing}\nMDE at 80\\% power:'
new1 = r'''\subsection{Minimal Detectable Effect and Equivalence Testing}
MDE at 80\% power and $\alpha = 0.05$ (two-sided) was calculated as $\text{MDE} = (z_{1-\alpha/2} + z_{1-\beta}) \times \text{SE}_{\text{TWFE}} = 2.80 \times 0.068 = 0.19$ HALE-years per percentage point of GDP, using the clustered standard error from the primary TWFE specification ($N = 4{,}304$, $G = 190$). Equivalence testing followed the two one-sided tests (TOST) framework (ref S2), testing $H_0: \beta \geq \delta$ against $H_1: \beta < \delta$ for equivalence bounds $\delta \in \{0.1, 0.2\}$. The equivalence bound of $+0.1$ HALE-years per pp GDP was chosen as a conservative threshold representing approximately 7\% of the cross-sectional gradient ($+1.47$), well below what would be considered a policy-meaningful effect. The null hypothesis $\beta \geq +0.2$ was rejected at $p < 0.001$ and $\beta \geq +0.1$ at $p = 0.0006$.'''
if 'MDE at 80\\% power:' in c and old1 in c:
    c = c.replace(old1, new1)
    print('F1: MDE expanded')

# Bootstrap
old2 = '\\subsection{Wild Cluster Bootstrap}\nCluster wild bootstrap'
new2 = r'''\subsection{Wild Cluster Bootstrap}
We implemented a cluster wild bootstrap (ref S1) for the low-income TWFE specification to address the small number of clusters ($G = 23$ after listwise deletion). The bootstrap procedure resampled entire country clusters with Rademacher weights ($\pm 1$ with equal probability), re-estimating the full TWFE model on each of $B = 9{,}999$ bootstrap samples. The two-sided bootstrap $p$-value was computed as the fraction of bootstrap estimates whose absolute deviation from the bootstrap mean exceeded the absolute value of the original point estimate ($+0.851$). This approach provides asymptotic refinement over standard cluster-robust inference when the number of clusters is small.'''
if old2 in c:
    c = c.replace(old2, new2)
    print('F2: Bootstrap expanded')

# LOO
old3 = '\\subsection{Leave-One-Out Jackknife}\nFull sample'
new3 = r'''\subsection{Leave-One-Out Jackknife}
For both the full sample ($N = 190$ countries) and the low-income subsample ($G = 23$ countries), we iteratively excluded each country and re-estimated the primary TWFE specification. The range of resulting GHE coefficients quantifies the influence of any single country on the overall estimate. For the low-income analysis, this is particularly important given the small number of clusters: a single influential country could potentially drive the positive signal.'''
if old3 in c:
    c = c.replace(old3, new3)
    print('F3: LOO expanded')

# Austerity reconciliation
old4 = r'\subsection{Austerity Estimates}\nTwenty-one countries'
new4 = r'''\subsection{Austerity Estimates}
Twenty-one countries experienced GHE austerity ($>$1.5 pp GDP decrease within 3 years). The event study showed no systematic post-austerity HALE decline---all post-austerity coefficients were positive or near zero. A simple pre/post DiD estimator yielded a different result ($\beta = -0.71$, $p = 0.033$). This discrepancy arises because the DiD estimator collapses the full time series into a binary pre/post comparison, which is sensitive to the choice of pre- and post-reform windows and does not account for secular trends as flexibly as the event study specification. We prioritise the event study as the more granular specification but report both estimates transparently.'''
if old4 in c:
    c = c.replace(old4, new4)
    print('F4: Austerity reconciled')

# Missing data
old5 = r'\subsubsection{Missing Data}\nMissingness:'
new5 = r'''\subsubsection{Missing Data}
Missingness: governance 26.3\%, OOP 28.9\%, tax revenue 44.4\%, urbanisation 18.5\%, fertility 17.8\%. Primary TWFE uses listwise deletion ($N = 4{,}304$). IV-2SLS restricted to non-missing tax revenue ($N = 2{,}753$). One pipeline used MICE ($m = 20$, PMM; ref S3) as sensitivity. The pattern of missingness was not completely at random: governance and OOP data were more frequently missing for smaller and lower-income countries, which could introduce selection bias. However, the consistency of results across complete-case and MICE-based analyses suggests that missing-data bias is unlikely to materially affect the conclusions.'''
if old5 in c:
    c = c.replace(old5, new5)
    print('F5: Missing data expanded')

# IV
old6 = r'\subsubsection{IV Diagnostics}\nTax revenue failed'
new6 = r'''\subsubsection{Instrumental Variable Diagnostics}
Tax revenue failed as instrument within-country (first-stage $F < 0.2$ in TWFE). One pipeline's long-difference specification yielded $F = 16.3$ but wide second-stage CIs ($-1.27$ to $+0.61$). The failure of the within-country IV strategy reflects the fact that year-to-year variation in tax revenue is dominated by macroeconomic cycles rather than structural fiscal capacity changes, making it a weak predictor of within-country GHE variation.'''
if old6 in c:
    c = c.replace(old6, new6)
    print('F6: IV expanded')

# Mediation
old7 = r'\subsubsection{Mediation Analysis}\n$\ln'
new7 = r'''\subsubsection{Mediation Analysis}
Product-of-coefficients method under TWFE:
\begin{align}
\ln(\text{OOP}_{it}) &= a \cdot \text{GHE}_{it} + \mathbf{X}_{it}'\boldsymbol{\gamma}_a + \alpha_i + \lambda_t + \varepsilon_{it}^a \\
\text{HALE}_{it} &= b \cdot \ln(\text{OOP}_{it}) + c' \cdot \text{GHE}_{it} + \mathbf{X}_{it}'\boldsymbol{\gamma}_b + \alpha_i + \lambda_t + \varepsilon_{it}^b
\end{align}
Indirect effect (GHE $\rightarrow$ OOP $\rightarrow$ HALE): $a \times b = +0.100$. Direct effect: $c' = -0.222$. Total effect: $c = -0.122$. The positive indirect effect through OOP reduction partially offsets the negative direct effect, consistent with the interpretation that GHE improves financial protection even where it does not measurably improve health outcomes.'''
if old7 in c:
    c = c.replace(old7, new7)
    print('F7: Mediation expanded')

open(path, 'w').write(c)
print('Done')
