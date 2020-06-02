## Script to read Intellect data
## Note: I changed the file types to .xlsx for all
## This is because CSVs were throwing an error in both Python and R
## It may be because excel files were saved with csv extension
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