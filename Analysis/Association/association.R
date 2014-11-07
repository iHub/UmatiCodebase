#=================== Association Mining =========================================================================

# Load Required Libraries
library(RSQLite)
library(tm)

#================== CONNECT TO DATABASE ========================================================================

# Setup SQLite Database
drv <-dbDriver('SQLite')
con <-dbConnect(drv,'twitter.sqlite')

#================== DEFINE KEYWORD FOR EVENT ==================================================================

# Keyword for Event
event = ''

#================== GET DATA FROM DATABASE ====================================================================

# Load Data from Database
sql <-paste("SELECT * FROM tweet_data WHERE [text] like '%",event,"%' ", sep="")
a <-dbGetQuery(sql,con)

#=================== CREATE TERM-DOCUMENT MATRIX ===============================================================

# Create Corpus of Tweets
b <-Corpus(VectorSource(a$text))

# Create a Text-Document Matrix, Remove Stopwords, Convert Text to Lowercase
c <-TermDocumentMatrix(b,control=list(removePunctuation=TRUE,stopwords=SMART,tolower=TRUE))

#=================== FIND ASSOCIATIONS FOR EVENT ================================================================

# Compute Optimal Lower Correlation Limit
cor_limit = length(unique(a$text)/nrow(a))

# Find Words Associated with Keyword
tmp <-findAssocs(c,event,cor_limit)

#==================== QUERY DB ASSOCIATED WORDS =================================================================

# Create Empy Data Frame
df = data.frame()

# Dynamic SQL Query
for (rn in rownames(tmp))
{
  qry_str = paste("SELECT * FROM likoni WHERE [text] like '%", event, "%'","AND [text] like '% ", rn, "%'" ,sep="")
  df1 <-dbGetQuery(con,qry_str)
  df <-rbind(df,df1)
}

#================= FILTERING DUPLICATES/RETWEETS ===============================================================

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
