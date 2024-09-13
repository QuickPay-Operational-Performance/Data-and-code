
# Counterexample 1
# p.la=0.8 
# p.lb=0.2 
# 
# p.sa=0.95
# p.sb=0.5

# Counterexample 2
# p.la=0.7 
# p.lb=0.2 
# 
# p.sa=0.9
# p.sb=0.45

# Counterexample 3
# p.la=0.25
# p.lb=0.12
# 
# p.sa=0.95
# p.sb=0.85

# Counterexample 4
# p.la=0.25
# p.lb=0.05
# 
# p.sa=0.91
# p.sb=0.70

# Counterexample 5
# p.la=0.05
# p.lb=0.01
# 
# p.sa=0.15
# p.sb=0.05

# Counterexample 6
# p.la=0.05
# p.lb=0.01
# 
# p.sa=0.1
# p.sb=0.05

# Counterexample 7
# p.la=0.05
# p.lb=0.01
# 
# p.sa=0.15
# p.sb=0.06

# Counterexample 8
# p.la=0.05
# p.lb=0.01
# 
# p.sa=0.15
# p.sb=0.10

# Counterexample 9
# p.la=0.05
# p.lb=0.01
# 
# p.sa=0.1
# p.sb=0.05

# Counterexample 10
# p.la=0.25
# p.lb=0.15
# 
# p.sa=0.1
# p.sb=0.05

# Counterexample 11
p.la=0.25
p.lb=0.15

p.sa=0.12
p.sb=0.06

delta.alpha=(p.sa-p.sb)-(p.la-p.lb)

treat.post=(log(p.sa/(1-p.sa))-log(p.sb/(1-p.sb)))-
           (log(p.la/(1-p.la))-log(p.lb/(1-p.lb)))

round(delta.alpha,2)
round(treat.post,2)