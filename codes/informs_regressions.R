rm(list = ls())

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
df_raw[,winsorized_initial_duration_in_days_i:=Winsorize(initial_duration_in_days_i,na.rm=T)]
df_raw[,winsorized_initial_budget_i:=Winsorize(initial_budget_i,na.rm=T)]

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
              "winsorized_initial_duration_in_days_i",
              "winsorized_initial_budget_i",
              "number_of_offers_received")

df_raw_cols=df_raw[,..select_cols]

# not necessary but speed efficient to set keys
setkey(df_raw_cols,contract_award_unique_key)
setkey(df,contract_award_unique_key)

#### Combine all variables into dataframe needed for regression ####
reg_df=merge(df,
             df_raw_cols,
             all.x = TRUE, # keep values in df, add columns of df_raw_cols
             by=c("contract_award_unique_key"))

#### Regression for Parallel Trends ####
df_qn<-unique(reg_df,by='action_date_year_quarter')[,"action_date_year_quarter"]
df_qn=df_qn[order(action_date_year_quarter)][,quarter_number:=seq.int(nrow(df_qn))]
reg_df=merge(reg_df,df_qn,by='action_date_year_quarter')
cluster_var = "contract_award_unique_key"

# Estimating linear time trend before quickpay was implemented

fixed_vars =  c("action_date_year_quarter",
                "recipient_duns",
                "product_or_service_code")

pt_formula=formula(paste("winsorized_delay~treat_i+
                         quarter_number:treat_i+
                         winsorized_initial_duration_in_days_i+
                         winsorized_initial_budget_i+
                         number_of_offers_received",
                         "|", paste(fixed_vars, collapse= "+"),
                         "| 0 |", cluster_var))

parallel_trend<-felm(pt_formula,
                     data=subset(reg_df,post_t==0), 
                     exactDOF = TRUE, 
                     cmethod = "reghdfe")

stargazer(parallel_trend,
          title = "Linear Time Trend Before QuickPay",
          dep.var.labels.include = FALSE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("Firm FE","Yes"),
                           c("Quarter FE","Yes"),
                           c("PSC FE","Yes"),
                           c("Controls","Yes","Yes")), 
          type="html",
          style="qje",
          notes="Each observation is a project-quarter. Standard errors are robust and clustered at the project level. Observations are for quarters before quickpay.",
          header = F)

#### Baseline Regressions ####
baseline_reg=felm(winsorized_delay~treat_i+post_t:treat_i+post_t|0|0|contract_award_unique_key,
                  data=reg_df, 
                  exactDOF = TRUE, 
                  cmethod = "reghdfe")
# time fixed effects also included in the following specs
controls_and_firm_fe=felm(winsorized_delay~treat_i+post_t:treat_i+
                            winsorized_initial_duration_in_days_i+
                            post_t:winsorized_initial_duration_in_days_i+
                            winsorized_initial_budget_i+
                            post_t:winsorized_initial_budget_i+
                            number_of_offers_received+
                            post_t:number_of_offers_received|
                            recipient_duns+action_date_year_quarter|
                            0|contract_award_unique_key,
                          data=reg_df, 
                          exactDOF = TRUE, 
                          cmethod = "reghdfe")

controls_and_firm_task_fe=felm(winsorized_delay~treat_i+post_t:treat_i+
                                 winsorized_initial_duration_in_days_i+
                                 post_t:winsorized_initial_duration_in_days_i+
                                 winsorized_initial_budget_i+
                                 post_t:winsorized_initial_budget_i+
                                 number_of_offers_received+
                                 post_t:number_of_offers_received|
                                 recipient_duns+product_or_service_code+action_date_year_quarter
                               |0|contract_award_unique_key,
                               data=reg_df, 
                               exactDOF = TRUE, 
                               cmethod = "reghdfe")

#### Save Baseline to html ####
vars.order <- c("treat_i", 
                "treat_i:post_t",
                "post_t:contract_financing_i",
                "winsorized_initial_duration_in_days_i",
                "post_t:winsorized_initial_duration_in_days_i",
                "winsorized_initial_budget_i",
                "post_t:winsorized_initial_budget_i",
                "number_of_offers_received",
                "post_t:number_of_offers_received")

stargazer(baseline_reg,
          controls_and_firm_fe,
          controls_and_firm_task_fe,
          title = "Quickpay 2009-2011",
          dep.var.labels="$Delay_{it}$ (in days, 5 p.c. Winsorized)",
          dep.var.caption = "",
          object.names=FALSE, 
          model.numbers=TRUE,
          font.size = "small",
          align = TRUE,
          omit.stat=c("f", "ser"),
          column.sep.width = "-2pt",
          order=paste0("^", vars.order , "$"),
          #  covariate.labels = vars.rename,
          add.lines = list(c("Year-Quarter Fixed Effects","No","Yes","Yes"),
                           c("Firm Fixed Effects","No","Yes","Yes"),
                           c("Task Fixed Effects","No","No","Yes")),
          style="default",
          type="html",
          #    notes="(i) Each observation is a project-quarter, (ii) Standard errors are heteroskedasticity-robust and clustered at the project level.",
          header=F)
#### Financial Constraints Regressions ####
contract_financing_baseline=felm(winsorized_delay~treat_i+
                          post_t:treat_i+
                          post_t:treat_i:contract_financing_i+
                          contract_financing_i+
                          post_t|0|0|contract_award_unique_key,
                        data=reg_df, 
                        exactDOF = TRUE, 
                        cmethod = "reghdfe")

contract_financing_firm_fe=felm(winsorized_delay~treat_i+
                                  post_t:treat_i+
                                  post_t:treat_i:contract_financing_i+
                                  contract_financing_i+
                                  post_t:contract_financing_i+
                                  winsorized_initial_duration_in_days_i+
                                  post_t:winsorized_initial_duration_in_days_i+
                                  winsorized_initial_budget_i+
                                  post_t:winsorized_initial_budget_i+
                                  number_of_offers_received+
                                  post_t:number_of_offers_received|
                                  recipient_duns+action_date_year_quarter|
                                  0|contract_award_unique_key,
                                data=reg_df, 
                                exactDOF = TRUE, 
                                cmethod = "reghdfe")

contract_financing_firm_and_task_fe=felm(winsorized_delay~treat_i+
                                           post_t:treat_i+
                                           post_t:treat_i:contract_financing_i+
                                           contract_financing_i+
                                           post_t:contract_financing_i+
                                           winsorized_initial_duration_in_days_i+
                                           post_t:winsorized_initial_duration_in_days_i+
                                           winsorized_initial_budget_i+
                                           post_t:winsorized_initial_budget_i+
                                           number_of_offers_received+
                                           post_t:number_of_offers_received|
                                           recipient_duns+product_or_service_code+action_date_year_quarter|
                                           0|contract_award_unique_key,
                                         data=reg_df, 
                                         exactDOF = TRUE, 
                                         cmethod = "reghdfe")

#### Save FC to html ####
vars.order <- c("treat_i", 
                "treat_i:post_t", 
                "treat_i:post_t:contract_financing_i",
                "contract_financing_i",
                "post_t:contract_financing_i",
                "winsorized_initial_duration_in_days_i",
                "post_t:winsorized_initial_duration_in_days_i",
                "winsorized_initial_budget_i",
                "post_t:winsorized_initial_budget_i",
                "number_of_offers_received",
                "post_t:number_of_offers_received")

stargazer(contract_financing_baseline,
          contract_financing_firm_fe,
          contract_financing_firm_and_task_fe,
          title = "Quickpay 2009-2011",
          dep.var.labels="$Delay_{it}$ (in days, 5 p.c. Winsorized)",
          dep.var.caption = "",
          object.names=FALSE, 
          model.numbers=TRUE,
          font.size = "small",
          align = TRUE,
          omit.stat=c("f", "ser"),
          column.sep.width = "-2pt",
          order=paste0("^", vars.order , "$"),
        #  covariate.labels = vars.rename,
          add.lines = list(c("Year-Quarter Fixed Effects","No","Yes","Yes"),
                           c("Firm Fixed Effects","No","Yes","Yes"),
                           c("Task Fixed Effects","No","No","Yes")),
          style="default",
          type="html",
          #    notes="(i) Each observation is a project-quarter, (ii) Standard errors are heteroskedasticity-robust and clustered at the project level.",
          header=F)

















