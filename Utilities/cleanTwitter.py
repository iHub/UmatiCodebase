import re
import string
table=  string.maketrans("","")

#class cleanTwitter(object):
def clean(s):
	#remove hyperlinks
	s = re.sub("http.*", "", s)
	#Remove the letters RT
	s = re.sub("(rt|RT)\s", "", s)
	#remove twitter handles
	s = re.sub("@\w+", "", s)
	#remove digits
	s = re.sub("^\d+|\d+", "", s)
	#remove the punctuation
	s= s.translate(table,string.punctuation)
	#remove any spaces at the beginning and end
	s = re.sub("^\s|\s$", "", s)
	#converts tweets to UTF-8
	s=s.encode("utf-8","ignore")
	return s
	
