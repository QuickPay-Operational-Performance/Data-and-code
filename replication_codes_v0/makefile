input_directory:=~/Dropbox/data_quickpay/qp_replication/input
working_directory:=~/Dropbox/data_quickpay/qp_replication/working
output_directory:=~/Dropbox/data_quickpay/qp_replication/output
code_directory:=~/Dropbox/data_quickpay/qp_replication/code

# Phony target to check whether everything is up to date

all: $(output_directory)/o_tab_summary_stats.pdf\
     $(output_directory)/o_tab_main.pdf\
     $(output_directory)/o_tab_logit_positive.pdf\
     $(output_directory)/o_tab_logit_negative.pdf\
     $(output_directory)/o_tab_financial_liquidity.pdf\
     $(output_directory)/o_tab_portfolio.pdf\
     $(output_directory)/o_tab_congestion.pdf\
     $(output_directory)/o_tab_bid_metrics.pdf\
     $(output_directory)/o_tab_competition.pdf\
     $(output_directory)/o_tab_stage.pdf\
     $(output_directory)/o_tab_performance_incentives.pdf\
     $(output_directory)/o_tab_robustness.pdf\
     $(output_directory)/o_tab_parallel_trends.pdf\
     $(output_directory)/o_fig_model_free.pdf\
     $(output_directory)/o_fig_event_study.pdf

################################################################################################################

# Summary statistics

$(output_directory)/o_tab_summary_stats.pdf: o_tab_summary_stats.Rmd  \
		    $(input_directory)/quickpay_delays.csv
	
	Rscript -e 'rmarkdown::render("o_tab_summary_stats.Rmd", output_file = "$(output_directory)/o_tab_summary_stats.pdf")'


################################################################################################################

# Model free

$(output_directory)/o_fig_model_free.pdf: o_fig_model_free.Rmd  \
		    $(working_directory)/w_clean_control.csv
	
	Rscript -e 'rmarkdown::render("o_fig_model_free.Rmd", output_file = "$(output_directory)/o_fig_model_free.pdf")'

################################################################################################################

# Main table

$(output_directory)/o_tab_main.pdf: o_tab_main.Rmd  \
		    $(working_directory)/w_clean_control.csv
	
	Rscript -e 'rmarkdown::render("o_tab_main.Rmd", output_file = "$(output_directory)/o_tab_main.pdf")'

################################################################################################################

# Event study

$(output_directory)/o_fig_event_study.pdf: o_fig_event_study.Rmd  \
		    $(working_directory)/w_clean_control.csv
	
	Rscript -e 'rmarkdown::render("o_fig_event_study.Rmd", output_file = "$(output_directory)/o_fig_event_study.pdf")'

################################################################################################################

# Logit Positive

$(output_directory)/o_tab_logit_positive.pdf: o_tab_logit_positive.Rmd  \
		    $(working_directory)/w_clean_control.csv
	
	Rscript -e 'rmarkdown::render("o_tab_logit_positive.Rmd", output_file = "$(output_directory)/o_tab_logit_positive.pdf")'

################################################################################################################

# Logit Negative

$(output_directory)/o_tab_logit_negative.pdf: o_tab_logit_negative.Rmd  \
		    $(working_directory)/w_clean_control.csv
	
	Rscript -e 'rmarkdown::render("o_tab_logit_negative.Rmd", output_file = "$(output_directory)/o_tab_logit_negative.pdf")'

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

# Performance Incentives

$(output_directory)/o_tab_performance_incentives.pdf: o_tab_performance_incentives.Rmd  \
		    $(working_directory)/w_clean_control.csv
	
	Rscript -e 'rmarkdown::render("o_tab_performance_incentives.Rmd", output_file = "$(output_directory)/o_tab_performance_incentives.pdf")'

################################################################################################################

# Robustness

$(output_directory)/o_tab_robustness.pdf: o_tab_robustness.Rmd  \
		    $(working_directory)/w_clean_control.csv   \
                     $(input_directory)/quickpay_delays.csv
	
	Rscript -e 'rmarkdown::render("o_tab_robustness.Rmd", output_file = "$(output_directory)/o_tab_robustness.pdf")'

################################################################################################################

# Parallel Trends

$(output_directory)/o_tab_parallel_trends.pdf: o_tab_parallel_trends.Rmd  \
		    $(working_directory)/w_clean_control.csv
	
	Rscript -e 'rmarkdown::render("o_tab_parallel_trends.Rmd", output_file = "$(output_directory)/o_tab_parallel_trends.pdf")'

################################################################################################################
