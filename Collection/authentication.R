#========================= Twitter App Authentication ========================================================================================

#Load required libraries
library(twitteR)

#========================= Set Working Directory =============================================================================================

#Set Directory for All Files
setwd('/ExtraStorage/scripts/Shiny App')

#======================== App Credentials ====================================================================================================

#Setup Twitter App Credentials
reqURL <-"https://api.twitter.com/oauth/request_token"
accessURL <-"https://api.twitter.com/oauth/access_token"
authURL <-"https://api.twitter.com/oauth/authorize"
consumerKey <-"8mzRs9PySHKmTcvXBcy5w"
consumerSecret <-"ZKNBKniG4ADfyk3tHCWQsj0wowapFpXhqoj8O4OnQQ"

#======================= Authenticate =======================================================================================================

#Authenticate Credentials
twitCred <- OAuthFactory$new(consumerKey=consumerKey,consumerSecret=consumerSecret,requestURL=reqURL,accessURL=accessURL,authURL=authURL)

#Download Authentication Certificate
download.file(url="http://curl.haxx.se/ca/cacert.pem", destfile="cacert.pem")

#Initiate System Handshake
twitCred$handshake(cainfo="cacert.pem")

# Set SSL certs globally
options(RCurlOptions = list(cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl")))

#save authentication credentials
save(list="twitCred", file="twitteR_credentials")
#==========================================================================================================================================
