#=================== Association Mining =========================================================================

# Load Required Libraries
library(RSQLite)
library(tm)

# Load Data from Database


# Create Corpus of Tweets
text <-Corpus(VectorSource(tweets$text))

#create a text-document matrix and remove stopwords
c <-TermDocumentMatrix(b,control=list(removePunctuation=TRUE,stopwords=TRUE,tolower=TRUE,stemDocument=TRUE))

#=================== FIND ASSOCIATIONS FOR EVENT ================================================================

#find associations with keywords
tmp <-findAssocs(c,'likoni',0.2)

#==================== QUERY DB ASSOCIATED WORDS =================================================================

#create empy data frame
df = data.frame()

#dynamic SQL query
for (rn in rownames(tmp))
{
  qry_str = paste("SELECT * FROM likoni WHERE [text] like '%likoni%' AND [text] like '%", rn, "%' ",sep="")
  df1 <-dbGetQuery(con,qry_str)
  df <-rbind(df,df1)
}

#================= FILTERING DUPLICATES/RETWEETS ===============================================================

#calculate levenshtein distance between succesive tweets
indexes_to_remove = c()

for (i in 1:length(df$text))
{
  distance <-(stringdist(df$text[i],df$text[i+1],method='lv'))   
  if(!is.na(distance)){
    if(distance == 10 | distance < 3 ){
      indexes_to_remove = c(indexes_to_remove,i)
    }
  }
}

#remove retweets
d <-unique(df[-indexes_to_remove,]$text)
