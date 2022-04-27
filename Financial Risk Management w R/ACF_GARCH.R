## Exercise 12 – Serial Correlation, Volatility Clustering, GARCH 

# ACF for log returns and |log returns| / GARCH for the Wilshire 5000 index

library(quantmod) 
getSymbols("WILL5000IND",src="FRED") 
wilsh <- na.omit(WILL5000IND) 
wilsh <- wilsh["1979-12-31/2017-12-31"] 
names(wilsh) <- "TR" 

# Next, we calculated its daily log returns: 
  
logret <- diff(log(wilsh))[-1] 

# graph the auto_correlation funtion

acf(logret) 

# graph the absolute value for acf

acf(abs(logret))

# To estimate the GARCH(1,1) –t model, we use the “rugarch” package in R: 
  
library(rugarch) 
uspec <- ugarchspec(variance.model = list(model = "sGARCH",garchOrder = c(1,1)), 
                     mean.model = list(armaOrder = c(0,0), include.mean = TRUE), 
                     distribution.model = "std") 
fit.garch <- ugarchfit(spec = uspec, data = logret[,1]) 

# The estimated parameters are in 

fit.garch@fit$coef 

# The output of the estimation are then saved: 

save1 <- cbind( logret[,1], fit.garch@fit$sigma, fit.garch@fit$z ) 
names(save1) <- c( 'logret', 's', 'z' ) 

# check the acf of the z column to see if GARCH caputered volatility

acf(save1$z) 
acf(abs(save1$z))

## ACF for log returns and |log returns| / GARCH for Gold

load('_FRED_gold.rda')

gold <- na.omit(gold)
gold <- gold["1979-12-31/2017-12-31"] 

logret_g <-  diff(log(gold))[-1]

head(logret_g)
tail(logret_g)

acf(logret_g) 
acf(abs(logret_g))

uspec <- ugarchspec(variance.model = list(model = "sGARCH",garchOrder = c(1,1)), 
                    mean.model = list(armaOrder = c(0,0), include.mean = TRUE), 
                    distribution.model = "std") 
fit.garch <- ugarchfit(spec = uspec, data = logret_g[,1])

round(fit.garch@fit$coef,6) 


save1 <- cbind( logret_g[,1], fit.garch@fit$sigma, fit.garch@fit$z ) 
names(save1) <- c( 'logret', 's', 'z' ) 

# check the acf of the z column to see if GARCH caputered volatility

acf(save1$z) 
acf(abs(save1$z))

## Exercise 13 – VaR and ES from GARCH bootstrap 

#VaR and ES in GARCH bootstrap for the Wilshire 5000 index

library(quantmod) 
getSymbols("WILL5000IND",src="FRED") 
wilsh <- na.omit(WILL5000IND) 
wilsh <- wilsh["1979-12-31/2017-12-31"] 
names(wilsh) <- "TR" 

# Next, we calculated its daily log returns:

logret <- diff(log(wilsh))[-1] 

# To estimate the GARCH(1,1) –t model, we use the “rugarch” package in R: 

library(rugarch) 
uspec <- ugarchspec( variance.model = list(model = "sGARCH",garchOrder = c(1,1)), 
                     mean.model = list(armaOrder = c(0,0), include.mean = TRUE), 
                     distribution.model = "std") 
fit.garch <- ugarchfit(spec = uspec, data = logret[,1]) 

# The estimated parameters are in 

fit.garch@fit$coef 

# The output of the estimation are then saved: 

save1 <- cbind( logret[,1], fit.garch@fit$sigma, fit.garch@fit$z ) 
names(save1) <- c('logret', 's', 'z') 

# We use the R function “ugarchboot” to simulate 1-day outcomes: 

RNGkind(sample.kind = 'Rounding')
set.seed(123789) #set seed value 
boot.garch <- ugarchboot(fit.garch, 
                         method=c("Partial","Full")[1], # ignore parameter uncertainty 
                         sampling="raw", # draw from standardized residuals 
                         n.ahead=1, # 1-day ahead 
                         n.bootpred=100000, # number of simulated outcomes 
                         solver= 'solnp') 
                         
# The simulated outcomes are then saved in the vector “rvec”: 

rvec <- boot.garch@fseries

# The VaR and ES at the 95% confidence level are calculated as before: 

VaR <- quantile(rvec,0.05) 
ES <- mean(rvec[rvec<VaR])

# Gold

load('_FRED_gold.rda')

gold <- na.omit(gold)
gold <- gold["1979-12-31/1987-10-19 "] 

logret_g <-  diff(log(gold))[-1]


head(logret_g)
tail(logret_g)

acf(logret_g) 
acf(abs(logret_g))

uspec <- ugarchspec(variance.model = list(model = "sGARCH",garchOrder = c(1,1)), 
                    mean.model = list(armaOrder = c(0,0), include.mean = TRUE), 
                    distribution.model = "std") 
fit.garch <- ugarchfit(spec = uspec, data = logret_g[,1])



round(fit.garch@fit$coef,6) 


save1 <- cbind( logret_g[,1], fit.garch@fit$sigma, fit.garch@fit$z ) 

names(save1) <- c( 'logret', 's', 'z' ) 

RNGkind(sample.kind = 'Rounding')
set.seed(123789) #set seed value 
boot.garch <- ugarchboot(fit.garch, 
                         method=c("Partial","Full")[1], # ignore parameter uncertainty 
                         sampling="raw", # draw from standardized residuals 
                         n.ahead=1, # 1-day ahead 
                         n.bootpred=100000, # number of simulated outcomes 
                         solver= 'solnp') 

rvec <- boot.garch@fseries

VaR <- quantile(rvec,0.05) 
ES <- mean(rvec[rvec<VaR])

round(VaR,6)
round(ES, 6)
