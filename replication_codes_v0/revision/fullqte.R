ls_fl_quantiles <- seq(0.9,0.95,0.005)
fit_quantiles <- rq(wins_percentage_delay ~ treat_new+
                      post_t:treat_new+
                      post_t,
                    tau = ls_fl_quantiles,
                    data = reg_df_subset)

plot(fit_quantiles,
     parm=4,
     ols=F,
   #  ylim=c(0,30),
   #  xlim=c(0.05,0.95),
     xlab="Quantile",
     ylab="Treatment effect \n (Percentage delay rate)",
     mar=c(5.1, 5.1, 2.1, 2.1))