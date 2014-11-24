# -*- coding: utf-8 -*- 


'''
Script    : Tagger
Created   : November 21, 2014
Author(s) : iHub Research
Version   : v1.0
License   : Apache License, Version 2.0
'''

import os
import binascii
import dbaseops
import settings
import json

from flask import Flask, request, session, redirect, url_for, \
      render_template, flash, jsonify, Markup

from flask.ext.mail import Mail, Message

''' ------------------------------- setup and initialize app ------------------------------- '''
app = Flask(__name__)

app.config.update(**settings.flask_config)

mail = Mail(app)

''' ---------------------------------------- Routes ---------------------------------------- '''
@app.route('/')
def index():
    session['logged_in'] = False
    return render_template('index.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    error = None
    if request.method == 'POST':
        dbase = dbaseops.RedisDBase()
        error = dbase.checkUserCredentials(request.form['username'], request.form['password'])
        
        if not error:
            session['logged_in'] = True
            flash('You were logged in')
            return redirect(url_for('create'))
    return render_template('login.html', error=error)

@app.route('/create')
def create():
    if not session.get('logged_in'):
        return redirect(url_for('login'))

    return render_template('createSession.html')

@app.route('/sessions/<tag_sessionid>')
def session_code(tag_sessionid):
    return render_template('tagSession.html', session_id = tag_sessionid)

@app.route('/view/<tag_sessionid>', methods=['GET'])
def load_session_data(tag_sessionid):
    
    '''' Code to read session information from the Redis'''
    try:        
        user_session = '/sessions/' + tag_sessionid
        dbase = dbaseops.RedisDBase()
        session_info = dbase.getUserSessionInfo(user_session)
        
        # Raise an exception when session information has not been found
        if not session_info:
            raise NameError('<br><br><span>Session {0} has not been found<span>'.format(tag_sessionid))
        
        # Get the tagging question and keys from Redis using session_id
        tag_qst, tag_keys = dbase.getSessionInfo(session_info['tag_qst_id'])
        
        # Comment ID formatting to remove unicode 
        tag_keys = eval(tag_keys)

        # Create the comments list as a string by removing array characters
        comments_list = str(session_info['comments_to_tag']).strip('[]')

        # Raise an exception when the comments list is empty
        if not comments_list:
            raise NameError('<br><br>Tagging Sesssion {0} is complete. Thank you for your submissions!'.format(tag_sessionid))

        # Get the comment records from the PostGres database
        dbase = dbaseops.PostGresDBase()
        comments_data = dbase.getComments(comments_list)
        
        # Return the updated session with actual comment data
        session_info['comments_to_tag'] = comments_data

        session_info['tag_qst'] = tag_qst
        session_info['tag_keys'] = tag_keys

        return jsonify(session_info)            

    # Code to handle Exceptions
    except NameError as detail:
        # Return the error message and go to form for completion
        flash(Markup(detail))
        return url_for('complete')
    
    except Exception as detail:
        # Return error message on current form for any other errors
        return jsonify({'error': detail})

# @app.route('/sessions/add', methods=['POST'])
@app.route('/savelabels', methods=['GET','POST'])
def saveLabels():
    
    ''' Code to post tagged data to PostGresDBase  and update tag list and remove those tagged in RedisDBase'''
    
    #Get the string object passed from the form where data was tagged
    tagdataString = request.form['toSave']

    #Convert the data into a json object
    tagdata = json.loads(tagdataString)

    #Use try to handle excpetions
    try:

        #Create a connection to PostGres Database  and save the tagged data in the Postgres database
        dbase = dbaseops.PostGresDBase()
        # dbase.postTags(tagdata)   

        #Get the tag_sessionid as stored in Redis database
        tag_sessionid = url_for('session_code', tag_sessionid= tagdata['session_id'])
        
        #Create a connection to Redis Database
        dbase = dbaseops.RedisDBase()

        #Get the whole session details. We want to get initial list of comments that needed to be tagged from Redis
        session_info = dbase.getUserSessionInfo(tag_sessionid)

        #List comes back as a string, so convert it to a proper list
        session_comments = eval(session_info['comments_to_tag'])
        
        #Loop through the list that was posted as tagged from web form and remove them the original Redis list
        for tag_item in tagdata['tags']:
            session_comments.remove(tag_item)

        # Update the RedisDBase to remove saved tags
        dbase.updateUserSessionTagList(tag_sessionid, session_comments)

        # Return and display success message. If all data has been tagged go to main page else ask if they want to continue
        if len(session_comments):
            message = '''<span><p>Tags Saved!</p></span><br><br><span>Do you want to save more tags? Click <a href="/create
                 ">here</a> to continue tagging</span>'''
        else:
            message = '<span><p>Tags Saved!</p></span><br><br>Tagging Sesssion is now complete... Thank you for your submissions!'

        #Show message and open page with confirmation that tags have been saved. 
        flash(Markup(message))
        return url_for('complete')        

    # If we encounter any errors. Show the error message
    except Exception as error_detail:
        return jsonify({'error': 'Error ({0})'.format(error_detail)})

@app.route('/postSessions', methods=['GET', 'POST'])
def postSessions():
    ''' --------------------------------- Code to create sessions -------------------------------------- '''                  
    try:

        sessions_to_create = {}
        start_position = 0

        details_string = request.form['sessionsObject']
        sessions_details = (json.loads(details_string))['taggers_info']

        total_tags = sum(item['number_to_tag'] for item in sessions_details['taggers'])
        
        dbase = dbaseops.PostGresDBase()
        comments_to_tag = dbase.getToTag(total_tags)
        
        #Save the tagging session details to Redis
        dbase = dbaseops.RedisDBase()        
        tag_qstid = dbase.postSessionInfo(sessions_details)

        #Create individual user tagging sessions with list of comment ids
        with mail.connect() as conn:
            for user_session in sessions_details['taggers']:
                
                user_session['tag_qst_id'] = tag_qstid

                end_position =  start_position + user_session['number_to_tag']
                user_session['comments_to_tag'] = comments_to_tag[start_position:end_position]

                # Move position where to start slicing the list of comments_to_tag
                start_position+=user_session['number_to_tag']
                
                # Create the random path for the tagging session
                tag_session_url = url_for('session_code', tag_sessionid=str(binascii.b2a_hex(os.urandom(10))))

                # Add to the object of sessions to create for posting in the RedisDBase
                sessions_to_create[tag_session_url] = user_session

                ''' --------------------------------- Code to create and send the emails to the users -------------------------------------- '''                  
                message = '''Hello, %s. \n\nPlease tag the data in response to the question\n\n %s\n\n 
                            Find the tagging session at http://192.168.33.71:5000%s .\n\nThanks,''' \
                             % (user_session['user_to_tag'], sessions_details['tag_qst'],  tag_session_url)
                subject = 'Request to tag data' 
                msg = Message(recipients=[user_session['user_email']],
                                body=message,
                                sender=("Python Tagging App", "chalenge@ihub.co.ke"),
                                subject=subject)

                conn.send(msg)        

            ''' --------------------------------- Save each user session details to Redis -------------------------------------- '''     
            dbase.postUserSessionInfo(sessions_to_create)

        #Show message and open page with confirmation that tags have been saved. 
        message = '''<span><p>Sessions Created!</p></span><br><br><span>
            Do you want to save more tags? Click <a href="' + tag_sessionid +
            '">here</a> to continue tagging</span>'''        
        
        flash(Markup(message))
        return url_for('complete')                
        # return jsonify(sessions_to_create)

    except Exception as error_detail:
        return jsonify({'error': 'Creating tagging sessions has this error ({0})'.format(error_detail)})

@app.route('/complete')
def complete():
    return render_template('complete.html')

''' --------------------------------- Main Function -------------------------------------- '''                  
if __name__ == '__main__':
    app.run(host='0.0.0.0',
         port=int('5000'))