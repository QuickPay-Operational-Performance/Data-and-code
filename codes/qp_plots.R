project_age=ggplot(reg_df, 
      aes(x=log(project_quarter_age), 
          linetype=business_type)) +
  geom_density(color="black",size=0.3)+  
  theme_minimal()+ 
  theme(panel.border = element_rect(color="black",fill=NA), 
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), 
        axis.title=element_blank(),
        plot.title = element_text(hjust = 0.5))+ 
  labs(linetype='Business type')+
  theme(legend.position="bottom")+
  xlim(0,2.5)+
  ggtitle("Project age")


duration=ggplot(reg_df, 
                   aes(x=log(1+winsorized_initial_duration_in_days_i), 
                       linetype=business_type)) +
  geom_density(color="black",size=0.3)+  
  theme_minimal()+ 
  theme(panel.border = element_rect(color="black",fill=NA), 
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), 
        axis.title=element_blank(),
        plot.title = element_text(hjust = 0.5))+ 
  labs(linetype='Business type')+
  theme(legend.position="bottom")+
  xlim(0,2.5)+
  ggtitle("Initial duration")

budget=ggplot(reg_df, 
                aes(x=log(winsorized_initial_budget_i), 
                    linetype=business_type)) +
  geom_density(color="black",size=0.3)+  
  theme_minimal()+ 
  theme(panel.border = element_rect(color="black",fill=NA), 
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), 
        axis.title=element_blank(),
        plot.title = element_text(hjust = 0.5))+ 
  labs(linetype='Business type')+
  theme(legend.position="bottom")+
  xlim(4,14)+
  ggtitle("Initial budget")

num_offers=ggplot(reg_df, 
              aes(x=log(1+number_of_offers_received), 
                  linetype=business_type)) +
  geom_density(color="black",size=0.3)+  
  theme_minimal()+ 
  theme(panel.border = element_rect(color="black",fill=NA), 
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), 
        axis.title=element_blank(),
        plot.title = element_text(hjust = 0.5))+ 
  labs(linetype='Business type')+
  theme(legend.position="bottom")+
  xlim(4,14)+
  ggtitle("Number of bids received")


competition=ggplot(reg_df, aes(x=competitively_awarded_i, 
                   group = business_type)) + 
  geom_bar(aes(y = ..prop..,
               linetype=business_type),
           position="dodge",
           colour="black",
           fill=NA,
           size=0.2,
           width=0.8) + 
  theme_minimal()+ 
  theme(panel.border = element_rect(fill=NA), 
        panel.grid.major = element_blank(),        
        panel.grid.minor = element_blank(),
        axis.title=element_blank(),
        plot.title = element_text(hjust = 0.5))+
  labs(linetype='Group')+
  theme(legend.position="bottom")+
  ggtitle("Competition")


financing=ggplot(reg_df, aes(x=contract_financing_i, 
                               group = business_type)) + 
  geom_bar(aes(y = ..prop..,
               linetype=business_type),
           position="dodge",
           colour="black",
           fill=NA,
           size=0.2,
           width=0.8) + 
  theme_minimal()+ 
  theme(panel.border = element_rect(fill=NA), 
        panel.grid.major = element_blank(),        
        panel.grid.minor = element_blank(),
        axis.title=element_blank(),
        plot.title = element_text(hjust = 0.5))+
  labs(linetype='Group')+
  theme(legend.position="bottom")+
  ggtitle("Contract financing")


win_delay=ggplot(reg_df, 
                   aes(x=log(1+winsorized_delay), 
                       linetype=business_type)) +
  geom_density(color="black",size=0.3)+  
  theme_minimal()+ 
  theme(panel.border = element_rect(color="black",fill=NA), 
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), 
        axis.title=element_blank(),
        plot.title = element_text(hjust = 0.5))+ 
  labs(linetype='Business type')+
  theme(legend.position="bottom")+
  xlim(1,5)+
  ggtitle("Delay")

figure=ggarrange(project_age, duration, budget,num_offers,
                 win_delay, competition, financing,
                 ncol=4, nrow=2,
                 common.legend = TRUE, 
                 legend="bottom",
                 align='hv')

annotate_figure(figure,
                left = text_grob("Density/Proportion", color = "black", rot = 90)
)

ggsave("~/Desktop/qp_density_plots.jpeg",
       bg="white",
       height=10, 
       width=13, 
       unit="in", 
       dpi=320)

