#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Oct  6 17:07:09 2020

@author: vibhutidhingra
"""

import pandas as pd 
pd.set_option('expand_frame_repr', True)

# %% Read the raw data + assign quarter years to date

df=pd.read_csv('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_fy10_to_fy18.csv')
df.recipient_duns=df.recipient_duns.astype('Int64')
df['action_date']=pd.to_datetime(df['action_date'])
df["action_date_year_quarter"]=df.action_date.dt.year.astype(str)+'-Q'+df.action_date.dt.quarter.astype(str)

#%%
df1=df[df.action_date<=pd.to_datetime('2012-06-30')]

df1.loc[df1.action_date <=pd.to_datetime('2011-03-31'), "relative_period"] ="before_qp" 

df1.loc[df1.action_date >pd.to_datetime('2011-03-31'), "relative_period"] ="after_qp" 
#%%
num_contracts=df1.groupby(['contracting_officers_determination_of_business_size_code'])['contract_award_unique_key','naics_code','product_or_service_code'].nunique().reset_index()
num_contracts.rename(columns={'contract_award_unique_key':'number_of_projects','naics_code':'number_of_naics_code','product_or_service_code':'number_of_psc'},inplace=True)

#%%
dfv=df1.sort_values(by='action_date').drop_duplicates(subset='contract_award_unique_key').reset_index(drop=True)
# get entry when a contract first appeared in the sample
from scipy.stats import mstats

dfv['period_of_performance_current_end_date']=pd.to_datetime(dfv.period_of_performance_current_end_date)
dfv['period_of_performance_start_date']=pd.to_datetime(dfv.period_of_performance_start_date)

dfv["initial_duration"]=(dfv.period_of_performance_current_end_date-dfv.period_of_performance_start_date).dt.days
dfv["winsorized_contract_value"]=mstats.winsorize(dfv.base_and_all_options_value, limits=[0.05, 0.05])
dfv["winsorized_initial_duration"]=mstats.winsorize(dfv.initial_duration, limits=[0.05, 0.05])

#%%
initial_duration=dfv.groupby(['contracting_officers_determination_of_business_size_code'])['winsorized_initial_duration'].mean().reset_index()

initial_value=dfv.groupby(['contracting_officers_determination_of_business_size_code'])['winsorized_contract_value'].mean().reset_index()

#%%
from functools import reduce
dfs = [initial_duration, initial_value, num_contracts]


df_final = reduce(lambda left,right:\
                  pd.merge(left,right,on=['contracting_officers_determination_of_business_size_code']), dfs)

#%% Write to md

# 'wt' -- overwrite existing material, 'a' -- append to existing material                
print(df_final.to_markdown(), file=open('/Users/vibhutidhingra/Desktop/df_final.md','wt'))                     

#%%
print(df1[['product_or_service_code',\
           'product_or_service_code_description']].drop_duplicates(subset='product_or_service_code',ignore_index=True).\
to_markdown(), file=open('/Users/vibhutidhingra/Desktop/df_psc.md','wt'))