#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Aug 11 15:48:10 2020

@author: vibhutidhingra
"""

# Script to get contract characteristics when it first appeared in the data
# This is useful to have as a separate file coz frequently used in regressions
# E.g. to get time-invariant contract characteristics such as financing, performance-based, etc.

import pandas as pd

df=pd.read_csv('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_fy10_to_fy18.csv')

df['action_date']=pd.to_datetime(df.action_date,errors='coerce')
qp_data_first_reported=df.sort_values(by=['contract_award_unique_key',\
                                     'action_date']).drop_duplicates(subset=\
                        'contract_award_unique_key').reset_index(drop=True)

#%%
qp_data_first_reported.to_csv('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_first_reported.csv',index=False)