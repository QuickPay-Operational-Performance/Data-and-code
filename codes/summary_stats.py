#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Jun 20 14:35:19 2020

@author: vibhutidhingra
"""
import pandas as pd 
import matplotlib.pyplot as plt

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

non_competitive=sb[(sb.extent_competed_code.isnull())|(sb.extent_competed_code.isin(['G','B','C']))].groupby(['action_date_year_quarter'])['contract_award_unique_key'].nunique().reset_index()
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

pba_lb=lb[lb.performance_based_service_acquisition_code=='Y'].groupby(['action_date_year_quarter'])['contract_award_unique_key'].nunique().reset_index()
pba_lb=pba_lb.rename(columns={'contract_award_unique_key':'Number of performance based contracts'})

fin_lb=lb[lb.contract_financing_code.isin(['C','A','D','E','F'])].groupby(['action_date_year_quarter'])['contract_award_unique_key'].nunique().reset_index()
fin_lb=fin_lb.rename(columns={'contract_award_unique_key':'Number of contracts receiving financing'})

non_competitive_lb=lb[(lb.extent_competed_code.isnull())|(lb.extent_competed_code.isin(['G','B','C']))].groupby(['action_date_year_quarter'])['contract_award_unique_key'].nunique().reset_index()
non_competitive_lb=non_competitive_lb.rename(columns={'contract_award_unique_key':'Number of non-competed contracts'})

dfs = [df.set_index(['action_date_year_quarter']) for df in [lb_summary_1, pba_lb, fin_lb,non_competitive_lb]]
lb_summary=pd.concat(dfs, axis=1).reset_index()

#%% Write to md

# 'wt' -- overwrite existing material, 'a' -- append to existing material                
print(lb_summary.to_markdown(), file=open('/Users/vibhutidhingra/Desktop/lb_summary_stats.md','wt'))  

#%% Plot the total number of firms over time
folder_path='/Users/vibhutidhingra/Desktop/research/Git:Github/qp_data_and_code/img/summary_stats'
fig = plt.figure(figsize=(8, 6))
plt.xticks(rotation=90)
plt.plot(lb_summary.action_date_year_quarter,lb_summary['Number of firms'],\
         label='Large Business')
plt.plot(sb_summary.action_date_year_quarter,sb_summary['Number of firms'],\
         label='Small Business')
fig.suptitle('Number of firms', fontsize=18)
plt.legend(loc="best")
#plt.ylabel('Fraction of contracts', fontsize=18)
plt.xlabel('Year-Quarter', fontsize=16)
plt.savefig(folder_path+'/summary_number_firms.png',bbox_inches='tight')
#%% Plot the total number of contracts over time

fig = plt.figure(figsize=(8, 6))
plt.xticks(rotation=90)
plt.plot(lb_summary.action_date_year_quarter,lb_summary['Number of contracts'],\
         label='Large Business')
plt.plot(sb_summary.action_date_year_quarter,sb_summary['Number of contracts'],\
         label='Small Business')
fig.suptitle('Number of unique active contracts', fontsize=18)
plt.legend(loc="best")
#plt.ylabel('Fraction of contracts', fontsize=18)
plt.xlabel('Year-Quarter', fontsize=16)
plt.savefig(folder_path+'/summary_number_contracts.png',bbox_inches='tight')
#%% Plot the graph - Performance based

fig = plt.figure(figsize=(8, 6))
plt.xticks(rotation=90)
plt.plot(lb_summary.action_date_year_quarter,lb_summary['Number of performance based contracts']/lb_summary['Number of contracts'],\
         label='Large Business')
plt.plot(sb_summary.action_date_year_quarter,sb_summary['Number of performance based contracts']/sb_summary['Number of contracts'],\
         label='Small Business')
fig.suptitle('Performance-based contracts', fontsize=18)
plt.legend(loc="best")
plt.ylabel('Fraction of contracts', fontsize=18)
plt.xlabel('Year-Quarter', fontsize=16)
plt.savefig(folder_path+'/summary_pba.png',bbox_inches='tight')
#%% Plot the graph - Financing

fig = plt.figure(figsize=(8, 6))
plt.xticks(rotation=90)
plt.plot(lb_summary.action_date_year_quarter,lb_summary['Number of contracts receiving financing']/lb_summary['Number of contracts'],\
         label='Large Business')
plt.plot(sb_summary.action_date_year_quarter,sb_summary['Number of contracts receiving financing']/sb_summary['Number of contracts'],\
         label='Small Business')
fig.suptitle('Financed contracts', fontsize=18)
plt.legend(loc="best")
plt.ylabel('Fraction of contracts', fontsize=18)
plt.xlabel('Year-Quarter', fontsize=16)
plt.savefig(folder_path+'/summary_contract_financing.png',bbox_inches='tight')
#%% Plot the graph - Non-competed contracts

fig = plt.figure(figsize=(8, 6))
plt.xticks(rotation=90)
plt.plot(lb_summary.action_date_year_quarter,\
         lb_summary['Number of non-competed contracts']/lb_summary['Number of contracts'],\
         label='Large Business')
plt.plot(sb_summary.action_date_year_quarter,\
         sb_summary['Number of non-competed contracts']/sb_summary['Number of contracts'],\
         label='Small Business')
fig.suptitle('Non-competitive contracts', fontsize=18)
plt.legend(loc="best")
plt.ylabel('Fraction of contracts', fontsize=18)
plt.xlabel('Year-Quarter', fontsize=16)
plt.savefig(folder_path+'/summary_non_compete.png',bbox_inches='tight')

#%% Number of null values (convert to string to show in groupby)

cols=['performance_based_service_acquisition','performance_based_service_acquisition_code',\
      'extent_competed','extent_competed_code',\
      'contract_financing','contract_financing_code']
df[cols]=df[cols].astype(str)

## pba
pba_notnull=df.groupby(['performance_based_service_acquisition',\
                        'performance_based_service_acquisition_code'])['contract_award_unique_key'].nunique().reset_index()
pba_notnull=pba_notnull.rename(columns={'contract_award_unique_key':'Number of contracts'})

## extent competed
noncompete_notnull=df.groupby(['extent_competed','extent_competed_code'])['contract_award_unique_key'].nunique().reset_index()
noncompete_notnull=noncompete_notnull.rename(columns={'contract_award_unique_key':'Number of contracts'})

## contract financing
fin_notnull=df.groupby(['contract_financing','contract_financing_code'])['contract_award_unique_key'].nunique().reset_index()
fin_notnull=fin_notnull.rename(columns={'contract_award_unique_key':'Number of contracts'})

## to markdown

print(pba_notnull.to_markdown(), file=open('/Users/vibhutidhingra/Desktop/pba_notnull.md','wt'))  
print(noncompete_notnull.to_markdown(), file=open('/Users/vibhutidhingra/Desktop/noncompete_notnull.md','wt'))  
print(fin_notnull.to_markdown(), file=open('/Users/vibhutidhingra/Desktop/fin_notnull.md','wt'))  

#%% Value and length of contracts 
from scipy.stats import mstats
folder_path='/Users/vibhutidhingra/Desktop/research/Git:Github/qp_data_and_code/img/summary_stats'

dfv=df.sort_values(by='action_date').drop_duplicates(subset='contract_award_unique_key').reset_index(drop=True)
# get entry when a contract first appeared in the sample

dfv['period_of_performance_current_end_date']=pd.to_datetime(dfv.period_of_performance_current_end_date)
dfv['period_of_performance_start_date']=pd.to_datetime(dfv.period_of_performance_start_date)

dfv["initial_duration"]=(dfv.period_of_performance_current_end_date-dfv.period_of_performance_start_date).dt.days
dfv["winsorized_contract_value"]=mstats.winsorize(dfv.base_and_all_options_value, limits=[0.05, 0.05])
dfv["winsorized_initial_duration"]=mstats.winsorize(dfv.initial_duration, limits=[0.05, 0.05])

sb_contracts=dfv[dfv.contracting_officers_determination_of_business_size_code=='S'].reset_index()
lb_contracts=dfv[dfv.contracting_officers_determination_of_business_size_code=='O'].reset_index()

plot_sb=sb_contracts.groupby('action_date_year_quarter')[['base_and_all_options_value',\
                            'winsorized_contract_value','initial_duration','winsorized_initial_duration']].mean().reset_index()
plot_lb=lb_contracts.groupby('action_date_year_quarter')[['base_and_all_options_value',\
                            'winsorized_contract_value','initial_duration','winsorized_initial_duration']].mean().reset_index()

fig = plt.figure(figsize=(8, 6))
plt.xticks(rotation=90)
plt.plot(plot_sb.action_date_year_quarter.astype(str),\
         plot_sb.winsorized_contract_value,label="Small Business")
plt.plot(plot_lb.action_date_year_quarter.astype(str),\
         plot_lb.winsorized_contract_value,label="Large Business")
plt.legend(loc="best")
plt.ylabel('Initial contract value \n (5% winsorized average)', fontsize=18)
plt.xlabel('Year-Quarter', fontsize=16)
plt.savefig(folder_path+'/summary_initial_value.png',bbox_inches='tight')

fig = plt.figure(figsize=(8, 6))
plt.xticks(rotation=90)
plt.plot(plot_sb.action_date_year_quarter.astype(str),\
         plot_sb.winsorized_initial_duration,label="Small Business")
plt.plot(plot_lb.action_date_year_quarter.astype(str),\
         plot_lb.winsorized_initial_duration,label="Large Business")
plt.legend(loc="best")
plt.ylabel('Initial project duration \n (5% winsorized average)', fontsize=18)
plt.xlabel('Year-Quarter', fontsize=16)
plt.savefig(folder_path+'/summary_initial_duration.png',bbox_inches='tight')

#%% Default rates for large and small businesses

# to markdown
df[['action_type_code','action_type']]=df[['action_type_code','action_type']].astype(str)
contracts_per_action_type=df.groupby(['action_type_code','action_type'])['contract_award_unique_key'].nunique().reset_index()
contracts_per_action_type.rename(columns={'contract_award_unique_key':'Number of contracts'}, inplace=True)
print(contracts_per_action_type.to_markdown(), file=open('/Users/vibhutidhingra/Desktop/contracts_per_action_type.md','wt'))  




