#############################################################################################
############################## N-QUARTER ANALYSIS WITH CLEANED DATA ########################
#############################################################################################

data <- read.csv("reg_df.csv")
data <- data[,-1]
# delete the first column, which consists of the row names

sum(data$delay==0, na.rm=TRUE)
# a total of 94,349 zero delay observations
sum(!is.na(data$delay))
# 127,056 delay obs. in total
# over 70% zeros in the data

################### TRUNCATE THE UPPER AND LOWER 2.5% OF QUARTERLY DELAY ################
data.noNA <- data[!is.na(data$delay),]
# only keep the rows with non-NA delays

delay.nonzero0 <- data.noNA$delay[!(data.noNA$delay==0)]

LB<- sort(delay.nonzero0)[round(length(delay.nonzero0)*0.025)+1]
# LB = -182
UB<- sort(delay.nonzero0)[round(length(delay.nonzero0)*0.975)+1]
# UB = 507

row.id <- which(data.noNA$delay >= LB & data.noNA$delay <= UB)
# row ids with truncated delay data
data.trun <- data.noNA[row.id,]
# discard the quarterly delays in the upper and lower 2.5% to avoid outliers
# includes zero delays

###################### Number of delays observed in a project #######################
delay.nonzero0 <- data.trun[!(data.trun$delay==0), ]
# nonzero delays after truncating at 2.5% and 97.5%
tmp <- unique(delay.nonzero0[,c("contract_award_unique_key", "business_type")])
id.s <- tmp[tmp$business_type %in% "S",1]
id.l <- tmp[tmp$business_type %in% "O",1]
# small and large business project IDs

freq <- table(delay.nonzero0$contract_award_unique_key)
# number of quarterly delays reported in each project over 10 quarters
freq.s <- freq[rownames(freq) %in% id.s]
# small projects frequency
freq.l <- freq[rownames(freq) %in% id.l]
# large projects frequency

count <- table(freq)
count.s <- table(freq.s)
count.l <- table(freq.l)
frac <- count/length(freq)*100
frac.s <- count.s/length(freq.s)*100
frac.l <- count.l/length(freq.l)*100
freq.data <- cbind(count, frac, cumsum(frac))
colnames(freq.data)[3] <- "cumu"
cbind(count.s, frac.s, cumsum(frac.s))
cbind(count.l, frac.l, cumsum(frac.l))

projID1 <- rownames(freq[freq==1])
projID2 <- rownames(freq[freq==2])
projID3 <- rownames(freq[freq==3])
projID4 <- rownames(freq[freq >= 4])
# number of projects with delays in two and three quarters

delaySep.2 <- sapply(projID2, function(x) 
  floor(diff(as.Date(delay.nonzero0[delay.nonzero0[,1] %in% x,2]))/90))
# find the number of quarters between delays with projects with two delays
cbind(table(delaySep.2), table(delaySep.2)/length(delaySep.2)*100)

#########################################################################################
################################ TOTAL DELAY OVER N QUARTERS ############################
#########################################################################################

axisT <- sort(unique(data.trun$action_date_year_quarter))
# end of each quarter

demoCol <- c("contract_award_unique_key", "business_type", "recipient_duns", "naics_code", 
             "product_or_service_code",
             "number_of_offers_received", "contract_financing_i", 
             "competitively_awarded_i", "period_of_performance_start_date", 
             "initial_duration_in_days_i")
# the demographic info of each project

demoData <- unique(data.trun[,demoCol])
# data set with demographic info of each project
# 43,879-by-10 data frame

################################ N-QUATERLY DELAY  ###############################

data.nQ <- list()
# a list of data frames with n-quarter delays (n=1,2,4)
data.nQ[[1]] <- data.trun
# element 1: data frame with quarterly delay
colnames(data.nQ[[1]])[2] <- "quarter"

for (q in 2:3){
  # create dataframes with q-quarterly delays and put it in data.nQ[[q]]
  delay.tmp <- NULL
  if (q == 2){
    # half-year delay case
    # get one yr before and one yr after QP
    axisT.tmp <- axisT
    axisT.id <- c(2,4,6,8)
    # drop the first and last quarter in the obs. horizon. Consider half-years immediately 
    # before & after QP
    # To drop the half-year interval from 2011-03-31 to 2011-06-30 that covers QP, set c(1,3,7,9)
  } else {
    # annual delay case
    # get one yr before and one yr after QP
    axisT.tmp <- axisT[c(2,4,6,8)]
    axisT.id <- c(1,3)
    # get the first and third half-year
  }    
    for (i in 1:length(axisT.id)){
      # compute the half-year delay that starts at axisT.tmp[i]
      tmp1 <- data.nQ[[q-1]][data.nQ[[q-1]]$quarter %in% axisT.tmp[axisT.id[i]], c("contract_award_unique_key", "delay")]
      # take out all projects and their quarterly delays in axisT.tmp[i] (if a project is not in tmp1,
      # then it does not have quarterly delay in axisT.tmp[i])
      tmp2 <- data.nQ[[q-1]][data.nQ[[q-1]]$quarter %in% axisT.tmp[axisT.id[i]+1],c("contract_award_unique_key", "delay")]
      # take out all projects and their quarterly delays in quarter axisT[i+1]
      inter <- merge(tmp1, tmp2, by="contract_award_unique_key")
      # projects that have quarter delays in both quarters
      delay <- inter[,2]+inter[,3]
      # add the delays in two consecutive quarters
      tmp3 <- data.frame(inter[,1],delay)
      # the delay information of projects with delay in both quarters
      colnames(tmp3)[1] <- colnames(tmp1)[1]
      tmp <- rbind(tmp3, tmp1[!(tmp1[,1] %in% inter[,1]),], tmp2[!(tmp2[,1] %in% inter[,1]),])
      # combine tmp3 with projects that have only one quarterly delay
      
      quarter <- rep(axisT.tmp[axisT.id[i]], dim(tmp)[1])
      
      delay.tmp <- rbind(delay.tmp, data.frame(tmp, quarter))
    }
    data.nQ[[q]] <- merge(delay.tmp, demoData, by="contract_award_unique_key", all.x=TRUE)
    # merge the demographic information with the bi-quarterly delay
}

##########################################################################################
################################ DESCRIPTIVE ANALYSIS ####################################
##########################################################################################

data.nonzero <- lapply(data.nQ, function (x) x[!(x$delay==0),])
# list of dataframes for nonzero n-quarter delays 
axisT.list <- lapply(data.nQ, function (x) sort(unique(x$quarter)))
# the list of axisT

obs.num <- list()
# a list storing number of small and non-small businesses in each quarter with 
# n quarter delays
delay.avg.s <- list()
delay.avg.l <- list()
# list of average nonzero delays

for (q in 1:length(data.nQ)){
  obs.num.s <- sapply(axisT.list[[q]], function(x) sum(data.nonzero[[q]]$quarter %in% x & 
                                               data.nonzero[[q]]$business_type %in% "S"))
  obs.num.l <- sapply(axisT.list[[q]], function(x) sum(data.nonzero[[q]]$quarter %in% x & 
                                               data.nonzero[[q]]$business_type %in% "O"))
  # number of small and large businesses obs. in each quarter
  obs.num[[q]] <- data.frame(obs.num.s, obs.num.l)
  
  delay.avg.s[[q]] <- sapply(axisT.list[[q]], function(x) 
    mean(data.nonzero[[q]]$delay[data.nonzero[[q]]$quarter %in% x & 
                                   data.nonzero[[q]]$business_type %in% "S"]))
  delay.avg.l[[q]] <- sapply(axisT.list[[q]], function(x) 
    mean(data.nonzero[[q]]$delay[data.nonzero[[q]]$quarter %in% x & 
                                   data.nonzero[[q]]$business_type %in% "O"]))
  # average quarterly delay of small and large businesses
}

################################ QUARTERLY DELAY ####################################
hist(data.nonzero[[1]]$delay,breaks=100)

par(mar=c(6,5,1,1),mfrow=c(2,1))
plot(1:10, delay.avg.s[[1]], type="b", pch=15, col="red", xlab="", ylab="Avg. quarterly delay (days)", 
     xaxt="n", ylim=c(60,150))
lines(1:10, delay.avg.l[[1]], type="b", pch=19, col="black")
legend("topleft", c("Small", "Non-small"), col=c("red", "black"), pch=c(15,19), lwd=1)
lines(rep(5.5,2), c(60,150), type="l", col="grey", lwd=4)
axis(1, at = 1:10, labels=axisT, las=2)

plot(1:10, delay.avg.s[[1]]/delay.avg.s[[1]][1], type="b", pch=15, col="red", xlab="", 
     ylab="Normalized avg. quarterly delay (days)", 
     xaxt="n")
lines(1:10, delay.avg.l[[1]]/delay.avg.l[[1]][1], type="b", pch=19, col="black")
legend("topleft", c("Small", "Non-small"), col=c("red", "black"), pch=c(15,19), lwd=1)
lines(rep(5.5,2), c(0,3), type="l", col="grey", lwd=4)
axis(1, at = 1:10, labels=axisT, las=2)

########################################## BI-QUARTERLY DELAY ####################################

hist(data.nonzero[[2]]$delay,breaks=100)

par(mar=c(6,5,1,1), mfrow=c(2,1))
plot(1:length(axisT.list[[2]]), delay.avg.s[[2]], type="b", pch=15, col="red", xlab="", ylab="Avg. bi-quarterly delay (days)", 
     xaxt="n", ylim=c(85,135))
lines(1:length(axisT.list[[2]]), delay.avg.l[[2]], type="b", pch=19, col="black")
#legend("topleft", c("Small", "Non-small"), col=c("red", "black"), pch=c(15,19), lwd=1)
lines(rep(2.5,2), c(85,135), type="l", col="grey", lwd=4)
axis(1, at = 1:length(axisT.list[[2]]), labels=axisT.list[[2]], las=2)

plot(1:length(axisT.list[[2]]), delay.avg.s[[2]]/delay.avg.s[[2]][1], type="b", pch=15, col="red", xlab="", 
     ylab="Normalized avg. bi-quarterly delay (days)", xaxt="n")
lines(1:length(axisT.list[[2]]), delay.avg.l[[2]]/delay.avg.l[[2]][1], type="b", pch=19, col="black")
#legend("topleft", c("Small", "Non-small"), col=c("red", "black"), pch=c(15,19), lwd=1)
lines(rep(2.5,2), c(0,2), type="l", col="grey", lwd=4)
axis(1, at = 1:length(axisT.list[[2]]), labels=axisT.list[[2]], las=2)

##########################################################################################
##########################################################################################
######################## LINEAR REGRESSION ON NONZERO DELAYS #############################
##########################################################################################
##########################################################################################

library(lfe)
#################### DATA PREP: LIST OF DATAFRAMES OF NONZERO DELAYS #####################

data.lm <- list()
# list that stores nonzero delays over N-quarters (N=1,2,3,4)

for (q in 1:length(data.nonzero)){
  if (q==1){
    # the quarterly delay data, rename post_t to post and treat_i to treat
    colnames(data.nonzero[[q]])[9:10] <- c("post","treat")
    data.lm[[q]] <- data.nonzero[[q]]
  } else {# delay with 2 or 4 quarters
    tmp <- data.nonzero[[q]]
    # drop quarters
    post <- rep(0, dim(tmp)[1])
    post[tmp$quarter %in% axisT[6:10]] <- 1
    # the post variable
    treat <- rep(0, dim(tmp)[1])
    treat[tmp$business_type %in% "S"] <- 1
    # the treat variable
    
    data.lm[[q]] <- data.frame(tmp, post, treat)
  }
}

#########################################################################################
######### TRIPLE-INTERACTION LINEAR REGRESSION ON QUARTERLY NONZERO DELAYS ##############
######### USING ENTIRE DATA SET                                            ##############
#########################################################################################

post_qrtr <- rep(0, length(data.lm[[1]]$post))
# initiate the vector that stores the number of quarters after QP launch

for (i in 7:10){
  # set post_qrtr as the number of quarters after the 1st quarter post QP, i.e., 2006 quarter 2
  post_qrtr[data.lm[[1]]$quarter %in% axisT[i]] <- i-6
}

post_qrtr <- as.factor(post_qrtr)
data.lm[[1]] <- data.frame(data.lm[[1]], post_qrtr)

######## clustering at the NAICS code level ##########

lm.base0.aug <- felm(delay~ treat:post + treat + post + post_qrtr + treat:post_qrtr
                     | 0 | 0 | naics_code, 
                     data=data.lm[[1]],
                     exactDOF = TRUE,
                     cmethod ="reghdfe")
summary(lm.base0.aug)


lm.base.aug <- felm(delay~ treat:post + treat + treat:post_qrtr | quarter | 0 | naics_code, 
                    data=data.nonzero[[1]],
                    exactDOF = TRUE,
                    cmethod ="reghdfe")
summary(lm.base.aug)


lm.psc.aug <- felm(delay~ treat:post + treat  + treat:post_qrtr
                   | quarter + naics_code + product_or_service_code | 0 | naics_code, 
                   data=data.nonzero[[1]],
                   exactDOF = TRUE,
                   cmethod ="reghdfe")
summary(lm.psc.aug)

######## clustering at the PSC code level ##########

lm.base0.aug1 <- felm(delay~ treat:post + treat + post + post_qrtr + treat:post_qrtr
                      | 0 | 0 | product_or_service_code, 
                      data=data.nonzero[[1]],
                      exactDOF = TRUE,
                      cmethod ="reghdfe")
summary(lm.base0.aug1)


lm.base.aug1 <- felm(delay~ treat:post + treat + treat:post_qrtr 
                     | quarter | 0 | product_or_service_code, 
                     data=data.nonzero[[1]],
                     exactDOF = TRUE,
                     cmethod ="reghdfe")
summary(lm.base.aug1)


lm.psc.aug1 <- felm(delay~ treat:post + treat  + treat:post_qrtr
                    | quarter + naics_code + product_or_service_code | 0 | product_or_service_code, 
                    data=data.nonzero[[1]],
                    exactDOF = TRUE,
                    cmethod ="reghdfe")
summary(lm.psc.aug1)


#########################################################################################
######### TRIPLE-INTERACTION LINEAR REGRESSION ON QUARTERLY NONZERO DELAYS ##############
######### USING PROJECTS THAT DELAY ONLY ONCE                              ##############
#########################################################################################

data.lm.1d <- data.lm[[1]][data.lm[[1]]$contract_award_unique_key %in% projID1,]
# consider projects that delay only once over the entire observation horizon

######## clustering at the NAICS code level ##########

lm.base0.1d <- felm(delay~ treat:post + treat + post + post_qrtr + treat:post_qrtr
                     | 0 | 0 | naics_code, 
                     data=data.lm.1d,
                     exactDOF = TRUE,
                     cmethod ="reghdfe")
summary(lm.base0.1d)


lm.base.1d- felm(delay~ treat:post + treat + treat:post_qrtr | quarter | 0 | naics_code, 
                    data=data.lm.1d,
                    exactDOF = TRUE,
                    cmethod ="reghdfe")
summary(lm.base.aug)


lm.naics.1d <- felm(delay~ treat:post + treat + treat:post_qrtr  
                     | quarter + naics_code | 0 | naics_code, 
                     data=data.lm.1d,
                     exactDOF = TRUE,
                     cmethod ="reghdfe")
summary(lm.naics.1d)


lm.psc.1d <- felm(delay~ treat:post + treat  + treat:post_qrtr
                   | quarter + naics_code + product_or_service_code | 0 | naics_code, 
                   data=data.lm.1d,
                   exactDOF = TRUE,
                   cmethod ="reghdfe")
summary(lm.psc.1d)

######## clustering at the PSC code level ##########

lm.base0.1d1 <- felm(delay~ treat:post + treat + post + post_qrtr + treat:post_qrtr
                      | 0 | 0 | product_or_service_code, 
                      data=data.lm.1d,
                      exactDOF = TRUE,
                      cmethod ="reghdfe")
summary(lm.base0.1d1)


lm.base.1d1 <- felm(delay~ treat:post + treat + treat:post_qrtr 
                     | quarter | 0 | product_or_service_code, 
                     data=data.lm.1d,
                     exactDOF = TRUE,
                     cmethod ="reghdfe")
summary(lm.base.1d1)


lm.naics.1d1<- felm(delay~ treat:post + treat + treat:post_qrtr  
                      | quarter + naics_code | 0 | product_or_service_code, 
                      data=data.lm.1d,
                      exactDOF = TRUE,
                      cmethod ="reghdfe")
summary(lm.naics.1d1)

lm.psc.1d1 <- felm(delay~ treat:post + treat  + treat:post_qrtr
                    | quarter + naics_code + product_or_service_code | 0 | product_or_service_code, 
                    data=data.lm.1d,
                    exactDOF = TRUE,
                    cmethod ="reghdfe")
summary(lm.psc.1d1)

#########################################################################################
############# LINEAR REGRESSION ON N-QUARTER NONZERO DELAYS (N=1,2,4) ###################
#########################################################################################

lm.base0 <- list()
# list of regression results without quarter fixed effects with N quarter delays
lm.base <- list()
# list of regression results with quarter fixed effects
lm.naics <- list()
# list of regression results with NAICS fixed effects
lm.psc <- list()
# list of regression results with PSC fixed effects

for (q in 1:length(data.lm)){# regressions on nonzero N-quarterly delays, clustering at psc code level
  lm.base0[[q]] <- felm(delay~ treat:post + treat + post | 0 | 0 | product_or_service_code, 
                       data=data.lm[[q]],
                       exactDOF = TRUE,
                       cmethod ="reghdfe")
  lm.base[[q]] <- felm(delay~ treat:post + treat | quarter | 0 | product_or_service_code, 
                     data=data.lm[[q]],
                     exactDOF = TRUE,
                     cmethod ="reghdfe")
  lm.naics[[q]] <- felm(delay~ treat:post + treat  | quarter + naics_code | 0 | product_or_service_code, 
                        data=data.lm[[q]],
                        exactDOF = TRUE,
                        cmethod ="reghdfe")
  lm.psc[[q]] <- felm(delay~ treat:post + treat | quarter + naics_code + product_or_service_code 
                      | 0 | product_or_service_code, 
                      data=data.lm[[q]],
                      exactDOF = TRUE,
                      cmethod ="reghdfe")
  }

summary(lm.psc[[1]])
summary(lm.psc[[2]])
summary(lm.psc[[3]])
#### RESULT: NO SIGNIFICANT DIFFERENCE, 
#### IMPLYING THAT A FIRM DOES NOT DELAY IN CONSECUTIVE QUARTERS (?) REPORTING 
#### A DELAY ONLY ONCE A YEAR?

##########################################################################################
##########################################################################################
######################## LOGISTIC REGRESSION ON NONZERO DELAYS ###########################
##########################################################################################
##########################################################################################

library(alpaca)

#################### DATA PREP: LIST OF DATAFRAMES OF LOGISTIC DELAYS ###################

data.logit <- list()
# the list of dataframes with logistic regression data under N-quarterly delays (N=1,2,3,4)

for (q in 1:length(data.nQ)){
  if (q==1){
    # the quarterly delay data, rename post_t to post and treat_i to treat
    colnames(data.nQ[[q]])[9:10] <- c("post","treat")
    tmp <- data.nQ[[q]]
  } else {# delay with 2 or 4 quarters
    tmp <- data.nQ[[q]]
    post <- rep(0, dim(tmp)[1])
    post[tmp$quarter %in% axisT[6:10]] <- 1
    # the post variable
    treat <- rep(0, dim(tmp)[1])
    treat[tmp$business_type %in% "S"] <- 1
    # the treat variable
    
    tmp <- data.frame(tmp, post, treat)
  }
  delayFlag <- tmp$delay
  # the delays over q quarters
  delayFlag[delayFlag>0] <- 1
  # set all delays to have flag 1
  delayFlag[delayFlag<0] <- -1
  # set all expedites to have flag -1
  
  data.logit[[q]] <- data.frame(tmp, delayFlag)
}

### list of dataframes for estimating delay and expedition probabilities, respectively
data.delay <- list()
data.exp <- list()
for (q in 1:length(data.logit)){
  data.delay[[q]] <- data.logit[[q]]
  data.exp[[q]] <- data.logit[[q]]

  data.delay[[q]]$delayFlag[data.delay[[q]]$delayFlag < 0] <- 0
  # set all expeditions to zero so data.delay is binary, gives probability of having delays
  data.exp[[q]]$delayFlag[data.exp[[q]]$delayFlag > 0] <- 0
  data.exp[[q]]$delayFlag <- - data.exp[[q]]$delayFlag
}

#########################################################################################
#################################### DESCRIPTIVE ANALYSIS ###############################
#########################################################################################
frac.delay <- list()
frac.exp <- list()
# lists of dataframes storing the fractions of delays and expeditions over N quarters

for (q in 1:length(data.logit)){
  data.s <- data.logit[[q]][data.logit[[q]]$treat ==1,]
  data.l <- data.logit[[q]][data.logit[[q]]$treat ==0,]
  # the subsets of small and large businesses
  
  frac.delay.s <- sapply(axisT.list[[q]], function (x) 
    sum(data.s$delayFlag[data.s$quarter %in% x]==1)/sum(data.s$quarter %in% x))
  # the fraction of delays in all small businesses that are active in each quarter
  frac.delay.l <- sapply(axisT.list[[q]], function (x) 
    sum(data.l$delayFlag[data.l$quarter %in% x]==1)/sum(data.l$quarter %in% x))
  # the fraction of delays in all large businesses that are active in each quarter
  frac.delay[[q]] <- data.frame(frac.delay.s, frac.delay.l)
  
  frac.exp.s <- sapply(axisT.list[[q]], function (x) 
    sum(data.s$delayFlag[data.s$quarter %in% x]==-1)/sum(data.s$quarter %in% x))
  # the fraction of expeditions in all small businesses that are active in each quarter
  frac.exp.l <- sapply(axisT.list[[q]], function (x) 
    sum(data.l$delayFlag[data.l$quarter %in% x]==-1)/sum(data.l$quarter %in% x))
  # the fraction of expeditions in all large businesses that are active in each quarter
  frac.exp[[q]] <- data.frame(frac.exp.s, frac.exp.l)
}

#################### fractions of delay and expedition in one quarter ##################
par(mfrow=c(2,2))
par(mar=c(6,5,1,1))
plot(1:length(axisT.list[[1]]), frac.delay[[1]][,1], type="b", pch=15, col="red", 
     ylim=c(0.15,0.32), xlab="", ylab="Fraction of delayed projects", xaxt="n")
lines(1:length(axisT), frac.delay[[1]][,2], type="b", pch=19, col="black")
legend("topleft", c("Small", "Non-small"), col=c("red", "black"), pch=c(15,19), lwd=1)
lines(rep(5.5,2), c(0.15,0.32), type="l", col="grey", lwd=4)
axis(1, at = 1:length(axisT), labels=axisT, las=2)

par(mar=c(6,5,1,1))
plot(1:length(axisT), frac.delay[[1]][,1]/frac.delay[[1]][1,1], type="b", 
     pch=15, col="red", ylim=c(0.9,1.8), xlab="", 
     ylab="Change in faction of delayed projects", xaxt="n")
lines(1:length(axisT), frac.delay[[1]][,2]/frac.delay[[1]][1,2], type="b", 
      pch=19, col="black")
legend("topleft", c("Small", "Non-small"), col=c("red", "black"), pch=c(15,19), lwd=1)
lines(rep(5.5,2), c(0.9,1.8), type="l", col="grey", lwd=4)
axis(1, at = 1:length(axisT), labels=axisT, las=2)

par(mar=c(6,5,1,1))
plot(1:length(axisT), frac.exp[[1]][,1], type="b", pch=15, col="red", 
     ylim=c(0.008,0.024), xlab="", ylab="Fraction of expedited projects", xaxt="n")
lines(1:length(axisT), frac.exp[[1]][,2], type="b", pch=19, col="black")
legend("bottomleft", c("Small", "Non-small"), col=c("red", "black"), pch=c(15,19), lwd=1)
lines(rep(5.5,2), c(0.008,0.024), type="l", col="grey", lwd=4)
axis(1, at = 1:length(axisT), labels=axisT, las=2)

par(mar=c(6,5,1,1))
plot(1:length(axisT), frac.exp[[1]][,1]/frac.exp[[1]][1,1], type="b", pch=15, 
     col="red", 
     ylim=c(0.4,2.0), xlab="", ylab="Change in faction of expedited projects", xaxt="n")
lines(1:length(axisT), frac.exp[[1]][,2]/frac.exp[[1]][1,2], type="b", pch=19, 
      col="black")
legend("topleft", c("Small", "Non-small"), col=c("red", "black"), pch=c(15,19), lwd=1)
lines(rep(5.5,2), c(0.4,2.0), type="l", col="grey", lwd=4)
axis(1, at = 1:length(axisT), labels=axisT, las=2)

################## fractions of delay and expedition over two quarters ##################
par(mfrow=c(2,2))
par(mar=c(6,5,1,1))
plot(1:length(axisT.list[[2]]), frac.delay[[2]][,1], type="b", pch=15, col="red", 
     ylim=c(0.15,0.32), xlab="", ylab="Fraction of delayed projects", xaxt="n")
lines(1:length(axisT.list[[2]]), frac.delay[[2]][,2], type="b", pch=19, col="black")
legend("topleft", c("Small", "Non-small"), col=c("red", "black"), pch=c(15,19), lwd=1)
lines(rep(4.5,2), c(0.15,0.32), type="l", col="grey", lwd=4)
lines(rep(5.5,2), c(0.15,0.32), type="l", lty=2, col="grey", lwd=4)
axis(1, at = 1:length(axisT.list[[2]]), labels=axisT.list[[2]], las=2)

par(mar=c(6,5,1,1))
plot(1:length(axisT.list[[2]]), frac.delay[[2]][,1]/frac.delay[[2]][1,1], 
     type="b", pch=15, col="red", ylim=c(0.8,1.8), xlab="", 
     ylab="Change in faction of delayed projects", xaxt="n")
lines(1:length(axisT.list[[2]]), frac.delay[[2]][,2]/frac.delay[[2]][1,2], 
      type="b", pch=19, col="black")
legend("topleft", c("Small", "Non-small"), col=c("red", "black"), 
       pch=c(15,19), lwd=1)
lines(rep(4.5,2), c(0.8,1.8), type="l", col="grey", lwd=4)
lines(rep(5.5,2), c(0.8,1.8), type="l", lty=2, col="grey", lwd=4)
axis(1, at = 1:length(axisT.list[[2]]), labels=axisT.list[[2]], las=2)

par(mar=c(6,5,1,1))
plot(1:length(axisT.list[[2]]), frac.exp[[2]][,1], type="b", pch=15, col="red", 
     ylim=c(0.008,0.024), xlab="", ylab="Fraction of expedited projects", xaxt="n")
lines(1:length(axisT.list[[2]]), frac.exp[[2]][,2], type="b", pch=19, col="black")
legend("bottomleft", c("Small", "Non-small"), col=c("red", "black"), pch=c(15,19), lwd=1)
lines(rep(2.5,2), c(0.008,0.024), type="l", col="grey", lwd=4)
axis(1, at = 1:length(axisT.list[[2]]), labels=axisT.list[[2]], las=2)

par(mar=c(6,5,1,1))
plot(1:length(axisT.list[[2]]), frac.exp[[2]][,1]/frac.exp[[2]][1,1], 
     type="b", pch=15, col="red", ylim=c(0.5,2.0), xlab="", 
     ylab="Change in faction of expedited projects", xaxt="n")
lines(1:length(axisT.list[[2]]), frac.exp[[2]][,2]/frac.exp[[2]][1,2], 
      type="b", pch=19, col="black")
legend("topleft", c("Small", "Non-small"), col=c("red", "black"), 
       pch=c(15,19), lwd=1)
lines(rep(2.5,2), c(0.5,2.0), type="l", col="grey", lwd=4)
axis(1, at = 1:length(axisT.list[[2]]), labels=axisT.list[[2]], las=2)

#########################################################################################
############ TRIPLE-INTERACTION LOGISTIC REGRESSION ON QUARTERLY DELAYS #################
############ USING ALL PROJECTS                                         #################
#########################################################################################

post_qrtr <- rep(0, length(data.logit[[1]]$post))
# initiate the vector that stores the number of quarters after QP launch

for (i in 7:10){
  # set post_qrtr as the number of quarters after the 1st quarter post QP, i.e., 2006 quarter 2
  post_qrtr[data.logit[[1]]$quarter %in% axisT[i]] <- i-6
}

post_qrtr <- as.factor(post_qrtr)
data.delay[[1]] <- data.frame(data.delay[[1]], post_qrtr)
data.exp[[1]] <- data.frame(data.exp[[1]], post_qrtr)
# append the # of quarters post-QP to the quarterly data

######################################### DELAY REGRESSION ##########################################

logitDelay.base0.tr <- feglm(delayFlag ~ treat + treat:post + post_qrtr + post + treat:post_qrtr 
                             | 0 | naics_code + product_or_service_code, 
                             data = data.delay[[1]])
summary(logitDelay.base0.tr, type="clustered", cluster = ~ naics_code)
summary(logitDelay.base0.tr, type="clustered", cluster = ~ product_or_service_code)


logitDelay.base.tr <- feglm(delayFlag ~ treat + treat:post + treat:post_qrtr 
                            | quarter | naics_code + product_or_service_code, 
                            data = data.delay[[1]])
summary(logitDelay.base.tr, type="clustered", cluster = ~ naics_code)
summary(logitDelay.base.tr, type="clustered", cluster = ~ product_or_service_code)


logitDelay.naics.tr <- feglm(delayFlag ~ treat + treat:post + treat:post_qrtr | quarter + naics_code
                             | naics_code + product_or_service_code, data = data.delay[[1]])
summary(logitDelay.naics.tr, type="clustered", cluster = ~ naics_code)
summary(logitDelay.naics.tr, type="clustered", cluster = ~ product_or_service_code)


logitDelay.psc.tr <- feglm(delayFlag ~ treat + treat:post + treat:post_qrtr 
                           | quarter + naics_code + product_or_service_code
                           | naics_code, data = data.delay[[1]])
summary(logitDelay.psc.tr, type="clustered", cluster = ~ naics_code)
summary(logitDelay.psc.tr, type="clustered", cluster = ~ product_or_service_code)

#########################################################################################
############ TRIPLE-INTERACTION LOGISTIC REGRESSION ON QUARTERLY DELAYS #################
############ EXCLUDING PROJECTS THAT DELAY MORE THAN ONCE               #################
#########################################################################################

projID.drop <- union(union(projID2, projID3), projID4)
# project IDs with more than one delay
data.delay.1d <- data.delay[[1]][!(data.delay[[1]]$contract_award_unique_key %in% projID.drop),]

######################################### DELAY REGRESSION ##########################################

logitDelay.base0.tr1d <- feglm(delayFlag ~ treat + treat:post + post_qrtr + post + treat:post_qrtr 
                             | 0 | naics_code + product_or_service_code, 
                             data = data.delay.1d)
summary(logitDelay.base0.tr1d, type="clustered", cluster = ~ naics_code)
summary(logitDelay.base0.tr1d, type="clustered", cluster = ~ product_or_service_code)


logitDelay.base.tr1d <- feglm(delayFlag ~ treat + treat:post + treat:post_qrtr 
                            | quarter | naics_code + product_or_service_code, 
                            data = data.delay.1d)
summary(logitDelay.base.tr1d, type="clustered", cluster = ~ naics_code)
summary(logitDelay.base.tr1d, type="clustered", cluster = ~ product_or_service_code)


logitDelay.psc.tr1d <- feglm(delayFlag ~ treat + treat:post + treat:post_qrtr 
                           | quarter + naics_code + product_or_service_code
                           | naics_code, data = data.delay.1d)
summary(logitDelay.psc.tr1d, type="clustered", cluster = ~ naics_code)
summary(logitDelay.psc.tr1d, type="clustered", cluster = ~ product_or_service_code)

#########################################################################################
################## LOGISTIC REGRESSION ON N-QUARTERLY DELAYS ###################
#########################################################################################
logitDelay.base0 <- list()
logitDelay.base <- list()
logitDelay.naics <- list()
logitDelay.psc <- list()
# lists to store logistic regression results
for (q in 1:length(data.logit)){
  logitDelay.base0[[q]] <- feglm(delayFlag ~ treat + treat:post + post 
                            | 0 | naics_code + product_or_service_code + contract_award_unique_key, 
                            data = data.delay[[q]])
  logitDelay.base[[q]] <- feglm(delayFlag ~ treat + treat:post | quarter 
                                | naics_code + product_or_service_code, 
                                data = data.delay[[q]])
  logitDelay.naics[[q]] <- feglm(delayFlag ~ treat + treat:post | quarter + naics_code
                          | naics_code + product_or_service_code + contract_award_unique_key, 
                          data = data.delay[[q]])
  logitDelay.psc[[q]] <- feglm(delayFlag ~ treat + treat:post 
                               | quarter + naics_code + product_or_service_code
                               | contract_award_unique_key, data = data.delay[[q]])
}


  summary(logitDelay.psc[[1]], type="clustered", cluster = ~ naics_code)
  summary(logitDelay.psc[[2]], type="clustered", cluster = ~ naics_code)
  summary(logitDelay.psc[[3]], type="clustered", cluster = ~ naics_code)
  
  summary(logitDelay.psc[[1]], type="clustered", cluster = ~ product_or_service_code)
  summary(logitDelay.psc[[2]], type="clustered", cluster = ~ product_or_service_code)
  summary(logitDelay.psc[[3]], type="clustered", cluster = ~ product_or_service_code)
  
  summary(logitDelay.psc[[1]], type="clustered", cluster = ~ contract_award_unique_key)
  summary(logitDelay.psc[[2]], type="clustered", cluster = ~ contract_award_unique_key)
  summary(logitDelay.psc[[3]], type="clustered", cluster = ~ contract_award_unique_key)

  #########################################################################################
  ################## LOGISTIC REGRESSION ON N-QUARTERLY EXPEDITIONS ###################
  #########################################################################################
  logitExp.base0 <- list()
  logitExp.base <- list()
  logitExp.naics <- list()
  logitExp.psc <- list()
  # lists to store logistic regression results
  for (q in 1:length(data.exp)){
    logitExp.base0[[q]] <- feglm(delayFlag ~ treat + treat:post + post 
                                   | 0 | naics_code + product_or_service_code, 
                                   data = data.exp[[q]])
    logitExp.base[[q]] <- feglm(delayFlag ~ treat + treat:post | quarter 
                                  | naics_code + product_or_service_code, 
                                  data = data.exp[[q]])
    logitExp.naics[[q]] <- feglm(delayFlag ~ treat + treat:post | quarter + naics_code
                                   | naics_code + product_or_service_code, 
                                   data = data.exp[[q]])
    logitExp.psc[[q]] <- feglm(delayFlag ~ treat + treat:post 
                                 | quarter + naics_code + product_or_service_code
                                 | naics_code , data = data.exp[[q]])
  }
  
  
  summary(logitExp.psc[[1]], type="clustered", cluster = ~ naics_code)
  summary(logitExp.psc[[2]], type="clustered", cluster = ~ naics_code)
  summary(logitExp.psc[[3]], type="clustered", cluster = ~ naics_code)
  
  summary(logitExp.psc[[1]], type="clustered", cluster = ~ product_or_service_code)
  summary(logitExp.psc[[2]], type="clustered", cluster = ~ product_or_service_code)
  summary(logitExp.psc[[3]], type="clustered", cluster = ~ product_or_service_code)
  
  