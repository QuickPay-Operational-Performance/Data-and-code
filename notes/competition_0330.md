# Effect of Aggressive Competition 

**Hypothesis:** 

* QuickPay increased competition for small projects.

* This led to more aggressive bids. That is, contractors quoted unrealistically small timelines for the projects.

* As a result, we should see “artificial delays” on these projects as they revert to their realistic timelines later. 

* **Note:** This hypothesis only applies to projects that were signed after QuickPay. See Figure below for different groups in the sample.

  ![](/Users/vibhutidhingra/Desktop/research/Git:Github/qp_data_and_code/img/competition_1.png)

* We, therefore, need the effect coming from new projects. 

  ![](/Users/vibhutidhingra/Desktop/research/Git:Github/qp_data_and_code/img/competition_2.png)

## Subsample Model

For a subsample of competitive or noncompetitive projects: 

$$Delay_{it}=\beta_0 +\beta_1 Treat_i+ \beta_2 StartedAfterQP_i+ \beta_3 Post_t\\ \qquad+ \beta_4 (Treat_i×Post_t×StartedAfterQP_i )+\epsilon_{it}$$

* Note: $Post_t = 0 \implies StartedAfterQP_i = 0$
  * These projects don’t exist in the period before QuickPay

|                | Before QP           | After QP                                        | Difference                      |
| -------------- | ------------------- | ----------------------------------------------- | ------------------------------- |
| Small Projects | $\beta_0 + \beta_1$ | $\beta_0 + \beta_1 + \beta_2 +\beta_3 +\beta_4$ | $\beta_2+\beta_3+\beta_4$       |
| Large Projects | $\beta_0$           | $\beta_0 + \beta_2 +\beta_3$                    | $\beta_2+\beta_3$               |
| **Difference** | $\beta_1$           | $\beta_1+\beta_4$                               | **Treatment Effect:** $\beta_4$ |

**According to our hypothesis, $\beta_4$ should be positive and significant for competitive projects, and insignificant for non-competitive projects.**

## Combined Model

* The model below will give the same result as subsample analysis, but also allow us to test whether difference between the two treatment effects is statistically significant. 

$$Delay_{it}=\beta_0 +\beta_1 Treat_i+ \beta_2 StartedAfterQP_i+ \beta_3 Post_t+ \beta_4 Competitive_i\\ \qquad + \beta_5 (Treat_i \times Competitive_i) + \beta_6 (Post_t \times Competitive_i)\\ \qquad + \beta_7 (StartedAfterQP_i \times Competitive_i) +\beta_8 (Treat_i×Post_t×StartedAfterQP_i )\\ \qquad +\beta_9 (Treat_i×Post_t×StartedAfterQP_i \times Competitive_i) + \epsilon_{it}$$

* Note: $Post_t = 0 \implies StartedAfterQP_i = 0$
  * These projects don’t exist in the period before QuickPay

For non-competitive projects:

|                | Before QP           | After QP                                  | Difference                      |
| -------------- | ------------------- | ----------------------------------------- | ------------------------------- |
| Small Projects | $\beta_0 + \beta_1$ | $\beta_0+\beta_1+\beta_2+\beta_3+\beta_8$ | $\beta_2+\beta_3+\beta_8$       |
| Large Projects | $\beta_0$           | $\beta_0 + \beta_2 +\beta_3$              | $\beta_2+\beta_3$               |
| **Difference** | $\beta_1$           | $\beta_1+\beta_8$                         | **Treatment Effect:** $\beta_8$ |

For competitive projects:

|                | Before QP                           | After QP                                             | Difference                                           |
| -------------- | ----------------------------------- | ---------------------------------------------------- | ---------------------------------------------------- |
| Small Projects | $\beta_0 + \beta_1+\beta_4+\beta_5$ | $\sum_{i=0}^{9} \beta_i$                             | $\beta_2+\beta_3+\beta_6 +\beta_7+\beta_8 + \beta_9$ |
| Large Projects | $\beta_0+\beta_4$                   | $\beta_0 + \beta_2 +\beta_3+\beta_4+\beta_6+\beta_7$ | $\beta_2+\beta_3+\beta_6+\beta_7$                    |
| **Difference** | $\beta_1+\beta_5$                   | $\beta_1+\beta_5+\beta_8+\beta_9$                    | **Treatment Effect:** $\beta_8+\beta_9$              |

**According to our hypothesis, $\beta_9$ should be positive and significant. That is the difference in treatment effect for competitive and non-competitive projects is significant.**

## Combined Model with Old Projects 

$$Delay_{it}=\beta_0 +\beta_1 Treat_i+ \beta_2 StartedAfterQP_i+ \beta_3 Post_t+ \beta_4 Competitive_i\\ \qquad + \beta_5 (Treat_i \times Competitive_i) + \beta_6 (Post_t \times Competitive_i)\\ \qquad + \beta_7 (StartedAfterQP_i \times Competitive_i) +\beta_8 (Treat_i \times Post_t)\\ \qquad + \beta_9 (Treat_i \times Post_t \times Competitive_i) \\ \qquad +\beta_{10} (Treat_i×Post_t×StartedAfterQP_i )\\ \qquad +\beta_{11} (Treat_i×Post_t×StartedAfterQP_i \times Competitive_i) + \epsilon_{it}$$

* Note: $Post_t = 0 \implies StartedAfterQP_i = 0$
  * These projects don’t exist in the period before QuickPay

#### Started Before QP:

For non-competitive projects:

|                | Before QP           | After QP                          | Difference                      |
| -------------- | ------------------- | --------------------------------- | ------------------------------- |
| Small Projects | $\beta_0 + \beta_1$ | $\beta_0+\beta_1+\beta_3+\beta_8$ | $\beta_3+\beta_8$               |
| Large Projects | $\beta_0$           | $\beta_0 +\beta_3$                | $\beta_3$                       |
| **Difference** | $\beta_1$           | $\beta_1+\beta_8$                 | **Treatment Effect:** $\beta_8$ |

For competitive projects:

|                | Before QP                          | After QP                                                     | Difference                              |
| -------------- | ---------------------------------- | ------------------------------------------------------------ | --------------------------------------- |
| Small Projects | $\beta_0 +\beta_1+\beta_4+\beta_5$ | $\beta_0+\beta_1+\beta_3+\\ \beta_4+\beta_5+\beta_6+\\ \beta_8+\beta_9$ | $\beta_3+\beta_6+\beta_8+\beta_9$       |
| Large Projects | $\beta_0+\beta_4$                  | $\beta_0 +\beta_3+\beta_4+\beta_6$                           | $\beta_3+\beta_6$                       |
| **Difference** | $\beta_1+ \beta_5$                 | $\beta_1+\beta_5+\beta_8+ \beta_9$                           | **Treatment Effect:** $\beta_8+\beta_9$ |

Difference between competitive and non-competitive projects: $\beta_9$

#### Started After QuickPay

For non-competitive projects:

|                | Before QP           | After QP                                               | Difference                                 |
| -------------- | ------------------- | ------------------------------------------------------ | ------------------------------------------ |
| Small Projects | $\beta_0 + \beta_1$ | $\beta_0+\beta_1+\\\beta_2+\beta_3+\beta_8+\beta_{10}$ | $\beta_2+\beta_3+\beta_8+\beta_{10}$       |
| Large Projects | $\beta_0$           | $\beta_0+\beta_2 +\beta_3$                             | $\beta_2+\beta_3$                          |
| **Difference** | $\beta_1$           | $\beta_1+\beta_8+\beta_{10}$                           | **Treatment Effect:** $\beta_8+\beta_{10}$ |

For competitive projects:

|                | Before QP                          | After QP                                                     | Difference                                                   |
| -------------- | ---------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Small Projects | $\beta_0 +\beta_1+\beta_4+\beta_5$ | $\beta_0+\beta_1+ \beta_2 +\beta_3+\\ \beta_4+\beta_5+\beta_6+\\ +\beta_7+\beta_8+\beta_9+\\\beta_{10}+\beta_{11}$ | $\beta_2+\beta_3+\\ \beta_6+\beta_7+\\ \beta_8+\beta_9+\\ \beta_{10}+\beta_{11} $ |
| Large Projects | $\beta_0+\beta_4$                  | $\beta_0+\beta_2 +\beta_3+\beta_4+\beta_6+\beta_7$           | $\beta_2 +\beta_3+\\ \beta_6 + \beta_7$                      |
| **Difference** | $\beta_1+ \beta_5$                 | $\beta_1+\beta_5+\\ \beta_8+ \beta_9 \\ \beta_{10}+\beta_{11}$ | $\beta_8+\beta_9 +\beta_{10}+\beta_{11}$                     |

Difference between competitive and non-competitive projects: $\beta_9+\beta_{11}$

**Interpretation: $\beta_{11}$ is the additional treatment effect for (small) competitive projects signed after QuickPay (relative to those that started before the policy). ** 

