#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Sep 26 01:00:44 2021

@author: vibhutidhingra
"""

# Projects for which we have correct start dates (based on API)

#%% Packages and directory

import pandas as pd

main_directory='/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/'

#%% Read data from API

def read_multiple_csvs(path):
    import glob, os
   # path = r'/Users/vibhutidhingra/Downloads/all_subawards'                    
    all_files = glob.glob(os.path.join(path, "*.csv"))  # advisable to use os.path.join as this makes concatenation OS independent
    df_from_each_file = (pd.read_csv(f) for f in all_files)
    df = pd.concat(df_from_each_file, ignore_index=True)
    return df

folder_path=main_directory+'api_csv_initial'

df=read_multiple_csvs(folder_path)

df=df[['generated_unique_award_id',
        'date_signed']]

#%% Read data from original sample (first info)

orig_path=main_directory+'qp_data_first_reported.csv'

df2=pd.read_csv(orig_path,usecols=['contract_award_unique_key',
                                   'period_of_performance_start_date',
                                   'action_date',
                                   'modification_number'])

#%% Merge the two

df3=pd.merge(df,df2,left_on='generated_unique_award_id',
             right_on='contract_award_unique_key',
             how='outer')

df3['date_signed']=pd.to_datetime(df3.date_signed)
df3['period_of_performance_start_date']=pd.to_datetime(df3.period_of_performance_start_date)
df3['action_date']=pd.to_datetime(df3.action_date)

ub=pd.to_datetime('2012-07-01')

#%% Get first implementation sample

# "action_date" matches "date_signed" more accurately than "period_of_performance_start_date"

first=df3[df3.action_date<ub]

# Keep those projects for which either we don't have date signed in API
# or those that match action date

projects_to_keep=first[(first.date_signed.isnull())|
                       (first.date_signed==first.action_date)]['contract_award_unique_key'].drop_duplicates()

#%% Export to csv

projects_to_keep.to_csv(main_directory+"projects_to_keep.csv", sep=',',index=False)



