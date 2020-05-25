#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri May 22 23:52:36 2020

@author: vibhutidhingra
"""


import pandas as pd
import glob, os
from scipy.stats.mstats import winsorize
import numpy as np
import matplotlib.pyplot as plt 

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
             
################################################################
# add column for performance based acquisition to Resampled data
################################################################

df_sorted=pd.read_csv('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/resampled_qp_data/qp_resampled_data_fy10_to_fy18.csv')

df_sorted[['action_date_year_quarter','last_reported_start_date','last_reported_end_date']]=\
df_sorted[['action_date_year_quarter','last_reported_start_date','last_reported_end_date']].astype(np.datetime64)

df_sorted["winsorized_delay"]=winsorize(df_sorted.change_in_deadline,limits=0.001)

# add column for performance based acquisition 
df_sorted=df_sorted.merge(df[['performance_based_service_acquisition_code',\
                              'performance_based_service_acquisition',\
                              'contract_award_unique_key']].drop_duplicates(\
subset='contract_award_unique_key').reset_index(drop=True),on='contract_award_unique_key')

################################################################
# [Plots]
################################################################

####################
# Small Businesses #
####################
small_business=df_sorted.query("business_type=='S'")
small_business_pb=small_business.query("performance_based_service_acquisition_code=='Y'")
small_business_not_pb=small_business.query("performance_based_service_acquisition_code!='Y'")

sb_pb_group=small_business_pb.groupby('action_date_year_quarter',as_index=False).agg({'change_in_deadline':['mean','count','std'],'winsorized_delay':['mean','count','std']})
sb_not_pb_group=small_business_not_pb.groupby('action_date_year_quarter',as_index=False).agg({'change_in_deadline':['mean','count','std'],'winsorized_delay':['mean','count','std']})

sb_pb_group.columns=pd.Index([e[0] +'_'+ e[1] for e in sb_pb_group.columns.tolist()])
sb_not_pb_group.columns=pd.Index([e[0] +'_'+ e[1] for e in sb_not_pb_group.columns.tolist()])

### Winsorized average ###

fig = plt.figure(figsize(15,8))
plt.xticks(rotation=90)
#plt.gca().xaxis.set_major_locator(LinearLocator(numticks=25))  
plt.title('Small Business Average delays (in days) -- winsorized (0.1%)')
plt.plot(sb_pb_group.action_date_year_quarter_.astype(str),\
         sb_pb_group.winsorized_delay_mean,label="Performance-Based contract",\
         marker='o', markersize=5)
plt.plot(sb_not_pb_group.action_date_year_quarter_.astype(str),\
         sb_not_pb_group.winsorized_delay_mean,label="Not Performance-Based",\
         marker='o', markersize=5)
plt.legend(loc="upper left")
plt.axvline(x=5.5, color="black")
text(8, 60,'Payment accelerated to \n Small Businesses \n (Apr 27, 2011)',
    horizontalalignment='center')
plt.xlabel("Year-Quarter",fontsize=14)
savefig('/Users/vibhutidhingra/Desktop/research/Git:Github/qp_data_and_code/img/sb_performance_based_comparison.png', bbox_inches='tight')


####################
# Large Businesses #
####################
large_business=df_sorted.query("business_type=='O'")
large_business_pb=large_business.query("performance_based_service_acquisition_code=='Y'")
large_business_not_pb=large_business.query("performance_based_service_acquisition_code!='Y'")

lb_pb_group=large_business_pb.groupby('action_date_year_quarter',as_index=False).agg({'change_in_deadline':['mean','count','std'],'winsorized_delay':['mean','count','std']})
lb_not_pb_group=large_business_not_pb.groupby('action_date_year_quarter',as_index=False).agg({'change_in_deadline':['mean','count','std'],'winsorized_delay':['mean','count','std']})

lb_pb_group.columns=pd.Index([e[0] +'_'+ e[1] for e in lb_pb_group.columns.tolist()])
lb_not_pb_group.columns=pd.Index([e[0] +'_'+ e[1] for e in lb_not_pb_group.columns.tolist()])

### Winsorized average ###

fig = plt.figure(figsize(15,8))
plt.xticks(rotation=90)
#plt.gca().xaxis.set_major_locator(LinearLocator(numticks=25))  
plt.title('Large Business Average delays (in days) -- winsorized (0.1%)')
plt.plot(lb_pb_group.action_date_year_quarter_.astype(str),\
         lb_pb_group.winsorized_delay_mean,label="Performance-Based contract",\
         marker='o', markersize=5)
plt.plot(lb_not_pb_group.action_date_year_quarter_.astype(str),\
         lb_not_pb_group.winsorized_delay_mean,label="Not Performance-Based",\
         marker='o', markersize=5)
plt.legend(loc="upper left")
plt.xlabel("Year-Quarter",fontsize=14)
plt.axvline(x=10.5, color="black")
plt.axvline(x=12.5, color="black")
plt.axvline(x=18.5, color="black")
text(22.5, 60,'Payment accelerated to \n Large Businesses \n (Aug 1, 2014)',
    horizontalalignment='center')
savefig('/Users/vibhutidhingra/Desktop/research/Git:Github/qp_data_and_code/img/lb_performance_based_comparison.png', bbox_inches='tight')
