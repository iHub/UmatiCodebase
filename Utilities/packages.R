
#================================== Install Packages ================================================

# Function for Checking Installed Packages and Installing if Not
packs <- function(pkg){
    new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
    if (length(new.pkg)) 
        install.packages(new.pkg, dependencies = TRUE)
    sapply(pkg, require, character.only = TRUE)
}
 
# Call Function
packages <- c("rjson","twitteR", "streamR", "RSQLite","tm","stringr","klaR","RWeka","RCurl","RJSONIO","stringdist","openNLP","openNLPmodels.en","NLP","e1071")
packs (packages)

#If you get an error and the following packages can't be installed: twitteR,streamR and RCurl
#In your shell:
#apt-get -y build-dep libcurl4-gnutls-dev
#apt-get -y install libcurl4-gnutls-dev
