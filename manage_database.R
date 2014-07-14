#==================================== Create and Manage SQLite Database =================================================================

#Load Required Library
library(RPostgreSQL)
library(RSQLite)

#Drivers
drv <-dbDriver('SQLite')
#Connect to PostgreSQL Database
con = dbConnect('PostgreSQL',host='41.242.2.145',dbname='twitter',user='patrick',password='dlabroot',port='5432')
con1 = dbConnect(drv,'twitter.sqlite')



