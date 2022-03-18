## Script to read Intellect data
## Note: I changed the file types to .xlsx for all
## This is because CSVs were throwing an error in both Python and R
## It may be because excel files were saved/formatted with csv extension
## .xlsx works fine in R 

rm(list = ls())
library(readxl)
library(dplyr)
library(data.table) 
library(knitr)

# get file paths
files <- list.files(path = "~/Dropbox/data_quickpay/qp_data/intellect_data", 
                    pattern = "*.xlsx", full.names = T)

# merge all files into one dataframe
df <- sapply(files, read_excel, simplify=FALSE) %>% 
  rbindlist(., fill = TRUE)

# count number of firms for which the column values are Non-Null 
firm_count <-data.frame(number_of_firms=nrow(df)-colSums(is.na(df)))
# total number of firms in the sample - number of firms with NA values
kable(firm_count, format="html")

##############################
# checking with contract info
##############################

df$`D-U-N-S@ Number`<-as.numeric(gsub("-", "", df$`D-U-N-S@ Number`))
df$`2010 Sales Volume`<-gsub("\\$",'',df$`2010 Sales Volume`)
df$`2010 Sales Volume`<-as.numeric(gsub(",",'',df$`2010 Sales Volume`))

df1=df[,c("2010 Sales Volume","D-U-N-S@ Number")]

##############################
##############################
##############################


recipient_budget=subset(reg_df1,action_date_year_quarter<as.Date('2011-04-27'))[,
                                        sum(base_and_all_options_value),
                         by='recipient_duns']

setnames(recipient_budget,"V1","pre_qp_total_budget")                        

reg_df1=merge(reg_df1,recipient_budget,by='recipient_duns')

reg_df1[,budget_to_sales:=ifelse(`2010 Sales Volume`>0,
                                 pre_qp_total_budget/`2010 Sales Volume`,
                                 NaN)]

pre_qp_projects=unique(subset(reg_df,action_date_year_quarter<as.Date('2011-04-27'))$contract_award_unique_key)

reg_df1[,wins_budget_to_sales:=Winsorize(budget_to_sales,
                                         probs=c(0.05,0.95),
                                         na.rm=T)]

hist(log(reg_df1$wins_budget_to_sales))

tidy(felm(wins_percentage_delay~treat_i+
          post_t:treat_i+
          log(wins_budget_to_sales)+
          treat_i:log(wins_budget_to_sales)+
          post_t:log(wins_budget_to_sales)+
          post_t:treat_i:log(wins_budget_to_sales)|
          action_date_year_quarter| # no fixed effects
          0| # no IV
          contract_award_unique_key, # clustered at project level
        data=subset(reg_df1,contract_award_unique_key%in%pre_qp_projects),
        exactDOF = TRUE,
        cmethod = "reghdfe"))