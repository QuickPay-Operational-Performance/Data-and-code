#############################################################################################
########################## COMPUTE THE PROJECT STAGE AT EACH QUARTER ########################
##### OUTPUT: projStage_QP1.csv
##### Col. 1:     project key
##### Col. 2-12:  project stage in quarter i-1
##### Col. 13:    project type
#############################################################################################

data <- read.csv("dataNew.csv")
# 309,143-by-15 data frame. Each row is a project
# col. 1:    project Key
# col. 2-13: last reported end date at the end of 12 quarters starting from 2009.12.31
# col. 14:   start date of each project
# col. 15:   whether the project is a small business

axisT <- as.Date(substring(colnames(data)[2:13],2), format = "%Y.%m.%d") 
# [1] "2009-12-31" "2010-03-31" "2010-06-30" "2010-09-30" "2010-12-31" "2011-03-31"
# [7] "2011-06-30" "2011-09-30" "2011-12-31" "2012-03-31" "2012-06-30" "2012-09-30" 

table(data$Small)
#      O      S 
# 120552 188591 

for (i in 2:14) { data[,i]<- as.Date(data[,i])  }
# convert the entries to date items

#####################################################################################################
#################################### COMPUTE THE QUARTERLY DELAY ####################################
### Output: qtrDelay (entry is NA only if the project has not started in the previous quarter)
#####################################################################################################

qtrDelay0 <- data[,3:13] - data[,2:12]
# find the quarterly delay in each of the 11 quarters starting from 2010.3.31
# An entry in tmp may be NA if the project has started but no actions reported 
# during the quarter, or if the project has not started yet. In the former case,
# the delay is 0. In the latter case, there is no delay.
qtrDelay <- qtrDelay0

tmp <- t(sapply(data$First_start_date, function(x) axisT - x>=0))
# compare the time axis with the starting date
# col. i (i=1~12) indicates whether each project has started as of axisT[i] (indicator=TRUE)
# If a project starts in the last quarter, then its delay will not be observed.
# So we only consider quarterly delays for projects that start in the first 11 quarters.

for (i in 1:11)
  # set the NA delays in qtrDelay to 0 if the project has always started at the previous quarter
{ 	qtrDelay[is.na(qtrDelay0[,i]) & tmp[,i], i] <- 0 	}

write.csv(delay, "delay.csv", row.names = FALSE)

#####################################################################################################
#################################### COMPUTE PROJECT DURATION #######################################
### Output: projTN = duration projected at the end of quarter 1~12
#####################################################################################################

startQtr <- rowSums(!tmp)+1
# the starting quarter of each project
table(startQtr)
#     1     2     3     4     5     6     7     8     9    10    11    12    13 
# 26409 24856 25575 38156 18367 20170 23164 37939 16811 19666 22988 34640   402 
# 26,409 projects start in or before the 1st quarter in the data
# 402 projects start after the last quarter in the data

idQtr13 <- which(startQtr ==13)
# remove projects that start after the last quarter in the data
dataN0 <- data[-idQtr13,]
qtrDelayN0 <- qtrDelay[-idQtr13,]
startQtrN0 <- startQtr[-idQtr13]

projT0 <- sapply(2:13, function(x) dataN0[,x] - dataN0[,14])
# the projected duration at axisT[1:12]: NAs 
projT <- projT0
# initialize

id0 <- rep(FALSE, nrow(projT0))
# initialize the indicator on whether a project's initial duration has been recorded
initT <- rep(0, nrow(projT0))
# store the first observed project duration: NAs or numerics
for (i in 1:11)
{# record the initial duration of all projects
  id <- !id0 & !is.na(projT0[,i])
  initT[id] <- projT0[id,i]
  id0 <- id0 | id
}

qtrDelayNum <- qtrDelayN0
for (i in 1:11)
{ # change the data type to numericals
  # col. i = quarter (i+1) end date - quarter (i) end date = delay in quarter i+1
  qtrDelayNum[,i] <- as.numeric(qtrDelayN0[,i])
}

for (i in 1:12)
{#  for all projects that start in quarter i (=1:12), find total delay in 1, 2,... quarters
  if (i<=10)
  {# if a project starts in quarter i (=1:10)
    cumDelay <- t(apply(qtrDelayNum[startQtrN0==i, i:11], 1, cumsum))
  }
    if (i == 11)
  {# if a project starts in quarter 11, then only observe one delay in quarter 12, i.e., col. 11
    cumDelay <- qtrDelayNum[startQtrN0==i, i]
  }
    # find the cumulative delay from the starting quarter for projects that start in quarter i
  if (i<=11)
  {# if a project starts in the first 11 quarters, then we observe at least one quarterly delay
    projT[startQtrN0==i, i] <- initT[startQtrN0==i]
    # the initial project duration when it starts or in Qtr1 if the project starts before the first obs. quarter
    projT[startQtrN0==i, (i+1):12] <- initT[startQtrN0==i] + cumDelay
    # find the project duration
    # col. i = projected end date at the end of quarter i
  }
  if (i==12)
  {# if a project starts in quarter 12, then no delay is observed.
    projT[startQtrN0==i,i] <- initT[startQtrN0==i]
    # if the project starts in quarter 12, then the last projected duration is the initial projection
  }
}
# col. i of projT: projected duration at the end of quarter i
# the last column of projT (col. 12) is the final projected duration in the observation horizon

id <- which(initT == 0)
# find the projects whose first observed duration = 0
# 45,418 in total
projTN<- projT[-id,]
# remove the projects with zero initial duration
dataN <- dataN0[-id,]
qtrDelayN <- qtrDelayN0[-id,]
# remove projects with zero initial project duration

#####################################################################################################
#################################### COMPUTE PROJECT STAGE  #########################################
### Output: stage = stage of project in quarter 2~12, before deciding the delay. NA in stage means 
###         that either the project has not started in previous quarter, or that the project has ended.
#####################################################################################################

projEnd <- sapply(2:12, function(i) axisT[i]-dataN$First_start_date>= projTN[,12])
# col. i = indicator of whether a project has ended by quarter i, by comparing against the last projected duration

timeSpent <- projEnd
# initialize the matrix that stores the time spent at each observation point for the projects
for (i in 1:11)
{
  timeSpent[,i] <- axisT[i+1]-dataN$First_start_date
  # if the project is still on-going at the observation time (quarter 2-12), then compute the time spent in the project
  # col. i: num of days between end of quarter (i+1) and the starting date
  timeSpent[projEnd[,i],i] <- NA
  # if the project has ended at an observation time point, then reset the timeSpent to NA
}

stage <- timeSpent/projTN[,1:11]
# project stage
# NA in stage means that either the project has not started, in which case projTN is NA, 
# or that the project has ended, in which case timeSpent is NA.

stage.aug <- data.frame(dataN$proKy, stage, dataN$Small)
colnames(stage.aug) <- c("proKy", as.character(axisT[2:12]), "Small")
table(stage.aug$Small)
#      O      S 
#  101194 162458 

boxplot(stage.aug[, 2:12], outline=F, ylim=c(-0.5,3), main="All business")

par(mfrow=c(1,2))
boxplot(stage.aug[stage.aug$Small %in% 'O', 2:12], outline=F, ylim=c(-0.5,3), main="Non-small business")
boxplot(stage.aug[stage.aug$Small %in% 'S', 2:12], outline=F, ylim=c(-0.5,3), main="Small business")

stage.med <- sapply(1:11, function(i) median(stage[,i], na.rm=TRUE))
# find the median of in each quarter
stage.med.s <- sapply(1:11, function(i) median(stage[stage.aug$Small %in% 'S',i], na.rm=TRUE))
stage.med.o <- sapply(1:11, function(i) median(stage[stage.aug$Small %in% 'O',i], na.rm=TRUE))

par(mfrow=c(1,1))
plot(1:11, stage.med, type="b", pch=15, col="black", xlab="Quarter", ylab="Median project stage", ylim=c(0.45,0.85))
lines(1:11, stage.med.s, type="b", pch=19, col="red")
lines(1:11, stage.med.o, type="b", pch=17, col="blue")
lines(rep(5.5,2), c(0.45,0.85), type="l", col="grey", lwd=4)
legend("topleft", c("All", "Small", "Non-small"), col=c("black", "red", "blue"), pch=c(15,19,17), lwd=1)

boxplot(stage.aug[, 2:12], outline=F, ylim=c(-0.5,3), main="All business")

write.csv(stage.aug, "projStage_QP1.csv", row.names=FALSE)

