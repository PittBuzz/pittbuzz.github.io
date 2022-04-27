## Retrieve the data on the exchange rate between the Japanese Yen and the US Dollar from FRED:

library(quantmod) 

getSymbols("DEXUSAL", src = "FRED") 
wilsh <- na.omit(DEXUSAL) 
wilsh <- wilsh["1979-12-31/2017-12-31"] 
# wilsh <- 1 / wilsh
names(wilsh) <- "ER" 

head(wilsh)  
tail(wilsh)

# daily log returns

logret <- diff(log(wilsh)) 
head(logret,3) 

logret <- diff(log(wilsh))[-1] 
round(head(logret,3),6) 

# discrete returns
ret <- exp(logret) - 1 
round(head(ret,3),6)

mu <- round(mean(logret), 6) 
sig <- round(sd(logret), 6) 

# assumes normal distribution

var <- round(qnorm(0.01,mu,sig),6)
es <- round(mu-sig*dnorm(qnorm(0.01,0,1),0,1)/0.01, 6) 


# assumes normal with randomn

RNGkind(sample.kind = "Rounding")
set.seed(123789) # pseudo random
rvec <- rnorm(100000, mu, sig)

# sampling

#RNGkind(sample.kind = "Rounding") # fix the random discrepency with new version of R
set.seed(123789) 

rvec <- sample(as.vector(logret), 100000, replace = TRUE)

VaR <- round(quantile(rvec, 0.01),6)
ES <- round(mean(rvec[rvec < VaR]),6)

# expected shortfall of its assets over a day, at the 99% confidence level

HFvar <- round(1000 * ( exp(ES)-1 ),2) # in millions of dollars
HFvar
