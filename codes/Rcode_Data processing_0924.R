data <- read.csv("qp_resampled_data_fy10_to_fy12.csv")
colnames(data)
#[1] "contract_award_unique_key" "action_date_year_quarter" 
#[3] "last_reported_start_date"  "last_reported_end_date"   
#[5] "last_reported_budget"      "business_type"    

proKy <- unique(data[,1])
# unique key of projects, 309,143 in total.

for (i in 2:4) {data[,i] <- as.Date(data[,i])}
# convert all dates into Date format

axisT <- sort(unique(data[,2]))
# 12 quarters in total
#  [1] "2009-12-31" "2010-03-31" "2010-06-30" "2010-09-30" "2010-12-31" "2011-03-31" "2011-06-30"
#  [8] "2011-09-30" "2011-12-31" "2012-03-31" "2012-06-30" "2012-09-30"

#########################################################################################################

############################### INITIALIZATION ####################################
dataN <- matrix("NA", nrow=length(proKy), ncol=length(axisT)+2)
colnames(dataN) <- c(as.character(axisT), "First_start_date", "Small")
# columns 1-12 store the last_reported_end_date as of the date at the colnames
# col. 13 stores the first observed start date in the data
# col. 14 stores the indicator for small business

############################# DATA PROCESSING ###########################################################
dataN[,13] <- sapply(proKy, function(x) as.character(min(data[data[,1] %in% x,3])))
# use the earliest observed start date as the start date of the project
dataN[,14] <- sapply(proKy, function(x) as.character(unique(data[data[,1] %in% x,6])))
# the small business indicator of each project

for (i in 1:length(axisT)){
  # fill in the last reported project end date
  dataN[proKy %in% data[data[,2] %in% axisT[i],1],i] <- as.character(data[data[,2] %in% axisT[i],4])
}

dataC <- data.frame(proKy, dataN)
colnames(dataC)[2:13] <- as.character(axisT)

write.csv(dataC, "dataNew.csv", row.names=FALSE)

  