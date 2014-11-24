#!/usr/bin/env python
# -*- coding: utf-8 -*-


'''
Script    : Tagger Settings
Created   : November 21, 2014
Author(s) : iHub Research
Version   : v1.0
License   : Apache License, Version 2.0
'''

'''General settings for the app! Configures the mail platform and the database from which it will retrieve data.
'''

#
flask_config = dict(
    DEBUG = True,
    MAIL_SERVER='smtp.gmail.com',
    MAIL_PORT=587,
    MAIL_USE_TLS = True,
    MAIL_USE_SSL= False,
    MAIL_USERNAME = 'your_email_address',
    MAIL_PASSWORD = 'your_password',
    SECRET_KEY = 'MPF\xfbz\xfbz\xa7\xcf\x84\x8cd\rg\xd5\x04\xee\xa4\xd6\xb9]\xf8\x0e\xf3'
)

#dbase Configuration settings
dbase_config = {
  'user': 'your_dbase_user',
  'password': 'your_dbase_password',
  'host': 'your_server_address',
  'database': 'Umati',
  'port': your_dbase_port
}

