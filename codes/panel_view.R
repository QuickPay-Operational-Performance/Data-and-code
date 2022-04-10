df=fread(paste0(data_folder,'resampled_qp_data/qp_resampled_data_fy10_to_fy12_with_zero_obs.csv'))
df[,treated:=ifelse(business_type=="S" &
                      action_date_year_quarter>=as.Date('2011-04-27'),1,0)]

plot_df=df[,c('contract_award_unique_key',
              'action_date_year_quarter',
               'treated')]
plot_df[,time:=as.integer(format(action_date_year_quarter,'%Y%m'))]

panelview(plot_df[12320:12400,],
          D='treated',
          index=c('contract_award_unique_key',
                  'time'),
          axis.adjust=T,
          ylab='Project ID',
          xlab='Time',
          theme.bw=T)