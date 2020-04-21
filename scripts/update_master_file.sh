#!/bin/bash
ip=`grep "ip=" /home/vod/properties/path.txt | cut -d\' -f2`
USERNAME=`grep USERNAME /home/vod/properties/ship_credentials.txt | cut -d\' -f2`
PASS=`grep PASS /home/vod/properties/ship_credentials.txt | cut -d\' -f2`
for line in `cat $ip`
do
	HOSTNAME=`echo $line | cut -d ',' -f 2`
	ship=`echo $line | cut -d ',' -f 1`
	
	echo "Copying master file to $ship"
	#sshpass -p ${PASS} scp /home/vod/properties/Config_Files_master.txt ${USERNAME}@${HOSTNAME}:/home/config_files/
	sshpass -p ${PASS} scp /home/vod/scripts/fetch_files.sh ${USERNAME}@${HOSTNAME}:/home/config_files/
done
