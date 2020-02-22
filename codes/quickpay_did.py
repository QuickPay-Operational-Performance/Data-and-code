#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Feb 16 09:02:31 2020

@author: vibhutidhingra
"""

import pandas as pd
import numpy as np
import quickpay_datacleaning as qpc
import matplotlib.pyplot as plt

pd.set_option('display.expand_frame_repr', False)

#####################################
# Obtain the raw data for analysis  #
#####################################

## naics filter:
# - top 20 four-digit naics in Barrot/Nanda paper (Table A.6)
# - firm fixed price
# - defense contracts only
# - not bundled contract
# - not small disadvantaged business

path_fy2010='/Users/vibhutidhingra/Dropbox/data_quickpay/FY2010_097_Contracts_Full_20200205'
# FY 2010 === 2009-10-01 to 2010-09-30
df_fy2010=qpc.naics_filter_multiple_csvs(path_fy2010)

path_fy2011='/Users/vibhutidhingra/Dropbox/data_quickpay/FY2011_097_Contracts_Full_20200205'
df_fy2011=qpc.naics_filter_multiple_csvs(path_fy2011)

path_fy2012='/Users/vibhutidhingra/Dropbox/data_quickpay/FY2012_097_Contracts_Full_20200205'
df_fy2012=qpc.naics_filter_multiple_csvs(path_fy2012)

qp_data=pd.concat([df_fy2010,df_fy2011,df_fy2012])

qp_data=qpc.convert_to_date_time(qp_data)

qp_data["top_level_psc"]=qp_data.product_or_service_code.apply(lambda x: str(x)[0:2])

qp_data["small_business"]=\
qp_data.contracting_officers_determination_of_business_size_code.\
apply(lambda x: int(x=='S'))

qp_data["four_digit_naics"]=qp_data.naics_code.apply(lambda x: int(str(x)[0:4]))

qp_data.to_pickle('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data.pkl')

############################################################
# Quickpay for SB only: Apr 27, 2011 to July 11, 2012
############################################################
# Divide contracts into before and after quickpay
############################################################

# qp_data=pd.read_pickle('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data.pkl')

qp_data_truncate=qp_data[qp_data.action_date<=pd.to_datetime('2012-07-01')]
# truncate because ALL primes (large and small) were to 
# receive accelerated payments from July 11, 2012 onwards

max_dates=qp_data_truncate.groupby('contract_award_unique_key')['action_date',\
                                 'period_of_performance_current_end_date',\
                                 'period_of_performance_start_date'].max().reset_index()
max_dates=max_dates.rename(columns={'action_date':'max_action_date',\
                                    'period_of_performance_current_end_date':'max_end_date',\
                                    'period_of_performance_start_date':'max_start_date'})
min_dates=qp_data_truncate.groupby('contract_award_unique_key')['action_date',\
                                 'period_of_performance_current_end_date',\
                                 'period_of_performance_start_date'].min().reset_index()
min_dates=min_dates.rename(columns={'action_date':'min_action_date',\
                                    'period_of_performance_current_end_date':'min_end_date',\
                                    'period_of_performance_start_date':'min_start_date'})

max_min_dates=min_dates.merge(max_dates,on='contract_award_unique_key')

# set of contracts that ended before quickpay was implemented (on/before April 1, 2011)
pre_treatment_contracts=set(max_min_dates[max_min_dates.max_end_date<=pd.to_datetime('2011-04-01')].contract_award_unique_key)

# set of contracts that started after quickpay was launched (May 1, 2011 onwards)
# also put filter on min end date to avoid data entry/admin issues
post_treatment_contracts=set(max_min_dates\
                             [(max_min_dates.min_start_date>=pd.to_datetime('2011-05-01'))\
                              &(max_min_dates.min_end_date>=pd.to_datetime('2011-05-01'))]\
                              .contract_award_unique_key)

# some contracts appear in both sets - likely admin issues/data entry errors
# remove them from the above sets 
both=pre_treatment_contracts&post_treatment_contracts
pre_treatment_contracts=pre_treatment_contracts-both
post_treatment_contracts=post_treatment_contracts-both

############################################
# Calculate delays and generate sample 
#############################################
pre_treatment_df=qp_data_truncate[qp_data_truncate.contract_award_unique_key.isin(pre_treatment_contracts)]
pre_treatment_delay=qpc.calculate_delays(pre_treatment_df)

post_treatment_df=qp_data_truncate[qp_data_truncate.contract_award_unique_key.isin(post_treatment_contracts)]
post_treatment_delay=qpc.calculate_delays(post_treatment_df)

# Get other variables 
cols=['contract_award_unique_key',\
      'contracting_officers_determination_of_business_size_code',\
      'product_or_service_code',\
      'top_level_psc',\
      'four_digit_naics',\
      'small_business',
      'naics_code']

pre_treatment_delay=pre_treatment_delay.merge(pre_treatment_df[cols].drop_duplicates(subset='contract_award_unique_key'),on='contract_award_unique_key')
pre_treatment_delay["after_quickpay"]=int(False)

post_treatment_delay=post_treatment_delay.merge(post_treatment_df[cols].drop_duplicates(subset='contract_award_unique_key'),on='contract_award_unique_key')
post_treatment_delay["after_quickpay"]=int(True)

sample_did=pd.concat([post_treatment_delay,pre_treatment_delay])

sample_did.to_csv('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_sample_did.csv',index=False)

#############
# Make plot
##############

plot_df=pd.DataFrame()
plot_df["small_business_delays"]=np.nan
plot_df["large_business_delays"]=np.nan
plot_df["time_period"]=["before_quickpay","after_quickpay"]

plot_df["small_business_delays"].iloc[0]=sample_did.query("small_business==1 & after_quickpay==0").days_of_change_in_deadline_overall.mean()
plot_df["small_business_delays"].iloc[1]=sample_did.query("small_business==1 & after_quickpay==1").days_of_change_in_deadline_overall.mean()

plot_df["large_business_delays"].iloc[0]=sample_did.query("small_business==0 & after_quickpay==0").days_of_change_in_deadline_overall.mean()
plot_df["large_business_delays"].iloc[1]=sample_did.query("small_business==0 & after_quickpay==1").days_of_change_in_deadline_overall.mean()

fig = plt.figure()
plt.plot(plot_df.time_period,plot_df.small_business_delays,label="small_business")
plt.plot(plot_df.time_period,plot_df.large_business_delays,label="large_business")
plt.legend(bbox_to_anchor=(1.04,1), loc="upper left")
plt.ylabel('Average days of delay', fontsize=16)
plt.savefig('/Users/vibhutidhingra/Dropbox/data_quickpay/did_plot.png', bbox_inches = "tight")
