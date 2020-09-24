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

#### Get FAO from small projects only ####
df_raw_full=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_fy10_to_fy18.csv',
                  select=c("action_date",
                           "federal_action_obligation",
                           "contract_award_unique_key",
                           "recipient_duns",
                           "action_date_fiscal_year",
                           "contracting_officers_determination_of_business_size_code"))
# Get action date year quarter from date
df_raw_full[,action_date_year_quarter:=as.Date(as.yearqtr(action_date, format="%Y-%m-%d"), frac = 1)]

# Get sum of federal action obligations per recipient-quarter
# We want to get sum of obligations coming from small projects only
fao_per_recipient_quarter=subset(df_raw_full,
                                 contracting_officers_determination_of_business_size_code=='S')[,
                                                                                                sum(federal_action_obligation),
                                                                                                by=c("recipient_duns",
                                                                                                     "action_date_year_quarter",
                                                                                                     "action_date_fiscal_year")]
setnames(fao_per_recipient_quarter, "V1", "total_fao_from_small_projects")

# Get sales in a given fiscal year
fao_to_sales=fread('~/Dropbox/data_quickpay/qp_data/govt_weight_per_recipient.csv')

# Get ratio of total fao to sales in each recipient-quarter
fao_per_recipient_quarter=merge(fao_per_recipient_quarter,
                                fao_to_sales[,c("recipient_duns",
                                                "action_date_fiscal_year",
                                                "sales_volume")],
                                by=c("recipient_duns","action_date_fiscal_year"))
fao_per_recipient_quarter[,fao_to_sales_per_quarter:=(total_fao_from_small_projects*4)/sales_volume]
setorderv(fao_per_recipient_quarter, c("recipient_duns","action_date_year_quarter"))
fao_per_recipient_quarter[,winsorized_fao_to_sales_per_quarter:=Winsorize(fao_to_sales_per_quarter,na.rm=T)] 

#### Regressions #### 
## new reg_df2 because many observations get dropped in this 
# Note this will assign fao ratio in a quarter 
# to each contract of a recipient -- even if it is a large business contract
# We will fix this when we define Rho
reg_df2=merge(reg_df,fao_per_recipient_quarter,by=c("recipient_duns",
                                                    "action_date_year_quarter"))
reg_df2[,rho_it:=ifelse(treat_i==1,winsorized_fao_to_sales_per_quarter,0)]

fixed_vars =  c("action_date_year_quarter",
                "recipient_duns",
                "product_or_service_code")
control_vars=c("initial_duration_in_days_i")
cluster_var="contract_award_unique_key"

ti_formula=formula(paste("winsorized_delay~rho_it+post_t:rho_it",
                                          "+",paste(control_vars,"+post_t:",control_vars,collapse="+"),
                                          "|", paste(fixed_vars, collapse= "+"),
                                          "| 0 |", cluster_var))

ti_formula_with_treat=formula(paste("winsorized_delay~rho_it+post_t:rho_it+treat_i+treat_i:post_t",
                                            "+",paste(control_vars,"+post_t:",control_vars,collapse="+"),
                                            "|", paste(fixed_vars, collapse= "+"),
                                            "| 0 |", cluster_var))

ti_reg=felm(ti_formula,
                         data=reg_df2,
                         exactDOF = TRUE, 
                         cmethod = "reghdfe")

ti_reg_with_treat=felm(ti_formula_with_treat,
                           data=reg_df2,
                           exactDOF = TRUE, 
                           cmethod = "reghdfe")

ti_reg_subset=felm(ti_formula,
                                data=subset(reg_df2,(treat_i==1 & rho_it>0)|treat_i==0),
                                exactDOF = TRUE, 
                                cmethod = "reghdfe")

ti_reg_with_treat_subset=felm(ti_formula_with_treat,
                                  data=subset(reg_df2,(treat_i==1 & rho_it>0)|treat_i==0),
                                  exactDOF = TRUE, 
                                  cmethod = "reghdfe")

ti_reg_subset_2=felm(ti_formula,
                   data=subset(reg_df2,(treat_i==1 & rho_it>0 & rho_it<=1)|treat_i==0),
                   exactDOF = TRUE, 
                   cmethod = "reghdfe")

ti_reg_with_treat_subset_2=felm(ti_formula_with_treat,
                              data=subset(reg_df2,(treat_i==1 & rho_it>0  & rho_it<=1)|treat_i==0),
                              exactDOF = TRUE, 
                              cmethod = "reghdfe")

#### Output Table #### 
vars.order=c("rho_it",
             "rho_it:post_t",
             "treat_i",
             "post_t:treat_i",
             "initial_duration_in_days_i",
             "post_t:initial_duration_in_days_i")

stargazer(ti_reg,
          ti_reg_with_treat,
          ti_reg_subset,
          ti_reg_with_treat_subset,
          ti_reg_subset_2,
          ti_reg_with_treat_subset_2,
          object.names=FALSE, 
          model.numbers=T,
          add.lines = list(c("Firm FE","Yes","Yes","Yes","Yes","Yes","Yes"),
                           c("Quarter FE","Yes","Yes","Yes","Yes","Yes","Yes"),
                           c("PSC FE","Yes","Yes","Yes","Yes","Yes","Yes"),
                           c("Project FE","No","No","No","No","No","No")),
          type="html",style="qje",
          order=paste0("^", vars.order , "$"),
          notes="(i) Each observation is a project-quarter, (ii) Columns (3) and (4) drop treated observations with a non-positive rho, (iii) Columns (5) and (6) only consider those treated observations that have rho greater than 0 and less than or equal to 1, (iv) Standard errors are robust and clustered at the project level",
          header=F)

#### Output Plot for Rho #### 
# can also replace business_type with factor(treat_i) 
plot=ggplot(reg_df2, aes(x=business_type, y=rho_it, color=business_type)) +  
  geom_boxplot() + 
  scale_y_continuous(limits = c(0, 12), breaks = seq(-1, 12, by = 0.5)) 

ggsave(plot, 
       file="/Users/vibhutidhingra/Desktop/research/Git:Github/qp_data_and_code/img/rho_box_plot.png",
       scale=0.8)
