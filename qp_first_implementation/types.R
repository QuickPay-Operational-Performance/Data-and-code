# Run till `percentage_delay` block in RmD

#### Get concurrent small/large projects ####

two_type_contractors=reg_df[,n_distinct(treat_i),by='recipient_duns']
two_type_contractors=unique(subset(two_type_contractors,V1==2 &
                                     !is.na(recipient_duns))$recipient_duns)

# remove large projects of contractors with two types

reg_df3=subset(reg_df,!(treat_i==0 & recipient_duns%in%two_type_contractors))

#### Winsorize again in reg_df3 ####

reg_df3[,wins_percentage_delay:=Winsorize(100*percentage_delay,                    
                                         probs=c(0.05,0.95),
                                         na.rm=T)]

# time spent in the project so far/total time of the project
# if project was active in previous quarter
reg_df3[,project_quarter_stage:=ifelse(contract_award_unique_key==
                                         lag(contract_award_unique_key,1),
                                       as.numeric(lag(action_date_year_quarter,1)-initial_start_date)/as.numeric(lag(last_reported_end_date,1)-initial_start_date),NaN)]

# (action_date_year_quarter-90) to get beginning of the quarter

reg_df3[,wins_project_quarter_stage:=Winsorize(project_quarter_stage,                    
                                              probs=c(0.05,0.95),
                                              na.rm=T)]

# stage at end of quarter -- not using this!
reg_df3[,stage_aliter:=as.numeric(action_date_year_quarter-initial_start_date)/as.numeric(last_reported_end_date-initial_start_date)]

#### Financial constraint Regresssions ####

baseline_reg=felm(wins_percentage_delay~treat_i+
                    post_t:treat_i+
                    post_t+
                    receives_financial_assistance+
                    post_t:receives_financial_assistance+
                    treat_i:receives_financial_assistance+
                    post_t:treat_i:receives_financial_assistance|
                    0| # no fixed effects
                    0| # no IV
                    contract_award_unique_key, # clustered at project level
                  data=subset(reg_df3,
                              initial_start_date<=as.Date('2010-06-30')), 
                  exactDOF = TRUE, 
                  cmethod = "reghdfe")

controls_and_no_fe=felm(wins_percentage_delay~treat_i+
                          post_t+
                          log(wins_project_quarter_stage)+
                          post_t:treat_i+
                          treat_i:receives_financial_assistance+
                          receives_financial_assistance+
                          post_t:receives_financial_assistance+
                          post_t:treat_i:receives_financial_assistance+
                          log(1+winsorized_initial_duration_in_days_i)+
                          log(1+winsorized_initial_budget_i)+
                          number_of_offers_received+
                          post_t:log(1+winsorized_initial_duration_in_days_i)+
                          post_t:log(1+winsorized_initial_budget_i)+
                          post_t:number_of_offers_received|
                          0|
                          0|
                          contract_award_unique_key,
                        data=subset(reg_df3,
                                    initial_start_date<=as.Date('2010-06-30')), 
                        exactDOF = TRUE, 
                        cmethod = "reghdfe")

controls_and_time_fe=felm(wins_percentage_delay~treat_i+
                            log(wins_project_quarter_stage)+
                            post_t:treat_i+
                            receives_financial_assistance+ 
                            treat_i:receives_financial_assistance+
                            post_t:receives_financial_assistance+
                            post_t:treat_i:receives_financial_assistance+
                            log(1+winsorized_initial_duration_in_days_i)+
                            log(1+winsorized_initial_budget_i)+
                            number_of_offers_received+
                            post_t:log(1+winsorized_initial_duration_in_days_i)+
                            post_t:log(1+winsorized_initial_budget_i)+
                            post_t:number_of_offers_received|
                            action_date_year_quarter|
                            0|
                            contract_award_unique_key,
                          data=subset(reg_df3,
                                      initial_start_date<=as.Date('2010-06-30')), 
                          exactDOF = TRUE, 
                          cmethod = "reghdfe")

# time fixed effects also included in the following specs
controls_time_task_fe=felm(wins_percentage_delay~treat_i+
                             log(wins_project_quarter_stage)+
                             post_t:treat_i+
                             receives_financial_assistance+
                             treat_i:receives_financial_assistance+
                             post_t:receives_financial_assistance+
                             post_t:treat_i:receives_financial_assistance+
                             log(1+winsorized_initial_duration_in_days_i)+
                             log(1+winsorized_initial_budget_i)+
                             number_of_offers_received+
                             post_t:log(1+winsorized_initial_duration_in_days_i)+
                             post_t:log(1+winsorized_initial_budget_i)+
                             post_t:number_of_offers_received|
                             product_or_service_code+action_date_year_quarter|
                             0|
                             contract_award_unique_key,
                           data=subset(reg_df3,
                                       initial_start_date<=as.Date('2010-06-30')), 
                           exactDOF = TRUE, 
                           cmethod = "reghdfe")

controls_and_all_fe=felm(wins_percentage_delay~treat_i+
                           log(wins_project_quarter_stage)+
                           post_t:treat_i+
                           receives_financial_assistance+
                           treat_i:receives_financial_assistance+
                           post_t:receives_financial_assistance+
                           post_t:treat_i:receives_financial_assistance+
                           log(1+winsorized_initial_duration_in_days_i)+
                           log(1+winsorized_initial_budget_i)+
                           number_of_offers_received+
                           post_t:log(1+winsorized_initial_duration_in_days_i)+
                           post_t:log(1+winsorized_initial_budget_i)+
                           post_t:number_of_offers_received|
                           naics_code+product_or_service_code+action_date_year_quarter|
                           0|
                           contract_award_unique_key,
                         data=subset(reg_df3,
                                     initial_start_date<=as.Date('2010-06-30')), 
                         exactDOF = TRUE, 
                         cmethod = "reghdfe")

financial_assistance_table=stargazer(baseline_reg,
                                     controls_and_no_fe,
                                     controls_and_time_fe,
                                     controls_time_task_fe,
                                     controls_and_all_fe,
                                     digits=2,
                                     digits.extra=2,
                                     title = "Financial constraints and QuickPay reform",
                                     dep.var.labels="$PercentDelay_{it}$  ",
                                     dep.var.caption = "",
                                     covariate.labels =c("$Treat_i$",
                                                         "$Post_t$",
                                                         "$CF_i$",
                                                         "$Treat_i \\times Post_t$",
                                                         "$Post_t \\times CF_i$",
                                                         "$Treat_i \\times CF_i$",
                                                         "$Treat_i \\times Post_t \\times CF_i$",
                                                         "Constant"),
                                     object.names=FALSE, 
                                     model.numbers=TRUE,
                                     font.size = "small",
                                     omit.stat=c("f", "ser"),
                                     column.sep.width = "-2pt",
                                     add.lines = list(
                                       c("Duration, Budget, Bids",rep("No",1),rep("Yes",4)),
                                       c("$Post_t \\times $  (Duration, Budget, Bids)",rep("No",1),rep("Yes",4)),                           c("Project stage",rep("No",1),rep("Yes",4)),
                                       c("Time fixed effects",rep("No",2),rep("Yes",3)),
                                       c("Task fixed effects",rep("No",3),rep("Yes",2)),
                                       c("Industry fixed effects",rep("No",4),rep("Yes",1))),
                                     omit=c('winsorized_initial_duration_in_days_i',
                                            'winsorized_initial_budget_i',
                                            'number_of_offers_received',
                                            'post_t:winsorized_initial_duration_in_days_i',
                                            'post_t:winsorized_initial_budget_i',
                                            'post_t:number_of_offers_received',
                                            'wins_project_quarter_stage'),
                                     table.placement = "H",
                                     style="default",
                                     notes=c("Each observation is a project-quarter.",
                                             "SEs are robust and clustered at the project level.",
                                             "Large projects with a concurrent small project are removed.",
                                             "Sample restricted to projects that started before June 2010"),
                                     header=F)