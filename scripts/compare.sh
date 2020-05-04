#!/bin/bash
ideal_path='/home/vod/Ship_Current_Files/Sky-Princess'
config_path='/home/vod/Ship_Current_Files'
temp='/home/vod/tmp/temp1.txt'
diff_path='/home/vod/tmp/diff.csv'


suppress_comments()
{
	extension=`echo $1 | cut -d '.' -f 2`
	sed -i 's/^[ \t]*//' $1
	sed -i 's/#.*$//g' $1

}



for server in `ls $ideal_path`
do
	for file in `ls $ideal_path/$server`
	do
		suppress_comments $ideal_path/$server/$file
	done
done

echo "SHIP NAME, FILE NAME, SERVER NAME, SHIP VALUES, IDEAL VALUES" >$diff_path
#server="app01"
for ship in `ls $config_path`
do
	echo "Comparing $ship files"
	for server in `ls $config_path/$ship`
	do
		for file in `ls $config_path/$ship/$server`
		do
			extension=`echo $file | cut -d '.' -f 2`
			if [ "$file" != "vhosts.conf" ]
			then
				suppress_comments $config_path/$ship/$server/$file
				a="$ideal_path/$server/$file"
				b="$config_path/$ship/$server/$file"
				diff $a $b > $temp
				if [ -s $temp ]
				then
						ideal_file_values=`grep "<" $temp | cut -c 3- | sed ':a;N;$!ba;s/\n/;/g'| sed 's/,/","/g'`
						ship_file_values=`grep ">" $temp | cut -c 3- | sed ':a;N;$!ba;s/\n/;/g'| sed 's/,/","/g'`
						echo "${ship},${file},${server},$ship_file_values,$ideal_file_values" >>$diff_path
				fi
			fi
		done
	done
done
