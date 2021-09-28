#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Sep 21 12:33:25 2021

@author: vibhutidhingra
"""

import pandas as pd

#%% Read data from API

def read_multiple_csvs(path):
    import glob, os
   # path = r'/Users/vibhutidhingra/Downloads/all_subawards'                    
    all_files = glob.glob(os.path.join(path, "*.csv"))  # advisable to use os.path.join as this makes concatenation OS independent
    df_from_each_file = (pd.read_csv(f) for f in all_files)
    df = pd.concat(df_from_each_file, ignore_index=True)
    return df

folder_path='/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/api_csv_initial'

df=read_multiple_csvs(folder_path)

df=df[['generated_unique_award_id',
        'date_signed']]

#%% Read data from original sample (first info)

orig_path='/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_first_reported.csv'

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
df3['modification_number']=df3['modification_number'].astype(str)

ub=pd.to_datetime('2012-07-01')

#%% Get first implementation sample

first=df3[df3.action_date<ub]

first.loc[first.date_signed.isnull(),"QuickPay (2009-2012)"]=\
"Date signed (API) not found"

first.loc[first.date_signed>first.period_of_performance_start_date,"QuickPay (2009-2012)"]=\
"Date signed (API) > Start date"


first.loc[first.date_signed==first.period_of_performance_start_date,"QuickPay (2009-2012)"]=\
"Date signed (API) = Start date"


first.loc[first.date_signed<first.period_of_performance_start_date,"QuickPay (2009-2012)"]=\
"Date signed (API) < Start date"

#%% Diagnostics

results=first.groupby("QuickPay (2009-2012)")['contract_award_unique_key'].nunique().reset_index()
results.contract_award_unique_key.sum()
results["Fraction of projects"]= round(results.contract_award_unique_key/results.contract_award_unique_key.sum(),2)

results=results.rename(columns={'contract_award_unique_key':'Number of projects'})

#%% Export to markdown

export_path='/Users/vibhutidhingra/Desktop/git_folders/QuickPay/QP_Data-and-code/notes'

print(results.to_markdown(), file=open(export_path+'/initial_diagonistic.md','wt'))  

#%% Do the same for action date now

first.loc[first.date_signed.isnull(),"QuickPay (2009-2012)"]=\
"Date signed (API) not found"

first.loc[first.date_signed>first.action_date,"QuickPay (2009-2012)"]=\
"Date signed (API) > Action date"


first.loc[first.date_signed==first.action_date,"QuickPay (2009-2012)"]=\
"Date signed (API) = Action date"


first.loc[first.date_signed<first.action_date,"QuickPay (2009-2012)"]=\
"Date signed (API) < Action date"

#%% Diagnostics

results2=first.groupby("QuickPay (2009-2012)")['contract_award_unique_key'].nunique().reset_index()
results2.contract_award_unique_key.sum()
results2["Fraction of projects"]= round(results2.contract_award_unique_key/results2.contract_award_unique_key.sum(),2)

results2=results2.rename(columns={'contract_award_unique_key':'Number of projects'})

#%% Export to markdown

print('\n', file=open(export_path+'/initial_diagonistic.md','a'))  

print(results2.to_markdown(), file=open(export_path+'/initial_diagonistic.md','a'))  


