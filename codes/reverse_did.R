rm(list = ls())
library(tidyverse)
library(zoo) # for year-quarter
#library(dplyr)
library(data.table) # much faster than dplyr & syntax similar to python 
library(dtplyr)
library(lfe) # linear fixed effects 
library(DescTools) 
library(MatchIt)
library(stargazer)
library(broom)

#### Read data #####

df=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/resampled_qp_data/qp_resampled_data_fy10_to_fy18.csv')
#,stringsAsFactors=FALSE)

df[,action_date_year_quarter:=as.Date(action_date_year_quarter)][,
    winsorized_delay:=Winsorize(change_in_deadline,na.rm=TRUE)][,
    business_type:=relevel(as.factor(business_type),ref="S")]

df[,before_aug_2014:=ifelse(action_date_year_quarter<=as.Date("2014-08-01"),1,0)][,
    after_aug_2014:=ifelse(action_date_year_quarter>as.Date("2014-08-01"),1,0)]
# Payment accelerated to Large Businesses on Aug 1, 2014

old_contracts=unique(subset(df,action_date_year_quarter<=as.Date("2013-03-31"))$contract_award_unique_key)
# we want to exclude contracts that were active in or before the quarter including Feb 21, 2013 
# use march 31, 2013 as threshold because thats when the corresponding quarter ends 


#### Select range ####
# Focus on time period 6 quarters before and 6 quarters after QP
# was implemented for Large businesses

# Longest interval we should consider is +/- 6 quarters
# Treatment implemented 6 quarters after Mar 31, 2013
upper_date=as.Date("2016-03-31")
lower_date=as.Date("2013-03-31")

# 6 quarters
df1=subset(df,!contract_award_unique_key%in%old_contracts &
             action_date_year_quarter<=upper_date&
             action_date_year_quarter>=lower_date)
range="Mar 2013 - Mar 2016"

# # 5 quarters
# df1=subset(df,!contract_award_unique_key%in%old_contracts &
#              action_date_year_quarter<=as.Date("2015-12-31")&
#              action_date_year_quarter>=as.Date("2013-06-30"))
# range="Jun 2013 - Dec 2015"

# # 4 quarters
# df1=subset(df,!contract_award_unique_key%in%old_contracts &
#              action_date_year_quarter<=as.Date("2015-09-30")&
#              action_date_year_quarter>=as.Date("2013-09-30"))
# range="Sep 2013 - Sep 2015"

# # 3 quarters
# df1=subset(df,!contract_award_unique_key%in%old_contracts &
#              action_date_year_quarter<=as.Date("2015-06-30")&
#              action_date_year_quarter>=as.Date("2013-12-31"))
# range="Dec 2013 - Jun 2015"

#### Base Regressions #####

# Y = a + LargeBusiness + Before2014 + LargeBusiness x Before2014 + e

no_fe=felm(winsorized_delay ~ before_aug_2014*business_type |
               0|0|0,     
             data = df1)

recipient_fe=felm(winsorized_delay ~ before_aug_2014*business_type |
                                 recipient_duns|0|0,     
                               data = df1)

task_and_recipient_fe=felm(winsorized_delay ~before_aug_2014*business_type |
                                 recipient_duns+product_or_service_code|0|0,     
                               data = df1)

stargazer(no_fe,recipient_fe,task_and_recipient_fe,
          title = paste("Days of Delay (Winsorized):",range,sep=" "),
          dep.var.labels.include = TRUE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("Firm FE","No","Yes","Yes"),
                           c("Task FE","No","No","Yes"),
                           c("Controls","No","No","No")), 
          style="qje",
          notes=" (i) Each observation is a project-quarter",
          type="html",
          header=F)

#### Performance-based Regressions #####

# read only pb columns

df_raw=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_fy10_to_fy18.csv',
             select = c("contract_award_unique_key",
                        "performance_based_service_acquisition_code",
                        "performance_based_service_acquisition"))

pba_dict=unique(df_raw, by = "contract_award_unique_key")

pba_df=merge(df1,pba_dict,by= "contract_award_unique_key")
# read only pb columns

no_fe=felm(winsorized_delay ~ before_aug_2014*business_type |
             0|0|0,     
           data = subset(pba_df,performance_based_service_acquisition_code=='Y'))

recipient_fe=felm(winsorized_delay ~ before_aug_2014*business_type |
                    recipient_duns|0|0,     
                  data = subset(pba_df,performance_based_service_acquisition_code=='Y'))

task_and_recipient_fe=felm(winsorized_delay ~before_aug_2014*business_type |
                             recipient_duns+product_or_service_code|0|0,     
                           data = subset(pba_df,performance_based_service_acquisition_code=='Y'))

stargazer(no_fe,recipient_fe,task_and_recipient_fe,
          title = paste("Days of Delay (Winsorized):",range,sep=" "),
          dep.var.labels.include = TRUE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("Firm FE","No","Yes","Yes"),
                           c("Task FE","No","No","Yes"),
                           c("Controls","No","No","No")), 
          style="qje",
          notes=" (i) Each observation is a project-quarter",
          type="html",
          header=F)

#### Only firms with one type of contract ####

# get list of firms with both Small & Large contracts 
firms_with_multiple_types=unique(df1[,uniqueN(business_type),by=recipient_duns][V1==2,]$recipient_duns)

df2=subset(df1,!recipient_duns%in%firms_with_multiple_types)
# remove them from the sample

# Y = a + LargeBusiness + Before2014 + LargeBusiness x Before2014 + e

no_fe=felm(winsorized_delay ~ before_aug_2014*business_type |
             0|0|0,     
           data = df2)

# This does not work any more because each firm corresponds to one business type -- so collinearity
# recipient_fe=felm(winsorized_delay ~ before_aug_2014*business_type |
#                     recipient_duns|0|0,     
#                   data = df2)

task_fe=felm(winsorized_delay ~before_aug_2014*business_type |
                             product_or_service_code|0|0,     
                           data = df2)

task_and_industry_fe=felm(winsorized_delay ~before_aug_2014*business_type |
               naics_code+product_or_service_code|0|0,     
             data = df2)

stargazer(no_fe,task_fe,task_and_industry_fe,
          title = paste("Days of Delay (Winsorized):",range,sep=" "),
          dep.var.labels.include = TRUE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("PSC code FE","No","Yes","Yes"),
                           c("Industry FE","No","No","Yes"),
                           c("Controls","No","No","No")), 
          style="qje",
          notes.align = "l",
          notes=" (i) Each observation is a project-quarter, (ii) Sample restricted to firms that receive only one type of contract (small or large, but not both)",
          type="html",
          header=F)

#### Firms with one type of contract: Performance-based Regressions #####

# read only pb columns

df_raw=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_fy10_to_fy18.csv',
             select = c("contract_award_unique_key",
                        "performance_based_service_acquisition_code",
                        "performance_based_service_acquisition"))

pba_dict=unique(df_raw, by = "contract_award_unique_key")

pba_df2=merge(df2,pba_dict,by= "contract_award_unique_key")
# read only pb columns

no_fe=felm(winsorized_delay ~ before_aug_2014*business_type |
             0|0|0,     
           data = subset(pba_df2,performance_based_service_acquisition_code=='Y'))

recipient_fe=felm(winsorized_delay ~ before_aug_2014*business_type |
                    product_or_service_code|0|0,     
                  data = subset(pba_df2,performance_based_service_acquisition_code=='Y'))

task_and_recipient_fe=felm(winsorized_delay ~before_aug_2014*business_type |
                             naics_code+product_or_service_code|0|0,     
                           data = subset(pba_df2,performance_based_service_acquisition_code=='Y'))

stargazer(no_fe,task_fe,task_and_industry_fe,
          title = paste("Days of Delay (Winsorized):",range,sep=" "),
          dep.var.labels.include = TRUE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("PSC code FE","No","Yes","Yes"),
                           c("Industry FE","No","No","Yes"),
                           c("Controls","No","No","No")), 
          style="qje",
          notes.align = "l",
          notes=" (i) Each observation is a project-quarter, (ii) Sample restricted to firms that receive only one type of contract (small or large, but not both), (iii) Performance based contracts only",
          type="html",
          header=F)














