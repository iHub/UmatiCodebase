#Load Required Libraries
library(streamR)
library(twitteR)
library(stringr)
library(tm)


#Load Authentication File
load("twitteR_credentials")

#Register Authentication 
registerTwitterOAuth(twitCred)

#The follow string
following=c("115141256","16712223","25985333","92731878","20087934","11680312","28089461","79596159","154036419","35206251","25979455","53037279")
while(TRUE)
{
  #Capture Tweets via the Streaming API
  filterStream(file.name="tweets.json",follow=following,timeout=600,oauth=twitCred)
  
  #Place the tweets in a dataframe
  try(expr=(tweets=parseTweets('tweets.json', simplify=TRUE)))
  
  #delete the json file
  try(expr=file.remove('tweets.json'))
  
  
  #Filter to remove tweets that mention the follow account but are not from it
  j=length(following)
  filter=NULL #intialise the dataframe to hold the filtered data as empty
  i=1 #initialise the loop counter
  while(i<=j)
  {
    tempFilter=tweets[tweets$user_id_str==following[i], ] #filters tweets based on the user_id based on the following[i]
    filter=rbind(filter,tempFilter) #adds the filtered tweets to the main filter
    i=i+1 #increaments the counter
  }
  tweets=filter #puts the filtered tweets back into the tweets dataframe
  
  #name of the accounts that have tweeted
  accounts=tweets$screen_name
  
  #Extract the text and place it in a dataframe
  tweetsText=tweets$text
  
  #removes the usernames and links from the text of tweets
  tweetsText=gsub("(@)\\w+|(http).*","",tweetsText) 
  
  #Converts all uppercase letters in the textfield of the dataframe into lowercase
  tweetsText=tolower(tweetsText)
  
  #removes all punctuation from the corpus
  tweetsText=gsub("[[:punct:]]","",tweetsText)
  
  #removes the manual retweets(the letters rt)
  tweetsText=gsub("(rt)\\s","",tweetsText)
  
  #Creates a corpus that is used for analysis
  try(expr=(tweetsCorpus = Corpus(VectorSource(iconv(tweetsText,to="utf-8")))))
  
  #Uses the text mining package to remove stopwords from the corpus
  tweetsCorpus= tm_map(tweetsCorpus,removeWords,stopwords("SMART"))
  
  #converts the words back into a list/corpus data type
  #tweetsCorpus = Corpus(VectorSource(tweetsCorpus))
  
  #convert the corpus into a Term document matrix
  tweetsTDM=TermDocumentMatrix(tweetsCorpus)
  
  #convert the Term document matrix into a data frame
  tweetsDF=as.data.frame(inspect(tweetsTDM))
  
  #used to add up the occurance of the words in the DF
  wordCount= as.data.frame(rowSums(tweetsDF))
  
  #formatting the data for presentation
  wordCount$word = rownames(wordCount)
  colnames(wordCount)=c("count","word" )
  
  #arranges the words in decreasing order.
  wordCount=wordCount[order(wordCount$count, decreasing=TRUE), ]
  
  
  #Takes the first 2 highest occuring words and their counts and puts them in variables
  keyWords=head(wordCount$word,2)
  keyCounts=head(wordCount$count,2)
  
  #The loop is used to find out where the 2 highiest occuring words happened
  k=1 #loop counter
  lim=length(wordCount$word)
  occurance=list() 
  repeat{
    b=1
    while(b<=2){
      if(wordCount[b,2]==rownames(tweetsDF)[k]){
        occurance=append(x=occurance,values=k)
      }
      b=b+1
    }
    k=k+1
    if(k>=lim) break()
  }
  occurance=unlist(occurance)
  
  #Loop takes the highest occuring words and tweets them
  i=1
  j=as.integer(head(wordCount$count,1)) #number of times the highest word occured
  
  if(j>=5)
  {
    aLength=length(accounts)
    aCount=list() #stores the accounts
    d=1 #counter that loops through the DF array
    
    while(i<=2)
    {
      repeat{
        if(tweetsDF[occurance[i],d]>=1)
        {
          aCount=append(x=aCount,values=accounts[d])
        }
        d=d+1
        if(d>=aLength) break()
      }
      freq=table(unlist(aCount)) #counts the occurance of the accounts
      Data=as.data.frame(freq) #conversion to dataframe
      
      loop=length(Data[1])
      tAcc=1
      trendAccounts=c() #empty dataframe
      while(tAcc<=loop)
      {
        trendAcc=paste(as.String(Data[tAcc,1]),"(",Data[tAcc,2],")",sep="")
        trendAccounts=append(x=trendAccounts,values=trendAcc)
        tAcc=tAcc+1
      }
      trendAccounts=as.String(trendAccounts)
      
      keyText=paste("The word",keyWords[i],"occured",keyCounts[i],"times",trendAccounts,sep=" ")
      #try(expr=(tweet(text=keyText)))
      #Logs the new key words
      KWReport =paste(keyText, 'at', Sys.time())
      write(x=KWReport,file="KWLog.txt",append=TRUE)
      i=i+1
    }
  }
}
#everything after this line is experimentation
#something=lookupUsers("princelySid,blackorwa")
#f=findFreqTerms(e,lowfreq=2)

accounts=tweets$screen_name
expWC=wordCount
expDF=tweetsDF
dim(tweetsDF)
rownames(tweetsDF)[1]==rownames(wordCount)[1]
#The loop is used to find out where the 2 highiest occuring words happened
k=1
lim=length(expWC$word)
a=list()
repeat{
  b=1
  while(b<=2)
  {
    if(expWC[b,2]==rownames(expDF)[k]){
      a=append(x=a,values=k)
    }
    b=b+1
  }
  k=k+1
  if(k>=lim) break()
}
tret=unlist(a)

#Find the accounts that tweeted the high words
aLength=length(accounts)
aCount=list()
d=1
test=1
repeat{
  repeat{
    if(expDF[tret[test],d]>=1)
    {
      aCount=append(x=aCount,values=accounts[d])
    }
    d=d+1
    if(d>=aLength) break()
  }
  TT=paste(as.String(Data[test,1]),"(",Data[test,2],")",sep="")
  #tweet(TT)
  test=test+1
  if(test>=2) break()
}

freq=table(unlist(aCount))
Data=as.data.frame(freq)
TT=paste(as.String(Data[1,1]),"(",Data[1,2],")",sep="")
c=unlist(a)
names(freq)
