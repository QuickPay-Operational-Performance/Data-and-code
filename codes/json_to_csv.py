#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Aug  9 21:29:30 2021

@author: vibhutidhingra
"""


#%% Load packages

import glob, os
import pandas as pd
import json
from json.decoder import JSONDecodeError

#%% Path to files

# folder where jsons are stored
path='/Users/vibhutidhingra/Downloads/1'

# location and name of the exported csv
save_path='/Users/vibhutidhingra/Desktop/qp_initial_1.csv'

#%% Get path for each file in the folder

# get paths for all json files
all_files = glob.glob(os.path.join(path, "*.json"))

#%% Select columns

cols_to_keep=['generated_unique_award_id',\
              'date_signed',\
              'base_and_all_options',\
              'period_of_performance_start_date',\
              'period_of_performance_end_date',\
              'total_obligation',\
              'period_of_performance_last_modified_date']

#%% Get all jsons as dataframe

# takes about 30 minutes to run

df_list=[]
for f in all_files:
    with open(f) as infile:
        try:
            data = json.load(infile)
            df=pd.json_normalize(data,sep='_')
            if len(df.columns)>=len(cols_to_keep):
            # some files dont have the columns    
                df_list.append(df[cols_to_keep])
        except JSONDecodeError: #catch errors for empty json files
            pass

#%% Combine into one dataframe

df_final = pd.concat(df_list,ignore_index=True)
    
#%% Save to CSV 

df_final.to_csv(save_path,index=False)