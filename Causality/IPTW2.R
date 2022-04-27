#load packages
library(tableone)
library(ipw)
library(sandwich) #for robust variance estimation
library(survey)
library(MatchIt)
library(Matching)

data("lalonde")
str(lalonde)

expit <- function(x) {1/(1+exp(-x)) }
logit <- function(p) {log(p)-log(1-p)}

df <- data.frame(lalonde)
str(df)

#covariates we will use (shorter list than you would use in practice)
xvars<-c("age","educ","black","hisp","married","nodegr",
         "re74","re75", 're78', 'u74', 'u75')

table1<- CreateTableOne(vars=xvars,strata="treat", data = df, test=FALSE)

## include standardized mean difference (SMD)
print(table1,smd=TRUE)

#propensity score model
psmodel <- glm(treat ~ age 
               + educ
               + black
               + hisp
               + married
               + nodegr
               + re74
               + re75
               + u74
               + u75
               , family  = binomial(link ="logit")
               , data = df)

## value of propensity score for each subject
ps <-predict(psmodel, type = "response")

summary(ps)

#create weights
weight <- ifelse('treat' == 1, 1/(ps), 1/(1-ps))

#apply weights to data
weighteddata <- svydesign(ids = ~ 1, data = df, weights = ~ weight)

#weighted table 1
weightedtable <- svyCreateTableOne(vars = xvars, strata = "treat", 
                                  data = weighteddata, test = FALSE)
## Show table with SMD
print(weightedtable, smd = TRUE)

#to get a weighted mean for a single covariate directly:
mean(weight['treat' == 1] * age['treat' == 1]) / (mean(weight['treat' == 1]))
