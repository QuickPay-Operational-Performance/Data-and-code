# Portfolio model

## Basic idea

We want to see how a firm's response to QuickPay (QP) in terms of project delay depends on the firm's exposure to QuickPay.

**Observations**: projects.

**Dependent variable:** Delay of project *i* in quarter *t*. 

In the classic diff-in-diff model, the treatment effect is constant for all treated objects. We take the difference of the dependent variable in treated group post- and pre-treatment, and then take the difference of the dependent variable in the control group post- and pre-treatment. And under the parallel trend assumption, we substract the control group difference from the treated group difference to tease out the time effect. The remaining part is the treatment effect on the treated group.

We shall do the same thing for the portfolio model but allow the treatment effect to vary within the treated group. Specifically, we hypothesize that the treatment effect depend on the weight of QP projects in a firm's portfolio because the firm responds to QP differently under different weights. 

**Dummy variables:**

- $Post_t=1$ if period $t$ is post-treatment
- $Tr_i=1$ if project $i$ is small-business project

### Tercile model

In the discrete version, we divide the all treated projects, i.e., small-business projects, into three groups.

- **$TrL_i=1$** if *small-business* project $i$ belongs to a firm that has *low exposure to QP*, i.e., the weight of the small-business projects in the firm's portfolio is in the bottom tercile among all firms that have at least one small-business project. Otherwise $TrL_i=0$
- $TrM_i=1$ if *small-business* project $i$ belongs to a firm with *medium exposure to QP*, i.e., the weight of the small-business projects in the firm's portfolio is in the middle tercile among all firms that have at least one small-business project. Otherwise $TrM_i=0$.
- $TrH_i=1$ if *small-business* project $i$ belongs to a firm with *high exposure to QP*, i.e., the weight of the small-business projects in the firm's portfolio is in the top tercile among all firms that have at least one small-business project. Otherwise $TrM_i=0$.

Then if we use the low-exposure group as the baseline treatment group, a bare-bones model would be:
$$
\begin{align}
Y_{it}&=\beta_0+\beta_1\times Tr_i + \beta_2\times TrM_i+\beta_3\times TrH_i +\beta_4\times Post_t\nonumber\\
&\qquad +\beta_5\times Tr_i\times Post_t + \beta_6\times TrM_i\times Post_t + \beta_7\times TrH_i\times Post_t + \epsilon_{it}

\end{align}
$$
The parameters of interest are:

- $\beta_5$: The treatment effect on projects that belong to firms with *low QP exposure*, compared to the non-treated group.
- $\beta_5+\beta_6$: The treatment effect on projects that belong to firms with *medium QP exposure*, compared to the control group. 
  - So $\beta_6$ *is the increase in the treatment effect due to the additional QP exposure, going from low to medium.*
-  $\beta_5+\beta_7$: The treatment effect on projects that belong to firms with *high QP exposure*, compared to the control group. 
  - So $\beta_7$ *is the increase in the treatment effect due to the additional QP exposure, going from low to high.*

### Continuous model

In the continuous version, each *treated* project has a firm-level exposure metric, $\theta_i$. The higher $\theta_i$, the more exposed the firm that owns project $i$ is among all firms. By definition, *$\theta_i>0$ for all treated projects*.

A bare-bones model would be:
$$
\begin{align}
Y_{it}&=\beta_0+\beta_1\times Tr_i + \beta_2\times \theta_i+\beta_3\times \theta_i^2+\beta_4\times Post_t\nonumber\\
&\qquad + \beta_5\times Tr_i\times Post_t + \beta_6\times\theta_i\times Post_t+\beta_7\times \theta_i^2\times Post_t+\epsilon_{it}
\end{align}
$$
Coefficients of interest:

- $\beta_5$ is the constant treatment effect that applies to all treated projects.
- $\beta_6$ is the *additional* treatment effect, on top of the constant treatment effect, per unit of increase in firm QP exposure.
- $\beta_7$ is the *additional* treatment effect, on top of the constant treatment effect, per unit of squared increase in firm QP exposure.

## Formal definitions

Consider project $i$ owned by firm $j$ at time $t$. Define firm $j$'s *QP exposure* as
$$
\rho_{j}=\frac{\text{Firm $j$'s total small-business $FAO$ in year 2010}}{\text{Firm $j$ annual sales in year 2010}}.
$$

### Tercile definition

Consider all firms with at least one small-business projects. Rank the $\rho_j$'s of those firms from low to high.

- All *small-business projects* that are owned by firms in the lowest tercile have $TrL_i=1$.
- All *small-business projects* that are owned by firms in the middle tercile have $TrM_i=1$.
- All *small-business projects* that are owned by firms in the highest tercile have $TrH_i=1$.

Then the model is, with fixed-time effects and other covariates:
$$
\begin{align}
Y_{it}&=\eta_t+\gamma_{i}+\beta_{0}X_i+\beta_1Tr_{i}+\beta_2TrM_i+\beta_3TrH_i+\beta_4Post_t\times X_i\nonumber\\
&\qquad +\beta_5\times Tr_i\times Post_t + \beta_6\times TrM_i\times Post_t + \beta_7\times TrH_i\times Post_t  + \epsilon_{it}
\end{align}
$$
where

- $\eta_t$ is the time fixed effects. Because we have $\eta_t$, we no longer have the $Post_t$ term from equ. (1).
- $\gamma_i$ is the project-level fixed effects, e.g., SPC codes.
- $X_i$ is the project-level characteristics, e.g., initial duration, initial budget. The $\beta_0$ term allows the delay $Y_{it}$ in the control group to vary wrt to $X_i$. The $\beta_4$ term allows the post-treatment period have a different trend compared to the pre-treatment period.

### Continuous definition

Consider all firms with at least one small-business projects. Rank the $\rho_j$'s of those firms from low to high. The firm with the lowest value of $\rho_j$ value has $\hat\rho_j=1/N$, the firm with the second lowest $\rho_j$ value has $\hat\rho_j=2/N$, ..., the firm with the highest $\rho_j$ value has $\hat\rho_j=1$.

For *small-business project* $i$, set $\theta_i=\hat\rho_j$ if project $i$ belongs to firm $j$. 

Then the model is, with fixed-time effects and other covariates:
$$
\begin{align}
Y_{it}&=\eta_t+\gamma_{i}+\beta_{0}X_i+\beta_1Tr_{i}+\beta_2\theta_i+\beta_3\theta^2_i+\beta_4Post_t\times X_i\nonumber\\
&\qquad +\beta_5\times Tr_i\times Post_t + \beta_6\times \theta_i\times Post_t + \beta_7\times \theta^2_i\times Post_t  + \epsilon_{it}
\end{align}
$$
