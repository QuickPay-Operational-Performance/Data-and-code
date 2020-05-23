#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri May 22 23:52:36 2020

@author: vibhutidhingra
"""


import pandas as pd
import glob, os

pd.set_option('display.expand_frame_repr', False)

path_to_folder='/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data'
col_names=['contract_award_unique_key',\
           'performance_based_service_acquisition_code',\
           'performance_based_service_acquisition',\
           'contracting_officers_determination_of_business_size_code',\
           'contracting_officers_determination_of_business_size']

all_files = glob.glob(os.path.join(path_to_folder, "*.csv"))  
# create a list of path for each file in the folder
df_from_each_file = (pd.read_csv(f,usecols=col_names) for f in all_files)
# query each file in the folder and save as generator
df = pd.concat(df_from_each_file, ignore_index=True)
# merge into one dataset

pba_key=df[['performance_based_service_acquisition_code','performance_based_service_acquisition']].drop_duplicates().reset_index(drop=True)

pb_acq=df.groupby(['performance_based_service_acquisition_code',\
                   'contracting_officers_determination_of_business_size'])['contract_award_unique_key'].nunique().reset_index()

pb_acq.rename(columns={'contract_award_unique_key':'Number of contracts'},inplace=True)

print(pb_acq.to_markdown())
print(pba_key.to_markdown())
             
