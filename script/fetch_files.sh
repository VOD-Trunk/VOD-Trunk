#!/bin/bash
config_file_path_local='/home/abhishek/Config_Automation/Config_Files'
git_path='/home/abhishek/deepam/VOD-Trunk'
temp='/home/abhishek/Config_Automation/temp.txt'
diff_path='/home/abhishek/deepam/VOD-Trunk/ship_git_diff.csv'
USERNAME=root
PASS="not4dev!"
echo "SHIP NAME, FILE NAME, SERVER NAME, SHIP VALUES, GIT VALUES, DECISION" >$diff_path
for line in `cat ip.txt`
do
    HOSTNAME=`echo $line | cut -d ',' -f 2`
	ship=`echo $line | cut -d ',' -f 1`
	echo "Fetching files from $ship"
	if [ 1 == 2 ]
	then
	echo ${PASS} | sudo sshpass -p ${PASS} ssh -l ${USERNAME} ${HOSTNAME} '/home/config_files/fetch_files.sh'
	fi
	servers="app01 app02 media01 media02 lb01 lb02"
	for server in $servers
	do
		if [ 1 == 2 ]
		then
		sudo rm -f ${config_file_path_local}/${ship}/${server}/*
		echo ${PASS} | sudo sshpass -p ${PASS} scp -r ${USERNAME}@${HOSTNAME}:/home/config_files/$server ${config_file_path_local}/${ship}
		fi
		echo "Server name : $server"
		cd /home/abhishek/deepam/VOD-Trunk
		git checkout develop
		if [ 1 == 2 ]
		then
		echo ${PASS} | sudo rm -rf ${git_path}/SHIP_FILES/${ship}/${server}
		cp -r ${config_file_path_local}/${ship}/${server} ./ship
		fi
		for file in `ls ${git_path}/SHIP_FILES/${ship}/${server}`
		do
			a="${git_path}/SHIP_FILES/${ship}/${server}/${file}"
			b="${git_path}/GIT_FILES/${ship}/${server}/${file}"
			diff $a $b > $temp
			if [ -s $temp ]
			then
				ship_file_values=`grep "<" $temp | cut -c 3- | sed ':a;N;$!ba;s/\n/;/g'`
				master_file_values=`grep ">" $temp | cut -c 3- | sed ':a;N;$!ba;s/\n/;/g'`
				echo "${ship}, ${file}, ${server}, $ship_file_values, $master_file_values" >>$diff_path
			fi
		done
		git add .
		git commit -m "updated files commited"
    done
done
