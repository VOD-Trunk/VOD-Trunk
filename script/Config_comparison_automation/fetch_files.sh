#!/bin/bash
#################################################
# Config file comparison automation: Final      #
# Author : ABHISHEK CHADHA                      #
# Date : 4/15/2020                              #
#                                               #
#################################################

git_path='/home/abhishek/deepam/VOD-Trunk'
temp='/home/abhishek/Config_Automation/temp.txt'
diff_path='/home/abhishek/deepam/VOD-Trunk/ship_git_diff.csv'
ip='/home/abhishek/Config_Automation/ip.txt'
USERNAME=root
PASS="not4dev!"
echo "SHIP NAME,FILE NAME,SERVER NAME,SHIP VALUES,GIT VALUES,DECISION" >$diff_path
echo "Pulling files from GIT"
echo
cd ${git_path}
git checkout develop
git pull origin develop
echo "======================================================================================================================="
echo
for line in `cat $ip`
do
    HOSTNAME=`echo $line | cut -d ',' -f 2`
	ship=`echo $line | cut -d ',' -f 1`
	echo
	echo
	echo
	echo
	echo "Copying files from all six servers to /home/config_files in app01 server of $ship"
	echo "======================================================================================================================="
	echo

	#Run the script fetch_files.sh on respective servers and move to next hostname if ssh takes more than 20 seconds.
	sshpass -p ${PASS} ssh -o ConnectTimeout=20 ${USERNAME}@${HOSTNAME} 'cd /home/config_files/ && rm -f config_files.tar.gz && ./fetch_files.sh && tar -czf config_files.tar.gz app01 app02 media01 media02 lb01 lb02' 2>/dev/null
	e=$?
	if [ "$e" != "0" ]
	then
		continue
	fi

	echo "Copying files from app01 of $ship to local GIT path."
	echo "======================================================================================================================="
	echo
	#Copy the consolidated config files from server to local git path.
	sshpass -p ${PASS} scp ${USERNAME}@${HOSTNAME}:/home/config_files/config_files.tar.gz ${git_path}/SHIP_FILES/${ship}
	cd ${git_path}/SHIP_FILES/${ship} && tar -xzf config_files.tar.gz && rm -f config_files.tar.gz
	echo "Comparing $ship files with corresponding $ship files in GIT."
	echo "======================================================================================================================="
	echo
	#compare SHIP files just copied with GIT files pulled from GIT.
	servers="app01 media01 lb01"
	for server in $servers
	do
		for file in `ls ${git_path}/SHIP_FILES/${ship}/${server}`
		do
			a="${git_path}/SHIP_FILES/${ship}/${server}/${file}"
			b="${git_path}/GIT_FILES/${ship}/${server}/${file}"
			diff $a $b > $temp
			if [ -s $temp ]
			then
				ship_file_values=`grep "<" $temp | cut -c 3- | sed ':a;N;$!ba;s/\n/;/g'`
				master_file_values=`grep ">" $temp | cut -c 3- | sed ':a;N;$!ba;s/\n/;/g'`
				echo "${ship},${file},${server},$ship_file_values,$master_file_values">>$diff_path
			fi
		done
	done
	echo "Logged all the differences in $diff_path"
	echo "======================================================================================================================="
	echo
done

echo "Sending the diff URL to all stake holders. --Email config not present currently, so skipping this part."
echo "======================================================================================================================="
echo
if [ 1 == 2 ]
then
line_count=`wc -l $diff_path`
if [ $line_count -gt 1 ]
then
	echo "https://github.com/VOD-Trunk/VOD-Trunk/blob/develop/ship_git_diff.csv" | sendmail abhishek.chadha@hsc.com
fi
fi

echo "Pushing the ship files and diff file in GIT."
echo "======================================================================================================================="
echo

cd ${git_path}
git add .
git commit -m "Updated files commited on `date`"
git push origin develop
