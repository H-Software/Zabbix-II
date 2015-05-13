#!/bin/bash

file=/tmp/zabbix_rh.yum.stats.log

flock=/tmp/zabbix_rh.yum.stats.log.lock

function erase_lockfile(){
    rm -f $flock > /dev/null 2>&1
}

if test `find "$flock" -mmin +55 2> /dev/null`; then
    erase_lockfile
fi

if [ -f "$flock" ] ; then
#    sleep 60
    exit 1
fi

touch $flock > /dev/null 2>&1

#refresh data
echo -n "total:" > $file
timeout 900 yum check-update -q --errorlevel=0 |grep -r ^[a-zA-Z0-9].* |wc -l 2> /dev/null >> $file

echo -n "security:" >> $file
timeout 900 yum list-security -q --errorlevel=0 |wc -l 2> /dev/null >> $file

echo -n "extras:" >> $file
timeout 900 yum list extras -q --errorlevel=0 |grep -v "Extra Packages" |wc -l 2> /dev/null >> $file

erase_lockfile

exit 0

