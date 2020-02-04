#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Feb  1 19:12:48 2020

@author: vibhutidhingra
"""
import quickpay_datacleaning as qpc
import matplotlib.pyplot as plt 
import pandas as pd
import numpy as np 

######################
# Get filtered files #
######################

path_2010='/Users/vibhutidhingra/Downloads/FY2010_097_Contracts_Full_20200110'
# folder containing files for all DoD transactions in FY 2010
path_2013='/Users/vibhutidhingra/Downloads/FY2013_097_Contracts_Full_20200110'
# folder containing files for all DoD transactions in FY 2013

## FIXED PRICE SB
query_osb_fp="contracting_officers_determination_of_business_size_code=='S' \
            & small_disadvantaged_business=='f' &\
            type_of_contract_pricing_code in ['A','B','J','K','L','M']"         
# query small businesses that were not disadvantaged and offered Fixed Pricing
df_fp_2010=qpc.query_multiple_csvs(path_2010,query_osb_fp)
df_fp_2013=qpc.query_multiple_csvs(path_2013,query_osb_fp)
# get dataframe corresponding to query

## COST REIMBURSEMENT SB
query_osb_cost="contracting_officers_determination_of_business_size_code=='S' \
            & small_disadvantaged_business=='f' \
            & type_of_contract_pricing_code in ['R','S','T','U','V']"
# query small businesses that were not disadvantaged and offered Cost Pricing           
df_cost_2010=qpc.query_multiple_csvs(path_2010,query_osb_cost)
df_cost_2013=qpc.query_multiple_csvs(path_2013,query_osb_cost)
# get dataframe corresponding to query

## Save files to pickle format 
df_fp_2010.to_pickle('~/Desktop/df_fp_2010.pkl')
df_fp_2013.to_pickle('~/Desktop/df_fp_2013.pkl')

df_cost_2010.to_pickle('~/Desktop/df_cost_2010.pkl')
df_cost_2013.to_pickle('~/Desktop/df_cost_2013.pkl')

## Get contract IDs that have both fixed price and cost components

contract_set_intersection_2010=set(df_fp_2010.contract_award_unique_key)&set(df_cost_2010.contract_award_unique_key)
contract_set_intersection_2013=set(df_fp_2013.contract_award_unique_key)&set(df_cost_2013.contract_award_unique_key)

# Remove these contracts from the dataframes
df_fp_2010=df_fp_2010[~df_fp_2010.contract_award_unique_key.isin(contract_set_intersection_2010)]
df_cost_2010=df_cost_2010[~df_cost_2010.contract_award_unique_key.isin(contract_set_intersection_2010)]

df_fp_2013=df_fp_2013[~df_fp_2013.contract_award_unique_key.isin(contract_set_intersection_2013)]
df_cost_2013=df_cost_2013[~df_cost_2013.contract_award_unique_key.isin(contract_set_intersection_2013)]

## Restrict to psc codes that exist in all groups

psc_set_intersection=set(df_cost_2010.product_or_service_code)\
                    &set(df_fp_2010.product_or_service_code)\
                    &set(df_cost_2013.product_or_service_code)\
                    &set(df_fp_2013.product_or_service_code)


df_cost_2010=df_cost_2010.query('product_or_service_code in @psc_set_intersection')
df_fp_2010=df_fp_2010.query('product_or_service_code in @psc_set_intersection')

df_cost_2013=df_cost_2013.query('product_or_service_code in @psc_set_intersection')
df_fp_2013=df_fp_2013.query('product_or_service_code in @psc_set_intersection')

## Calculate delays
delays_cost_2010=qpc.calculate_delays(df_cost_2010) #cost contracts
delays_fp_2010=qpc.calculate_delays(df_fp_2010) #fixed price contracts

delays_cost_2013=qpc.calculate_delays(df_cost_2013) #cost contracts
delays_fp_2013=qpc.calculate_delays(df_fp_2013) #fixed price contracts

## Winsorize delays 
delays_cost_2010=qpc.winsorize_columns(delays_cost_2010,'days_of_change_in_deadline_overall',0.05) #cost contracts
delays_fp_2010=qpc.winsorize_columns(delays_fp_2010,'days_of_change_in_deadline_overall',0.05) #fixed price contracts

delays_cost_2013=qpc.winsorize_columns(delays_cost_2013,'days_of_change_in_deadline_overall',0.05) #cost contracts
delays_fp_2013=qpc.winsorize_columns(delays_fp_2013,'days_of_change_in_deadline_overall',0.05) #fixed price contracts

##find average delays corresponding to each psc code 
grouped_delays_cost_2010=delays_cost_2010.groupby('product_or_service_code')['days_of_change_in_deadline_overall_winsorized'].mean().reset_index() 
grouped_delays_fp_2010=delays_fp_2010.groupby('product_or_service_code')['days_of_change_in_deadline_overall_winsorized'].mean().reset_index() 

grouped_delays_cost_2013=delays_cost_2013.groupby('product_or_service_code')['days_of_change_in_deadline_overall_winsorized'].mean().reset_index() 
grouped_delays_fp_2013=delays_fp_2013.groupby('product_or_service_code')['days_of_change_in_deadline_overall_winsorized'].mean().reset_index() 

## Plot the data 

# import matplotlib.dates as mdates

###########
# FY 2010 #
###########
# Rotate x-axis text to 45 degrees for better visibility
plt.xticks(rotation=45)
# Adjust numticks to increase or decrease the number of ticks visible on x-axis
plt.gca().xaxis.set_major_locator(LinearLocator(numticks=25))  
## Choose x and y axes for plot
plt.plot(grouped_delays_fp_2010.product_or_service_code,grouped_delays_fp_2010.days_of_change_in_deadline_overall_winsorized, label="Fixed price contracts")
plt.plot(grouped_delays_cost_2010.product_or_service_code,grouped_delays_cost_2010.days_of_change_in_deadline_overall_winsorized, label="Cost contracts")
## Labels, Legend, and Title
plt.ylabel('Delay days \n (5% winsorized average)',fontsize='x-large')
plt.xlabel('Product or service code',fontsize='x-large')
plt.legend(loc='center left', bbox_to_anchor=(1, 0.5))
plt.ylim(0,700)
plt.title('DOD transactions FY2010')# Save figure
plt.savefig('/Users/vibhutidhingra/Desktop/graph_FY2010.png', bbox_inches = "tight")

###########
# FY 2013 #
###########

# Rotate x-axis text to 45 degrees for better visibility
plt.xticks(rotation=45)
# Adjust numticks to increase or decrease the number of ticks visible on x-axis
plt.gca().xaxis.set_major_locator(LinearLocator(numticks=25))  
## Choose x and y axes for plot
plt.plot(grouped_delays_fp_2013.product_or_service_code,grouped_delays_fp_2013.days_of_change_in_deadline_overall_winsorized, label="Fixed price contracts")
plt.plot(grouped_delays_cost_2013.product_or_service_code,grouped_delays_cost_2013.days_of_change_in_deadline_overall_winsorized, label="Cost contracts")
## Labels, Legend, and Title
plt.ylabel('Delay days \n (5% winsorized average)',fontsize='x-large')
plt.xlabel('Product or service code',fontsize='x-large')
plt.legend(loc='center left', bbox_to_anchor=(1, 0.5))
plt.ylim(0,700)
plt.title('DOD transactions FY2013')# Save figure
plt.savefig('/Users/vibhutidhingra/Desktop/graph_FY2013.png', bbox_inches = "tight")


# Plotting the average delays across psc codes

average_winsorized_delay_cost_2010=delays_cost_2010.days_of_change_in_deadline_overall_winsorized.mean()
average_winsorized_delay_fp_2010=delays_fp_2010.days_of_change_in_deadline_overall_winsorized.mean()

average_winsorized_delay_cost_2013=delays_cost_2013.days_of_change_in_deadline_overall_winsorized.mean()
average_winsorized_delay_fp_2013=delays_fp_2013.days_of_change_in_deadline_overall_winsorized.mean()

cost_contracts=pd.DataFrame([['2010', average_winsorized_delay_cost_2010],['2013',average_winsorized_delay_cost_2013]]\
                            ,columns=['fiscal_year','average_delay'])

fp_contracts=pd.DataFrame([['2010', average_winsorized_delay_fp_2010],['2013',average_winsorized_delay_fp_2013]]\
                            ,columns=['fiscal_year','average_delay'])

# Rotate x-axis text to 45 degrees for better visibility
#plt.xticks(rotation=45)
# Adjust numticks to increase or decrease the number of ticks visible on x-axis
#plt.gca().xaxis.set_major_locator(LinearLocator(numticks=25))  
## Choose x and y axes for plot
plt.plot(cost_contracts.fiscal_year,cost_contracts.average_delay, label="FY 2010")
plt.plot(fp_contracts.fiscal_year,fp_contracts.average_delay, label="FY 2013")
## Labels, Legend, and Title
plt.ylabel('Delay days \n (5% winsorized average)',fontsize='x-large')
plt.xlabel('Fiscal Year',fontsize='x-large')
plt.legend(loc='center left', bbox_to_anchor=(1, 0.5))
plt.title('Average across PSC codes')
# Save figure
plt.savefig('/Users/vibhutidhingra/Desktop/graph_both_contracts.png', bbox_inches = "tight")


###################
# FP 2010 to 2013 #
###################
# Rotate x-axis text to 45 degrees for better visibility
plt.xticks(rotation=45)
# Adjust numticks to increase or decrease the number of ticks visible on x-axis
plt.gca().xaxis.set_major_locator(LinearLocator(numticks=25))  
## Choose x and y axes for plot
plt.plot(grouped_delays_fp_2010.product_or_service_code\
         ,grouped_delays_fp_2010.days_of_change_in_deadline_overall_winsorized, label="2010")
plt.plot(grouped_delays_fp_2013.product_or_service_code\
         ,grouped_delays_fp_2013.days_of_change_in_deadline_overall_winsorized, label="2013")
## Labels, Legend, and Title
plt.ylabel('Delay days \n (5% winsorized average)',fontsize='x-large')
plt.xlabel('Product or service code',fontsize='x-large')
plt.legend(loc='center left', bbox_to_anchor=(1, 0.5))
plt.ylim(0,700)
plt.title('Fixed price contracts')# Save figure
plt.savefig('/Users/vibhutidhingra/Desktop/fp_2010_to_2013.png', bbox_inches = "tight")


###################
# Cost 2010 to 2013 #
###################
# Rotate x-axis text to 45 degrees for better visibility
plt.xticks(rotation=45)
# Adjust numticks to increase or decrease the number of ticks visible on x-axis
plt.gca().xaxis.set_major_locator(LinearLocator(numticks=25))  
## Choose x and y axes for plot
plt.plot(grouped_delays_cost_2010.product_or_service_code\
         ,grouped_delays_cost_2010.days_of_change_in_deadline_overall_winsorized, label="2010")
plt.plot(grouped_delays_cost_2013.product_or_service_code\
         ,grouped_delays_cost_2013.days_of_change_in_deadline_overall_winsorized, label="2013")
## Labels, Legend, and Title
plt.ylabel('Delay days \n (5% winsorized average)',fontsize='x-large')
plt.xlabel('Product or service code',fontsize='x-large')
plt.legend(loc='center left', bbox_to_anchor=(1, 0.5))
plt.ylim(0,700)
plt.title('Cost contracts')# Save figure
plt.savefig('/Users/vibhutidhingra/Desktop/cost_2010_to_2013.png', bbox_inches = "tight")








