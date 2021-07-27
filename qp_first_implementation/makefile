raw_data_directory:=~/Dropbox/USA_Spending_Downloads/award_data_archive_20200205
filtered_data_directory:=~/Dropbox/data_quickpay/qp_data


# Phony target to check whether everything is up to date

all: qp_first_implementation.pdf \
     $(filtered_data_directory)/qp_first_matched_sample.csv

################################################################################################################

# Matched Sample

$(filtered_data_directory)/qp_first_matched_sample.csv: matching_qp.py \
			     $(filtered_data_directory)/qp_data_first_reported.csv \
			     $(filtered_data_directory)/resampled_qp_data/qp_resampled_data_fy10_to_fy18.csv
	python matching_qp.py

################################################################################################################

# Other Metrics 

################################################################################################################

# Regressions Plain DiD

qp_first_implementation.pdf: qp_first_implementation.Rmd \
			     $(filtered_data_directory)/qp_data_first_reported.csv \
			     $(filtered_data_directory)/resampled_qp_data/qp_resampled_data_fy10_to_fy18.csv
	
	Rscript -e 'rmarkdown::render("qp_first_implementation.Rmd")'

################################################################################################################

# First reported info

$(filtered_data_directory)/qp_data_first_reported.csv: first_reported_info_qp_data.py\
						$(filtered_data_directory)/qp_data_fy10_to_fy18.csv
	python first_reported_info_qp_data.py

################################################################################################################

# Resampling
# takes approx 3 hours to run

$(filtered_data_directory)/resampled_qp_data/qp_resampled_data_fy10_to_fy18.csv: qp_resample_data.py \
							$(filtered_data_directory)/qp_data_fy10_to_fy18.csv 
	python qp_resample_data.py

################################################################################################################

# commenting out for now 
# Step 1: Obtain data based on Barrot-Nanda paper

#$(filtered_data_directory)/qp_data_fy10_to_fy18.csv: qp_obtain_data.py quickpay_datacleaning.py\
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