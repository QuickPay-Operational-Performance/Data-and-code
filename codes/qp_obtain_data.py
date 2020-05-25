#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Apr 28 12:57:41 2020

@author: vibhutidhingra
"""


import pandas as pd
#import numpy as np
import quickpay_datacleaning as qpc
#import matplotlib.pyplot as plt
import glob, os

pd.set_option('display.expand_frame_repr', False)

#####################################
# Obtain the raw data for analysis  #
#####################################

## naics filter:
# - top 20 four-digit naics in Barrot/Nanda paper (Table A.6)
# - firm fixed price
# - defense contracts only
# - not bundled contract
# - not small disadvantaged business

### FY2010 to FY2012 ### 
### Oct 1, 2009 to Sept 30, 2012 ### 

path_fy2010='/Users/vibhutidhingra/Dropbox/data_quickpay/FY2010_097_Contracts_Full_20200205'
# FY 2010 === 2009-10-01 to 2010-09-30
df_fy2010=qpc.naics_filter_multiple_csvs(path_fy2010)

path_fy2011='/Users/vibhutidhingra/Dropbox/data_quickpay/FY2011_097_Contracts_Full_20200205'
df_fy2011=qpc.naics_filter_multiple_csvs(path_fy2011)

path_fy2012='/Users/vibhutidhingra/Dropbox/data_quickpay/FY2012_097_Contracts_Full_20200205'
df_fy2012=qpc.naics_filter_multiple_csvs(path_fy2012)

qp_data_fy10_to_fy12=pd.concat([df_fy2010,df_fy2011,df_fy2012])

qp_data_fy10_to_fy12.to_csv('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data_fy10_to_fy12.csv',index=False)

### FY2013 to FY2015 ### 
### Oct 1, 2012 to Sept 30, 2015 ### 

folder_path='/Users/vibhutidhingra/Dropbox/award_data_archive_20200205'
path_fy2013=folder_path+'/FY2013_All_Contracts_Full_20200205'
df_fy2013=qpc.naics_filter_multiple_csvs(path_fy2013)

path_fy2014=folder_path+'/FY2014_All_Contracts_Full_20200205'
df_fy2014=qpc.naics_filter_multiple_csvs(path_fy2014)

path_fy2015=folder_path+'/FY2015_All_Contracts_Full_20200205'
df_fy2015=qpc.naics_filter_multiple_csvs(path_fy2015)

qp_data_fy13_to_fy15=pd.concat([df_fy2013,df_fy2014,df_fy2015])

qp_data_fy13_to_fy15.to_csv('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data_fy13_to_fy15.csv',index=False)

### FY2016 to FY2018 ### 
### Oct 1, 2015 to Sept 30, 2018 ### 

folder_path='/Users/vibhutidhingra/Dropbox/award_data_archive_20200205'
path_fy2016=folder_path+'/FY2016_All_Contracts_Full_20200205'
df_fy2016=qpc.naics_filter_multiple_csvs(path_fy2016)

path_fy2017=folder_path+'/FY2017_All_Contracts_Full_20200205'
df_fy2017=qpc.naics_filter_multiple_csvs(path_fy2017)

path_fy2018=folder_path+'/FY2018_All_Contracts_Full_20200205'
df_fy2018=qpc.naics_filter_multiple_csvs(path_fy2018)

qp_data_fy16_to_fy18=pd.concat([df_fy2016,df_fy2017,df_fy2018])

qp_data_fy16_to_fy18.to_csv('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data_fy16_to_fy18.csv',index=False)

############################################
# Save all data into one file (no resample)
############################################

path_to_folder='/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data'
all_files = glob.glob(os.path.join(path_to_folder, "*.csv"))  
# create a list of path for each file in the folder
df_from_each_file = (pd.read_csv(f) for f in all_files)
# query each file in the folder and save as generator
df = pd.concat(df_from_each_file, ignore_index=True)
# merge into one dataset
df.to_csv('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_fy10_to_fy18.csv',index=False)
