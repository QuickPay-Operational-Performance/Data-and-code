# Competition theory

The competition theory posits that QuickPay (QP) increases the value of the project by accelerating payments. As a result, the firms will bid more aggressively post-QP in an attempt to win over the projects, which may cause them to deflate the project duration estimate. Thus, implementation of QP may lead to project "delays" on the books because the initial project duration is lower than it should be. Henceforth this delay will be referred to as *artificial delay.*

### Empirical tests for *artificial delay*

Note that this theory does not distinguish between small and large businesses. So it predicts the same treatment effect on small and large businesses.

One way to test the existence of *artificial delay* is to compare the treatment effect on treated projects that are under open competition with those that are not. Because the under-reporting behavior is a means to win over the project in competition, for projects that are not openly competed, we should not see this under-reporting and thus no artificial delay.

In the data, a column is named "Extend competed", an entry of which is "Full and Open Competition after exclusion of sources" with code "D". If we have enough projects (both treated and control) with code *D* in this category, then we can create a dummy variable
$$
COMP_i=
\begin{cases}
1 \quad &\text{if project $i$ has full and open competition,}\\
0 \quad & \text{otherwise.}
\end{cases}
$$
We can run the same model as contract financing to test the existence of *artificial delay*:
$$
\begin{align}
Y_{it}&=\eta_t+\gamma_i+\beta_0X_i+\beta_1Post_t\times X_i+\beta_2 COMP_i+\beta_3Tr_i+\beta_4Tr_i\times COMP_i\nonumber\\
&\qquad +\beta_5COMP_i\times Post_t+\beta_6Tr_i\times Post_t+\beta_7 Tr_i\times COMP_i\times Post_t + \epsilon_{it}
\end{align}
$$
where

- $Y_{it}=$ the delay of project $i$ observed at time $t$
- $\eta_t=$ time fixed-effects
- $\gamma_i=$ project-level fixed effects such as PSC code, firm (?)
- $X_i=$ continuous covariates of project $i$ such as initial duration, initial budget
- $Post_t=1$ if period $t$ is post-QP
- $Tr_i=1$ if project $i$ is treated by QP

#### Interpretation of coefficients

- $\beta_2$, $\beta_3$, and $\beta_4$ are the time-invariant "group-level" estimates of the competed projects, treated projects, and treated and competed projects.
- $\beta_5$ is the "group-level" estimate of competed projects post-QP. It allows the group-effect of competed projects to shift after QP.
- $\beta_6$ is the treatment effect on all treated projects. That is, the delay caused by QP in all small-business projects.
- $\beta_7$ is the increase in treatment effect due to open competition. That is, the *additional delay, namely, the artificial delay,* in small-business projects that are openly competed. The competition theory predicts that $\beta_7>0$.
  - The treatment effect on openly competed projects is $\beta_6+\beta_7$

**Openly competed projects:**

|               | Avg. delay pre-QP                             | Avg. delay post-QP                                           | Difference                        |
| ------------- | --------------------------------------------- | ------------------------------------------------------------ | --------------------------------- |
| Control group | $\eta+\gamma+\beta_0+\beta_2$                 | $\eta+\gamma+\beta_0+\beta_1+\beta_2+\beta_5$                | $\beta_1+\beta_5$                 |
| Treated group | $\eta+\gamma+\beta_0+\beta_2+\beta_3+\beta_4$ | $\eta+\gamma+\beta_0+\beta_1+\beta_2+\beta_3+\beta_4+\beta_5+\beta_6+\beta_7$ | $\beta_1+\beta_5+\beta_6+\beta_7$ |
|               |                                               | **Treatment effect = Difference-in-Difference**              | $\beta_6+\beta_7$                 |

**Not openly competed projects:**

|               | Avg. delay pre-QP             | Avg. delay post-QP                              | Difference        |
| ------------- | ----------------------------- | ----------------------------------------------- | ----------------- |
| Control group | $\eta+\gamma+\beta_0$         | $\eta+\gamma+\beta_0+\beta_1$                   | $\beta_1$         |
| Treated group | $\eta+\gamma+\beta_0+\beta_3$ | $\eta+\gamma+\beta_0+\beta_1+\beta_3+\beta_6$   | $\beta_1+\beta_6$ |
|               |                               | **Treatment effect = Difference-in-Difference** | $\beta_6$         |





