#!/usr/bin/env python
# -*- coding: utf-8 -*-


'''
Script    : Tagger Database Management
Created   : November 21, 2014
Author(s) : iHub Research
Version   : v1.0
License   : Apache License, Version 2.0
'''

import settings
import psycopg2
import redis

from psycopg2 import extras

       
''' ------------------------------- PostGresSQL Database Functions Class------------------------------- '''
class PostGresDBase():
    def __init__(self):
        self.conn = psycopg2.connect(**settings.dbaseConfig)
        self.cursor = self.conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        
    def __del__(self):
        self.cursor.close()
        self.conn.close()

    ''' This method returns n random comment ids dependent on the number of tags requested when sessions for a question where Created '''
    def getToTag(self, tags_needed):
        query = 'SELECT post_comments_id FROM "AutoCollected" ORDER BY RANDOM() LIMIT ' + str(tags_needed)
        self.cursor.execute(query)
        self.result = self.cursor.fetchall()
        return list(item['post_comments_id'] for item in self.result)

    def getComments(self, tags_list):
        query = 'SELECT page_id, page_name,post_message,post_comments_id,post_comments_message FROM "AutoCollected" WHERE post_comments_id IN (%s)' % tags_list
        self.cursor.execute(query)
        self.result = self.cursor.fetchall()
        return self.result

    def postTags(self, tagged_set):
        # TODO - Optimize to execute to database only once
        
        #Create a string with '%s,' string placeholders for use on the query statement
        placeholders = ', '.join(['%s'] * 6)
        query = 'INSERT INTO taggeddata VALUES (%s)' % placeholders

        #Loop through the list of tagged data replacing string placeholders with actual data and write each to the database
        for tag in tagged_set['tags']:
            self.cursor.execute(query, (tagged_set['session_id'],tagged_set['session_desc'], tagged_set['tagged_by'], tagged_set['session_qst'], tag, tagged_set['tags'][tag]))
        
        #Commit the data to the database
        self.conn.commit()

''' ------------------------------- Redis Database Functions Class------------------------------- '''
class RedisDBase():
    def __init__(self, **redis_kwargs):
        self.r_server = redis.Redis('localhost')

    def checkUserCredentials(self, username, password):
        error = None
        if username != self.r_server.get('username'):
            error = 'Invalid username'
        elif password != self.r_server.get('userpassword'):
            error = 'Invalid password'
        return error

    def postSessionInfo(self, session_info):
        self.r_server.incr('session_id')
        tag_sessionid = 'session_id' + str(self.r_server.get('session_id')) 
        self.r_server.hmset(tag_sessionid, session_info)
        return tag_sessionid

    def postUserSessionInfo(self, sessions_to_create):
        for session_id in sessions_to_create:
            self.r_server.hmset(session_id, sessions_to_create[session_id])

    def getSessionInfo(self, session_id):
        self.tag_qst, self.key_options = self.r_server.hmget(session_id, 'tag_qst', 'key_options')
        return self.tag_qst, self.key_options

    def getUserSessionInfo(self, session_id):
        self.result = self.r_server.hgetall(session_id)
        return self.result

    def updateUserSessionTagList(self, session_id, comments_to_tag):
        self.r_server.hset(session_id, 'comments_to_tag', comments_to_tag)
