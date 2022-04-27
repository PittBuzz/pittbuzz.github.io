#load packages
library(tableone)
library(Matching)
library(MatchIt)

expit <- function(x) {1/(1+exp(-x)) }
logit <- function(p) {log(p)-log(1-p)}

data(lalonde)
str(lalonde)



#create a new dataset
age <- lalonde$age
educ <- lalonde$educ
black <-as.numeric(lalonde$race=='black')
hispan <- as.numeric(lalonde$race=='hispan')
white <- as.numeric(lalonde$race=='white')
married <- lalonde$married
nodegree <- lalonde$nodegree
re74 <- lalonde$re74
re75 <- lalonde$re75
re78 <- lalonde$re78
treat <- lalonde$treat

df <- cbind(age
            , educ
            , black
            , hispan
            , married
            , nodegree
            , re74
            , re75
            , re78
            , treat)

#new table
df <- data.frame(df)



#covariates we will use (shorter list than you would use in practice)
xvars<-c("age","educ","black","hispan","married","nodegree",
         "re74","re75", 're78')

table1<- CreateTableOne(vars=xvars,strata="treat", data = df, test=FALSE)

#standardized mean difference (SMD)
print(table1,smd=TRUE)


#propensity score model
psmodel <- glm(treat ~ age 
              + educ
              + black
              + hispan
              + married
              + nodegree
              + re74
              + re75
              , family  = binomial()
              , data = df)

## value of propensity score for each subject
ps <-predict(psmodel, type = "response")               

summary(ps)      


### We will now carry out propensity score using
### the Match function

set.seed(931139)

#create propensity score
pscore <- psmodel$fitted.values

#logit <- function(p) {log(p)-log(1-p)}
psmatch <- Match (Tr = df$treat, M=1,
               X = pscore, replace = FALSE,
               caliper = 0.1)
matched <- df[unlist(psmatch[c("index.treated","index.control")]), ]
xvars<-c("age","educ","black","hispan","married","nodegree",
         "re74","re75", 're78')

#get standardized differences
matchedtab1 <- CreateTableOne(vars = xvars, 
                              strata ="treat", 
                            data = matched, test = FALSE)
print(matchedtab1, smd = TRUE)

#outcome analysis
y_trt <- matched$re78[matched$treat==1]
y_con <- matched$re78[matched$treat==0]

#pairwise difference
diffy < -y_trt-y_con

#paired t-test
t.test(diffy)
