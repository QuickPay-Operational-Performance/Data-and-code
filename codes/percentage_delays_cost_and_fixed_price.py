#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Feb 29 18:31:44 2020

@author: vibhutidhingra
"""

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
                    columns=['psc_code','fiscal_year','fixed_price_delays_percentage','cost_delays_percentage'])

index=0
for item in psc_list:
     for df in [df_2008,df_2009,df_2010,df_2011]:
            print(index, item)
            df=qpc.assign_broad_pricing_code(df)
            df_sub=df.query('product_or_service_code.str[0]+product_or_service_code.str[1]== @item',engine='python')
            delay_df=qpc.calculate_percentage_delays(df_sub)
            delay_df=delay_df[delay_df.initial_completion_time_in_days!=0].reset_index(drop=True)
            df_sub=df[cols].drop_duplicates()
            df_sub=df_sub.merge(delay_df,on='contract_award_unique_key')
            df_sub=qpc.winsorize_columns(df_sub,'percentage_delays',0.05)
            plot_df["psc_code"].iloc[index]=item
            plot_df["fiscal_year"].iloc[index]=df_sub.action_date_fiscal_year.iloc[0]
            plot_df["fixed_price_delays_percentage"].iloc[index]=df_sub[df_sub.price_structure=='FIXED PRICE'].percentage_delays_winsorized.mean()
            plot_df["cost_delays_percentage"].iloc[index]=df_sub[df_sub.price_structure=='COST PRICE'].percentage_delays_winsorized.mean()
            index=index+1

plot_df.fiscal_year=plot_df.fiscal_year.astype(str)

for item in set(plot_df.psc_code):
    fig = plt.figure()
    sub_plot_df=plot_df[plot_df.psc_code==item]
    plt.plot(sub_plot_df.fiscal_year,sub_plot_df.fixed_price_delays_percentage,label="fixed_price")
    plt.plot(sub_plot_df.fiscal_year,sub_plot_df.cost_delays_percentage,label="cost_price")
    plt.legend(loc="upper left")
    fig.suptitle('PSC code: '+item, fontsize=18)
    plt.xlabel('Fiscal Year', fontsize=18)
    plt.ylabel('Percentage change \n in completion time\n (winsorized)', fontsize=16)
    plt.savefig('/Users/vibhutidhingra/Desktop/percent_delays/percentage_delays_psc_code_'+item+'.png', bbox_inches = "tight")
    
## distribution of pricing by product service codes ##
all_df=pd.concat([df_2008,df_2009,df_2010,df_2011])
all_df=qpc.assign_broad_pricing_code(all_df)
all_df=all_df[all_df.price_structure.fillna('').str.contains('FIXED PRICE|COST PRICE')]

cp=all_df[all_df.price_structure=='COST PRICE'].reset_index(drop=True)
plot_cp=cp.groupby('product_or_service_code')['contract_award_unique_key'].nunique().reset_index(drop=True)

fp=all_df[all_df.price_structure=='FIXED PRICE'].reset_index(drop=True)
plot_fp=fp.groupby('product_or_service_code')['contract_award_unique_key'].nunique().reset_index()

fig = plt.figure()
plt.xticks(rotation=90)
plt.gca().xaxis.set_major_locator(LinearLocator(numticks=25))  
plt.plot(plot_fp.product_or_service_code,plot_fp.contract_award_unique_key,label="fixed price contracts")
plt.plot(plot_cp.product_or_service_code,plot_cp.contract_award_unique_key,label="cost contracts")
plt.legend(bbox_to_anchor=(1.04,1), loc="upper left")
plt.xlabel('PSC code', fontsize=18)
plt.ylabel('Number of contracts', fontsize=16)
plt.savefig('/Users/vibhutidhingra/Desktop/percent_delays/num_contracts.png', bbox_inches = "tight")
