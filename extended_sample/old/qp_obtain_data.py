#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Apr 28 12:57:41 2020

@author: vibhutidhingra
"""

#%% Load packages

import pandas as pd
#import quickpay_datacleaning as qpc
import glob, os

pd.set_option('display.expand_frame_repr', False)

#%% Define functions

def read_multiple_csvs(path):
   # path = r'/Users/vibhutidhingra/Downloads/all_subawards'                    
    all_files = glob.glob(os.path.join(path, "*.csv"))  # advisable to use os.path.join as this makes concatenation OS independent
    df_from_each_file = (pd.read_csv(f) for f in all_files)
    df = pd.concat(df_from_each_file, ignore_index=True)
    return df

def filter_naics_code(path):
    eligible_naics=['3366','1153','5612','3162','2379',\
                    '3159','5629','3149','2362','4831','6114',\
                    '3112','4812','4247','5311','3169','3333','3329','5415','3325']
    chunk_list=[]
    for chunk in pd.read_csv(path, chunksize=10000):
        chunk_list.append(chunk[(chunk.naics_code.astype(str).apply(lambda x: x[0:4]).isin(eligible_naics))\
                                &(chunk.awarding_agency_code==97)])
    filtered_df=pd.concat(chunk_list) #returns the dataframe 
    return filtered_df

def naics_filter_multiple_csvs(path_to_folder):
    all_files = glob.glob(os.path.join(path_to_folder, "*.csv"))  
    # create a list of path for each file in the folder
    df_from_each_file = (filter_naics_code(f) for f in all_files)
    # query each file in the folder and save as generator
    df = pd.concat(df_from_each_file, ignore_index=True)
    # convert to dataframe 
    return df

def filter_file(path,column_name,column_value):
    chunk_list=[]
    for chunk in pd.read_csv(path, chunksize=10000):
        chunk_list.append(chunk[chunk[column_name]== column_value])
    filtered_df=pd.concat(chunk_list) #returns the dataframe 
    return filtered_df

#%% Obtain the raw data for analysis  #

## naics filter:
# - top 20 four-digit naics in Barrot/Nanda paper (Table A.6)
# - defense contracts only

### FY2010 to FY2012 ### 
### Oct 1, 2009 to Sept 30, 2012 ### 

#%% 2010
main_path='/Users/vibhutid_admin/Dropbox/USA_Spending_Downloads/award_data_archive_20200205/'
path_fy2010=main_path+'FY2010_097_Contracts_Full_20200205'
# FY 2010 === 2009-10-01 to 2010-09-30
df_fy2010=naics_filter_multiple_csvs(path_fy2010)

#%% 2011
path_fy2011=main_path+'FY2011_097_Contracts_Full_20200205'
df_fy2011=naics_filter_multiple_csvs(path_fy2011)

#%% 2012
path_fy2012=main_path+'FY2012_097_Contracts_Full_20200205'
df_fy2012=naics_filter_multiple_csvs(path_fy2012)

#%% Combine all into one

qp_data_fy10_to_fy12=pd.concat([df_fy2010,df_fy2011,df_fy2012])

#%% Save to CSV

qp_data_fy10_to_fy12.to_csv('~/Desktop/qp_data_new.csv',index=False)
