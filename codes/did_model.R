library(tidyverse)
library(DescTools)
library(stargazer)

df<-read.csv('~/Dropbox/data_quickpay/qp_sample_did.csv',stringsAsFactors = FALSE)
df$winsorized_delay<-Winsorize(df$days_of_change_in_deadline_overall,na.rm=TRUE)

## Winsorized delay days ##
ols_model_win<-lm(winsorized_delay~after_quickpay*small_business,data=df)

## Raw delay days ##
ols_model<-lm(days_of_change_in_deadline_overall~after_quickpay*small_business,data=df)

# output
stargazer(ols_model_win,ols_model,title="OLS DiD model",align=TRUE, type="html",
          column.labels = c("Delay days (winsorized)", "Delay days (raw)"),
          model.numbers= FALSE,
          style = "qje")
