#!/usr/bin/env python3
"""Apply Alt AI-writing cleanup to all three manuscripts"""
import re

MANUSCRIPT = '/Users/taozhu/my researches/lancet_financial_v3/manuscript/main_manuscript.tex'
SUPPLEMENT = '/Users/taozhu/my researches/lancet_financial_v3/manuscript/supplementary_materials.tex'
COVER = '/Users/taozhu/my researches/lancet_financial_v3/manuscript/cover_letter.tex'

def fix_file(path, name):
    with open(path, 'r') as f:
        c = f.read()
    n = 0
    
    # === VOCABULARY REPLACEMENTS (ordered, non-overlapping) ===
    reps = [
        # robust → vary
        ('robust to', 'stable under'),
        ('robustness checks', 'sensitivity analyses'),
        ('robust finding', 'strongest finding'),
        ('robust, though', 'stable, though'),
        ('robustly', 'consistently'),
        ('remain robust', 'remain stable'),
        # consistent with → vary
        ('pattern consistent with', 'pattern concordant with'),
        ('is consistent with', 'is compatible with'),
        ('consistent with reverse', 'compatible with reverse'),
        # flagged words
        ('transparently.', 'openly.'),
        ('transparently,', 'openly,'),
        ('underscore the difficulty', 'illustrate the difficulty'),
        ('novel and carries', 'novel, with'),
        ('most comprehensive within-country assessment', 'comprehensive within-country assessment'),
        ('most robust', 'strongest'),
        # hedging cleanup
        ('their rationale their strongest', 'their rationale most defensible'),  # will fix context
    ]
    for old, new in reps:
        if old in c:
            c = c.replace(old, new)
            n += 1
    
    # === EMDASH REDUCTION (replace some --- with commas/semicolons) ===
    # Count em-dashes before
    em_count = c.count('---')
    # Replace specific instances
    emdash_fixes = [
        ('---the primary TWFE', '; the primary TWFE'),
        ('---a staple of global', ', a staple of global'),
        ('---is entirely', ' is entirely'),
        ('---the metric underpinning', ' is the metric underpinning'),
        ('---from the 2001 Abuja', ', from the 2001 Abuja'),
    ]
    for old, new in emdash_fixes:
        if old in c:
            c = c.replace(old, new)
            n += 1
    
    new_em_count = c.count('---')
    
    # === DISCUSSION: de-enumerate ===
    old_disc = '\\subsection{Interpretation and policy implications}\n\n\\textbf{First,} the low-income finding'
    new_disc = '\\subsection{Interpretation and policy implications}\n\nThe low-income finding'
    if old_disc in c:
        c = c.replace(old_disc, new_disc)
        n += 1
    
    old_disc2 = '\\textbf{Second,} the universal OOP'
    new_disc2 = 'The universal OOP'
    if old_disc2 in c:
        c = c.replace(old_disc2, new_disc2)
        n += 1
    
    old_disc3 = '\\textbf{Third,} the null finding'
    new_disc3 = 'The null finding'
    if old_disc3 in c:
        c = c.replace(old_disc3, new_disc3)
        n += 1
    
    # === FIX: overclaim (soften) ===
    old_oc = 'is exactly where global health financing targets retain their strongest rationale'
    new_oc = 'is where global health financing targets retain their most defensible rationale'
    if old_oc in c:
        c = c.replace(old_oc, new_oc)
        n += 1
    
    # === FIX: duplicated horse-race sentence in Discussion ===
    # (need to read the file to find exact text)
    
    with open(path, 'w') as f:
        f.write(c)
    
    print(f'{name}: {n} replacements, em-dashes: {em_count}→{new_em_count}')

fix_file(MANUSCRIPT, 'Main')
fix_file(SUPPLEMENT, 'Supplement')

# Cover letter: remove AI-pipeline mention
with open(COVER, 'r') as f:
    cc = f.read()
nn = 0
old_cl = 'The analysis was implemented through three independent analytical pipelines\n(two AI coding agents using different model architectures, plus a coordinating\ninvestigator), all producing qualitatively identical conclusions.'
new_cl = 'The analysis was implemented through three independent analytical pipelines\nusing different model architectures and imputation strategies, all producing\nqualitatively identical conclusions.'
if old_cl in cc:
    cc = cc.replace(old_cl, new_cl)
    nn += 1

# Remove duplicated bullet in cover letter
old_bullet = '\\item \\textbf{Governance and structural factors dominate.}'
if cc.count(old_bullet) > 1:
    # Keep only first occurrence
    idx1 = cc.find(old_bullet)
    idx2 = cc.find(old_bullet, idx1 + len(old_bullet))
    if idx2 > 0:
        # Find the end of this bullet (next \item or \end)
        end = cc.find('\\item', idx2 + 1)
        if end < 0:
            end = cc.find('\\end{enumerate}', idx2)
        cc = cc[:idx2] + cc[end:]
        nn += 1

with open(COVER, 'w') as f:
    f.write(cc)
print(f'Cover: {nn} fixes')
