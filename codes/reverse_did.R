rm(list = ls())

#### Load Packages ####
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

# subset of performance based contracts
no_fe_pba=felm(winsorized_delay ~ before_aug_2014*business_type |
             0|0|0,     
           data = subset(pba_df2,performance_based_service_acquisition_code=='Y'))

task_fe_pba=felm(winsorized_delay ~ before_aug_2014*business_type |
                    product_or_service_code|0|0,     
                  data = subset(pba_df2,performance_based_service_acquisition_code=='Y'))

task_and_industry_fe_pba=felm(winsorized_delay ~before_aug_2014*business_type |
                             naics_code+product_or_service_code|0|0,     
                           data = subset(pba_df2,performance_based_service_acquisition_code=='Y'))

stargazer(no_fe_pba,task_fe_pba,task_and_industry_fe_pba,
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

# subset of NON-performance based contracts

no_fe_non_pba=felm(winsorized_delay ~ before_aug_2014*business_type |
                 0|0|0,     
               data = subset(pba_df2,performance_based_service_acquisition_code=='N'))

task_fe_non_pba=felm(winsorized_delay ~ before_aug_2014*business_type |
                   product_or_service_code|0|0,     
                 data = subset(pba_df2,performance_based_service_acquisition_code=='N'))

task_and_industry_fe_non_pba=felm(winsorized_delay ~before_aug_2014*business_type |
                                naics_code+product_or_service_code|0|0,     
                              data = subset(pba_df2,performance_based_service_acquisition_code=='N'))

stargazer(no_fe_non_pba,task_fe_non_pba,task_and_industry_fe_non_pba,
          title = paste("Days of Delay (Winsorized):",range,sep=" "),
          dep.var.labels.include = TRUE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("PSC code FE","No","Yes","Yes"),
                           c("Industry FE","No","No","Yes"),
                           c("Controls","No","No","No")), 
          style="qje",
          notes.align = "l",
          notes=" (i) Each observation is a project-quarter, (ii) Sample restricted to firms that receive only one type of contract (small or large, but not both), (iii) Only contracts for which performance-based was not used",
          type="html",
          header=F)


# subset of contracts for which performance based contracts not applicable

no_fe_pba_not_applicable=felm(winsorized_delay ~ before_aug_2014*business_type |
                     0|0|0,     
                   data = subset(pba_df2,performance_based_service_acquisition_code=='X'))

task_fe_pba_not_applicable=felm(winsorized_delay ~ before_aug_2014*business_type |
                       product_or_service_code|0|0,     
                     data = subset(pba_df2,performance_based_service_acquisition_code=='X'))

task_and_industry_fe_pba_not_applicable=felm(winsorized_delay ~before_aug_2014*business_type |
                                    naics_code+product_or_service_code|0|0,     
                                  data = subset(pba_df2,performance_based_service_acquisition_code=='X'))

stargazer(no_fe_pba_not_applicable,task_fe_pba_not_applicable,task_and_industry_fe_pba_not_applicable,
          title = paste("Days of Delay (Winsorized):",range,sep=" "),
          dep.var.labels.include = TRUE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("PSC code FE","No","Yes","Yes"),
                           c("Industry FE","No","No","Yes"),
                           c("Controls","No","No","No")), 
          style="qje",
          notes.align = "l",
          notes=" (i) Each observation is a project-quarter, (ii) Sample restricted to firms that receive only one type of contract (small or large, but not both), (iii) Only contracts for which performance-based was not applicable",
          type="html",
          header=F)

#### Firms with one type of contract: Contract financing #####

# get list of firms with both Small & Large contracts 
firms_with_multiple_types=unique(df1[,uniqueN(business_type),by=recipient_duns][V1==2,]$recipient_duns)

df2=subset(df1,!recipient_duns%in%firms_with_multiple_types)
# remove them from the sample

# read only specific columns
df_raw=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_fy10_to_fy18.csv',
             select = c("contract_award_unique_key",
                        "contract_financing_code",
                        "contract_financing"))

fin_dict=unique(df_raw, by = "contract_award_unique_key")

fin_df=merge(df2,fin_dict,by= "contract_award_unique_key")

fin_df[,receives_financing:=ifelse(!contract_financing_code%in%c("Z",""),1,0)]

# subset of financed contracts
no_fe_fin=felm(winsorized_delay ~ before_aug_2014*business_type |
                  0|0|0,
               data = subset(fin_df,receives_financing==1))
 
task_fe_fin=felm(winsorized_delay ~ before_aug_2014*business_type |
                   product_or_service_code|0|0,
                 data = subset(fin_df,receives_financing==1))

task_and_industry_fe_fin=felm(winsorized_delay ~before_aug_2014*business_type |
                                naics_code+product_or_service_code|0|0,
                              data = subset(fin_df,receives_financing==1))

stargazer(no_fe_fin,task_fe_fin,task_and_industry_fe_fin,
          title = paste("Days of Delay (Winsorized):",range,sep=" "),
          dep.var.labels.include = TRUE,
          object.names=FALSE,
          model.numbers=FALSE,
          add.lines = list(c("PSC code FE","No","Yes","Yes"),
                           c("Industry FE","No","No","Yes"),
                           c("Controls","No","No","No")),
          style="qje",
          notes.align = "l",
          notes=" (i) Each observation is a project-quarter, (ii) Sample restricted to firms that receive only one type of contract (small or large, but not both), (iii) Financed contracts only",
          type="html",
          header=F)

# subset of non financed contracts
no_fe_nonfin=felm(winsorized_delay ~ before_aug_2014*business_type |
                 0|0|0,
               data = subset(fin_df,receives_financing==0))

task_fe_nonfin=felm(winsorized_delay ~ before_aug_2014*business_type |
                   product_or_service_code|0|0,
                 data = subset(fin_df,receives_financing==0))

task_and_industry_fe_nonfin=felm(winsorized_delay ~before_aug_2014*business_type |
                                naics_code+product_or_service_code|0|0,
                              data = subset(fin_df,receives_financing==0))

stargazer(no_fe_nonfin,task_fe_nonfin,task_and_industry_fe_nonfin,
          title = paste("Days of Delay (Winsorized):",range,sep=" "),
          dep.var.labels.include = TRUE,
          object.names=FALSE,
          model.numbers=FALSE,
          add.lines = list(c("PSC code FE","No","Yes","Yes"),
                           c("Industry FE","No","No","Yes"),
                           c("Controls","No","No","No")),
          style="qje",
          notes.align = "l",
          notes=" (i) Each observation is a project-quarter, (ii) Sample restricted to firms that receive only one type of contract (small or large, but not both), (iii) Non-financed contracts only",
          type="html",
          header=F)


#### Firms with one type of contract: Terciles Obligation to Sales ratio #### 

# get list of firms with both Small & Large contracts 
firms_with_multiple_types=unique(df1[,uniqueN(business_type),by=recipient_duns][V1==2,]$recipient_duns)

# remove them from the sample
df2=subset(df1,!recipient_duns%in%firms_with_multiple_types)

# add fiscal year to df2 (contract data)
# format Add the year to 1 if the month (in action-date-year-quarter) 
# is greater than or equal to 10 (or to zero if not)
# because new fiscal year starts from Oct

df2[,action_date_year_quarter:=as.Date(action_date_year_quarter)]
df2[,action_date_fiscal_year:=as.numeric(format(action_date_year_quarter, "%Y")) 
    + (format(action_date_year_quarter, "%m") >= "10")]

# We are assuming fiscal years are same in USASpending & Intellect data

fao_to_sales=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/govt_weight_per_recipient.csv')

df3=merge(df2,fao_to_sales,by= c("recipient_duns","action_date_fiscal_year"))

df3[,winsorized_fao_weight:=Winsorize(fao_weight,na.rm=TRUE)]
df3[,fao_weight_tercile:=ntile(winsorized_fao_weight,3)]

# Y = a + LargeBusiness + Before2014 + LargeBusiness x Before2014 + e

select_tercile = 3

tercile_name=case_when(select_tercile==1 ~ "Bottom Tercile",
                       select_tercile==2 ~ "Middle Tercile",
                       select_tercile==3 ~ "Top Tercile")
no_fe=felm(winsorized_delay ~ before_aug_2014*business_type |
             0|0|0,     
           data = subset(df3,fao_weight_tercile==select_tercile))

task_fe=felm(winsorized_delay ~before_aug_2014*business_type |
               product_or_service_code|0|0,     
             data = subset(df3,fao_weight_tercile==select_tercile))

task_and_industry_fe=felm(winsorized_delay ~before_aug_2014*business_type |
                            naics_code+product_or_service_code|0|0,     
                          data = subset(df3,fao_weight_tercile==select_tercile))

stargazer(no_fe,task_fe,task_and_industry_fe,
          title = paste("Days of Delay (Winsorized):", range, tercile_name, "of Obligation to Sales Ratio", sep=" "),
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


summary_fao_weight=na.omit(df3)[, max(winsorized_fao_weight), by=fao_weight_tercile][, .(fao_weight_tercile = fao_weight_tercile, 
                                                             max_winsorized_fao_ratio = V1)]

kableExtra::kable(summary_fao_weight)

summary_fao_weight_num_contracts=na.omit(df3)[, uniqueN(contract_award_unique_key), by=list(fao_weight_tercile,business_type)][, .(fao_weight_tercile = fao_weight_tercile, 
                                                                                                  business_type=business_type,
                                                                                                  number_of_contracts = V1)][order(fao_weight_tercile)]

kableExtra::kable(summary_fao_weight_num_contracts)

# delays decreased for firms more reliant on govt contracts (tercile = 3) and increased for firms that are less reliant (tercile = 1, 2)

#### Firms with one type of contract: Parametric Obligation to Sales Ratio ####

no_fe=felm(winsorized_delay ~ before_aug_2014*business_type*winsorized_fao_weight|
             0|0|0,     
           data = df3)

task_fe=felm(winsorized_delay ~before_aug_2014*business_type*winsorized_fao_weight|
               product_or_service_code|0|0,     
             data = df3)

task_and_industry_fe=felm(winsorized_delay ~ before_aug_2014*business_type*winsorized_fao_weight |
                            naics_code+product_or_service_code|0|0,     
                          data = df3)

stargazer(no_fe,task_fe,task_and_industry_fe,
          title = paste("Days of Delay (Winsorized):", range, sep=" "),
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

# Aliter 

no_fe=felm(winsorized_delay ~ before_aug_2014+business_type+
             before_aug_2014:business_type:winsorized_fao_weight|
             0|0|0,     
           data = df3)

task_fe=felm(winsorized_delay ~before_aug_2014+business_type+
               before_aug_2014:business_type:winsorized_fao_weight|
               product_or_service_code|0|0,     
             data = df3)

task_and_industry_fe=felm(winsorized_delay ~ before_aug_2014+business_type+
                            before_aug_2014:business_type:winsorized_fao_weight|
                            naics_code+product_or_service_code|0|0,     
                          data = df3)

stargazer(no_fe,task_fe,task_and_industry_fe,
          title = paste("Days of Delay (Winsorized):", range, sep=" "),
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

#### Firms with one type of contract: Performance-based and Sales to obligation terciles #####

# get list of firms with both Small & Large contracts 
firms_with_multiple_types=unique(df1[,uniqueN(business_type),by=recipient_duns][V1==2,]$recipient_duns)

df2=subset(df1,!recipient_duns%in%firms_with_multiple_types)
# remove them from the sample

# add fiscal year to df2 (contract data)
# format Add the year to 1 if the month (in action-date-year-quarter) 
# is greater than or equal to 10 (or to zero if not)
# because new fiscal year starts from Oct

df2[,action_date_year_quarter:=as.Date(action_date_year_quarter)]
df2[,action_date_fiscal_year:=as.numeric(format(action_date_year_quarter, "%Y")) 
    + (format(action_date_year_quarter, "%m") >= "10")]

# We are assuming fiscal years are same in USASpending & Intellect data

fao_to_sales=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/govt_weight_per_recipient.csv')

df3=merge(df2,fao_to_sales,by= c("recipient_duns","action_date_fiscal_year"))

df3[,winsorized_fao_weight:=Winsorize(fao_weight,na.rm=TRUE)]
df3[,fao_weight_tercile:=ntile(winsorized_fao_weight,3)]

# read only pb columns

df_raw=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_fy10_to_fy18.csv',
             select = c("contract_award_unique_key",
                        "performance_based_service_acquisition_code",
                        "performance_based_service_acquisition"))

pba_dict=unique(df_raw, by = "contract_award_unique_key")

pba_df3=merge(df3,pba_dict,by= "contract_award_unique_key")
# read only pb columns

# subset of performance based contracts
no_fe_pba_tercile_1=felm(winsorized_delay ~ before_aug_2014*business_type |
                   0|0|0,     
               data = subset(pba_df3,performance_based_service_acquisition_code=='Y'&
                                 fao_weight_tercile==1))

no_fe_pba_tercile_2=felm(winsorized_delay ~ before_aug_2014*business_type |
                             0|0|0,     
                         data = subset(pba_df3,performance_based_service_acquisition_code=='Y'&
                                           fao_weight_tercile==2))

no_fe_pba_tercile_3=felm(winsorized_delay ~ before_aug_2014*business_type |
                             0|0|0,     
                         data = subset(pba_df3,performance_based_service_acquisition_code=='Y'&
                                           fao_weight_tercile==3))


stargazer(no_fe_pba_tercile_1,no_fe_pba_tercile_2,no_fe_pba_tercile_3,
          title = paste("Days of Delay (Winsorized):",range,sep=" "),
          dep.var.labels.include = TRUE,
          object.names=FALSE, 
          model.numbers=FALSE,
          column.labels = c("Bottom Tercile","Middle Tercile","Top Tercile"),
          add.lines = list(c("PSC code FE","No","No","No"),
                           c("Industry FE","No","No","No"),
                           c("Controls","No","No","No")), 
          style="qje",
          notes.align = "l",
          notes=" (i) Each observation is a project-quarter, (ii) Sample restricted to firms that receive only one type of contract (small or large, but not both), (iii) Performance based contracts only",
          type="html",
          header=F)

# subset of non performance based contracts
no_fe_nonpba_tercile_1=felm(winsorized_delay ~ before_aug_2014*business_type |
                             0|0|0,     
                         data = subset(pba_df3,performance_based_service_acquisition_code!='Y'&
                                           fao_weight_tercile==1))

no_fe_nonpba_tercile_2=felm(winsorized_delay ~ before_aug_2014*business_type |
                             0|0|0,     
                         data = subset(pba_df3,performance_based_service_acquisition_code!='Y'&
                                           fao_weight_tercile==2))

no_fe_nonpba_tercile_3=felm(winsorized_delay ~ before_aug_2014*business_type |
                             0|0|0,     
                         data = subset(pba_df3,performance_based_service_acquisition_code!='Y'&
                                           fao_weight_tercile==3))

stargazer(no_fe_nonpba_tercile_1,no_fe_nonpba_tercile_2,no_fe_nonpba_tercile_3,
          title = paste("Days of Delay (Winsorized):",range,sep=" "),
          dep.var.labels.include = TRUE,
          object.names=FALSE, 
          model.numbers=FALSE,
          column.labels = c("Bottom Tercile","Middle Tercile","Top Tercile"),
          add.lines = list(c("PSC code FE","No","No","No"),
                           c("Industry FE","No","No","No"),
                           c("Controls","No","No","No")), 
          style="qje",
          notes.align = "l",
          notes=" (i) Each observation is a project-quarter, (ii) Sample restricted to firms that receive only one type of contract (small or large, but not both), (iii) Non-performance based contracts only",
          type="html",
          header=F)


#### Firms with one type of contract: LB subsample terciles Obligation to Sales ratio ####
# In this case, we consider the subsamples as:
# all small businesses, large businesses under i-th tercile 

# get list of firms with both Small & Large contracts 
firms_with_multiple_types=unique(df1[,uniqueN(business_type),by=recipient_duns][V1==2,]$recipient_duns)

# remove them from the sample
df2=subset(df1,!recipient_duns%in%firms_with_multiple_types)

# add fiscal year to df2 (contract data)
# format Add the year to 1 if the month (in action-date-year-quarter) 
# is greater than or equal to 10 (or to zero if not)
# because new fiscal year starts from Oct

df2[,action_date_year_quarter:=as.Date(action_date_year_quarter)]
df2[,action_date_fiscal_year:=as.numeric(format(action_date_year_quarter, "%Y")) 
    + (format(action_date_year_quarter, "%m") >= "10")]

# We are assuming fiscal years are same in USASpending & Intellect data

fao_to_sales=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/govt_weight_per_recipient.csv')

df3=merge(df2,fao_to_sales,by= c("recipient_duns","action_date_fiscal_year"))

df3[,winsorized_fao_weight:=Winsorize(fao_weight,na.rm=TRUE)]
df3[,fao_weight_tercile:=ntile(winsorized_fao_weight,3)]

# Y = a + LargeBusiness + Before2014 + LargeBusiness x Before2014 + e

df3[,lb_tercile_name:=case_when(business_type=="O" & fao_weight_tercile==1~ "Bottom Tercile LB",
                                business_type=="O" & fao_weight_tercile==2~ "Middle Tercile LB",
                                business_type=="O" & fao_weight_tercile==3~ "Top Tercile LB")]

select_tercile="Top Tercile LB"

no_fe=felm(winsorized_delay ~ before_aug_2014*business_type |
               0|0|0,
           data = subset(df3,lb_tercile_name==select_tercile | business_type=="S" ))

task_fe=felm(winsorized_delay ~before_aug_2014*business_type |
                 product_or_service_code|0|0,
             data = subset(df3,lb_tercile_name==select_tercile | business_type=="S" ))

task_and_industry_fe=felm(winsorized_delay ~before_aug_2014*business_type |
                              naics_code+product_or_service_code|0|0,
                          data = subset(df3,lb_tercile_name==select_tercile | business_type=="S" ))

stargazer(no_fe,task_fe,task_and_industry_fe,
          title = paste("Days of Delay (Winsorized):", range, select_tercile, "of Obligation to Sales Ratio", sep=" "),
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



#### Firms with one type of contract: LB subsample Contract financing terciles Obligation to Sales ratio ####
# In this case, we consider the subsamples as:
# all small businesses, large businesses under i-th tercile 

# get list of firms with both Small & Large contracts 
firms_with_multiple_types=unique(df1[,uniqueN(business_type),by=recipient_duns][V1==2,]$recipient_duns)

# remove them from the sample
df2=subset(df1,!recipient_duns%in%firms_with_multiple_types)

# add fiscal year to df2 (contract data)
# format Add the year to 1 if the month (in action-date-year-quarter) 
# is greater than or equal to 10 (or to zero if not)
# because new fiscal year starts from Oct

df2[,action_date_year_quarter:=as.Date(action_date_year_quarter)]
df2[,action_date_fiscal_year:=as.numeric(format(action_date_year_quarter, "%Y")) 
    + (format(action_date_year_quarter, "%m") >= "10")]

# read only specific columns
df_raw=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_fy10_to_fy18.csv',
             select = c("contract_award_unique_key",
                        "contract_financing_code",
                        "contract_financing"))

fin_dict=unique(df_raw, by = "contract_award_unique_key")
fin_df=merge(df2,fin_dict,by= "contract_award_unique_key")
fin_df[,receives_financing:=ifelse(!contract_financing_code%in%c("Z",""),1,0)]

# We are assuming fiscal years are same in USASpending & Intellect data

fao_to_sales=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/govt_weight_per_recipient.csv')

df3=merge(fin_df,fao_to_sales,by= c("recipient_duns","action_date_fiscal_year"))

df3[,winsorized_fao_weight:=Winsorize(fao_weight,na.rm=TRUE)]
df3[,fao_weight_tercile:=ntile(winsorized_fao_weight,3)]

# Y = a + LargeBusiness + Before2014 + LargeBusiness x Before2014 + e

df3[,lb_tercile_name:=case_when(business_type=="O" & fao_weight_tercile==1~ "Bottom Tercile LB",
                                business_type=="O" & fao_weight_tercile==2~ "Middle Tercile LB",
                                business_type=="O" & fao_weight_tercile==3~ "Top Tercile LB")]

no_fe_1=felm(winsorized_delay ~ before_aug_2014*business_type |
               0|0|0,
           data = subset(df3,receives_financing==1 & 
                             (lb_tercile_name=="Bottom Tercile LB" | business_type=="S") ))

no_fe_2=felm(winsorized_delay ~ before_aug_2014*business_type |
                 0|0|0,
             data = subset(df3,receives_financing==1 & 
                               (lb_tercile_name=="Middle Tercile LB" | business_type=="S") ))
no_fe_3=felm(winsorized_delay ~ before_aug_2014*business_type |
                 0|0|0,
             data = subset(df3,receives_financing==1 & 
                               (lb_tercile_name=="Top Tercile LB" | business_type=="S") ))

stargazer(no_fe_1,no_fe_2,no_fe_3,
          title = paste("Days of Delay (Winsorized):", range, "of Obligation to Sales Ratio", sep=" "),
          dep.var.labels.include = TRUE,
          object.names=FALSE,
          model.numbers=FALSE,
          column.labels = c("Bottom Tercile","Middle Tercile","Top Tercile"),
          add.lines = list(c("PSC code FE","No","No","No"),
                           c("Industry FE","No","No","No"),
                           c("Controls","No","No","No")),
          style="qje",
          notes.align = "l",
          notes=" (i) Each observation is a project-quarter, (ii) Only contracts that receive financing, (iii) Sample restricted to firms that receive only one type of contract (small or large, but not both)",
          type="html",
          header=F)


## contracts that DONT receive financing

no_fe_1_nonfin=felm(winsorized_delay ~ before_aug_2014*business_type |
                 0|0|0,
             data = subset(df3,receives_financing==0 & 
                               (lb_tercile_name=="Bottom Tercile LB" | business_type=="S") ))

no_fe_2_nonfin=felm(winsorized_delay ~ before_aug_2014*business_type |
                 0|0|0,
             data = subset(df3,receives_financing==0 & 
                               (lb_tercile_name=="Middle Tercile LB" | business_type=="S") ))
no_fe_3_nonfin=felm(winsorized_delay ~ before_aug_2014*business_type |
                 0|0|0,
             data = subset(df3,receives_financing==0 & 
                               (lb_tercile_name=="Top Tercile LB" | business_type=="S") ))

stargazer(no_fe_1_nonfin,no_fe_2_nonfin,no_fe_3_nonfin,
          title = paste("Days of Delay (Winsorized):", range, "of Obligation to Sales Ratio", sep=" "),
          dep.var.labels.include = TRUE,
          object.names=FALSE,
          model.numbers=FALSE,
          column.labels = c("Bottom Tercile","Middle Tercile","Top Tercile"),
          add.lines = list(c("PSC code FE","No","No","No"),
                           c("Industry FE","No","No","No"),
                           c("Controls","No","No","No")),
          style="qje",
          notes.align = "l",
          notes=" (i) Each observation is a project-quarter, (ii) Only contracts that DO NOT receive financing, (iii) Sample restricted to firms that receive only one type of contract (small or large, but not both)",
          type="html",
          header=F)



