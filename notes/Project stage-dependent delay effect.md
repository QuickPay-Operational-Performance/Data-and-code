# Project stage-dependent delay effect

Consider a project that has two sequential tasks, where the second task cannot start until the first task is completed. Upon completion, each task generates a deliverable with associated payments $P_1$ and $P_2$.

The contractor determines the completion times of the tasks by controlling its effort level. Let $t_i$ denote the completion time of task $i$ ($i=1,2$). A shorter completion time implies a higher effort level and thus a higher cost for the contractor. Let $c_i(t)$ denote the cost of completing task $i$ with time $t$. The two tasks may have different costs but both $c_1$ and $c_2$ are increasing convex in $t$. The different costs $c_1$ and $c_2$ imply that it more be easier to change the completion time of one task than the other.

Let $\tau$ denote the payment delay. Then completion times $(t_1,t_2)$ imply that the first task is completed at $t_1$, the second task at $t_1+t_2$. The contractor receives $P_1$ at $t_1+\tau$ and the contractor receives $P_2$ at $t_1+t_2+\tau$. (This is the first-best scenario where the contractor is not financially constrained, i.e., it does not rely on the payment to continue the project.)

Let $r$ denote the discount rate. The contractor determines $(t_1,t_2)$ given delay $\tau$ by maximizing the present value of its profit:
$$
v(t_1,t_2)=P_1e^{-r(t_1+\tau)}+P_2e^{-r(t_1+t_2+\tau)}-c(t_1)-c(t_2)e^{-rt_1}
$$
The optimal $(t_1^*,t_2^*)$ satisfies the first-order conditions:
$$
\frac{\partial v(t^*_1,t^*_2)}{\partial t_1}= 0,\qquad \frac{\partial v(t^*_1,t^*_2)}{\partial t_2}.
$$
The second-order conditions are: $\frac{\partial^2 v(t^*_1,t^*_2)}{\partial t_1^2}< 0$, $\frac{\partial^2 v(t^*_1,t^*_2)}{\partial t_2^2}<0$.

The optimal completion times $(t_1^*,t_2^*)$ are functions of the payment delay $\tau$. Using equ. (2) and totally differentiating wrt to $(t_1,\tau)$ and $(t_2,\tau)$ yields:
$$
\begin{align}
\frac{\partial t_1^*}{\partial \tau}=-\frac{\partial^2 v(t^*_1,t^*_2)}{\partial t_1\partial \tau}/\frac{\partial^2 v(t^*_1,t^*_2)}{\partial t_1^2},\\
\frac{\partial t_2^*}{\partial \tau}=-\frac{\partial^2 v(t^*_1,t^*_2)}{\partial t_2\partial \tau}/\frac{\partial^2 v(t^*_1,t^*_2)}{\partial t_2^2}.
\end{align}
$$
Note that
$$
\frac{\partial^2 v(t_1,t_2)}{\partial t_1\partial \tau}=r^2e^{-r(t_1+\tau)}P_1+r^2e^{-r(t_1+t_2+\tau)}P_2,\qquad \frac{\partial^2 v(t_1,t_2)}{\partial t_2\partial \tau}=r^2e^{-r(t_1+t_2+\tau)}P_2.
$$
Thus, under the second-order condition, $\frac{\partial t_1^*}{\partial \tau}>0$, $\frac{\partial t_2^*}{\partial \tau}>0$. But their magnitudes may differ. Clearly, the numerator in equ. (3) is greater than that in equ. (4). But the relative magnitude of the denominators in (3) and (4) is not clear.
$$
\begin{align}
-\frac{\partial^2 v(t_1,t_2)}{\partial t_1^2}&=c''(t_1)+r^2c(t_2)e^{-rt_1}-r^2P_1e^{-r(t_1+\tau)}-r^2P_2e^{-r(t_1+t_2+\tau)},\\
-\frac{\partial^2 v(t_1,t_2)}{\partial t_2^2}&=c''(t_2)e^{-rt_1}-r^2P_2e^{-r(t_1+t_2+\tau)}.
\end{align}
$$
Thus, reducing payment delay $\tau$ generally has an _uneven_ effect on the project progress depending on the stage of the project. 

