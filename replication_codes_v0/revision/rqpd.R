x=rqpd(winsorized_initial_duration_in_days_i~treat_i+
         treat_i:project_signed_after_quickpay+
         project_signed_after_quickpay|
         as.factor(product_or_service_code),
       #can only include one fixed effect at a time it seems 
       panel(lambda = 1, # penalty parameter (default)
             taus=c(0.05, 0.15, 0.25, 0.35, 0.45, 0.55,0.65,0.75,0.85), # (default)
             tauw=rep(1/9, 9), # (default)
             method="pfe"),
       data =reg_df_first_reported)

sum_x=summary.rqpd(x,se="boot")

mydf=sum_x$coefficients
mydf[rownames(mydf) %in% c('treat_i:project_signed_after_quickpay[0.1]',
                           'treat_i:project_signed_after_quickpay[0.25]',
                           'treat_i:project_signed_after_quickpay[0.5]',
                           'treat_i:project_signed_after_quickpay[0.75]',
                           'treat_i:project_signed_after_quickpay[0.9]'), ]  

