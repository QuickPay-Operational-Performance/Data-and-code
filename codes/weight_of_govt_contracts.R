rm(list = ls())
library(readxl)
library(dplyr)
library(data.table) 
library(knitr)

#### Read intellect data #### 
files <- list.files(path = "~/Dropbox/data_quickpay/qp_data/intellect_data", 
                    pattern = "*.xlsx", full.names = T)

# merge all files into one dataframe
df <- sapply(files, read_excel, simplify=FALSE) %>% 
  rbindlist(., fill = TRUE)

df$`D-U-N-S@ Number`<-as.numeric(gsub("-", "", df$`D-U-N-S@ Number`))

cols_needed=c("D-U-N-S@ Number",
              "Company Name",
              "2010 Sales Volume",
             "2011 Sales Volume",
             "2012 Sales Volume",
             "2013 Sales Volume",
             "2014 Sales Volume",
             "2015 Sales Volume",
             "2016 Sales Volume" ,
             "2017 Sales Volume" ,
             "2018 Sales Volume" )

data=df[,..cols_needed]

sales_df = melt(data, id.vars = c("D-U-N-S@ Number","Company Name"),
             measure.vars = cols_needed[3:11])

sales_df[ , ("value") := lapply(.SD,  function(x) as.numeric(gsub("[,$]", "", x))),
          .SDcols = "value"]

sales_df[, sales_year:=as.numeric(substr(variable, start = 1, stop = 4))]

#### Read USASpending data #### 

dft=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_fy10_to_fy18.csv',
         select = c("contract_award_unique_key",
                    "recipient_duns",
                    "federal_action_obligation",
                    "action_date",
                    "contracting_officers_determination_of_business_size_code"))

dft=dft[contracting_officers_determination_of_business_size_code%in%c("O","S")]

dft[, action_date:=as.Date(action_date)]
dft[, action_date_calendar_year:=as.numeric(format(action_date,'%Y'))]
dft[, recipient_duns:=as.numeric(recipient_duns)]

# group by recipient duns and year, and add all federal action obligations
fao=dft[, 
            lapply(.SD, sum),
            .SDcols = c("federal_action_obligation"),
            by = c("recipient_duns","action_date_calendar_year")] 

setnames(fao, c("federal_action_obligation"), 
         c("sum_federal_action_obligation"))

#### Merge the two datasets ####
govt_weight_per_recipient=merge(x=fao,y=sales_df,
      by.x=c("recipient_duns","action_date_calendar_year"),
      by.y=c("D-U-N-S@ Number","sales_year"))[]

setnames(govt_weight_per_recipient, c("variable","value"), 
         c("sales_year","sales_volume"))

govt_weight_per_recipient[, fao_weight:= ifelse(is.finite(sum_federal_action_obligation) & sales_volume>0,
                                                sum_federal_action_obligation/sales_volume, NaN)]
                            
#### get contracts info #### 

# get unique values based on contract ID and year
dft_contracts_only=unique(dft[,c("contract_award_unique_key",
                "action_date_calendar_year",
                "recipient_duns",
                "contracting_officers_determination_of_business_size_code")],
         by=c("contract_award_unique_key",
                "action_date_calendar_year"))

# merge with sales info
contracts_share_of_govt=merge(dft_contracts_only,govt_weight_per_recipient,
                         by=c("recipient_duns","action_date_calendar_year"))[]

#### summary #### 

# summarize based on small and large businesses
fao_weight_summary=contracts_share_of_govt[, 
        lapply(.SD, mean, na.rm=TRUE),
        .SDcols = c("sum_federal_action_obligation",
                    "sales_volume"),
        by = c("action_date_calendar_year",
               "contracting_officers_determination_of_business_size_code")] 
setnames(fao_weight_summary, c("sum_federal_action_obligation","sales_volume"), 
         c("mean_total_obligations","mean_sales_volume"))

fao_weight_summary[,"obligations_to_sales_ratio":=mean_total_obligations/mean_sales_volume]

fao_weight_summary=fao_weight_summary[order(action_date_calendar_year)]
kable(fao_weight_summary)




