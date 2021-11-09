#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jul 27 02:46:52 2021

@author: vibhutidhingra
"""


# Code to obtain matched data for QuickPay

#%% Load packages

import pandas as pd
import quickpay_datacleaning as qd

#%% Output path

directory='/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/'

#%% Read data

projects_to_keep=pd.read_csv(directory+'projects_to_keep.csv')

df=pd.read_csv(directory+\
               'resampled_qp_data/qp_resampled_data_fy10_to_fy12_with_zero_obs.csv')
# read quarterly resampled data

df=qd.convert_to_date_time(df)

df.action_date_year_quarter=\
pd.to_datetime(df.action_date_year_quarter)

# restrict to quarter ending June 30, 2012
df=df[(df.action_date_year_quarter<\
            pd.to_datetime('2012-07-01'))&
      (df.contract_award_unique_key.isin(projects_to_keep.contract_award_unique_key))]
    
# data is truncated at July 1, 2012 -- 
# so quarter ending Sept 30, 2012 will only have values as of July 1, 2012

df=df.sort_values(by=['contract_award_unique_key',\
                                'action_date_year_quarter'])

#%% #%% Remove null delay observations 

# this is for projects that are less than a quarter long

df.loc[df.contract_award_unique_key==df.contract_award_unique_key.shift(1),\
       "change_in_deadline"]=(df.last_reported_end_date-df.last_reported_end_date.shift(1)).dt.days
       
df=df[~df.change_in_deadline.isnull()]

#%% Read first info

cols_to_merge=['base_and_all_options_value',
 'product_or_service_code',
 'period_of_performance_start_date',
 'period_of_performance_current_end_date',
 'awarding_agency_code',
 'awarding_sub_agency_code',
 'type_of_contract_pricing_code',
 'number_of_offers_received',
 'contract_award_unique_key',
]

df_first_reported=pd.read_csv(directory+
                        'qp_data_first_reported.csv',
                        usecols=cols_to_merge)
# contains time-invariant contract characteristics 
# -- info when contract first appeared in the data

df=df.merge(df_first_reported,\
                            on='contract_award_unique_key')

df=df.rename(columns={'period_of_performance_start_date':'first_start_date',\
                   'period_of_performance_current_end_date':'first_end_date'})

#%% Select matching columns

match_cols=['product_or_service_code',
            'awarding_sub_agency_code',
            'type_of_contract_pricing_code']

df["group_id"]=df.groupby(match_cols)\
                .grouper.group_info[0]

#%% Get groups that have both treatment & control
                
df_grouped=df.groupby('group_id')\
['business_type'].nunique().reset_index()

keep_ids=set(df_grouped[df_grouped.business_type==2]\
.group_id)

#%% Keep only paired observations

matched_df=df[df.group_id.isin(keep_ids)] 

matched_df["new_id"]=list(zip(matched_df.group_id,\
          matched_df.business_type))

#%% Assign weights -- step 1

# get number of treated & control obs in each subclass
num_projects=matched_df.groupby(['group_id',\
                                 'business_type'])\
['contract_award_unique_key'].count().reset_index()


# controls prelim_weight= num_treated/num_control
num_projects.loc[\
    (num_projects.business_type=='O')&\
    (num_projects.group_id==num_projects.group_id.shift(-1)),"prelim_weight"]=\
    num_projects.contract_award_unique_key.shift(-1)/num_projects.contract_award_unique_key

# treated prelim_weight= 1    
num_projects.loc[\
  num_projects.business_type=='S',"prelim_weight"]=1

# create new id
num_projects["new_id"]=list(zip(num_projects.group_id,\
          num_projects.business_type))
                 
#%% Assign weights -- step 2

# create dictionary of prelim weights
    
pweights_dict=num_projects.set_index('new_id')['prelim_weight'].to_dict()

matched_df["prelim_weights"]=matched_df.new_id.\
                    map(pweights_dict.get)

#%% Scale weights

sum_control_prelim_weights=matched_df[matched_df.business_type=='O']\
.prelim_weights.sum()

num_unique_controls=len(matched_df[matched_df.business_type=='O'].drop_duplicates())

#%% Assign weights

# controls = prelim_weight*num_controls/sum_control_weights
matched_df.loc[(matched_df.business_type=='O'),"weight"]=\
   (matched_df.prelim_weights*num_unique_controls)/sum_control_prelim_weights
   
# treated weight= 1
matched_df.loc[\
  matched_df.business_type=='S',"weight"]=matched_df.prelim_weights

#%% Drop columns

matched_df=matched_df.drop(columns=\
                           ['new_id', 'prelim_weights'])

#%% Save to csv

matched_df.to_csv(directory+\
                  'qp_first_matched_sample.csv',\
                  index=False)




