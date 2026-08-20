with open('/Users/taozhu/my researches/lancet_financial_v3/manuscript/supplementary_materials.tex','r') as f:
    sc = f.read()
n = 0

# 1. Literature search → prose
old1 = r'''\begin{itemize}
\item \textbf{PubMed:}'''
idx = sc.find(old1)
if idx > 0:
    end = sc.find(r'\end{itemize}', idx) + len(r'\end{itemize}')
    old_block = sc[idx:end]
    new_block = r'''PubMed: (``government health expenditure'' OR ``public health spending'' OR ``health financing'') AND (``life expectancy'' OR ``health-adjusted life expectancy'' OR ``mortality'' OR ``population health'') AND (``governance'' OR ``institutional quality'' OR ``causal identification'' OR ``fixed effects'' OR ``panel''), 2000--2026. Web of Science: TS=(``government health expenditure'' OR ``public health spending'') AND TS=(``life expectancy'' OR ``mortality'' OR ``population health'') AND TS=(``governance'' OR ``fixed effects'' OR ``panel'' OR ``instrumental variable''), 2000--2026. EconLit: (``health expenditure'' OR ``health spending'') AND (``life expectancy'' OR ``mortality'' OR ``health outcome*'') AND (``governance'' OR ``institution*'' OR ``fixed effects'' OR ``causal''). Google Scholar: ``government health expenditure'' ``life expectancy'' panel data (first 200 results screened).'''
    sc = sc.replace(old_block, new_block)
    n += 1
    print('F1: Literature → prose')

# 2. Data sources → prose
old2 = r'\begin{itemize}[leftmargin=*]'
idx2 = sc.find(old2)
if idx2 > 0:
    end2 = sc.find(r'\end{itemize}', idx2) + len(r'\end{itemize}')
    old_block2 = sc[idx2:end2]
    new_block2 = r'''HALE at birth was extracted from the GBD 2023 Results Tool (\texttt{https://vizhub.healthdata.org/gbd-results/}, accessed July 19, 2026). Government health expenditure (SH.XPD.GHED.GD.ZS) and external health aid (SH.XPD.EHEX.CH.ZS, downloaded August 10, 2026) were obtained from the World Bank WDI API. Additional WDI variables: infant mortality (SP.DYN.IMRT.IN), GDP per capita PPP (NY.GDP.PCAP.PP.KD), urban population (SP.URB.TOTL.IN.ZS), fertility rate (SP.DYN.TFRT.IN), and out-of-pocket expenditure (SH.XPD.OOPC.CH.ZS). Tax revenue (GC.TAX.TOTL.GD.ZS) was obtained from the IMF GFS and WDI. The governance composite is the equal-weighted mean of six WGI 2025 dimensions (Cronbach's $\alpha = 0.97$; \texttt{https://www.govindicators.org}). Baseline (2000) World Bank income classification was applied as a time-invariant attribute.'''
    sc = sc.replace(old_block2, new_block2)
    n += 1
    print('F2: Data sources → prose')

# 3. Pipelines → prose
old3 = r'\begin{enumerate}'
idx3 = sc.find(old3)
if idx3 > 0:
    end3 = sc.find(r'\end{enumerate}', idx3) + len(r'\end{enumerate}')
    old_block3 = sc[idx3:end3]
    new_block3 = r'''Pipeline A (Claude, DeepSeek V4 Pro) used MICE multiple imputation ($m = 20$) with 20 sensitivity analyses. Pipeline B (Alt, Kimi K3 via OpenRouter) used complete-case analysis with 10 sensitivity analyses. Pipeline C (Coordinator) implemented event studies, synthetic control, mediation, temporal aggregation, and the horse-race model on the primary analytical sample. All pipelines were implemented in R.'''
    sc = sc.replace(old_block3, new_block3)
    n += 1
    print('F3: Pipelines → prose')

open('/Users/taozhu/my recherches/lancet_financial_v3/manuscript/supplementary_materials.tex','w').write(sc)
print(f'Total: {n}')
