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
Ship_NAME=SUPPORT
log_file='configFetch.log'
	
echo "Copying master file to $Ship_NAME"
sshpass -p ${PASS} ssh -o "StrictHostKeyChecking=no" ${USERNAME}@${HOSTNAME} 'if [ ! -d /home/config_files ]; then mkdir -p /home/config_files;fi'
sshpass -p ${PASS} ssh -o "StrictHostKeyChecking=no" ${USERNAME}@${HOSTNAME} 'if [ ! -f /home/config_files/temp.txt ]; then touch /home/config_files/temp.txt;fi'
sshpass -p ${PASS} scp -o "StrictHostKeyChecking=no" $WORKSPACE/Config_Files_master.txt ${USERNAME}@${HOSTNAME}:/home/config_files/
sshpass -p ${PASS} scp -o "StrictHostKeyChecking=no" $WORKSPACE/fetch_files.sh ${USERNAME}@${HOSTNAME}:/home/config_files/
sshpass -p ${PASS} ssh -o "StrictHostKeyChecking=no" ${USERNAME}@${HOSTNAME} "bash -s" -- < $WORKSPACE/fetch_files.sh >> $workspace/logs/"${log_file}"
#done
