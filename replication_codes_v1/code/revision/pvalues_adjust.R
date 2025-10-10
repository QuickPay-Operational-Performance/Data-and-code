rm(list=ls())

liquidity=0.02993911
sequencing=5.70e-3
stage=2.17e-8
num_bids=3.17e-2
duration=3.59e-3
budget=9.64e-4
competition=4.24e-5
congestion_budget=4.63e-7
congestion_projects=0.155
congestion_tasks=0.129

p=c(liquidity,
    sequencing,
    stage,
    num_bids,
    duration,
    budget,
    competition,
    congestion_budget,
    congestion_projects,
    congestion_tasks)

#p.adjust.M=p.adjust.methods[p.adjust.methods != "fdr"]
p.adjust.M=c("none","hochberg","hommel","BH","holm")
p.adj=sapply(p.adjust.M, function(meth) p.adjust(p, meth))
p.adj=round(p.adj, 4)
adjusted_df=as.data.frame(p.adj) 

# Add variable names as a column
adjusted_df$variable <- c(
  "liquidity",
  "sequencing",
  "stage",
  "num_bids",
  "duration",
  "budget",
  "competition",
  "congestion_budget",
  "congestion_projects",
  "congestion_tasks"
)

# Move variable column to the front
adjusted_df=adjusted_df[, c("variable", setdiff(names(adjusted_df), "variable"))]
latex_table=xtable(adjusted_df,digits=4,  caption = "Adjusted p-values by method")
print(latex_table, include.rownames = FALSE)
