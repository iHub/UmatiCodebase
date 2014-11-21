
'
Script    : Facebook Query
Created   : November 21, 2014
Author(s) : iHub Research
Version   : v1.0
License   : Apache License, Version 2.0
'

import os
import requests
import datetime
import time

#User 'logger.py' for logging settings
import logging
logger = logging.getLogger('root.'+__name__)

#These come from app I have setup
App_ID='714612301882745'
App_Secret="439aa3a5e9e0143928984cdb33d55176"

#Read Access token
file_AT = open('GetLogonApp/long_AT.txt')
longAT =file_AT.read()
file_AT.close()

#Read query for getting post ids
file = open('CollectorApp/GraphAPIQueries/fetch_feed_ids.txt')
get_post_ids = file.read()
file.close()

#Read query for getting comments from post
file = open('CollectorApp/GraphAPIQueries/fetch_feed_data_comments.txt')
get_query_data = file.read()
file.close()


class fb_query(object):

    """ Class for managing facebook queries """
    
    def __init__(self,
                 end_upd_window = datetime.datetime.now(),
                 start_upd_offset = datetime.timedelta(hours=24) ):

        """ Constructor for query class
        Input:
        end_upd_window - when the posts are gathere too default is now 
        start_upd_offset - how far back to collect posts
        """

        #Query parameters
        self.access_token = longAT
        self.id_query = get_post_ids
        self.data_query = get_query_data
        self.page_info = None

        #ID query results
        self.page_id = None
        self.post_ids = None
        self.query_results = []

        

        #Create posts update window offset from end_upd_window
        self.end_upd_window = end_upd_window
        posts_since = end_upd_window - start_upd_offset
        self.posts_since_unix = int(time.mktime(posts_since.timetuple()))
        self.posts_until_unix= int(time.mktime(end_upd_window.timetuple()))

        

    def do_id_query(self, page_info, top_level_fields, ret_qry=False):

        self.page_info = None
        self.page_id = None
        self.post_ids = []

        self.page_info = page_info
        page_url = page_info['url'].replace('http://www.facebook.com/','')
        page_url = page_url.replace('groups/','')
        page_url = page_url.replace('?ref=stream','')
        #Get page ids
        
        for field in top_level_fields:
            logger.info('doing field {}'.format(field))
            id_query2 = 'https://'+self.id_query.format(page_url,
                                                        field,
                                                        self.posts_since_unix,
							self.posts_until_unix,
                                                        longAT)
    
            
            if ret_qry:
                print id_query2
            
            
            r_id = requests.get(id_query2)
            
            if r_id.status_code != 400:
                ids_json = r_id.json()
                self.page_id = ids_json['id']
                self.post_ids = self.post_ids + [ it['id'] for it in ids_json[field]['data']]
            
                
        
        #get rid of duplicates
        self.post_ids = list(set(self.post_ids))
        
        
    def do_comments_query(self, num_limit):
        """
        Input:
        URL of facebook
        query_str
        access_token

        Output:
        facebook get request in json format
        """

        self.query_results = []
        
        if len(self.post_ids) != 0:
            #Get comments from post
            for it in self.post_ids:
                get_qry_data2 = 'https://'+self.data_query.format(it,
                                                                  num_limit,
                                                                  longAT)
                #print get_qry_data2
                r_comments = requests.get(get_qry_data2)
                comments_json = r_comments.json()
                try:
                    logger.info("Retrieved {0} comments for post {1}".format(len(comments_json['comments']['data']),
                                                                             comments_json['id']))
                    self.query_results.append(comments_json)
                except:
                    #Add exception handling here
                    logger.warning('no comments for {}'.format(comments_json['id']))
                    continue
        else:
            logger.info("no ids")
        



    def to_records(self):


        """
        This queries all comments on posts fro give url
        Input: URL of fb group/user
        Output: list of records of data
        """

        #initialise output list
        records = []

        #loop that converts json to flat dictionary records
        #should build a util that uses recursion - more general
        page_name = self.page_info['page_name']

        for it1 in self.query_results:

          thisRecord = { 'PageName': page_name,
                       'PageId': self.page_id,
                       'post_message':None,
                       'post_id':None,
                       'post_created_time':None,
                       'post_comments_id':None,
                       'post_comments_message':None,
                       'post_comments_from_name':None,
                       'post_comments_from_id':None,
                       'post_comments_created_time':None}
          
          #Check if top level post is ok
          try:
            thisRecord['post_message'] = it1['message']
            thisRecord['post_id'] = it1['id']
            thisRecord['post_created_time'] = it1['created_time']
          except:
            error_str = 'No message in post {}'.format(it1['id'])
            logging.warning(error_str)
            continue #if error then got to next post
          else:
            try:
              for it2 in it1['comments']['data']:
                try:             
                    thisRecord['post_comments_id'] = it2['id']
                    thisRecord['post_comments_message'] =it2['message']
                    thisRecord['post_comments_from_name'] = it2['from']['name']
                    thisRecord['post_comments_from_id'] =  it2['from']['id'] 
                    thisRecord['post_comments_created_time'] =it2['created_time']
                    cp_thisRecord = dict(thisRecord) #Remember to copy dict otherwise only passes ref to dict rather than vals
                    records.append(cp_thisRecord)
                    
                except:
                  error_str = 'Problem with comment id {1}, on post id[2]'.format(it1['id'],it2['id'])
                  logging.warning(error_str)
                  continue #if error then got to next comment in post
            except:
              error_str = 'No comments for post id {0}'.format(it1['id'])
              logging.warning(error_str)
              continue #if error then got to next comment in post

        return records
