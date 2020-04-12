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
	echo $HOSTNAME
	sshpass -p ${PASS} ssh ${USERNAME}@${HOSTNAME} '/home/config_files/fetch_files.sh'
	servers="app01 app02 media01 media02 lb01 lb02"
	for server in $servers
	do
		sudo rm -f ${config_file_path_local}/${ship}/${server}/*
		sshpass -p ${PASS} scp -r ${USERNAME}@${HOSTNAME}:/home/config_files/$server ${config_file_path_local}/${ship}
		echo "Server name : $server"
		cd /home/abhishek/deepam/VOD-Trunk
		git checkout develop
		git pull origin develop

		echo ${PASS} | sudo rm -f ${git_path}/SHIP_FILES/${ship}/${server}/*
		cp -r ${config_file_path_local}/${ship}/${server} ${git_path}/SHIP_FILES/${ship}

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
    	done
done

line_count=`wc -l $diff_path`
if [ $line_count -gt 1 ]
then
	echo "https://github.com/VOD-Trunk/VOD-Trunk/blob/develop/ship_git_diff.csv" | sendmail abhishek.chadha@hsc.com
fi

git add .
git commit -m "Updated files commited on `date`"
git push origin develop
