#!/bin/bash
git_path='/home/abhishek/deepam/VOD-Trunk'
diff_path='/home/abhishek/deepam/VOD-Trunk/ship_git_diff.csv'
line_count=`wc -l $diff_path`
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
		if [ "$decision" == "YES" ] || [ "$decision" == "yes" ] || [ "$decision" == "Yes" ] || [ "$decision" == " YES" ] || [ "$decision" == " yes" ]
		then
			echo "Diff found at $ship $server $file $decision"
			cd $git_path
			git checkout develop
			git pull origin develop
			cp $git_path/SHIP_FILES/$ship/$server/$file $git_path/GIT_FILES/$ship/$server/$file
			git add .
			git commit -m "Updating $ship GIT files with updated values on $ship"
			
			git checkout master
			git pull origin master
			git add .
			git commit -m "Updating $ship master GIT files with updated values on $ship"
			git checkout develop $git_path/GIT_FILES/$ship/$server/$file
		fi
	done

	git push origin develop
	git push origin master
fi
