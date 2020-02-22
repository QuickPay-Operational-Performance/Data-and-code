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
