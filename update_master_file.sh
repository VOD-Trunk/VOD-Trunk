#!/bin/bash
WORKSPACE=$1
#ip=`grep "ip=" /home/vod/properties/path.txt | cut -d\' -f2`
#USERNAME=`grep USERNAME /home/vod/properties/ship_credentials.txt | cut -d\' -f2`
#PASS=`grep PASS /home/vod/properties/ship_credentials.txt | cut -d\' -f2`
#for line in `cat $ip`
#do
#HOSTNAME=`echo $line | cut -d ',' -f 2`
USERNAME='root'
PASS='Carnival@1234'
HOSTNAME='192.168.248.161'
ship=SUPPORT
	
echo "Copying master file to $ship"
sshpass -p ${PASS} scp -o "StrictHostKeyChecking=no" $WORKSPACE/Config_Files_master.txt ${USERNAME}@${HOSTNAME}:/home/config_files/
sshpass -p ${PASS} scp -o "StrictHostKeyChecking=no" $WORKSPACE/fetch_files.sh ${USERNAME}@${HOSTNAME}:/home/config_files/
#done
