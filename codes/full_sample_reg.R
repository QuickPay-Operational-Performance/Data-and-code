rm(list = ls())
library(tidyverse)
#library(zoo) # for year-quarter
library(dplyr)
library(lfe) # linear fixed effects 
library(DescTools) 
library(MatchIt)
library(stargazer)
library(broom)
library(magrittr) # for pipes
#library(bookdown)
#library(cobalt) # for checking balance after/before matching 

df=read.csv('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/resampled_qp_data/qp_resampled_data_fy10_to_fy18.csv',stringsAsFactors=FALSE)

df$action_date_year_quarter=as.Date(df$action_date_year_quarter)
df<-df%>%mutate(winsorized_delay=Winsorize(df$change_in_deadline,na.rm=TRUE),
                
                treat=case_when(df$action_date_year_quarter<=as.Date("2011-04-27")~0,
                                # before Apr 27, 2011 -- no one treated
                                (df$action_date_year_quarter>as.Date("2011-04-27"))&
                                  (df$business_type=="S")~1,
                                # after Apr 27, 2011 -- small businesses treated
                                (df$action_date_year_quarter>as.Date("2012-07-11"))&
                                  (df$action_date_year_quarter<=as.Date("2013-02-21"))&
                                  (df$business_type=="O")~1,
                                # July 11, 2012 to Feb 21, 2013 -- large businesses treated
                                (df$action_date_year_quarter>as.Date("2014-08-01"))&
                                  (df$business_type=="O")~1,
                                # after Aug 1, 2014 -- large businesses treated
                                (df$action_date_year_quarter>as.Date("2013-02-21"))&
                                  (df$action_date_year_quarter<=as.Date("2014-08-01"))&
                                  (df$business_type=="O")~0,
                                # Feb 21, 2013 - Aug 1, 2014 -- large businesses control
                                (df$action_date_year_quarter<as.Date("2012-07-11"))&
                                  (df$business_type=="O")~0))
df$action_date_year_quarter=relevel(as.factor(as.Date(df$action_date_year_quarter)),
                                    ref="2011-03-31")


recipient_fe=felm(winsorized_delay ~ treat + business_type|
               recipient_duns|0|0,     
             data = df,
             exactDOF = TRUE,
             cmethod = "reghdfe")

time_fe=felm(winsorized_delay ~ treat + business_type|
               action_date_year_quarter|0|0,     
               data = df,
               exactDOF = TRUE,
               cmethod = "reghdfe")


recipient_and_time_fe=felm(winsorized_delay ~ treat + business_type|
                             recipient_duns+action_date_year_quarter|0|0,     
                           data = df,
                           exactDOF = TRUE,
                           cmethod = "reghdfe")

stargazer(time_fe,recipient_fe,recipient_and_time_fe,         
          title = "Days of Delay (Winsorized): Full Sample (2009-2017)",
          dep.var.labels.include = TRUE,
          object.names=FALSE, 
          model.numbers=FALSE,
          add.lines = list(c("Firm FE","No","Yes","Yes"),
                           c("Product/Service Code FE","No","No","No"),
                           c("Quarter-Year FE","Yes","No","Yes"),
                           c("Controls","No")), 
          type="html",style="qje",
          notes=" (i) Each observation is a project-quarter",
          header = F)





