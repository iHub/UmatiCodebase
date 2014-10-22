# Load Libraries
library(openNLP)
library(openNLPmodels.en)
library(RSQLite)
library(NLP)

# set working directory
setwd('/Users/umati3/Desktop/Aggregate')
dir() 

# Load Data
drv <-dbDriver('SQLite')
con <-dbConnect(drv,'Twitter Data.sqlite')
sql <-"SELECT * FROM twitter_data WHERE [text] like '%mombasa%' AND [text] like '%MRC%' "
a <-dbGetQuery(con,sql)

# Extract Text
b <-a[,c(2)]
c <-as.String(b)

# Need sentence and word token annotations.
sent_token_annotator <- Maxent_Sent_Token_Annotator()
word_token_annotator <- Maxent_Word_Token_Annotator()
a2 <- annotate(c, list(sent_token_annotator, word_token_annotator))

parse_annotator <- Parse_Annotator()

# Compute the parse annotations only.
p <- parse_annotator(c, a2)

# Extract the formatted parse trees.
ptexts <- sapply(p$features,'[[',"parse")

# Read into NLP Tree objects.
ptrees <- lapply(ptexts, Tree_parse)
ptrees
