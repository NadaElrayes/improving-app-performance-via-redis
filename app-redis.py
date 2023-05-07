# /usr/bin/python2.7
import psycopg2
import redis
from configparser import ConfigParser
from flask import Flask, request, render_template, g, abort
import time

def config(filename='config/database.ini', section='postgresql'):
    # create a parser
    parser = ConfigParser()
    # read config file
    parser.read(filename)

    # get section, default to postgresql
    db = {}
    if parser.has_section(section):
        params = parser.items(section)
        for param in params:
            db[param[0]] = param[1]
    else:
        raise Exception('Section {0} not found in the {1} file'.format(section, filename))

    return db

def fetch(sql):
    # connect to database listed in database.ini
    conn = connect()
    if(conn != None):
        cur = conn.cursor()
        cur.execute(sql)
        
        # fetch one row
        retval = cur.fetchone()
        
        # close db connection
        cur.close() 
        conn.close()
        print('PostgreSQL connection is now closed')

        return retval
    else:
        return None  

def connect_redis():
    # Connect to Redis
    try:
        print ('Connecting to Redis...') 
        conn = redis.Redis(host=\"redis-cluster-endpoint-placeholder\", port=6379)
    except(Exception):
        print ('Connection to Redis failed...')
        conn = None
    else:
        return conn

def fetch_redis(key):
    conn = connect_redis()
    if(conn != None):
        retval = conn.get(key)
        return retval
    else:
        return None 

def SetInRedis (key,value):
    conn = connect_redis()
    if(conn != None):
        conn.set(key,value)
        print ('Caching data in Redis...')
        return value 

def connect():
    # Connect to the PostgreSQL database server and return a cursor
    conn = None
    try:
        # read connection parameters
        params = config()

        # connect to the PostgreSQL server
        print('Connecting to the PostgreSQL database...')
        conn = psycopg2.connect(**params)
        
                
    except (Exception, psycopg2.DatabaseError) as error:
        print('Error:', error)
        conn = None
    
    else:
        # return a conn
        return conn

app = Flask(__name__) 

@app.before_request
def before_request():
   g.request_start_time = time.time()
   g.request_time = lambda: \"%.5fs\" % (time.time() - g.request_start_time)

@app.route(\"/\")     
def index():
    sql = 'SELECT slow_version();'

    # Fetching db_version from Redis if exists
    key_db_version= 'db_version'
    db_result = fetch_redis(key_db_version)
    
    # Fetching db_version from postgresql and caching in Redis
    if db_result is None:
        print ('DB version Not Found in Redis...')
        db_result = fetch(sql)
        SetInRedis(key_db_version,str(db_result))
    else:
        # Convert the fetched db_version fronm Redis into string
        print ('Retrieved db_version data from Redis...')
        db_result = db_result.decode(\"utf-8\")

    if(db_result):
        db_version = ''.join(db_result)
    else:
        abort(500)
    
    # Fetching db_hostname from Redis if exists
    key_db_host = 'db_host'
    host_param = fetch_redis(key_db_host)

    # Fetching db_hostname from postgresql and caching in Redis
    if host_param is None:
        print ('Hostname Not Found in Redis...')
        params = config()
        host_param = params['host']
        SetInRedis(key_db_host,host_param)

    else:
        # Convert the fetched db_hostname fronm Redis into string
        print ('Retrieved db_hostname data from Redis...')
        host_param=host_param.decode(\"utf-8\")

    return render_template('index.html', db_version = db_version, db_host = host_param)

if __name__ == \"__main__\":        # on running python app.py
    app.run()                     # run the flask app
