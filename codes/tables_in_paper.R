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

#### Baseline Regressions ####
#baseline="winsorized_delay~post_t:treat_i+"

baseline_reg=felm(winsorized_delay~treat_i+post_t:treat_i+post_t|0|0|contract_award_unique_key,
                  data=reg_df, 
                  exactDOF = TRUE, 
                  cmethod = "reghdfe")
# time fixed effects also included in the following specs
controls_and_firm_fe=felm(winsorized_delay~treat_i+post_t:treat_i+
                            initial_duration_in_days_i+
                            post_t:initial_duration_in_days_i|
                            recipient_duns+action_date_year_quarter|
                            0|contract_award_unique_key,
                          data=reg_df, 
                          exactDOF = TRUE, 
                          cmethod = "reghdfe")

controls_and_firm_task_fe=felm(winsorized_delay~treat_i+post_t:treat_i+
                                 initial_duration_in_days_i+
                                 post_t:initial_duration_in_days_i|
                                 recipient_duns+product_or_service_code+action_date_year_quarter
                               |0|contract_award_unique_key,
                               data=reg_df, 
                               exactDOF = TRUE, 
                               cmethod = "reghdfe")
#### Treatment Intensity Regressions ####

df_raw_full=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_fy10_to_fy18.csv',
                  select=c("action_date",
                           "federal_action_obligation",
                           "contract_award_unique_key",
                           "recipient_duns",
                           "action_date_fiscal_year"))

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

## Regression 
## new reg_df2 because many observations get dropped in this 
reg_df2=merge(reg_df,fao_per_recipient_quarter,by=c("recipient_duns","action_date_year_quarter"))
reg_df2[,rho_it:=ifelse(treat_i==1,winsorized_fao_to_sales_per_quarter,0)]

fixed_vars =  c("action_date_year_quarter","recipient_duns","product_or_service_code")
control_vars=c("initial_duration_in_days_i")
cluster_var="contract_award_unique_key"
treatment_intensity_formula=formula(paste("winsorized_delay~treat_i+rho_it+treat_i:post_t+
                                   post_t:rho_it",
                                          "+",paste(control_vars,"+post_t:",control_vars,collapse="+"),
                                          "|", paste(fixed_vars, collapse= "+"),
                                          "| 0 |", cluster_var))

treatment_intensity=felm(treatment_intensity_formula,
                         data=reg_df2, 
                         exactDOF = TRUE, 
                         cmethod = "reghdfe")

#### Export Baseline Table to PDF ####
# to pdf 
vars.order <- c("Constant",
                "post_t", 
                "treat_i", 
                "treat_i:post_t", 
                "rho_it", 
                "rho_it:post_t",
                "initial_duration_in_days_i",
                "post_t:initial_duration_in_days_i")
vars.rename <- c("Constant",
                 "$Post_t$", 
                 "$Treat_i$", 
                 "$Post_t times Treat_i$", 
                 "$rho_{it}$", 
                 "$Post_t times rho_{it}$",
                 "$InitialDuration_i$",
                 "$Post_t times InitialDuration_i$")

stargazer(baseline_reg,
          controls_and_firm_fe,
          controls_and_firm_task_fe,
          treatment_intensity,
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
          covariate.labels = vars.rename,
          add.lines = list(c("Year-Quarter Fixed Effects","No","Yes","Yes","Yes"),
                           c("Firm Fixed Effects","No","Yes","Yes","Yes"),
                           c("Task Fixed Effects","No","No","Yes","Yes"),
                           c("Controls","No","Yes","Yes","Yes")),
          style="default",
          #    notes="(i) Each observation is a project-quarter, (ii) Standard errors are heteroskedasticity-robust and clustered at the project level.",
          header=F)

#### Financial Constraints Regressions ####
int_vars=c("financing_constraints_i")
cluster_var = "contract_award_unique_key"
control_vars=c("initial_duration_in_days_i") #,"initial_budget_i")
fixed_vars =  c("action_date_year_quarter","recipient_duns","product_or_service_code")

financing_constraints_formula=formula(paste("winsorized_delay~treat_i+post_t:treat_i+",
                                   paste("post_t:treat_i:",int_vars,collapse="+"),
                                   "+", paste(int_vars[1],"+ post_t:",int_vars[1]),
                                   "+",paste(control_vars,"+post_t:",control_vars,collapse="+"),
                                   "|", paste(fixed_vars, collapse= "+"),
                                   "| 0 |", cluster_var))

# 1: Contract Financing

reg_df[,financing_constraints_i:=contract_financing_i]

contract_financing=felm(financing_constraints_formula,
                        data=reg_df, 
                        exactDOF = TRUE, 
                        cmethod = "reghdfe")

# 2: Grants or C8A Participant

reg_df[,financing_constraints_i:=receives_financial_aid_i]

grants_or_c8a_participant=felm(financing_constraints_formula,
                               data=reg_df, 
                               exactDOF = TRUE, 
                               cmethod = "reghdfe")

# 3: Grants or "Grants & Contracts" or C8A Participant

reg_df[,financing_constraints_i:=receives_contracts_and_financial_aid_i]

grants_contracts_or_c8a_participant=felm(financing_constraints_formula,
                                         data=reg_df, 
                                         exactDOF = TRUE, 
                                         cmethod = "reghdfe")

# to pdf 
vars.order <- c("treat_i", 
                "treat_i:post_t", 
                "treat_i:post_t:financing_constraints_i",
                "financing_constraints_i",
                "post_t:financing_constraints_i",
                "initial_duration_in_days_i",
                "post_t:initial_duration_in_days_i")
vars.rename <- c("$Treat_i$", 
                 "$Post_t times Treat_i$", 
                 "$Post_t times Treat_i times FinancingConstraints_i$",
                 "$FinancingConstraints_i$",
                 "$Post_t times FinancingConstraints_i$",
                 "$InitialDuration_i$",
                 "$Post_t times InitialDuration_i$")

stargazer(contract_financing,
          grants_or_c8a_participant,
          grants_contracts_or_c8a_participant,
          title = "Quickpay 2009-2011",
          dep.var.labels="$Delay_{it}$ (in days, 5 p.c. Winsorized)",
          dep.var.caption = "",
          object.names=FALSE, 
          model.numbers=TRUE,
          column.labels = c("ContractFinancing", "Grants or C8A",
                            "Contracts+Grants/C8A"),
          font.size = "small",
          align = TRUE,
          omit.stat=c("f", "ser"),
          column.sep.width = "-2pt",
          order=paste0("^", vars.order , "$"),
          covariate.labels = vars.rename,
          add.lines = list(c("Year-Quarter Fixed Effects","Yes","Yes","Yes"),
                           c("Firm Fixed Effects","Yes","Yes","Yes"),
                           c("Task Fixed Effects","Yes","Yes","Yes"),
                           c("Controls","Yes","Yes","Yes")),
          style="default",
          #    notes="(i) Each observation is a project-quarter, (ii) Standard errors are heteroskedasticity-robust and clustered at the project level.",
          header=F)



