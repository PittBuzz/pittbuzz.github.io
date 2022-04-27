## Exercise 9 – Skewness, Kurtosis, Jarque-Bera Test for Normality

library(quantmod) 
getSymbols("WILL5000IND",src="FRED") 
wilsh <- na.omit(WILL5000IND) 
wilsh <- wilsh["1979-12-31/2017-12-31"] 
names(wilsh) <- "TR"

# Next, we calculated its daily log returns: 
logret <- diff(log(wilsh))[-1] 


# Skewness: The coefficient of skewness is estimated using the “skewness” function in the “moments” package in R. 

library(moments) 
rvec <- as.vector(logret) 
round(skewness(rvec),2) 

# Kurtosis: The coefficient of kurtosis is estimated using the “kurtosis” function in the “moments” package in R. 

library(moments) 
rvec <- as.vector(logret) 
round(kurtosis(rvec),2) 

# Jarque-Bera test of normality: The JB test of normality is performed using the “jarque.test” function in the “moments” package in R. 

library(moments) 
rvec <- as.vector(logret) 
jarque.test(rvec) 

# Returns of the Archived Gold Prices from FRED

load('_FRED_gold.rda')

gold <- na.omit(gold)

logret_g <-  diff(log(gold))[-1]

head(logret_g)
tail(logret_g)

mu <- round(mean(logret_g), 8) 
sig <- round(sd(logret_g), 8) 

rvec_g <- as.vector(logret_g) 

#skewness

round(skewness(rvec_g),2) 

#kurtosis

round(kurtosis(rvec_g),2) 

# JB test
jarque.test(rvec_g)


round(skewness(rvec),2)

round(kurtosis(rvec),2)


## Exercise 10 – Estimate parameters of the scaled student-t distribution 

# Use the “moments” package in R to estimate the parameters of the scaled student-t distribution: 

library(MASS) 
rvec <- as.vector(logret) 
t.fit <- fitdistr(rvec, 't') 
round(t.fit$estimate,6)

# Using the estimated parameters, we estimated the VaR and ES at the 95% confidence level:

alpha <- 0.05 
set.seed(123789) 
library(metRology) 
rvec <- rt.scaled(100000,mean=t.fit$estimate[1],sd=t.fit$estimate[2],df=t.fit$estimate[3]) 
VaR <- quantile(rvec,alpha) 
ES <- mean(rvec[rvec<VaR]) 
round(VaR,6) 
round(ES,6)

# estimate the gold returns scaled distribtuions

rvec_g <- as.vector(logret_g)
t.fit_g <- fitdistr(rvec_g, 't')
round(t.fit_g$estimate, 6)

alpha <- 0.05
set.seed(123789)

rvec_g <- rt.scaled(100000, mean = t.fit_g$estimate[1], sd = t.fit_g$estimate[2], df = t.fit_g$estimate[3])

var_g <- quantile(rvec_g, alpha)
es_g <- mean(rvec_g[rvec_g < var_g])

round(var_g, 6)
round(es_g, 6)


## Exercise 11 – Estimate VaR and ES at 10-day horizon 


# Simulation Method 1: “moments” package in R to estimate the parameters of the scaled student-t distribution: 
  
library(MASS) 
rvec <- as.vector(logret) 
t.fit <- fitdistr(rvec, 't') 
round(t.fit$estimate,6)

# simulate ten day outcomes repeat 100k

alpha <- 0.05 
set.seed(123789) 
rvec <- rep(0,100000) 
for (i in 1:10) { 
  rvec <- rvec+rt.scaled(100000,mean=t.fit$estimate[1],sd=t.fit$estimate[2],df=t.fit$estimate[3]) 
} 
VaR <- quantile(rvec,alpha) 
ES <- mean(rvec[rvec<VaR]) 

# Simulation Method 2: randomly samples ten 1-day observations from the empirical distribution and add them up

alpha <- 0.05 
set.seed(123789) 
rvec <- rep(0,100000) 
for (i in 1:10) { 
  rvec <- rvec+ sample(as.vector(logret),100000,replace=TRUE) 
} 
VaR <- quantile(rvec,alpha) 
ES <- mean(rvec[rvec<VaR])

# Simulation Method 3: t draws blocks of ten consecutive 1-day outcomes and add them up. Repeat 100,000 times. 

alpha <- 0.05 
set.seed(123789) 
rdat <- as.vector(logret) 
rvec <- rep(0,100000) 
posn <- seq(from=1,to=length(rdat)-9,by=1) 
rpos <- sample(posn,100000,replace=TRUE) 
for (i in 1:10) { 
  rvec <- rvec+ rdat[rpos] 
  rpos <- rpos+1 
} 
VaR <- quantile(rvec,alpha) 
ES <- mean(rvec[rvec<VaR]) 

# VaR and ES at 10-day horizon for Gold

load('_FRED_gold.rda')

gold <- na.omit(gold)

logret_g <-  diff(log(gold))[-1]

head(logret_g)
tail(logret_g)

mu <- round(mean(logret_g), 8) 
sig <- round(sd(logret_g), 8) 

rvec_g <- as.vector(logret_g) 

# estimate the gold returns scaled distribtuions

rvec_g <- as.vector(logret_g)
t.fit_g <- fitdistr(rvec_g, 't')
round(t.fit_g$estimate, 6)

# sim 1

alpha <- 0.05 
set.seed(123789) 
rvec_g <- rep(0,100000) 
for (i in 1:10) { 
  rvec_g <- rvec_g + rt.scaled(100000 ,mean = t.fit_g$estimate[1], sd = t.fit_g$estimate[2], df = t.fit_g$estimate[3]) 
} 

VaR_1 <- quantile(rvec_g, alpha) 
ES_1 <- mean(rvec_g[rvec_g<VaR_1]) 

# sim 2

alpha <- 0.05 
set.seed(123789) 
rvec_g <- rep(0,100000) 
for (i in 1:10) { 
  rvec_g <- rvec_g + sample(as.vector(logret_g), 100000, replace = TRUE) 
} 

VaR_2 <- quantile(rvec_g, alpha) 
ES_2 <- mean(rvec_g[rvec_g<VaR_2])

# sim 3

alpha <- 0.05 
set.seed(123789) 
rdat <- as.vector(logret_g) 
rvec <- rep(0, 100000) 
posn <- seq(from = 1, to = length(rdat)-9,  by= 1) 
rpos <- sample(posn, 100000, replace = TRUE) 
for (i in 1:10) { 
  rvec <- rvec + rdat[rpos] 
  rpos <- rpos + 1 
} 

VaR_3 <- quantile(rvec, alpha) 
ES_3 <- mean(rvec[rvec<VaR_3]) 

round(VaR_1, 6)
round(ES_1, 6)

round(VaR_2, 6)
round(ES_2, 6)

round(VaR_3, 6)
round(ES_3,6)


