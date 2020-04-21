#!/bin/bash
#################################################
# Config file comparison automation: Final      #
# Author : ABHISHEK CHADHA                      #
# Date : 4/20/2020                              #
#                                               #
#################################################

git_path=`grep git_path /home/vod/properties/path.txt | cut -d\' -f2`
temp=`grep temp /home/vod/properties/path.txt | cut -d\' -f2`
diff_path=`grep diff_path /home/vod/properties/path.txt | cut -d\' -f2`
logs=`grep logs /home/vod/properties/path.txt | cut -d\' -f2`
ip=`grep "ip=" /home/vod/properties/path.txt | cut -d\' -f2`

USERNAME=`grep USERNAME /home/vod/properties/ship_credentials.txt | cut -d\' -f2`
PASS=`grep PASS /home/vod/properties/ship_credentials.txt | cut -d\' -f2`


echo "SHIP NAME,FILE NAME,SERVER NAME,SHIP VALUES,GIT VALUES,DECISION" >$diff_path
echo "Pulling files from GIT"
echo
cd ${git_path}
git checkout develop
git pull origin develop
rm -f $logs
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
		echo "Could not ssh to $ship : $HOSTNAME" >> $logs
		continue
	fi

	echo "Copying files from app01 of $ship to local GIT path."
	echo "======================================================================================================================="
	echo
	#Copy the consolidated config files from server to local git path.
	sshpass -p ${PASS} scp ${USERNAME}@${HOSTNAME}:/home/config_files/config_files.tar.gz ${git_path}/Ship_Current_Files/${ship}
	cd ${git_path}/Ship_Current_Files/${ship} && tar -xzf config_files.tar.gz && rm -f config_files.tar.gz
	echo "Comparing $ship files with corresponding $ship files in GIT."
	echo "======================================================================================================================="
	echo
	#compare SHIP files just copied with GIT files pulled from GIT.
	servers="app01 media01 lb01"
	for server in $servers
	do
		for file in `ls ${git_path}/Ship_Current_Files/${ship}/${server}`
		do
			#Comparing files between the two servers on same ship to find differences.
			if [ "$server" == "app01" ]
			then
				x="${git_path}/Ship_Current_Files/${ship}/app01/${file}"
				y="${git_path}/Ship_Current_Files/${ship}/app02/${file}"
				if [ ! -f "$x" ] && [ -f "$y" ]
				then
					echo "On $ship, File '${file}' not found in app01 but present in app02." >> $logs
				fi

				if [ -f "$x" ] && [ ! -f "$y" ]
				then
					echo "On $ship, File '${file}' not found in app02 but present in app01." >> $logs
				fi

				if [ -f "$x" ] && [ -f "$y" ]
				then
						diff $x $y > $temp
						if [ -s $temp ]
						then
							echo "On $ship, difference found between app01:$file and app02:$file" >> $logs
						fi
				fi
			fi

			if [ "$server" == "media01" ]
			then
				x="${git_path}/Ship_Current_Files/${ship}/media01/${file}"
				y="${git_path}/Ship_Current_Files/${ship}/media02/${file}"
				if [ ! -f "$x" ] && [ -f "$y" ]
				then
					echo "On $ship, File '${file}' not found in media01 but present in media02." >> $logs
				fi

				if [ -f "$x" ] && [ ! -f "$y" ]
				then
					echo "On $ship, File '${file}' not found in media02 but present in media01." >> $logs
				fi

				if [ -f "$x" ] && [ -f "$y" ]
				then
					diff $x $y > $temp
					if [ -s $temp ]
					then
						echo "On $ship, difference found between media01:$file and media02:$file" >> $logs
					fi
				fi
			fi

			if [ "$server" == "lb01" ]
			then
				x="${git_path}/Ship_Current_Files/${ship}/lb01/${file}"
				y="${git_path}/Ship_Current_Files/${ship}/lb02/${file}"
				if [ ! -f "$x" ] && [ -f "$y" ]
				then
					echo "On $ship, File '${file}' not found in lb01 but present in lb02." >> $logs
				fi

				if [ -f "$x" ] && [ ! -f "$y" ]
				then
					echo "On $ship, File '${file}' not found in lb02 but present in lb01." >> $logs
				fi

				if [ -f "$x" ] && [ -f "$y" ]
				then
					diff $x $y > $temp
					if [ -s $temp ]
					then
						echo "On $ship, difference found between lb01:$file and lb02:$file" >> $logs
					fi
				fi
			fi

			#Comparing current files on ship with corresponding file in GIT.
			a="${git_path}/Ship_Current_Files/${ship}/${server}/${file}"
			b="${git_path}/Ship_Configuration_Files/${ship}/${server}/${file}"

			if [ ! -f "$a" ] && [ -f "$b" ]
			then
				echo "On $ship, File '${file}' not found in Ship_Current_Files but present in Ship_Configuration_Files." >> $logs
			fi

			if [ ! -f "$b" ] && [ -f "$a" ]
			then
				echo "On $ship, File '${file}' not found in Ship_Configuration_Files but present in Ship_Current_Files." >> $logs
			fi
			if [ -f "$b" ] && [ -f "$a" ]
			then
				diff $a $b > $temp
				if [ -s $temp ]
				then
					ship_file_values=`grep "<" $temp | cut -c 3- | sed ':a;N;$!ba;s/\n/;/g'`
					master_file_values=`grep ">" $temp | cut -c 3- | sed ':a;N;$!ba;s/\n/;/g'`
					echo "${ship},${file},${server},$ship_file_values,$master_file_values">>$diff_path
				fi
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
