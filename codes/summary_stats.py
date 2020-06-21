#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Jun 20 14:35:19 2020

@author: vibhutidhingra
"""
import pandas as pd 

pd.set_option('expand_frame_repr', True)

# %% Read the raw data + assign quarter years to date

df=pd.read_csv('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_fy10_to_fy18.csv')
df.recipient_duns=df.recipient_duns.astype('Int64')
df['action_date']=pd.to_datetime(df['action_date'])
df["action_date_year_quarter"]=df.action_date.dt.year.astype(str)+'-Q'+df.action_date.dt.quarter.astype(str)

#%% Summary for Small Business Contracts

sb=df[df.contracting_officers_determination_of_business_size_code=='S']

sb_summary_1=sb.groupby(['action_date_year_quarter'])['recipient_duns','contract_award_unique_key'].nunique().reset_index()
sb_summary_1.rename(columns={'recipient_duns':'Number of firms','contract_award_unique_key':'Number of contracts'},inplace=True)

pba=sb[sb.performance_based_service_acquisition_code=='Y'].groupby(['action_date_year_quarter'])['contract_award_unique_key'].nunique().reset_index()
pba=pba.rename(columns={'contract_award_unique_key':'Number of performance based contracts'})

fin=sb[sb.contract_financing_code.isin(['C','A','D','E','F'])].groupby(['action_date_year_quarter'])['contract_award_unique_key'].nunique().reset_index()
fin=fin.rename(columns={'contract_award_unique_key':'Number of contracts receiving financing'})

non_competitive=sb[sb.extent_competed_code.isin(['G','B','C'])].groupby(['action_date_year_quarter'])['contract_award_unique_key'].nunique().reset_index()
non_competitive=non_competitive.rename(columns={'contract_award_unique_key':'Number of non-competed contracts'})

dfs = [df.set_index(['action_date_year_quarter']) for df in [sb_summary_1, pba, fin,non_competitive]]
sb_summary=pd.concat(dfs, axis=1).reset_index()

#%% Write to md

# 'wt' -- overwrite existing material, 'a' -- append to existing material                
print(sb_summary.to_markdown(), file=open('/Users/vibhutidhingra/Desktop/sb_summary_stats.md','wt'))                     

#%% Summary for Large Business Contracts

lb=df[df.contracting_officers_determination_of_business_size_code=='O']

lb_summary_1=lb.groupby(['action_date_year_quarter'])['recipient_duns','contract_award_unique_key'].nunique().reset_index()
lb_summary_1.rename(columns={'recipient_duns':'Number of firms','contract_award_unique_key':'Number of contracts'},inplace=True)

pba=lb[lb.performance_based_service_acquisition_code=='Y'].groupby(['action_date_year_quarter'])['contract_award_unique_key'].nunique().reset_index()
pba=pba.rename(columns={'contract_award_unique_key':'Number of performance based contracts'})

fin=lb[lb.contract_financing_code.isin(['C','A','D','E','F'])].groupby(['action_date_year_quarter'])['contract_award_unique_key'].nunique().reset_index()
fin=fin.rename(columns={'contract_award_unique_key':'Number of contracts receiving financing'})

non_competitive=lb[lb.extent_competed_code.isin(['G','B','C'])].groupby(['action_date_year_quarter'])['contract_award_unique_key'].nunique().reset_index()
non_competitive=non_competitive.rename(columns={'contract_award_unique_key':'Number of non-competed contracts'})

dfs = [df.set_index(['action_date_year_quarter']) for df in [lb_summary_1, pba, fin,non_competitive]]
lb_summary=pd.concat(dfs, axis=1).reset_index()

#%% Write to md

# 'wt' -- overwrite existing material, 'a' -- append to existing material                
print(lb_summary.to_markdown(), file=open('~/Desktop/lb_summary_stats.md','wt'))  
