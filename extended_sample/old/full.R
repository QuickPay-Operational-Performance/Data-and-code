library(data.table)
library(fixest)
library(dplyr)
library(DescTools)
library(zoo)

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
dates=df[,.(initial_start_date=first(period_of_performance_start_date),
             initial_end_date=first(period_of_performance_current_end_date),
             eventual_end_date=last(period_of_performance_current_end_date)),
             by='contract_award_unique_key']
dates[,initial_duration:=as.numeric(initial_end_date-initial_start_date)]
dates[,delay:=as.numeric(eventual_end_date-initial_end_date)]
dates[,post_t:=ifelse(initial_end_date>as.Date('2011-04-27'),1,0)]
dates[,start_year_quarter:=as.Date(as.yearqtr(initial_start_date))]

dates=merge(dates,
            unique(df[,c('contract_award_unique_key',
                  'product_or_service_code',
                  'naics_code',
                  'contracting_officers_determination_of_business_size_code',
                  'awarding_sub_agency_code',
                  'type_of_contract_pricing_code',
                  'recipient_duns',
                  'small_disadvantaged_business',
                  'base_and_all_options_value',
                  'number_of_offers_received',
                  'action_type_code',
                  'type_of_set_aside')],
                  by='contract_award_unique_key'),
            by='contract_award_unique_key',
            all.x=T)

small_contractors=unique(dates[contracting_officers_determination_of_business_size_code=="S"]$recipient_duns)
large_contractors=unique(dates[contracting_officers_determination_of_business_size_code=="O"]$recipient_duns)


dates[,treat_new:=case_when(contracting_officers_determination_of_business_size_code=='S'~ 1,
                          contracting_officers_determination_of_business_size_code=='O' &
                             !(recipient_duns%in%small_contractors)~0)]

dates[,treat_i:=case_when(contracting_officers_determination_of_business_size_code=='S'~ 1,
                          contracting_officers_determination_of_business_size_code=='O'~0)]

dates[,initial_duration:=as.numeric(initial_end_date-initial_start_date)]
dates[,wins_initial_duration:=Winsorize(initial_duration,na.rm=T)]

dates[,initial_budget:=base_and_all_options_value]
dates[,wins_initial_budget:=Winsorize(initial_budget,na.rm=T)]

dates[,wins_offers:=Winsorize(number_of_offers_received,na.rm=T)]

dates[,wins_delay:=Winsorize(delay,probs=c(0.01,0.99),na.rm=T)]
m1=feols(wins_delay~treat_i*post_t+
        wins_initial_duration+
        wins_initial_budget+
        wins_offers+
        post_t:wins_initial_duration+
        post_t:wins_initial_budget+
        post_t:wins_offers|
        product_or_service_code+
        naics_code+
        awarding_sub_agency_code+
     #   recipient_duns+
        start_year_quarter,
        data=dates[action_type_code%in%c("M","") & 
                     type_of_set_aside=="NO SET ASIDE USED." & 
                     eventual_end_date<as.Date('2012-06-30')&
                     initial_start_date< initial_end_date &
                     small_disadvantaged_business=="f" &
                     type_of_contract_pricing_code=="J"])




