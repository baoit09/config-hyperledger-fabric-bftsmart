#!/bin/sh

set -e

sudo apt-get update || true
sudo apt-get --no-install-recommends -y install \
    build-essential pkg-config runit erlang \
    libicu-dev libmozjs185-dev libcurl4-openssl-dev

wget http://apache-mirror.rbc.ru/pub/apache/couchdb/source/2.1.1/apache-couchdb-2.1.1.tar.gz

tar -xvzf apache-couchdb-2.1.1.tar.gz
cd apache-couchdb-2.1.1/
./configure && make release
USER="couchdb"
EXISTS=$( cat /etc/passwd | grep $USER | sed -e 's/:.*//g') 
echo ${EXISTS}
if [ ${EXISTS} != "couchdb" ] ; then
sudo adduser --system \
        --no-create-home \
        --shell /bin/bash \
        --group --gecos \
        "CouchDB Administrator" couchdb
fi

sudo rm -rf /home/couchdb/*
sudo cp -R rel/couchdb /home/couchdb
sudo chown -R couchdb:couchdb /home/couchdb
sudo find /home/couchdb -type d -exec chmod 0770 {} \;
sudo sh -c 'chmod 0644 /home/couchdb/etc/*'

if [ -d /opt/couchdb ] ;  then
sudo rm -rf /opt/couchdb
fi
sudo mkdir /opt/couchdb
sudo mkdir /opt/couchdb/data
sudo chmod 777 -R /opt/couchdb
sudo cp ../local.ini /home/couchdb/etc/local.ini

if [ ! -d /var/log/couchdb ] ; then
sudo mkdir /var/log/couchdb
sudo chown couchdb:couchdb /var/log/couchdb
fi
if [ ! -d /etc/sv ] ; then
sudo mkdir /etc/sv
fi
if [ ! -d /etc/sv/couchdb ] ; then
sudo mkdir /etc/sv/couchdb
sudo mkdir /etc/sv/couchdb/log
fi

sudo rm -rf /ect/sv/couchdb/log/*

cat > run << EOF
#!/bin/sh
export HOME=/home/couchdb
exec 2>&1
exec chpst -u couchdb /home/couchdb/bin/couchdb
EOF

cat > log_run << EOF
#!/bin/sh
exec svlogd -tt /var/log/couchdb
EOF

sudo mv ./run /etc/sv/couchdb/run
sudo mv ./log_run /etc/sv/couchdb/log/run

sudo chmod u+x /etc/sv/couchdb/run
sudo chmod u+x /etc/sv/couchdb/log/run

sudo mkdir -p /etc/service
if [ -d /etc/service/couchdb ] ; then
sudo rm -rf /etc/service/couchdb/*
fi
sudo ln -s /etc/sv/couchdb/ /etc/service/couchdb

sleep 5
sudo sv status couchdb
if [ -f /etc/service/couchdb/supervise/lock ] ; then
sudo rm /etc/service/couchdb/supervise/lock
fi
sudo sv stop /etc/service/couchdb
sudo runsv /etc/service/couchdb &
sudo sv start /etc/service/couchdb
