# QuickPay Delay Analysis

## 1. Motivation

The quarterly delay of active projects exhibit the following unique features:

- In each quarter, over 80% of active projects do not report any delay/expedition. This means that the data set is zero-inflated.
- The nonzero quarterly delays do not seem to be censored. The minimum delay/expedition observed in the data set is one day (see the histogram in Fig. 1 below). Thus, Tobit model does not fit our data.
- The project may either be delayed or expedited, meaning that the quarterly delay may be either positive or negative. Thus, zero-inflated model for count data is not suitable.

![hist_QP1_nonzero-delay](C:\Users\jxn174\Documents\Github\Data-and-code\img\hist_QP1_nonzero-delay.png)

​											**Figure 1. Histogram of non-zero quarterly delay**



To account for and better understand the unique features of the project delay data, we take the following approach:

1. _Study the effect of QP on the probability of having a delay and expedition_: To this end, we use logistic regressions and divide the observed quarterly delay into three groups: zero delay, positive delay, and negative delay. This analysis focuses on probability and does not tell us the effect of QP on delay magnitudes when a project does delay.
2. *Study the effect of QP on the magnitudes of quarterly delay when a project has nonzero delay:* To this end, we focus on the subset of data with nonzero delays (i.e., the data shown in Fig. 1) and run linear regression.



## 2. Descriptive analysis

### 2.1. Magnitudes of delay

The following table shows that comparable numbers of small (i.e., treated) businesses and non-small (i.e., control) businesses report nonzero delays in each quarter.

| Date                 | Num. of treated projects with nonzero delays | Num. of control projects with nonzero delays |
| -------------------- | -------------------------------------------- | -------------------------------------------- |
| 3/31/2010            | 518                                          | 646                                          |
| 6/30/2010            | 846                                          | 1008                                         |
| 9/30/2010            | 1401                                         | 1717                                         |
| 12/31/2010           | 1353                                         | 1570                                         |
| 3/31/2011            | 1612                                         | 1749                                         |
| 6/30/2011            | 1519                                         | 1828                                         |
| 9/30/2011            | 1969                                         | 2136                                         |
| 12/31/2011           | 1483                                         | 1664                                         |
| 3/31/2012            | 1844                                         | 1887                                         |
| 6/30/2012            | 1689                                         | 1829                                         |
| 9/30/2012            | 2177                                         | 1968                                         |
| **Overall fraction** | **47.7%**                                    | **52.3%**                                    |
|                      |                                              | Total number of obs.: 34,413                 |



Figure 2 illustrates the average quarterly delays of projects that do report delays/expeditions. The average quarter delay is quite high if we consider only projects that report a change in completion date, ranging from 120 days (4 months) to 200 days (almost 7 months).

![avgDelay_nonzero](C:\Users\jxn174\Documents\Github\Data-and-code\QP1\avgDelay_nonzero.png)

  **Figure 2. Average quarterly delay of projects that report a change in expected completion date**



**Parallel trend assumption:** As can be seen from Fig. 2, and I have checked by running the same regression we have in the paper, the parallel trend assumption holds over the subset of nonzero delays. So we can use the same DiD method to identify the treatment effect.



### 2.2. Probability of delay and expedition

Let  $p^{dt}_t$ and $p^{dc}_t$ denote the fraction of treated (small business) and control (non-small business) projects that report delay in quarter $t$.
$$
\begin{align}
p^{dt}_t &=\frac{\text{Num. of treated projects that report a delay in quarter $t$}}{\text{Num. of active projects in quarter $t$}},\\
p^{dc}_t &=\frac{\text{Num. of control projects that report a delay in quarter $t$}}{\text{Num. of active projects in quarter $t$}}
\end{align}
$$
Similarly, we define $p^{et}_t$ and $p^{ec}_t$ as the fraction of treated (small business) and control (non-small business) projects that report expedition in quarter $t$.

Figure 3 illustrates the fraction of delays and expeditions in each quarter. 

- The top row of Fig. 3 illustrates the fraction of delays. 
  - The top left figure shows the actual fractions  $p^{dt}_t$ and $p_t^{dc}$, which are between 7% and 17% in any quarter.
  - The top right figure shows the change in fractions  $p^{dt}_t$ and $p_t^{dc}$, i.e., $p^{dt}_t/p^{dt}_1$ and $p^{dc}_t/p^{dc}_1$. Thus, both curves start at 1, allowing easier comparison between the control and treated projects. From this figure, it is clear that the fraction of treated projects that report delays increases faster than the control projects after QP.
- The bottom row of Fig. 3 illustrates the fraction of expeditions.
  - The bottom left figure shows the actual fractions of $p^{et}_t$ and $p^{ec}_t$, which are between 0.5% and 1.2%.
  - The bottom right figure shows the change in fractions  $p^{et}_t$ and $p_t^{ec}$, i.e., $p^{et}_t/p^{et}_1$ and $p^{ec}_t/p^{ec}_1$.  We can see that the expedition fraction of small businesses go down significantly after QP compared to the control group.



<img src="C:\Users\jxn174\Documents\Github\Data-and-code\QP1\frac.png" alt="frac" style="zoom:150%;" />

​																	**Figure 3. Fractions of delays and expeditions in each quarter**



## 3. Econometric model for logistic regressions

### 3.1. Basic idea of logit model

In a logit model, the dependent variable $Y$ is either 0 or 1. Let $p(x)=Prob(Y=1|X=x)$ denote the probability that the dependent variable is 1 given the covariates/independent variables $X=x$. So the probability that an observation turns out to be 1 is affected by its characteristics $x$. The logit model assumes that the log of odds, i.e., $p(x)/[1-p(x)]$, called the logit, has a linear relationship on $x$:
$$
\begin{align}
&\text{logit}[p(x)]= \ln \frac{p(x)}{1-p(x)}=\alpha +\beta x.\\
\iff \quad & p(x) = \frac{\exp\{\alpha+\beta x\}}{1+\exp\{\alpha +\beta x\}}
\end{align}
$$

#### 3.1.2. Interpretation of coefficient $\beta$

The sign of $\beta$ determines whether $p(x)$ increases or decreases as $x$ increases. The rate of climb or descent increases at $|\beta|$ increases; as $\beta\to0$ the curve $p(x)$ flattens to a horizontal line. When $\beta=0$, $Y$ or $p(x)$ is independent of $x$.

Exponentiating both sides of equ. (3) shows that the odds are an exponential function of $x$. Thus, the odds increases multiplicatively by $e^\beta$ per unit of increase in x. In other words, $e^\beta$ is an odds ratio, the odds at $X=x+1$ divided by the odds at $X=x$.

### 3.2. Econometric model

We shall model the probability of delay and expedition differently as the covariates and especially QP may has _asymmetric_ effects on the probability of delay and expedition. I only discuss the model for probability of delay here. The model for probability of expedition is similar.

Let the dependent variable $Y_{it}=1$ if project $i$ in quarter $t$ reports positive delay and $Y_{it}=0$ if it has zero or negative delay.

Let $\pi_{it}$ denote the probability that an active project $i$ reports a positive delay in quarter $t$, i.e., $Y_{it}=1$. Then $\pi_{it}$ depends on a variety of project- and time-level covariates: $\pi_{it}=p(Treat_i, Post_t, Time, X_i, Stage_{it})$, where 

- $Treat_i=1$ if project $i$ is treated, i.e., small-business project and 0 otherwise.
- $Post_t=1$ if time $t$ is post treatment and 0 otherwise.
- $Time$ indicates the time fixed-effects.
- $X_i$ indicates other project-level characteristics such as product and services code, firm NAICS code, etc.
- $Stage_{it}$ is the stage of project $i$ at time $t$. I divided the project stage at time $t$ into three terciles, 
  - $Stage_{it}=0$ if the stage of project $i$ is in the lowest tercile at quarter $t$ (i.e., earliest compared to other projects).
  - $Stage_{it}=1$ if the stage of project $i$ is in the lowest tercile at quarter $t$ (i.e., intermediate compared to other projects).
  - $Stage_{it}=2$ if the stage of project $i$ is in the highest tercile at quarter $t$ (i.e., oldest compared to other projects).

#### 3.2.1. Bare-bones model

Using the logit model, we have the following bare-bones DiD model:
$$
\begin{align}
&\ln\frac{\pi_{it}}{1-\pi_{it}}= \beta_0+\beta_1 Treat_i + \beta_2 Post_t + \beta_3 Treat_i\times Post_t
\end{align}
$$
Here the coefficient of interest is $\beta_3$: 

- If $\beta_3>0$, then QP increases the probability that a (treated) project would delay.
- $e^{\beta_3}$ is the odds ratio, the odds of a small-business project under QP divided by the odds of a small-business project without QP, namely the treatment effect on the treated.

#### 3.2.2. Base model with controls

$$
\ln\frac{\pi_{it}}{1-\pi_{it}}= \beta_1 Treat_i + \beta_2 Treat_i\times Post_t+ \mu_t + X_i + Stage_{it}
$$

Here $\mu_t$ is the year-quarter fixed effect, $X_i$ includes the project-level fixed effect (PSC) and firm-level fixed effect (NAICS), and $Stage_{it}$ is the project-stage fixed effect. The coefficient of interest is $\beta_2$ with the same interpretation as above.

#### 3.2.3. Stage-stage dependent treatment effect

For ease of exposition, let $MS_{it}$ and $TS_{it}$ denote the indicators of the middle and top tercile of stage. That is, $MS_{it}=1$ iff $Stage_{it}=1$ and $TS_{it}=1$ iff $Stage_{it}=2$.
$$
\begin{align}
\ln\frac{\pi_{it}}{1-\pi_{it}}&= \beta_1 Treat_i + \beta_2 Treat_i\times Post_t+ \mu_t + X_i + Stage_{it} \nonumber\\
&\qquad + \beta_3 Treat_i\times MS_{it} +\beta_4 Treat_i\times TS_{it}  + \beta_5 Post_t\times MS_{it} + \beta_6 Post_t\times TS_{it} \nonumber\\
&\qquad + \beta_7Treat_i\times Post_t\times MS_{it} + \beta_8Treat_i\times Post_t\times TS_{it}. 
\end{align}
$$
Coefficients of interest are $\beta_7$ and $\beta_8$:

- $e^{\beta_7}$ is the odds ratio between the delay odds of a middle-stage small-business project with QP and without QP. Note that the baseline, i.e., early-stage projects, has odds ratio 1 by construction. Thus, if $\beta_7>0$, then QP increases the delay probability of a middle-stage (small-business) project more than an early-stage (small-business) project.
- $e^{\beta_8}$ is the odds ratio between the delay odds of a late-stage small-business project with QP and without QP. Note that the baseline, i.e., early-stage projects, has odds ratio 1 by construction. Thus, if $\beta_8>0$, then QP increases the delay probability of a late-stage (small-business) project more than an early-stage (small-business) project.



## 4. Results on logistic regression: probability of delay or expedition

All results use clustered errors. *Significance code:* $^{***} p<0.01$, $^{**} p<0.05$, $^* p<0.1$. 

### 4.1. Baseline regression

<img src="C:\Users\jxn174\AppData\Roaming\Typora\typora-user-images\image-20211010210554133.png" alt="image-20211010210554133" style="zoom:130%;" />



The estimation results are shown above for the delay (Table 1) and expedition (Table 2) probabilities. As observed in Fig. 3, QP increases the probability that a (small-business) project delays in a quarter and decreases the probability that a (small-business) project expedites in a quarter.

The ratio of delay odds with and without QP is $e^{0.14}=1.15$. The ratio of expedition odds with and without QP is around $e^{-0.25}=0.78$.

### 4.2. Effect of project stage

<img src="C:\Users\jxn174\Documents\Github\Data-and-code\QP1\stage_prob_est.png" alt="stage_prob_est" style="zoom:130%;" />



From Table 3, project stage does not affect the effect of QP on a project's delay probability.

From Table 4, a late-stage project is less likely to expedite under QP than an early- or middle-stage project. The ratio of expedition odds with and without QP is $e^{-1}=0.37$.



## 5. Results from linear regression: magnitudes of delay

All results use clustered errors. *Significance code:* $^{***} p<0.01$, $^{**} p<0.05$, $^* p<0.1$. 

### 5.1. Baseline regression

<img src="C:\Users\jxn174\Documents\Github\Data-and-code\QP1\delay_est.png" alt="delay_est" style="zoom:130%;" />



From Table 5, QP increases the average quarterly delay by around 18 days for all projects that report a delay.

### 5.2. Effect of project stage

<img src="C:\Users\jxn174\Documents\Github\Data-and-code\QP1\stage_delay_est.png" alt="stage_delay_est" style="zoom:130%;" />



From Table 6, the effect of QP on quarterly delay magnitude is not mediated by project stage.