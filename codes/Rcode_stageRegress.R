#############################################################################################
################################ PROJECT STAGE REGRESSION MODEL #############################
#############################################################################################

################################################################################
########################### DATA PROCESSING ####################################
##### OUTPUT: lm_data_all.csv: data including all delays #######################
#####         lm_data_nonzero.csv: data with nonzero delays ####################
################################################################################

stage <- read.csv("projStage_QP1.csv")
# read the project stage data
qtrDelay <- read.csv("delay.csv")
# read the quarterly delay data
delay <- qtrDelay[qtrDelay$proKey %in% stage$proKy,]
# consider the delays for projects with sensible stage information

axisT <- as.Date(substring(colnames(stage)[2:12],2), format = "%Y.%m.%d") 
# the time stamps

projData <- read.csv("qp_data_first_reported.csv")
# read in the initial characteristics of all projects
projData <- projData[projData$contract_award_unique_key %in% stage$proKy,]
# only keep the data on projects in "stage" variable

###############################################################################
########### Transform continuous stage into categorical variables #############
## Idea: In quarter t(=1~11), divide the projects into three groups based on ##
##       their stage.                                                        ##
###############################################################################
stage.div <- NULL
# store the 1/3 and 2/3 break points of stage in each quarter
stage.dummy <- NULL
# categorical stage dummy
# NA: project inactive in the _previous_ quarter. 
#     If a project has not started in previous quarter, then this implies NA delay.
#     If a project has ended in the previous quarter, then the delay would be zero.
# 0:  early stage compared to other projects at the same quarter
# 1:  middle stage compared to other projects at the same quarter
# 2:  late stage compared to other projects at the same quarter
for (i in 1:11)
{
  tmp <- sort(stage[!(is.na(stage[,i+1])),i+1])
  # sort the non-NA elements of quarter i stage
  tmp.len <- length(tmp)
  stage.div <- rbind(stage.div, c(tmp[round(tmp.len/3)], tmp[round(2*tmp.len/3)]))
  # find the 1/3 and 2/3 break points
  dummy <- stage[,i+1]
  dummy[stage[,i+1] <= stage.div[i,1]] <- 0
  dummy[stage[,i+1] > stage.div[i,1] & stage[,i+1] <= stage.div[i,2]] <- 1
  dummy[stage[,i+1] > stage.div[i,2]] <- 2
  stage.dummy <- cbind(stage.dummy, dummy)
}
colnames(stage.dummy) <- as.character(axisT)
stage.div <- t(stage.div)
# col. i: (1st tercile, 2nd tercile) of quarter i stage

########################################################################
################ Reshape data matrices for regression ##################
########################################################################
getCols <- c("recipient_duns", 
             "product_or_service_code",
             "naics_code",
             "extent_competed_code",
             "contract_financing_code",
             "small_business"
)
# the columns to get as controls

lm.data<- NULL
# data frame = [proKey, Quarterly delay, Project stage dummy, Action time]
for (i in 1:11)
{
  ind <- !(is.na(stage.dummy[,i])) & !(is.na(delay[,i+1]))
  # TRUE if project is active in quarter i:  has started in the
  # previous quarter and has not ended, which is indicated by "stage"
  tmp.d <- delay[ind,c(1,i+1)]
  # take out [projKey, Qrtr i delay] when the project is active
  tmp.s <- stage.dummy[ind,i]
  # take out the stage.dummy of quarter i 
  Qrtr <- rep(axisT[i],nrow(tmp.d))
  # the quarter
  
  ind <- projData$contract_award_unique_key %in% tmp.d[,1]
  # true if a project is active (included in tmp.d)
  tmp <- data.frame(tmp.d, tmp.s, Qrtr, projData[ind,getCols])
  # combine delay with stage dummy and time stamp
  colnames(tmp)[2:4] <- c("Delay", "Stage", "Action_time")
  lm.data <- rbind(lm.data, tmp)
  # stack on existing data frame
}

write.csv(lm.data, "lm_data_all.csv", row.names=FALSE)

#############################################################################################
########################### NONZERO DELAY EXPLORATORY ANALYSIS ##############################
#############################################################################################
id.nonzero <- which(!(lm.data$Delay ==0))
# find the rows with nonzero quarterly delays
tmp <- lm.data$Delay[id.nonzero]
# take out all the nonzero delays
length(tmp)
# 36,224 vs 322,834 in total

LB<- sort(tmp)[round(length(tmp)*0.025)+1]
# LB = -188
UB<- sort(tmp)[round(length(tmp)*0.975)+1]
# UB = 709

tmp.trun <- tmp[tmp >= LB & tmp <= UB] 
# discard the lower and upper 2.5% of the data to avoid outliers
hist(tmp.trun, breaks = 100, main="Histogram of non-zero quarterly delay", 
      xlab="quarterly delay (truncated at 2.5% and 97.5%)")

id.nonzero.trun <- id.nonzero[tmp >= LB & tmp <= UB]
# the row ids of nonzero, non-outlier delays

#############################################################################################
##################### AVG. QUARTERLY DELAY OF SMALL AND LARGE BUSINESSES ####################

data.nonzero <- lm.data[id.nonzero.trun,]
obs.num.s <- sapply(axisT, function(x) sum(data.nonzero$Action_time %in% x & data.nonzero$small_business== 1))
obs.num.l <- sapply(axisT, function(x) sum(data.nonzero$Action_time %in% x & data.nonzero$small_business== 0))
# number of small and large businesses obs. in each quarter
obs.num <- data.frame(obs.num.s, obs.num.l)

delay.avg.s <- sapply(axisT, function(x) 
  mean(data.nonzero$Delay[data.nonzero$Action_time %in% x & data.nonzero$small_business== 1]))
delay.avg.l <- sapply(axisT, function(x) 
  mean(data.nonzero$Delay[data.nonzero$Action_time %in% x & data.nonzero$small_business== 0]))
# average quarterly delay of small and large businesses
delay.avg <- data.frame(delay.avg.s, delay.avg.l)

par(mar=c(6,5,1,1))
plot(1:11, delay.avg.s, type="b", pch=15, col="red", xlab="", ylab="Avg. quarterly delay (days)", xaxt="n")
lines(1:11, delay.avg.l, type="b", pch=19, col="black")
legend("topleft", c("Small", "Non-small"), col=c("red", "black"), pch=c(15,19), lwd=1)
lines(rep(5.5,2), c(120,205), type="l", col="grey", lwd=4)
axis(1, at = 1:11, labels=axisT, las=2)

################################## PARALLEL TREND ASSUMPTION ################################
data.nonzero$Stage <- as.factor(data.nonzero$Stage)
data.nonzero$Action_time <- as.factor(data.nonzero$Action_time)
data.nonzero$recipient_duns <- as.factor(data.nonzero$recipient_duns)
# convert the stage and small business indicators into factors

time <- rep(0, nrow(data.nonzero))
for (i in 1:length(axisT))
{# set up a continuous time covariate to investigate the time trend
  time[data.nonzero$Action_time %in% as.factor(axisT[i])] <- i
}

data.nonzero.aug <- data.frame(data.nonzero, time)
# add the continuous time covariate to the data frame

length(unique(data.nonzero$recipient_duns))
# Result: 6,490 different firms
summary(as.numeric(table(data.nonzero$recipient_duns)))
#    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#  1.000   1.000   2.000   5.303   4.000 795.000 
# only two obs. for about 50% of the all firms. Should not use firm-level fixed effects

length(unique(data.nonzero$product_or_service_code))
# Result: 955 different PSCs
summary(as.numeric(table(data.nonzero$product_or_service_code)))
#    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#   1.00    2.00    4.00   36.03   14.00  2644.00

length(unique(data.nonzero$naics_code))
# Result: 62 different NAICS
summary(as.numeric(table(data.nonzero$naics_code)))
#  Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
# 1.00    14.25   101.50   555.05   409.75 10034.00 

lm.trend <- lm(Delay ~ Action_time + small_business + naics_code 
               + product_or_service_code + Stage + small_business*time, 
               data= data.nonzero.aug[data.nonzero$Action_time %in% as.factor(axisT[1:5]),])
tmp <- coef(summary(lm.trend))
tmp[nrow(tmp),]
# estimation results for the interaction term

lm.trend <- lm(Delay ~ Action_time + small_business + naics_code 
               + Stage + small_business*time, 
               data= data.nonzero.aug[data.nonzero$Action_time %in% as.factor(axisT[1:5]),])
tmp <- coef(summary(lm.trend))
tmp[nrow(tmp),]

# Result: statistically insignificant interaction term under different configurations

# NOTE: THE STANDARD ERRORS ARE NOT ROBUST HERE. PROBABLY NEED TO CHANGE. BUT THE RESULT WOULD NOT
# BE DIFFERENT AS THE CURRENT MODEL IGNORES CLUSTERING AND WOULD UNDER-ESTIMATE THE STD. ERR. THUS,
# ADDING CLUSTERING WOULD ONLY MAKE THE COEFFICIENT EVEN MORE INSIGNIFICANT.

#############################################################################################
################################ BASELINE REGRESSION ########################################
#############################################################################################
post <- 1-as.numeric(data.nonzero$Action_time %in% as.factor(axisT[1:5]))
# Post-treatment indicator
data.nonzero.post <- data.frame(data.nonzero, post)
# as the post variable

write.csv(data.nonzero.post, "lm_data_nonzero.csv", row.names=FALSE)

####################### SIMPLE LINEAR REGRESSION WITHOUT CLUSTERING #########################
lm.base <- lm(Delay ~ Action_time + small_business + small_business:post, data= data.nonzero.post)
summary(lm.base)

lm.stage <- lm(Delay ~ Action_time + small_business + Stage + small_business:post, data= data.nonzero.post)
summary(lm.stage)

lm.naics <- lm(Delay ~ Action_time + small_business + Stage + naics_code + small_business:post, 
               data= data.nonzero.post)
summary(lm.naics)

lm.psc <- lm(Delay ~ Action_time + small_business + Stage + naics_code + product_or_service_code
             + small_business*post, data= data.nonzero.post)
tmp <- coef(summary(lm.psc))
tmp[nrow(tmp),]

############################# LINEAR REGRESSIONS WITH CLUSTERING ##############################
# clustering at the NAICS code level

library(lfe)

lm.base0.cl <- felm(Delay~ small_business:post + small_business + post | 0 | 0 | naics_code, 
                   data=data.nonzero.post,
                   exactDOF = TRUE,
                   cmethod ="reghdfe")
summary(lm.base0.cl)


lm.base.cl <- felm(Delay~ small_business:post + small_business | Action_time | 0 | naics_code, 
                   data=data.nonzero.post,
                   exactDOF = TRUE,
                   cmethod ="reghdfe")
summary(lm.base.cl)


lm.stage.cl <- felm(Delay~ small_business:post + small_business | Action_time + Stage | 0 | naics_code, 
                   data=data.nonzero.post,
                   exactDOF = TRUE,
                   cmethod ="reghdfe")
summary(lm.stage.cl)


lm.naics.cl <- felm(Delay~ small_business:post + small_business | Action_time + Stage + naics_code | 0 | naics_code, 
                    data=data.nonzero.post,
                    exactDOF = TRUE,
                    cmethod ="reghdfe")
summary(lm.naics.cl)


lm.psc.cl <- felm(Delay~ small_business:post + small_business | Action_time + Stage + naics_code
                  + product_or_service_code | 0 | naics_code, 
                    data=data.nonzero.post,
                    exactDOF = TRUE,
                    cmethod ="reghdfe")
summary(lm.psc.cl)

# clustering at the psc code level

lm.base.cl.p <- felm(Delay~ small_business:post + small_business | Action_time | 0 | product_or_service_code, 
                   data=data.nonzero.post,
                   exactDOF = TRUE,
                   cmethod ="reghdfe")
summary(lm.base.cl.p)

lm.stage.cl.p <- felm(Delay~ small_business:post + small_business | Action_time + Stage | 0 | product_or_service_code, 
                     data=data.nonzero.post,
                     exactDOF = TRUE,
                     cmethod ="reghdfe")
summary(lm.stage.cl.p)

lm.naics.cl.p <- felm(Delay~ small_business:post + small_business | Action_time + Stage + naics_code 
                      | 0 | product_or_service_code, 
                      data=data.nonzero.post,
                      exactDOF = TRUE,
                      cmethod ="reghdfe")
summary(lm.naics.cl.p)

lm.psc.cl.p <- felm(Delay~ small_business:post + small_business | Action_time + Stage + naics_code + product_or_service_code
                      | 0 | product_or_service_code, 
                      data=data.nonzero.post,
                      exactDOF = TRUE,
                      cmethod ="reghdfe")
summary(lm.psc.cl.p)

hist(residuals(lm.psc.cl.p))

## Linear regression without the delays at 365 & 366

data.trun <- data.nonzero.post[!data.nonzero.post$Delay %in% c(365,366),]
# remove obs. with 365 and 366 days of delay

lm.trun0 <- felm(Delay~ small_business:post + small_business + post | 0 | 0 | naics_code, 
                    data=data.trun,
                    exactDOF = TRUE,
                    cmethod ="reghdfe")
summary(lm.trun0)


lm.trun <- felm(Delay~ small_business:post + small_business | Action_time | 0 | naics_code, 
                   data=data.trun,
                   exactDOF = TRUE,
                   cmethod ="reghdfe")
summary(lm.trun)


lm.trun.stage <- felm(Delay~ small_business:post + small_business | Action_time + Stage | 0 | naics_code, 
                    data=data.trun,
                    exactDOF = TRUE,
                    cmethod ="reghdfe")
summary(lm.trun.stage)


lm.trun.psc <- felm(Delay~ small_business:post + small_business | Action_time + Stage + naics_code
                  + product_or_service_code | 0 | naics_code, 
                  data=data.trun,
                  exactDOF = TRUE,
                  cmethod ="reghdfe")
summary(lm.trun.psc)


#############################################################################################
################################ STAGE-DEPENDENT REGRESSION #################################
#############################################################################################
#######
lmStage.base0.cl <- felm(Delay ~ small_business:post:Stage + small_business + small_business:post 
                        + small_business:Stage + post:Stage + post | Stage | 0 | product_or_service_code,
                        data=data.nonzero.post,
                        exactDOF = TRUE,
                        cmethod ="reghdfe")
summary(lmStage.base0.cl)

lmStage.trun0 <- felm(Delay ~ small_business:post:Stage + small_business + small_business:post 
                         + small_business:Stage + post:Stage + post | Stage | 0 | product_or_service_code,
                         data=data.trun,
                         exactDOF = TRUE,
                         cmethod ="reghdfe")
summary(lmStage.trun0)

#######
lmStage.base.cl <- felm(Delay ~ small_business:post:Stage + small_business + small_business:post 
                        + small_business:Stage + post:Stage | Action_time + Stage | 0 | product_or_service_code,
                        data=data.nonzero.post,
                        exactDOF = TRUE,
                        cmethod ="reghdfe")
summary(lmStage.base.cl)

lmStage.trun <- felm(Delay ~ small_business:post:Stage + small_business + small_business:post 
                        + small_business:Stage + post:Stage | Action_time + Stage | 0 | product_or_service_code,
                        data=data.trun,
                        exactDOF = TRUE,
                        cmethod ="reghdfe")
summary(lmStage.trun)

lmStage.naics.cl <- felm(Delay ~ small_business:post:Stage + small_business + small_business:post 
                        + small_business:Stage + post:Stage | Action_time + Stage + naics_code
                        | 0 | product_or_service_code,
                        data=data.nonzero.post,
                        exactDOF = TRUE,
                        cmethod ="reghdfe")
summary(lmStage.naics.cl)


lmStage.psc.cl <- felm(Delay ~ small_business:post:Stage + small_business + small_business:post 
                        + small_business:Stage + post:Stage | Action_time + Stage +product_or_service_code
                        | 0 | product_or_service_code,
                        data=data.nonzero.post,
                        exactDOF = TRUE,
                        cmethod ="reghdfe")
summary(lmStage.psc.cl)

lmStage.trun.psc <- felm(Delay ~ small_business:post:Stage + small_business + small_business:post 
                       + small_business:Stage + post:Stage | Action_time + Stage +product_or_service_code
                       | 0 | product_or_service_code,
                       data=data.trun,
                       exactDOF = TRUE,
                       cmethod ="reghdfe")
summary(lmStage.trun.psc)

## RESULT: the effect of QP on the extent of quarterly delay is not mediated by the project stage.

#############################################################################################
################################ LOGISTIC REGRESSION ########################################
#############################################################################################

################################## EXPLORATORY ANLAYSIS #####################################
data0 <- read.csv("lm_data_all.csv")

DelayFlag <- data0$Delay
DelayFlag[data0$Delay > 0] <- 1
DelayFlag[data0$Delay < 0] <- -1
# all delays are labeled 1 and expeditions are labeld -1

data <- data.frame(data0[,-2], DelayFlag)
data.s <- data[data$small_business==1,]
data.l <- data[data$small_business==0,]
# the subsets of small and large businesses

axisT <- unique(data$Action_time)

frac.delay.s <- sapply(axisT, function (x) 
  sum(data.s$DelayFlag[data.s$Action_time %in% x]==1)/sum(data.s$Action_time %in% x))
# the fraction of delays in all small businesses that are active in each quarter
frac.delay.l <- sapply(axisT, function (x) 
  sum(data.l$DelayFlag[data.l$Action_time %in% x]==1)/sum(data.l$Action_time %in% x))
# the fraction of delays in all large businesses that are active in each quarter
frac.delay <- data.frame(frac.delay.s, frac.delay.l)

frac.exp.s <- sapply(axisT, function (x) 
  sum(data.s$DelayFlag[data.s$Action_time %in% x]==-1)/sum(data.s$Action_time %in% x))
# the fraction of expeditions in all small businesses that are active in each quarter
frac.exp.l <- sapply(axisT, function (x) 
  sum(data.l$DelayFlag[data.l$Action_time %in% x]==-1)/sum(data.l$Action_time %in% x))
# the fraction of expeditions in all large businesses that are active in each quarter
frac.exp <- data.frame(frac.exp.s, frac.exp.l)


par(mfrow=c(2,2))

par(mar=c(6,5,1,1))
plot(1:11, frac.delay.s, type="b", pch=15, col="red", ylim=c(0.06,0.18), xlab="", ylab="Fraction of delayed projects", xaxt="n")
lines(1:11, frac.delay.l, type="b", pch=19, col="black")
legend("topleft", c("Small", "Non-small"), col=c("red", "black"), pch=c(15,19), lwd=1)
lines(rep(5.5,2), c(0.06,0.18), type="l", col="grey", lwd=4)
axis(1, at = 1:11, labels=axisT, las=2)

par(mar=c(6,5,1,1))
plot(1:11, frac.delay.s/frac.delay.s[1], type="b", pch=15, col="red", ylim=c(0.9,1.7), xlab="", 
     ylab="Change in faction of delayed projects", xaxt="n")
lines(1:11, frac.delay.l/frac.delay.l[1], type="b", pch=19, col="black")
legend("topleft", c("Small", "Non-small"), col=c("red", "black"), pch=c(15,19), lwd=1)
lines(rep(5.5,2), c(0.9,1.7), type="l", col="grey", lwd=4)
axis(1, at = 1:11, labels=axisT, las=2)

par(mar=c(6,5,1,1))
plot(1:11, frac.exp.s, type="b", pch=15, col="red", ylim=c(0.003,0.013), xlab="", 
     ylab="Fraction of expedited projects", xaxt="n")
lines(1:11, frac.exp.l, type="b", pch=19, col="black")
legend("bottomleft", c("Small", "Non-small"), col=c("red", "black"), pch=c(15,19), lwd=1)
lines(rep(5.5,2), c(0.003,0.013), type="l", col="grey", lwd=4)
axis(1, at = 1:11, labels=axisT, las=2)

par(mar=c(6,5,1,1))
plot(1:11, frac.exp.s/frac.exp.s[1], type="b", pch=15, col="red", ylim=c(0.4,1.3), xlab="", 
     ylab="Change in faction of expedited projects", xaxt="n")
lines(1:11, frac.exp.l/frac.exp.l[1], type="b", pch=19, col="black")
legend("topleft", c("Small", "Non-small"), col=c("red", "black"), pch=c(15,19), lwd=1)
lines(rep(5.5,2), c(0.4,1.3), type="l", col="grey", lwd=4)
axis(1, at = 1:11, labels=axisT, las=2)


#################################### LOGIT REGRESSION: package bife #######################################

library(bife)
# use the fixed effects package for logit models
# NO CLUSTERING OF ERRORS HERE

post <- rep(1,nrow(data))
post[data$Action_time %in% axisT[1:5]] <- 0
# the post indicator
data <- data.frame(data,post)
data.delay <- data
data.delay$DelayFlag[data$DelayFlag < 0] <- 0
# set expedition to 0

logit.base <- bife(DelayFlag ~ small_business + small_business:post | Action_time, 
                   data = data.delay)
summary(logit.base)


logit.stage <- bife(DelayFlag ~ small_business + small_business:post + factor(Stage) | Action_time, 
                   data = data.delay)
summary(logit.stage)


logit.naics <- bife(DelayFlag ~ small_business + small_business:post + factor(Stage) + factor(Action_time) 
                    | naics_code, data = data.delay)
summary(logit.naics)

#################################### LOGIT REGRESSION: package alpaca #######################################

library(alpaca)

######################################### BASE-MODEL REGRESSION ##########################################
#### GENERATES SAME RESULT AS bife package WHEN CLUSTERING IS NOT ADDED
#### The ROBUST ERROR ESTIMATOR (sandwich) DOES NOT SEEM TO CHANGE THE STD. ERR. MUCH
#### CLUSTERING DOES HAVE A BIG IMPACT

logit.base.al <- feglm(DelayFlag ~ small_business + small_business:post | Action_time | naics_code, 
                   data = data.delay)
summary(logit.base.al)
summary(logit.base.al, type="sandwich")
summary(logit.base.al, type="clustered", cluster = ~ naics_code)


logit.stage.al <- feglm(DelayFlag ~ small_business + small_business:post | Action_time + Stage| naics_code, 
                       data = data.delay)
summary(logit.stage.al)
summary(logit.stage.al, type="sandwich")
summary(logit.stage.al, type="clustered", cluster = ~ naics_code)


logit.naics.al <- feglm(DelayFlag ~ small_business + small_business:post | Action_time + Stage + naics_code
                        | naics_code, data = data.delay)
summary(logit.naics.al)
summary(logit.naics.al, type="sandwich")
summary(logit.naics.al, type="clustered", cluster = ~ naics_code)


logit.psc.al <- feglm(DelayFlag ~ small_business + small_business:post 
                        | Action_time + Stage + naics_code + product_or_service_code | naics_code, 
                        data = data.delay)
summary(logit.psc.al)
summary(logit.psc.al, type="sandwich")
summary(logit.psc.al, type="clustered", cluster = ~ naics_code)

##################### STAGE-DEPENDENT REGRESSION: WITH CLUTSERING ############################################
logitStage.base <- feglm(DelayFlag ~ small_business:post:Stage + small_business + small_business:post 
                        + small_business:Stage + post:Stage | Action_time + Stage 
                        | product_or_service_code + naics_code,
                        data=data.delay)
summary(logitStage.base, type="clustered", cluster = ~product_or_service_code)
summary(logitStage.base, type="clustered", cluster = ~naics_code)


logitStage.naics <- feglm(DelayFlag ~ small_business:post:Stage + small_business + small_business:post 
                         + small_business:Stage + post:Stage | Action_time + Stage + naics_code 
                         | product_or_service_code,
                         data=data.delay)
summary(logitStage.naics, type="clustered", cluster = ~product_or_service_code)
summary(logitStage.naics, type="clustered", cluster = ~naics_code)

logitStage.psc <- feglm(DelayFlag ~ small_business:post:Stage + small_business + small_business:post 
                          + small_business:Stage + post:Stage
                        | Action_time + Stage + naics_code + product_or_service_code,
                          data=data.delay)
summary(logitStage.psc, type="clustered", cluster = ~product_or_service_code)
summary(logitStage.psc, type="clustered", cluster = ~naics_code)

########################################################################################################
############################## LOGIT REGRESSION: EXPEDITION ############################################
########################################################################################################

data.exp <- data
data.exp$DelayFlag[data$DelayFlag>0] <- 0
data.exp$DelayFlag <- -data.exp$DelayFlag

######################################### BASE-MODEL REGRESSION ########################################
logit.base.exp <- feglm(DelayFlag ~ small_business:post + small_business | Action_time 
                        | naics_code + product_or_service_code, data=data.exp)
summary(logit.base.exp, type="clustered", cluster = ~naics_code)
summary(logit.base.exp, type="clustered", cluster = ~product_or_service_code)


logit.stage.exp <- feglm(DelayFlag ~ small_business:post + small_business | Action_time + Stage 
                         | naics_code + product_or_service_code,
                        data=data.exp)
summary(logit.stage.exp, type="clustered", cluster = ~naics_code)
summary(logit.stage.exp, type="clustered", cluster = ~product_or_service_code)


logit.naics.exp <- feglm(DelayFlag ~ small_business:post + small_business | Action_time + Stage + naics_code 
                         | product_or_service_code, data=data.exp)
summary(logit.naics.exp, type="clustered", cluster = ~naics_code)
summary(logit.naics.exp, type="clustered", cluster = ~product_or_service_code)


logit.psc.exp <- feglm(DelayFlag ~ small_business:post + small_business | Action_time + Stage + naics_code 
                         + product_or_service_code,
                         data=data.exp)
summary(logit.psc.exp, type="clustered", cluster = ~naics_code)
summary(logit.psc.exp, type="clustered", cluster = ~product_or_service_code)


##################################### STAGE-DEPENDENT REGRESSION #######################################
logitStage.base.exp <- feglm(DelayFlag ~ small_business:post:Stage + small_business + small_business:post 
                         + small_business:Stage + post:Stage | Action_time + Stage 
                         | naics_code + product_or_service_code,
                         data=data.exp)
summary(logitStage.base.exp, type="clustered", cluster = ~naics_code)
summary(logitStage.base.exp, type="clustered", cluster = ~product_or_service_code)


logitStage.naics.exp <- feglm(DelayFlag ~ small_business:post:Stage + small_business + small_business:post 
                             + small_business:Stage + post:Stage | Action_time + Stage + naics_code 
                             | product_or_service_code,
                             data=data.exp)
summary(logitStage.naics.exp, type="clustered", cluster = ~naics_code)
summary(logitStage.naics.exp, type="clustered", cluster = ~product_or_service_code)


logitStage.psc.exp <- feglm(DelayFlag ~ small_business:post:Stage + small_business + small_business:post 
                              + small_business:Stage + post:Stage 
                            | Action_time + Stage + naics_code + product_or_service_code,
                              data=data.exp)
summary(logitStage.psc.exp, type="clustered", cluster = ~naics_code)
summary(logitStage.psc.exp, type="clustered", cluster = ~product_or_service_code)
