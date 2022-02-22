
df_first_reported[,action_date_year_quarter:=as.Date(as.yearqtr(action_date+0.25))-1]
df_plot=subset(df_first_reported,contract_award_unique_key%in%unique(reg_df$contract_award_unique_key))

#### Project Age Plots ####

mean_delay=reg_df[!is.na(project_quarter_age) 
                   & action_date_year_quarter<=as.Date('2012-06-30'), 
                   mean(log(project_quarter_age)),  
                   by = c('action_date_year_quarter',
                          'business_type')]
mean_delay[,year_quarter:=format(action_date_year_quarter,"%Y-%b")]
mean_delay[,business_type:=ifelse(business_type=="S",
                                  "Small","Large")]
mean_delay=mean_delay[order(action_date_year_quarter,-business_type)]

project_age=ggplot(mean_delay, aes(x=year_quarter,
                                   y=V1, 
                                   group = business_type))+
  geom_line(aes(linetype=business_type, color=business_type),
            alpha=0.7) +    
  scale_x_discrete(limits=mean_delay$year_quarter)+
  geom_point(aes(shape=business_type),size=1.5)+  
  annotate("text", label = "QuickPay", x = 16.5, y = 0.14,color="dimgrey")+
  geom_vline(xintercept = 14, linetype="solid", 
             color = "light gray", size=1)+  
  annotate("text", label = "JOBS act", x = 11.2, y = 0.13,color="dimgrey")+
  geom_vline(xintercept = 9, linetype="solid", 
             color = "light gray", size=1) +
  theme_minimal()+
  labs(x="Year-Quarter", y = "Average age of projects")+
  scale_linetype_manual(values=c("solid","dashed"))+
  scale_color_manual(values=c('gray','black'))+
  scale_shape_manual(values=c(1,2))+
  theme(axis.text.x = element_text(angle = 90),
        axis.line = element_blank(),
        panel.border = element_rect(fill=NA),
        panel.background = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())+
  ggtitle("Project age")

#### Contract Financing ####

mean_delay=df_first_reported[!is.na(contract_financing_i) 
                   & action_date_year_quarter<=as.Date('2012-06-30'), 
                   sum(contract_financing_i)/length(contract_financing_i),  
                   by = c('action_date_year_quarter',
                          'contracting_officers_determination_of_business_size_code')]
mean_delay[,year_quarter:=format(action_date_year_quarter,"%Y-%b")]
mean_delay[,business_type:=ifelse(contracting_officers_determination_of_business_size_code=="S",
                                  "Small","Large")]
mean_delay=mean_delay[order(action_date_year_quarter,-business_type)]

# Plot

cf=ggplot(mean_delay, aes(x=year_quarter,
                       y=V1, 
                       group = business_type))+
  geom_line(aes(linetype=business_type, color=business_type),
            alpha=0.7) +    
  scale_x_discrete(limits=mean_delay$year_quarter)+
  geom_point(aes(shape=business_type),size=1.5)+  
  annotate("text", label = "QuickPay", x = 16.5, y = 0.14,color="dimgrey")+
  geom_vline(xintercept = 14.2, linetype="solid", 
             color = "light gray", size=1)+  
  annotate("text", label = "JOBS act", x = 11.2, y = 0.13,color="dimgrey")+
  geom_vline(xintercept = 9.2, linetype="solid", 
             color = "light gray", size=1) +
  theme_minimal()+
  labs(x="Year-Quarter", y = "Proportion of projects \n receiving contract financing")+
  scale_linetype_manual(values=c("solid","dashed"))+
  scale_color_manual(values=c('gray','black'))+
  scale_shape_manual(values=c(1,2))+
  theme(axis.text.x = element_text(angle = 90),
        axis.line = element_blank(),
        panel.border = element_rect(fill=NA),
        panel.background = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())+
  ggtitle("Contract financing")

ggsave('~/Desktop/cf_plots.jpeg',width=8,height=5)

#### Receives Grants ####

df_first_reported[,gets_grants:=ifelse(receives_grants=='t',1,0)]
mean_delay=df_first_reported[!is.na(gets_grants) 
                             & action_date_year_quarter<as.Date('2012-06-30'), 
                             sum(gets_grants)/length(gets_grants),  
                             by = c('action_date_year_quarter',
                                    'contracting_officers_determination_of_business_size_code')]
mean_delay[,year_quarter:=format(action_date_year_quarter,"%Y-%b")]
mean_delay[,business_type:=ifelse(contracting_officers_determination_of_business_size_code=="S",
                                  "Small","Large")]
mean_delay=mean_delay[order(action_date_year_quarter,-business_type)]

# Plot

grants=ggplot(mean_delay, aes(x=year_quarter,
                          y=V1, 
                          group = business_type))+
  geom_line(aes(linetype=business_type, color=business_type),
            alpha=0.7) +    
  scale_x_discrete(limits=mean_delay$year_quarter)+
  geom_point(aes(shape=business_type),size=1.5)+  
  annotate("text", label = "QuickPay", x = 16.5, y = 0.14,color="dimgrey")+
  geom_vline(xintercept = 14.2, linetype="solid", 
             color = "light gray", size=1)+  
  annotate("text", label = "JOBS act", x = 11.2, y = 0.13,color="dimgrey")+
  geom_vline(xintercept = 9.2, linetype="solid", 
             color = "light gray", size=1) +
  theme_minimal()+
  labs(x="Year-Quarter", y = "Proportion of projects where \n contractor is said to receive grants")+
  scale_linetype_manual(values=c("solid","dashed"))+
  scale_color_manual(values=c('gray','black'))+
  scale_shape_manual(values=c(1,2))+
  theme(axis.text.x = element_text(angle = 90),
        axis.line = element_blank(),
        panel.border = element_rect(fill=NA),
        panel.background = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())+
  ggtitle("Receiving grants/assistance")

ggsave('~/Desktop/grants.jpeg',width=8,height=5)

#### Competition plots ####
mean_delay=df_plot[!is.na(competitively_awarded_i) 
                  & action_date_year_quarter<=as.Date('2012-06-30'), 
                  sum(competitively_awarded_i)/length(competitively_awarded_i),  
                  by = c('action_date_year_quarter',
                         'contracting_officers_determination_of_business_size_code')]
mean_delay[,year_quarter:=format(action_date_year_quarter,"%Y-%b")]
mean_delay[,business_type:=ifelse(contracting_officers_determination_of_business_size_code=="S",
                                   "Small","Large")]
mean_delay=mean_delay[order(action_date_year_quarter,-business_type)]

# Plot

competition=ggplot(mean_delay, aes(x=year_quarter,
                       y=V1, 
                       group = business_type))+
  geom_line(aes(linetype=business_type, color=business_type),
            alpha=0.7) +    
  scale_x_discrete(limits=mean_delay$year_quarter)+
  geom_point(aes(shape=business_type),size=1.5)+  
  annotate("text", label = "QuickPay", x = 16.5, y = 0.65,color="dimgrey")+
  geom_vline(xintercept = 14, linetype="solid", 
             color = "light gray", size=1)+  
  annotate("text", label = "JOBS act", x = 11.2, y = 0.65,color="dimgrey")+
  geom_vline(xintercept = 9, linetype="solid", 
             color = "light gray", size=1) +
  theme_minimal()+
  labs(x="Year-Quarter", y = "Proportion of projects \n competitively awarded")+
  scale_linetype_manual(values=c("solid","dashed"))+
  scale_color_manual(values=c('gray','black'))+
  scale_shape_manual(values=c(1,2))+
  theme(axis.text.x = element_text(angle = 90),
        axis.line = element_blank(),
        panel.border = element_rect(fill=NA),
        panel.background = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())+
  ggtitle("Competitive projects")

#### Number of projects ####

df_plot[,business_type:=contracting_officers_determination_of_business_size_code]
mean_delay=df_plot[action_date_year_quarter<=as.Date('2012-06-30'), 
                  n_distinct(contract_award_unique_key),  
                  by = c('action_date_year_quarter',
                         'business_type')]
mean_delay[,year_quarter:=format(action_date_year_quarter,"%Y-%b")]
mean_delay[,business_type:=ifelse(business_type=="S",
                                  "Small","Large")]
mean_delay=mean_delay[order(action_date_year_quarter,-business_type)]

num_projects=ggplot(mean_delay, aes(x=year_quarter,
                                   y=V1, 
                                   group = business_type))+
  geom_line(aes(linetype=business_type, color=business_type),
            alpha=0.7) +    
  scale_x_discrete(limits=mean_delay$year_quarter)+
  geom_point(aes(shape=business_type),size=1.5)+  
  annotate("text", label = "QuickPay", x = 16.5, y = 0.14,color="dimgrey")+
  geom_vline(xintercept = 14, linetype="solid", 
             color = "light gray", size=1)+  
  annotate("text", label = "JOBS act", x = 11.2, y = 0.13,color="dimgrey")+
  geom_vline(xintercept = 9, linetype="solid", 
             color = "light gray", size=1) +
  theme_minimal()+
  labs(x="Year-Quarter", y = "Number of projects")+
  scale_linetype_manual(values=c("solid","dashed"))+
  scale_color_manual(values=c('gray','black'))+
  scale_shape_manual(values=c(1,2))+
  theme(axis.text.x = element_text(angle = 90),
        axis.line = element_blank(),
        panel.border = element_rect(fill=NA),
        panel.background = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())+
  ggtitle("Num projects")

ggsave('~/Desktop/num_projects.jpeg',width=8,height=5,bg='white')
#### Number of offers ####

df_plot[,wins_num_offers:=Winsorize(number_of_offers_received,
                                    probs=c(0.05,0.95),
                                    na.rm=T)]
mean_delay=df_plot[competitively_awarded_i==1 & !is.na(wins_num_offers)
                   & action_date_year_quarter<=as.Date('2012-06-30'), 
                   mean(wins_num_offers),  
                   by = c('action_date_year_quarter',
                          'contracting_officers_determination_of_business_size_code')]
mean_delay[,year_quarter:=format(action_date_year_quarter,"%Y-%b")]
mean_delay[,business_type:=ifelse(contracting_officers_determination_of_business_size_code=="S",
                                  "Small","Large")]
mean_delay=mean_delay[order(action_date_year_quarter,-business_type)]

# Plot

num_offers=ggplot(mean_delay, aes(x=year_quarter,
                       y=V1, 
                       group = business_type))+
  geom_line(aes(linetype=business_type, color=business_type),
            alpha=0.7) +    
  scale_x_discrete(limits=mean_delay$year_quarter)+
  geom_point(aes(shape=business_type),size=1.5)+  
  annotate("text", label = "QuickPay", x = 16.5, y = 3.25,color="dimgrey")+
  geom_vline(xintercept = 14, linetype="solid", 
             color = "light gray", size=1)+  
  annotate("text", label = "JOBS act", x = 11.2, y = 3.25,color="dimgrey")+
  geom_vline(xintercept = 9, linetype="solid", 
             color = "light gray", size=1) +
  theme_minimal()+
  labs(x="Year-Quarter", y = "Number of offers received \n for competitively awarded projects")+
  scale_linetype_manual(values=c("solid","dashed"))+
  scale_color_manual(values=c('gray','black'))+
  scale_shape_manual(values=c(1,2))+
  theme(axis.text.x = element_text(angle = 90),
        axis.line = element_blank(),
        panel.border = element_rect(fill=NA),
        panel.background = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())+
  ggtitle("Competitive projects:Initial offers")

#### Initial duration ####

df_plot[,wins_duration:=Winsorize(initial_duration_in_days_i,na.rm=T)]
mean_delay=df_plot[competitively_awarded_i==1 & !is.na(wins_duration)
                   & action_date_year_quarter<=as.Date('2012-06-30'), 
                   mean(wins_duration),  
                   by = c('action_date_year_quarter',
                          'contracting_officers_determination_of_business_size_code')]
mean_delay[,year_quarter:=format(action_date_year_quarter,"%Y-%b")]
mean_delay[,business_type:=ifelse(contracting_officers_determination_of_business_size_code=="S",
                                  "Small","Large")]
mean_delay=mean_delay[order(action_date_year_quarter,-business_type)]

# Plot

duration=ggplot(mean_delay, aes(x=year_quarter,
                       y=V1, 
                       group = business_type))+
  geom_line(aes(linetype=business_type, color=business_type),
            alpha=0.7) +    
  scale_x_discrete(limits=mean_delay$year_quarter)+
  geom_point(aes(shape=business_type),size=1.5)+  
  annotate("text", label = "QuickPay", x = 16.5, y = 0.65,color="dimgrey")+
  geom_vline(xintercept = 14, linetype="solid", 
             color = "light gray", size=1)+  
  annotate("text", label = "JOBS act", x = 11.2, y = 0.65,color="dimgrey")+
  geom_vline(xintercept = 9, linetype="solid", 
             color = "light gray", size=1) +
  theme_minimal()+
  labs(x="Year-Quarter", y = "Average initial duration \n for competitively awarded projects")+
  scale_linetype_manual(values=c("solid","dashed"))+
  scale_color_manual(values=c('gray','black'))+
  scale_shape_manual(values=c(1,2))+
  theme(axis.text.x = element_text(angle = 90),
        axis.line = element_blank(),
        panel.border = element_rect(fill=NA),
        panel.background = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())+
  ggtitle("Competitive projects:Initial duration")

#### Initial budget ####

df_plot[,wins_budget:=Winsorize(base_and_all_options_value,na.rm=T)]
mean_delay=df_plot[competitively_awarded_i==1 & !is.na(wins_budget)
                   & action_date_year_quarter<=as.Date('2012-06-30'), 
                   mean(wins_budget),  
                   by = c('action_date_year_quarter',
                          'contracting_officers_determination_of_business_size_code')]
mean_delay[,year_quarter:=format(action_date_year_quarter,"%Y-%b")]
mean_delay[,business_type:=ifelse(contracting_officers_determination_of_business_size_code=="S",
                                  "Small","Large")]
mean_delay=mean_delay[order(action_date_year_quarter,-business_type)]

# Plot

budget=ggplot(mean_delay, aes(x=year_quarter,
                       y=V1, 
                       group = business_type))+
  geom_line(aes(linetype=business_type, color=business_type),
            alpha=0.7) +    
  scale_x_discrete(limits=mean_delay$year_quarter)+
  geom_point(aes(shape=business_type),size=1.5)+  
  annotate("text", label = "QuickPay", x = 16.5, y = 0.65,color="dimgrey")+
  geom_vline(xintercept = 14, linetype="solid", 
             color = "light gray", size=1)+  
  annotate("text", label = "JOBS act", x = 11.2, y = 0.65,color="dimgrey")+
  geom_vline(xintercept = 9, linetype="solid", 
             color = "light gray", size=1) +
  theme_minimal()+
  labs(x="Year-Quarter", y = "Average initial budget \n for competitively awarded projects")+
  scale_linetype_manual(values=c("solid","dashed"))+
  scale_color_manual(values=c('gray','black'))+
  scale_shape_manual(values=c(1,2))+
  theme(axis.text.x = element_text(angle = 90),
        axis.line = element_blank(),
        panel.border = element_rect(fill=NA),
        panel.background = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())+
  ggtitle("Competitive projects:Initial budget")

library(ggpubr)

figure=ggarrange(cf,competition,num_offers,
          duration,budget,project_age,
          ncol=3, nrow=2,
          common.legend = TRUE, 
          legend="bottom",
          align='hv')

annotate_figure(figure,
                left = text_grob("Density/Proportion", color = "black", rot = 90)
)
ggsave("~/Desktop/plot.jpeg",
       bg="white",
       height=10, 
       width=13, 
       unit="in", 
       dpi=320)
