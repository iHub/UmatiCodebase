#load library
library(caret)
library(RSQLite)
library(klaR)
library(e1071)

#set working directory
setwd('/Users/umati3/Desktop/Aggregate')

#load data from DB
drv <-dbDriver('SQLite')
con <-dbConnect(drv,'Twitter Data.sqlite')
dbListTables(con)
a <-dbReadTable(con,'twitter_data')

x <-a[,c(3,8,13,14,18,20,21,22,23)]
y <-as.factor(a[,c(2)])

#model
model <-naiveBayes(x,y)

#sample data set
x1 <-sample(x,5)
y1 <-sample(y,5)

#predict
b <-predict(model,x1)



