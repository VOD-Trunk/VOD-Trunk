#!/bin/bash

WORKSPACE=$1

USERNAME='root'
PASS=`echo Q2Fybml2YWxAMTIzNAo= | base64 -d`
HOSTNAME='192.168.248.161'
Ship_NAME=SUPPORT
log_file='config.log'

if [ ! -d $WORKSPACE/Ship_Config/VOD-Trunk/Ship_Current_Files/$Ship_NAME ]
then
mkdir -p $WORKSPACE/Ship_Config/VOD-Trunk/Ship_Current_Files/$Ship_NAME
fi

if [ ! -d $WORKSPACE/Config_Files ]
then
mkdir -p $WORKSPACE/Config_Files
fi

git_path=$WORKSPACE/Ship_Config/VOD-Trunk
push_path=$WORKSPACE/Config_Files

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
sshpass -p ${PASS} scp -o "StrictHostKeyChecking=no" ${USERNAME}@${HOSTNAME}:/home/config_files/config_files.tar.gz ${git_path}/Ship_Current_Files/${Ship_NAME}
cd ${git_path}/Ship_Current_Files/${Ship_NAME} && tar -xzf config_files.tar.gz && rm -f config_files.tar.gz


#Push All config files to git
cd ${push_path}
git init
git remote add VOD-Trunk https://github.com/VOD-Trunk/VOD-Trunk.git
git clone https://github.com/VOD-Trunk/VOD-Trunk.git
#git checkout -b develop
#git pull develop
cp -r ${git_path}/Ship_Current_Files/${Ship_NAME} $WORKSPACE/Config_Files/VOD-Trunk/Ship_Configuration_Files/
cd ${push_path}/VOD-Trunk
sudo git add --all
sudo git commit -m "Updating $Ship_NAME GIT files with updated values on $Ship_NAME config"
sudo git push --all

echo "======================================================================================================================="
echo  "GIT Changes Pushed"
