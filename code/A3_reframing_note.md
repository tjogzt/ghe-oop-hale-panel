# A3 — Analytical Note: Reframing the Paper Around Three Pillars

**Purpose.** This note defines the revised narrative structure for the
manuscript following peer review. The original framing led with the null
within-country finding; the revision repositions three results as the
analytical pillars, in order of evidential strength and policy relevance.

---

## Pillar 1 — The low-income positive signal (now the CENTRAL finding)

**Evidence.**
- TWFE within low-income countries: GHE coefficient **+0.85 years of HALE per
  percentage point of GDP** (p = 0.030), the only income group with a positive,
  statistically detectable within-country association.
- Directionally replicated with log GHE per capita (PPP): +0.33 (p = 0.045).
- Consistent with the regional result for Sub-Saharan Africa (+0.21, p = 0.411;
  Middle East & North Africa +0.24, p = 0.089) — positive point estimates
  concentrated where baseline health systems are weakest.
- Synthetic-control case evidence is coherent with this gradient: the two
  reforms in the lowest-income settings (Rwanda CBHI 2005, China 2009) show the
  largest post-reform HALE gains relative to synthetic counterfactuals
  (+2.1 and +2.9 years), although placebo-based inference is inconclusive
  (rank p = 0.76 and 0.15 respectively).

**Interpretive stance.** This is a *suggestive*, not definitive, signal: it
rests on subgroup TWFE and case-study evidence, and low-income countries are
precisely those with the least fiscal space to act on it. The revised
manuscript presents it as the central substantive finding because it is the
only result with a positive sign that survives multiple specifications, and
because it aligns with the theory of diminishing marginal returns to health
spending.

## Pillar 2 — OOP mediation: GHE buys financial protection (a benefit in itself)

**Evidence.**
- Path A (GHE → log-OOP): **−0.120** (p < 0.001), consistent across ALL income
  groups (low −0.153; lower-middle −0.157; upper-middle −0.155; high −0.059).
- Path B (log-OOP → HALE | GHE): −0.835 (p = 0.022).
- The beneficial indirect path through OOP (+0.100) is offset by a negative
  residual channel (direct effect −0.222, p = 0.013).

**Interpretive stance.** Even where HALE does not measurably improve, GHE
reliably reduces out-of-pocket financial hardship. Reducing catastrophic
health expenditure is an explicit SDG target (3.8.2) and a first-order policy
good independent of mortality effects. The revised manuscript treats this as a
*positive policy finding*, not a consolation result: GHE "works" along the
financial-protection margin even when the health-outcome margin is silent
within 2 decades of observation.

## Pillar 3 — The null within-country effect for middle/high-income (tempered)

**Evidence.**
- Primary TWFE (no governance controls): β = −0.12 (p = 0.077) — does **not**
  reach conventional significance.
- With governance controls (now sensitivity only): β = −0.16 (p = 0.016).
- Long difference: β = −0.33 (p = 0.034); 5-yr TWFE −0.20 (p = 0.034);
  10-yr TWFE −0.27 (p = 0.027).
- Event study excluding COVID-era spikes: post-spike HALE trajectory remains
  negative (−0.71 at t+5) but loses significance (p = 0.090), and placebo
  event studies show comparable "declines" arise by chance in a substantial
  minority of random draws.

**Interpretive stance.** The claim is downgraded from "GHE is associated with
HALE declines" to "**no evidence of a positive within-country effect** in
middle- and high-income settings". We explicitly distinguish *absence of
evidence* from *evidence of absence*: the negative point estimates are
consistent with reverse causality (crisis-driven spending) but the data cannot
reject a small positive effect either. Governance-conditioned estimates are
reported only as sensitivity because WGI perception indices may themselves
respond to health-system performance (joint endogeneity / over-control).

---

## Consequences for manuscript structure

1. **Summary/Findings**: lead with the income gradient (positive only in
   low-income), then OOP mediation as a positive finding, then the tempered
   null. Remove any phrasing implying a demonstrated *negative* causal effect.
2. **Methods**: add synthetic control; move governance to sensitivity;
   document COVID-exclusion and placebo procedures for the event study.
3. **Results order**: (i) descriptive gradient → (ii) primary TWFE without
   governance → (iii) income heterogeneity (low-income positive) →
   (iv) mediation → (v) quasi-experimental (event study excl. COVID, SCM
   reforms, austerity mirror, placebos) → (vi) robustness (pre-COVID,
   temporal heterogeneity, horse race).
4. **Discussion**: foreground the IV failure (first-stage F < 1) as a
   limitation of the identification portfolio; discuss reform heterogeneity
   (Rwanda/China vs Ghana/Mexico) as evidence that *how* money is spent
   dominates *how much*; state plainly that aggregate GHE/GDP ratios are
   insufficient as a stand-alone policy lever.
