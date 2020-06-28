rm(list = ls())
library(readxl)
library(dplyr)
library(data.table) 
library(knitr)
library(ggplot2)

#### Read intellect data #### 
files <- list.files(path = "~/Dropbox/data_quickpay/qp_data/intellect_data", 
                    pattern = "*.xlsx", full.names = T)

# merge all files into one dataframe
df <- sapply(files, read_excel, simplify=FALSE) %>% 
  rbindlist(., fill = TRUE)

df$`D-U-N-S@ Number`<-as.numeric(gsub("-", "", df$`D-U-N-S@ Number`))
# remove hyphen and convert to number

cols_needed=c("D-U-N-S@ Number",
              "Company Name",
              "2010 Sales Volume",
             "2011 Sales Volume",
             "2012 Sales Volume",
             "2013 Sales Volume",
             "2014 Sales Volume",
             "2015 Sales Volume",
             "2016 Sales Volume" ,
             "2017 Sales Volume" ,
             "2018 Sales Volume" )

data=df[,..cols_needed]
# read select columns

sales_df = melt(data, id.vars = c("D-U-N-S@ Number","Company Name"),
             measure.vars = cols_needed[3:11])
# convert to long form 

sales_df[ , ("value") := lapply(.SD,  function(x) as.numeric(gsub("[,$]", "", x))),
          .SDcols = "value"]
# remove $ and , signs and convert to number for sales & employee info

sales_df[, sales_year:=as.numeric(substr(variable, start = 1, stop = 4))]
# extract year from "2010 Sales Volume" --> 2010

# the years in Intellect data correspond to fiscal years 

#### Read USASpending data #### 

dft=fread('/Users/vibhutidhingra/Dropbox/data_quickpay/qp_data/qp_data_fy10_to_fy18.csv',
         select = c("contract_award_unique_key",
                    "recipient_duns",
                    "federal_action_obligation",
                    "action_date_fiscal_year",
                    "contracting_officers_determination_of_business_size_code"))

dft=dft[contracting_officers_determination_of_business_size_code%in%c("O","S")]
# remove null values
dft[, recipient_duns:=as.numeric(recipient_duns)]
# convert duns number to numeric

# group by recipient duns and year, and add all federal action obligations
fao=dft[, 
            lapply(.SD, sum),
            .SDcols = c("federal_action_obligation"),
            by = c("recipient_duns","action_date_fiscal_year")] 

setnames(fao, c("federal_action_obligation"), 
         c("sum_of_federal_action_obligation"))
## we have entries as: duns, year, fao_sum --> Firm 8353532, Year 2010, Total_obligations 500,000$ 

#### Merge the two datasets ####
govt_weight_per_recipient=merge(x=fao,y=sales_df,
      by.x=c("recipient_duns","action_date_fiscal_year"),
      by.y=c("D-U-N-S@ Number","sales_year"))[]

setnames(govt_weight_per_recipient, c("variable","value"), 
         c("sales_fiscal_year","sales_volume"))

govt_weight_per_recipient[, fao_weight:= ifelse(is.finite(sum_of_federal_action_obligation) &
                                                  is.finite(sales_volume)&
                                                  sales_volume>0,
                                                sum_of_federal_action_obligation/sales_volume, NaN)]
                            
#### get contracts info #### 

# get list of firms active in a given year and their contract classification
# eg. suppose firm A appears in 2015 as both S & O
# then we will have two entries for above: 1) A, 2015, S and 2) A, 2015, O

fao_weight_table=unique(dft[,c("recipient_duns",
                "action_date_fiscal_year",
                "contracting_officers_determination_of_business_size_code")])


fao_weight_table=merge(x=fao_weight_table,y=govt_weight_per_recipient,
                                by=c("recipient_duns","action_date_fiscal_year"))[]

#### summary #### 

# summarize based on small and large businesses
fao_weight_median=fao_weight_table[, 
        lapply(.SD, median, na.rm=TRUE),
        .SDcols = c("sum_of_federal_action_obligation",
                    "sales_volume",
                    "fao_weight"),
        by = c("action_date_fiscal_year",
               "contracting_officers_determination_of_business_size_code")] 

setnames(fao_weight_median, c("sum_of_federal_action_obligation","sales_volume","fao_weight"), 
         c("median_total_obligations","median_sales_volume","median_fao_weight"))

fao_weight_mean=fao_weight_table[, 
                                   lapply(.SD, mean, na.rm=TRUE),
                                   .SDcols = c("sum_of_federal_action_obligation",
                                               "sales_volume",
                                               "fao_weight"),
                                   by = c("action_date_fiscal_year",
                                          "contracting_officers_determination_of_business_size_code")] 

setnames(fao_weight_mean, c("sum_of_federal_action_obligation","sales_volume","fao_weight"), 
         c("mean_total_obligations","mean_sales_volume","mean_fao_weight"))

fao_weight_summary=merge(fao_weight_mean, fao_weight_median,
                         by=c("action_date_fiscal_year",
                              "contracting_officers_determination_of_business_size_code"))

fao_weight_summary[,action_date_fiscal_year:=as.factor(action_date_fiscal_year)]
setnames(fao_weight_summary,"contracting_officers_determination_of_business_size_code","business_size")


fao_weight_summary=fao_weight_summary[order(action_date_fiscal_year)]
#kable(fao_weight_summary)

#### mean plots ####

folder_name='/Users/vibhutidhingra/Desktop/research/Git:Github/qp_data_and_code/img/summary_stats'

mean_weight_plot=ggplot(fao_weight_summary, 
       aes(x=action_date_fiscal_year, 
           y=mean_fao_weight,
           shape=business_size, group=1)) +
          geom_point(size=3)+ 
          theme_bw()+
          theme(panel.grid.major = element_blank(),
                panel.grid.minor = element_blank()) 
ggsave(paste0(folder_name,'/mean_weight_plot.png'),mean_weight_plot)

mean_sales_plot=ggplot(fao_weight_summary, 
       aes(x=action_date_fiscal_year, 
           y=mean_sales_volume,
           shape=business_size, group=1)) +
            geom_point(size=3)+ 
            theme_bw()+
            theme(panel.grid.major = element_blank(),
                  panel.grid.minor = element_blank()) 
ggsave(paste0(folder_name,'/mean_sales_plot.png'),mean_sales_plot)

mean_obligations_plot=ggplot(fao_weight_summary, 
       aes(x=action_date_fiscal_year, 
           y=mean_total_obligations,
           shape=business_size, group=1)) +
            geom_point(size=3)+ 
            theme_bw()+
            theme(panel.grid.major = element_blank(),
                  panel.grid.minor = element_blank()) 
ggsave(paste0(folder_name,'/mean_obligations_plot.png'),mean_obligations_plot)

#### median plots ####

median_weight_plot=ggplot(fao_weight_summary, 
                        aes(x=action_date_fiscal_year, 
                            y=median_fao_weight,
                            shape=business_size, group=1)) +
                    geom_point(size=3)+ 
                    theme_bw()+
                    theme(panel.grid.major = element_blank(),
                          panel.grid.minor = element_blank()) 
ggsave(paste0(folder_name,'/median_weight_plot.png'),median_weight_plot)

median_sales_plot=ggplot(fao_weight_summary, 
                       aes(x=action_date_fiscal_year, 
                           y=median_sales_volume,
                           shape=business_size, group=1)) +
                      geom_point(size=3)+ 
                      theme_bw()+
                      theme(panel.grid.major = element_blank(),
                            panel.grid.minor = element_blank()) 
ggsave(paste0(folder_name,'/median_sales_plot.png'),median_sales_plot)

median_obligations_plot=ggplot(fao_weight_summary, 
                             aes(x=action_date_fiscal_year, 
                                 y=median_total_obligations,
                                 shape=business_size, group=1)) +
                      geom_point(size=3)+ 
                      theme_bw()+
                      theme(panel.grid.major = element_blank(),
                            panel.grid.minor = element_blank()) #+ggtitle("Plant growth")
ggsave(paste0(folder_name,'/median_obligations_plot.png'),median_obligations_plot)


#### Analysis for firms with NO negative obligations ####

negative_obligation_firms=unique(dft[federal_action_obligation<0]$recipient_duns)
dft_non_neg_fao=dft[!recipient_duns%in%negative_obligation_firms]

# group by recipient duns and year, and add all federal action obligations
fao_non_neg_fao=dft_non_neg_fao[, 
        lapply(.SD, sum),
        .SDcols = c("federal_action_obligation"),
        by = c("recipient_duns","action_date_fiscal_year")] 

setnames(fao_non_neg_fao, c("federal_action_obligation"), 
         c("sum_of_federal_action_obligation"))

#### NO negative obligations: Merge the two datasets ####
govt_weight_per_recipient_non_neg_fao=merge(x=fao_non_neg_fao,y=sales_df,
                                by.x=c("recipient_duns","action_date_fiscal_year"),
                                by.y=c("D-U-N-S@ Number","sales_year"))[]

setnames(govt_weight_per_recipient_non_neg_fao, c("variable","value"), 
         c("sales_fiscal_year","sales_volume"))

govt_weight_per_recipient_non_neg_fao[, fao_weight:= ifelse(is.finite(sum_of_federal_action_obligation) &
                                                  is.finite(sales_volume)&
                                                  sales_volume>0,
                                                sum_of_federal_action_obligation/sales_volume, NaN)]

#### NO negative obligations: get contracts info #### 

# get list of firms active in a given year and their contract classification
# eg. suppose firm A appears in 2015 as both S & O
# then we will have two entries for above: 1) A, 2015, S and 2) A, 2015, O

fao_weight_table_non_neg_fao=unique(dft_non_neg_fao[,c("recipient_duns",
                               "action_date_fiscal_year",
                               "contracting_officers_determination_of_business_size_code")])


fao_weight_table_non_neg_fao=merge(x=fao_weight_table_non_neg_fao,
                                   y=govt_weight_per_recipient_non_neg_fao,
                       by=c("recipient_duns","action_date_fiscal_year"))[]

#### NO negative obligations: summary #### 

# summarize based on small and large businesses
fao_weight_median_non_neg_fao=fao_weight_table_non_neg_fao[, 
                                   lapply(.SD, median, na.rm=TRUE),
                                   .SDcols = c("sum_of_federal_action_obligation",
                                               "sales_volume",
                                               "fao_weight"),
                                   by = c("action_date_fiscal_year",
                                          "contracting_officers_determination_of_business_size_code")] 

setnames(fao_weight_median_non_neg_fao, c("sum_of_federal_action_obligation","sales_volume","fao_weight"), 
         c("median_total_obligations","median_sales_volume","median_fao_weight"))

fao_weight_mean_non_neg_fao=fao_weight_table_non_neg_fao[, 
                                 lapply(.SD, mean, na.rm=TRUE),
                                 .SDcols = c("sum_of_federal_action_obligation",
                                             "sales_volume",
                                             "fao_weight"),
                                 by = c("action_date_fiscal_year",
                                        "contracting_officers_determination_of_business_size_code")] 

setnames(fao_weight_mean_non_neg_fao, c("sum_of_federal_action_obligation","sales_volume","fao_weight"), 
         c("mean_total_obligations","mean_sales_volume","mean_fao_weight"))

fao_weight_summary_non_neg_fao=merge(fao_weight_mean_non_neg_fao, fao_weight_median_non_neg_fao,
                         by=c("action_date_fiscal_year",
                              "contracting_officers_determination_of_business_size_code"))

fao_weight_summary_non_neg_fao[,action_date_fiscal_year:=as.factor(action_date_fiscal_year)]
setnames(fao_weight_summary_non_neg_fao,"contracting_officers_determination_of_business_size_code","business_size")


fao_weight_summary_non_neg_fao=fao_weight_summary_non_neg_fao[order(action_date_fiscal_year)]
#kable(fao_weight_summary)

#### NO negative obligations: mean plots ####

mean_weight_plot_non_neg_fao=ggplot(fao_weight_summary_non_neg_fao, 
                        aes(x=action_date_fiscal_year, 
                            y=mean_fao_weight,
                            shape=business_size, group=1)) +
  geom_point(size=3)+ 
  theme_bw()+
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()) +
  ggtitle("Only firms with non-negative obligations")
ggsave(paste0(folder_name,'/mean_weight_plot_non_neg_fao.png'),mean_weight_plot_non_neg_fao)

mean_sales_plot_non_neg_fao=ggplot(fao_weight_summary_non_neg_fao, 
                       aes(x=action_date_fiscal_year, 
                           y=mean_sales_volume,
                           shape=business_size, group=1)) +
  geom_point(size=3)+ 
  theme_bw()+
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())  +
  ggtitle("Only firms with non-negative obligations")
ggsave(paste0(folder_name,'/mean_sales_plot_non_neg_fao.png'),mean_sales_plot_non_neg_fao)


mean_obligations_plot_non_neg_fao=ggplot(fao_weight_summary_non_neg_fao, 
                             aes(x=action_date_fiscal_year, 
                                 y=mean_total_obligations,
                                 shape=business_size, group=1)) +
  geom_point(size=3)+ 
  theme_bw()+
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())  +
  ggtitle("Only firms with non-negative obligations")
ggsave(paste0(folder_name,'/mean_obligations_plot_non_neg_fao.png'),mean_obligations_plot_non_neg_fao)


#### NO negative obligations: median plots ####

median_weight_plot_non_neg_fao=ggplot(fao_weight_summary_non_neg_fao, 
                          aes(x=action_date_fiscal_year, 
                              y=median_fao_weight,
                              shape=business_size, group=1)) +
  geom_point(size=3)+ 
  theme_bw()+
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())  +
  ggtitle("Only firms with non-negative obligations")
ggsave(paste0(folder_name,'/median_weight_plot_non_neg_fao.png'),
       median_weight_plot_non_neg_fao)


median_sales_plot_non_neg_fao=ggplot(fao_weight_summary_non_neg_fao, 
                         aes(x=action_date_fiscal_year, 
                             y=median_sales_volume,
                             shape=business_size, group=1)) +
  geom_point(size=3)+ 
  theme_bw()+
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())  +
  ggtitle("Only firms with non-negative obligations")
ggsave(paste0(folder_name,'/median_sales_plot_non_neg_fao.png'),
       median_sales_plot_non_neg_fao)

median_obligations_plot_non_neg_fao=ggplot(fao_weight_summary_non_neg_fao, 
                               aes(x=action_date_fiscal_year, 
                                   y=median_total_obligations,
                                   shape=business_size, group=1)) +
  geom_point(size=3)+ 
  theme_bw()+
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())  +
  ggtitle("Only firms with non-negative obligations")
ggsave(paste0(folder_name,'/median_obligations_plot_non_neg_fao.png'),
       median_obligations_plot_non_neg_fao)


