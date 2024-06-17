library(openxlsx)
library(tidyverse)
library(dplyr)
library(pryr)
library(lfe) # linear fixed effects 
library(DescTools) 
library(zoo) # for year quarter
library(stargazer)
library(broom)
library(fixest)
library(data.table)
library(scales)
library(coefplot)
library(MatchIt)
library(pBrackets)
library(grid)

###### Read data ######

df=fread('/Users/vibhutid_admin/Desktop/qp_data_new.csv')
df[,action_date:=as.Date(action_date)]
df[,period_of_performance_start_date:=as.Date(period_of_performance_start_date)]
df[,period_of_performance_current_end_date:=as.Date(period_of_performance_current_end_date)]

df=df[order(contract_award_unique_key,
            action_date)]

###### Get all active quarters ######

start_end_dates=df[,.(first_action_date=first(action_date),
                      last_action_date=last(action_date)),
                   by='contract_award_unique_key']

start_end_dates[, first_action_quarter := as.Date(as.yearqtr(first_action_date)+ 0.25) - 1]
start_end_dates[, last_action_quarter := as.Date(as.yearqtr(last_action_date)+ 0.25) - 1]


# Function to get list of quarters between two dates
get_quarters <- function(start, end) {
  quarters <- seq(from = start, to = end, by = "3 months")
  return(quarters)
}

# Add quarter column to the data table
# Get all quarters during which a buyer was active
# takes a few minutes to run
start_end_dates[, active_quarters := list(list(get_quarters(first_action_quarter, 
                                                            last_action_quarter))), 
            by = 1:nrow(start_end_dates)]

# Unnest the 'active_quarters' column
# We get all buyer-quarter observations
start_end_dates <- unnest(start_end_dates, active_quarters)

# Set as data table
start_end_dates=setDT(start_end_dates)

# Fix the quarter date formats
# Some have 30th as the last date when it should be 31st
start_end_dates[,active_quarters:=fifelse(format(active_quarters,"%m")%in%
                                        c('01','03','05','07','08','10','12') &
                                        format(active_quarters,"%d")=='30',
                                      active_quarters+1,
                                      active_quarters)]

# Some have 01 as the date when it should be end of preceding month
# E.g., 2010-09-30 instead of 2010-10-01
start_end_dates[,active_quarters:=fifelse(format(active_quarters,"%d")=='01',
                                      active_quarters-1,
                                      active_quarters)]

start_end_dates=start_end_dates[,c('contract_award_unique_key','active_quarters')]
setnames(start_end_dates,'active_quarters','action_date_year_quarter')

###### Last reported start and end dates ######

df[,action_date_year_quarter:=as.Date(as.yearqtr(action_date)+ 0.25) - 1]
df[,action_date_year_quarter:=fifelse(format(action_date_year_quarter,"%m")%in%
                                   c('01','03','05','07','08','10','12') &
                                   format(action_date_year_quarter,"%d")=='30',
                                 action_date_year_quarter+1,
                                 action_date_year_quarter)]

df[,action_date_year_quarter:=fifelse(format(action_date_year_quarter,"%d")=='01',
                                      action_date_year_quarter-1,
                                      action_date_year_quarter)]

last_reported=df[,.(last_reported_end_date=last(period_of_performance_current_end_date),
        last_reported_start_date=last(period_of_performance_start_date)),
   by=c('contract_award_unique_key','action_date_year_quarter')]

start_end_dates=merge(start_end_dates,
                      last_reported,
                      by=c('contract_award_unique_key','action_date_year_quarter'),
                      all.x=T)

start_end_dates[, last_reported_end_date := 
                  na.locf(last_reported_end_date), 
                by = contract_award_unique_key]

start_end_dates[, last_reported_start_date := 
                  na.locf(last_reported_start_date), 
                by = contract_award_unique_key]

###### Treatment ########
df=df[order(contract_award_unique_key,action_date)]

df_first=df[,.(initial_end_date = first(period_of_performance_current_end_date), # first reported end date
                    eventual_end_date = last(period_of_performance_current_end_date),  # last reported end date
                    initial_start_date = first(period_of_performance_start_date),
                    initial_budget=first(base_and_all_options_value),
                    contracting_officers_determination_of_business_size_code=
                 first(contracting_officers_determination_of_business_size_code),
               type_of_contract_pricing_code=first(type_of_contract_pricing_code),
               awarding_sub_agency_code=first(awarding_sub_agency_code),
               product_or_service_code=first(product_or_service_code),
               naics_code=first(naics_code),
               recipient_duns=first(recipient_duns),
               small_disadvantaged_business=first(small_disadvantaged_business),
               number_of_offers_received=first(number_of_offers_received),
               contract_financing_code=first(contract_financing_code),
               extent_competed_code=first(extent_competed_code)), # first reported start date
                 by='contract_award_unique_key']
df_first[,initial_duration:=as.numeric(initial_end_date-initial_start_date)]
df_first[,price_structure:=case_when(type_of_contract_pricing_code%in%c('J','L','M','B','K','A')~"Fixed",
                                      type_of_contract_pricing_code%in%c('U','R','S','T','V')~"Cost")]

df_first[,contract_financing_i:=ifelse(!is.null(contract_financing_code)&
                                           !contract_financing_code%in%c("Z", ""),1,0)]

# Competition_i
df_first[,competitively_awarded_i:=ifelse(!extent_competed_code%in%c("G","B", "C"),1,0)]
#df_first[,competitively_awarded_i:=ifelse(!extent_competed_code=="A",1,0)]

df_first[,treat_i:=case_when(contracting_officers_determination_of_business_size_code=="S" &
                                 small_disadvantaged_business=="f" ~ 1,
                               contracting_officers_determination_of_business_size_code=="O" &
                                 small_disadvantaged_business=="f" ~ 0)]

#### Regression DF #####
reg_df=merge(start_end_dates,
             df_first,
             by='contract_award_unique_key',
             all.x=T)

reg_df=reg_df[order(contract_award_unique_key,action_date_year_quarter)]

reg_df[,delay:=fifelse(contract_award_unique_key==lag(contract_award_unique_key),
                       as.numeric(last_reported_end_date-lag(last_reported_end_date)),
                       NaN)]
reg_df[,wins_delay:=Winsorize(delay,na.rm=T)]
reg_df[,wins_initial_duration:=Winsorize(initial_duration,probs=c(0.05,0.95),na.rm=T)]
reg_df[,wins_initial_budget:=Winsorize(initial_budget,probs=c(0.05,0.95),na.rm=T)]
reg_df[,wins_offers:=Winsorize(number_of_offers_received,probs=c(0.05,0.95),na.rm=T)]
reg_df[,relative_delay:=delay/(1+initial_duration)]
reg_df[,wins_relative_delay:=Winsorize(relative_delay,probs=c(0.05,0.95),na.rm=T)]
reg_df[,post_t:=fifelse(action_date_year_quarter>=as.Date('2011-04-27'),1,0)]
reg_df[,positive_delay:=ifelse(delay>0,1,0)]
reg_df[,negative_delay:=ifelse(delay<0,1,0)]

feols(wins_delay~treat_i+
        post_t:treat_i+
        wins_initial_duration+
        wins_initial_budget+
        wins_offers|action_date_year_quarter+
        awarding_sub_agency_code+
        product_or_service_code+
        naics_code+
        type_of_contract_pricing_code,
      cluster=~contract_award_unique_key,
      data=reg_df)
#      data=reg_df[!type_of_contract_pricing_code%in%c('J','L','M','B','K','A')])
  #    data=reg_df[price_structure=='Cost'])


small_contractors=unique(subset(reg_df,treat_i==1)$recipient_duns)
large_contractors=unique(subset(reg_df,treat_i==0)$recipient_duns)

reg_df[,treat_new:=case_when(treat_i==1 ~ 1, # all small projects are 1
                                 treat_i==0 & !(recipient_duns%in%small_contractors)~0, # only large projects w/o small project is zero
                                 treat_i==0 & recipient_duns%in%small_contractors~NaN)]


reg_df[, small_disad:= case_when(small_disadvantaged_business=="t" ~1,
                           small_disadvantaged_business=="f"~0)]
feols(wins_delay~treat_i+
           post_t:treat_i+
        small_disad+
        post_t:small_disad+
           treat_i:post_t:small_disad+
           wins_initial_duration+
           wins_initial_budget+
           wins_offers|action_date_year_quarter+
           awarding_sub_agency_code+
           product_or_service_code+
           naics_code+
           type_of_contract_pricing_code+
        recipient_duns,
         cluster=~contract_award_unique_key,
         data=reg_df[!(small_disad==1 & treat_i==0)])


reg_df[,started_after:=fifelse(initial_start_date>as.Date('2011-04-27'),1,0)]

feols(wins_delay~treat_new+
        started_after+
        treat_new:started_after+
        post_t:treat_new+
        treat_new:post_t:started_after+
        wins_initial_duration+
        wins_initial_budget+
        wins_initial_budget+
        post_t:wins_initial_duration+
        post_t:wins_initial_budget+
        post_t:wins_offers|action_date_year_quarter+
        product_or_service_code+
        naics_code+
        recipient_duns+
        awarding_sub_agency_code+
        type_of_contract_pricing_code,
      cluster=~contract_award_unique_key,
      data=reg_df[competitively_awarded_i==1])


feols(win)