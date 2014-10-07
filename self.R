
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
setwd('/Users/amoeba/Downloads')

#Set Default Number of Threads
options(mc.cores=1)

#Set Java Heap Size
options(java.parameters = "-Xmx2g")

#Set Database Credentials
drv <-dbDriver('SQLite')
con <-dbConnect(drv,'twitter.sqlite')

#============================= Get Data ========================================================================================

#Grab Data from Database
sql <-"SELECT * FROM tweet_data WHERE [text] like '%Mpeketoni%' "
b <-dbGetQuery(con,sql)

#============================== Association Mining ===========================================================================

#Create a Term-Document Matrix
corpus <-Corpus(VectorSource(b$text))
tdm <-TermDocumentMatrix(corpus,control=list(removePunctuation=TRUE,tolower=TRUE,stopwords=TRUE))

#Find Associated Words
tmp <-findAssocs(tdm,'raila',0.01)
tmp

#============================ Dynamic SQL Query =============================================================================
df = data.frame()

#dynamic SQL query
for (rn in rownames(tmp))
{
  qry_str = paste("SELECT * FROM likoni WHERE [text] like '%likoni%' AND [text] like '%", rn, "%' ",sep="")
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


#===================== Feature Extraction ====================================================================================

#Define Function Interacting with Datum Box API
getSentiment <- function (text, key){
  text <- URLencode(text);
  
  #save all the spaces, then get rid of the weird characters that break the API, then convert back the URL-encoded spaces.
  text <- str_replace_all(text, "%20", " ");
  text <- str_replace_all(text, "%\\d\\d", "");
  text <- str_replace_all(text, " ", "%20");
  
  
  if (str_length(text) > 360){
    text <- substr(text, 0, 359);
  }
  #######################################################################################################################
  
  data <- getURL(paste("http://api.datumbox.com/1.0/TwitterSentimentAnalysis.json?api_key=", key, "&text=",text, sep=""))
  js <- fromJSON(data, asText=TRUE);
  
  # get mood probability
  sentiment = js$output$result
  
  ######################################################################################################################
  
  data <- getURL(paste("http://api.datumbox.com/1.0/SubjectivityAnalysis.json?api_key=", key, "&text=",text, sep=""))
  js <- fromJSON(data, asText=TRUE);
  
  # get mood probability
  subject = js$output$result
  
  #####################################################################################################################
  
  data <- getURL(paste("http://api.datumbox.com/1.0/TopicClassification.json?api_key=", key, "&text=",text, sep=""))
  js <- fromJSON(data, asText=TRUE);
  
  # get mood probability
  topic = js$output$result
  
  ###################################################################################################################
  data <- getURL(paste("http://api.datumbox.com/1.0/GenderDetection.json?api_key=", key, "&text=",text, sep=""))
  js <- fromJSON(data, asText=TRUE);
  
  # get mood probability
  gender = js$output$result
  
  return(list(sentiment=sentiment,subject=subject,topic=topic,gender=gender))
}

clean.text <- function(some_txt)
{
  some_txt = gsub("(RT|via)((?:\\b\\W*@\\w+)+)", "", some_txt)
  some_txt = gsub("@\\w+", "", some_txt)
  some_txt = gsub("[[:punct:]]", "", some_txt)
  some_txt = gsub("[[:digit:]]", "", some_txt)
  some_txt = gsub("http\\w+", "", some_txt)
  some_txt = gsub("[ \t]{2,}", "", some_txt)
  some_txt = gsub("^\\s+|\\s+$", "", some_txt)
  
  # define "tolower error handling" function
  try.tolower = function(x)
  {
    y = NA
    try_error = tryCatch(tolower(x), error=function(e) e)
    if (!inherits(try_error, "error"))
      y = tolower(x)
    return(y)
  }
  
  some_txt = sapply(some_txt, try.tolower)
  some_txt = some_txt[some_txt != ""]
  names(some_txt) = NULL
  return(some_txt)
}

# clean text
tweet_clean = clean.text(a$message)

# how many tweets
tweet_num = length(tweet_clean)

# data frame (text, sentiment, score)
tweet_df = data.frame(text=tweet_clean, sentiment=rep("", tweet_num),
                      subject=1:tweet_num, topic=1:tweet_num, gender=1:tweet_num, stringsAsFactors=FALSE)


# apply function getSentiment
sentiment = rep(0, tweet_num)
for (i in 1:length(a$message))
{
  tmp = getSentiment(a$message[i], "f8852cf1eeb4db7272658c7ab10401ef")
  
  tweet_df$sentiment[i] = tmp$sentiment
  
  tweet_df$subject[i] = tmp$subject
  tweet_df$topic[i] = tmp$topic
  tweet_df$gender[i] = tmp$gender
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
model <-model = train(x,y,'nb',trControl=trainControl(method='cv',number=10))










