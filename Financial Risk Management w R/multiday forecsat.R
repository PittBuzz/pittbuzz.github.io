# Foreign Exxchange

library(quantmod) 
getSymbols("DEXUSAL", src = "FRED") 
wilsh <- na.omit(DEXUSAL) 
wilsh <- wilsh["1979-12-31/2017-12-31"] 
#wilsh <- 1 / wilsh
names(wilsh) <- "ER"

# Next, we calculated its daily log returns: 
logret <- diff(log(wilsh))[-1] 


library(moments) 
rvec <- as.vector(logret) 
round(skewness(rvec),2) 


rvec <- as.vector(logret) 
round(kurtosis(rvec),2) 

rvec <- as.vector(logret) 
jarque.test(rvec) 

mu <- round(mean(logret), 6) 
sig <- round(sd(logret), 6) 

mu


library(MASS) 
rvec <- as.vector(logret) 
t.fit <- fitdistr(rvec, 't') 
round(t.fit$estimate,6)

# one day return

alpha <- 0.01 
set.seed(123789) 
library(metRology) 
rvec <- rt.scaled(100000,mean=t.fit$estimate[1],sd=t.fit$estimate[2],df=t.fit$estimate[3]) 
VaR <- quantile(rvec,alpha) 
ES <- mean(rvec[rvec<VaR]) 

round(VaR,6) 
round(ES,6)

# ten day horizon
# Sim 1

RNGkind(sample.kind = 'Rounding') 
set.seed(123789) 
rvec <- rep(0,100000) 
for (i in 1:10) { 
  rvec <- rvec+rt.scaled(100000,mean=t.fit$estimate[1],sd=t.fit$estimate[2],df=t.fit$estimate[3]) 
} 
VaR <- quantile(rvec,alpha) 
ES <- mean(rvec[rvec<VaR]) 


round(VaR,6) 
round(ES,6)

# Sim 2

RNGkind(sample.kind = 'Rounding') 
set.seed(123789) 
rvec <- rep(0,100000) 
for (i in 1:10) { 
  rvec <- rvec+ sample(as.vector(logret),100000,replace=TRUE) 
} 

VaR <- quantile(rvec,alpha) 
ES <- mean(rvec[rvec<VaR])

round(VaR,6) 
round(ES,6)

# Sim 3

RNGkind(sample.kind = 'Rounding')
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

round(VaR,6) 
round(ES,6)
