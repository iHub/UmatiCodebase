
'
Script    : Classification
Created   : November 21, 2014
Author(s) : iHub Research
Version   : v1.0
License   : Apache License, Version 2.0
'
#=================================================================== CLASSIFICATION ================================================================================
# Load Required Libraries
library(tm)
library(tm)
library(klaR)
library(caret)
library(RWeka)
#=================================================================== SETTINGS ======================================================================================
# Set Working Directory
setwd('~')

# Set Default Number of Threads
options(mc.cores=1)

# Set Java Heap Size
options(java.parameters = "-Xmx2g")

#=================================================================== LOAD DATA ======================================================================================
# Load Annotated CSV File
a <-read.csv('~')

# ==================================================================  FEATURE EXTRACTION ============================================================================
#Create Bigram Tokenizer 
BigramTokenizer <- function(x) NGramTokenizer(x, Weka_control(min = 2, max = 2))

# Create a Term-Document Matrix
corpus <-Corpus(VectorSource(a$text))
tdm <-DocumentTermMatrix(corpus,control=list(removePunctuation=TRUE,tolower=TRUE,stopwords='english',tokenizer=BigramTokenizer))

#Bind Bigrams to Bigrams as Additional Column
features <-as.data.frame(as.matrix(tdm))
label <-a$label
compute <-cbind(features,label)

#================================================================= CREATE PREDICTION MODEL =============================================================================
# Select Target and Feature Variables
x <-compute[-c(ncol(compute - 1))]
y <-as.factor(compute$label)
model <-train(x,y,'nb',trControl=trainControl(method='cv',number=10))

# Prediction
d <-predict(model,features)

# Confusion Matrix to Visualize Classification Errors
table(predict(model$finalModel,x)$class,)

