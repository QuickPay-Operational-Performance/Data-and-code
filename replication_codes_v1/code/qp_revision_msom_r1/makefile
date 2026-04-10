data_directory:=~/Dropbox/data_quickpay/qp_data/
code_directory:=~/Desktop/Research/QuickPay_Data-and-code/replication_codes_v1/code
input_directory:=~/Dropbox/data_quickpay/qp_replication/input/
working_directory:=~/Dropbox/data_quickpay/qp_replication/working/
figures_directory:=~/Desktop/Research/QuickPay_Data-and-code/replication_codes_v1/code/qp_revision_msom_r1/figures
output_directory:=~/Desktop/Research/QuickPay_Data-and-code/replication_codes_v1/code/qp_revision_msom_r1/output

########################################################################
# REVISION 
########################################################################

# Phony target to check whether everything is up to date

all: $(output_directory)/o_fig_event_study.pdf\
     $(output_directory)/o_plot_bid_metrics_parallel_trends.pdf\
     $(output_directory)/o_tab_alt_cluster.pdf\
     $(output_directory)/o_tab_contractor_level.pdf\
     $(output_directory)/o_tab_main_contractor_controls.pdf\
     $(output_directory)/o_tab_task_extension.pdf\
     $(output_directory)/o_tab_task_variability.pdf\
     $(output_directory)/o_plot_timeline_2008_2013.pdf

######################################################################################
# Table -- Alternate Standard Errors
######################################################################################

$(output_directory)/o_tab_alt_cluster.pdf: o_tab_alt_cluster.Rmd \
		   $(code_directory)/file_paths.R\
		   $(working_directory)/w_clean_control.csv
	
	Rscript -e 'rmarkdown::render("o_tab_alt_cluster.Rmd",output_dir = "$(output_directory)/")'

######################################################################################
# Table -- Contractor Controls
######################################################################################

$(output_directory)/o_tab_main_contractor_controls.pdf: o_tab_main_contractor_controls.Rmd \
		   $(code_directory)/file_paths.R\
		   $(working_directory)/w_clean_control.csv
	
	Rscript -e 'rmarkdown::render("o_tab_main_contractor_controls.Rmd",output_dir = "$(output_directory)/")'

######################################################################################
# Table -- Task Extension
######################################################################################

$(output_directory)/o_tab_task_extension.pdf: o_tab_task_extension.Rmd \
		   $(code_directory)/file_paths.R\
		   $(input_directory)/quickpay_delays.csv
	
	Rscript -e 'rmarkdown::render("o_tab_task_extension.Rmd",output_dir = "$(output_directory)/")'

######################################################################################
# Table -- Task Variability
######################################################################################

$(output_directory)/o_tab_task_variability.pdf: o_tab_task_variability.Rmd \
		   $(code_directory)/file_paths.R\
		   $(input_directory)/quickpay_delays.csv
	
	Rscript -e 'rmarkdown::render("o_tab_task_variability.Rmd",output_dir = "$(output_directory)/")'


######################################################################################
# Table -- Contractor Level Regression
######################################################################################

$(output_directory)/o_tab_contractor_level.pdf: o_tab_contractor_level.Rmd \
		   $(code_directory)/file_paths.R\
		   $(input_directory)/quickpay_delays.csv
	
	Rscript -e 'rmarkdown::render("o_tab_contractor_level.Rmd",output_dir = "$(output_directory)/")'

######################################################################################
# Plot -- Extended Timeline
######################################################################################

$(output_directory)/o_plot_timeline_2008_2013.pdf: o_plot_timeline_2008_2013.Rmd \
		   $(code_directory)/file_paths.R\
		   $(working_directory)/w_qp_timeline_2008_2013.rds
	
	Rscript -e 'rmarkdown::render("o_plot_timeline_2008_2013.Rmd",output_dir = "$(output_directory)/")'


######################################################################################
# Plot -- Event Study
######################################################################################

$(output_directory)/o_fig_event_study.pdf: o_fig_event_study.Rmd \
		   $(code_directory)/file_paths.R\
		   $(working_directory)/w_clean_control.csv
	
	Rscript -e 'rmarkdown::render("o_fig_event_study.Rmd",output_dir = "$(output_directory)/")'

######################################################################################
# Plot -- Event Study
######################################################################################

$(output_directory)/o_plot_bid_metrics_parallel_trends.pdf: o_plot_bid_metrics_parallel_trends.Rmd \
		   $(code_directory)/file_paths.R\
		   $(input_directory)/quickpay_delays.csv
	
	Rscript -e 'rmarkdown::render("o_plot_bid_metrics_parallel_trends.Rmd",output_dir = "$(output_directory)/")'


######################################################################################
# Working Data File (Extended Timeline: 2008-2013)
######################################################################################

#$(working_directory)/w_qp_timeline_2008_2013.rds: w_extended_timeline_2008_2013.Rmd \
#		   ~/Dropbox/USA_Spending_Downloads/award_data_archive_20200205/*.csv\
#	
#	Rscript -e 'rmarkdown::render("w_extended_timeline_2008_2013",output_dir = "$(output_directory)/")'


######################################################################################
# Working Files (Text Descriptions)
######################################################################################

#$(working_directory)/w_dt_with_delay.csv: w_qp_text_descriptions.Rmd \
#		   ~/Dropbox/USA_Spending_Downloads/award_data_archive_20200205/"FY(2010|2011|2012)_097_Contracts_Full_20200205"*.csv\
#	
#	Rscript -e 'rmarkdown::render("w_qp_text_descriptions.Rmd",output_dir = "$(output_directory)/")'


#$(working_directory)/w_dt_with_quality.csv: w_qp_text_descriptions.Rmd \
#		   ~/Dropbox/USA_Spending_Downloads/award_data_archive_20200205/"FY(2010|2011|2012)_097_Contracts_Full_20200205"*.csv\
#	
#	Rscript -e 'rmarkdown::render("w_qp_text_descriptions.Rmd",output_dir = "$(output_directory)/")'
