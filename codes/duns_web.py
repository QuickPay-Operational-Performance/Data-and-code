#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed May 27 17:13:22 2020

@author: vibhutidhingra
"""

import requests
import pandas as pd
import requests
import numpy as np
import urllib
import glob, os

path_to_folder='Folder path where we have the 90 CSVs'

all_files = glob.glob(os.path.join(path_to_folder, "*.csv"))  

list_of_dfs=[]

for f in all_files:
        url = 'URL where files have to be uploaded'
        files = {'file': open('f', 'rb')}
        # read one file at a time from the folder
        r = requests.post(url, files=files)
        # upload file on the url
        df=r.content 
        # this part is tricky -- need to check what the output is like 
        # and save the csv into a dataframe -- here I assume that r.content will give a csv
        list_of_dfs.append(df)
        # get response

total_output_df = pd.concat(list_of_dataframes)
# merge all outputs into one dataframe
total_output_df.to_csv('file_path.csv',index=False)
# save that dataframe to a csv file 