#=================================================================== CLASSIFICATION ================================================================================

# Load Required Libraries
library(e1071) 
library(RSQLite)
library(tm)

# Set Database Parameters
drv <-dbDriver('SQLite')
con <-dbConnect(drv,'twitter.sqlite')

# Train Data


# feature extraction
x <-df[,c(40:1445)]
y <-df[,c(12)]
model <-naiveBayes(x,as.factor(y))

# prediction
d <-predict(model,matrix)

#confusion matrix to visualize classification errors
table(predict(model$finalModel,x)$class,)
