#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Apr 23 21:04:57 2020

@author: vibhutidhingra
"""
import pandas as pd
from scipy.stats.mstats import winsorize
import numpy as np
import matplotlib.pyplot as plt 

pd.set_option('display.expand_frame_repr', False)

df_raw=pd.read_pickle('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data.pkl')
df=df_raw[df_raw.action_date<=pd.to_datetime('2012-07-01')]
df.recipient_duns=df.recipient_duns.astype(float).astype(str)
df.naics_code=df.naics_code.astype(str)

business_type=df.set_index('contract_award_unique_key')\
['contracting_officers_determination_of_business_size_code'].to_dict()
task_type=df.set_index('contract_award_unique_key')\
['product_or_service_code'].to_dict()
recipient_duns=df.set_index('contract_award_unique_key')\
['recipient_duns'].to_dict()
naics=df.set_index('contract_award_unique_key')\
['naics_code'].to_dict()

df.sort_values(by=['contract_award_unique_key','action_date'],inplace=True)

################################################################
# [Resampling] -- Skip later and just read the file
################################################################

select_variables=['contract_award_unique_key',
                    'period_of_performance_start_date',
                    'period_of_performance_current_end_date']

df_start_end = df.melt(id_vars=select_variables, \
                           value_vars='action_date',\
                           value_name='action_date_year_month')

df_sorted = df_start_end.groupby(['contract_award_unique_key']).apply\
            (lambda x: x.drop_duplicates('action_date_year_month').set_index\
             ('action_date_year_month').resample('Q',kind='period').last()).drop\
             (columns=['contract_award_unique_key','variable']).reset_index().ffill()
             
df_sorted.rename(columns=\
                 {'action_date_year_month':'action_date_year_quarter',\
                  'period_of_performance_start_date':'last_reported_start_date',\
                  'period_of_performance_current_end_date':'last_reported_end_date'},\
                  inplace=True)

df_sorted.sort_values(by=['contract_award_unique_key','action_date_year_quarter'],inplace=True) 

df_sorted.loc[df_sorted.contract_award_unique_key==df_sorted.contract_award_unique_key.shift(1),\
              "change_in_deadline"]=(df_sorted.last_reported_end_date-df_sorted.last_reported_end_date.shift(1)).dt.days            
              
df_sorted["business_type"]=df_sorted.contract_award_unique_key.map(business_type)
df_sorted["product_or_service_code"]=df_sorted.contract_award_unique_key.map(task_type)
df_sorted["recipient_duns"]=df_sorted.contract_award_unique_key.map(recipient_duns)
df_sorted["naics_code"]=df_sorted.contract_award_unique_key.map(naics)
df_sorted.to_csv('~/Dropbox/quickpay_resampled.csv',index=False)

################################################################
# [Plots]
################################################################

df_sorted=pd.read_csv('~/Dropbox/quickpay_resampled.csv')

df_sorted[['action_date_year_quarter','last_reported_start_date','last_reported_end_date']]=\
df_sorted[['action_date_year_quarter','last_reported_start_date','last_reported_end_date']].astype(np.datetime64)

df_sorted["winsorized_delay"]=winsorize(df_sorted.change_in_deadline,limits=0.001)

small_business=df_sorted.query("business_type=='S'")
large_business=df_sorted.query("business_type=='O'")

small_business_group=small_business.groupby('action_date_year_quarter',as_index=False).agg({'change_in_deadline':['mean','count','std'],'winsorized_delay':['mean','count','std']})
small_business_group.columns=pd.Index([e[0] +'_'+ e[1] for e in small_business_group.columns.tolist()])

large_business_group=large_business.groupby('action_date_year_quarter',as_index=False).agg({'change_in_deadline':['mean','count','std'],'winsorized_delay':['mean','count','std']})
large_business_group.columns=pd.Index([e[0] +'_'+ e[1] for e in large_business_group.columns.tolist()])

### Winsorized average ###

fig = plt.figure()
plt.xticks(rotation=90)
#plt.gca().xaxis.set_major_locator(LinearLocator(numticks=25))  
plt.title('0.1% Winsorized average delays (in days)')
plt.plot(small_business_group.action_date_year_quarter_.astype(str),\
         small_business_group.winsorized_delay_mean,label="small business",\
         marker='o', markersize=5)
plt.plot(large_business_group.action_date_year_quarter_.astype(str),\
         large_business_group.winsorized_delay_mean,label="large business",\
         marker='o', markersize=5)
plt.legend(loc="upper left")
plt.axvline(x=5.5, color="black")
text(7.5, 1.5,'Quickpay implemented\n (Apr 27, 2011)',
     horizontalalignment='center')
plt.xlabel("Year-Quarter",fontsize=14)
#plt.axvline(x=6)
savefig('/Users/vibhutidhingra/Desktop/research/Git:Github/qp_data_and_code/img/trends_winsorized.png', bbox_inches='tight')

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
plt.axvline(x=4.5,color="black")
text(6.5, 1.5,'Quickpay implemented\n (Apr 27, 2011)',
     horizontalalignment='center')
plt.legend(loc="lower left")
plt.xlabel("Year-Quarter",fontsize=14)
savefig('/Users/vibhutidhingra/Desktop/research/Git:Github/qp_data_and_code/img/trends_number_of_contracts.png', bbox_inches='tight')

fig = plt.figure()
plt.xticks(rotation=90)
#plt.gca().xaxis.set_major_locator(LinearLocator(numticks=25))  
plt.title('Raw average delays (in days)')
plt.plot(small_business_group.action_date_year_quarter_.astype(str),\
         small_business_group.change_in_deadline_mean,label="small business",\
         marker='o', markersize=5)
plt.plot(large_business_group.action_date_year_quarter_.astype(str),\
         large_business_group.change_in_deadline_mean,label="large business",\
         marker='o', markersize=5)
plt.legend(loc="upper left")
plt.axvline(x=5.5, color="black")
text(7.5, 1.5,'Quickpay implemented\n (Apr 27, 2011)',
     horizontalalignment='center')
plt.xlabel("Year-Quarter",fontsize=14)
savefig('/Users/vibhutidhingra/Desktop/research/Git:Github/qp_data_and_code/img/trends_raw.png', bbox_inches='tight')

