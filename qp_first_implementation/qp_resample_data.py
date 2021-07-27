#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jul 27 06:19:55 2021

@author: vibhutidhingra
"""

# Code to obtain quarterly resampled data for QuickPay

#%% Load packages

import pandas as pd

#%% Output path

directory='/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/'

#%% Read data

cols_to_read=['contract_award_unique_key',\
              'action_date',\
              'period_of_performance_start_date',\
              'period_of_performance_current_end_date',\
              'base_and_all_options_value',\
              'contracting_officers_determination_of_business_size_code']

df=pd.read_csv(directory+'qp_data_fy10_to_fy18.csv',
               usecols=cols_to_read)

# this is faster than using function
df['action_date']=pd.to_datetime(df['action_date'],errors='coerce')
df=df[df.action_date<=pd.to_datetime('2017-12-31')]

df['period_of_performance_start_date']=\
    pd.to_datetime(df['period_of_performance_start_date'],errors='coerce')
df['period_of_performance_current_end_date']=\
pd.to_datetime(df['period_of_performance_current_end_date'],errors='coerce')

df.sort_values(by=['contract_award_unique_key','action_date'],inplace=True)

#%% Dictionary for business type

# Remove projects that have more than one category
multiple_values=df.groupby('contract_award_unique_key')\
['contracting_officers_determination_of_business_size_code'].nunique().reset_index()

multiple_values=set(multiple_values[multiple_values.contracting_officers_determination_of_business_size_code>1].\
                    contract_award_unique_key)

df=df[~df.contract_award_unique_key.isin(multiple_values)]

business_type=df.set_index('contract_award_unique_key')\
['contracting_officers_determination_of_business_size_code'].to_dict()

#%% Resampling

select_variables=['contract_award_unique_key',
                    'period_of_performance_start_date',
                    'period_of_performance_current_end_date',
                    'base_and_all_options_value']

df_start_end = df.melt(id_vars=select_variables, \
                           value_vars='action_date',\
                           value_name='action_date_year_quarter')

import time
start=time.time()
df_sorted = df_start_end.groupby(['contract_award_unique_key']).apply\
            (lambda x: x.drop_duplicates('action_date_year_quarter').set_index\
             ('action_date_year_quarter').resample('Q').last()).drop\
             (columns=['contract_award_unique_key','variable']).reset_index().ffill()
end=time.time()
print(end-start)
            
df_sorted.rename(columns=\
                 {'period_of_performance_start_date':'last_reported_start_date',\
                  'period_of_performance_current_end_date':'last_reported_end_date',\
                  'base_and_all_options_value':'last_reported_budget'},\
                  inplace=True)

#%% Get business type

df_sorted["business_type"]=\
df_sorted.contract_award_unique_key.map(business_type.get)

#%% Save to CSV

df_sorted.to_csv(directory+
                'qp_resampled_data_fy10_to_fy18.csv',index=False)
