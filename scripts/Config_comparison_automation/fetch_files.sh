#!/bin/bash
temp='/home/config_files/temp.txt'
master='/home/config_files/Config_files_master.txt'
rm -f /home/config_files/app01/*
rm -f /home/config_files/app02/*
rm -f /home/config_files/media01/*
rm -f /home/config_files/media02/*
rm -f /home/config_files/lb01/*
rm -f /home/config_files/lb02/*
IFS=$'\n'
sed -n '/Application\ Server/,/Media\ Server/p' $master > $temp
for i in `cat $temp`
do
	if [ "$i" == "Application Server" ] || [ "$i" == "Media Server" ] || [ "$i" == "" ]
	then
		   continue
	else
		   cp $i /home/config_files/app01
		   scp app02:$i /home/config_files/app02
	fi
done

sed -n '/Media\ Server/,/Load\ Balancer/p' $master >  $temp
for j in `cat $temp`
do
	if [ "$j" == "Media Server" ] || [ "$j" == "Load Balancer" ] || [ "$j" == "" ]
	then
		   continue
	else
		   scp media01:$j /home/config_files/media01
		   scp media02:$j /home/config_files/media02
	fi
done

sed -n '/Load\ Balancer/,$p' $master >  $temp
for k in `cat $temp`
do
	if [ "$k" == "Load Balancer" ] || [ "$k" == "" ]
	then
		   continue
	else
	   scp lb01:$k /home/config_files/lb01
	   scp lb02:$k /home/config_files/lb02
	fi
done
