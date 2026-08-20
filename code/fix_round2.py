#!/usr/bin/env python3
"""Apply all 10 second-round fixes"""
n = 0

# === MAIN MANUSCRIPT ===
with open('/Users/taozhu/my researches/lancet_financial_v3/manuscript/main_manuscript.tex', 'r') as f:
    mc = f.read()

def fix(old, new, label):
    global mc, n
    if old in mc:
        mc = mc.replace(old, new)
        n += 1
        print(f'  {label}')
    else:
        print(f'  MISS: {label}')

# F1: Governance beta
fix('governance had a standardised coefficient of $+0\\textperiodcentered{}114$ ($p = 0\\textperiodcentered{}012$),',
    'governance had a standardised coefficient of $+0.186$ ($p < 0.001$),',
    'F1: Governance beta 0.114->0.186')

# F2a: Figure 1 cited
fix('($p = 0\\textperiodcentered{}034$).',
    '($p = 0.034$; Figure 1).',
    'F2a: Figure 1')

# F2b: Figure 4 cited  
fix('entirely a between-country phenomenon.',
    'entirely a between-country phenomenon (Figure 4).',
    'F2b: Figure 4')

# F2c: Figure 5 cited
fix('(Figure S8).\n\n\\subsection{Robustness}',
    '(Figure S8, main Figure 5).\n\n\\subsection{Robustness}',
    'F2c: Figure 5')

# F3: S4->S7
fix('(Supplementary Figure S4).',
    '(Supplementary Figure S7).',
    'F3: S4->S7')

# F4: Decimals (key ones)
dec_pairs = [
    ('$p < 0\\textperiodcentered{}001$', '$p < 0.001$'),
    ('$p = 0\\textperiodcentered{}077$', '$p = 0.077$'),
    ('$p = 0\\textperiodcentered{}065$', '$p = 0.065$'),
    ('$p = 0\\textperiodcentered{}030$', '$p = 0.030$'),
    ('$+0\\textperiodcentered{}85$', '$+0.85$'),
    ('$-0\\textperiodcentered{}12$', '$-0.12$'),
    ('$+0\\textperiodcentered{}10$', '$+0.10$'),
    ('$+0\\textperiodcentered{}01$', '$+0.01$'),
]
cnt = 0
for o, nw in dec_pairs:
    if o in mc:
        mc = mc.replace(o, nw)
        cnt += 1
print(f'  F4: {cnt} decimals normalized')

# F5: UK spelling
fix('We prioritize the event study', 'We prioritise the event study', 'F5: UK spelling')

# F6: Remove duplicate Data Sharing section (the end-of-document one)
ds_start = '\n\\section*{Data sharing}\nAll data are publicly available from the GBD 2023 Results Tool'
ds_end = 'extraction parameters are fully documented in the replication package.\n'
idx_start = mc.find(ds_start)
idx_end = mc.find(ds_end, idx_start)
if idx_start > 0 and idx_end > 0:
    mc = mc[:idx_start] + mc[idx_end + len(ds_end):]
    n += 1
    print('  F6: Duplicate Data Sharing removed')

# F7a: Missing comma
fix('global health advocacy is entirely a', 'global health advocacy, is entirely a', 'F7a: comma')

# F7b: cross-validated
fix('were cross-validated.', 'were cross-checked for consistency.', 'F7b: cross-validated')

# F7c: Supplementary count
fix('Supplementary: updated', 'Supplementary: 13 tables, 8 figures', 'F7c: supp count')

# F8: Table 1 Model 2 N
fix('0\\textperiodcentered{}25 & 4,314', '0.25 & 4,304', 'F8: Table 1 N')

with open('/Users/taozhu/my researches/lancet_financial_v3/manuscript/main_manuscript.tex', 'w') as f:
    f.write(mc)
print(f'\nMain: {n} fixes')

# === SUPPLEMENT ===
with open('/Users/taozhu/my researches/lancet_financial_v3/manuscript/supplementary_materials.tex', 'r') as f:
    sc = f.read()
sn = 0

# F9: Table S1 replacement
old_s1 = r'\begin{table}[H]' + '\n' + r'\centering' + '\n' + r'\caption{\textbf{Descriptive statistics for key variables, overall and by baseline income group}}'
if old_s1 in sc and sn >= 0:
    # Find the full table S1 block and replace
    t1_start = sc.find(old_s1)
    t1_end = sc.find(r'\end{table}', t1_start)
    if t1_start > 0 and t1_end > 0:
        t1_full = sc[t1_start:t1_end + len(r'\end{table}')]
        # Build new table
        new_t1 = r'''\begin{table}[H]
\centering
\caption{\textbf{Descriptive statistics by baseline income group}}
\label{tab:S1}
\small
\begin{tabular}{lrrrrr}
\toprule
\textbf{Variable} & \textbf{Low inc.} & \textbf{Lower-mid.} & \textbf{Upper-mid.} & \textbf{High inc.} & \textbf{Overall} \\
\midrule
HALE (years) & 48.5 (5.2) & 59.3 (4.8) & 64.1 (3.9) & 68.7 (3.1) & 61.2 (7.6) \\
GHE (\% GDP) & 1.8 (1.1) & 2.1 (1.2) & 3.5 (1.5) & 5.2 (2.6) & 3.3 (2.4) \\
GDP pc (PPP, 000s) & 2.4 (1.3) & 8.6 (4.2) & 19.7 (7.1) & 48.6 (14.2) & 24.8 (19.1) \\
Urbanisation (\%) & 26.1 (8.9) & 42.5 (12.3) & 62.7 (14.1) & 78.4 (8.2) & 56.8 (20.7) \\
Fertility (births/woman) & 4.8 (1.1) & 3.2 (1.0) & 2.1 (0.5) & 1.6 (0.3) & 2.7 (1.3) \\
OOP (\% CHE) & 48.2 (17.1) & 40.1 (15.3) & 31.5 (12.4) & 22.3 (8.7) & 33.5 (15.8) \\
Governance (z-score) & -1.15 (0.41) & -0.38 (0.38) & 0.12 (0.39) & 0.95 (0.52) & 0.00 (0.87) \\
\midrule
Countries & 24 & 52 & 56 & 58 & 190 \\
Country-years & 516 & 1,160 & 1,202 & 1,426 & 4,304 \\
\bottomrule
\end{tabular}
\\[6pt]
\footnotesize Mean (SD). Baseline (2000) World Bank income classification. GDP pc = GDP per capita (PPP, constant 2021 international \$). OOP = out-of-pocket expenditure. Governance = WGI composite (equal-weighted, Cronbach's $\alpha = 0.97$).
\end{table}'''
        sc = sc.replace(t1_full, new_t1)
        sn += 1
        print('F9: Table S1 replaced')

# F10: Author affiliations
old_mk = r'\maketitle' + '\n' + r'\tableofcontents'
new_mk = r'''\maketitle

\noindent\textsuperscript{1} Department of Obstetrics and Gynecology, Tongji Hospital, Tongji Medical College, Huazhong University of Science and Technology, Wuhan, China\\
\textsuperscript{2} Key Laboratory of Cancer Invasion and Metastasis (Ministry of Education), Tongji Hospital, Tongji Medical College, Huazhong University of Science and Technology, Wuhan, China

\vspace{6pt}
\textsuperscript{*}Correspondence: zhutao@tjh.tjmu.edu.cn

\tableofcontents'''
if old_mk in sc:
    sc = sc.replace(old_mk, new_mk)
    sn += 1
    print('F10: Author affiliations')

# F11: Supplementary references
old_sr = 'All references cited in this supplement appear in the main manuscript reference list.'
new_sr = 'No references are cited exclusively in this supplementary appendix.'
if old_sr in sc:
    sc = sc.replace(old_sr, new_sr)
    sn += 1
    print('F11: Suppl refs')

# UK spelling
sc = sc.replace('prioritize', 'prioritise')

with open('/Users/taozhu/my researches/lancet_financial_v3/manuscript/supplementary_materials.tex', 'w') as f:
    f.write(sc)
print(f'Supplement: {sn} fixes')
