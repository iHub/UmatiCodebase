
'''
Script    : Facebook Database Management 
Created   : November 21, 2014
Author(s) : iHub Research
Version   : v1.0
License   : Apache License, Version 2.0
'''

from dateutil import parser
import datetime

#DBmanagementimports
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# from sqlalchemy.ext.declarative import declarative_base
# Base = declarative_base()

from CollectorApp.SqlalchemyBase import Base
 
class DBmanager(object):
     
    def __init__(self, db_name = 'Collector.sqlite'):
         
        #Create connection to db        
        #self.engine = create_engine('sqlite:///'+db_name,echo=False)
	self.engine = create_engine('~',echo=False)
        #connect to engine
        Session = sessionmaker(bind=self.engine)
        self.session = Session() #The session object is now the handle to our db
         
    def create_all(self):
        #Create the tables in db specified by engine
        Base.metadata.create_all(self.engine)
     
    def add_record(self, table, rc):
        rc_for_table = table(rc)
        self.session.merge(rc_for_table) #use merge rather than add to deal with duplicates
 
 
#Table Comments imports
#Import columns and types to make table
from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.exc import IntegrityError
     
#Define class that represents Comments table
class Comments(Base):
    #The below reflects the name of fb comments in iresearch db	
    __tablename__ = 'AutoCollected'
    
    #Define schema
    #id = Column(Integer, primary_key=True)
    page_name = Column(String)
    page_id = Column(Integer)
    post_message = Column(String)
    post_id = Column(Integer)
    #post_created_time = Column(DateTime)
    post_created_time = Column(DateTime(timezone=True))
    post_comments_id = Column(String, primary_key=True)
    post_comments_message = Column(String)
    post_comments_from_name = Column(String)
    post_comments_from_id = Column(String)
    post_comments_created_time = Column(DateTime(timezone=True))# Column(DateTime) #
    
    #Define
    def __init__(self, record):
        
        """
        Be nice to find a quicker way to do
        """
        
        
        self.page_name = record['PageName']
        self.page_id = record['PageId']
        self.post_message = record['post_message']
        self.post_id = record['post_id']
        #post_idself.post_created_time = parser.parse(record['post_created_time'],ignoretz=True) #You need to ignore tz or when comparing on merge sqlalchemy get confused
        self.post_created_time = parser.parse(record['post_created_time']) #You need to ignore tz or when comparing on merge sqlalchemy get confused
        self.post_comments_id = record['post_comments_id']
        self.post_comments_message = record['post_comments_message']
        self.post_comments_from_name = record['post_comments_from_name']
        self.post_comments_from_id = record['post_comments_from_id']
        #self.post_comments_created_time = parser.parse(record['post_comments_created_time'],ignoretz=True)
        self.post_comments_created_time = parser.parse(record['post_comments_created_time'])
        
  
 
    def __repr__(self):
        return "<comment('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s')>" % (self.page_name,
                                                                       self.page_id,
                                                                       self.post_message,
                                                                       self.post_id,
                                                                       self.post_created_time,
                                                                       self.post_comments_id,
                                                                       self.post_comments_message,
                                                                       self.post_comments_from_name,
                                                                       self.post_comments_from_id,
                                                                       self.post_comments_created_time)


