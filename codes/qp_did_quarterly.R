rm(list = ls())
library(tidyverse)
library(dplyr)
library(lfe) # linear fixed effects 
library(DescTools) 
library(stargazer)
library(broom)
library(data.table)

#### Read data and assign variables ####

# df_raw=read.csv('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data.csv',stringsAsFactors = FALSE)

df=read.csv('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/resampled_qp_data/quickpay_resampled_fy10_to_fy12.csv',
            stringsAsFactors = FALSE)
df=subset(df,as.Date(action_date_year_quarter)<max(as.Date(df$action_date_year_quarter)))
# restrict to quarter ending June 30, 2012
# data is truncated at July 1, 2012 -- 
# so quarter ending Sept 30, 2012 will only have values as of July 1, 2012

df=df %>% mutate_at(vars(action_date_year_quarter,last_reported_start_date,last_reported_end_date),
                    as.Date, format="%Y-%m-%d")
df=df%>%arrange(contract_award_unique_key,action_date_year_quarter)
# sort by contract id and date 
df$delay=ifelse(df$contract_award_unique_key==lag(df$contract_award_unique_key,1), 
                df$last_reported_end_date-lag(df$last_reported_end_date,1),NaN)

df$winsorized_delay=Winsorize(df$delay,na.rm=TRUE)

df$after_quickpay=ifelse(df$action_date_year_quarter>as.Date("2011-04-27"),1,0)

df$small_business=ifelse(df$business_type=="S",1,0)

df$naics_code<-as.factor(df$naics_code)
#df$recipient_duns<-as.factor(df$recipient_duns)
df$product_or_service_code<-as.factor(df$product_or_service_code)

#### Baseline Regressions ####


ols_fe<-felm(as.formula("winsorized_delay ~ after_quickpay*small_business| 
                     0|0|0"),
             data=df, 
             exactDOF = TRUE, 
             cmethod = "reghdfe")

firm_fe<-felm(as.formula("winsorized_delay ~ after_quickpay*small_business| 
                     recipient_duns|0|0"),
              data=df, 
              exactDOF = TRUE, 
              cmethod = "reghdfe")

firm_and_task_fe<-felm(as.formula("winsorized_delay ~ after_quickpay*small_business| 
                     recipient_duns+product_or_service_code|0|0"),
                       data=df, 
                       exactDOF = TRUE, 
                       cmethod = "reghdfe")

firm_and_task_naics_fe<-felm(as.formula("winsorized_delay ~ after_quickpay*small_business| 
                     recipient_duns+product_or_service_code+naics_code|0|0"),
                             data=df, 
                             exactDOF = TRUE, 
                             cmethod = "reghdfe")

stargazer(ols_fe,firm_fe,firm_and_task_fe,firm_and_task_naics_fe,
          title = "Days of Delay (Winsorized): Quickpay 2009-2011",
          dep.var.labels.include = FALSE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("Firm FE","No","Yes","Yes","Yes"),
                           c("Product/Service Code FE","No","No","Yes","Yes"),
                           c("Industry FE","No","No","No","Yes"),
                           c("Controls","No", "No","No", "No")), 
          type="html",style="qje",
          notes="Each observation is a project-quarter",
          header = F)


#### Sample restricted to firms that were active in both pre and post treatment period ####
# This will help test whether the mechanism driving treatment effect is indeed moral hazard


firms_before=unique(subset(df,after_quickpay==0)$recipient_duns)
firms_after=unique(subset(df,after_quickpay==1)$recipient_duns)
firms_in_both=intersect(firms_before,firms_after)

ols_fe<-felm(as.formula("winsorized_delay ~ after_quickpay*small_business| 
                     0|0|0"),
             data=subset(df,recipient_duns%in%firms_in_both), 
             exactDOF = TRUE, 
             cmethod = "reghdfe")

firm_fe<-felm(as.formula("winsorized_delay ~ after_quickpay*small_business| 
                     recipient_duns|0|0"),
              data=subset(df,recipient_duns%in%firms_in_both), 
              exactDOF = TRUE, 
              cmethod = "reghdfe")

firm_and_task_fe<-felm(as.formula("winsorized_delay ~ after_quickpay*small_business| 
                     recipient_duns+product_or_service_code|0|0"),
                       data=subset(df,recipient_duns%in%firms_in_both), 
                       exactDOF = TRUE, 
                       cmethod = "reghdfe")

firm_and_task_naics_fe<-felm(as.formula("winsorized_delay ~ after_quickpay*small_business| 
                     recipient_duns+product_or_service_code+naics_code|0|0"),
                             data=subset(df,recipient_duns%in%firms_in_both), 
                             exactDOF = TRUE, 
                             cmethod = "reghdfe")

stargazer(ols_fe,firm_fe,firm_and_task_fe,firm_and_task_naics_fe,
          title = "Days of Delay (Winsorized): Quickpay 2009-2011",
          dep.var.labels.include = FALSE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("Firm FE","No","Yes","Yes","Yes"),
                           c("Product/Service Code FE","No","No","Yes","Yes"),
                           c("Industry FE","No","No","No","Yes"),
                           c("Controls","No", "No","No", "No")), 
          type="html",style="qje",
          notes=" (i) Each observation is a project-quarter, (ii) Sample restricted to firms that were active in both pre and post treatment period",
          header = F)


#### Sample restricted to contracts that were active in both pre and post treatment period ####


contracts_before=unique(subset(df,after_quickpay==0)$contract_award_unique_key)
contracts_after=unique(subset(df,after_quickpay==1)$contract_award_unique_key)
contracts_in_both=intersect(contracts_before,contracts_after)

ols_fe<-felm(as.formula("winsorized_delay ~ after_quickpay*small_business| 
                     0|0|0"),
             data=subset(df,contract_award_unique_key%in%contracts_in_both), 
             exactDOF = TRUE, 
             cmethod = "reghdfe")

firm_fe<-felm(as.formula("winsorized_delay ~ after_quickpay*small_business| 
                     recipient_duns|0|0"),
              data=subset(df,contract_award_unique_key%in%contracts_in_both), 
              exactDOF = TRUE, 
              cmethod = "reghdfe")

firm_and_task_fe<-felm(as.formula("winsorized_delay ~ after_quickpay*small_business| 
                     recipient_duns+product_or_service_code|0|0"),
                       data=subset(df,contract_award_unique_key%in%contracts_in_both), 
                       exactDOF = TRUE, 
                       cmethod = "reghdfe")

firm_and_task_naics_fe<-felm(as.formula("winsorized_delay ~ after_quickpay*small_business| 
                     recipient_duns+product_or_service_code+naics_code|0|0"),
                             data=subset(df,contract_award_unique_key%in%contracts_in_both), 
                             exactDOF = TRUE, 
                             cmethod = "reghdfe")

stargazer(ols_fe,firm_fe,firm_and_task_fe,firm_and_task_naics_fe,
          title = "Days of Delay (Winsorized): Quickpay 2009-2011",
          dep.var.labels.include = FALSE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("Firm FE","No","Yes","Yes","Yes"),
                           c("Product/Service Code FE","No","No","Yes","Yes"),
                           c("Industry FE","No","No","No","Yes"),
                           c("Controls","No", "No","No", "No")), 
          type="html",style="qje",
          notes=" (i) Each observation is a project-quarter, (ii) Sample restricted to contracts that were active in both pre and post treatment period",
          header = F)


#### Regression for assigning time trend ####

df_qn<-df[!duplicated(df$action_date_year_quarter), ]%>%
  select("action_date_year_quarter")%>%arrange(action_date_year_quarter)
# drop duplicates based on quarter, select only quarter column, and sort values in ascending order
df_qn$time <- seq.int(nrow(df_qn)) 
# add a column to denote row index
# sort values by action date quarter, and assign time = t-th quarter in the observation horizon

df_sb_tt=merge(subset(df,small_business==1),df_qn,by="action_date_year_quarter")

ols_model<-lm(winsorized_delay~time*after_quickpay,data=df_sb_tt)
stargazer(ols_model,         
          title = "Days of Delay (Winsorized): Small businesses only (2009-2011)",
          dep.var.labels.include = TRUE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("Firm FE","No"),
                           c("Product/Service Code FE","No"),
                           c("Industry FE","No"),
                           c("Controls","No")), 
          type="html",style="qje",
          notes=" (i) Each observation is a project-quarter, (ii) Sample restricted to small businesses only, (iii) Time, t, represents t-th quarter in the observation horizon",
          header = F)

## Considering only time trend and interaction with "after_quickpay"
## Because high correlation between time trend and "after_quickpay" variable 
## -- similar to collinearity issue in DD

ols_model<-lm(winsorized_delay~time+time:after_quickpay,data=df_sb_tt)
stargazer(ols_model,         
          title = "Days of Delay (Winsorized): Small businesses only (2009-2011)",
          dep.var.labels.include = TRUE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("Firm FE","No"),
                           c("Product/Service Code FE","No"),
                           c("Industry FE","No"),
                           c("Controls","No")), 
          type="html",style="qje",
          notes=" (i) Each observation is a project-quarter, (ii) Sample restricted to small businesses only, (iii) Time, t, represents t-th quarter in the observation horizon",
          header = F)

#### Regression for Performance based contracts #####

covariates=c("contract_award_unique_key",
             "performance_based_service_acquisition_code",
             "performance_based_service_acquisition")

df_pb=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_fy10_to_fy18.csv',
            select=covariates)

df1=merge(as.data.table(df),unique(df_pb,by='contract_award_unique_key'),
          on='contract_award_unique_key')

#### Baseline Regressions for Performance Based contract ####
# (SEs clustered, but cluster variable not specified)

ols_fe<-felm(as.formula("winsorized_delay ~ after_quickpay*small_business| 
                     0|0|0"),
             data=subset(df1,performance_based_service_acquisition_code=="Y"), 
             exactDOF = TRUE, 
             cmethod = "reghdfe")

firm_fe<-felm(as.formula("winsorized_delay ~ after_quickpay*small_business| 
                     recipient_duns|0|0"),
              data=subset(df1,performance_based_service_acquisition_code=="Y"), 
              exactDOF = TRUE, 
              cmethod = "reghdfe")

firm_and_task_fe<-felm(as.formula("winsorized_delay ~ after_quickpay*small_business| 
                     recipient_duns+product_or_service_code|0|0"),
                       data=subset(df1,performance_based_service_acquisition_code=="Y"), 
                       exactDOF = TRUE, 
                       cmethod = "reghdfe")

firm_and_task_naics_fe<-felm(as.formula("winsorized_delay ~ after_quickpay*small_business| 
                     recipient_duns+product_or_service_code+naics_code|0|0"),
                             data=subset(df1,performance_based_service_acquisition_code=="Y"), 
                             exactDOF = TRUE, 
                             cmethod = "reghdfe")

stargazer(ols_fe,firm_fe,firm_and_task_fe,firm_and_task_naics_fe,
          title = "Performance Based Contracts: Days of Delay (Winsorized): Quickpay 2009-2011",
          dep.var.labels.include = FALSE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("Firm FE","No","Yes","Yes","Yes"),
                           c("Product/Service Code FE","No","No","Yes","Yes"),
                           c("Industry FE","No","No","No","Yes"),
                           c("Controls","No", "No","No", "No")), 
          type="html",style="qje",
          notes="Each observation is a project-quarter",
          header = F)


#### Baseline Regressions for NON-Performance Based contracts ####
# (SEs clustered, but cluster variable not specified)

ols_fe<-felm(as.formula("winsorized_delay ~ after_quickpay*small_business| 
                     0|0|0"),
             data=subset(df1,performance_based_service_acquisition_code!="Y"), 
             exactDOF = TRUE, 
             cmethod = "reghdfe")

firm_fe<-felm(as.formula("winsorized_delay ~ after_quickpay*small_business| 
                     recipient_duns|0|0"),
              data=subset(df1,performance_based_service_acquisition_code!="Y"), 
              exactDOF = TRUE, 
              cmethod = "reghdfe")

firm_and_task_fe<-felm(as.formula("winsorized_delay ~ after_quickpay*small_business| 
                     recipient_duns+product_or_service_code|0|0"),
                       data=subset(df1,performance_based_service_acquisition_code!="Y"), 
                       exactDOF = TRUE, 
                       cmethod = "reghdfe")

firm_and_task_naics_fe<-felm(as.formula("winsorized_delay ~ after_quickpay*small_business| 
                     recipient_duns+product_or_service_code+naics_code|0|0"),
                             data=subset(df1,performance_based_service_acquisition_code!="Y"), 
                             exactDOF = TRUE, 
                             cmethod = "reghdfe")

stargazer(ols_fe,firm_fe,firm_and_task_fe,firm_and_task_naics_fe,
          title = "NON-Performance Based Contracts: Days of Delay (Winsorized): Quickpay 2009-2011",
          dep.var.labels.include = FALSE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("Firm FE","No","Yes","Yes","Yes"),
                           c("Product/Service Code FE","No","No","Yes","Yes"),
                           c("Industry FE","No","No","No","Yes"),
                           c("Controls","No", "No","No", "No")), 
          type="html",style="qje",
          notes="Each observation is a project-quarter",
          header = F)

#### Only firms with one type of contract ####
library(data.table)

firms_with_multiple_types=unique(setDT(df)[,uniqueN(business_type),by=recipient_duns][V1==2,]$recipient_duns)

df2=subset(setDT(df),!recipient_duns%in%firms_with_multiple_types)


ols_fe<-felm(winsorized_delay ~ after_quickpay*small_business| 
                     0|0|0,
             data=df2, 
             exactDOF = TRUE, 
             cmethod = "reghdfe")

task_fe<-felm(winsorized_delay ~ after_quickpay*small_business| 
                     product_or_service_code|0|0,
                       data=df2, 
                       exactDOF = TRUE, 
                       cmethod = "reghdfe")

industry_and_task_fe<-felm(winsorized_delay ~ after_quickpay*small_business| 
                       product_or_service_code+naics_code|0|0,
                             data=df2, 
                             exactDOF = TRUE, 
                             cmethod = "reghdfe")

stargazer(ols_fe,task_fe,industry_and_task_fe,
          title = "Days of Delay (Winsorized): Quickpay Dec 2009- June 2012",
          dep.var.labels.include = FALSE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("Product/Service Code FE","No","Yes","Yes"),
                           c("Industry FE","No","No","Yes"),
                           c("Controls","No", "No","No")), 
          type="html",style="qje",
          notes.align = "l",
          notes=" (i) Each observation is a project-quarter, (ii) Sample restricted to firms that receive only one type of contract (small or large, but not both)",
          header = F)

#### Firms with one type of contract: Performance-based Regressions #####

# read only pb columns

df_raw=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_fy10_to_fy18.csv',
             select = c("contract_award_unique_key",
                        "performance_based_service_acquisition_code",
                        "performance_based_service_acquisition"))

pba_dict=unique(df_raw, by = "contract_award_unique_key")

pba_df2=merge(df2,pba_dict,by= "contract_award_unique_key")
# read only pb columns


no_fe_pba=felm(winsorized_delay ~ after_quickpay*small_business |
                 0|0|0,     
               data = subset(pba_df2,performance_based_service_acquisition_code=='Y'))

task_fe_pba=felm(winsorized_delay ~ after_quickpay*small_business |
                   product_or_service_code|0|0,     
                 data = subset(pba_df2,performance_based_service_acquisition_code=='Y'))

task_and_industry_fe_pba=felm(winsorized_delay ~after_quickpay*small_business |
                                naics_code+product_or_service_code|0|0,     
                              data = subset(pba_df2,performance_based_service_acquisition_code=='Y'))

stargazer(no_fe_pba,task_fe_pba,task_and_industry_fe_pba,
          title = "Days of Delay (Winsorized): Quickpay Dec 2009- June 2012",
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

#### Firms with one type of contract: Contract financing #####

range = "Oct 2009 to June 2012"
library(data.table)
firms_with_multiple_types=unique(setDT(df)[,uniqueN(business_type),by=recipient_duns][V1==2,]$recipient_duns)
df2=subset(setDT(df),!recipient_duns%in%firms_with_multiple_types)

df_raw=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_fy10_to_fy18.csv',
             select = c("contract_award_unique_key",
                        "contract_financing_code",
                        "contract_financing"))
fin_dict=unique(df_raw, by = "contract_award_unique_key")
fin_df=merge(df2,fin_dict,by= "contract_award_unique_key")
fin_df[,receives_financing:=ifelse(!contract_financing_code%in%c("Z",""),1,0)]

# receive financing

no_fe_fin=felm(winsorized_delay ~ after_quickpay*small_business |
                 0|0|0,     
               data = subset(fin_df,receives_financing==1))

task_fe_fin=felm(winsorized_delay ~ after_quickpay*small_business |
                   product_or_service_code|0|0,     
                 data = subset(fin_df,receives_financing==1))

task_and_industry_fe_fin=felm(winsorized_delay ~after_quickpay*small_business |
                                naics_code+product_or_service_code|0|0,     
                              data = subset(fin_df,receives_financing==1))

stargazer(no_fe_fin,task_fe_fin,task_and_industry_fe_fin,
          title = "Days of Delay (Winsorized): Quickpay Dec 2009- June 2012",
          dep.var.labels.include = TRUE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("PSC code FE","No","Yes","Yes"),
                           c("Industry FE","No","No","Yes"),
                           c("Controls","No","No","No")), 
          style="qje",
          notes.align = "l",
          notes=" (i) Each observation is a project-quarter, (ii) Sample restricted to firms that receive only one type of contract (small or large, but not both), (iii) Only contracts that receive financing",
          type="html",
          header=F)

# no financing
no_fe_fin=felm(winsorized_delay ~ after_quickpay*small_business |
                 0|0|0,     
               data = subset(fin_df,receives_financing==0))

task_fe_fin=felm(winsorized_delay ~ after_quickpay*small_business |
                   product_or_service_code|0|0,     
                 data = subset(fin_df,receives_financing==0))

task_and_industry_fe_fin=felm(winsorized_delay ~after_quickpay*small_business |
                                naics_code+product_or_service_code|0|0,     
                              data = subset(fin_df,receives_financing==0))

stargazer(no_fe_fin,task_fe_fin,task_and_industry_fe_fin,
          title = "Days of Delay (Winsorized): Quickpay Dec 2009- June 2012",
          dep.var.labels.include = TRUE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("PSC code FE","No","Yes","Yes"),
                           c("Industry FE","No","No","Yes"),
                           c("Controls","No","No","No")), 
          style="qje",
          notes.align = "l",
          notes=" (i) Each observation is a project-quarter, (ii) Sample restricted to firms that receive only one type of contract (small or large, but not both), (iii) Only contracts that do not receive financing",
          type="html",
          header=F)

#### Firms with one type of contract: Terciles Obligation to Sales Ratio ####

range = "Oct 2009 to June 2012"

library(data.table)

firms_with_multiple_types=unique(setDT(df)[,uniqueN(business_type),by=recipient_duns][V1==2,]$recipient_duns)

df2=subset(setDT(df),!recipient_duns%in%firms_with_multiple_types)

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

no_fe=felm(winsorized_delay ~ after_quickpay*small_business |
             0|0|0,     
           data = subset(df3,fao_weight_tercile==select_tercile))

task_fe=felm(winsorized_delay ~after_quickpay*small_business |
               product_or_service_code|0|0,     
             data = subset(df3,fao_weight_tercile==select_tercile))

task_and_industry_fe=felm(winsorized_delay ~after_quickpay*small_business |
                            naics_code+product_or_service_code|0|0,     
                          data = subset(df3,fao_weight_tercile==select_tercile))

stargazer(no_fe,task_fe,task_and_industry_fe,
          title = paste("Days of Delay (Winsorized):",range, tercile_name, "of Obligation to Sales Ratio", sep=" "),
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

## Summary: 

summary_fao_weight=na.omit(df3)[, max(winsorized_fao_weight), by=fao_weight_tercile][, .(fao_weight_tercile = fao_weight_tercile, 
                                                                                         max_winsorized_fao_ratio = V1)]

kableExtra::kable(summary_fao_weight)

summary_fao_weight_num_contracts=na.omit(df3)[, uniqueN(contract_award_unique_key), by=list(fao_weight_tercile,business_type)][, .(fao_weight_tercile = fao_weight_tercile, 
                                                                                                                                   business_type=business_type,
                                                                                                                                   number_of_contracts = V1)][order(fao_weight_tercile)]
kableExtra::kable(summary_fao_weight_num_contracts)


#### Firms with one type of contract: Parametric Obligation to Sales Ratio ####

no_fe=felm(winsorized_delay ~ after_quickpay*small_business*winsorized_fao_weight|
             0|0|0,     
           data = df3)

task_fe=felm(winsorized_delay ~after_quickpay*small_business*winsorized_fao_weight|
               product_or_service_code|0|0,     
             data = df3)

task_and_industry_fe=felm(winsorized_delay ~ after_quickpay*small_business*winsorized_fao_weight |
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

# Delay = b0 + b1 SmallBusiness + b2 AfterQP + b3 (SmallBusiness x AfterQP x FaoRatio) + e

no_fe=felm(winsorized_delay ~ after_quickpay+small_business+
             after_quickpay:small_business:winsorized_fao_weight|
             0|0|0,     
           data = df3)

task_fe=felm(winsorized_delay ~after_quickpay+small_business+
               after_quickpay:small_business:winsorized_fao_weight|
               product_or_service_code|0|0,     
             data = df3)

task_and_industry_fe=felm(winsorized_delay ~ after_quickpay+small_business+
                            after_quickpay:small_business:winsorized_fao_weight|
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







