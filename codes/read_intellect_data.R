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

df_contracts=read.csv('/Users/vibhutidhingra/Dropbox/data_quickpay/full_sample_recipient_duns.csv',
                      stringsAsFactors = FALSE)

df1=df[,-c(3:5)] # almost all values are null for these columns so remove them 

#### Sales & Employee columns
duns_needed=na.omit(df1[,1:27])$`D-U-N-S@ Number`
# look at not null values for employee & sales columns
nrow(subset(df_contracts,recipient_duns%in%duns_needed))

nrow(subset(df_contracts,recipient_duns%in%duns_needed &
  contracting_officers_determination_of_business_size=="SMALL BUSINESS"))

#### All columns
duns_needed2=na.omit(df1)$`D-U-N-S@ Number`
nrow(subset(df_contracts,recipient_duns%in%duns_needed2))

nrow(subset(df_contracts,recipient_duns%in%duns_needed2&
              contracting_officers_determination_of_business_size=="SMALL BUSINESS"))



