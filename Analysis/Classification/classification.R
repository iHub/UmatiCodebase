
'
Script    : Classification
Created   : November 21, 2014
Author(s) : iHub Research
Version   : v1.0
'

#=================================================================== CLASSIFICATION ================================================================================
# Load Required Libraries
library(e1071) 
library(tm)
library(tm)
library(klaR)
library(caret)
library(RWeka)
#=================================================================== SETTINGS ======================================================================================
#Set Working Directory
setwd('~')

#Set Default Number of Threads
options(mc.cores=1)

#Set Java Heap Size
options(java.parameters = "-Xmx2g")

#=================================================================== LOAD DATA ======================================================================================
# Load Annotated CSV File
a <-read.csv('~')

# ==================================================================  FEATURE EXTRACTION ============================================================================
#Create Bigram Tokenizer 
BigramTokenizer <- function(x) NGramTokenizer(x, Weka_control(min = 2, max = 2))

# Create a Term-Document Matrix
corpus <-Corpus(VectorSource(a$text))
tdm <-TermDocumentMatrix(corpus,control=list(removePunctuation=TRUE,tolower=TRUE,stopwords=TRUE))
tdm1 <-removeSparseTerms(tdm,0.99)

#Bind Bigrams to Bigrams as Additional Column
features <-as.data.frame(as.matrix(tdm_1))
compute <-cbind(features,a$label)

#================================================================= CREATE PREDICTION MODEL =============================================================================
# Select Target and Feature Variables
x <-compute
y <-as.factor(compute['label'])
model <-train(x,y,'nb',trControl=trainControl(method='cv',number=10))


# Feature Extraction
x <-a['label']
y <-a['label']
model <-naiveBayes(x,as.factor(y))

# Prediction
d <-predict(model,matrix)

# Confusion Matrix to Visualize Classification Errors
table(predict(model$finalModel,x)$class,)

