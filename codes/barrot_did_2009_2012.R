rm(list = ls())

#### Load packages ####
library(tidyverse)
library(dplyr)
library(pryr)
library(lfe) # linear fixed effects 
library(DescTools) 
library(zoo) # for year quarter
library(stargazer)
library(broom)
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

# read selected columns from full data
covariates=c("contract_award_unique_key",
             "action_date",
             "contract_financing_code",
             "contract_financing",
             "extent_competed_code",
             "extent_competed",
             "performance_based_service_acquisition_code",
             "performance_based_service_acquisition",
             "receives_grants",
             "receives_contracts_and_grants")
df_raw=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_fy10_to_fy18.csv',
             select=covariates)
df_raw[,action_date_year_quarter:=as.Date(as.yearqtr(as.Date(action_date)),frac = 1)]
# get quarter corresponding to action date -- might need later

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

#### Assign variables: ContractFinancing_i, Competition_i, PerformanceBased_i ####
df_raw[,contract_financing_i:=ifelse(!is.null(contract_financing_code)&
                                     !contract_financing_code%in%c("Z", ""),1,0)]
df_raw[,competitively_awarded_i:=ifelse(!is.null(extent_competed_code)&
                                        !extent_competed_code%in%c("","G","B", "C"),1,0)]
df_raw[,performance_based_contract_i:=ifelse(performance_based_service_acquisition_code=='Y',1,0)]

select_cols=c("contract_award_unique_key",
              "contract_financing_i",
              "competitively_awarded_i",
              "performance_based_contract_i")

df_raw_unique=unique(df_raw, by = c("contract_award_unique_key"))[,..select_cols]

# not necessary but speed efficient to set keys
setkey(df_raw_unique,contract_award_unique_key)
setkey(df,contract_award_unique_key)

#### Combine all variables into dataframe needed for regression ####
reg_df=merge(df,
             df_raw_unique,
             all.x = TRUE, # keep values in df, add columns of df_raw_unique
             by=c("contract_award_unique_key"))

#### Set Regression formula ####

# int_var: interaction variable
# fixed_var_1: fixed effect variable
# fixed_var_2: fixed effect variable
# cluster_var: cluster variable 

reg_formula=formula("winsorized_delay ~ treat_i:post_t + treat_i:post_t:int_var + 
    post_t:int_var | fixed_var_1 + fixed_var_2 | 0 | cluster_var")

#### Regression for contract financing ####
cf_i=
  list(
  int_var=as.name("contract_financing_i"),
  fixed_var_2=as.name("action_date_year_quarter"),
  cluster_var=0
  )

## Firm and Time Fixed Effects
firm_fe_formula=formula(substitute_q(reg_formula,
                 c(cf_i,
                   list(fixed_var_1=as.name("recipient_duns"))
                 )
                ))

firm_and_time_fe<-felm(firm_fe_formula,
                       data=reg_df, 
                       exactDOF = TRUE, 
                       cmethod = "reghdfe")

## Firm, Task and Time Fixed Effects
firm_task_fe_formula=formula(winsorized_delay ~ treat_i:post_t + 
                               treat_i:post_t:contract_financing_i + 
                               post_t:contract_financing_i | 
                               product_or_service_code + 
                               recipient_duns +
                               action_date_year_quarter
                               |0|0)

firm_task_and_time_fe<-felm(firm_task_fe_formula,
                            data=reg_df, 
                            exactDOF = TRUE, 
                            cmethod = "reghdfe")

## Project and Time Fixed Effects
project_fe_formula=formula(substitute_q(reg_formula,
                                     c(cf_i,
                                       list(fixed_var_1=as.name("contract_award_unique_key"))
                                     )
))

project_and_time_fe<-felm(project_fe_formula,
                          data=reg_df, 
                          exactDOF = TRUE, 
                          cmethod = "reghdfe")

stargazer(firm_and_time_fe,firm_task_and_time_fe, project_and_time_fe,
          title = "Days of Delay (Winsorized): Quickpay 2009-2011",
          dep.var.labels.include = FALSE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("Firm FE","Yes","Yes","No"),
                           c("Quarter FE","Yes","Yes","Yes"),
                           c("PSC FE","No","Yes","No"),
                           c("Project FE","No","No","Yes"),
                           c("Controls","No","No", "No")), 
          type="html",style="qje",
          notes="Each observation is a project-quarter",
          header = F)

#### Regression for competition ####

comp_i=
  list(
    int_var=as.name("competitively_awarded_i"),
    fixed_var_2=as.name("action_date_year_quarter"),
    cluster_var=0
  )

## Firm and Time Fixed Effects
firm_fe_formula=formula(substitute_q(reg_formula,
                                     c(comp_i,
                                       list(fixed_var_1=as.name("recipient_duns"))
                                     )
))

firm_and_time_fe<-felm(firm_fe_formula,
                       data=reg_df, 
                       exactDOF = TRUE, 
                       cmethod = "reghdfe")

## Firm, Task and Time Fixed Effects
firm_task_fe_formula=formula(winsorized_delay ~ treat_i:post_t + 
                               treat_i:post_t:competitively_awarded_i + 
                               post_t:competitively_awarded_i | 
                               product_or_service_code + 
                               recipient_duns +
                               action_date_year_quarter
                             |0|0)

firm_task_and_time_fe<-felm(firm_task_fe_formula,
                            data=reg_df, 
                            exactDOF = TRUE, 
                            cmethod = "reghdfe")

## Project and Time Fixed Effects
project_fe_formula=formula(substitute_q(reg_formula,
                                        c(comp_i,
                                          list(fixed_var_1=as.name("contract_award_unique_key"))
                                        )
))

project_and_time_fe<-felm(project_fe_formula,
                          data=reg_df, 
                          exactDOF = TRUE, 
                          cmethod = "reghdfe")

stargazer(firm_and_time_fe,firm_task_and_time_fe, project_and_time_fe,
          title = "Days of Delay (Winsorized): Quickpay 2009-2011",
          dep.var.labels.include = FALSE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("Firm FE","Yes","Yes","No"),
                           c("Quarter FE","Yes","Yes","Yes"),
                           c("PSC FE","No","Yes","No"),
                           c("Project FE","No","No","Yes"),
                           c("Controls","No","No", "No")), 
          type="html",style="qje",
          notes="Each observation is a project-quarter",
          header = F)

#### Regression for performance-based contracts ####

pb_i=
  list(
    int_var=as.name("performance_based_contract_i"),
    fixed_var_2=as.name("action_date_year_quarter"),
    cluster_var=0
  )

## Firm and Time Fixed Effects
firm_fe_formula=formula(substitute_q(reg_formula,
                                     c(pb_i,
                                       list(fixed_var_1=as.name("recipient_duns"))
                                     )
))

firm_and_time_fe<-felm(firm_fe_formula,
                       data=reg_df, 
                       exactDOF = TRUE, 
                       cmethod = "reghdfe")

## Firm, Task and Time Fixed Effects
firm_task_fe_formula=formula(winsorized_delay ~ treat_i:post_t + 
                               treat_i:post_t:performance_based_contract_i + 
                               post_t:performance_based_contract_i | 
                               product_or_service_code + 
                               recipient_duns +
                               action_date_year_quarter
                             |0|0)

firm_task_and_time_fe<-felm(firm_task_fe_formula,
                            data=reg_df, 
                            exactDOF = TRUE, 
                            cmethod = "reghdfe")

## Project and Time Fixed Effects
project_fe_formula=formula(substitute_q(reg_formula,
                                        c(pb_i,
                                          list(fixed_var_1=as.name("contract_award_unique_key"))
                                        )
))

project_and_time_fe<-felm(project_fe_formula,
                          data=reg_df, 
                          exactDOF = TRUE, 
                          cmethod = "reghdfe")

stargazer(firm_and_time_fe,firm_task_and_time_fe, project_and_time_fe,
          title = "Days of Delay (Winsorized): Quickpay 2009-2011",
          dep.var.labels.include = FALSE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("Firm FE","Yes","Yes","No"),
                           c("Quarter FE","Yes","Yes","Yes"),
                           c("PSC FE","No","Yes","No"),
                           c("Project FE","No","No","Yes"),
                           c("Controls","No","No", "No")), 
          type="html",style="qje",
          notes="Each observation is a project-quarter",
          header = F)
