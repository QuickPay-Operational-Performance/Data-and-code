#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Mar 21 17:16:01 2021

@author: vibhutidhingra
"""

import pandas as pd
from scipy.stats import mstats

file_path='/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_fy10_to_fy18.csv'

columns_needed=['contract_award_unique_key',\
                'action_date_fiscal_year',\
                'action_date',\
                'period_of_performance_current_end_date',\
                'base_and_all_options_value']

df_raw=pd.read_csv(file_path,usecols=columns_needed)

#df_first=df_raw[pd.to_datetime(df_raw.action_date)<=pd.to_datetime('2012-09-30')]

#%%

def convert_to_date_time(df): # input dataframe
    df = df.copy(deep=True)#copy so that the input dataframe is not altered
    date_cols=df.columns[df.columns.str.endswith('_date')].tolist() #get columns that have dates
    if date_cols: #If the list is non-empty, execute the following code
        df[date_cols]=df[date_cols].apply(pd.to_datetime, errors='coerce')
        #pandas requires dates to be in some range, coercing errors will set weird dates like year 2919 to NaT
        #Run pd.Timestamp.max and pd.Timestamp.min to see range allowed
    return df

def calculate_delays(df):#,path_to_dictionary_csv):
    df=df.copy(deep=True)#copy so that the input dataframe is not altered
    ###########################
    # Clean transactions file #
    ###########################
    df=df.drop_duplicates()
    df=convert_to_date_time(df)
    ##############
    # Get Delays #
    ##############
    df_subset_earliest=df.sort_values(by='action_date').drop_duplicates(subset='contract_award_unique_key')
    # get columns corresponding to earliest action date for each contract
    df_subset_earliest=df_subset_earliest.rename(columns={'period_of_performance_current_end_date':'earliest_end_date'})
    # rename completion date column to denote the initial end date of the project
    df_subset_earliest=df_subset_earliest[['contract_award_unique_key','earliest_end_date']]

    df_subset_latest=df.sort_values(by='action_date',ascending=False).drop_duplicates(subset='contract_award_unique_key')
    # get columns corresponding to latest action date for each contract
    df_subset_latest=df_subset_latest.rename(columns={'period_of_performance_current_end_date':'latest_end_date'})
    # rename completion date column to denote the eventual end date of the project
    df_subset_latest=df_subset_latest[['contract_award_unique_key','latest_end_date']]

    delays_df=pd.merge(df_subset_latest,df_subset_earliest,on='contract_award_unique_key')
    delays_df["days_of_delay_overall"]=(delays_df.latest_end_date-delays_df.earliest_end_date).dt.days
    delays_df["days_of_delay_winsorized"]=mstats.winsorize(delays_df.days_of_delay_overall,\
                                             limits=[0.05, 0.05])

    return delays_df

delays_df=calculate_delays(df_raw)

percentage_of_projects_delayed=len(delays_df[delays_df.days_of_delay_overall>0])*100/len(delays_df)
mean_delay_of_those_delayed=delays_df[delays_df.days_of_delay_overall>0].days_of_delay_overall.mean()

print("\n percentage_of_projects_delayed=",percentage_of_projects_delayed)

print("\n mean_delay_of_those_delayed=",mean_delay_of_those_delayed)

#%%

def calculate_budget(df):#,path_to_dictionary_csv):
    df=df.copy(deep=True)#copy so that the input dataframe is not altered
    ###########################
    # Clean transactions file #
    ###########################
    df=df.drop_duplicates()
    df=convert_to_date_time(df)
    ##############
    # Get Delays #
    ##############
    df_subset_earliest=df.sort_values(by='action_date').drop_duplicates(subset='contract_award_unique_key')
    # get columns corresponding to earliest action date for each contract
    df_subset_earliest=df_subset_earliest.rename(columns={'base_and_all_options_value':'earliest_budget'})
    # rename completion date column to denote the initial end date of the project
    df_subset_earliest=df_subset_earliest[['contract_award_unique_key','earliest_budget']]

    df_subset_latest=df.sort_values(by='action_date',ascending=False).drop_duplicates(subset='contract_award_unique_key')
    # get columns corresponding to latest action date for each contract
    df_subset_latest=df_subset_latest.rename(columns={'base_and_all_options_value':'latest_budget'})
    # rename completion date column to denote the eventual end date of the project
    df_subset_latest=df_subset_latest[['contract_award_unique_key','latest_budget']]

    budget_df=pd.merge(df_subset_latest,df_subset_earliest,on='contract_award_unique_key')
    budget_df["change_in_budget_overall"]=(budget_df.latest_budget-budget_df.earliest_budget)
    budget_df["winsorized_budget_overall"]=mstats.winsorize(budget_df.change_in_budget_overall,\
                                             limits=[0.05, 0.05])
    
    return budget_df

budget_df=calculate_budget(df_raw)

percentage_of_projects_over_budget=len(budget_df[budget_df.winsorized_budget_overall>0])*100/len(budget_df)
mean_change_of_those_overbudget=budget_df[budget_df.winsorized_budget_overall>0].winsorized_budget_overall.mean()

