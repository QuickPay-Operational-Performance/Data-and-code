rm(list = ls())
library(tidyverse)
library(dplyr)
library(lfe) # linear fixed effects 
library(DescTools) 
library(stargazer)
library(broom)

#####################################
# Read data and assign variables #
####################################
# df_raw=read.csv('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data.csv',stringsAsFactors = FALSE)

df=read.csv('/Users/vibhutidhingra/Dropbox/data_quickpay/quickpay_resampled.csv',stringsAsFactors = FALSE)
df=subset(df,action_date_year_quarter<max(df$action_date_year_quarter))
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
df$recipient_duns<-as.factor(df$recipient_duns)
df$product_or_service_code<-as.factor(df$product_or_service_code)
#####################################################
# Baseline Regressions 
# (SEs clustered, but cluster variable not specified)
#####################################################

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

###########################################################################################
# Sample restricted to firms that were active in both pre and post treatment period
# This will help test whether the mechanism driving treatment effect is indeed moral hazard
###########################################################################################

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

###########################################################################################
# Sample restricted to contracts that were active in both pre and post treatment period
###########################################################################################

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


#######################################
# Regression for assigning time trend #
#######################################

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












