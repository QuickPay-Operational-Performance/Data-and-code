#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Apr 29 21:01:23 2020

@author: vibhutidhingra
"""

import pandas as pd
from scipy.stats.mstats import winsorize
import numpy as np
import matplotlib.pyplot as plt 

pd.set_option('display.expand_frame_repr', False)

df_sorted=pd.read_csv('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/resampled_qp_data/qp_resampled_data_fy10_to_fy18.csv')

df_sorted[['action_date_year_quarter','last_reported_start_date','last_reported_end_date']]=\
df_sorted[['action_date_year_quarter','last_reported_start_date','last_reported_end_date']].astype(np.datetime64)

df_sorted["winsorized_delay"]=winsorize(df_sorted.change_in_deadline,limits=0.001)

small_business=df_sorted.query("business_type=='S'")
large_business=df_sorted.query("business_type=='O'")

small_business_group=small_business.groupby('action_date_year_quarter',as_index=False).agg({'change_in_deadline':['mean','count','std'],'winsorized_delay':['mean','count','std']})
small_business_group.columns=pd.Index([e[0] +'_'+ e[1] for e in small_business_group.columns.tolist()])

large_business_group=large_business.groupby('action_date_year_quarter',as_index=False).agg({'change_in_deadline':['mean','count','std'],'winsorized_delay':['mean','count','std']})
large_business_group.columns=pd.Index([e[0] +'_'+ e[1] for e in large_business_group.columns.tolist()])

################################################################
# [Plots]
################################################################

### Winsorized average ###

fig = plt.figure(figsize(15,8))
plt.xticks(rotation=90)
#plt.gca().xaxis.set_major_locator(LinearLocator(numticks=25))  
plt.title('Average delays (in days) -- winsorized (0.1%)')
plt.plot(small_business_group.action_date_year_quarter_.astype(str),\
         small_business_group.winsorized_delay_mean,label="small business",\
         marker='o', markersize=5)
plt.plot(large_business_group.action_date_year_quarter_.astype(str),\
         large_business_group.winsorized_delay_mean,label="large business",\
         marker='o', markersize=5)
plt.legend(loc="upper left")
plt.axvline(x=5.5, color="black")
plt.axvline(x=10.5, color="black")
plt.axvline(x=12.5, color="black")
plt.axvline(x=18.5, color="black")
plt.axvline(x=32, color="black")
text(8, 60,'Payment accelerated to \n Small Businesses \n (Apr 27, 2011)',
    horizontalalignment='center')
text(15.5, 60,'Payment accelerated to \n Small Businesses \n (Feb 21, 2013)',
    horizontalalignment='center')
text(22.5, 60,'Payment accelerated to \n Large Businesses \n (Aug 1, 2014)',
    horizontalalignment='center')
plt.xlabel("Year-Quarter",fontsize=14)
savefig('/Users/vibhutidhingra/Desktop/research/Git:Github/qp_data_and_code/img/full_sample_trends_winsorized.png', bbox_inches='tight')

### Winsorized std dev ###

fig = plt.figure(figsize(15,8))
plt.xticks(rotation=90)
#plt.gca().xaxis.set_major_locator(LinearLocator(numticks=25))  
plt.title(' Std Dev of delays (in days) -- winsorized (0.1%)')
plt.plot(small_business_group.action_date_year_quarter_.astype(str),\
         small_business_group.winsorized_delay_std,label="small business",\
         marker='o', markersize=5)
plt.plot(large_business_group.action_date_year_quarter_.astype(str),\
         large_business_group.winsorized_delay_std,label="large business",\
         marker='o', markersize=5)
plt.legend(loc="upper left")
plt.axvline(x=5.5, color="black")
plt.axvline(x=10.5, color="black")
plt.axvline(x=12.5, color="black")
plt.axvline(x=18.5, color="black")
plt.axvline(x=32, color="black")
text(8, 300,'Payment accelerated to \n Small Businesses \n (Apr 27, 2011)',
    horizontalalignment='center')
text(15.5, 300,'Payment accelerated to \n Small Businesses \n (Feb 21, 2013)',
    horizontalalignment='center')
text(22.5, 300,'Payment accelerated to \n Large Businesses \n (Aug 1, 2014)',
    horizontalalignment='center')
plt.xlabel("Year-Quarter",fontsize=14)
savefig('/Users/vibhutidhingra/Desktop/research/Git:Github/qp_data_and_code/img/full_sample_trends_winsorized_std_dev.png', bbox_inches='tight')

### Number of contracts ###

fig = plt.figure()
plt.xticks(rotation=90)
#plt.gca().xaxis.set_major_locator(LinearLocator(numticks=25)) 
plt.title('Number of active contracts') 
lb=large_business_group[large_business_group.action_date_year_quarter_>pd.to_datetime('2009-12-31')]
sb=small_business_group[small_business_group.action_date_year_quarter_>pd.to_datetime('2009-12-31')]
plt.plot(sb.action_date_year_quarter_.astype(str),\
         sb.winsorized_delay_count,label="small business",\
         marker='o', markersize=5)
plt.plot(lb.action_date_year_quarter_.astype(str),\
         lb.winsorized_delay_count,label="large business",\
         marker='o', markersize=5)
plt.legend(loc="upper left")
plt.axvline(x=5.5, color="black")
plt.axvline(x=10.5, color="black")
plt.axvline(x=12.5, color="black")
plt.axvline(x=18.5, color="black")
plt.axvline(x=32, color="black")
text(8, 5000,'Payment accelerated to \n Small Businesses \n (Apr 27, 2011)',
    horizontalalignment='center')
text(15.5, 5000,'Payment accelerated to \n Small Businesses \n (Feb 21, 2013)',
    horizontalalignment='center')
text(22.5, 5000,'Payment accelerated to \n Large Businesses \n (Aug 1, 2014)',
    horizontalalignment='center')
plt.xlabel("Year-Quarter",fontsize=14)
savefig('/Users/vibhutidhingra/Desktop/research/Git:Github/qp_data_and_code/img/full_sample_trends_number_of_contracts.png', bbox_inches='tight')

### Average raw delays ###

fig = plt.figure()
plt.xticks(rotation=90)
#plt.gca().xaxis.set_major_locator(LinearLocator(numticks=25))  
plt.title('Average raw  delays (in days)')
plt.plot(small_business_group.action_date_year_quarter_.astype(str),\
         small_business_group.change_in_deadline_mean,label="small business",\
         marker='o', markersize=5)
plt.plot(large_business_group.action_date_year_quarter_.astype(str),\
         large_business_group.change_in_deadline_mean,label="large business",\
         marker='o', markersize=5)
plt.legend(loc="upper left")
plt.axvline(x=5.5, color="black")
plt.axvline(x=10.5, color="black")
plt.axvline(x=12.5, color="black")
plt.axvline(x=18.5, color="black")
plt.axvline(x=32, color="black")
text(8, 60,'Payment accelerated to \n Small Businesses \n (Apr 27, 2011)',
    horizontalalignment='center')
text(15.5, 60,'Payment accelerated to \n Small Businesses \n (Feb 21, 2013)',
    horizontalalignment='center')
text(22.5, 60,'Payment accelerated to \n Large Businesses \n (Aug 1, 2014)',
    horizontalalignment='center')
plt.xlabel("Year-Quarter",fontsize=14)
savefig('/Users/vibhutidhingra/Desktop/research/Git:Github/qp_data_and_code/img/full_sample_trends_raw.png', bbox_inches='tight')
