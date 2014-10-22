
#================================== Install Packages ================================================

# Function for Checking Installed Packages and Installing if Not
packs <- function(pkg){
    new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
    if (length(new.pkg)) 
        install.packages(new.pkg, dependencies = TRUE)
    sapply(pkg, require, character.only = TRUE)
}
 
# Call Function
packages <- c("twitteR", "streamR", "RSQLite","tm","stringr","klaR","RWeka","RCurl","RJSONIO","stringdist","openNLP","openNLPmodels.en","NLP")
packs (packages)
