#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue May  4 19:51:07 2021

@author: vibhutidhingra
"""

# Code for project data snapshot shown in writeup

import pandas as pd #global function needed for eval  

def filter_file_query(path,query_detail):
        chunk_list=[]
        for chunk in pd.read_csv(path, chunksize=10000): 
            chunk_list.append(chunk.query(query_detail,engine='python'))
        filtered_df=pd.concat(chunk_list) #returns the dataframe 
        return filtered_df
# we can use python queries if filtering on more than one column
# example: 
# query_detail = "contracting_officers_determination_of_business_size_code=='S' & small_disadvantaged_business=='t'"
 
path='/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_fy10_to_fy18.csv'
query_detail = "contract_award_unique_key=='CONT_AWD_0002_9700_W912DW10D1017_9700'"


df=filter_file_query(path,query_detail)
df.action_date=pd.to_datetime(df.action_date, errors='coerce')
df.sort_values(by='action_date',inplace=True)

cols_needed=['contract_award_unique_key',\
 'base_and_all_options_value',
 'primary_place_of_performance_city_name',
 'primary_place_of_performance_state_name',
 'period_of_performance_start_date',\
 'period_of_performance_current_end_date',\
 'awarding_agency_name',\
 'awarding_sub_agency_name',\
 'recipient_duns',
 'recipient_name',\
 'type_of_contract_pricing',
 'award_description',\
 'product_or_service_code',
 'product_or_service_code_description',
 'contract_bundling_code',\
 'naics_code',
 'naics_description',\
 'extent_competed_code',
 'extent_competed',
 'solicitation_procedures_code',
 'solicitation_procedures',\
 'other_than_full_and_open_competition',
 'number_of_offers_received',\
 'performance_based_service_acquisition_code',
 'performance_based_service_acquisition',
 'contract_financing_code',
 'contract_financing',\
 'contracting_officers_determination_of_business_size',
 'contracting_officers_determination_of_business_size_code',
 'emerging_small_business']

example_df=df[cols_needed].iloc[0]
print(example_df.to_latex())

# To get final end date: 
df.period_of_performance_current_end_date.tail()

# To get an example modification
print(df[['period_of_performance_current_end_date',\
          'award_description']].iloc[0:5].to_latex(index=False))