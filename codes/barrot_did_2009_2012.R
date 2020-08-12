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
df_raw[,competitively_awarded_i:=ifelse(!is.null(extent_competed_code)&
                                          !extent_competed_code%in%c("","G","B", "C"),1,0)]
df_raw[,performance_based_contract_i:=ifelse(performance_based_service_acquisition_code=='Y',1,0)]

df_raw[,receives_financial_aid_i:=ifelse(receives_grants=='t'|
                                                  c8a_program_participant=='t',1,0)]

df_raw[,receives_contracts_and_financial_aid_i:=ifelse(receives_contracts_and_grants=='t'|
                                           receives_grants=='t'|
                                           c8a_program_participant=='t',1,0)]

df_raw[,initial_duration_in_days_i:=as.numeric(as.Date(period_of_performance_current_end_date)-
                                        as.Date(period_of_performance_start_date))]
df_raw[,initial_budget_i:=base_and_all_options_value]

select_cols=c("contract_award_unique_key",
              "contract_financing_i",
              "competitively_awarded_i",
              "performance_based_contract_i",
              "receives_financial_aid_i",
              "receives_contracts_and_financial_aid_i",
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

#### Regression formula ####
baseline="winsorized_delay~post_t:treat_i + post_t:treat_i:"

#### Regression for contract financing ####
int_var=as.name("contract_financing_i") 
cluster_var = 0

## Firm and Time Fixed Effects
fixed_vars =  c("action_date_year_quarter","recipient_duns")
control_vars=c("initial_duration_in_days_i","initial_budget_i")

firm_fe_formula=formula(paste(baseline,int_var, "+ post_t:",int_var,
                              "+",paste("post_t:",control_vars,collapse="+"),
                                          "|", paste(fixed_vars, collapse= "+"),
                                          "| 0 |", cluster_var))

firm_and_time_fe<-felm(firm_fe_formula,
                       data=reg_df, 
                       exactDOF = TRUE, 
                       cmethod = "reghdfe")

## Firm, Task and Time Fixed Effects
fixed_vars =  c("action_date_year_quarter","recipient_duns","product_or_service_code")
firm_task_fe_formula=formula(paste(baseline,int_var, "+ post_t:",int_var,
                                   "+",paste("post_t:",control_vars,collapse="+"),
                              "|", paste(fixed_vars, collapse= "+"),
                              "| 0 |", cluster_var))

firm_task_and_time_fe<-felm(firm_task_fe_formula,
                            data=reg_df, 
                            exactDOF = TRUE, 
                            cmethod = "reghdfe")

## Project and Time Fixed Effects
fixed_vars =  c("action_date_year_quarter","contract_award_unique_key")

project_fe_formula=formula(paste(baseline,int_var, "+ post_t:",int_var,
                                 "+",paste("post_t:",control_vars,collapse="+"),
                                 "|", paste(fixed_vars, collapse= "+"),
                                 "| 0 |", cluster_var))

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
                           c("Controls","Yes","Yes", "Yes")), 
          type="html",style="qje",
          notes="Each observation is a project-quarter",
          header = F)

#### Regression for competition ####
int_var=as.name("competitively_awarded_i") 
cluster_var = 0

## Firm and Time Fixed Effects
fixed_vars =  c("action_date_year_quarter","recipient_duns")
control_vars=c("initial_duration_in_days_i","initial_budget_i")

firm_fe_formula=formula(paste(baseline,int_var, "+ post_t:",int_var,
                              "+",paste("post_t:",control_vars,collapse="+"),
                              "|", paste(fixed_vars, collapse= "+"),
                              "| 0 |", cluster_var))

firm_and_time_fe<-felm(firm_fe_formula,
                       data=reg_df, 
                       exactDOF = TRUE, 
                       cmethod = "reghdfe")

## Firm, Task and Time Fixed Effects
fixed_vars =  c("action_date_year_quarter","recipient_duns","product_or_service_code")
firm_task_fe_formula=formula(paste(baseline,int_var, "+ post_t:",int_var,
                                   "+",paste("post_t:",control_vars,collapse="+"),
                                   "|", paste(fixed_vars, collapse= "+"),
                                   "| 0 |", cluster_var))

firm_task_and_time_fe<-felm(firm_task_fe_formula,
                            data=reg_df, 
                            exactDOF = TRUE, 
                            cmethod = "reghdfe")

## Project and Time Fixed Effects
fixed_vars =  c("action_date_year_quarter","contract_award_unique_key")

project_fe_formula=formula(paste(baseline,int_var, "+ post_t:",int_var,
                                 "+",paste("post_t:",control_vars,collapse="+"),
                                 "|", paste(fixed_vars, collapse= "+"),
                                 "| 0 |", cluster_var))

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
                           c("Controls","Yes","Yes", "Yes")), 
          type="html",style="qje",
          notes="Each observation is a project-quarter",
          header = F)

#### Regression for performance-based contracts ####
int_var=as.name("performance_based_contract_i") 
cluster_var = 0

## Firm and Time Fixed Effects
fixed_vars =  c("action_date_year_quarter","recipient_duns")
control_vars=c("initial_duration_in_days_i","initial_budget_i")

firm_fe_formula=formula(paste(baseline,int_var, "+ post_t:",int_var,
                              "+",paste("post_t:",control_vars,collapse="+"),
                              "|", paste(fixed_vars, collapse= "+"),
                              "| 0 |", cluster_var))

firm_and_time_fe<-felm(firm_fe_formula,
                       data=reg_df, 
                       exactDOF = TRUE, 
                       cmethod = "reghdfe")

## Firm, Task and Time Fixed Effects
fixed_vars =  c("action_date_year_quarter","recipient_duns","product_or_service_code")
firm_task_fe_formula=formula(paste(baseline,int_var, "+ post_t:",int_var,
                                   "+",paste("post_t:",control_vars,collapse="+"),
                                   "|", paste(fixed_vars, collapse= "+"),
                                   "| 0 |", cluster_var))

firm_task_and_time_fe<-felm(firm_task_fe_formula,
                            data=reg_df, 
                            exactDOF = TRUE, 
                            cmethod = "reghdfe")

## Project and Time Fixed Effects
fixed_vars =  c("action_date_year_quarter","contract_award_unique_key")

project_fe_formula=formula(paste(baseline,int_var, "+ post_t:",int_var,
                                 "+",paste("post_t:",control_vars,collapse="+"),
                                 "|", paste(fixed_vars, collapse= "+"),
                                 "| 0 |", cluster_var))

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
                           c("Controls","Yes","Yes", "Yes")), 
          type="html",style="qje",
          notes="Each observation is a project-quarter",
          header = F)

#### Regression for Financial Assistance ####
int_var=as.name("receives_financial_aid_i") 
cluster_var = 0

## Firm and Time Fixed Effects
fixed_vars =  c("action_date_year_quarter","recipient_duns")
control_vars=c("initial_duration_in_days_i","initial_budget_i")

firm_fe_formula=formula(paste(baseline,int_var, "+ post_t:",int_var,
                              "+",paste("post_t:",control_vars,collapse="+"),
                              "|", paste(fixed_vars, collapse= "+"),
                              "| 0 |", cluster_var))

firm_and_time_fe<-felm(firm_fe_formula,
                       data=reg_df, 
                       exactDOF = TRUE, 
                       cmethod = "reghdfe")

## Firm, Task and Time Fixed Effects
fixed_vars =  c("action_date_year_quarter","recipient_duns","product_or_service_code")
firm_task_fe_formula=formula(paste(baseline,int_var, "+ post_t:",int_var,
                                   "+",paste("post_t:",control_vars,collapse="+"),
                                   "|", paste(fixed_vars, collapse= "+"),
                                   "| 0 |", cluster_var))

firm_task_and_time_fe<-felm(firm_task_fe_formula,
                            data=reg_df, 
                            exactDOF = TRUE, 
                            cmethod = "reghdfe")

## Project and Time Fixed Effects
fixed_vars =  c("action_date_year_quarter","contract_award_unique_key")

project_fe_formula=formula(paste(baseline,int_var, "+ post_t:",int_var,
                                 "+",paste("post_t:",control_vars,collapse="+"),
                                 "|", paste(fixed_vars, collapse= "+"),
                                 "| 0 |", cluster_var))

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
                           c("Controls","Yes","Yes", "Yes")), 
          type="html",style="qje",
          notes="Each observation is a project-quarter",
          header = F)

#### Regression for Contracts AND Financial Assistance #### 
int_var=as.name("receives_contracts_and_financial_aid_i") 
cluster_var = 0

## Firm and Time Fixed Effects
fixed_vars =  c("action_date_year_quarter","recipient_duns")
control_vars=c("initial_duration_in_days_i","initial_budget_i")

firm_fe_formula=formula(paste(baseline,int_var, "+ post_t:",int_var,
                              "+",paste("post_t:",control_vars,collapse="+"),
                              "|", paste(fixed_vars, collapse= "+"),
                              "| 0 |", cluster_var))

firm_and_time_fe<-felm(firm_fe_formula,
                       data=reg_df, 
                       exactDOF = TRUE, 
                       cmethod = "reghdfe")

## Firm, Task and Time Fixed Effects
fixed_vars =  c("action_date_year_quarter","recipient_duns","product_or_service_code")
firm_task_fe_formula=formula(paste(baseline,int_var, "+ post_t:",int_var,
                                   "+",paste("post_t:",control_vars,collapse="+"),
                                   "|", paste(fixed_vars, collapse= "+"),
                                   "| 0 |", cluster_var))

firm_task_and_time_fe<-felm(firm_task_fe_formula,
                            data=reg_df, 
                            exactDOF = TRUE, 
                            cmethod = "reghdfe")

## Project and Time Fixed Effects
fixed_vars =  c("action_date_year_quarter","contract_award_unique_key")

project_fe_formula=formula(paste(baseline,int_var, "+ post_t:",int_var,
                                 "+",paste("post_t:",control_vars,collapse="+"),
                                 "|", paste(fixed_vars, collapse= "+"),
                                 "| 0 |", cluster_var))

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
                           c("Controls","Yes","Yes", "Yes")), 
          type="html",style="qje",
          notes="Each observation is a project-quarter",
          header = F)
#### Data cleaning for Business Reliance ####
# Run until ``Regression formula`` first # 
# We are assuming fiscal years are same in USASpending & Intellect data
fao_to_sales=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/govt_weight_per_recipient.csv')

# add fiscal year to df (resampled contract data)
# format Add the year to 1 if the month (in action-date-year-quarter) 
# is greater than or equal to 10 (or to zero if not)
# because new fiscal year starts from Oct
df[,action_date_fiscal_year:=as.numeric(format(action_date_year_quarter, "%Y")) 
    + (format(action_date_year_quarter, "%m") >= "10")]

df_fao=merge(df,fao_to_sales,by= c("recipient_duns","action_date_fiscal_year"))

reg_df=merge(df_fao,
             df_raw_cols,
             all.x = TRUE, # keep values in df, add columns of df_raw_cols
             by=c("contract_award_unique_key"))

# merge contract characteristics with FAO data

reg_df[,winsorized_fao_weight:=Winsorize(fao_weight,na.rm=TRUE)]
reg_df[,fao_weight_tercile:=as.factor(ntile(winsorized_fao_weight,3))]
# tercile = 1 --> least dependent on federal contracts, tercile = 3 --> most revenue comes from govt

#### Regressions for Business Reliance ####
# tercile = 1 --> least dependent on federal contracts
# tercile = 3 --> most revenue comes from govt

int_var=as.name("fao_weight_tercile") 
cluster_var = 0

## Firm and Time Fixed Effects
fixed_vars =  c("action_date_year_quarter","recipient_duns")
control_vars=c("initial_duration_in_days_i","initial_budget_i")

firm_fe_formula=formula(paste(baseline,int_var, "+ post_t:",int_var,
                              "+",paste("post_t:",control_vars,collapse="+"),
                              "|", paste(fixed_vars, collapse= "+"),
                              "| 0 |", cluster_var))

firm_and_time_fe<-felm(firm_fe_formula,
                       data=reg_df, 
                       exactDOF = TRUE, 
                       cmethod = "reghdfe")

## Firm, Task and Time Fixed Effects
fixed_vars =  c("action_date_year_quarter","recipient_duns","product_or_service_code")
firm_task_fe_formula=formula(paste(baseline,int_var, "+ post_t:",int_var,
                                   "+",paste("post_t:",control_vars,collapse="+"),
                                   "|", paste(fixed_vars, collapse= "+"),
                                   "| 0 |", cluster_var))

firm_task_and_time_fe<-felm(firm_task_fe_formula,
                            data=reg_df, 
                            exactDOF = TRUE, 
                            cmethod = "reghdfe")

## Project and Time Fixed Effects
fixed_vars =  c("action_date_year_quarter","contract_award_unique_key")

project_fe_formula=formula(paste(baseline,int_var, "+ post_t:",int_var,
                                 "+",paste("post_t:",control_vars,collapse="+"),
                                 "|", paste(fixed_vars, collapse= "+"),
                                 "| 0 |", cluster_var))

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
                           c("Controls","Yes","Yes", "Yes")), 
          type="html",style="qje",
          notes="Each observation is a project-quarter",
          header = F)