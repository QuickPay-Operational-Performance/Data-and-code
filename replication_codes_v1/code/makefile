input_directory:=~/Dropbox/data_quickpay/qp_replication/input
data_folder:=~/Dropbox/data_quickpay/qp_data
working_directory:=~/Dropbox/data_quickpay/qp_replication/working
output_directory:=~/Desktop/Research/QuickPay/Data-and-code/replication_codes_v1/output

# Phony target to check whether everything is up to date

all: $(output_directory)/o_tab_summary_stats.pdf\
     $(output_directory)/o_tab_main.pdf\
     $(output_directory)/o_tab_alt_explanations.pdf\
     $(output_directory)/o_plot_matching.pdf\
     $(output_directory)/o_plot_balance.pdf\
     $(output_directory)/o_tab_financial_liquidity.pdf\
     $(output_directory)/o_tab_portfolio.pdf\
     $(output_directory)/o_tab_congestion.pdf\
     $(output_directory)/o_tab_bid_metrics.pdf\
     $(output_directory)/o_tab_competition.pdf\
     $(output_directory)/o_tab_stage.pdf\
     $(output_directory)/o_plot_placebo.pdf\
     $(output_directory)/o_tab_robustness.pdf\
     $(output_directory)/o_tab_parallel_trends.pdf\
     $(output_directory)/o_plot_model_free.pdf\
     $(output_directory)/o_tab_exclude_action_types.pdf\
     $(output_directory)/o_tab_include_stage_interaction.pdf\
     $(output_directory)/o_tab_extended_sample.pdf\
     $(output_directory)/o_plot_cumulative.pdf\
     $(output_directory)/o_tab_overall_delays.pdf

################################################################################################################

# Model free figure

$(output_directory)/o_plot_model_free.pdf: o_plot_model_free.Rmd  \
		    $(working_directory)/w_clean_control.csv
	
	Rscript -e 'rmarkdown::render("o_plot_model_free.Rmd", output_file = "$(output_directory)/o_plot_model_free.pdf")'

################################################################################################################

# Main table

$(output_directory)/o_tab_main.pdf: o_tab_main.Rmd  \
		    $(working_directory)/w_clean_control.csv
	
	Rscript -e 'rmarkdown::render("o_tab_main.Rmd", output_file = "$(output_directory)/o_tab_main.pdf")'

################################################################################################################

# Alt explanations

$(output_directory)/o_tab_alt_explanations.pdf: o_tab_alt_explanations.Rmd  \
		    $(working_directory)/w_clean_control.csv \
		    $(data_folder)/qp_data_first_reported.csv
	
	Rscript -e 'rmarkdown::render("o_tab_alt_explanations.Rmd", output_file = "$(output_directory)/o_tab_alt_explanations.pdf")'


################################################################################################################

# Matching plot

$(output_directory)/o_plot_matching.pdf: o_plot_matching.Rmd  \
		    $(working_directory)/w_clean_control.csv
	
	Rscript -e 'rmarkdown::render("o_plot_matching.Rmd", output_file = "$(output_directory)/o_plot_matching.pdf")'

################################################################################################################


# Balance plot after matching

$(output_directory)/o_plot_balance.pdf: o_plot_balance.Rmd  \
		    $(working_directory)/w_clean_control.csv
	
	Rscript -e 'rmarkdown::render("o_plot_balance.Rmd", output_file = "$(output_directory)/o_plot_balance.pdf")'

################################################################################################################

# Financial Liquidity

$(output_directory)/o_tab_financial_liquidity.pdf: o_tab_financial_liquidity.Rmd  \
		    $(working_directory)/w_clean_control.csv
	
	Rscript -e 'rmarkdown::render("o_tab_financial_liquidity.Rmd", output_file = "$(output_directory)/o_tab_financial_liquidity.pdf")'

################################################################################################################

# Project Sequence

$(output_directory)/o_tab_portfolio.pdf: o_tab_portfolio.Rmd  \
		    $(working_directory)/w_clean_control.csv
	
	Rscript -e 'rmarkdown::render("o_tab_portfolio.Rmd", output_file = "$(output_directory)/o_tab_portfolio.pdf")'

################################################################################################################

# Congestion

$(output_directory)/o_tab_congestion.pdf: o_tab_congestion.Rmd  \
		    $(working_directory)/w_clean_control.csv
	
	Rscript -e 'rmarkdown::render("o_tab_congestion.Rmd", output_file = "$(output_directory)/o_tab_congestion.pdf")'

################################################################################################################


# Bid Metrics

$(output_directory)/o_tab_bid_metrics.pdf: o_tab_bid_metrics.Rmd  \
		    $(input_directory)/quickpay_delays.csv
	
	Rscript -e 'rmarkdown::render("o_tab_bid_metrics.Rmd", output_file = "$(output_directory)/o_tab_bid_metrics.pdf")'

################################################################################################################


# Competition

$(output_directory)/o_tab_competition.pdf: o_tab_competition.Rmd  \
		    $(working_directory)/w_clean_control.csv
	
	Rscript -e 'rmarkdown::render("o_tab_competition.Rmd", output_file = "$(output_directory)/o_tab_competition.pdf")'

################################################################################################################

# Stage

$(output_directory)/o_tab_stage.pdf: o_tab_stage.Rmd  \
		    $(working_directory)/w_clean_control.csv
	
	Rscript -e 'rmarkdown::render("o_tab_stage.Rmd", output_file = "$(output_directory)/o_tab_stage.pdf")'

################################################################################################################
#
# APPENDIX TABLES + FIGURES
#
################################################################################################################

# Appendix: Summary statistics

$(output_directory)/o_tab_summary_stats.pdf: o_tab_summary_stats.Rmd  \
		    $(input_directory)/quickpay_delays.csv
	
	Rscript -e 'rmarkdown::render("o_tab_summary_stats.Rmd", output_file = "$(output_directory)/o_tab_summary_stats.pdf")'

################################################################################################################

# Appendix: Placebo tests

$(output_directory)/o_plot_placebo.pdf: o_plot_placebo.Rmd  \
		    $(working_directory)/w_clean_control.csv
	
	Rscript -e 'rmarkdown::render("o_plot_placebo.Rmd", output_file = "$(output_directory)/o_plot_placebo.pdf")'

################################################################################################################

# Appendix: Robustness

$(output_directory)/o_tab_robustness.pdf: o_tab_robustness.Rmd  \
		    $(working_directory)/w_clean_control.csv   \
                     $(input_directory)/quickpay_delays.csv
	
	Rscript -e 'rmarkdown::render("o_tab_robustness.Rmd", output_file = "$(output_directory)/o_tab_robustness.pdf")'

################################################################################################################

# Appendix: Parallel Trends

$(output_directory)/o_tab_parallel_trends.pdf: o_tab_parallel_trends.Rmd  \
		    $(working_directory)/w_clean_control.csv
	
	Rscript -e 'rmarkdown::render("o_tab_parallel_trends.Rmd", output_file = "$(output_directory)/o_tab_parallel_trends.pdf")'

################################################################################################################

# Appendix: Extended sample (Fixed price + Cost contracts)

$(output_directory)/o_tab_extended_sample.pdf: o_tab_extended_sample.Rmd  \
		    $(working_directory)/w_qp_extended_sample.rds
	
	Rscript -e 'rmarkdown::render("o_tab_extended_sample.Rmd", output_file = "$(output_directory)/o_tab_extended_sample.pdf")'

################################################################################################################

# Appendix: Exclude certain action types

$(output_directory)/o_tab_exclude_action_types.pdf: o_tab_exclude_action_types.Rmd  \
		    $(working_directory)/w_clean_control.csv\
		    $(data_folder)/qp_data_fy10_to_fy18.csv
	
	Rscript -e 'rmarkdown::render("o_tab_exclude_action_types.Rmd", output_file = "$(output_directory)/o_tab_exclude_action_types.pdf")'

################################################################################################################

# Appendix: Include stage interaction

$(output_directory)/o_tab_include_stage_interaction.pdf: o_tab_include_stage_interaction.Rmd  \
		    $(working_directory)/w_clean_control.csv
	
	Rscript -e 'rmarkdown::render("o_tab_include_stage_interaction.Rmd", output_file = "$(output_directory)/o_tab_include_stage_interaction.pdf")'

################################################################################################################

# Appendix: Cumulative delays

$(output_directory)/o_plot_cumulative.pdf: o_plot_cumulative.Rmd  \
		    $(data_folder)/projects_to_keep.csv\
		    $(data_folder)/qp_data_fy10_to_fy18.csv
	
	Rscript -e 'rmarkdown::render("o_plot_cumulative.Rmd", output_file = "$(output_directory)/o_plot_cumulative.pdf")'

################################################################################################################

# Appendix: Overall project delays

$(output_directory)/o_tab_overall_delays.pdf: o_tab_overall_delays.Rmd  \
		    $(data_folder)/projects_to_keep.csv\
		    $(data_folder)/resampled_qp_data/qp_resampled_data_fy10_to_fy12_with_zero_obs.csv\
		    $(data_folder)/qp_data_first_reported.csv
	
	Rscript -e 'rmarkdown::render("o_tab_overall_delays.Rmd", output_file = "$(output_directory)/o_tab_overall_delays.pdf")'

################################################################################################################

