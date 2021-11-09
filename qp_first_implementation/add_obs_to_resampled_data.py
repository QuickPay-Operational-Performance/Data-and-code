#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Nov  9 12:43:07 2021

@author: vibhutidhingra
"""

#%% Load packages

import pandas as pd
import quickpay_datacleaning as qpc

#%% Output path

output_folder='/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/'

df=pd.read_csv(output_folder+'resampled_qp_data/qp_resampled_data_fy10_to_fy12.csv')

#%% Get last action date for each project

df['action_date_year_quarter']=pd.to_datetime(df.action_date_year_quarter)
df_end=df.groupby('contract_award_unique_key')['action_date_year_quarter'].max().reset_index()
df_end.rename(columns={'action_date_year_quarter':'max_action_date_year_quarter'},inplace=True)

#%% API data

api_folder='/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/api_csv_initial'
df_api=qpc.read_multiple_csvs(api_folder)

df_api=df_api[['generated_unique_award_id','period_of_performance_end_date']]
df_api=df_api.rename(columns={'period_of_performance_end_date':'eventual_end_date'})

#horizon_end=pd.to_datetime('2012-06-30')
# use Sep 30 for now, as the UB before

df_end=df_end.merge(df_api,
            left_on='contract_award_unique_key',
            right_on='generated_unique_award_id')

df_end["eventual_end_date"]=pd.to_datetime(df_end.eventual_end_date,errors='coerce')    

ub=df.action_date_year_quarter.max()
df_end["date_in_horizon"]=df_end.eventual_end_date.apply(lambda x: min(x,ub))
df_end.drop(columns={'generated_unique_award_id','eventual_end_date'},inplace=True)

#%% Filter projects whose end dates are greater than action date

new_df=df_end[df_end.max_action_date_year_quarter<df_end.date_in_horizon]

new_df["missing_quarters"]=new_df.apply(lambda x:
    (pd.date_range(x.max_action_date_year_quarter,
                   x.date_in_horizon + pd.offsets.QuarterBegin(1), freq='Q')
     .to_period("Q")
     .end_time.date
     .tolist()[1:]),axis=1)


new_df1=new_df.explode('missing_quarters').dropna().reset_index(drop=True)
    
new_df1.drop(columns={'max_action_date_year_quarter','date_in_horizon'},inplace=True)
new_df1.rename(columns={'missing_quarters':'action_date_year_quarter'},inplace=True)

#%% Add to existing data

df1=pd.concat([df,new_df1])
df1=df1.sort_values(by=['contract_award_unique_key','action_date_year_quarter'])
df1=df1.reset_index(drop=True)

#%% Forward fill columns

col_names=['last_reported_start_date',
 'last_reported_end_date',
 'business_type',
 'last_reported_budget']

for col in col_names:
    df1[col]=df1.groupby('contract_award_unique_key')[col].transform(lambda x: x.ffill())

#%% Export to csv

df1.to_csv(output_folder+'resampled_qp_data/'+
                'qp_resampled_data_fy10_to_fy12_with_zero_obs.csv',index=False)




