

# Load Required Library
library(RSQLite)

# Create Driver and  Connection to SQLite Database
drv <-dbDriver('SQLite')
con = dbConnect(drv,'twitter.sqlite')
