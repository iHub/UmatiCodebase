
'
Script    : Self-Annotation
Created   : November 21, 2014
Author(s) : iHub Research
Version   : v1.0
License   : Apache License, Version 2.0
'

#============================ Set Environment  =============================================================================

#Load Required Packages
library(RSQLite)
library(stringdist)
library(tm)
library(klaR)
library(caret)
library(RWeka)
library(RCurl)
library(RJSONIO)
library(stringr)

#============================ Settings ======================================================================================

#Set Working Directory
setwd('~')

#Set Default Number of Threads
options(mc.cores=1)

#Set Java Heap Size
options(java.parameters = "-Xmx2g")

#Set Database Credentials
drv <-dbDriver('SQLite')
con <-dbConnect(drv,'twitter.sqlite')

#============================= Get Data ========================================================================================

# Event
event = ''

# Grab Data from Database
sql <-paste("SELECT * FROM tweet_data WHERE [text] like '% " , event, "%' ",sep="")
a <-dbGetQuery(con,sql)

# ============================== Association Mining ===========================================================================

#Create a Term-Document Matrix
corpus <-Corpus(VectorSource(b$text))
tdm <-TermDocumentMatrix(corpus,control=list(removePunctuation=TRUE,tolower=TRUE,stopwords=TRUE))

# Compute Optimal Lower Correlation Limit
tokens = MC_tokenizer(a$text)
len = length(unique(tokens))
cor_limit = len/nrow(a)*0.1

#Find Associated Words
tmp <-findAssocs(tdm,event,cor_limit)

#============================ Dynamic SQL Query =============================================================================
df = data.frame()

#dynamic SQL query
for (rn in rownames(tmp))
{
  qry_str = paste("SELECT * FROM likoni WHERE [text] like '% ", event, "%'","AND [text] like '% ", rn, "%'" ,sep="")
  df1 <-dbGetQuery(con,qry_str)
  df <-rbind(df1,df)
}

#Remove Duplicate Entries
df_2 <-unique(df)

#============================= Remove Retweets =================================================================================

#Create Empty Data Frame and Matrix
index_to_remove <-data.frame()
mat <-matrix(nrow = nrow(b),ncol = nrow(b))

#Find Retweets with String Distance Metric
for (i in 1:nrow(b))
{
  for (j in 1:nrow(b))
  {
    mat[i,j] <-stringdist(c[i],c[j])
    if(mat[i,j] == 10 | mat[i,j] == 0 | mat[i,j] > 3)
    {
      index_to_remove <-c(index_to_remove,i)
    }
  }
}

#Remove Tweets with Duplicate Inidex
c <-b$text[-c(index_to_remove)]
#========================== Self-Annotation ================================================================================

#Set Default Annotation to FALSE
b$label = F

for (i in 1:nrow(df_2))
{
  for (j in 1:nrow(b))
  {
    distance <-stringdist(df_2$row_names[i],b$row_names[j])
    if (distance == 0)
    {
      b$label[j] = T
      break
    }
  }
}


#================================ Extract Bigrans from Tweets =============================================================
#Set Core for Parallel Processing
options(mc.cores=1) 

#Create Bigram Tokenizer 
BigramTokenizer <- function(x) NGramTokenizer(x, Weka_control(min = 2, max = 2))

#Create Document-Term Matrix using Bigrams
tdm <-DocumentTermMatrix(corpus,control=list(,removePunctuation=TRUE,stopwords=TRUE,tolower=TRUE))
tdm_2 <-removeSparseTerms(tdm,0.99)

#Bind Bigrams to Data Frames as Additional Columns
features <-as.data.frame(as.matrix(tdm_2))
compute <-cbind(features,b)

#==================== Create Prediction Model =============================================================================

x <-compute[,c(1:ncol(compute))]
y <-as.factor(compute$label)
model <-train(x,y,'nb',trControl=trainControl(method='cv',number=10))
