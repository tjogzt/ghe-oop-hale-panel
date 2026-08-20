import sys
with open('/Users/taozhu/my researches/lancet_financial_v3/manuscript/main_manuscript.tex','r') as f:
    c = f.read()

old = ('The GHE-to-GDP ratio is a crude exposure measure that conflates\n'
       'changes in the numerator with changes in the denominator.')

new = ('The GHE-to-GDP ratio conflates health spending changes (numerator) with GDP\n'
       'fluctuations (denominator). We addressed this by entering log GHE per capita\n'
       r'and log GDP as separate covariates: the GHE per capita coefficient was' + '\n'
       r'$\beta = -0{\cdot}15$ ($p = 0{\cdot}51$) while log GDP remained' + '\n'
       r'strongly positive ($\beta = +0{\cdot}85$, $p < 0{\cdot}001$),' + '\n'
       "confirming that the null finding is not driven by the ratio's denominator.")

if old in c:
    c = c.replace(old, new)
    with open('/Users/taozhu/my researches/lancet_financial_v3/manuscript/main_manuscript.tex','w') as f:
        f.write(c)
    print('Fix 4 applied')
else:
    print('Text not found')
    print(repr(old[:80]))
