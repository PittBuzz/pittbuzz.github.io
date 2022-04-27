# Retrieve the Wilshire 5000 Index from FRED 

library(quantmod) 
wilsh<-getSymbols("WILL5000IND",src="FRED",auto.assign=FALSE) 
wilsh <- na.omit(wilsh) 
wilsh <- wilsh["1979-12-31/2017-12-31"] 
names(wilsh) <- "TR" 
head(wilsh,3) 
tail(wilsh,3) 


# Using Archived Gold Prices from FRED

load('_FRED_gold.rda')
head(gold)
tail(gold)

# Returns of the Wilshire 5000 Index from FRED

getSymbols("WILL5000IND",src="FRED") 
wilsh <- na.omit(WILL5000IND) 
wilsh <- wilsh["1979-12-31/2017-12-31"] 
names(wilsh) <- "TR" 

# First, run the following R commands to see that the first observation is an “NA”: 

logret <- diff(log(wilsh)) 
head(logret,3) 

# Second, run the following R commend to see that the “NA” in the first observation is removed:

logret <- diff(log(wilsh))[-1] 
round(head(logret,3),6) 

# Third, calculate the discrete returns using the log returns: 

ret <- exp(logret) - 1 
round(head(ret,3),6)

# Returns of the Archived Gold Prices from FRED

gold <- na.omit(gold)

logret_g <-  diff(log(gold))
head(logret_g)
tail(logret_g)


# Longer Horizon Returns of the Whilshire 5000 Index from FRED 
# In the lectures, we ran the following R script to create a data series called “wilsh”: 

#library(quantmod) 
getSymbols("WILL5000IND",src="FRED") 
wilsh <- na.omit(WILL5000IND) 
wilsh <- wilsh["1979-12-31/2017-12-31"] 
names(wilsh) <- "TR" 

# Next, we calculated its daily log returns: 

logret <- diff(log(wilsh))[-1] 
  
# We then used the following R commands to calculate longer horizon log returns: 

logret.w <- apply.weekly(logret,sum) 
logret.m <- apply.monthly(logret,sum) 
logret.q <- apply.quarterly(logret,sum) 
logret.y <- apply.yearly(logret,sum) 

#From these series, we calculated longer horizon discrete returns: 

ret.w <- exp(logret.w)-1 
ret.m <- exp(logret.m)-1 
ret.q <- exp(logret.q)-1 
ret.y <- exp(logret.y)-1 

# Longer Horizon Returns of Gold

logret_g <-  diff(log(gold))[-1]

logret_g.w <- apply.weekly(logret_g,sum) 
logret_g.m <- apply.monthly(logret_g,sum) 
logret_g.q <- apply.quarterly(logret_g,sum) 
logret_g.y <- apply.yearly(logret_g,sum) 

ret_g.w <- exp(logret_g.w)-1 
ret_g.m <- exp(logret_g.m)-1 
ret_g.q <- exp(logret_g.q)-1 
ret_g.y <- exp(logret_g.y)-1 

head(logret_g.w)
head(ret_g.m)
head(ret_g.q)
tail(ret_g.y)



