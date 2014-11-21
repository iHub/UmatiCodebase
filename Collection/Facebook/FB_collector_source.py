

'''
Script    : Facebook Collector
Created   : November 21, 2014
Author(s) : iHub Research
Version   : v1.0
License   : Apache License, Version 2.0
'''

import datetime
import os
import datetime
import pickle
import time
import sys

filedir = '~'

sys.path.append(filedir)

#User 'logger.py' for logging settings
import logging
import loggerSetup
logger = logging.getLogger('root.'+__name__)

#collector_wd = os.path.dirname(os.path.realpath(__file__))
collector_wd = filedir 
os.chdir(collector_wd)

#for ipython console
#%cpaste 
# 
# f = open('CollectorApp/latest_time.txt')
# un_latest = f.read()
# un_latest
# datetime.datetime.fromtimestamp(float(1385841926))
# 
# latest_time = '2013-12-12 14:01:23.000000'
# import pandas as pd
# dt_latest = pd.to_datetime(latest_time)

def main( collect_from, collect_to = datetime.datetime.now()):

    logger.info("STARTING: Collection range from: {0} to: {1}".format(collect_from.strftime("%Y-%m-%d %H:%M:%S"),
                                                                      collect_to.strftime("%Y-%m-%d %H:%M:%S")))
    #local imports
    from CollectorApp.DBmanagement import DBmanager
    from CollectorApp.DBmanagement import Comments
    import CollectorApp.fb_query as fb_query
#     reload(fb_query)
    
    ##DB management
    dbm = DBmanager('Collector.sqlite')
    dbm.create_all()
    
    
    #Setup collection window params
    latest_time = int(time.mktime(collect_to.timetuple()))
    window_delta = collect_to - collect_from
    
    
    #Save latest collected to
    with  open('CollectorApp/latest_time.txt','w') as f:
        f.write(str(latest_time))
    
    #Setup fbquery object - this needs the window to collect data
    fb1 = fb_query.fb_query(end_upd_window = collect_to,
                            start_upd_offset = window_delta)
    
    #Get Source List
    import pandas as pd
    df = pd.read_csv('CollectorApp/UmatiSources_firstClean.csv')
    Names = df['Name of Site/Page'].values.tolist()
    URLs = df['FacebookURL'].values.tolist()
    page_infos = zip(Names,URLs)
    page_infos = [ {'page_name' : it[0], 'url' : it[1]} for it in page_infos]
    
    
    #Setup FB fields to query for comments - look at FB Graph API explorer for possibilities
    top_level_fields = ['feed','posts']


    #Collection loop
    start_time = time.time() #Use this to time data collecting execution
    i=0
    #KTNKenya is row 44
    #Caroling Mutoko is row 23
    for it in page_infos:
        log_string = "Name: {0} , url: {1}".format(it['page_name'],it['url'])
        logger.info("Trying post id query for " + log_string)
        try:
            fb1.do_id_query(it,top_level_fields)
            logger.info( "Success for id query " + log_string +", row {}".format(i))
            try:
                fb1.do_comments_query(300)
                logger.info( "Sucess for comment read for page_name {0} row {1}".format(it['page_name'],i))
                record_list = fb1.to_records()
                logger.info("converted to records")
#                 pickle_name = 'PickleJar/Pickle'+it['page_name']+'.pkl'
                #Pickle download results for testing
#                 out_pkl = open(pickle_name,'wb')
#                 pickle.dump(record_list,out_pkl)
#                 out_pkl.close()
                for rc in record_list:
                    dbm.add_record(Comments,rc)
                try:
                    dbm.session.commit()
                    logger.info("Success adding records for {}".format(it['url']))
                except:
                    logger.error( 'error with db commit')
                    dbm.session.rollback()
                i+=1
            except:
                logger.error( "Error for comment read for page_name {0} row {1}".format(it['page_name'],i))
                i+=1
        except:
            logger.error( "Failure for id query " + log_string +", row {}".format(i))
            i+=1
    
    time_taken = time.time() - start_time
    logger.info("ENDING: Collection range from: {0} to: {1}".format(collect_from.strftime("%Y-%m-%d %H:%M:%S"),
                                                                    collect_to.strftime("%Y-%m-%d %H:%M:%S")))
    logger.info( "Time taken is {} minutes".format( str(time_taken/60.0)))

if __name__ == '__main__':
    collect_dates = [[datetime.datetime(2014,1,15) - datetime.timedelta(days=(j+1)),
                     datetime.datetime(2014,1,15) - datetime.timedelta(days=j) ]for j in range(0,8)]
    
    for date in collect_dates:
        
        main(date[0], date[1])


