raw_data_directory:=~/Dropbox/USA_Spending_Downloads/award_data_archive_20200205
filtered_data_directory:=~/Dropbox/data_quickpay/qp_data

# Phony target to check whether everything is up to date

all: qp_first_implementation.pdf \
     qp_first_matched.pdf \
     qp_first_relative_delay.pdf \
     qp_first_pc_delay.pdf \
     qp_first_budget_overrun.pdf 

################################################################################################################

# Budget Overruns

# Sample restricted to those projects whose start dates (first value of "action_date") match with the "date_signed" from API

qp_first_budget_overrun.pdf: qp_first_budget_overrun.Rmd \
			    $(filtered_data_directory)/projects_to_keep.csv \
			     $(filtered_data_directory)/qp_data_first_reported.csv \
			     $(filtered_data_directory)/resampled_qp_data/qp_resampled_data_fy10_to_fy12.csv

	Rscript -e 'rmarkdown::render("qp_first_budget_overrun.Rmd")'


################################################################################################################

# Matched Regressions: Quarterly delay rate (in days)

qp_first_matched.pdf: qp_first_matched.Rmd \
			$(filtered_data_directory)/qp_first_matched_sample.csv \
			$(filtered_data_directory)/qp_data_first_reported.csv
	Rscript -e 'rmarkdown::render("qp_first_matched.Rmd")'


# Matched Sample

# Sample restricted to those projects whose start dates (first value of "action_date") match with the "date_signed" from API

$(filtered_data_directory)/qp_first_matched_sample.csv: matching_qp.py \
			    $(filtered_data_directory)/projects_to_keep.csv \
			     $(filtered_data_directory)/qp_data_first_reported.csv \
			     $(filtered_data_directory)/resampled_qp_data/qp_resampled_data_fy10_to_fy12.csv
	python matching_qp.py

################################################################################################################

# Relative delay rate (Delay_it/Initial_Duration_i)

# Sample restricted to those projects whose start dates (first value of "action_date") match with the "date_signed" from API

qp_first_relative_delay.pdf: qp_first_relative_delay.Rmd \
		    $(filtered_data_directory)/projects_to_keep.csv \
		    $(filtered_data_directory)/qp_data_first_reported.csv \
		    $(filtered_data_directory)/resampled_qp_data/qp_resampled_data_fy10_to_fy12.csv
	
	Rscript -e 'rmarkdown::render("qp_first_relative_delay.Rmd")'


################################################################################################################

# Percentage delay rate (Delay_it/Duration_i,t-1)

# Sample restricted to those projects whose start dates (first value of "action_date") match with the "date_signed" from API

qp_first_pc_delay.pdf: qp_first_pc_delay.Rmd \
		    $(filtered_data_directory)/projects_to_keep.csv \
		    $(filtered_data_directory)/qp_data_first_reported.csv \
		    $(filtered_data_directory)/resampled_qp_data/qp_resampled_data_fy10_to_fy12.csv
	
	Rscript -e 'rmarkdown::render("qp_first_pc_delay.Rmd")'

################################################################################################################

# Quarterly delay rate (in days)

# Sample restricted to those projects whose start dates (first value of "action_date") match with the "date_signed" from API

qp_first_implementation.pdf: qp_first_implementation.Rmd \
			     $(filtered_data_directory)/projects_to_keep.csv \
			     $(filtered_data_directory)/qp_data_first_reported.csv \
			     $(filtered_data_directory)/resampled_qp_data/qp_resampled_data_fy10_to_fy12.csv
	
	Rscript -e 'rmarkdown::render("qp_first_implementation.Rmd")'

################################################################################################################

# Projects to keep

$(filtered_data_directory)/projects_to_keep.csv: projects_to_keep.py \
						$(filtered_data_directory)/api_csv_initial/*.csv \
						$(filtered_data_directory)/qp_data_first_reported.csv
	python projects_to_keep.py

################################################################################################################


# First reported info

$(filtered_data_directory)/qp_data_first_reported.csv: first_reported_info_qp_data.py\
						$(filtered_data_directory)/qp_data_fy10_to_fy18.csv
	python first_reported_info_qp_data.py

################################################################################################################

# Resampling FY 2010 to FY 2012

$(filtered_data_directory)/resampled_qp_data/qp_resampled_data_fy10_to_fy12.csv: qp_resample_fy10_to_fy12.py \
							$(filtered_data_directory)/qp_data_fy10_to_fy18.csv 
	python qp_resample_fy10_to_fy12.py

################################################################################################################

# Resampling FY 2010 to FY 2018
# takes approx 3 hours to run
# not used here

$(filtered_data_directory)/resampled_qp_data/qp_resampled_data_fy10_to_fy18.csv: qp_resample_data.py \
							$(filtered_data_directory)/qp_data_fy10_to_fy18.csv 
	python qp_resample_data.py

################################################################################################################

# commenting this for now coz keeping dependency data files in cloud only

# Step 1: Obtain data based on Barrot-Nanda paper

#$(filtered_data_directory)/qp_data_fy10_to_fy18.csv $(filtered_data_directory)/data_for_different_years/*.csv: 
#					     qp_obtain_data.py quickpay_datacleaning.py
#					     $(raw_data_directory)/FY2010_097_Contracts_Full_20200205/*.csv \
#					     $(raw_data_directory)/FY2011_097_Contracts_Full_20200205/*.csv \
#					     $(raw_data_directory)/FY2012_097_Contracts_Full_20200205/*.csv \
#					     $(raw_data_directory)/FY2013_All_Contracts_Full_20200205/*.csv \
#					     $(raw_data_directory)/FY2014_All_Contracts_Full_20200205/*.csv \
#					     $(raw_data_directory)/FY2015_All_Contracts_Full_20200205/*.csv \
#					     $(raw_data_directory)/FY2016_All_Contracts_Full_20200205/*.csv \
#					     $(raw_data_directory)/FY2017_All_Contracts_Full_20200205/*.csv \
#					     $(raw_data_directory)/FY2018_All_Contracts_Full_20200205/*.csv
#	python qp_obtain_data.py
