# Code to obtain delays at the project level (NOT project quarter)

# Resampled data also does not show within-quarter change in delays, as we only report last end date in a quarter
# That is, suppose Project A was only active for one quarter
# Then its delay relative to previous quarter was NaN
# But it could have experienced delays within its short lifespan of say 2 months in the same quarter.

# Keep only projects whose start dates match with API one
projects_to_keep=fread(paste0(data_folder,'projects_to_keep.csv'))

full_df=fread('/Users/vibhutid_admin/Dropbox/data_quickpay/qp_data/qp_data_fy10_to_fy18.csv')

full_df_tr=full_df[,c('contract_award_unique_key',
                      'contracting_officers_determination_of_business_size_code',
                      'period_of_performance_start_date',
                      'period_of_performance_current_end_date',
                      'action_date',
                      'naics_code',
                      'product_or_service_code')]

full_df_tr=setDT(full_df_tr)
full_df_tr[,action_date:=as.Date(action_date)]
full_df_tr[,period_of_performance_current_end_date:=
             as.Date(period_of_performance_current_end_date)]
full_df_tr[,period_of_performance_start_date:=
             as.Date(period_of_performance_start_date)]
full_df_tr=full_df_tr[order(contract_award_unique_key,
                            action_date)]

full_df_tr=subset(full_df_tr,
                  action_date<as.Date('2012-07-01'))

full_df_tr=setDT(as.data.frame(full_df_tr) %>% 
  group_by(contract_award_unique_key) %>%
  dplyr::mutate(
    initial_end_date = dplyr::first(period_of_performance_current_end_date),
    eventual_end_date = dplyr::last(period_of_performance_current_end_date),
    initial_start_date = dplyr::first(period_of_performance_start_date)
  ))

full_df_tr[,delay:=as.numeric(eventual_end_date-initial_end_date)]
full_df_tr[,positive_delay:=ifelse(delay>0,1,0)]
full_df_tr[,negative_delay:=ifelse(delay<0,1,0)]
# 
# mean(full_df_tr$positive_delay,na.rm=T)
# sd(full_df_tr$positive_delay,na.rm=T)
# 
# mean(full_df_tr$negative_delay,na.rm=T)
# sd(full_df_tr$negative_delay,na.rm=T)

full_df_tr_2=subset(full_df_tr,
                    contract_award_unique_key%in%projects_to_keep$contract_award_unique_key)

mean(full_df_tr_2$positive_delay,na.rm=T)
sd(full_df_tr_2$positive_delay,na.rm=T)

#### DID ####

full_df_tr_2[,treat_i:=ifelse(contracting_officers_determination_of_business_size_code=="S",
                              1,0)]

full_df_tr_2[,post_t:=ifelse(initial_start_date>as.Date('2011-04-27'),
                              1,0)]

full_df_tr_2[,wins_delay:=Winsorize(delay,na.rm=T)]
baseline_reg=felm(wins_delay~treat_i+
                    post_t:treat_i+
                    post_t|
                    product_or_service_code+naics_code| # no fixed effects
                    0| # no IV
                    contract_award_unique_key, # clustered at project level
                  data=full_df_tr_2, 
                  exactDOF = TRUE, 
                  cmethod = "reghdfe")
tidy(baseline_reg)
