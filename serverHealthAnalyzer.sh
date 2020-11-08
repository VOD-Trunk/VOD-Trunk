#!/bin/bash

workspace=$1

if [ ! -d $workspace/tmp ]
then
	mkdir -p $workspace/tmp
fi

ERROR_FILE=$workspace/logs/errors
CONTENT=$workspace/tmp/email1.txt
CONTENT2=$workspace/tmp/email2.txt
TEMP=$workspace/tmp/temp.txt
TEMP2=$workspace/tmp/temp2.txt
HEALTH_REPORTS=$workspace/Health_Reports
email_body=$workspace/tmp/body.html

rm -f $CONTENT $CONTENT2

echo "Ship_name | Stopped_service | DB_replication_broken | Media_storage_issue | App_storage_issue | app01_load | app02_load | media01_load | media02_load | nfs_read_only | Storage_failover | Timezone | Content_usage_issue | Itinerary_present" >> $CONTENT
echo "Ship_name | RAID_Status | Memory_Status | Fan_Status | Battery_Status | Temp_Status | Processor_Status" >> $CONTENT2

sed -i "s/'//g; s/\[//g; s/\]//g; s/\,/\n/g" $ERROR_FILE 
sed -i 's/^[ \t]*//' $ERROR_FILE

rows=`cat $ERROR_FILE`
IFS=$'\n'
for row in $rows
do
	echo "$row | NA | NA | NA | NA | NA | NA | NA | NA | NA | NA | NA | NA | NA" >> $CONTENT
	echo "$row | NA | NA | NA | NA | NA | NA" >> $CONTENT2

done

for i in `ls $HEALTH_REPORTS`
do
	ship=`grep -i -m 1 app01 $HEALTH_REPORTS/$i | cut -d "." -f 2,3`
        	
	stopped_count=`grep -i "stopped" $HEALTH_REPORTS/$i | wc -l`
	stopped_names=''
	grep -i "stopped" $HEALTH_REPORTS/$i > $TEMP
	if [ -s $TEMP ]
	then
		sed -i 's/^[ \t]*//' $TEMP
		LINES=`cat $TEMP`
		IFS=$'\n'
		s=0
		haproxy_stop_count=`grep -i haproxy $TEMP | wc -l`
		for j in $LINES
		do
			sed -n "1,/$j/p" $HEALTH_REPORTS/$i > $TEMP2
			server_name=`tac $TEMP2 | grep -m 1 ":"| cut -d "." -f 1`
			stopped_serv=`echo $j | cut -d ' ' -f 1`
			stopped_next="$server_name:$stopped_serv"
			if [ $s == 0 ]
			then
				stopped_names="$stopped_next"
			elif ([ $haproxy_stop_count == 2 ] && ([ "$stopped_next" == "lb01:haproxy" ] || [ "$stopped_next" == "lb02:haproxy" ])) && [ "$stopped_next" != "$stopped_names" ]
			then
				stopped_names="$stopped_names,$stopped_next"
			elif [ "$stopped_next" != "lb01:haproxy" ] && [ "$stopped_next" != "lb02:haproxy" ] && [ "$stopped_next" != "$stopped_names" ]
			then
				stopped_names="$stopped_names,$stopped_next"
			else
				:
			fi
			s=$((s+1))
		done
	fi
	echo "stopped names : $stopped_names"

	if [ $stopped_count -gt 1 ]
	then
		stopped_service="$stopped_names"
	else
		stopped_service="OK"
	fi

	
	grep "Seconds\_Behind\_Master\:\ NULL" $HEALTH_REPORTS/$i > $TEMP

	if [ -s $TEMP ]
	then
		db_replication_flag="Broken"
	else
		db_replication_flag="OK"
	fi
	
	
	
	#To check media storage going over 85%.
	
	sed -n '/Disk Space/,/Load Balancer Rotation/p' $HEALTH_REPORTS/$i > $TEMP
	nfs_m1=`grep -w -m 1 "\/nfs\/m1" $TEMP | tr -s ' ' | cut -d " " -f 7 | cut -d "%" -f 1`
	nfs_m2=`grep -w -m 1 "\/nfs\/m2" $TEMP | tr -s ' ' | cut -d " " -f 7 | cut -d "%" -f 1`
	nfs_a1=`grep -w -m 1 "\/nfs\/a1" $TEMP | tr -s ' ' | cut -d " " -f 7 | cut -d "%" -f 1`
	nfs_a2=`grep -w -m 1 "\/nfs\/a2" $TEMP | tr -s ' ' | cut -d " " -f 7 | cut -d "%" -f 1`
	
	#echo "nfs_m1 : $nfs_m1 nfs_m2 : $nfs_m2 nfs_a1 : $nfs_a1 nfs_a2 : $nfs_a2"

	if [ $nfs_m1 -gt 85 ] || [ $nfs_m2 -gt 85 ]
	then
		media_storage_issue="NOK"
	else
		media_storage_issue="OK"
	fi
	
	
	if [ $nfs_a1 -gt 80 ] || [ $nfs_a2 -gt 80 ]
	then
		app_storage_issue="NOK"
	else
		app_storage_issue="OK"
	fi
	
		
	#To display load average of 15 minutes on each of app and media server.
	
	sed -n '/CPU Load/,/Memory/p' $HEALTH_REPORTS/$i > $TEMP
	app01_load=`grep "load average" $TEMP | cut -d ',' -f 6 | sed -n 1p`
	app02_load=`grep "load average" $TEMP | cut -d ',' -f 6 | sed -n 2p`
	media01_load=`grep "load average" $TEMP | cut -d ',' -f 6 | sed -n 3p`
	media02_load=`grep "load average" $TEMP | cut -d ',' -f 6 | sed -n 4p`
	
		
	#To display whether Remote URL is working or not.
	url_stat=`grep "Remote URL status" $HEALTH_REPORTS/$i | grep "Not working" | wc -l`
	if [ $url_stat == 1 ]
	then
		remote_url_stat="NOK"
	else
		remote_url_stat="OK"
	fi
	
	
	#To display storage failover if present
	sed -n '/Storage/,/Read-Only Filesystems/p' $HEALTH_REPORTS/$i > $TEMP
	isStorageFailed=`grep -e "\/nfs\/m2" -e "\/nfs\/m1a2" $TEMP | wc -l`
	#echo "isStorageFailed : $isStorageFailed"
	if [ $isStorageFailed -gt 0 ]
	then
		storage_failover="NOK"
	else
		storage_failover="OK"
	fi
	
	#To display storage failover if present
	sed -n '/Read-Only Filesystems/,/Replication/p' $HEALTH_REPORTS/$i > $TEMP
	isReadOnly=`grep "ro," $TEMP | wc -l`
	if [ $isReadOnly -gt 0 ]
	then
		read_only="NOK"
	else
		read_only="OK"
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
		content_usage_issue="NOK"
	else
		content_usage_issue="OK"
	fi

	flag_itinerary=`grep "Current itinerary is not present." $HEALTH_REPORTS/$i | wc -l`

	if [ $flag_itinerary == 1 ]
	then
		Itinerary_present="NOK"
	else
		Itinerary_present="OK"
	fi

	#hardware metrics

	raid_status_count=`grep "RAID status" $HEALTH_REPORTS/$i | cut -d ':' -f 2- | grep "OK" | wc -l`
	raid_status_orig=`grep "RAID status" $HEALTH_REPORTS/$i | cut -d ':' -f 2- | sort -u | grep -v "OK" | tr '\n' ','`
	
	memory_status_count=`grep "Memory Status" $HEALTH_REPORTS/$i | cut -d ':' -f 2- | grep "OK" | wc -l`
	memory_status_orig=`grep "Memory Status" $HEALTH_REPORTS/$i | cut -d ':' -f 2- | sort -u | grep -v "OK" | tr '\n' ','`
	
	fan_status_count=`grep "Fan Status" $HEALTH_REPORTS/$i | cut -d ':' -f 2- | grep "OK" | wc -l`
	fan_status_orig=`grep "Fan Status" $HEALTH_REPORTS/$i | cut -d ':' -f 2- | sort -u | grep -v "OK" | tr '\n' ','`
	
	battery_status_count=`grep "Battery Status" $HEALTH_REPORTS/$i | cut -d ':' -f 2- | grep "OK" | wc -l`
	battery_status_orig=`grep "Battery Status" $HEALTH_REPORTS/$i | cut -d ':' -f 2- | sort -u | grep -v "OK" | tr '\n' ','`
	
	temp_status_count=`grep "Temp Status" $HEALTH_REPORTS/$i | cut -d ':' -f 2- | grep "OK" | wc -l`
	temp_status_orig=`grep "Temp Status" $HEALTH_REPORTS/$i | cut -d ':' -f 2- | sort -u | grep -v "OK" | tr '\n' ','`
	
	processor_status_count=`grep "Processor Status" $HEALTH_REPORTS/$i | cut -d ':' -f 2- | grep "OK" | wc -l`
	processor_status_orig=`grep "Processor Status" $HEALTH_REPORTS/$i | cut -d ':' -f 2- | sort -u | grep -v "OK" | tr '\n' ','`
	

	if [ $raid_status_count -eq 6 ]
	then
		raid_status="OK"
	else
		raid_status=$raid_status_orig
	fi

	if [ $memory_status_count -eq 6 ]
	then
		memory_status="OK"
	else
		memory_status=$memory_status_orig
	fi

	if [ $fan_status_count -eq 6 ]
	then
		fan_status="OK"
	else
		fan_status=$fan_status_orig
	fi

	if [ $battery_status_count -eq 6 ]
	then
		battery_status="OK"
	else
		battery_status=$battery_status_orig
	fi

	if [ $temp_status_count -eq 6 ]
	then
		temp_status="OK"
	else
		temp_status=$temp_status_orig
	fi

	if [ $processor_status_count -eq 6 ]
	then
		processor_status="OK"
	else
		processor_status=$processor_status_orig
	fi


		
	echo "$ship | $stopped_service | $db_replication_flag | $media_storage_issue | $app_storage_issue | $app01_load | $app02_load | $media01_load | $media02_load | $read_only | $storage_failover | $timezone | $content_usage_issue | $Itinerary_present" >> $CONTENT
	echo "$ship | $raid_status | $memory_status | $fan_status | $battery_status | $temp_status | $processor_status" >> $CONTENT2
done


#echo "Please find attached the individual reports." >> $CONTENT

sed -i 's/kp.ocean/Crown/; s/ex.ocean/Enchanted/; s/di.ocean/Diamond/; s/cbvod.cruises/Caribbean/; s/ep.ocean/Emerald/; s/gpvod2.cruises/Regal/; s/iptv.kodmdomain/KODM/; s/iptv.encdomain/Encore/; s/iptv.eudmdomain/EUDM/; s/mjvod.cruises/Majestic/; s/nadmiptv.com/NADM/; s/iptv.nsdmdomain/NSDM/; s/iptv.odydomain/Odyssey/; s/rp.ocean/Royal/; s/ru.ocean/Ruby/; s/savod.cruises/Sapphire/; s/spvod.cruises/Sun/; s/iptv.ovadomain/Ovation/; s/britanniavod.carnivaluk/Britannia/; s/ap.ocean/Grand/; s/iptv.nodmdomain/NODM/; s/yp.ocean/Sky/; s/iptv.vodmdomain/VODM/; s/iptv.osdmdomain/OSDM/; s/iptv.wedmdomain/WEDM/; s/co.ocean/Coral/;  s/iptv.zudmdomain/ZUDM/' $CONTENT
sed -i 's/kp.ocean/Crown/; s/ex.ocean/Enchanted/; s/di.ocean/Diamond/; s/cbvod.cruises/Caribbean/; s/ep.ocean/Emerald/; s/gpvod2.cruises/Regal/; s/iptv.kodmdomain/KODM/; s/iptv.encdomain/Encore/; s/iptv.eudmdomain/EUDM/; s/mjvod.cruises/Majestic/; s/nadmiptv.com/NADM/; s/iptv.nsdmdomain/NSDM/; s/iptv.odydomain/Odyssey/; s/rp.ocean/Royal/; s/ru.ocean/Ruby/; s/savod.cruises/Sapphire/; s/spvod.cruises/Sun/; s/iptv.ovadomain/Ovation/; s/britanniavod.carnivaluk/Britannia/; s/ap.ocean/Grand/; s/iptv.nodmdomain/NODM/; s/yp.ocean/Sky/; s/iptv.vodmdomain/VODM/; s/iptv.osdmdomain/OSDM/; s/iptv.wedmdomain/WEDM/; s/co.ocean/Coral/;  s/iptv.zudmdomain/ZUDM/' $CONTENT2

rm -f $TEMP $temp2

printf "<p>\n</p>\n<!DOCTYPE html>\n<html>\n<head>\n<style>\ntable,th,td\n{\nborder:3px solid black ; padding: 15px; \nborder-collapse:collapse;\n}\n</style>\n</head>\n<Body>\n<p>Consolidated server health report :</p>\n<br>\n<br>\n<table>" > $email_body

IFS=$'\n'
for table_row in `cat $CONTENT`
do
	echo "<tr>" >> $email_body
	IFS=$'|'
	for value in $table_row
	do
		value=`echo $value | xargs`
		if [[ "$value" == "OK" ]] || [[ "$value" == *"GMT"* ]] || [[ $value =~ ^[0-9]*(\.[0-9]+)?$ ]] || [[ "$value" == "Ship_name" ]] || [[ "$value" == "Stopped_service" ]] || [[ "$value" == "DB_replication_broken" ]] || [[ "$value" == "Media_storage_issue" ]] || [[ "$value" == "App_storage_issue" ]] || [[ "$value" == "Hard_disk_issue" ]] || [[ "$value" == "HDD_predictive_failure" ]] || [[ "$value" == "app01_load" ]] || [[ "$value" == "app02_load" ]] || [[ "$value" == "media01_load" ]] || [[ "$value" == "media02_load" ]] || [[ "$value" == "nfs_read_only" ]] || [[ "$value" == "Storage_failover" ]] || [[ "$value" == "Timezone" ]] || [[ "$value" == "Content_usage_issue" ]] || [[ "$value" == "Itinerary_present" ]] || [[ "$value" == "Britannia" ]] || [[ "$value" == "Caribbean" ]] || [[ "$value" == "Coral" ]] || [[ "$value" == "Crown" ]] || [[ "$value" == "Diamond" ]] || [[ "$value" == "Emerald" ]] || [[ "$value" == "Enchanted" ]] || [[ "$value" == "Encore" ]] || [[ "$value" == "EUDM" ]] || [[ "$value" == "Grand" ]] || [[ "$value" == "OSDM" ]] || [[ "$value" == "KODM" ]] || [[ "$value" == "Majestic" ]] || [[ "$value" == *"NADM"* ]] || [[ "$value" == "NSDM" ]] || [[ "$value" == "NODM" ]] || [[ "$value" == "Odyssey" ]] || [[ "$value" == "Ovation" ]] || [[ "$value" == "Regal" ]] || [[ "$value" == "Ruby" ]] || [[ "$value" == "Sky" ]] || [[ "$value" == "Sun" ]] || [[ "$value" == "VODM" ]] || [[ "$value" == "WEDM" ]] || [[ "$value" == "Sapphire" ]] || [[ "$value" == "ZUDM" ]] || [[ "$value" == "Royal" ]]
		then
			echo "<td>" $value"</td>" >> $email_body
		elif [[ "$value" == *":"* ]] || [[ "$value" == *"errors"* ]]
		then
			echo "<td bgcolor='#FFA500'>" $value"</td>" >> $email_body
		else
			echo "<td bgcolor='#FF0000'>" $value"</td>" >> $email_body
		fi
	done
	echo "</tr>" >> $email_body
done 

printf "</table>\n<br>\n<br>\n<p>Consolidated hardware components health report :</p>\n<br>\n<br>\n<table>" >> $email_body

IFS=$'\n'
for table2_row in `cat $CONTENT2`
do
	echo "<tr>" >> $email_body
	IFS=$'|'
	for value in $table2_row
	do
		value=`echo $value | xargs`
		if [[ "$value" == "OK" ]] || [[ "$value" == "Ship_name" ]] || [[ "$value" == "RAID_Status" ]] || [[ "$value" == "Memory_Status" ]] || [[ "$value" == "Fan_Status" ]] || [[ "$value" == "Battery_Status" ]] || [[ "$value" == "Temp_Status" ]] || [[ "$value" == "Processor_Status" ]] || [[ "$value" == "Britannia" ]] || [[ "$value" == "Caribbean" ]] || [[ "$value" == "Coral" ]] || [[ "$value" == "Crown" ]] || [[ "$value" == "Diamond" ]] || [[ "$value" == "Emerald" ]] || [[ "$value" == "Enchanted" ]] || [[ "$value" == "Encore" ]] || [[ "$value" == "EUDM" ]] || [[ "$value" == "Grand" ]] || [[ "$value" == "OSDM" ]] || [[ "$value" == "KODM" ]] || [[ "$value" == "Majestic" ]] || [[ "$value" == *"NADM"* ]] || [[ "$value" == "NSDM" ]] || [[ "$value" == "NODM" ]] || [[ "$value" == "Odyssey" ]] || [[ "$value" == "Ovation" ]] || [[ "$value" == "Regal" ]] || [[ "$value" == "Ruby" ]] || [[ "$value" == "Sky" ]] || [[ "$value" == "Sun" ]] || [[ "$value" == "VODM" ]] || [[ "$value" == "WEDM" ]] || [[ "$value" == "Sapphire" ]] || [[ "$value" == "ZUDM" ]] || [[ "$value" == "Royal" ]]
		then
			echo "<td>" $value"</td>" >> $email_body
		elif [[ "$value" == "Not available" ]]
		then
			echo "<td bgcolor='#FFA500'>" $value"</td>" >> $email_body
		else
			echo "<td bgcolor='#FF0000'>" $value"</td>" >> $email_body
		fi
	done
	echo "</tr>" >> $email_body
done

printf "</table>\n</Body>\n</html>" >> $email_body