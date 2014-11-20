
'
Script    : Authentication
Created   : November 21, 2014
Author(s) : iHub Research
Version   : v1.0
License   : Apache License, Version 2.0
'
# Register app at https://apps.twitter.com to get authentication credentials

#========================= Twitter App Authentication ===================================================================================

# Load Required library
library(twitteR)

#========================= Set Working Directory ========================================================================================

# Set Directory for All Files
setwd('~')

#======================== App Credentials ===============================================================================================

# Add App Keys Provided by Twitter
consumerKey = ""
consumerSecret = ""

# Setup Twitter App Credentials
reqURL <-"https://api.twitter.com/oauth/request_token"
accessURL <-"https://api.twitter.com/oauth/access_token"
authURL <-"https://api.twitter.com/oauth/authorize"
consKey <- consumerKey
consSecret <- consumerSecret

#======================= Authenticate ===================================================================================================

# Authenticate Credentials
twitCred <- OAuthFactory$new(consumerKey=consKey,consumerSecret=consSecret,requestURL=reqURL,accessURL=accessURL,authURL=authURL)

# Download Authentication Certificate
download.file(url="http://curl.haxx.se/ca/cacert.pem", destfile="cacert.pem")

# Initiate System Handshake
twitCred$handshake(cainfo="cacert.pem")

# Set SSL Certs 
options(RCurlOptions = list(cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl")))

# Save Authentication Credentials
save(list="twitCred", file="twitteR_credentials")
#==========================================================================================================================================
