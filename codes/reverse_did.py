#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jun 10 20:55:03 2020

@author: vibhutidhingra
"""
import pandas as pd
from scipy.stats.mstats import winsorize
import numpy as np
import matplotlib.pyplot as plt 

df=pd.read_csv('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/resampled_qp_data/qp_resampled_data_fy10_to_fy18.csv')
# contracts signed after Feb 21, 2013 i.e. on/after March 31, 2013
# TREAT = 1 if LB & quarter after Aug 1, 2014
# Look at new firms only

df.action_date_year_quarter=df.action_date_year_quarter.astype('datetime64')
df.recipient_duns=df.recipient_duns.astype('Int64')

after_mar_2013=set(df[df.action_date_year_quarter>=pd.to_datetime('2013-03-31')].contract_award_unique_key)
before_mar_2013=set(df[df.action_date_year_quarter<pd.to_datetime('2013-03-31')].contract_award_unique_key)

new_contracts=after_mar_2013-before_mar_2013

dfs=df[df.contract_award_unique_key.isin(new_contracts)].reset_index()

dfs[['last_reported_start_date','last_reported_end_date']]=\
dfs[['last_reported_start_date','last_reported_end_date']].astype(np.datetime64)

lim=0.01
dfs["winsorized_delay"]=winsorize(dfs.change_in_deadline,limits=lim)

small_business=dfs.query("business_type=='S'")
large_business=dfs.query("business_type=='O'")

small_business_group=small_business.groupby('action_date_year_quarter',as_index=False).agg({'change_in_deadline':['mean','count','std'],'winsorized_delay':['mean','count','std']})
small_business_group.columns=pd.Index([e[0] +'_'+ e[1] for e in small_business_group.columns.tolist()])

large_business_group=large_business.groupby('action_date_year_quarter',as_index=False).agg({'change_in_deadline':['mean','count','std'],'winsorized_delay':['mean','count','std']})
large_business_group.columns=pd.Index([e[0] +'_'+ e[1] for e in large_business_group.columns.tolist()])

fig = plt.figure(figsize(8,4))
plt.xticks(rotation=90)
#plt.gca().xaxis.set_major_locator(LinearLocator(numticks=25))  
plt.title('New contracts (active on/after Mar 31, 2013) \n Average delays (in days) -- winsorized at '+ str(int(lim*100)) +'%')
plt.plot(small_business_group.action_date_year_quarter_.astype(str),\
         small_business_group.winsorized_delay_mean,label="small business",\
         marker='o', markersize=5)
plt.plot(large_business_group.action_date_year_quarter_.astype(str),\
         large_business_group.winsorized_delay_mean,label="large business",\
         marker='o', markersize=5)
plt.legend(loc="upper left")
axvline(x=4.5,color='black')
plt.xlabel("Year-Quarter",fontsize=14)
savefig('/Users/vibhutidhingra/Desktop/research/Git:Github/qp_data_and_code/img/reverse_did_trends.png', bbox_inches='tight')



