#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jun  7 04:13:22 2019

@author: vibhutidhingra
"""

import data_cleaning_usaspending as dcu
import pandas as pd
import requests
import urllib
from io import BytesIO
from zipfile import ZipFile
import time
    
df=dcu.read_multiple_csvs('/Users/vibhutidhingra/Dropbox/data/raw_subwards_from_custom_award_data')

df = df[~((df.prime_award_date_signed < '2011-03-01') | (df.prime_award_amount<25000))]
#Remove contracts that were signed before this date or lower than this amount
#Because subcontracts data is required for primes > 25,000$ signed after this date

unique_prime_ids=dcu.list_unique_prime_ids(df)
   
all_transactions_for_unique_prime_ids=pd.DataFrame()
all_subawards_for_unique_prime_ids=pd.DataFrame()

user='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.75.14 (KHTML, like Gecko) Version/7.0.3 Safari/7046A194A'

params_transaction = {
    "filters": {
        "award_ids": unique_prime_ids,
    },
    "columns": []
}
url = "https://api.usaspending.gov/api/v2/download/transactions/"
r = requests.post(url, json=params_transaction)
print(r.status_code, r.reason) 
data=r.json()
# sometimes the file takes time to be ready in backend
# Maybe wait a few minutes for file to be ready and then run the code below this comment
try:
    req = urllib.request.Request(data['url'], headers={'User-Agent' : user,})
    resp = urllib.request.urlopen(req)
except urllib.error.HTTPError as e:
    time.sleep(30) #Wait 30 seconds to read data, then try again
    req = urllib.request.Request(data['url'], headers={'User-Agent' : user,})
    resp = urllib.request.urlopen(req) 
    print(e.fp.read())
zf = ZipFile(BytesIO(resp.read()))
all_transactions_for_unique_prime_ids = pd.read_csv(zf.open('all_contracts_prime_transactions_1.csv'))
all_subawards_for_unique_prime_ids=pd.read_csv(zf.open('all_contracts_subawards_1.csv'))

##################
# convert_to_csv #
##################
all_transactions_for_unique_prime_ids.to_csv("/Users/vibhutidhingra/Dropbox/data/data_for_unique_primes_using_raw_subawards/all_transactions_for_unique_prime_ids.csv",index=False)
all_subawards_for_unique_prime_ids.to_csv("/Users/vibhutidhingra/Dropbox/data/data_for_unique_primes_using_raw_subawards/all_subawards_for_unique_prime_ids.csv",index=False)