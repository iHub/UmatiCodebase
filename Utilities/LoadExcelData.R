#Load library to interface with xlsx
library('xlsx')

path_data = "../"
#read excel data to dataframe / seems to take a looooong time on the server??

umati_data_manual = read.xlsx2(
  file ="Results/20140109_FullCleanedData_toDec2013.xlsx",
                              sheetIndex=1,                              
                              stringsAsFactors=F)

#Again we have issues with excel formatting some dates as strings
#And some as Excel dates

#This discovers which dates are formatted as strings and which as datestamps
#by trying to convert to numeric types
#dates as strings with character throw an NA and so we can
#find those that are correctly formatted

num_time = as.numeric(umati_data_manual$Date_plusManualCorrection)
filter = is.na(num_time)
index_nas = which(filter)
plot(1:length(index_nas), index_nas, type='l')

#Split into correct formatting
umati_data_manual$dateIsString = as.factor(filter)
udata_isStringTFormat = data.frame(umati_data_manual$Date_plusManualCorrection,
                                   stringsAsFactors=F)
udata_isStringTFormat$key = 1:nrow(udata_isStringTFormat)


#Get string formatted data
times_to_format = udata_isStringTFormat[filter==TRUE,]
help(strftime)
help(format)

t_posix = as.POSIXct(times_to_format[,1],
                  format="%m/%d/%Y %H:%M:%S",
                  tz="UTC-3")

#Check if these have formatted correctly
filter_ts = is.na(t_posix)
which(filter_ts) #nope
times_to_format[filter_ts,1]

#Convert to posix time - note different string format
t_posix2 = as.POSIXct(times_to_format[filter_ts,1],
                      format="%m/%d/%Y",
                      tz="UTC-3")
t_num = as.numeric(t_posix2)
t_utc = as.POSIXct(t_num,
                   origin="1970-01-01",
                   tz="UTC")
t_utc
#Combine split data back together
length(t_posix[!filter_ts]) + length(t_posix2)

times_to_format[!filter_ts,1]=t_posix[!filter_ts] #False is the first format that worked
times_to_format[filter_ts,1]=t_posix2 #True is second stage format

as.POSIXct(as.numeric(times_to_format[,1]),
           origin="1970-01-01",
           tz="UTC")

plot(1:nrow(times_to_format), times_to_format[,1], type='l')

#Formatting excel indexed times as unix times
times_to_format_xlts = udata_isStringTFormat[filter==F,]
times_to_format_xlts[,1] = as.numeric(times_to_format_xlts[,1])
#Check if conversion to numeric worked
which(is.na(times_to_format_xlts[,1])) #worked!

#Now convert to unix
#Note excel index is number of days since 30-Jan-1899, while posix
#is in seconds. Hence reason for multiplication in first arg, and origin
#Also put in timezone as EAT = UTC+3 (r uses +/- on timezone counterintuitively)

t_posix_xl = as.POSIXct(times_to_format_xlts[,1]*24*60*60,
           origin="1899-12-30",
           tz="UTC+3")
plot(t_posix_xl,type='l')
#Combine formatting of string and excel times

udata_isStringTFormat[filter==FALSE,1] = t_posix_xl
udata_isStringTFormat[filter==FALSE,]
udata_isStringTFormat[filter==TRUE,] = times_to_format

udata_isStringTFormat[,1] = as.POSIXct(as.numeric(udata_isStringTFormat[,1]),
                                            origin="1970-01-01",
                                            tz="UTC")

plot(udata_isStringTFormat[,1],type='l') #Looks good
colnames(udata_isStringTFormat)=c("cleaned_time","key")

#Now we want remove unwanted columns from dataframe
#We want to keep all data that monitors collected, but drop columns
#That we used in Excel to do datetime formatting
#We will keep the original bad datetime format, plus we want month and year columns

cols = colnames(umati_data_manual)
View(cols)
colstokeep=cols[1:28]

umati_data_cleaned = umati_data_manual[,colstokeep]
umati_data_cleaned$key = 1:nrow(umati_data_cleaned)


umati_cleaned_unix_dates = merge(umati_data_cleaned,udata_isStringTFormat,by='key')

month= format(umati_cleaned_unix_dates$cleaned_time, format = "%b")
year = format(umati_cleaned_unix_dates$cleaned_time, format = "%Y")
ones = rep(1, nrow(umati_cleaned_unix_dates))

umati_cleaned_unix_dates$month = month
umati_cleaned_unix_dates$year = year
umati_cleaned_unix_dates$ones = ones

#Now the data set should be reader
sum(umati_cleaned_unix_dates$ones)

str(umati_cleaned_unix_dates)

#Numeric fields
numeric_f= c('How.inflaMmatory.is.the.content.of.the.text.',
  'How.much.iNfluence.does.the.speaker.have.on.the.audience.',
  'Bucket',
  'year')
for( col in numeric_f){
  umati_cleaned_unix_dates[,col] = as.numeric(umati_cleaned_unix_dates[,col])
}
                            
str(umati_cleaned_unix_dates)

#drop keys column
umati_cleaned_unix_dates=subset(umati_cleaned_unix_dates, select= -key)

#And that, my friends, should be it
