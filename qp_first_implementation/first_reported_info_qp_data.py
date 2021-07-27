#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jul 27 10:50:46 2021

@author: vibhutidhingra
"""

# Code to obtain first info data for QuickPay


# Script to get contract characteristics when it first appeared in the data
# This is useful to have as a separate file coz frequently used in regressions
# E.g. to get time-invariant contract characteristics such as financing, performance-based, etc.

#%% Load packages

import pandas as pd

#%% Output path

directory='/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/'

#%% Read data

df=pd.read_csv(directory+'qp_data_fy10_to_fy18.csv')

df['action_date']=pd.to_datetime(df.action_date,errors='coerce')
qp_data_first_reported=df.sort_values(by=['contract_award_unique_key',\
                                     'action_date']).drop_duplicates(subset=\
                        'contract_award_unique_key').reset_index(drop=True)

#%% Save to csv

qp_data_first_reported.to_csv(directory+'qp_data_first_reported.csv',\
                              index=False)