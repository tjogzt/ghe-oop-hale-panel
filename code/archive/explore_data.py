#!/usr/bin/env python3
import pandas as pd
import numpy as np

df = pd.read_csv('/Volumes/tjogzt4T/lancet_financial_v2/data/processed/integrated_panel_final.csv')

print("=== Dimensions ===")
print(f"Rows: {df.shape[0]}, Cols: {df.shape[1]}")
print(f"Years: {df['year'].min()}-{df['year'].max()}, Countries: {df['iso3c'].nunique()}")

print("\n=== Key Variables Missing ===")
for v in ['hale','ghe_share_gdp','gdp_per_capita_ppp','governance_composite','urbanization','fertility_rate','tax_revenue_gdp','oop_expenditure']:
    if v in df.columns:
        print(f"  {v:30s}: {df[v].isna().sum():5d} ({100*df[v].isna().sum()/len(df):.1f}%)")

print("\n=== HALE ===")
print(df['hale'].describe())
print("\n=== GHE %GDP ===")
print(df['ghe_share_gdp'].describe())

print("\n=== Income Distribution ===")
print(df['income'].value_counts(dropna=False))

print("\n=== Region ===")
print(df['region'].value_counts().head(10))

# Check: how many countries have data for both 2000 AND latest year?
yr_range = df.groupby('iso3c')['year'].agg(['min','max'])
yr_range['span'] = yr_range['max'] - yr_range['min']
print(f"\nCountries with span >= 20 years: {(yr_range['span'] >= 20).sum()}")
print(f"Countries with span >= 15 years: {(yr_range['span'] >= 15).sum()}")

# Long difference: change in HALE vs change in GHE
df_sorted = df.sort_values(['iso3c','year'])
first = df_sorted.groupby('iso3c').first().reset_index()
last = df_sorted.groupby('iso3c').last().reset_index()
ld = pd.merge(first[['iso3c','hale','ghe_share_gdp','gdp_per_capita_ppp']], 
              last[['iso3c','hale','ghe_share_gdp','gdp_per_capita_ppp']], 
              on='iso3c', suffixes=('_0','_T'))
ld['d_hale'] = ld['hale_T'] - ld['hale_0']
ld['d_ghe'] = ld['ghe_share_gdp_T'] - ld['ghe_share_gdp_0']
ld['d_gdppc'] = np.log(ld['gdp_per_capita_ppp_T']) - np.log(ld['gdp_per_capita_ppp_0'])
ld = ld.dropna(subset=['d_hale','d_ghe'])
print(f"\n=== Long Difference (2000→latest) ===")
print(f"N countries: {len(ld)}")
print(f"d_HALE: mean={ld['d_hale'].mean():.1f}, SD={ld['d_hale'].std():.1f}")
print(f"d_GHE: mean={ld['d_ghe'].mean():.1f}, SD={ld['d_ghe'].std():.1f}")
print(f"Corr(d_GHE, d_HALE): {ld['d_ghe'].corr(ld['d_hale']):.3f}")

# Count: how many countries increased GHE AND increased HALE?
ld['ghe_up'] = ld['d_ghe'] > 0
ld['hale_up'] = ld['d_hale'] > 0
print(f"\nGHE up + HALE up: {(ld['ghe_up'] & ld['hale_up']).sum()}")
print(f"GHE up + HALE down: {(ld['ghe_up'] & ~ld['hale_up']).sum()}")
print(f"GHE down + HALE up: {(~ld['ghe_up'] & ld['hale_up']).sum()}")
print(f"GHE down + HALE down: {(~ld['ghe_up'] & ~ld['hale_up']).sum()}")
