#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Feb 22 03:10:46 2020

@author: vibhutidhingra
"""

import pandas as pd 
import matplotlib.pyplot as plt

sample_did=pd.read_csv('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_sample_did.csv')
sb=sample_did[sample_did.small_business==1]
lb=sample_did[sample_did.small_business==0]

### Distribution of contracts based on PSC codes #####
sb1=sb.groupby('product_or_service_code')['contract_award_unique_key'].nunique().reset_index()
lb1=lb.groupby('product_or_service_code')['contract_award_unique_key'].nunique().reset_index()
## Plot only those PSC codes that are given to both large and small businesses
psc_in_both=set(lb.product_or_service_code)&set(sb.product_or_service_code)
sb1=sb1[sb1.product_or_service_code.isin(psc_in_both)]
lb1=lb1[lb1.product_or_service_code.isin(psc_in_both)]
fig = plt.figure()
plt.xticks(rotation=90)
plt.gca().xaxis.set_major_locator(LinearLocator(numticks=25))  
plt.plot(sb1.product_or_service_code,sb1.contract_award_unique_key,label="small_business")
plt.plot(lb1.product_or_service_code,lb1.contract_award_unique_key,label="large_business")
plt.legend(bbox_to_anchor=(1.04,1), loc="upper left")
plt.ylabel('Number of contracts', fontsize=16)
plt.xlabel('product_or_service_code', fontsize=16)
plt.savefig('/Users/vibhutidhingra/Dropbox/data_quickpay/did_sample_dist_psc.png', bbox_inches = "tight")

### Distribution of contracts based on Naics codes #####
sb1=sb.groupby('naics_code')['contract_award_unique_key'].nunique().reset_index()
lb1=lb.groupby('naics_code')['contract_award_unique_key'].nunique().reset_index()
## Plot only those naics code that are given to both large and small businesses
naics_in_both=set(lb.naics_code)&set(sb.naics_code)
sb1=sb1[sb1.naics_code.isin(naics_in_both)]
lb1=lb1[lb1.naics_code.isin(naics_in_both)]
fig = plt.figure()
plt.xticks(rotation=90)
plt.gca().xaxis.set_major_locator(LinearLocator(numticks=25))  
plt.plot(sb1.naics_code.astype(str),sb1.contract_award_unique_key,label="small_business")
plt.plot(lb1.naics_code.astype(str),lb1.contract_award_unique_key,label="large_business")
plt.legend(bbox_to_anchor=(1.04,1), loc="upper left")
plt.ylabel('Number of contracts', fontsize=16)
plt.xlabel('naics_code', fontsize=16)
plt.savefig('/Users/vibhutidhingra/Dropbox/data_quickpay/did_sample_dist_naics.png', bbox_inches = "tight")

### Distribution of contracts awarded before and after quickpay #####
sb1=sb.groupby('after_quickpay')['contract_award_unique_key'].nunique().reset_index()
lb1=lb.groupby('after_quickpay')['contract_award_unique_key'].nunique().reset_index()
fig = plt.figure()
plt.xticks(rotation=90)
plt.plot(sb1.after_quickpay.astype(str),sb1.contract_award_unique_key,label="small_business")
plt.plot(lb1.after_quickpay.astype(str),lb1.contract_award_unique_key,label="large_business")
plt.legend(bbox_to_anchor=(1.04,1), loc="upper left")
plt.ylabel('Number of contracts', fontsize=16)
plt.xlabel('after_quickpay', fontsize=16)
plt.savefig('/Users/vibhutidhingra/Dropbox/data_quickpay/did_sample_dist_before_after_qp.png', bbox_inches = "tight")

### Distribution of federal action obligation in a given year-month ####

qp_data=pd.read_pickle('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data.pkl')
qp_data["action_date_ym"]=qp_data.action_date.apply(lambda x: x.year*100+x.month)

sb_data=qp_data[qp_data.small_business==1]
lb_data=qp_data[qp_data.small_business==0]

sb_data_obligation=sb_data.groupby(['action_date_ym'])['federal_action_obligation'].nunique().reset_index()
lb_data_obligation=lb_data.groupby(['action_date_ym'])['federal_action_obligation'].nunique().reset_index()

fig = plt.figure()
plt.xticks(rotation=90)
plt.gca().xaxis.set_major_locator(LinearLocator(numticks=20))  
plt.plot(sb_data_obligation.action_date_ym.astype(str),sb_data_obligation.federal_action_obligation,label="small_business")
plt.plot(lb_data_obligation.action_date_ym.astype(str),lb_data_obligation.federal_action_obligation,label="large_business")
plt.legend(bbox_to_anchor=(1.04,1), loc="upper left")
plt.ylabel('Number of unique\nfederal action obligations', fontsize=16)
plt.xlabel('action_date_year_month', fontsize=16)
plt.savefig('/Users/vibhutidhingra/Dropbox/data_quickpay/did_sample_dist_federal_obligation.png', bbox_inches = "tight")
