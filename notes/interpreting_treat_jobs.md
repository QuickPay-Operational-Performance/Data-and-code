$Delay_{p,t}=a+b*Treat_p +c*(Treat\times Post) + d*(Treat\times Jobs)+ e*Post + f*Jobs +e$

* Let $t_{jobs}$ denote the time period when Jobs act was launched
* Let $t_{qp}$ denote the time period QP was launched
* $t_{jobs}<t_{qp}$
* Let $t=0$ denote start of the observation horizon, and $t=T$ denote the end of the observation horizon
* $Jobs=1$ if $t>t_{jobs}$
*  $Post=1$ if $t>t_{qp}$

## Small businesses 

* SB before Jobs act
  * $Jobs = 0 \implies Post =0$
  * $Delay=a+b$

* SB after Jobs act but before QP
  * $Jobs = 1 , Post =0$
  * $Delay=a+b+d+f$
* SB after QP
  * $Post=1 \implies Jobs =1$
  * $Delay = a+b+c+d+e+f$​

## Large businesses 

* LB before Jobs act
  * $Jobs = 0 \implies Post =0$
  * $Delay=a$

* LB after Jobs act but before QP
  * $Jobs = 1 , Post =0$
  * $Delay=a+f$
* LB after QP
  * $Post=1 \implies Jobs =1$
  * $Delay = a+e+f$

## $Treat \times Jobs$

* Small after jobs act but before QP - Small before Jobs act
  *  $(a+b+d+f)-(a+b)=d+f$
* Large after jobs act but before QP - Large before Jobs act
  * $(a+f)-a=f$

* Diff-in-diff= $(d+f)-f=d$
* $d=\Delta Delays_{[t_{jobs},t_{qp}]}-\Delta Delays_{[0,t_{jobs}]}$
* This is the treatment effect of Jobs act before QP

## $Treat \times Post$

* Small after QP - Small before QP (but after Jobs)
  *  $(a+b+c+d+e+f)-(a+b+d+f)=c+e$
* Large after QP - Large before QP (but after Jobs)
  * $(a+e+f)-(a+f)=e$​
* Diff-in-diff =  $(c+e)-e=c$

* $c=\Delta Delays_{[t_{qp},T]}-\Delta Delays_{[t_{jobs},t_{qp}]}$
* This is the treatment effect of QP relative to the time period after Jobs act

---

* Small after QP - Small before Jobs
  *  $(a+b+c+d+e+f)-(a+b)=c+d+e+f$
* Large after QP - Large before Jobs
  * $(a+e+f)-(a)=e+f$​
* Diff-in-diff =  $(c+d+e+f)-(e+f)=c+d$

* $c+d=\Delta Delays_{[t_{qp},T]}-\Delta Delays_{[0,t_{jobs}]}$
* Not clear what this can be attributed to... 