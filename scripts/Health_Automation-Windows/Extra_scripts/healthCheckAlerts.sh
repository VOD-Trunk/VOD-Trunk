#!/bin/bash

ERROR_FILE='/cygdrive/c/Users/E01807/Desktop/HealthCheckCode/errors'
STOPPED_SERVICES='/cygdrive/c/Users/E01807/Desktop/HealthCheckCode/tmp/stopped.txt'
CONTENT='/cygdrive/c/Users/E01807/Desktop/HealthCheckCode/tmp/email2.txt'
TEMP='/cygdrive/c/Users/E01807/Desktop/HealthCheckCode/tmp/temp1.txt'
temp2='/cygdrive/c/Users/E01807/Desktop/HealthCheckCode/tmp/temp2.txt'
temp3='/cygdrive/c/Users/E01807/Desktop/HealthCheckCode/tmp/temp3.txt'
temp4='/cygdrive/c/Users/E01807/Desktop/HealthCheckCode/tmp/temp4.txt'
temp5='/cygdrive/c/Users/E01807/Desktop/HealthCheckCode/tmp/temp5.txt'
HEALTH_REPORTS='/cygdrive/c/Users/E01807/Desktop/HealthCheckCode/Health_Reports'
media_error_count='/cygdrive/c/Users/E01807/Desktop/HealthCheckCode/tmp/media_error_count.txt'
Seconds_Behind_Master='/cygdrive/c/Users/E01807/Desktop/HealthCheckCode/tmp/Seconds_Behind_Master.txt'

rm -f $CONTENT
echo "Subject: Health Check status" >> $CONTENT
echo >> $CONTENT
#echo "Please find below the health check status of all the ships:" >> $CONTENT
#echo >> $CONTENT

#To fetch ship names which were either unreachable or health check couldn't run.

#echo "Ships missing in this email are :" >> $CONTENT
cat $ERROR_FILE >> $CONTENT

for i in {1..5}
do
	echo >> $CONTENT
done


#To check if any service is stopped on any server.
		
for i in `ls $HEALTH_REPORTS`
do
	ship=`grep -i -m 1 app01 $HEALTH_REPORTS/$i | cut -d "." -f 2,3`
        echo "On ship $ship :" >> $CONTENT
	echo >> $CONTENT
	
	grep -i "stopped" $HEALTH_REPORTS/$i > $STOPPED_SERVICES

			LINES=`cat $STOPPED_SERVICES`
			if [ -s $STOPPED_SERVICES ]

			then
					IFS=$'\n'
					for j in $LINES
					do
							sed -n "1,/$j/p" $HEALTH_REPORTS/$i > $TEMP
				server_name=`tac $TEMP | grep -m 1 ":"| cut -d "." -f 1`
				echo "Server $server_name" >> $CONTENT
							echo $j >> $CONTENT
							echo `date` >> $CONTENT
							echo >> $CONTENT
					done
			fi
			
			
			
	
	
	#To check if any server is unreachable.
	
	Unreachable_servers=`grep -i -m 1 "No route to host"  $HEALTH_REPORTS/$i`
		
	if [ -z $Unreachable_servers ]
	
	then
		:
	else
		echo "Server unreachble error:" >> $CONTENT
		echo  $Unreachable_servers >> $CONTENT
		echo `date` >> $CONTENT
		echo >> $CONTENT
	fi
	
	

	#To check if DB replication is broken.
	
	
	grep "Seconds\_Behind\_Master\:\ NULL" $HEALTH_REPORTS/$i > $Seconds_Behind_Master

	if [ -s $Seconds_Behind_Master ]

	then
		echo "DB Replication has failed on $ship" >> $CONTENT
		echo `date` >> $CONTENT
		echo >> $CONTENT
	fi
	
	
	#To check the VIPs situation on all servers.
	
	sed -n '/VIPs/,/Storage/p' $HEALTH_REPORTS/$i > $temp2
	app_VIPs=`sed -n '/app01/,/app02/p' $temp2 | grep -i inet | wc -l`
	
	if [ $app_VIPs -ne 2 ]
	then
		echo "Both VIPs are not on app01." >> $CONTENT
		echo `date` >> $CONTENT
		echo >> $CONTENT
	fi
	
	media_VIPs=`sed -n '/media01/,/media02/p' $temp2 | grep -i inet | wc -l`
	
	if [ $media_VIPs == 0 ]
	then
		echo "No VIP on media01" >> $CONTENT
		echo `date` >> $CONTENT
		echo >> $CONTENT
	fi

	lb_VIPs=`sed -n '/lb01/,/lb02/p' $temp2 | grep -i inet | wc -l`

	if [ $lb_VIPs == 0 ]
        then
		echo "No VIP on lb01" >> $CONTENT
		echo `date` >> $CONTENT	
		echo >> $CONTENT
    fi

	
	#To check media storage going over 75%.
	
	sed -n '/Disk Space/,/Load Balancer Rotation/p' $HEALTH_REPORTS/$i > $temp3
	nfs_m1=`grep -w -m 1 "\/nfs\/m1" $temp3 | tr -s ' ' | cut -d " " -f 7 | cut -d "%" -f 1`
	nfs_m2=`grep -w -m 1 "\/nfs\/m2" $temp3 | tr -s ' ' | cut -d " " -f 7 | cut -d "%" -f 1`
	nfs_a1=`grep -w -m 1 "\/nfs\/a1" $temp3 | tr -s ' ' | cut -d " " -f 7 | cut -d "%" -f 1`
	nfs_a2=`grep -w -m 1 "\/nfs\/a2" $temp3 | tr -s ' ' | cut -d " " -f 7 | cut -d "%" -f 1`
	
	if [ $nfs_m1 -gt 85 ] || [ $nfs_m2 -gt 85 ]
	then
		echo "Below partitions are using more than 85% storage. Please check urgently." >> $CONTENT
		echo >> $CONTENT
		echo >> $CONTENT
		
		if [ $nfs_m1 -gt 85 ]
		then
				echo "------------ /nfs/m1 is using more than 85% disk space.-------------" >> $CONTENT
				echo >> $CONTENT
				echo >> $CONTENT
		fi

		if [ $nfs_m2 -gt 85 ]
		then
				echo "------------ /nfs/m2 is using more than 85% disk space.-------------" >> $CONTENT
				echo >> $CONTENT
				echo >> $CONTENT
		fi
		
		if [ $nfs_a1 -gt 85 ]
		then
				echo "------------ /nfs/a1 is using more than 85% disk space.-------------" >> $CONTENT
				echo >> $CONTENT
				echo >> $CONTENT
		fi
		
		if [ $nfs_a2 -gt 85 ]
		then
				echo "------------ /nfs/a2 is using more than 85% disk space.-------------" >> $CONTENT
				echo >> $CONTENT
				echo >> $CONTENT
		fi
	fi

	
	#To check media error counts on the Dell hard drives. Won't work with HP servers.
	
	grep "Media Error Count" $HEALTH_REPORTS/$i > $media_error_count
	
	if [ -s $media_error_count ]
	then
		echo "Below errors are found on the Hard Disks." >> $CONTENT
		tac $HEALTH_REPORTS/$i | sed -n '/Media Error Count/,/RAID/p'| tac >> $CONTENT
		echo >> $CONTENT
		echo >> $CONTENT
	fi

	
	#To display load average of 15 minutes on each of app and media server.
	
	sed -n '/CPU Load/,/Memory/p' $HEALTH_REPORTS/$i > $temp4
	app01_load=`grep "load average" $temp4 | cut -d ',' -f 6 | sed -n 1p`
	app02_load=`grep "load average" $temp4 | cut -d ',' -f 6 | sed -n 2p`
	media01_load=`grep "load average" $temp4 | cut -d ',' -f 6 | sed -n 3p`
	media02_load=`grep "load average" $temp4 | cut -d ',' -f 6 | sed -n 4p`
	
	echo "The CPU load average on each server is as given below:" >> $CONTENT
	echo "app01 --> $app01_load" >> $CONTENT
	echo "app02 --> $app02_load" >> $CONTENT
	echo "media01 --> $media01_load" >> $CONTENT
	echo "media02 --> $media02_load" >> $CONTENT
	echo >> $CONTENT
	echo >> $CONTENT
	
	#To display whether Remote URL is working or not.
	url_stat=`grep "Remote URL status" $HEALTH_REPORTS/$i | grep "Not working" | wc -l`
	if [ $url_stat == 1 ]
	then
		echo "Remote URL status : Not working" >> $CONTENT
		echo >> $CONTENT
		echo >> $CONTENT
	fi
	
	
	#To display storage failover if present
	sed -n '/Storage/,/Read-Only Filesystems/p' $HEALTH_REPORTS/$i > $temp5
	isStorageFailed=`grep -e "\/nfs\/m2" -e "\/nfs\/m1a2" $temp5 | wc -l`
	if [ $isStorageFailed -gt 0 ]
	then
		echo "Storage failover observed on this ship. Please check urgently." >> $CONTENT
		echo >> $CONTENT
		echo >> $CONTENT
	fi
	
	
	#To alert if Timezone is set as Null.
	isTimeNull=`grep Timezone $HEALTH_REPORTS/$i | grep GMT | wc -l`
	if [ $isTimeNull -ne 1 ]
	then
		echo "Timezone is set as Null. Please check urgently." >> $CONTENT
		echo >> $CONTENT
		echo >> $CONTENT
	fi
	
	flag_content=`grep "Content usage report is not refreshed since 24 hours" $HEALTH_REPORTS/$i | wc -l`
	content_alert_Str=`grep "Content usage report is not refreshed since 24 hours" $HEALTH_REPORTS/$i`
	
	if [ $flag_content == 1 ]
	then
		echo $content_alert_Str >> $CONTENT
	fi
	
	
	for i in {1..3}
	do
	echo >> $CONTENT
	done

done

echo "Please find attached the individual reports." >> $CONTENT

sed -i 's/kp.ocean/Crown\ Princess/; s/di.ocean/Diamond\ Princess/; s/cbvod.cruises/Caribbean\ Princess/; s/ep.ocean/Emerald\ Princess/; s/gpvod2.cruises/Regal\ Princess/; s/iptv.kodmdomain/KODM/; s/iptv.encdomain/Encore/; s/iptv.eudmdomain/EUDM/; s/mjvod.cruises/Majestic/; s/nadmiptv.com/NADM/; s/iptv.nsdmdomain/NSDM/; s/iptv.odydomain/Odyssey/; s/rp.ocean/Royal\ Princess/; s/ru.ocean/Ruby\ Princess/; s/savod.cruises/Sapphire\ Princess/; s/spvod.cruises/Sun\ Princess/; s/iptv.ovadomain/Ovation/; s/britanniavod.carnivaluk/Britannia/; s/ap.ocean/Grand/; s/iptv.nodmdomain/NODM/; s/yp.ocean/Sky\ Princess/; s/iptv.vodmdomain/VODM/; s/iptv.wedmdomain/WEDM/; s/co.ocean/Coral\ Princess/; s/iptv.zudmdomain/ZUDM/' $CONTENT


pscp -pw hsc321 C:/Users/E01807/Desktop/HealthCheckCode/Health_Reports/* root@192.168.248.136:/root/autoring/Health_Reports
pscp -pw hsc321 C:/Users/E01807/Desktop/HealthCheckCode/tmp/email2.txt root@192.168.248.136:/root/autoring/



rm -f $STOPPED_SERVICES $TEMP $Seconds_Behind_Master $temp2 $temp3 $temp4 $temp5
