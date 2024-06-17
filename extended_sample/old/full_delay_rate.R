library(data.table)
library(fixest)
library(dplyr)
library(DescTools)
library(zoo)

#### Read data ####
keep_cols=c('contract_award_unique_key',
            'period_of_performance_current_end_date',
            'period_of_performance_start_date',
            'contracting_officers_determination_of_business_size_code',
            'base_and_all_options_value',
            'action_date',
            'naics_code',
            'recipient_duns',
            'awarding_sub_agency_code',
            'product_or_service_code',
            'type_of_contract_pricing_code',
            'small_disadvantaged_business',
            'number_of_offers_received',
            'action_type_code',
            'type_of_set_aside')

# everything 
df1=fread("/Users/vibhutid_admin/Dropbox/USA_Spending_Downloads/award_data_archive_20200205/FY2010_097_Contracts_Full_20200205/FY2010_097_Contracts_Full_20200206_1.csv",
          select = keep_cols)
df2=fread("/Users/vibhutid_admin/Dropbox/USA_Spending_Downloads/award_data_archive_20200205/FY2010_097_Contracts_Full_20200205/FY2010_097_Contracts_Full_20200206_2.csv",
          select = keep_cols)
df3=fread("/Users/vibhutid_admin/Dropbox/USA_Spending_Downloads/award_data_archive_20200205/FY2011_097_Contracts_Full_20200205/FY2011_097_Contracts_Full_20200206_1.csv",
          select = keep_cols)
df4=fread("/Users/vibhutid_admin/Dropbox/USA_Spending_Downloads/award_data_archive_20200205/FY2011_097_Contracts_Full_20200205/FY2011_097_Contracts_Full_20200206_2.csv",
          select = keep_cols)
df5=fread("/Users/vibhutid_admin/Dropbox/USA_Spending_Downloads/award_data_archive_20200205/FY2012_097_Contracts_Full_20200205/FY2012_097_Contracts_Full_20200206_1.csv",
          select = keep_cols)
df6=fread("/Users/vibhutid_admin/Dropbox/USA_Spending_Downloads/award_data_archive_20200205/FY2012_097_Contracts_Full_20200205/FY2012_097_Contracts_Full_20200206_2.csv",
          select = keep_cols)

df_list=list(df1,df2,df3,df4,df5,df6)
df <- do.call("rbind", df_list)

df[,action_date:=as.Date(action_date)]
df[,period_of_performance_current_end_date:=as.Date(period_of_performance_current_end_date)]
df[,period_of_performance_start_date:=as.Date(period_of_performance_start_date)]

df=df[order(contract_award_unique_key,action_date)]

#### Get start and end quarters ####

start_end_dates=df[,.(first_action_date=first(action_date),
                      initial_start_date=first(period_of_performance_start_date),
                      initial_end_date=first(period_of_performance_current_end_date),
                      eventual_end_date=last(period_of_performance_current_end_date),
                      last_action_date=last(action_date)),
                   by='contract_award_unique_key']

start_end_dates[,start_time:=fifelse(first_action_date<=initial_start_date,
                                    first_action_date,
                                    initial_start_date)]
start_end_dates[,end_time:=fifelse(eventual_end_date<=last_action_date,
                                   eventual_end_date,
                                   last_action_date)]
start_end_dates[,start_quarter:=as.Date(as.yearqtr(start_time)+ 0.25) - 1]
start_end_dates[,end_quarter:=as.Date(as.yearqtr(end_time)+ 0.25) - 1]

start_end_dates[,start_quarter:=fifelse(start_quarter<=as.Date('2009-12-31'),
                                        as.Date('2009-12-31'),
                                        start_quarter)]

start_end_dates[,end_quarter:=fifelse(end_quarter>=as.Date('2012-06-30'),
                                        as.Date('2012-06-30'),
                                      end_quarter)]

start_end_dates=start_end_dates[start_quarter<=end_quarter]

# Function to get list of quarters between two dates
get_quarters <- function(start, end) {
  quarters <- seq(from = start, to = end, by = "3 months")
  return(quarters)
}

#### Get all active quarters ####

# Get all quarters during which a project was active
# takes a few minutes to run
start_end_dates[, active_quarters := list(list(get_quarters(start_quarter, 
                                                            end_quarter))), 
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

df[,action_date_year_quarter:=as.Date(as.yearqtr(action_date)+ 0.25) - 1]
df[,action_date_year_quarter:=fifelse(format(action_date_year_quarter,"%m")%in%
                                        c('01','03','05','07','08','10','12') &
                                        format(action_date_year_quarter,"%d")=='30',
                                      action_date_year_quarter+1,
                                      action_date_year_quarter)]

df[,action_date_year_quarter:=fifelse(format(action_date_year_quarter,"%d")=='01',
                                      action_date_year_quarter-1,
                                      action_date_year_quarter)]

#### Get last reported dates ####

last_reported=df[,.(last_reported_end_date=last(period_of_performance_current_end_date),
                    last_reported_start_date=last(period_of_performance_start_date)),
                 by=c('contract_award_unique_key',
                      'action_date_year_quarter')]

start_end_dates=merge(start_end_dates,
                      last_reported,
                      by=c('contract_award_unique_key','action_date_year_quarter'),
                      all.x=T)

# For N/A dates, take the most recently reported one by project ID
# start_end_dates[, last_reported_end_date :=
#                   na.locf(last_reported_end_date),
#                 by = contract_award_unique_key]
# 
# start_end_dates[, last_reported_start_date :=
#                   na.locf(last_reported_start_date),
#                 by = contract_award_unique_key]

### makeshift --- NOT accurate ####
start_end_dates[, last_reported_end_date :=
                  na.locf(last_reported_end_date)]

start_end_dates[, last_reported_start_date :=
                  na.locf(last_reported_start_date)]

#### Get first info ####

df=df[order(contract_award_unique_key,action_date)]

df_first=df[,.(initial_end_date = first(period_of_performance_current_end_date), 
               eventual_end_date = last(period_of_performance_current_end_date),
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
               action_type_code=first(action_type_code),
               type_of_set_aside=first(type_of_set_aside)),
            by='contract_award_unique_key']

df_first[,initial_duration:=as.numeric(initial_end_date-initial_start_date)]

df_first[,price_structure:=case_when(type_of_contract_pricing_code%in%c('J','L','M','B','K','A')~"Fixed",
                                     type_of_contract_pricing_code%in%c('U','R','S','T','V')~"Cost")]

df_first[,treat_i:=case_when(contracting_officers_determination_of_business_size_code=="S" &
                               small_disadvantaged_business=="f" ~ 1,
                             contracting_officers_determination_of_business_size_code=="O" &
                               small_disadvantaged_business=="f" ~ 0)]


reg_df=merge(start_end_dates,
             df_first,
             by='contract_award_unique_key',
             all.x=T)

reg_df=reg_df[action_date_year_quarter<=as.Date('2012-06-30')]

reg_df=reg_df[order(contract_award_unique_key,action_date_year_quarter)]

reg_df[,delay:=fifelse(contract_award_unique_key==lag(contract_award_unique_key),
                       as.numeric(last_reported_end_date-lag(last_reported_end_date)),
                       NaN)]
reg_df[,wins_delay:=Winsorize(delay,probs=c(0.01,0.99),na.rm=T)]
reg_df[,wins_initial_duration:=Winsorize(initial_duration,probs=c(0.05,0.95),na.rm=T)]
reg_df[,wins_initial_budget:=Winsorize(initial_budget,probs=c(0.05,0.95),na.rm=T)]
reg_df[,wins_offers:=Winsorize(number_of_offers_received,probs=c(0.05,0.95),na.rm=T)]
reg_df[,relative_delay:=delay/(1+initial_duration)]
reg_df[,wins_relative_delay:=Winsorize(relative_delay,probs=c(0.05,0.95),na.rm=T)]
reg_df[,post_t:=fifelse(action_date_year_quarter>=as.Date('2011-04-27'),1,0)]
reg_df[,positive_delay:=ifelse(delay>0,1,0)]
reg_df[,negative_delay:=ifelse(delay<0,1,0)]

reg_df[,project_quarter_stage:=ifelse(contract_award_unique_key==
                                        lag(contract_award_unique_key,1),
                                      as.numeric(lag(action_date_year_quarter,1)-
                                                   initial_start_date)/as.numeric(lag(last_reported_end_date,1)-
                                                                                    initial_start_date),
                                      NaN)]

# (action_date_year_quarter-90) to get beginning of the quarter
reg_df[,wins_project_quarter_stage:=Winsorize(project_quarter_stage,                    
                                              probs=c(0.05,0.95),
                                              na.rm=T)]

