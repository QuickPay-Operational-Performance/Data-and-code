#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Apr 29 17:01:16 2020

@author: vibhutidhingra
"""


import pandas as pd
import numpy as np
import quickpay_datacleaning as qpc
import matplotlib.pyplot as plt

pd.set_option('display.expand_frame_repr', False)

#####################################
# Obtain the raw data for analysis  #
#####################################

folder_path='/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data'

df=qpc.read_multiple_csvs(folder_path)

#cols=list(set(df.columns[df.columns.str.contains('_date')])-{'action_date_fiscal_year'})
#date_cols=[x for x in cols if df[x].dtype==object]

#df[date_cols]=pd.to_datetime(df[cols])

df=df[df.action_date<=pd.to_datetime('2017-12-31')]
df.recipient_duns=df.recipient_duns.astype(float).astype(str)
df.naics_code=df.naics_code.astype(str)

business_type=df.set_index('contract_award_unique_key')\
['contracting_officers_determination_of_business_size_code'].to_dict()
task_type=df.set_index('contract_award_unique_key')\
['product_or_service_code'].to_dict()
recipient_duns=df.set_index('contract_award_unique_key')\
['recipient_duns'].to_dict()
naics=df.set_index('contract_award_unique_key')\
['naics_code'].to_dict()

df[['period_of_performance_start_date',\
   'period_of_performance_current_end_date']]=\
    pd.to_datetime(df[['period_of_performance_start_date',\
   'period_of_performance_current_end_date']],errors='coerce')

df.sort_values(by=['contract_award_unique_key','action_date'],inplace=True)

######################################################
# [Resampling] -- Skip later and just read the file
######################################################

select_variables=['contract_award_unique_key',
                    'period_of_performance_start_date',
                    'period_of_performance_current_end_date']

df_start_end = df.melt(id_vars=select_variables, \
                           value_vars='action_date',\
                           value_name='action_date_year_month')

df_sorted = df_start_end.groupby(['contract_award_unique_key']).apply\
            (lambda x: x.drop_duplicates('action_date_year_month').set_index\
             ('action_date_year_month').resample('Q').last()).drop\
             (columns=['contract_award_unique_key','variable']).reset_index().ffill()
             
df_sorted.rename(columns=\
                 {'action_date_year_month':'action_date_year_quarter',\
                  'period_of_performance_start_date':'last_reported_start_date',\
                  'period_of_performance_current_end_date':'last_reported_end_date'},\
                  inplace=True)

#############################################
# Calculate delays and add some covariates
#############################################

df_sorted[['last_reported_start_date','last_reported_end_date']]=\
df_sorted[['last_reported_start_date','last_reported_end_date']].apply(lambda x: pd.to_datetime(x,errors='coerce'),axis=1)

df_sorted.sort_values(by=['contract_award_unique_key','action_date_year_quarter'],inplace=True) 

df_sorted.loc[df_sorted.contract_award_unique_key==df_sorted.contract_award_unique_key.shift(1),\
              "change_in_deadline"]=(df_sorted.last_reported_end_date-df_sorted.last_reported_end_date.shift(1)).dt.days            
              
df_sorted["business_type"]=df_sorted.contract_award_unique_key.map(business_type)
df_sorted["product_or_service_code"]=df_sorted.contract_award_unique_key.map(task_type)
df_sorted["recipient_duns"]=df_sorted.contract_award_unique_key.map(recipient_duns)
df_sorted["naics_code"]=df_sorted.contract_award_unique_key.map(naics)

#################
# Save as csv 
#################

df_sorted.to_csv('~/Dropbox/qp_resampled_data_fy10_to_fy18.csv',index=False)

#############################################