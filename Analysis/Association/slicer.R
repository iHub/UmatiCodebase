
'
Script    : Slicer
Created   : November 21, 2014
Author(s) : iHub Research
Version   : v1.0
License  : Apache License, Version 2.0
'

slicer <-function(event,number){
    # ================= LOAD REQUIRED LIBRARIES =====================================================================
    library(RSQLite)
    library(stringdist)
    library(tm)

    #================== CONNECT TO DATABASE ===========================================================================
    # Setup SQLite Database
    drv <-dbDriver('SQLite')
    con <-dbConnect(drv,'mpeketoni.sqlite')

    #================== GET DATA FROM DATABASE =========================================================================
    # Load Data from Database
    sql <-paste("SELECT * FROM mpeketoni WHERE [text] like '%",event,"%' LIMIT ", number,"", sep="")
    a <-dbGetQuery(con,sql)
    a1 <-a['text']

    # Create Temporary DB table
    dbWriteTable(con,'intermediate',a1)
  
    #=================== CREATE TERM-DOCUMENT MATRIX =====================================================================
    # Create Corpus of Tweets
    b <-Corpus(VectorSource(a$text))
  
    # Create a Text-Document Matrix, Remove Stopwords, Convert Text to Lowercase
    c <-TermDocumentMatrix(b,control=list(removePunctuation=TRUE,stopwords='english',tolower=TRUE))
  
    #=================== FIND ASSOCIATIONS FOR EVENT =====================================================================
    # Compute Optimal Lower Correlation Limit
    tokens = MC_tokenizer(a$text)
    len = length(unique(tokens))
    cor_limit = len/nrow(a)*0.1
  
    # Find Words Associated with Keyword
    tmp <-findAssocs(c,event,cor_limit)
  
    #==================== QUERY DB FOR ASSOCIATED WORDS ====================================================================
    # Create Empy Data Frame
    df = data.frame()
  
    # Dynamic SQL Query
    for (rn in rownames(tmp))
      {
      qry_str = paste("SELECT * FROM intermediate WHERE [text] like '%", event, "%'","AND [text] like '% ", rn, "%'" ,sep="")
      df1 <-dbGetQuery(con,qry_str)
      df <-rbind(df,df1)
      rm(df1)
      }
  
    #================= FILTERING DUPLICATES/RETWEETS ========================================================================
    # Remove Native Retweets
    rt = as.vector(unique(df$text))
  
    # Create Empty Data Frame and Matrix
    index_to_remove <-c()
    mat <-matrix(nrow = length(rt),ncol = length(rt))
  
    # Find Similar String Distance Metric
    for (i in 1:length(rt))
      {
        for (j in 1:length(rt))
          {
            mat[i,j] <-stringdist(rt[i],rt[j],method='lv')
              if(!is.na(mat[i,j]))
                {
                if(mat[i,j] <= 20 && mat[i,j]!= 0)
                  {
                    x <- i
                    index_to_remove <-rbind(x,index_to_remove)
                    rm(x)
                  }
                }
          }
      } 
  
    # Remove Similar Tweets 
    d <- rt[-c(index_to_remove)]

    # Write CSV File
    write.csv(d,"tweets.csv",row.names=FALSE)
    
    # Delete Temporary DB Table
    dbRemoveTable(con,'intermediate')
  }

#--------------------------- Use Slicer Function -------------------------------------------------------------------------------

slicer()







