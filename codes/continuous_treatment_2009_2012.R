rm(list = ls())

## Treatment as a continuous variable: Based on "Business Reliance"
## Treatment = 0 if contract characterized as large business
## Treatment = Fao/Sales if contract characterized as small business (ratio calculated per year-quarter)

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

df_raw_first_reported=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_first_reported.csv')
# contains time-invariant contract characteristics -- info when contract first appeared in the data

df_raw_full=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_fy10_to_fy18.csv',
                  select=c("action_date",
                           "federal_action_obligation",
                           "contract_award_unique_key",
                           "recipient_duns",
                           "action_date_fiscal_year"))

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
df_raw_first_reported[,contract_financing_i:=ifelse(!is.null(contract_financing_code)&
                                       !contract_financing_code%in%c("Z", ""),1,0)]
df_raw_first_reported[,no_contract_financing_i:=ifelse(is.null(contract_financing_code)|
                                          contract_financing_code%in%c("Z", ""),1,0)]
#### 
df_raw_first_reported[,competitively_awarded_i:=ifelse(!is.null(extent_competed_code)&
                                          !extent_competed_code%in%c("","G","B", "C"),1,0)]
df_raw_first_reported[,not_competitively_awarded_i:=ifelse(is.null(extent_competed_code)|
                                              extent_competed_code%in%c("","G","B", "C"),1,0)]
#### 
df_raw_first_reported[,performance_based_contract_i:=ifelse(performance_based_service_acquisition_code=='Y',1,0)]
df_raw_first_reported[,not_performance_based_contract_i:=ifelse(performance_based_service_acquisition_code!='Y',1,0)]
#### 
df_raw_first_reported[,receives_financial_aid_i:=ifelse(receives_grants=='t'|
                                           c8a_program_participant=='t',1,0)]
df_raw_first_reported[,no_financial_aid_i:=ifelse(receives_grants=='f'&
                                     c8a_program_participant=='f',1,0)]
#### 
df_raw_first_reported[,receives_contracts_and_financial_aid_i:=ifelse(receives_contracts_and_grants=='t'|
                                                         receives_grants=='t'|
                                                         c8a_program_participant=='t',1,0)]
df_raw_first_reported[,no_contracts_and_financial_aid_i:=ifelse(receives_contracts_and_grants=='f'&
                                                   receives_grants=='f'&
                                                   c8a_program_participant=='f',1,0)]

df_raw_first_reported[,initial_duration_in_days_i:=as.numeric(as.Date(period_of_performance_current_end_date)-
                                                 as.Date(period_of_performance_start_date))]
df_raw_first_reported[,initial_budget_i:=base_and_all_options_value]

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

df_raw_first_reported_cols=df_raw_first_reported[,..select_cols]

# not necessary but speed efficient to set keys
setkey(df_raw_first_reported_cols,contract_award_unique_key)
setkey(df,contract_award_unique_key)

#### Combine all variables into dataframe needed for regression ####
reg_df=merge(df,
             df_raw_first_reported_cols,
             all.x = TRUE, # keep values in df, add columns of df_raw_cols
             by=c("contract_award_unique_key"))

#### Data cleaning for Business Reliance ####
# We are assuming fiscal years are same in USASpending & Intellect data
fao_to_sales=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/govt_weight_per_recipient.csv')

# Get sum of federal action obligations per recipient-quarter
df_raw_full[,action_date_year_quarter:=as.Date(as.yearqtr(action_date, format="%Y-%m-%d"), frac = 1)]
fao_per_recipient_quarter=df_raw_full[,sum(federal_action_obligation),
                                      by=c("recipient_duns",
                                           "action_date_year_quarter",
                                           "action_date_fiscal_year")]
setnames(fao_per_recipient_quarter, "V1", "total_fao")

# Get ratio of total fao to sales in each recipient-quarter
fao_per_recipient_quarter=merge(fao_per_recipient_quarter,
      fao_to_sales[,c("recipient_duns","action_date_fiscal_year","sales_volume")],
      by=c("recipient_duns","action_date_fiscal_year"))
fao_per_recipient_quarter[,fao_to_sales_per_quarter:=total_fao*4/sales_volume]
setorderv(fao_per_recipient_quarter, c("recipient_duns","action_date_year_quarter"))
fao_per_recipient_quarter[,winsorized_fao_to_sales_per_quarter:=Winsorize(fao_to_sales_per_quarter,na.rm=T)] 

#### Regression data frame #### 
reg_df=merge(reg_df,fao_per_recipient_quarter,by=c("recipient_duns","action_date_year_quarter"))
reg_df[,rho_it:=ifelse(treat_i==1,winsorized_fao_to_sales_per_quarter,0)]

#### Baseline DiD ####
basic_did<-felm(winsorized_delay~rho_it*post_t,
                            data=reg_df, 
                            exactDOF = TRUE, 
                            cmethod = "reghdfe")

stargazer(basic_did,
          title = "Days of Delay (Winsorized): Quickpay 2009-2011",
          dep.var.labels.include = FALSE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("Firm FE","No"),
                           c("Quarter FE","No"),
                           c("PSC FE","No"),
                           c("Project FE","No"),
                           c("Controls","No")), 
          type="html",style="qje",
          notes="(i) Each observation is a project-quarter",
          header = F)

#### Baseline FE Regressions #####
cluster_var = 0
## Firm and Time Fixed Effects
fixed_vars =  c("action_date_year_quarter","recipient_duns")
control_vars=c("initial_duration_in_days_i") #,"initial_budget_i")

firm_fe_formula=formula(paste("winsorized_delay~rho_it+rho_it:post_t",
                              "+",paste(control_vars,"+post_t:",control_vars,collapse="+"),
                              "|", paste(fixed_vars, collapse= "+"),
                              "| 0 |", cluster_var))

firm_and_time_fe<-felm(firm_fe_formula,
                       data=reg_df, 
                       exactDOF = TRUE, 
                       cmethod = "reghdfe")

## Firm, Task and Time Fixed Effects
fixed_vars =  c("action_date_year_quarter","recipient_duns","product_or_service_code")
firm_task_fe_formula=formula(paste("winsorized_delay~rho_it+rho_it:post_t",
                                   "+",paste(control_vars,"+post_t:",control_vars,collapse="+"),
                                   "|", paste(fixed_vars, collapse= "+"),
                                   "| 0 |", cluster_var))

firm_task_and_time_fe<-felm(firm_task_fe_formula,
                            data=reg_df, 
                            exactDOF = TRUE, 
                            cmethod = "reghdfe")

stargazer(firm_and_time_fe,firm_task_and_time_fe,
          title = "Days of Delay (Winsorized): Quickpay 2009-2011",
          dep.var.labels.include = FALSE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("Firm FE","Yes","Yes"),
                           c("Quarter FE","Yes","Yes"),
                           c("PSC FE","No","Yes"),
                           c("Project FE","No","No"),
                           c("Controls","Yes","Yes")), 
          type="html",style="qje",
          notes="Each observation is a project-quarter",
          header = F)

#### Contract Financing #####
int_vars=c("contract_financing_i","no_contract_financing_i")
cluster_var = 0

## Firm and Time Fixed Effects
fixed_vars =  c("action_date_year_quarter","recipient_duns")
control_vars=c("initial_duration_in_days_i") #,"initial_budget_i")

firm_fe_formula=formula(paste("winsorized_delay~",
                              paste("post_t:rho_it:",int_vars,collapse="+"),
                              "+", paste(int_vars[1],"+ post_t:",int_vars[1]),
                              "+",paste(control_vars,"+post_t:",control_vars,collapse="+"),
                              "|", paste(fixed_vars, collapse= "+"),
                              "| 0 |", cluster_var))

firm_and_time_fe<-felm(firm_fe_formula,
                       data=reg_df, 
                       exactDOF = TRUE, 
                       cmethod = "reghdfe")

## Firm, Task and Time Fixed Effects
fixed_vars =  c("action_date_year_quarter","recipient_duns","product_or_service_code")
firm_task_fe_formula=formula(paste("winsorized_delay~",
                                   paste("post_t:rho_it:",int_vars,collapse="+"),
                                   "+", paste(int_vars[1],"+ post_t:",int_vars[1]),
                                   "+",paste(control_vars,"+post_t:",control_vars,collapse="+"),
                                   "|", paste(fixed_vars, collapse= "+"),
                                   "| 0 |", cluster_var))

firm_task_and_time_fe<-felm(firm_task_fe_formula,
                            data=reg_df, 
                            exactDOF = TRUE, 
                            cmethod = "reghdfe")

stargazer(firm_and_time_fe,firm_task_and_time_fe,
          title = "Days of Delay (Winsorized): Quickpay 2009-2011",
          dep.var.labels.include = FALSE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("Firm FE","Yes","Yes"),
                           c("Quarter FE","Yes","Yes"),
                           c("PSC FE","No","Yes"),
                           c("Project FE","No","No"),
                           c("Controls","Yes","Yes")), 
          type="html",style="qje",
          notes="Each observation is a project-quarter",
          header = F)
