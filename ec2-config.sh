#!/bin/bash

# Create a log file to monitor the execution of user data
# Redirect the stdout & stderr to init-script.log file
exec &> /var/log/init-script.log
set -o verbose
set -o errexit
set -o pipefail

# Check if python3 is installed, and install it if not
python3 --version || sudo yum install python3

# Check if pip3 is installed, and install it if not
pip3 --version || sudo yum -y install python3-pip

pip3 install psycopg2-binary flask configparser

#Install Redis for python
pip3 install redis

#Install Redis6 for redis-cli
amazon-linux-extras install redis6 -y

# Install postgresql client
yum install postgresql -y

# This is to convert the app-redis.py to Unix format
yum install dos2unix -y

# Download the application code
cd ~
wget https://github.com/ACloudGuru/elastic-cache-challenge/archive/refs/heads/master.zip
unzip master.zip
cd elastic-cache-challenge-master/

# Connect to the postgresql db and create the function used by the app 
export PGPASSWORD=${db_password}
db_endpoint_host=$(echo ${db_endpoint} | cut -d : -f 1)
psql -h $db_endpoint_host -U ${db_user} --no-password  -f install.sql ${db_name}

# Configure DB Connection
echo "[postgresql]
host=$(echo $db_endpoint_host)
database=${db_name}
user=${db_user}
password=$(echo $PGPASSWORD)"> ./config/database.ini

# Copy the app-redis.py content to the remote server
touch app-redis.py
echo "${app_redis}" > app-redis.py
dos2unix app-redis.py

sed -i -e "s/redis-cluster-endpoint-placeholder/${redis_endpoint}/g" app-redis.py

