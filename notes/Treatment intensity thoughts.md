# Treatment intensity

**We want the treatment intensity to represent the extent to which a particular project/firm is affected by QuickPay _when QuickPay is implemented_. **

Our data:

- QuickPay was implemented on April 27, 2011. 
- We have five quarters before the implementation and five quarters after the implementation, from Q1 of 2010 to Q2 of 2012. Label these ten quarters at $t=1,2,...,10$. Then $Post_t=Ind(t\geq6)$, where $Ind(\cdot)$ is the indicator function.

Consider project $i$ owned by firm $j$ at time $t$. Recall that we define $\rho_{ijt}$ as
$$
\rho_{ijt}=\frac{\sum_{k\in\mathcal I_{jt}}FAO_{kt}}{Sales_{jt}}\times Treat_i,
$$
where 

- $FAO_{kt}=$ total federal action obligation on project $k$ in period $t$.
- $\mathcal I_{jt}$ = set of firm $j$'s projects in which firm $j$ is categorized as "small business" and thus benefit from QuickPay.
- $Sales_{jt}=$ total sales of firm $j$ in period $t$.
- $\rho_{ijt}$ is the weight of all small-business projects in firm $j$'s business portfolio if project $i$ is a small-business project. $\rho_{ijt}$ is zero if project $i$ is a large-business project. 

### Estimate treatment intensity of QuickPay

There are a few alternatives:

1. **Use the $\rho_{ijt}$ computed in the _last quarter before_ QuickPay implementation.** This would be the value $\rho_{ij5}$ at $t=5$, Q1 of 2011. 
2. **Use the average weight in the _last year before_ QuickPay implementation.** This means that in equ. (1), we compute the total $FAO_{kt}$ on project $k$ over the four quarters at $t=2,3,4,5$, then divide it the total sales over the four quarters. This might be better than using the first metric because it looks at the entire fiscal year, so we may have less of a problem in government allocating too much cash in a particular quarter and taking some cash back in another quarter. In other words, it smooths out the fluctuation in government obligation.
3. **Use the average weight in _four consecutive quarters before_ QuickPay implementation, excluding the last quarter before QuickPay.** This is similar to the second approach but we exclude the last quarter before QuickPay and use $t=1,2,3,4$. The exclusion of the last quarter guards against a firm's actions, e.g., take on more small-business projects, in anticipation of the implementation of QuickPay. So the exogeneity of the treatment intensity is more likely to be true.

I don't think using $\rho_{ijt}$ _after_ QuickPay implementation ($t\geq6$) is appropriate. The reason is that the very implementation of QuickPay may incentivize a firm to get more small-business projects. Furthermore, if QuickPay does help the firm, then the firm's sales should also be affected. Therefore, the value of $\rho_{ijt}$ _after_ QuickPay implementation embodies the treatment effect itself. 

In contrast, $\rho_{ijt}$ values _before_ QuickPay implementation can be viewed as exogeneous. So by using $\rho_{ijt}$ _before_ QuickPay, our treatment intensity metric captures the different extent to which QuickPay would affect a firm. 

### Model

Let $\hat\rho_{ij}$ denote the treatment intensity computed from $\rho_{ijt}$ using one of the three approaches mentioned above. Note that $\hat\rho_{ij}$ may be undefined for certain projects. This happens if we use the third approach and a small-business project $i'$ of firm $j$ starts in the last quarter ($t=5$) before QuickPay implementation. In this case, if firm $j$ has small-business projects before $t=5$, then we have the value of $\hat\rho_{ij}$ for firm $j$ and can use that for the new project $i'$. If firm $j$ does not have any small-business project before $t=5$, then we would not have such a value. I am not sure what to do in that scenario. (Of course, if we think that the exclusion of last quarter is not necessary, then we wouldn't have this issue. This is because all our projects start before QuickPay and end after QuickPay.)

The value $\hat\rho_{ij}$ is invariant in time and $\hat\rho_{ij}=0$ for all project $i$ in the control group.

Note that $\hat\rho_{ij}$ varies with firm $j$. All small-business projects in firm $j$ have the same value of $\hat\rho_{ij}$. Henceforth, write $\hat\rho_{ij}$ as $\hat\rho_{\cdot j}$ for clarity.

#### Model 1: Continuous treatment intensity

Let $N$ denote the number of firms in the treatment group. Let $\alpha_{j}$ denote the empirical distribution of $\hat\rho_{\cdot j}$. Specifically, sort all $N$ values of $\hat\rho_{\cdot j}$ in increasing order. The firm with the lowest value of $\hat\rho_{\cdot j}$ value has $\alpha_j=1/N$, the firm with the second lowest $\hat\rho_{\cdot j}$ has $\alpha_j=2/N$, ..., the firm with the highest $\hat\rho_{\cdot j}$ has $\alpha_j=1$. 

Define $\theta_{i}$ denote the treatment intensity of project $i$ owned by firm $j$:
$$
\theta_{i}=Treat_i\times\alpha_j\qquad \forall i\in\cup_{t=1,...,5}\,\mathcal I_{jt}.
$$
Run the following regression model:
$$
Delay_{it}=\eta_t+\beta_1\theta_{i}+\beta_2Post_t\times\theta_{i}+\beta_3Post_t\times X_i+\beta_4 X_i + \gamma_{i}+\epsilon_{it}
$$
The parameter of interest of $\beta_2$, which captures the treatment effect on the treated group.

#### Model 2: Discrete treatment intensity

Using $\alpha_j$ computed above, we can divide $\{\alpha_j:j=1,\ldots,N\}$ into $K$ brackets ($K=2,3$). Let $\Theta_i\in\{1,...,K\}$ denote the categorical variable that indicates the treatment intensity of project $i$. 

The model is:
$$
Delay_{it}=\eta_t+\beta_1\Theta_{i}+\beta_2Post_t\times\Theta_{i}+\beta_3Post_t\times X_i+\beta_4 X_i + \gamma_{i}+\epsilon_{it}
$$
The parameter of interest is $\beta_2$, which is a $K$-dim vector. The components in $\beta_2$ estimate the effect of different treatment intensities.