#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri May 22 17:57:53 2020

@author: vibhutidhingra
"""


import pandas as pd
import glob, os

pd.set_option('display.expand_frame_repr', False)

path_to_folder='/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data'
col_names=['contract_award_unique_key','recipient_duns',\
           'recipient_name', 'contracting_officers_determination_of_business_size']

all_files = glob.glob(os.path.join(path_to_folder, "*.csv"))  
# create a list of path for each file in the folder
df_from_each_file = (pd.read_csv(f,usecols=col_names) for f in all_files)
# query each file in the folder and save as generator
df = pd.concat(df_from_each_file, ignore_index=True)
# merge into one dataset
df_unique=df.drop_duplicates(subset='contract_award_unique_key').reset_index()
# drop duplicates
df_unique.recipient_duns=df_unique.recipient_duns.astype('Int64')
# convert duns number to integer type 
df_unique.to_csv('/Users/vibhutidhingra/Dropbox/data_quickpay/full_sample_recipient_duns.csv',index=False)
# save to csv 

# example rows/columns
df_example=df_unique[['recipient_duns','recipient_name','contracting_officers_determination_of_business_size']].iloc[0:5]
print(df_example.to_markdown(showindex=False).replace('\n',''))

##########################################################
# Save into Multiple CSVs 
# Intellect db only allows to search for 500 duns at a time 
##########################################################

df=pd.read_csv('/Users/vibhutidhingra/Dropbox/data_quickpay/full_sample_recipient_duns.csv')
df.recipient_duns=df.recipient_duns.astype('Int64')
unique_duns=df[['recipient_duns']].drop_duplicates().reset_index(drop=True)

size = 500
list_of_dfs = [unique_duns.loc[i:i+size-1,:] for i in range(0, len(unique_duns),size)]
# converts into list of dataframes 

for i in range(0,len(list_of_dfs)):
   folder_path='/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/split_csvs_for_duns'
   file_name = 'duns_file_'+str(i)
   file_path=folder_path+'/'+file_name+'.csv'
   list_of_dfs[i].to_csv(file_path,index=False)