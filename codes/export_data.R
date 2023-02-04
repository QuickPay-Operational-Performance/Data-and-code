# after `clean_control` chunk in `qp_first_pc_clean_control_time_independent.R`

setnames(reg_df_subset,'number_of_offers_received','winsorized_number_of_offers_received')
setnames(reg_df_subset,'number_of_offers_received_original','number_of_offers_received')
reg_df_subset[,percentage_delay:=100*percentage_delay]

df_export=reg_df_subset[,!c('diff_end_date_and_action_date','initial_start_date','initial_end_date')]

fwrite(df_export,paste0(data_folder,'data_qp_clean_control_03-02-2023.csv'))