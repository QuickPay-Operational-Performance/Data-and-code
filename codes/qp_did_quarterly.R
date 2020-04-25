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
df=read.csv('~/Dropbox/quickpay_resampled.csv',stringsAsFactors = FALSE)

df=df %>% mutate_at(vars(action_date_year_quarter,last_reported_start_date,last_reported_end_date),
                    as.Date, format="%Y-%m-%d")

df$delay=ifelse(df$contract_award_unique_key==lag(df$contract_award_unique_key,1), 
                df$last_reported_end_date-lag(df$last_reported_end_date,1),NaN)

df$winsorized_delay=Winsorize(df$delay,na.rm=TRUE)

df$after_quickpay=ifelse(df$action_date_year_quarter>as.Date("2011-04-27"),1,0)

df$small_business=ifelse(df$business_type=="S",1,0)

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

