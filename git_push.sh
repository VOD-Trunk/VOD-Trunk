#!/bin/bash
git_path=`grep git_path /home/vod/properties/path.txt | cut -d\' -f2`
diff_path=`grep diff_path /home/vod/properties/path.txt | cut -d\' -f2`
cd $git_path
git checkout develop
git pull origin develop
line_count=`wc -l $diff_path | cut -d ' ' -f 1`
echo "Line count : $line_count"
if [ $line_count -gt 1 ]
then
	echo "Reading the csv file for decisions"
	echo "=========================================================================="
	LINES=`cat $diff_path`
	IFS=$'\n'
	for line in $LINES
	do
		ship=`echo $line | cut -d ',' -f 1`
		file=`echo $line | cut -d ',' -f 2`
		server=`echo $line | cut -d ',' -f 3`
		decision=`echo $line | cut -d ',' -f 6`
		if [ "$decision" == "YES" ] || [ "$decision" == "yes" ] || [ "$decision" == "Yes" ] || [ "$decision" == " YES" ]
		then
			echo "Diff found at $ship $server $file $decision"
			cd $git_path
			git checkout develop
			git pull origin develop
			cp $git_path/Ship_Current_Files/$ship/$server/$file $git_path/Ship_Configuration_Files/$ship/$server/$file
			git add .
			git commit -m "Updating $ship GIT files with updated values on $ship"
			
			git checkout master
			git pull origin master
			git add .
			git commit -m "Updating $ship master GIT files with updated values on $ship"
			git checkout develop $git_path/Ship_Configuration_Files/$ship/$server/$file
		fi
	done

	git push origin develop
	git push origin master
fi
