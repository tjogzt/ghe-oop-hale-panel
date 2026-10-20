with open('/Users/taozhu/my researches/lancet_financial_v3/manuscript/main_manuscript.tex','r') as f: c=f.read()
n=0

# Replace Ref 20
old = r'\bibitem{20} Baldacci E, Clements B, Gupta S, Cui Q. Social spending, human'
if old in c:
    idx = c.find(old)
    end = c.find('\n\n', idx) + 2
    if end < idx: end = idx + 200
    new = r'\bibitem{20} Moreno-Serra R, Smith PC. Does progress towards universal health coverage improve population health? \textit{Lancet} 2012; \textbf{380}: 917--23.'
    c = c[:idx] + new + c[end:]
    n += 1
    print('Ref 20 replaced')

open('/Users/taozhu/my researches/lancet_financial_v3/manuscript/main_manuscript.tex','w').write(c)

# Supplement: add method refs
with open('/Users/taozhu/my researches/lancet_financial_v3/manuscript/supplementary_materials.tex','r') as sf:
    sc = sf.read()

old_sm = r'\subsection{Synthetic Control Method}'
new_sm = r'''\subsection{Methodological References}
Key references: wild cluster bootstrap (Cameron AC, Gelbach JB, Miller DL. 
Bootstrap-based improvements for inference with clustered errors. 
\textit{Rev Econ Stat} 2008; \textbf{90}: 414--27); equivalence testing 
(Lakens D. \textit{Soc Psychol Personal Sci} 2017; \textbf{8}: 355--62); 
multiple imputation (van Buuren S, Groothuis-Oudshoorn K. \textit{J Stat Softw} 
2011; \textbf{45}: 1--67); synthetic control (Abadie A, Diamond A, Hainmueller J. 
\textit{J Am Stat Assoc} 2010; \textbf{105}: 493--505).

\subsection{Synthetic Control Method}'''
if old_sm in sc:
    sc = sc.replace(old_sm, new_sm)
    n += 1
    print('Method refs added')

open('/Users/taozhu/my recherches/lancet_financial_v3/manuscript/supplementary_materials.tex','w').write(sc)
print(f'Total: {n}')
