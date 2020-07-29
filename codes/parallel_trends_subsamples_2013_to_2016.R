rm(list = ls())

#### Load Packages ####
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
library(ggplot2)
#### Read data #####
df=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/resampled_qp_data/qp_resampled_data_fy10_to_fy18.csv')
df[,action_date_year_quarter:=as.Date(action_date_year_quarter)][,
    winsorized_delay:=Winsorize(change_in_deadline,na.rm=TRUE)][,
    business_type:=relevel(as.factor(business_type),ref="S")]

df[,before_aug_2014:=ifelse(action_date_year_quarter<=as.Date("2014-08-01"),1,0)][,
    after_aug_2014:=ifelse(action_date_year_quarter>as.Date("2014-08-01"),1,0)]
# Payment accelerated to Large Businesses on Aug 1, 2014

old_contracts=unique(subset(df,action_date_year_quarter<=as.Date("2013-03-31"))$contract_award_unique_key)
# we want to exclude contracts that were active in or before the quarter including Feb 21, 2013 
# use march 31, 2013 as threshold because thats when the corresponding quarter ends 

#### Select range ####
# Focus on time period 6 quarters before and 6 quarters after QP
# was implemented for Large businesses

# Longest interval we should consider is +/- 6 quarters
# Treatment implemented 6 quarters after Mar 31, 2013
upper_date=as.Date("2016-03-31")
lower_date=as.Date("2013-03-31")

# 6 quarters
df1=subset(df,!contract_award_unique_key%in%old_contracts &
             action_date_year_quarter<=upper_date&
             action_date_year_quarter>=lower_date)
range="Mar 2013 - Mar 2016"

#### Select Firms with one type of contract ####
firms_with_multiple_types=unique(df1[,uniqueN(business_type),
                          by=recipient_duns][V1==2,]$recipient_duns)
df2=subset(df1,!recipient_duns%in%firms_with_multiple_types)
# remove them from the sample

#### Merge FAO ratio for firms with one type of contract ####
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

#### Parallel Trends: Firms with only one type of contract ####
folder_path='/Users/vibhutidhingra/Desktop/research/Git:Github/qp_data_and_code/img/parallel_trends_subsamples/'
plot_df=df2[,mean(winsorized_delay,na.rm = TRUE), by = c("business_type","action_date_year_quarter")]
setnames(plot_df, "V1", "winsorized_delay")
pt_only_one_type=ggplot(data=na.omit(plot_df),
                        aes(x=action_date_year_quarter, y=winsorized_delay, colour=business_type)) +
  geom_line() +
  ggtitle("Firms with only one type of contract") 

ggsave(paste0(folder_path,"pt_only_one_type.png"), width = 8, height = 4)

#### Parallel Trends: FAO ratio for firms with one type of contract ####
## Firms with only one type of contract but also having a fao ratio (i.e. present in Intellect data)

plot_df1=df3[, mean(winsorized_delay,na.rm = TRUE), 
             by = c("business_type","action_date_year_quarter")]
setnames(plot_df1, "V1", "winsorized_delay")
pt_only_one_type_with_fao=ggplot(data=na.omit(plot_df1),
                                 aes(x=action_date_year_quarter, 
                                     y=winsorized_delay, 
                                     colour=business_type)) +
  geom_line()+
  ggtitle("Firms with only one type of contract \n and having a FAO ratio") 

ggsave(paste0(folder_path,"pt_only_one_type_with_fao.png"), width = 8, height = 4)

####  Parallel Trends Across Terciles: FAO ratio for firms with one type of contract ####

df3[,category:=case_when(business_type=="O" & fao_weight_tercile==1~ "Bottom Tercile LB",
                         business_type=="O" & fao_weight_tercile==2~ "Middle Tercile LB",
                         business_type=="O" & fao_weight_tercile==3~ "Top Tercile LB",
                         business_type=="S"~ "Small business")]
plot_df2=df3[,mean(winsorized_delay,na.rm = TRUE), 
       by = c("category","action_date_year_quarter")]
setnames(plot_df2, "V1", "winsorized_delay")
pt_across_terciles=ggplot(data=na.omit(plot_df2),
       aes(x=action_date_year_quarter, 
           y=winsorized_delay, 
           colour=category)) +
  geom_line()+
  ggtitle("Parallel trends across FAO terciles:\n Firms with only one type of contract") 
ggsave(paste0(folder_path,"pt_across_terciles.png"), width = 8, height = 4)

#### Parallel Trends Within Terciles: FAO ratio for firms with one type of contract ####

## Checking parallel trends within terciles
## Firms with only one type of contract, having a fao ratio (i.e. present in Intellect data)

df3[,category_within_terciles:=case_when(business_type=="O" & fao_weight_tercile==1~ "Bottom Tercile LB",
                                         business_type=="O" & fao_weight_tercile==2~ "Middle Tercile LB",
                                         business_type=="O" & fao_weight_tercile==3~ "Top Tercile LB",
                                         business_type=="S" & fao_weight_tercile==1~ "Bottom Tercile SB",
                                         business_type=="S" & fao_weight_tercile==2~ "Middle Tercile SB",
                                         business_type=="S" & fao_weight_tercile==3~ "Top Tercile SB")]

####  
bottom_tercile=subset(df3,fao_weight_tercile==1)[, 
               mean(winsorized_delay,na.rm = TRUE), 
               by = c("category_within_terciles","action_date_year_quarter")]
setnames(bottom_tercile, "V1", "winsorized_delay")
pt_bottom_tercile=ggplot(data=na.omit(bottom_tercile),
       aes(x=action_date_year_quarter, y=winsorized_delay, colour=category_within_terciles)) +
  geom_line()+
  ggtitle("Bottom Tercile of FAO ratio:\n Firms with only one type of contract") 
ggsave(paste0(folder_path,"pt_bottom_tercile.png"), width = 8, height = 4)

####   
middle_tercile=subset(df3,fao_weight_tercile==2)[, 
               mean(winsorized_delay,na.rm = TRUE), 
               by = c("category_within_terciles","action_date_year_quarter")]
setnames(middle_tercile, "V1", "winsorized_delay")
pt_middle_tercile=ggplot(data=na.omit(middle_tercile),
       aes(x=action_date_year_quarter, y=winsorized_delay, colour=category_within_terciles)) +
  geom_line()+
  ggtitle("Middle Tercile of FAO ratio:\n Firms with only one type of contract") 
ggsave(paste0(folder_path,"pt_middle_tercile.png"), width = 8, height = 4)

####   
top_tercile=subset(df3,fao_weight_tercile==3)[, 
            mean(winsorized_delay,na.rm = TRUE), 
            by = c("category_within_terciles","action_date_year_quarter")]
setnames(top_tercile, "V1", "winsorized_delay")
pt_top_tercile=ggplot(data=na.omit(top_tercile),
       aes(x=action_date_year_quarter, y=winsorized_delay, colour=category_within_terciles)) +
  geom_line()+
  ggtitle("Top Tercile of FAO ratio:\n Firms with only one type of contract") 
ggsave(paste0(folder_path,"pt_top_tercile.png"), width = 8, height = 4)



