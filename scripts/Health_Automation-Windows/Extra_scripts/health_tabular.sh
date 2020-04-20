#!/bin/bash

ERROR_FILE='/cygdrive/c/Users/E01807/Desktop/HealthCheckCode/errors'
STOPPED_SERVICES='/cygdrive/c/Users/E01807/Desktop/HealthCheckCode/tmp/stopped.txt'
CONTENT='/cygdrive/c/Users/E01807/Desktop/HealthCheckCode/tmp/email1.txt'
TEMP='/cygdrive/c/Users/E01807/Desktop/HealthCheckCode/tmp/temp1.txt'
temp2='/cygdrive/c/Users/E01807/Desktop/HealthCheckCode/tmp/temp2.txt'
temp3='/cygdrive/c/Users/E01807/Desktop/HealthCheckCode/tmp/temp3.txt'
temp4='/cygdrive/c/Users/E01807/Desktop/HealthCheckCode/tmp/temp4.txt'
temp5='/cygdrive/c/Users/E01807/Desktop/HealthCheckCode/tmp/temp5.txt'
HEALTH_REPORTS='/cygdrive/c/Users/E01807/Desktop/HealthCheckCode/Health_Reports'
media_error_count='/cygdrive/c/Users/E01807/Desktop/HealthCheckCode/tmp/media_error_count.txt'
Seconds_Behind_Master='/cygdrive/c/Users/E01807/Desktop/HealthCheckCode/tmp/Seconds_Behind_Master.txt'

rm -f $CONTENT

echo "Ship_name Stopped_service DB_replication_broken Media_storage_issue App_storage_issue Hard_disk_issue app01_load app02_load media01_load media02_load Remote_URL_status Storage_failover Timezone Content_usage_issue" >> $CONTENT
		
for i in `ls $HEALTH_REPORTS`
do
	ship=`grep -i -m 1 app01 $HEALTH_REPORTS/$i | cut -d "." -f 2,3`
        	
	stopped_count=`grep -i "stopped" $HEALTH_REPORTS/$i | wc -l`

			if [ $stopped_count -gt 1 ]
			then
				stopped_service="Yes"
			else
				stopped_service="No"
			fi

	
	grep "Seconds\_Behind\_Master\:\ NULL" $HEALTH_REPORTS/$i > $Seconds_Behind_Master

	if [ -s $Seconds_Behind_Master ]
	then
		db_replication_flag="Yes"
	else
		db_replication_flag="No"
	fi
	
	
	#To check the VIPs situation on all servers.
	
	#sed -n '/VIPs/,/Storage/p' $HEALTH_REPORTS/$i > $temp2
	#app_VIPs=`sed -n '/app01/,/app02/p' $temp2 | grep -i inet | wc -l`
	#media_VIPs=`sed -n '/media01/,/media02/p' $temp2 | grep -i inet | wc -l`
	#lb_VIPs=`sed -n '/lb01/,/lb02/p' $temp2 | grep -i inet | wc -l`
	
	#if [ $app_VIPs -ne 2 ] || [ $media_VIPs == 0 ] || [ $lb_VIPs == 0 ]
	#then
	#	vip_issue="Yes"
	#else
	#	vip_issue="No"
	#fi
	
	#To check media storage going over 85%.
	
	sed -n '/Disk Space/,/Load Balancer Rotation/p' $HEALTH_REPORTS/$i > $temp3
	nfs_m1=`grep -w -m 1 "\/nfs\/m1" $temp3 | tr -s ' ' | cut -d " " -f 7 | cut -d "%" -f 1`
	nfs_m2=`grep -w -m 1 "\/nfs\/m2" $temp3 | tr -s ' ' | cut -d " " -f 7 | cut -d "%" -f 1`
	nfs_a1=`grep -w -m 1 "\/nfs\/a1" $temp3 | tr -s ' ' | cut -d " " -f 7 | cut -d "%" -f 1`
	nfs_a2=`grep -w -m 1 "\/nfs\/a2" $temp3 | tr -s ' ' | cut -d " " -f 7 | cut -d "%" -f 1`
	
	echo "nfs_m1 : $nfs_m1 nfs_m2 : $nfs_m2 nfs_a1 : $nfs_a1 nfs_a2 : $nfs_a2"

	if [ $nfs_m1 -gt 85 ] || [ $nfs_m2 -gt 85 ]
	then
		media_storage_issue="Yes"
	else
		media_storage_issue="No"
	fi
	
	
	if [ $nfs_a1 -gt 90 ] || [ $nfs_m2 -gt 90 ]
	then
		app_storage_issue="Yes"
	else
		app_storage_issue="No"
	fi
	
		
	grep "Media Error Count" $HEALTH_REPORTS/$i > $media_error_count
	
	if [ -s $media_error_count ]
	then
		media_errors=`tac $HEALTH_REPORTS/$i | sed -n '/Media Error Count/,/RAID/p'| tac`
		hard_disk_issue="Yes"
	else
		hard_disk_issue="No"
	fi

	
	#To display load average of 15 minutes on each of app and media server.
	
	sed -n '/CPU Load/,/Memory/p' $HEALTH_REPORTS/$i > $temp4
	app01_load=`grep "load average" $temp4 | cut -d ',' -f 6 | sed -n 1p`
	app02_load=`grep "load average" $temp4 | cut -d ',' -f 6 | sed -n 2p`
	media01_load=`grep "load average" $temp4 | cut -d ',' -f 6 | sed -n 3p`
	media02_load=`grep "load average" $temp4 | cut -d ',' -f 6 | sed -n 4p`
	
		
	#To display whether Remote URL is working or not.
	url_stat=`grep "Remote URL status" $HEALTH_REPORTS/$i | grep "Not working" | wc -l`
	if [ $url_stat == 1 ]
	then
		remote_url_stat="NOK"
	else
		remote_url_stat="OK"
	fi
	
	
	#To display storage failover if present
	sed -n '/Storage/,/Read-Only Filesystems/p' $HEALTH_REPORTS/$i > $temp5
	isStorageFailed=`grep -e "\/nfs\/m2" -e "\/nfs\/m1a2" $temp5 | wc -l`
	echo "isStorageFailed : $isStorageFailed"
	if [ $isStorageFailed -gt 0 ]
	then
		storage_failover="Yes"
	else
		storage_failover="No"
	fi
	
	
	#To alert if Timezone is set as Null.
	isTimeNull=`grep Timezone $HEALTH_REPORTS/$i | grep GMT | wc -l`
	if [ $isTimeNull -ne 1 ]
	then
		timezone="Null"
	else
		timezone=`grep Timezone $HEALTH_REPORTS/$i | grep GMT | cut -d ":" -f 2`
	fi
	
	flag_content=`grep "Content usage report is not refreshed since 24 hours" $HEALTH_REPORTS/$i | wc -l`
	content_alert_Str=`grep "Content usage report is not refreshed since 24 hours" $HEALTH_REPORTS/$i`
	
	if [ $flag_content == 1 ]
	then
		content_usage_issue="Yes"
	else
		content_usage_issue="No"
	fi
	
		
	echo "$ship  $stopped_service $db_replication_flag $media_storage_issue $app_storage_issue $hard_disk_issue $app01_load $app02_load $media01_load $media02_load $remote_url_stat $storage_failover $timezone $content_usage_issue" >> $CONTENT
	
done


#echo "Please find attached the individual reports." >> $CONTENT

sed -i 's/kp.ocean/Crown/; s/di.ocean/Diamond/; s/cbvod.cruises/Caribbean/; s/ep.ocean/Emerald/; s/gpvod2.cruises/Regal/; s/iptv.kodmdomain/KODM/; s/iptv.encdomain/Encore/; s/iptv.eudmdomain/EUDM/; s/mjvod.cruises/Majestic/; s/nadmiptv.com/NADM/; s/iptv.nsdmdomain/NSDM/; s/iptv.odydomain/Odyssey/; s/rp.ocean/Royal/; s/ru.ocean/Ruby/; s/savod.cruises/Sapphire/; s/spvod.cruises/Sun/; s/iptv.ovadomain/Ovation/; s/britanniavod.carnivaluk/Britannia/; s/ap.ocean/Grand/; s/iptv.nodmdomain/NODM/; s/yp.ocean/Sky/; s/iptv.vodmdomain/VODM/; s/iptv.wedmdomain/WEDM/; s/co.ocean/Coral/;  s/iptv.zudmdomain/ZUDM/' $CONTENT


#pscp -pw hsc321 C:/Users/E01807/Desktop/HealthCheckCode/Health_Reports/* root@192.168.248.136:/root/autoring/Health_Reports
pscp -pw hsc321 C:/Users/E01807/Desktop/HealthCheckCode/tmp/email1.txt root@192.168.248.136:/root/autoring/



rm -f $STOPPED_SERVICES $TEMP $Seconds_Behind_Master $temp2 $temp3 $temp4 $temp5

