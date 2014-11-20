
'
Script    : Collector
Created   : November 21, 2014
Author(s) : iHub Research
Version   : v1.0
License   : Apache License, Version 2.0
'
#============================= Collect Tweets =============================================================================
# Load Required Libraries
library(streamR)
library(twitteR)
library(RSQLite)

# Load Authentication File
load("twitteR_credentials")

# Register Authentication 
registerTwitterOAuth(twitCred)

#============================ Capture Tweets and Push to Database ===========================================================================
# Twitter ID for Tracked Account
UserID = ''

#Capture Tweets and Push to Database
while(TRUE)
{
  # Load Keyword file and Convert to Characters
  keywords <-unlist(read.csv('keys.csv',header=FALSE))
  chr_keywords <-as.character(keywords)
  
  # Capture Tweets via the Streaming API
  filterStream(file.name="tweets.json",track=chr_keywords,tweets=0,timeout=10,oauth=twitCred)
  
  # Convert Tweets from JSON to Data Frame
  try(a <-parseTweets('tweets.json'))
  
  # Listen for New Keyword/Hashtag
  for(thisid in a$user_id_str){
    if(thisid == UserID){
      tmp <-subset(a,a$user_id_str == UserID)
      tmp2<-tmp[,c(1)]
      
      # Add new keyword
      sink('keys.csv',append=TRUE)
      cat(c(',',tmp2))
      sink()
      
      # Log the change
      log <-file('log.txt')
      report <-paste('The Keyword',tmp2,'has been added', 'at', Sys.time())
      writeLines(text=report,con=log,sep=",")
      close(log)
      
      # Capture Tweets via Search API
      search <-searchTwitter(tmp2)
      try(search_df <-twListToDF(search))
      
      # Push Search results to DB in separate table
      dbWriteTable(con1,'search_table',search_df,append=TRUE)
      dbCommit(con)
    }
  }
  
  # Write Tweets to Database
  dbWriteTable(con,'tweet_data',a,append=TRUE)
  dbCommit(con)
  
  # Delete JSON file after Push to DB
  file.remove('tweets.json')
}
