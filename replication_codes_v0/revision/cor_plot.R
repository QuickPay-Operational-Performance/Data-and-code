
old_names=c('wins_percentage_delay',
'treat_new',
'post_t',
'project_signed_after_quickpay',
'winsorized_initial_duration_in_days_i',
'wins_number_of_offers_received',
'winsorized_initial_budget_i',
'task_inexperienced_i',
'new_entrant_i',
'inexp')

new_names=c('Delay',
            'Treat',
            'Post',
            'SA',
            'Duration',
            'Offers',
            'Budget',
            'Inexperienced',
            'New entrant',
            'Cts Inexp')

x=na.omit(reg_df_subset[competitively_awarded_i==1,
                        ..old_names])

setnames(x,old_names,new_names)

corrplot::corrplot(cor(x),method='color')