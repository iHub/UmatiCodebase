# R Twitter

This a suite of R code for capturing and analyzing data from Twitter. The Twitter collector Consists of 3 scripts and a csv file for collecting tweets:

![alt tag](http://www.joyofdata.de/blog/wp-content/uploads/2014/06/twitter-150x135.png)
![alt tag](http://rprogramming.net/wp-content/uploads/2012/10/R-Programming.png)

* database.r 
* authentication.r 
* collect.r 
* keywords.csv 
* packages.r

Used to manage the connection to the SQLite database. Set the working directory and the name of the your database Authentication.r This is used to set the authentication for access to the streaming API, read about setting it up here:http://community.ihub.co.ke/blogs/17424/how-to-using-r-to-capture-and-analyze-tweets collect_tweets.r Used to collect tweets based of a string of keywords, up to a limit of ** 400 keywords** each <60 characters long There's also a hack that allows you to monitor a specific twitter account so that you can update the list of key words when you can't log into the server.

Keywords are stored in a csv file. Keywords.csv Store of the keywords.

*Noise Reduction* Various noise reduction techniques to filter large amounts of tweets. Consists of two scripts: association.r classification.r Association.r This script works by finding the words the are most associated with a given keyword using association mining. We use a lower correlation limit of 0.2 but this should on varied depending on the size of your corpus. It then goes into the database and selects the tweets that mention your keyword and it's most relevant associations. It will also drop duplicates and retweets. Classification.r Does tokenisation for feature extraction and uses individual words as features for the naive-Bayes algorithm as a predictive model. Used to reduce noise.

nlp.r Creates a parse tree of tweets. For visual inception for the grammatical structure of tweets, particularly tweets of interest.

twitterTracker.r This is used to monitor twitter accounts so that you can tell what they are talking about within a given time period. Developed so as reduce the amount of time it takes before monitors are aware that an event has broken out so that the keyword can be added to the list of keywords being tracked. Words that occur above a certain threshold are then tweeted by a twitter bot that can be monitored and send SMS notifications.

Currently in version 0.2, the vision for this program is to be one day be able to add keywords automatically without human intervention.
