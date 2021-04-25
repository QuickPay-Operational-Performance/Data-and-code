# Project stage-dependent treatment effects

## Motivation

Project stage carries important information about project progress and is a distinguishing feature from finished goods transactions. The stage of a project may also affect how the vendor makes decisions. The vendors may behave differently in the early stage of the project compared to in the late stage. We would like to examine whether project stage affects the vendor's reactions to payment acceleration (QuickPay).

The project payments are made throughout the life of the project, based on, e.g., cost invoices of the project vendor, project progress, etc. Would QP have a stronger effect on projects in early stages, given that the majority of the payments are yet to come so QP affects a large fraction of project value?

In general, would payment acceleration affect the project performance evenly throughout the life cycle of a project? If not, at which stage does the project respond to the payment acceleration more strongly? Answers to these question provide insights on the "design" of payment schedule by the buyer. How can the buyer pay the project vendor so that its project performance is maximized?



## Definition of project stage

The project starts at time $t_0$. Let $T$ denote its _actual_ completion time or its _latest_ observed prediction of the completion time if the project is not yet finished. Time $T$ may be outside our observation window. For example, our DiD analysis time horizon is 2009-2012. Consider a project that started in 2010. In 2021, we found that the project was completed on 2014. Then $t_0=2010$ and $T=2014$. If the project is still underway when iin 2021, then we will use the "potential end date" as of 2021 as $T$.

This approach uses the _latest_ measurement/projection of the project end date to find the project duration. I think that this is more aligned with the definition of project stage. If the vendor keeps revising and postponing the projected completion time, then it means that the project was in fact at a stage earlier than what was anticipated at the beginning. By using the _latest_ measurement of the end date, we can measure the project stage at time $t$ as it truly is. We don't use the initial projection of the project end date as it may be subject to aggressive bidding and thus not a truful reflection of the actual project duration as the vendor knows it. In addition, we don't know the initial estimate if the project starts before our observation window. 

Let $S_{it}$ denote the stage of project $i$ in time $t$ over its life space $[t_0,T]$. If we divide each project's life into two halves, then $S_{it}\in\{1,2\}$. $S_{it}=1$ and $S_{it}=2$ mean that project $i$ is in the first and second half of its life in period $t$. 

Within our observation window, the project may move from the first half of its life to the second half. So the project stage $S_{it}$ varies over time.



## Econometric model

We would like to examine whether the project vendor responds to QP differently depending on the stage that the project is in. Specifically, we would like to know whether the projected delay depends on the project stage. All else being equal, would QP induce longer delays on early-stage or late-stage projects? 

Because the project stage $S_{it}$ changes over time, this implies for a treated project $i$, its _treatment effect may change over time_. This is different from the static treatment effects we have done so far.

Consider the simple case with $S_{it}\in\{1,2\}$. Define

- $ES_{it}=1$ if project $i$ is in the early stage of its life in period $t$, i.e., $S_{it}=1$. 
- $Tr_i=1$ if project $i$ is treated (affected by QP), and 
- $Post_t=1$ if period $t$ is post-treatment.

The bare-bones DiD model is:
$$
\begin{align}
Y_{it}&=\beta_0+\beta_1 Tr_i+\beta_2 Post_t+\beta_3ES_{it}+\beta_4 Tr_i\times Post_t\nonumber\\
&\quad +\beta_5Tr_i\times ES_{it}+\beta_6 Post_t\times ES_{it}+\beta_7 Tr_i\times Post_t\times ES_{it}+e_{it}.
\end{align}
$$
The new terms are the ones involving $ES_{it}$, i.e., $\beta_3$ and $\beta_5$-$\beta_7$. Their interpretation is explained below.

- $\beta_3$ is the average delay of _all_ projects that are in the early stage of their life, in addition to the baseline affect $\beta_0$.
- $\beta_5$ is the average delay of _treated_ projects that are in the early stage of their life, in addition to the baseline $\beta_0+\beta_1+\beta_3$. If $\beta_5$ is statistically significant, then the fact that being treated and in the early stage has an additional effect on top of the individual effects of being treated and being in the early stage alone.
- $\beta_6$ is the average delay of _all_ early stage projects if the delay is measured after treatment period, in addition to $\beta_0+\beta_2+\beta_3$. If $\beta_6$ is statistically significant, then the fact that being in the early stage and that measured post treatment has an additional effect on top of the individual effects of early-stage and post-treatment measurements alone.
- $\beta_7$ is the average delay of early stage _treated_ projects if the delay is measured post treatment, in additional $\beta_0+\beta_1+\beta_2+...+\beta_6$. If $\beta_7$ is statistically significant, then the fact of being an early-stage treated project and measured after QP has an additional effect on top of the individual effects. 

**Treatment effects:**

- **Treatment effect on late-stage projects:** $\beta_4$. This is the baseline treatment effect.
- **Treatment effect on early-stage projects:** $\beta_4+\beta_7$.
- **If there is stage-dependent treatment effect, then $\beta_7$ should be statistically significant.**

_**Time varying treatment effect:**_ Consider a treated project with $ES_{it}=1$ on $t=1,\ldots,8$ and $ES_{it}=0$ on $t\geq9$. Then on $t\leq8$, its treatment effect is given by $\beta_4$ and on $t\geq9$, its treatment effect is given by $\beta_4+\beta_7$.

_Note_: If we control for project stage in a more granular way rather than doing two halves, then we would drop $\beta_3$ term. If we allow our project stage control to interact with $Post_t$, then we also drop $\beta_6$.