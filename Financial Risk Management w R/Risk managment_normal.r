# Exercise 5 – Estimating Parameters of the Normal Distribution

## In the lectures, we ran the following R script to create a data series called “wilsh”: 

library(quantmod) 

getSymbols("WILL5000IND",src = "FRED") 
wilsh <- na.omit(WILL5000IND) 
wilsh <- wilsh["1979-12-31/2017-12-31"] 
names(wilsh) <- "TR" 

# Next, we calculated its daily log returns: 

logret <- diff(log(wilsh))[-1] 

# estimate the parameters of the nor,al distribution mean and standard deviation

round( mean(logret), 8) 
round( sd(logret), 8) 


# Returns of the Archived Gold Prices from FRED

load('_FRED_gold.rda')

gold <- na.omit(gold)

logret_g <-  diff(log(gold))[-1]
head(logret_g)
tail(logret_g)

mu <- round(mean(logret_g), 8) 
sig <- round(sd(logret_g), 8) 


## Exercise 6 – Estimating Value-at-Risk (VaR) of the Normal Distribution

# The VaR at the 95% confidence level for the daily log returns:

var <- qnorm(0.05,mu,sig) 

HFvar <- 1000 * ( exp(var)-1 ) # in millions of dollars

var
HFvar

## Exercise 7 – Estimating Expected Shortfall (ES) of the Normal Distribution

# The ES at the 95% confidence level for the daily log returns can be calculated using the 
# estimated mean (mu) and estimated standard deviation (sig): 

es <- mu-sig*dnorm(qnorm(0.05,0,1),0,1)/0.05 

# We can now find the ES of the daily change in its assets, at the 95% confidence level, using the following R command: 

HFvar <- 1000 * ( exp(es)-1 ) # in millions of dollars

es
HFvar

## Exercise 8 – Estimating VaR and ES via simulation

# Simulate from the normal distribution (mu, sig):

set.seed(123789) # pseudo random
rvec <- rnorm(100000, mu, sig) # 100,000 samples

# The VaR at the 95% confidence level is the 5% quantile of these 100,000 outcomes

VaR <- quantile(rvec, 0.05)

#The ES as the 95% confidence level is the average of these 100,000 outcomes that are worse than the VaR. 

ES <- mean(rvec[rvec < VaR])

# The second simulation method does not assume that daily log returns are normally distributed. 

RNGkind(sample.kind = "Rounding") # fix the random discrepency with new version of R
set.seed(123789) 
rvec_2 <- sample(as.vector(logret_g), 100000, replace = TRUE) # with replacement

VaR_2 <- quantile(rvec_2,0.05) 

ES_2 <- mean(rvec_2[rvec_2 < VaR_2])

VaR
ES

VaR_2
ES_2



