#!/bin/bash

WORKSPACE=$1

USERNAME='root'
PASS=`echo Q2Fybml2YWxAMTIzNAo= | base64 -d`
HOSTNAME='192.168.248.161'
Ship_NAME=SUPPORT
log_file='config.log'

if [ ! -d $WORKSPACE/Config_Files/VOD-Trunk/$Ship_NAME ]
then
mkdir -p $WORKSPACE/Config_Files/VOD-Trunk/$Ship_NAME
fi

git_path=$WORKSPACE/Config_Files/VOD-Trunk

#Run the script fetch_files.sh on respective servers and move to next hostname if ssh takes more than 20 seconds.
sshpass -p ${PASS} ssh -o "StrictHostKeyChecking=no" ${USERNAME}@${HOSTNAME} 'cd /home/config_files/ && rm -f config_files.tar.gz && ./fetch_files.sh && tar -czf config_files.tar.gz app01 app02 media01 media02 lb01 lb02' 2>/dev/null
	T=$?
	if [ "$T" != "0" ]
	then
		echo "Could not ssh to $Ship_NAME" >> $log_file
		continue
	fi

echo "Copying files from app01 of $Ship_NAME to local GIT path."
	echo "======================================================================================================================="
	echo


#Copy the consolidated config files from server to local git path.
sshpass -p ${PASS} scp ${USERNAME}@${HOSTNAME}:/home/config_files/config_files.tar.gz ${git_path}/Ship_Current_Files/${Ship_NAME}
cd ${git_path}/Ship_Current_Files/${Ship_NAME} && tar -xzf config_files.tar.gz && rm -f config_files.tar.gz
