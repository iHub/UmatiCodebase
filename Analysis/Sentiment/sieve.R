
'
Script    : Sentiment Analysis
Created   : November 21, 2014
Author(s) : iHub Research
Version   : v1.0
'

sieve <- function(sent,object){

      # Load Required Libraries
      library(stringr)
      library(RCurl)
      library(RJSONIO)

      # Load Data
      data <-read.csv('tweets.csv',stringsAsFactors=FALSE)
  
      # Define Function Interacting with Datum Box API
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
      tweet_clean = clean.text(data$x)

      # how many tweets
      tweet_num = length(tweet_clean)

      # data frame (text, sentiment, score)
      tweet_df = data.frame(text=tweet_clean, sentiment=rep("", tweet_num),
                      subject=1:tweet_num, topic=1:tweet_num, gender=1:tweet_num, stringsAsFactors=FALSE)

      # apply function getSentiment
      sentiment = rep(0, tweet_num)
      for (i in 1:length(data$x))
        {
          tmp = getSentiment(data$x[i], "f8852cf1eeb4db7272658c7ab10401ef")
          tweet_df$sentiment[i] = tmp$sentiment
          tweet_df$subject[i] = tmp$subject
          tweet_df$topic[i] = tmp$topic
          tweet_df$gender[i] = tmp$gender
        }

      # write to CSV
      object = 'subjective'
      sent = 'negative'
      
      sub <- subset(tweet_df,tweet_df$sentiment == sent && tweet_df$subject == object)
      write.csv(sub,'sieve.csv')
    }


#-------------------------------- Use Sieve Function ------------------------------------------------------

sieve('positive','subjective')


