rm(list = ls())
library(tidyverse)
library(zoo) # for year-quarter
#library(dplyr)
library(data.table) # much faster than dplyr & syntax similar to python 
library(dtplyr)
library(lfe) # linear fixed effects 
library(DescTools) 
library(MatchIt)
library(stargazer)
library(broom)
#library(magrittr) # for pipes
#library(bookdown)
#library(cobalt) # for checking balance after/before matching 

df=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/resampled_qp_data/qp_resampled_data_fy10_to_fy18.csv')
#,stringsAsFactors=FALSE)

df[,action_date_year_quarter:=as.Date(action_date_year_quarter)][,
    winsorized_delay:=Winsorize(change_in_deadline,na.rm=TRUE)][,
    business_type:=as.factor(business_type)][,
    treat:=case_when(df$action_date_year_quarter<=as.Date("2011-04-27")~0,
                                # before Apr 27, 2011 -- no one treated
                                (df$action_date_year_quarter>as.Date("2011-04-27"))&
                                  (df$business_type=="S")~1,
                                # after Apr 27, 2011 -- small businesses treated
                                (df$action_date_year_quarter>=as.Date("2012-07-11"))&
                                  (df$action_date_year_quarter<=as.Date("2013-03-31"))&
                                  (df$business_type=="O")~1,
                                # July 11, 2012 to Feb 21, 2013 -- large businesses treated
                                # consider end date as March 31, 2013 so treat=1 in that quarter
                                (df$action_date_year_quarter>as.Date("2014-08-01"))&
                                  (df$business_type=="O")~1,
                                # after Aug 1, 2014 -- large businesses treated
                                (df$action_date_year_quarter>as.Date("2013-03-31"))&
                                  (df$action_date_year_quarter<=as.Date("2014-08-01"))&
                                  (df$business_type=="O")~0,
                                # Feb 21, 2013 - Aug 1, 2014 -- large businesses control
                                # consider start date as March 31, 2013 so treat=1 in that quarter
                                (df$action_date_year_quarter<as.Date("2012-07-11"))&
                                  (df$business_type=="O")~0)][, 
      quarter:= as.factor(quarters(as.Date(action_date_year_quarter)))]

df_qn=unique(df[,"action_date_year_quarter"])[order(action_date_year_quarter)]
# drop duplicates based on quarter, select only quarter column, and sort values in ascending order
df_qn[,time:=seq.int(nrow(df_qn))] 

df=merge(df,df_qn, by="action_date_year_quarter")
df[,
   action_date_year_quarter:=relevel(as.factor(as.Date(action_date_year_quarter)),
                                     ref="2011-03-31")]


############################################
# Regressions with Fixed Effects
############################################
## assumes treatment efffect is same for large and small businesses 
## delay_i,t = a + b x (Treat_i,t) + c x (BSize) + d x (Year-Quarter or Time) + e

# Time fixed effect
time_and_business_size_fe=felm(winsorized_delay ~ treat+business_type |
                                 action_date_year_quarter|0|0,     
                           data = df,
                           exactDOF = TRUE,
                           cmethod = "reghdfe")

############################################
## Interact with business type 
## delay_i,t = a + b x (Treat_i,t*BSize) + f x (Treat_i,t) + c x (BSize) + d x (Year-Quarter) + e
time_and_business_size_fe_int=felm(winsorized_delay ~ treat+treat*business_type|
                             action_date_year_quarter|0|0,     
                           data = df,
                           exactDOF = TRUE,
                           cmethod = "reghdfe")

time_and_contract_fe_int=felm(winsorized_delay ~ treat+treat:business_type|
                                     action_date_year_quarter+contract_award_unique_key|0|0,     
                                   data = df,
                                   exactDOF = TRUE,
                                   cmethod = "reghdfe")


stargazer(time_and_business_size_fe,time_and_business_size_fe_int,time_and_contract_fe_int,         
          title = "Days of Delay (Winsorized): Full Sample (2009-2017)",
          dep.var.labels.include = TRUE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("Contract FE","No","No","Yes"),
                           c("Quarter-Year FE","Yes","Yes","Yes"),
                           c("Controls","No","No","Yes")), 
          type="html",style="qje",
          notes=" (i) Each observation is a project-quarter",
          header = F)

############################################
# Regressions with Time Trends
############################################
reg1=felm(winsorized_delay ~ treat+time+business_type|
                                   quarter|0|0,     
                                   data = df,
                                   exactDOF = TRUE,
                                   cmethod = "reghdfe")

reg2=felm(winsorized_delay ~ time+treat*business_type|
                                     quarter|0|0,     
                                     data = df,
                                     exactDOF = TRUE,
                                     cmethod = "reghdfe")


# t + Q_1 + ... + Q_4 + Tr x t + Tr x Q_1 + ... + Tr x Q_4 + other controls

reg3=felm(winsorized_delay ~  time+treat+
                              time:treat+
                              treat:quarter+
                              business_type|
                              quarter|0|0,     
                              data = df,
                              exactDOF = TRUE,
                              cmethod = "reghdfe")

# t + Q_1 + ... + Q_4 + Tr x t + Tr x Q_1 + ... 
# + Tr x Q_4 + SM x Tr x t + SM x Tr x Q_1 + ... + SM x Tr x Q_4 + other controls

reg4=felm(winsorized_delay ~ time+treat+
                              time:treat+
                              quarter:treat+
                              business_type:treat:time+
                              business_type:treat:quarter+
                              business_type|
                              quarter|0|0,     
                              data = df,
                              exactDOF = TRUE,
                              cmethod = "reghdfe")

stargazer(reg1,reg2,reg3,reg4,         
          title = "Days of Delay (Winsorized): Full Sample (2009-2017)",
          dep.var.labels.include = TRUE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("Quarter FE","Yes","Yes","Yes","Yes"),
                           c("Controls","No","No","No","No")), 
          type="html",style="qje",
          notes=" (i) Each observation is a project-quarter, (ii) Quarter FE in {1,2,3,4}",
          header = F)





