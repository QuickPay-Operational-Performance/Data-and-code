project_stage=ggplot(reg_df, 
      aes(x=log(wins_project_quarter_stage), 
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
  xlim(-4,0)+
  ggtitle("Project stage")


duration=ggplot(reg_df, 
                   aes(x=winsorized_initial_duration_in_days_i, 
                       linetype=business_type)) +
  geom_density(color="black",size=0.3)+  
  theme_minimal()+
  scale_linetype_manual(name  ="",
                        breaks=c("S", "O"),
                        labels=c("Treated","Control"),
                        values=c("solid","dashed"))+
  scale_color_manual(name  ="",
                     breaks=c("S", "O"),
                     labels=c("Treated","Control"),
                     values=c('black','black'))+
  scale_shape_manual(name  ="",
                     breaks=c("S", "O"),
                     labels=c("Treated","Control"),
                     values=c(16,17))+ 
  theme(panel.border = element_rect(color="black",fill=NA), 
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), 
        legend.text = element_text(size=11),
        axis.title=element_blank(),
        plot.title = element_text(hjust = 0.5))+ 
  labs(linetype='Business type')+
  theme(legend.position="bottom")+
  xlim(5,600)+
  ggtitle("Initial duration")

budget=ggplot(reg_df, 
                aes(x=log(1+winsorized_initial_budget_i), 
                    linetype=business_type)) +
  geom_density(color="black",size=0.3)+  
  theme_minimal()+
  scale_linetype_manual(name  ="",
                        breaks=c("S", "O"),
                        labels=c("Treated","Control"),
                        values=c("solid","dashed"))+
  scale_color_manual(name  ="",
                     breaks=c("S", "O"),
                     labels=c("Treated","Control"),
                     values=c('black','black'))+
  scale_shape_manual(name  ="",
                     breaks=c("S", "O"),
                     labels=c("Treated","Control"),
                     values=c(16,17))+ 
  theme(panel.border = element_rect(color="black",fill=NA), 
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), 
        axis.title=element_blank(),
        plot.title = element_text(hjust = 0.5),
        legend.text = element_text(size=11))+ 
  labs(linetype='Business type')+
  theme(legend.position="bottom")+
  xlim(6,14)+
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

library(ggpubr)
figure=ggarrange(project_stage,duration, budget,num_offers,
                 win_delay, competition, financing,
                 ncol=4, nrow=2,
                 common.legend = TRUE, 
                 legend="bottom",
                 align='hv')

annotate_figure(figure,
                left = text_grob("Density/Proportion", color = "black", rot = 90)
)

# ggsave("~/Desktop/Research/QuickPay/paper/Figures/qp_density_plots.jpeg",
#        bg="white",
#        height=10, 
#        width=13, 
#        unit="in", 
#        dpi=320)

#### NAICS 4-digit ####
naics=readxl::read_xlsx('/Users/vibhutid_admin/Desktop/Research/QuickPay/naics.xlsx')
setDT(naics)[,NAICS:=as.character(NAICS)]

reg_df[,naics_code_4D:=substr(naics_code,1,4)]
reg_df=merge(reg_df,naics,by.x='naics_code_4D',by.y='NAICS')

naics_4D=ggplot(reg_df, aes(x=Description, 
                            group = business_type)) + 
  geom_bar(aes(y = ..prop..,
               #linetype=business_type,
               fill=business_type),
           position="dodge",
           colour="black",
           size=0.2,
           width=0.8) +
  scale_fill_manual(breaks=c("O","S"),
                    values=c("gray","maroon"),
                    labels=c("Controls","Treated"),
                    name="")+ 
  theme_minimal()+ 
  theme(panel.border = element_rect(fill=NA), 
        panel.grid.major = element_blank(),        
        panel.grid.minor = element_blank(),
        axis.title=element_blank(),
        plot.title = element_text(hjust = 0.5),
        plot.margin = unit(c(1,1,0.5,0.5), "cm"),
        axis.text.x = element_text(angle = 45, hjust=1))+
  labs(linetype='Group')+
  theme(legend.position="bottom")+ 
  ggtitle("Industry code (Four-digit NAICS)")+
  coord_fixed(ratio=14)

ggsave("~/Desktop/Research/QuickPay/paper/Figures/naics_dist.jpeg",
       bg="white",
       height=10, 
       width=13, 
       unit="in", 
       dpi=320)

#### Competitively awarded ####

reg_df[,competed:=ifelse(competitively_awarded_i==1,"Yes","No")]
competed_projects=ggplot(reg_df, aes(x=competed, 
                            group = business_type)) + 
  geom_bar(aes(y = ..prop..,
               #linetype=business_type,
               fill=business_type),
           position="dodge",
           colour="black",
           size=0.2,
           width=0.8) +
  scale_fill_manual(breaks=c("O","S"),
                    values=c("gray","maroon"),
                    labels=c("Controls","Treated"),
                    name="")+ 
  theme_minimal()+ 
  theme(panel.border = element_rect(fill=NA), 
        panel.grid.major = element_blank(),        
        panel.grid.minor = element_blank(),
        axis.title=element_blank(),
        plot.title = element_text(hjust = 0.5))+
  labs(linetype='Group')+
  theme(legend.position="bottom")+ 
  ggtitle("Competetively awarded projects")+
  coord_fixed(ratio=2)

# ggsave("~/Desktop/Research/QuickPay/paper/Figures/competed_projects.jpeg",
#        bg="white")

#### PSC ####

reg_df[,psc_code_2D:=substr(product_or_service_code,1,2)]

reg_df2=subset(reg_df,psc_code_2D%in%unique(reg_df$psc_code_2D)[3:42])

psc_code_2D=ggplot(reg_df2, aes(x=as.factor(psc_code_2D), 
                            group = business_type)) + 
  geom_bar(aes(y = ..prop..,
               #linetype=business_type,
               fill=business_type),
           position="dodge",
           colour="black",
           size=0.2,
           width=0.8) +
  scale_fill_manual(values=c("gray","maroon")) + 
  theme_minimal()+ 
  theme(panel.border = element_rect(fill=NA), 
        panel.grid.major = element_blank(),        
        panel.grid.minor = element_blank(),
        axis.title=element_blank(),
        plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
  labs(linetype='Group',
       y='Proportion')+
  theme(legend.position="bottom")+
  ggtitle("Task code (Two-digit)")
psc_code_2D