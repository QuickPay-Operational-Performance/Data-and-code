df=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_first_matched_sample.csv')

# specify date columns
date_cols=c("action_date_year_quarter",
            "last_reported_start_date",
            "last_reported_end_date",
            "first_end_date",
            "first_start_date")
df[,(date_cols):= lapply(.SD, as.Date), .SDcols = date_cols]

# restrict to quarter ending June 30, 2012
df=subset(df,as.Date(action_date_year_quarter)<max(as.Date(df$action_date_year_quarter)))
# data is truncated at July 1, 2012 -- 
# so quarter ending Sept 30, 2012 will only have values as of July 1, 2012

# sort by contract id and date 
df=df[order(contract_award_unique_key,
            action_date_year_quarter)]

# determine quarter-to-quarter delay
df[,delay:=ifelse(contract_award_unique_key==lag(contract_award_unique_key,1), 
                  last_reported_end_date-lag(last_reported_end_date,1),NaN)]

# winsorize quarter-to-quarter delay
df[,winsorized_delay:=Winsorize(delay,na.rm=TRUE)]

#Post_t: A dummy that period t is post-treatment
df[,post_t:=ifelse(action_date_year_quarter>as.Date("2011-04-27"),1,0)]
# quickpay implemented on 27 April 2011. So all quarters starting 30 June 2011 will be in post-period

#Treat_i: A dummy that contract i is in the treatment group
df[,treat_i:=ifelse(business_type=="S",1,0)]
# quickpay was implemented for small business contracts
df[,winsorized_initial_duration:=Winsorize(as.numeric(first_end_date-first_start_date),na.rm=T)]
df[,winsorized_initial_budget_i:=Winsorize(base_and_all_options_value,na.rm=T)]

tidy(felm(winsorized_delay~treat_i+
            post_t:treat_i+
            winsorized_initial_duration+
            winsorized_initial_budget_i+
            number_of_offers_received+
            post_t:winsorized_initial_duration+
            post_t:winsorized_initial_budget_i+
            post_t:number_of_offers_received|
            product_or_service_code+action_date_year_quarter|
            0|
            contract_award_unique_key,
          data=df,
          weights=df$weight,
          exactDOF = TRUE, 
          cmethod = "reghdfe"))

