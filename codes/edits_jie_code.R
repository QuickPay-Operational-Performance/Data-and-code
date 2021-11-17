# Run line 1-253 from Jie's code, then this... 

library(data.table)
library(DescTools)

#### Delays truncated at 2.5% ####

hist(data.lm[[1]]$delay,breaks=100)

lm.base0.aug <- felm(delay~ treat*post
                     | 0 | 0 | contract_award_unique_key, 
                     data=data.lm[[1]],
                     exactDOF = TRUE,
                     cmethod ="reghdfe")
summary(lm.base0.aug)

#### Winsorize on Truncated Data at 2.5% ####

trun_data=subset(data,delay!=0)
setDT(trun_data)[,wins_trun_2.5:=Winsorize(delay,na.rm=T,probs=c(0.025,0.975))]
hist(trun_data$wins_trun_2.5,breaks=100)

lm.base0.aug <- felm(wins_trun_2.5~ treat_i*post_t
                     | 0 | 0 | contract_award_unique_key,
                     data=trun_data,
                     exactDOF = TRUE,
                     cmethod ="reghdfe")
summary(lm.base0.aug)

#### Winsorize at 5% for full distribution #####

hist(subset(data,winsorized_delay!=0)$winsorized_delay,breaks=100)

lm.base0.aug <- felm(winsorized_delay~ treat_i*post_t | 0 | 0 | contract_award_unique_key,
                     data=subset(data,winsorized_delay!=0),
                     exactDOF = TRUE,
                     cmethod ="reghdfe")
summary(lm.base0.aug)
