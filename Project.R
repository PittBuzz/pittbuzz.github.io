library(lubridate)

df <- read_csv('data_complaints.csv')


Q1 <- df %>%
  group_by(State) %>%
  mutate(`Date received` = mdy(`Date received`)) %>%
  filter(Product  == 'Student loan', `Date received` > '2018-01-01') %>% 
  count() %>%
  arrange(desc(n))

Q1

glimpse(Q2)

Q2 <- df %>%
 
  mutate(`Date received` = mdy(`Date received`)) %>%
  mutate(`Date sent to company` = mdy(`Date sent to company`)) %>%
  mutate(avg_time =  `Date sent to company` - `Date received`) %>%
  filter(`Submitted via` == 'Email') 
summary(Q2) 

mean(Q2$avg_time, rm.na = T)  

library(tidytext)
Q3 <-  df %>%
  filter(Product == 'Credit card or prepaid card') %>%
  drop_na(`Consumer complaint narrative`)

Q3 %>%
   mutate(`Consumer complaint narrative` = as.character
         (`Consumer complaint narrative`)) %>%
  unnest_tokens(word, `Consumer complaint narrative`) %>%
  filter(word %in% c('student', 'Student')) %>%
  count(word)
  
  

 

Q4 <- df %>%
  filter(Product =='Student loan') %>%
  group_by(Issue) %>%
  summarize(Count = n()) %>%
  arrange(desc(Count))

Q4  


Q5 <- df %>%
  filter(Product  == 'Mortgage') %>%
  select(Product) %>%
  mutate(`Consumer complaint narrative` = na.omit(df$`Consumer complaint narrative`))
  
 



separate(year, sep="__", 
         into = c("year", "name"), 
         convert = TRUE) 
  