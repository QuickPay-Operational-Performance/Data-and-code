rm(list = ls())
# Treatment Intensity Regressions 
## 2009 to 2012 Implementation ##
#### Load packages ####
library(tidyverse)
library(dplyr)
library(pryr)
library(lfe) # linear fixed effects 
library(DescTools) 
library(zoo) # for year quarter
library(stargazer)
library(broom)
library(ggplot2)
library(data.table)
#### Read data ####

# read quarterly resampled data
df=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/resampled_qp_data/quickpay_resampled_fy10_to_fy12.csv')

# specify date columns
date_cols=c("action_date_year_quarter","last_reported_start_date","last_reported_end_date")
df[,(date_cols):= lapply(.SD, as.Date), .SDcols = date_cols]

# restrict to quarter ending June 30, 2012
df=subset(df,as.Date(action_date_year_quarter)<max(as.Date(df$action_date_year_quarter)))
# data is truncated at July 1, 2012 -- 
# so quarter ending Sept 30, 2012 will only have values as of July 1, 2012

df_raw=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_first_reported.csv')
# contains time-invariant contract characteristics -- info when contract first appeared in the data

#### Assign variables: Delay, Winsorized Delay, Post_t, Treat_i ####

# sort by contract id and date 
df=df[order(contract_award_unique_key,action_date_year_quarter)]

# determine quarter-to-quarter delay
df[,delay:=ifelse(contract_award_unique_key==lag(contract_award_unique_key,1), 
                  last_reported_end_date-lag(last_reported_end_date,1),NaN)]

# winsorize quarter-to-quarter delay
df[,winsorized_delay:=Winsorize(delay,na.rm=TRUE)]

#Post_t: A dummy that period t is post-treatment
df[,post_t:=ifelse(action_date_year_quarter>as.Date("2011-04-27"),1,0)]
# quickpay implemented on 27 April 2011. So all quarters starting 30 June 2011 will be in post-period

#Treat_i: A dummy that contract i is in the treatment group
df[,treat_i:=ifelse(business_type=="S",1,0)]
# quickpay was implemented for small business contracts

#### Assign variables: ContractFinancing_i, Competition_i, PerformanceBased_i, Financial_Aid_i ####
df_raw[,contract_financing_i:=ifelse(!is.null(contract_financing_code)&
                                       !contract_financing_code%in%c("Z", ""),1,0)]
df_raw[,no_contract_financing_i:=ifelse(is.null(contract_financing_code)|
                                          contract_financing_code%in%c("Z", ""),1,0)]
#### 
df_raw[,competitively_awarded_i:=ifelse(!is.null(extent_competed_code)&
                                          !extent_competed_code%in%c("","G","B", "C"),1,0)]
df_raw[,not_competitively_awarded_i:=ifelse(is.null(extent_competed_code)|
                                              extent_competed_code%in%c("","G","B", "C"),1,0)]
#### 
df_raw[,performance_based_contract_i:=ifelse(performance_based_service_acquisition_code=='Y',1,0)]
df_raw[,not_performance_based_contract_i:=ifelse(performance_based_service_acquisition_code!='Y',1,0)]
#### 
df_raw[,receives_financial_aid_i:=ifelse(receives_grants=='t'|
                                           c8a_program_participant=='t',1,0)]
df_raw[,no_financial_aid_i:=ifelse(receives_grants=='f'&
                                     c8a_program_participant=='f',1,0)]
#### 
df_raw[,receives_contracts_and_financial_aid_i:=ifelse(receives_contracts_and_grants=='t'|
                                                         receives_grants=='t'|
                                                         c8a_program_participant=='t',1,0)]
df_raw[,no_contracts_and_financial_aid_i:=ifelse(receives_contracts_and_grants=='f'&
                                                   receives_grants=='f'&
                                                   c8a_program_participant=='f',1,0)]

df_raw[,initial_duration_in_days_i:=as.numeric(as.Date(period_of_performance_current_end_date)-
                                                 as.Date(period_of_performance_start_date))]
df_raw[,initial_budget_i:=base_and_all_options_value]

select_cols=c("contract_award_unique_key",
              "contract_financing_i",
              "no_contract_financing_i",
              "competitively_awarded_i",
              "not_competitively_awarded_i",
              "performance_based_contract_i",
              "not_performance_based_contract_i",
              "receives_financial_aid_i",
              "no_financial_aid_i",
              "receives_contracts_and_financial_aid_i",
              "no_contracts_and_financial_aid_i",
              "initial_duration_in_days_i",
              "initial_budget_i")

df_raw_cols=df_raw[,..select_cols]

# not necessary but speed efficient to set keys
setkey(df_raw_cols,contract_award_unique_key)
setkey(df,contract_award_unique_key)

#### Combine all variables into dataframe needed for regression ####
reg_df=merge(df,
             df_raw_cols,
             all.x = TRUE, # keep values in df, add columns of df_raw_cols
             by=c("contract_award_unique_key"))

#### Get number of small and large projects per firm quarter ####
sb=subset(reg_df,business_type=="S")[,n_distinct(contract_award_unique_key),
         by=c("recipient_duns",
              "action_date_year_quarter")]
setnames(sb,"V1","num_small_projects")

lb=subset(reg_df,business_type=="O")[,n_distinct(contract_award_unique_key),
                                     by=c("recipient_duns",
                                          "action_date_year_quarter")]
setnames(lb,"V1","num_large_projects")

both=merge(sb,
           lb,
           all.x=TRUE,
           all.y=TRUE,
           by=c("recipient_duns",
                "action_date_year_quarter"))
both[,num_large_projects:=ifelse(is.na(num_large_projects),0,num_large_projects)]
both[,num_small_projects:=ifelse(is.na(num_small_projects),0,num_small_projects)]
both[,percentage_small:=(num_small_projects*100)/(num_small_projects+num_large_projects)]
both[,percentage_large:=(num_large_projects*100)/(num_small_projects+num_large_projects)]

reg_df=merge(reg_df,
             both,
             all.x=TRUE,
             by=c("recipient_duns",
                  "action_date_year_quarter"))

#### Regression ####
fixed_vars =  c("action_date_year_quarter",
                "recipient_duns",
                "product_or_service_code")
control_vars=c("initial_duration_in_days_i")
cluster_var="contract_award_unique_key"

# can also replace num_small_projects with percentage_small -- but this has a simpler interpretation
ti_formula=formula(paste("winsorized_delay~
                         treat_i+
                         percentage_small+
                         percentage_small:post_t +
                         percentage_small:post_t:treat_i",
                         "+",paste(control_vars,"+post_t:",control_vars,collapse="+"),
                         "|", paste(fixed_vars, collapse= "+"),
                         "| 0 |", cluster_var))

ti_reg=felm(ti_formula,
            data=reg_df,
            exactDOF = TRUE, 
            cmethod = "reghdfe")

tidy(ti_reg)

# the idea is that the more small business projects you have, less your financial constraints after QP
# so fewer delays



