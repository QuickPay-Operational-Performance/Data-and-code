#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Feb 17 11:19:20 2020

@author: vibhutidhingra
"""
import pandas as pd
import numpy as np
import quickpay_datacleaning as qpc
import matplotlib.pyplot as plt
import itertools
import seaborn as sns

# restrict to construction contracts based on June 2019 PSC manual
# not a bundled contract
# defense contracts 
# small businesses that are not disadvantaged 

psc_list=['B5','C1','C2','F0','F1','F9','H1','H2','H3','H9','J0','J9','K0','N0','Y1','Z1','Z2']
query_infrastructure_quickpay= "product_or_service_code.str[0]+product_or_service_code.str[1]\
 ==['B5','C1','C2','F0','F1','F9','H1','H2','H3','H9','J0','J9','K0','N0','Y1','Z1','Z2']  &\
 (contract_bundling_code.fillna('') == ['H','D'] | contract_bundling_code.isnull())&\
 contracting_officers_determination_of_business_size_code=='S'&\
 small_disadvantaged_business=='f' "

path_2008='/Users/vibhutidhingra/Downloads/FY2008_097_Contracts_Full_20200205'
df_2008=qpc.query_multiple_csvs(path_2008,query_infrastructure_quickpay)

path_2009='/Users/vibhutidhingra/Downloads/FY2009_097_Contracts_Full_20200205'
df_2009=qpc.query_multiple_csvs(path_2009,query_infrastructure_quickpay)

path_2010='/Users/vibhutidhingra/Downloads/FY2010_097_Contracts_Full_20200205'
df_2010=qpc.query_multiple_csvs(path_2010,query_infrastructure_quickpay)

path_2011='/Users/vibhutidhingra/Downloads/FY2011_097_Contracts_Full_20200205'
df_2011=qpc.query_multiple_csvs(path_2011,query_infrastructure_quickpay)

cols=['contract_award_unique_key','price_structure','action_date_fiscal_year']
fiscal_years=['2008','2009','2010','2011']
product=list(itertools.product(psc_list,fiscal_years))

plot_df=pd.DataFrame(np.nan, index=np.arange(0,int(size(product)/2)),\
                    columns=['psc_code','fiscal_year','fixed_price_delays','cost_delays'])

index=0
for item in psc_list:
     for df in [df_2008,df_2009,df_2010,df_2011]:
            print(index, item)
            df=qpc.assign_broad_pricing_code(df)
            df_sub=df.query('product_or_service_code.str[0]+product_or_service_code.str[1]== @item',engine='python')
            delay_df=qpc.calculate_delays(df_sub)
            df_sub=df[cols].drop_duplicates()
            df_sub=df_sub.merge(delay_df,on='contract_award_unique_key')
            df_sub=qpc.winsorize_columns(df_sub,'days_of_change_in_deadline_overall',0.05)
            plot_df["psc_code"].iloc[index]=item
            plot_df["fiscal_year"].iloc[index]=df_sub.action_date_fiscal_year.iloc[0]
            plot_df["fixed_price_delays"].iloc[index]=df_sub[df_sub.price_structure=='FIXED PRICE'].days_of_change_in_deadline_overall_winsorized.mean()
            plot_df["cost_delays"].iloc[index]=df_sub[df_sub.price_structure=='COST PRICE'].days_of_change_in_deadline_overall_winsorized.mean()
            index=index+1

plot_df.fiscal_year=plot_df.fiscal_year.astype(str)

for item in set(plot_df.psc_code):
    fig = plt.figure()
    sub_plot_df=plot_df[plot_df.psc_code==item]
    plt.plot(sub_plot_df.fiscal_year,sub_plot_df.fixed_price_delays,label="fixed_price")
    plt.plot(sub_plot_df.fiscal_year,sub_plot_df.cost_delays,label="cost_price")
    plt.legend(loc="upper left")
    fig.suptitle('PSC code: '+item, fontsize=18)
    plt.xlabel('Fiscal Year', fontsize=18)
    plt.ylabel('Days of delay (winsorized)', fontsize=16)
    plt.savefig('/Users/vibhutidhingra/Desktop/psc_code_'+item+'.png', bbox_inches = "tight")
    
######### Box Plots ##########
 
fig_fp_fy = plt.figure()
sns.boxplot(x = "fiscal_year", y = "fixed_price_delays", data = plot_df)
plt.xlabel('Fiscal Year', fontsize=16)
plt.ylabel('Delay days (winsorized)', fontsize=16)
fig_fp_fy.suptitle('Fixed Price contracts', fontsize=16)
plt.savefig('/Users/vibhutidhingra/Desktop/fiscal_year_fp_boxplot.png', bbox_inches = "tight")

fig_cost_fy = plt.figure()
sns.boxplot(x = "fiscal_year", y = "cost_delays", data = plot_df)
plt.xlabel('Fiscal Year', fontsize=16)
plt.ylabel('Delay days (winsorized)', fontsize=16)
fig_cost_fy.suptitle('Cost contracts', fontsize=16)
plt.savefig('/Users/vibhutidhingra/Desktop/fiscal_year_cost_boxplot.png', bbox_inches = "tight")

fig_fp_psc = plt.figure()
sns.boxplot(x = "psc_code", y = "fixed_price_delays", data = plot_df)
plt.xlabel('Product and Service Code', fontsize=16)
plt.ylabel('Delay days (winsorized)', fontsize=16)
fig_fp_psc.suptitle('Fixed Price contracts', fontsize=16)
plt.savefig('/Users/vibhutidhingra/Desktop/psc_code_fp_boxplot.png', bbox_inches = "tight")

fig_cost_psc = plt.figure()
sns.boxplot(x = "psc_code", y = "cost_delays", data = plot_df)
plt.xlabel('Product and Service Code', fontsize=16)
plt.ylabel('Delay days (winsorized)', fontsize=16)
fig_cost_psc.suptitle('Cost contracts', fontsize=16)
plt.savefig('/Users/vibhutidhingra/Desktop/psc_code_cost_boxplot.png', bbox_inches = "tight")






