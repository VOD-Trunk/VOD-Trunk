#!/bin/bash

ts=`date +'%s'`
logfile='/root/Releases/tmp/exm-deployment.log'
action=$1
new_release=$2
component_choice=$3
abort_on_fail=$4
server=$5
transfer_flag=$6

declare -A statusArray

if [ "$component_choice" == "All" ]
then
	partial_flag=2
else
	partial_flag=1
	IFS=',' read -r -a choice_list <<< "$component_choice"
	for i in "${!choice_list[@]}"
	do
		choice_list[$i]=`echo ${choice_list[$i]} | sed "s/_/ /g"`
		if [ "${choice_list[$i]}" == "EXM V2" ]
		then
			choice_list[$i]="v2"
		elif [ "${choice_list[$i]}" == "LeftNav" ]
		then
			choice_list[$i]="exm-client-leftnav2"
		elif [ "${choice_list[$i]}" == "Admin Tool" ]
		then
			choice_list[$i]="exm-admin-tool"
		elif [ "${choice_list[$i]}" == "Cruise Client" ]
		then
			choice_list[$i]="exm-client-cruise"
		elif [ "${choice_list[$i]}" == "EXM Lite Client" ]
		then
			choice_list[$i]="exm-client-lite"
		elif [ "${choice_list[$i]}" == "Startup Client" ]
		then
			choice_list[$i]="exm-client-startup"
		elif [ "${choice_list[$i]}" == "Precor Client" ]
		then
			choice_list[$i]="exm-precor-client"
		elif [ "${choice_list[$i]}" == "NACOS Listener" ]
		then
			choice_list[$i]="nacos"
		elif [ "${choice_list[$i]}" == "Mute Daemon" ]
		then
			choice_list[$i]="mutedaemon"
		elif [ "${choice_list[$i]}" == "LeftNav Signage" ]
		then
			choice_list[$i]="exm-client-leftnav2-signage"
		elif [ "${choice_list[$i]}" == "Exm-v2-plugin-location" ]
		then
			choice_list[$i]="location"
		elif [ "${choice_list[$i]}" == "EXM Diagnostic Application" ]
		then
			choice_list[$i]="exm-diagnostic-app"
		elif [ "${choice_list[$i]}" == "EXM Diagnostic plugin" ]
		then
			choice_list[$i]="diagnostics"
		elif [ "${choice_list[$i]}" == "EXM Notification plugin" ]
		then
			choice_list[$i]="notification-service"
		elif [ "${choice_list[$i]}" == "Mute Status Service" ]
		then
			choice_list[$i]="mute"
		elif [ "${choice_list[$i]}" == "exm-db-upgrade" ]
		then
			choice_list[$i]="exm-db-upgrade"
		elif [ "${choice_list[$i]}" == "exm-v2-plugin-excursions" ]
		then
			choice_list[$i]="exm-v2-plugin-excursions"
		fi

	done
fi

err() {
    >&2 echo -e "$@"
}

log(){
    echo "$@" >&1 2>&1
    echo "$@" >> ${logfile}
}

get_current_build() {

	### This function returns the build that is present for a component before new deployment. It returns the path where symlink/component is present. These two variables are used throughout the code.

	component=$1

	if [ "$component" == "exm-admin-tool" ]
	then
			if [ ! -d /apps/exm-admin-tool/releases ]
			then
				log "Creating directory /apps/exm-admin-tool/releases as it was not present."
				mkdir -p /apps/exm-admin-tool/releases
			fi
			current_build=`ls -la /apps/exm-admin-tool/ | grep current | cut -d '>' -f 2 | sed 's/ //g'`
			releases_path='/apps/exm-admin-tool'
	fi

	if [ "$component" == "exm-client-cruise" ]
	then
			if [ ! -d /apps/exm-client/releases ]
			then
				log "Creating directory /apps/exm-client/releases as it was not present."
				mkdir -p /apps/exm-client/releases
			fi
			current_build=`ls -la /apps/exm-client/ | grep current | cut -d '>' -f 2 | sed 's/ //g'`
			releases_path='/apps/exm-client'
	fi

	if [ "$component" == "exm-precor-client" ]
	then
			if [ ! -d /apps/clientmap/exm-precor-client/releases ]
			then
				log "Creating directory /apps/clientmap/exm-precor-client/releases as it was not present."
				mkdir -p /apps/clientmap/exm-precor-client/releases
			fi
			current_build=`ls -la /apps/clientmap/exm-precor-client/ | grep current | cut -d '>' -f 2 | sed 's/ //g'`
			releases_path='/apps/clientmap/exm-precor-client'
	fi

	if [ "$component" == "exm-client-startup" ]
	then
			if [ ! -d /apps/clientmap/exm-client-startup/releases ]
			then
				log "Creating directory /apps/clientmap/exm-client-startup/releases as it was not present."
				mkdir -p /apps/clientmap/exm-client-startup/releases
			fi
			current_build=`ls -la /apps/clientmap/exm-client-startup/ | grep current | cut -d '>' -f 2 | sed 's/ //g'`
			releases_path='/apps/clientmap/exm-client-startup'
	fi

	if [ "$component" == "exm-client-leftnav2" ]
	then
			if [ ! -d /apps/clientmap/exm-client-leftnav2/releases ]
			then
				log "Creating directory /apps/clientmap/exm-client-leftnav2/releases as it was not present."
				mkdir -p /apps/clientmap/exm-client-leftnav2/releases
			fi
			current_build=`ls -la /apps/clientmap/exm-client-leftnav2/ | grep current | cut -d '>' -f 2 | sed 's/ //g'`
			releases_path='/apps/clientmap/exm-client-leftnav2'
	fi

	if [ "$component" == "exm-client-leftnav2-signage" ]
	then
			if [ ! -d /apps/clientmap/exm-client-leftnav2-signage/releases ]
			then
				log "Creating directory /apps/clientmap/exm-client-leftnav2-signage/releases as it was not present."
				mkdir -p /apps/clientmap/exm-client-leftnav2-signage/releases
			fi
			current_build=`ls -la /apps/clientmap/exm-client-leftnav2-signage/ | grep current | cut -d '>' -f 2 | sed 's/ //g'`
			releases_path='/apps/clientmap/exm-client-leftnav2-signage'
	fi

	if [ "$component" == "exm-diagnostic-app" ]
	then
			if [ ! -d /apps/exm-diagnostic-app/releases ]
			then
				log "Creating directory /apps/exm-diagnostic-app/releases as it was not present."
				mkdir -p /apps/exm-diagnostic-app/releases
			fi
			current_build=`ls -la /apps/exm-diagnostic-app/ | grep current | cut -d '>' -f 2 | sed 's/ //g'`
			releases_path='/apps/exm-diagnostic-app'
	fi

	if  [ "$component" == "exm-client-lite" ]
	then
			if [ ! -d /apps/clientmap/exm-client-lite/releases ]
			then
				log "Creating directory /apps/clientmap/exm-client-lite/releases as it was not present."
				mkdir -p /apps/clientmap/exm-client-lite/releases
			fi
			current_build=`ls -la /apps/clientmap/exm-client-lite/ | grep current | cut -d '>' -f 2 | sed 's/ //g'`
			releases_path='/apps/clientmap/exm-client-lite'
	fi

	if  [ "$component" == "mute" ]
	then
			if [ ! -d /apps/mute/releases ]
			then
				log "Creating directory /apps/mute/releases as it was not present."
				mkdir -p /apps/mute/releases
			fi
			current_build=`ls -la /apps/mute/current | grep "server.js" | cut -d '>' -f 2 | cut -d '/' -f 1-5| sed 's/ //g'`
			releases_path='/apps/mute'
	fi

	if [ "$component" == "v2" ]
	then
			current_build='/var/lib/tomcat7/hosts/prod.uiexm.com/webapps/v2.war'
			releases_path='/var/lib/tomcat7/hosts/prod.uiexm.com/webapps'
	fi

	if  [ "$component" == "location" ]
	then
			current_build='/var/lib/tomcat7/hosts/prod.uiexm.com/webapps/location.war'
			releases_path='/var/lib/tomcat7/hosts/prod.uiexm.com/webapps'
	fi

	if [ "$component" == "diagnostics" ]
	then
			current_build='/var/lib/tomcat7/hosts/prod.uiexm.com/webapps/diagnostics.war'
			releases_path='/var/lib/tomcat7/hosts/prod.uiexm.com/webapps'
	fi

	if [ "$component" == "notification-service" ]
	then
			current_build='/var/lib/tomcat7/hosts/prod.uiexm.com/webapps/notification-service.war'
			releases_path='/var/lib/tomcat7/hosts/prod.uiexm.com/webapps'
	fi

	if [ "$component" == "exm-v2-plugin-excursions" ]
	then
			current_build='/var/lib/tomcat7/hosts/prod.uiexm.com/webapps/exm-v2-plugin-excursions.war'
			releases_path='/var/lib/tomcat7/hosts/prod.uiexm.com/webapps'
	fi

	if [ "$component" == "nacos" ]
	then
			if [ ! -d /usr/local/nacos/releases ]
			then
				log "Creating directory /usr/local/nacos/releases as it was not present."
				mkdir -p /usr/local/nacos/releases
			fi
			current_build=`ls -la /usr/local/nacos/ | grep "nacos.daemon.jar " | cut -d '>' -f 2 | sed 's/ //g' | cut -d '/' -f 6`
			releases_path='/usr/local/nacos'
	fi

	if [ "$component" == "mutedaemon" ]
	then
			if [ ! -d /usr/local/mutedaemon/releases ]
			then
				log "Creating directory /usr/local/mutedaemon/releases as it was not present."
				mkdir -p /usr/local/mutedaemon/releases
			fi
			current_build=`ls -la /usr/local/mutedaemon/ | grep "mutedaemon.jar " | cut -d '>' -f 2 | sed 's/ //g' | cut -d '/' -f 6`
			releases_path='/usr/local/mutedaemon'
	fi	

	echo "$current_build:$releases_path"
}

restart_services() {

	### This function takes the component name and start/stop has input and accordingly starts or stops the relevant service if required.

	component=$1
	start_stop=$2
	
	if  ([ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component" == "diagnostics" ] || [ "$component" == "notification-service" ] || [ "$component" == "exm-v2-plugin-excursions" ]) && [ "$start_stop" == "stop" ]
	then
		log "Stopping tomcat7 service for $component..."
		pkill -9 -u tomcat java #Stop_Tomcat_Service
		sleep 5
		log "================================================================================================================"
	fi

	if  ([ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component" == "diagnostics" ] || [ "$component" == "notification-service" ] || [ "$component" == "exm-v2-plugin-excursions" ]) && [ "$start_stop" == "start" ]
	then
		log "Starting tomcat7 service for $component..."
		service tomcat7 start #Start_Tomcat_Service
		if [ "$component" == "notification-service" ]
		then
			sleep 45
		else
			sleep 35
		fi
		tomcat_status=`service tomcat7 status | grep running | wc -l`
		
		if [ $tomcat_status == 1 ]
		then
			echo "tomcat7 started successfully."
		else
			echo "tomcat7 failed to start"
		fi	

		log "================================================================================================================"	
	fi
	
	if ([ "$component" == "nacos" ] || [ "$component" == "mutedaemon" ]) && [ "$start_stop" == "stop" ]
	then
		log "Checking if $component service is running on this server..."

		isServiceRunning=`monit summary | grep $component | tr -s ' ' |  cut -d ' ' -f 3 | grep Running | wc -l`

		if [ $isServiceRunning == 1 ]
		then
			log "Stopping $component service..."
			monit stop $component
			sleep 5
		else
			log "$component service doesn't need to be restarted on this server."
		fi
		log "================================================================================================================"
	fi

	if ([ "$component" == "nacos" ] || [ "$component" == "mutedaemon" ]) && [ "$start_stop" == "start" ]
	then
		log "Checking if the $component Service is stopped..."

		isServiceRunning=`monit summary | grep $component | tr -s ' ' |  cut -d ' ' -f 3 | grep Running | wc -l`

		if [ $isServiceRunning -eq 0 ]
		then
			log "Starting $component service..."
			monit start $component
			sleep 7
			
			service_status=`ps -ef | grep "$component" | wc -l`
			
			if [ $service_status -gt 1 ]
			then
				log "$component started successfully."
			else
				log "$component failed to start."
			fi
		else
			log "$component service doesn't need to be restarted on this server."
		fi

		log "================================================================================================================"
	fi
}

deploy_new_build() {

	### This function contains all the deployment steps for each type of component. All tar files are deployed in one way and similarly all jar files in one way and all war files in one way.

	new_release=$1
	component=$2
	releases_path=$3
	current_build=$4

	#####Deployment of all clients have the same steps. So using the same code for both in below code block.

	if [ "$component" == "exm-db-upgrade" ]
	then
		log "Starting the DB upgrade"
        
        log "Taking DB backup"

		if [ ! -d /root/Releases/$new_release/dbbackup ]
		then
			mkdir -p /root/Releases/$new_release/dbbackup
		else
			for i in `ls /root/Releases/$new_release/dbbackup`
			do
				rm -rf /root/Releases/$new_release/dbbackup/$i
			done
		fi

		mysqldump -uexm -puie123 -h dbvip -R exm | sed 's/DEFINER=`exm`/DEFINER=`exm`/g' > /root/Releases/$new_release/dbbackup/exm-backup.sql

		if [ $? -eq 0 ]
		then
		    gzip /root/Releases/$new_release/dbbackup/exm-backup.sql
		    
		    size_prev_backup=$(find "/home/netsvcs/sqlback/`ls -Art /home/netsvcs/sqlback | tail -n 1`" -printf "%s")
			size_curr_backup=`find "/root/Releases/$new_release/dbbackup/exm-backup.sql.gz" -printf "%s"`

			#if (( $size_curr_backup >= $size_prev_backup ))
			#then
			#	log "DB backed up successfully. Backup can be found at /root/Releases/$new_release/dbbackup/exm-backup.sql"
			#else
			#	log "ERROR : DB backup failed!! Backup file is incomplete. Aborting build..."
			 #   exit 1
			#fi
		else
		    log "ERROR : DB backup failed!! Aborting build..."
		    exit 1
		fi

		file_name=`ls /root/Releases/$new_release/$component/*.tar.gz | cut -d "/" -f 6`

		ls -l /root/Releases/$new_release/exm-db-upgrade/$file_name

		if [ $? = 0 ]
		then
			log "DB Upgrade ZIP is present"
		else
			log "ERROR : DB Upgrade ZIP is missing"
			exit 1
		fi

		log "Unzipping $file_name ..."

		tar -xzf /root/Releases/$new_release/$component/$file_name -C /root/Releases/$new_release/$component/

		new_build=`cd /root/Releases/$new_release/$component/ && find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'`

		chmod +x /root/Releases/$new_release/exm-db-upgrade/$new_build/db-script.sh
		
		cd /root/Releases/$new_release/exm-db-upgrade/$new_build
		
		printf 'uie123\n' | ./db-script.sh --upgrade &>/dev/null
		
		count=`cat /root/update/$new_release/db-upgrade-dir/$new_build/*-dboper-*.log | grep -w "Liquibase Update Successful" | wc -l`
		 
		if [ $count -eq 2 ]
		then
			log "Liquibase Update Successful"
		else
			log "ERROR : DB upgrade was unsuccessful. Please check logs at /root/update/$new_release/exm-db-upgrade/$new_build"
			exit 1
		fi

		cat /root/update/$new_release/db-upgrade-dir/$new_build/*-dboper-*.log | grep -w "finished upgrade"

		if [ $? -eq 0 ]
		then
			log "Upgrade Finished."
		else
			log "ERROR : DB upgrade was unsuccessful. Please check logs at /root/update/$new_release/exm-db-upgrade/$new_build"
			exit 1
		fi

		cd /root
	fi


	if  [ "$component" == "exm-admin-tool" ] || [ "$component" == "exm-client-cruise" ] || [ "$component" == "exm-client-startup" ] || [ "$component" == "exm-client-leftnav2" ] || [ "$component" == "exm-client-leftnav2-signage" ] || [ "$component" == "exm-client-lite" ] || [ "$component" == "exm-diagnostic-app" ]
	then

		log "Starting the deployment of $component"
		log "Taking backup of the current build."

		if [ ! -d $releases_path/Backup ]
		then
			log "Creating directory $releases_path/Backup as it was not present."
			mkdir -p $releases_path/Backup
		elif [ -d $releases_path/Backup ]
		then
			for i in `ls $releases_path/Backup`
			do
				rm -rf $releases_path/Backup/$i
			done
		fi
		cp -r $current_build $releases_path/Backup
		file_name=`ls /root/Releases/$new_release/$component/*.tar.gz | cut -d "/" -f 6`

		log "Extracting tarball $file_name ..."

		tar -xf /root/Releases/$new_release/$component/$file_name -C /root/Releases/$new_release/$component/
		new_build=`cd /root/Releases/$new_release/$component/ && find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'`

		log "Copying $new_build to $releases_path/releases"

		cp -r /root/Releases/$new_release/$component/$new_build $releases_path/releases/
		link_present=`ls $releases_path | grep current | wc -l`
		if [ $link_present == 1 ]
		then 
			log "Unlinking current symlink..."
			log "current symlink is :"
			log "`ls -l $releases_path | grep current`"

			unlink $releases_path/current
		fi

		log "Creating new symlink current ..."

		ln -s $releases_path/releases/$new_build $releases_path/current

		log "New symlink is:"
		log "`ls -l $releases_path | grep current`"

		if [ "$component" == "exm-client-cruise" ]
		then
			log "Setting permission on new release folder for cruise client..."
			chmod -R 777 $releases_path/releases/$new_build
			chown -R apache:apache $releases_path/releases/$new_build

		fi
	fi

	#####Deployment of all .war files have the same steps. So using the same code for all in below code block.

	if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "excursion" ] || [ "$component" == "diagnostics" ] || [ "$component" == "notification-service" ] || [ "$component" == "exm-v2-plugin-excursions" ]
	then
		log "Starting deployment of $component"
		log "Copying $releases_path/$component.war and $releases_path/$component to /root/War_Backup/ for backup."
		log "Taking backup of the current build."

		if [ ! -d /root/War_Backup/$component ]
		then
			log "Creating directory /root/War_Backup/$component as it was not present."
			mkdir -p /root/War_Backup/$component
		elif [ -d /root/War_Backup/$component ]
		then
			for i in `ls /root/War_Backup/$component`
			do
				rm -rf /root/War_Backup/$component/$i
			done
		fi
		cp -r $releases_path/$component $releases_path/$component.war /root/War_Backup/$component
		#cp $releases_path/$component.war /tmp/
		rm -rf $releases_path/$component $releases_path/$component.war

		log "Copying new war file to $releases_path/$component.war"

		cp /root/Releases/$new_release/$component/* $releases_path/$component.war
	fi

	#####Deployment of nacos and mutedaemon have the same steps. So using the same code for both in below code block.

	if  [ "$component"  == "nacos" ] || [ "$component"  == "mutedaemon" ]
	then
		log "Starting deployment of $component"
				
		if [ ! -d $releases_path/Backup ]
		then
			log "Creating directory $releases_path/Backup as it was not present."
			mkdir -p $releases_path/Backup
		elif [ -d $releases_path/Backup ]
		then
			for i in `ls $releases_path/Backup`
			do
				rm -rf $releases_path/Backup/$i
			done
		fi

		if [ ! -d $releases_path/releases/$new_release ]
		then
			log "Creating directory $releases_path/releases/$new_release as it was not present."
			mkdir -p $releases_path/releases/$new_release
		elif [ -d $releases_path/releases/$new_release ]
		then
			log "Taking backup of the current build."	
			cp -r $releases_path/releases/$current_build $releases_path/Backup/

			for i in `ls $releases_path/releases/$new_release`
			do
				rm -rf $releases_path/releases/$new_release/$i
			done
		fi		

		new_build=`ls /root/Releases/$new_release/$component/*.jar | cut -d "/" -f 6`

		log "Copying $new_build to $releases_path/$new_release"

		if [ $component  == "nacos" ]
		then
			jar_symlink="nacos.daemon.jar"
		elif [ $component  == "mutedaemon" ]
		then
			jar_symlink="mutedaemon.jar"
		fi


		cp /root/Releases/$new_release/$component/$new_build $releases_path/releases/$new_release

		log "Unzipping the $component jar file"

		unzip -qq $releases_path/releases/$new_release/$new_build -d $releases_path/releases/$new_release

		log "Current $jar_symlink symlink is :"
		log "`ls -l $releases_path | grep "$jar_symlink "`"
		log "Unlinking $jar_symlink symlink..."
		unlink $releases_path/$jar_symlink
		log "Creating new symlink $jar_symlink ..."

		ln -s $releases_path/releases/$new_release/$new_build $releases_path/$jar_symlink

		log "New $jar_symlink symlink is :"
		log "`ls -l $releases_path | grep "$jar_symlink"`"
		log "Copying properties.uie file to $releases_path/releases/$new_release"
		if [ "$component" == "nacos" ]
		then
			cp $releases_path/Backup/$new_release/properties.uie $releases_path/releases/$new_release
		else
			cp $releases_path/Backup/$new_release/*.properties $releases_path/releases/$new_release
		fi

		log "Current properties.uie symlink is :"
		log "`ls -l $releases_path | grep "properties.uie"`"

		unlink $releases_path/properties.uie

		log "Creating new symlink properties.uie ..."

		if [ "$component" == "nacos" ]
		then
			ln -s $releases_path/releases/$new_release/properties.uie $releases_path/properties.uie
		else
			ln -s $releases_path/releases/$new_release/*.properties $releases_path/properties.uie
		fi

		log "New properties.uie symlink is :"
		log "`ls -l $releases_path | grep "properties.uie"`"
		
	fi

	### Steps for node-mute and exm-precor-client service is different from all others. It is a zip file.
	if [ "$component" == "exm-precor-client" ]
	then
		log "Starting the deployment of $component"
		log "Taking backup of the current build."

		if [ ! -d $releases_path/Backup ]
		then
			log "Creating directory $releases_path/Backup as it was not present."
			mkdir -p $releases_path/Backup
		elif [ -d $releases_path/Backup ]
		then
			for i in `ls $releases_path/Backup`
			do
				rm -rf $releases_path/Backup/$i
			done
		fi
		cp -r $current_build $releases_path/Backup

		if [ ! -d $releases_path/releases ]
		then
			log "Creating directory $releases_path/releases as it was not present."
			mkdir -p $releases_path/releases
		fi

		file_name=`ls /root/Releases/$new_release/$component/*.zip | cut -d "/" -f 6`

		log "Unzipping $file_name ..."

		unzip -qq /root/Releases/$new_release/$component/$file_name -d /root/Releases/$new_release/$component/

		new_build=`cd /root/Releases/$new_release/$component/ && find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'`

		log "Copying $new_build to $releases_path/releases/"

		cp -r /root/Releases/$new_release/$component/$new_build $releases_path/releases/

		link_present=`ls $releases_path | grep current | wc -l`
		if [ $link_present == 1 ]
		then 
			log "Unlinking current symlink..."
			log "current symlink is :"
			log "`ls -l $releases_path | grep current`"

			unlink $releases_path/current
		fi

		log "Creating new symlink current ..."
		ln -s $releases_path/releases/$new_build $releases_path/current

		log "New symlink is:"
		log "`ls -l $releases_path | grep current`"
	fi

	if [ "$component" == "mute" ]
	then
		log "Starting the deployment of $component"
		log "Taking backup of the current build."

		if [ ! -d $releases_path/Backup ]
		then
			log "Creating directory $releases_path/Backup as it was not present."
			mkdir -p $releases_path/Backup
		elif [ -d $releases_path/Backup ]
		then
			for i in `ls $releases_path/Backup`
			do
				rm -rf $releases_path/Backup/$i
			done
		fi
		cp -r $current_build $releases_path/Backup

		if [ ! -d $releases_path/releases ]
		then
			log "Creating directory $releases_path/releases as it was not present."
			mkdir -p $releases_path/releases
		fi

		file_name=`ls /root/Releases/$new_release/$component/*.zip | cut -d "/" -f 6`

		log "Unzipping $file_name ..."

		unzip -qq /root/Releases/$new_release/$component/$file_name -d /root/Releases/$new_release/$component/

		new_build=`cd /root/Releases/$new_release/$component/ && find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'`

		log "Copying $new_build to $releases_path/releases/"

		cp -r /root/Releases/$new_release/$component/$new_build $releases_path/releases/
		
		link_present=`ls $releases_path/current | grep "server.js" | wc -l`

		if [ $link_present == 1 ]
		then 
			log "Unlinking current symlink..."
			log "current symlink is :"
			log "`ls -l $releases_path/current | grep 'server.js'`"

			unlink $releases_path/current/server.js
		fi

		log "Creating new symlink current ..."

		ln -s $releases_path/releases/$new_build/*.js $releases_path/current/server.js

		log "New symlink is:"
		log "`ls -l $releases_path/current | grep 'server.js'`"
		
	fi

	if [ "$component" == "UIEWowzaLib" ] && ([ "$server" == "media01" ] || [ "$server" == "media02" ])
	then
		log "Changing permissions on required files on $Mserver..."
 		chmod 777 /home/wowza/media /home/wowza/media/v2/wowza /home/wowza/media/v2/wowza/running.json
		
		log "Stopping WowzaStreamingEngine service..."
		monit stop WowzaStreamingEngine
		sleep 30
		
		log "Taking backup of existing UIEWowzaLib.jar to /root/Wowza_backup and replacing with new jar..."
		
		if [ ! -d /root/Wowza_backup ]
		then 
			mkdir -p /root/Wowza_backup
		fi
		
		mv /usr/local/WowzaStreamingEngine/lib/UIEWowzaLib.jar /root/Wowza_backup
		cp /root/Releases/$new_release/UIEWowzaLib/*.jar /usr/local/WowzaStreamingEngine/lib/UIEWowzaLib.jar
		
		log "Starting WowzaStreamingEngine service..."
		monit start WowzaStreamingEngine
		sleep 30
		
	elif [ "$component" == "UIEWowzaLib" ] && ([ "$server" == "app01" ] || [ "$server" == "app02" ])
	then
		log "UIEWowzaLib is not supposed to be deployed on app servers."
	fi


}

rollback() {

	### Rollback function makes use of the Backup folder which contains the build that was there prior to this deployment.

	current_build=$1
	component=$2
	releases_path=$3

	if  [ "$component" == "exm-admin-tool" ] || [ "$component" == "exm-client-cruise" ] || [ "$component" == "exm-client-startup" ] || [ "$component" == "exm-client-leftnav2" ] || [ "$component" == "exm-client-leftnav2-signage" ] || [ "$component" == "exm-client-lite" ] || [ "$component" == "exm-diagnostic-app" ] || [ "$component" == "exm-precor-client" ]
	then

		log "Starting rollback of $component"
		rollback_build=`cd $releases_path/Backup/ && find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'`

		log "Unlinking the current link..."
		unlink $releases_path/current

		log "Creating a new link using the Backup build..."
		ln -s $releases_path/releases/$rollback_build $releases_path/current

		log "New symlink is:"
		log "`ls -l $releases_path | grep current`"
		
	fi



	if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "excursion" ] || [ "$component" == "diagnostics" ] || [ "$component" == "notification-service" ] || [ "$component" == "exm-v2-plugin-excursions" ]
	then

		log "Starting rollback of $component"
		log "Removing current build"

		rm -rf $releases_path/$component*

		log "Copying rollbcak build to $releases_path"
		cp /root/War_Backup/$component/$component.war $releases_path/$component.war
	fi



	if  [ "$component"  == "nacos" ] || [ "$component"  == "mutedaemon" ]
	then

		log "Starting rollback of $component"

		if [ $component  == "nacos" ]
		then
			jar_symlink="nacos.daemon.jar"
		elif [ $component  == "mutedaemon" ]
		then
			jar_symlink="mutedaemon.jar"
		fi


		rollback_build=`cd /$releases_path/Backup/ && find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'`

		log "Unlinking the current $jar_symlink symlink..."

		unlink $releases_path/$jar_symlink

		log "Creating a new link using the Backup build..."

		ln -s $releases_path/releases/$rollback_build/*.jar $releases_path/nacos.daemon.jar

		log "New $jar_symlink symlink is :"
		log "`ls -l $releases_path | grep "$jar_symlink"`"
		log "Unlinking the current properties.uie symlink..."
		unlink $releases_path/properties.uie

		log "Creating a new link using the Backup build..."

		ln -s $releases_path/releases/$rollback_build/*.uie $releases_path/properties.uie

		log "New properties.uie symlink is :"
		log "`ls -l $releases_path | grep "properties.uie"`"
	fi

	if  [ "$component"  == "mute" ]
	then
		log "Starting rollback of $component"

		rollback_build=`cd /$releases_path/Backup/ && find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'`

		link_present=`ls $releases_path/current | grep "server.js" | wc -l`

		if [ $link_present == 1 ]
		then 
			log "Unlinking current symlink..."
			log "current symlink is :"
			log "`ls -l $releases_path/current | grep 'server.js'`"

			unlink $releases_path/current/server.js
		fi

		log "Creating new symlink current ..."
		ln -s $releases_path/releases/$rollback_build/*.js $releases_path/current/server.js

		log "New symlink is:"
		log "`ls -l $releases_path/current | grep 'server.js'`"
	fi

	if  [ "$component"  == "exm-db-upgrade" ]
	then
		log "Rollback logic not present for DB upgrade."
	fi
}

verify() {

	### This function compares the Build Number present in the component after deployment/rollback and also tests whether related service has been restarted or not. If both checks are satisfied it marks the activity successful.

	component=$1
	releases_path=$2
	current_build=$3
	abort_on_fail=$4
	activity=$5
	services_status=1

	if  [ "$component" == "exm-admin-tool" ] || [ "$component" == "exm-client-cruise" ] || [ "$component" == "exm-client-startup" ] || [ "$component" == "exm-client-leftnav2" ] || [ "$component" == "exm-client-leftnav2-signage" ] || [ "$component" == "exm-client-lite" ] || [ "$component" == "exm-diagnostic-app" ] || [ "$component" == "exm-precor-client" ]
	then
		timestamp_build=`cat $current_build/timestamp.txt | grep "Build Number" | cut -d ":" -f 2 | sed 's/ //g'`
		if [ "$activity" == "deploy" ]
		then
			release_build=`cat /root/Releases/tmp/component_build_mapping.txt | grep -w "$component " | cut -d ":" -f 2 | sed 's/ //g'`
		else
			rollback_build=`cd $releases_path/Backup/ && find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'`
			release_build=`cat $releases_path/Backup/$rollback_build/timestamp.txt | grep "Build Number" | cut -d ":" -f 2 | sed 's/ //g'`
		fi

	fi

	if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "excursion" ] || [ "$component" == "diagnostics" ] || [ "$component" == "notification-service" ] || [ "$component" == "exm-v2-plugin-excursions" ]
	then
		timestamp_build=`cat $releases_path/$component/timestamp.txt | grep "Build Number" | cut -d ":" -f 2 | sed 's/ //g'`
		if [ "$activity" == "deploy" ]
		then
			release_build=`cat /root/Releases/tmp/component_build_mapping.txt | grep -w "$component " | cut -d ":" -f 2 | sed 's/ //g'`
		else
			release_build=`cat cat /root/War_Backup/$component/$component/timestamp.txt | grep "Build Number" | cut -d ":" -f 2 | sed 's/ //g'`
		fi
	fi

	if [ "$component" == "mute" ]
	then
		timestamp_build=`cat $current_build/timestamp.txt | grep "Build Number" | cut -d ":" -f 2 | sed 's/ //g'`
		if [ "$activity" == "deploy" ]
		then
			release_build=`cat /root/Releases/tmp/component_build_mapping.txt | grep -w "$component " | cut -d ":" -f 2 | sed 's/ //g'`
		else
			rollback_build=`cd $releases_path/Backup/ && find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'`
			release_build=`cat $releases_path/Backup/$rollback_build/timestamp.txt | grep "Build Number" | cut -d ":" -f 2 | sed 's/ //g'`
		fi
	fi

	if [ "$component" == "nacos" ] || [ "$component"  == "mutedaemon" ]
	then
		timestamp_build=`cat $releases_path/releases/$new_release/timestamp.txt | grep "Build Number" | cut -d ":" -f 2 | sed 's/ //g'`
		if [ "$activity" == "deploy" ]
		then
			release_build=`cat /root/Releases/tmp/component_build_mapping.txt | grep -w "$component " | cut -d ":" -f 2 | sed 's/ //g'`
		else
			rollback_build=`cd $releases_path/Backup/ && find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'`
			release_build=`cat $releases_path/Backup/$rollback_build/timestamp.txt | grep "Build Number" | cut -d ":" -f 2 | sed 's/ //g'`
		fi
	fi

	if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "excursion" ] || [ "$component" == "diagnostics" ] || [ "$component" == "notification-service" ] || [ "$component" == "exm-v2-plugin-excursions" ]
	then
		PID_FILE_SIZE=`stat -c%s /var/run/tomcat7.pid`
		SIZE=0
		

		if (( PID_FILE_SIZE > SIZE ));
		then
			log "tomcat7 service has a PID."
		else
			services_status=2
			if [ $abort_on_fail == "Abort" ]
			then
				log "ERROR : Aborting the deployment as tomcat was not restarted properly. Please check tomcat7 service. Thanks."
				exit 1
			fi

		fi

		ps -elf | grep -v grep | grep -q tomcat7
		if [ $? -eq 0 ]
		then
			log "Tomcat Service Running"
			log
		else
			services_status=2
			if [ $abort_on_fail == "Abort" ]
			then
				log "ERROR : Aborting mission during $component deployment as tomcat was not restarted properly. Please check tomcat7 service. Thanks."
				exit 1
			fi
		fi
	fi

	if [ "$component" == "nacos" ] || [ "$component"  == "mutedaemon" ]
	then
		PID_FILE_SIZE=`stat -c%s /var/run/$component.pid`
		SIZE=0
		

		if (( PID_FILE_SIZE > SIZE ));
		then
			log "$component Service has a PID."
		else
			services_status=2
			if [ $abort_on_fail == "Abort" ]
			then
				log "ERROR : Aborting mission during $component deployment as $component service was not restarted properly. Please check $component service. Thanks."
				exit 1
			fi

		fi


		ps -elf | grep -v grep | grep -q $component
		if [ $? -eq 0 ]
		then
			log "$component service is running"
		else
			services_status=2
			if [ $abort_on_fail == "Abort" ]
			then
				log "ERROR : Aborting mission during $component deployment as $component service was not restarted properly. Please check $component service. Thanks."
				exit 1
			fi
		fi

	fi

	

	if [ "$timestamp_build" == "$release_build" ]
	then
		timestamp_status=1
	else
		timestamp_status=2
		if [ $abort_on_fail == "Abort" ]
		then
			log "ERROR : Aborting mission during $component deployment as the timestamp is not updated. Please check $releases_path . Thanks."
			exit 1
		fi
	fi

	if ([ "$server" == "app01" ] || [ "$server" == "app02" ]) && [ "$component" == "UIEWowzaLib" ]
	then
		:
	else
	
		if [ $timestamp_status -eq 1 ] && [ $services_status -eq 1 ]
		then
			statusArray[$component]="Successful( Deployed Build Number : $timestamp_build, Build Number on Confluence :  $release_build )"
			log "================================================================================================================"
			log "The deployment/rollback of $component was successful."
			log "================================================================================================================"
			#echo "Successful( Version : $timestamp_release )"
		else
			statusArray[$component]="Failed( Deployed Build Number : $timestamp_build, Build Number on Confluence :  $release_build )"
			log "================================================================================================================"
			log "The deployment/rollback of $component has failed."
			if [ $timestamp_status -eq 1 ]
			then
				log "There was a problem in restarting the service associated with $component. Please check and re-deploy/rollback $component."
			elif [ $services_status -eq 1 ]
			then
				log "The desired build of $component has not been deployed/rolled back. Please check the symlink at $releases_path."
			fi
			log "================================================================================================================"
			#echo "Failed( Version : $timestamp_release )"
		fi
	fi
	#echo $timestamp_status
}

deploy_master() {

	### This is the main function which calls all the other functions according to the script arguments like 1) Component to be deployed. 2) To abort mission on failure or proceed 3) To deploy or rollabck  etc etc...

	component=$1
	abort_on_fail=$2
	activity=$3

	if [ "$component" != "exm-db-upgrade" ]
	then
		releases_path=$(get_current_build $component | cut -d ":" -f 2)
		current_build=$(get_current_build $component | cut -d ":" -f 1)
	fi
    

	if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "nacos" ] || [ "$component"  == "excursion" ] || [  "$component" == "diagnostics" ] || [ "$component" == "notification-service" ] || [ "$component" == "exm-v2-plugin-excursions" ]
	then
		restart_services $component stop
	fi
	if [ "$activity" == "deploy" ]
	then
		deploy_new_build $new_release $component $releases_path $current_build
	else
		rollback $new_release $component $releases_path $current_build
	fi

	if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "nacos" ] || [ "$component"  == "excursion" ] || [  "$component" == "diagnostics" ] || [ "$component" == "notification-service" ] || [ "$component" == "exm-v2-plugin-excursions" ]
	then
		restart_services $component start
	fi

	if [ "$component" != "exm-db-upgrade" ]
	then
		current_build=$(get_current_build $component | cut -d ":" -f 1)
		verify $component $releases_path $current_build $abort_on_fail $activity
	fi
}

checkComponent() {

	component=$1

    DIR="/root/Releases/$new_release/$component"
    if [ -d /root/Releases/$new_release/$component ]
    then
        :
    else
        log "ERROR : $component has not been transferred. Please transfer it from artifactory and then deploy."
        exit 1
    fi
}

#main script
		log "================================`date`================================"

if [[ $# -eq 0 ]]; then
	err "Usage: ${0} {option}"
	err "\t--deploy|-d"
	err "\t--rollback|-r"
	err
			exit 1
fi

if [ "$server" == "app01" ] && [ "$action" == "-d" ]
then
	isDbUpgradeReqd=`grep "exm-db-upgrade" /root/Releases/tmp/component_build_mapping.txt | wc -l`

	if [ $isDbUpgradeReqd -eq 1 ]
	then
		component="exm-db-upgrade"
		log "Starting DB upgrade of release $new_release"
		confluence_md5sum=`grep "exm-db-upgrade" /root/Releases/tmp/component_build_mapping.txt | cut -d ':' -f 3 | awk '{$1=$1};1'`
	    comp_md5sum=`cd /root/Releases/$new_release/$component && find -type f -exec md5sum "{}" + | cut -d' ' -f1`

	    if [ "$confluence_md5sum" == "$comp_md5sum" ]
	    then
	      	log "md5sum is same on confluence and server. $component has been transferred to app01 successfully."
	    else
	    	log "ERROR : $component could not be transferred successfully. md5sum is not matching between confluence and server. Aborting Build !!"
	        exit 1
	    fi

	    sed -i '/exm-db-upgrade/d' /root/Releases/tmp/component_build_mapping.txt
		sed -i '/^$/d' /root/Releases/tmp/component_build_mapping.txt
		
		deploy_master $component $abort_on_fail deploy
	else
		log "DB upgrade is not required."
	fi
fi

case "${1}" in
	-d|--deploy)
	  if [ "$server" == "app01" ] && [ "$transfer_flag" == "true" ]
	  then
	  	  rows=`cat /root/Releases/tmp/component_build_mapping.txt`
	      IFS=$'\n'
	      for row in $rows
	      do
	        component=`echo $row | cut -d ':' -f 1 | awk '{$1=$1};1'`
	        confluence_md5sum=`echo $row | cut -d ':' -f 3 | awk '{$1=$1};1'`
	        comp_md5sum=`cd /root/Releases/$new_release/$component && find -type f -exec md5sum "{}" + | cut -d' ' -f1`

	        if [ "$confluence_md5sum" == "$comp_md5sum" ]
	        then
	          	log "md5sum is same on confluence and server. $component has been transferred to app01 successfully."
	        else
	        	log "ERROR : $component could not be transferred successfully. md5sum is not matching between confluence and server. Aborting Build !!"
	            exit 1
	        fi
	      done
	  fi

	  if [ $partial_flag == 2 ]
	  then
		  log "Checking if components are present..."
	  	  iter=1
          components=`cat /root/Releases/tmp/component_build_mapping.txt`
          IFS=$'\n'
          for row in $components
		  do
          	component=`echo $row | cut -d' ' -f1`
          	checkComponent $component
          done

	  	  for row in $components
		  do
          	component=`echo $row | cut -d' ' -f1`
		  	if [ $iter == 1 ]
			then
			log "================================================================================================================"
			log "Starting deployment of $new_release all components"
			fi
		  	deploy_master $component $abort_on_fail deploy
			iter=$((iter+1))
		  done
		  log "===============FINAL DEPLOYMENT STATUS( $server )==============="
	  else
	  	  log "Checking if components are present..."
          for component in "${choice_list[@]}"
	  	  do
          	if [ "$component" == "All" ]
            then
            	continue
            fi
          	checkComponent $component
          done
	  	  iter=1
	  	  for component in "${choice_list[@]}"
		  do
			if [ $iter == 1 ]
			then
            if [ "$component" == "All" ]
            then
            	continue
            fi
			log "================================================================================================================"
			log "Starting deployment of $new_release selected components"
			fi
			deploy_master $component $abort_on_fail deploy
			iter=$((iter+1))
		  done
		  if [ ${#statusArray[@]} == 0 ]
		  then
		  	:
		  else
		  	log "===============FINAL DEPLOYMENT STATUS( $server )==============="
		  fi
	  fi
	  ;;
	-r|--rollback)
	  if [ $partial_flag == 2 ]
	  then
	  	  log "Checking which components to rollback..."
	  	  iter=1
          components=`cat /root/Releases/tmp/component_build_mapping.txt`
          IFS=$'\n'
          for row in $components
		  do
		  	 if [ $iter == 1 ]
				then
					log "================================================================================================================"
					log "Starting rollback of $new_release : All components"
				fi
          	 component=`echo $row | cut -d' ' -f1`
          	 verify $component
			  
			 comp_status=`grep 'Successful' "${statusArray[${component}]}" | wc -l`
			 
			 if [ "$comp_status" == "1" ]
			 then
				
				deploy_master $component $abort_on_fail rollback
			 else
			 	log "$component does not need to be rolled back."
				 continue
			 fi
			 iter=$((iter+1))
			 
		  done
		  if [ ${#statusArray[@]} == 0 ]
		  then
		  	:
		  else
		  	log "===============FINAL ROLLBACK STATUS( $server )==============="
		  fi
	  else
	  	  iter=1
	  	  for component in "${choice_list[@]}"
	  	  do
	  	  	  if [ $iter == 1 ]
			  then
              	if [ "$component" == "All" ]
                then
                    continue
                fi
				log "================================================================================================================"
				log "Starting rollback of $new_release : Selected components"
			  fi
			  
			  verify $component
			  
			  comp_status=`grep 'Successful' "${statusArray[${component}]}" | wc -l`
			 
			  if [ "$comp_status" == "1" ]
			  then
			    deploy_master $component $abort_on_fail rollback
			  else
			 	log "$component does not need to be rolled back."
				continue
			  fi
			  iter=$((iter+1))
		  done
		  if [ ${#statusArray[@]} == 0 ]
		  then
		  	:
		  else
		  	log "===============FINAL ROLLBACK STATUS( $server )==============="
		  fi
	  fi
	  ;;
	-t|--transfer)
	  if [ "$server" == "app01" ] && [ "$transfer_flag" == "true" ]
	  then
	  	  if [ -f /root/Releases/tmp/component_build_mapping.txt ]
	  	  then
			  rows=`cat /root/Releases/tmp/component_build_mapping.txt`
		      IFS=$'\n'
		      for row in $rows
		      do
		        component=`echo $row | cut -d ':' -f 1 | awk '{$1=$1};1'`
		        confluence_md5sum=`echo $row | cut -d ':' -f 3 | awk '{$1=$1};1'`
		        comp_md5sum=`cd /root/Releases/$new_release/$component && find -type f -exec md5sum "{}" + | cut -d' ' -f1`

		        if [ "$confluence_md5sum" == "$comp_md5sum" ]
		        then
		          	log "md5sum is same on confluence and server. $component has been transferred to app01 successfully."
		          	
			    else
		        	log "ERROR : $component could not be transferred properly. md5sum is not matching between confluence and server. Aborting Build !!"
		            exit 1
		        fi
		      done

		      log "Transferring artifacts to app02."
		      { #try
		      	ssh app02 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do if [ `echo ${folder} | grep "_" | wc -l` -eq 0 ]; then mv /root/Releases/${folder} /root/Releases/${folder}_`date +%Y_%m_%d__%H_%M_%S`; fi; done; fi' && scp -r /root/Releases/$new_release /root/Releases/tmp  app02:/root/Releases
		      	if [ -d /root/Releases/$new_release/UIEWowzaLib ]
				then
					scp -r /root/Releases/$new_release/UIEWowzaLib media01:/root/
					scp -r /root/Releases/$new_release/UIEWowzaLib media02:/root/
				fi
			  } || { # catch
					    log "Could not connect to app02 server."
			  }
		  else
		  	  log "ERROR : Aborting build. Files have not been transferred."
		  	  exit 1
		  fi	
	  	  
	  fi
	  ;;
	  *)
	  echo "ERROR : Unknown option ${1}"
	  exit 1
	  ;;
esac
if [ ${#statusArray[@]} == 0 ]
then
	:
else
	log "================================================================"
	for key in ${!statusArray[@]};
	do
		log "${key} : ${statusArray[${key}]}"
		log "================================================================"
	done
fi

if [ "$server" == "app01" ] && [ "$transfer_flag" == "true" ] && [ "$action" == "-d" ]
then
	log "Transferring artifacts to app02."
	{ #try
	ssh app02 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do if [ `echo ${folder} | grep "_" | wc -l` -eq 0 ]; then mv /root/Releases/${folder} /root/Releases/${folder}_`date +%Y_%m_%d__%H_%M_%S`; fi; done; fi'
	scp -r /root/Releases/$new_release /root/Releases/tmp  app02:/root/Releases
	if [ -d /root/Releases/$new_release/UIEWowzaLib ]
	then
		ssh media01 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do if [ `echo ${folder} | grep "_" | wc -l` -eq 0 ]; then mv /root/Releases/${folder} /root/Releases/${folder}_`date +%Y_%m_%d__%H_%M_%S`; fi; done; fi'
		ssh media02 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do if [ `echo ${folder} | grep "_" | wc -l` -eq 0 ]; then mv /root/Releases/${folder} /root/Releases/${folder}_`date +%Y_%m_%d__%H_%M_%S`; fi; done; fi'
		scp -r /root/Releases/$new_release/UIEWowzaLib /root/Releases/tmp media01:/root/Releases
		scp -r /root/Releases/$new_release/UIEWowzaLib /root/Releases/tmp media02:/root/Releases
	fi
	} || { # catch
		    log "Could not connect to app02 server."
	}
elif [ "$server" == "app01" ] && [ "$transfer_flag" == "false" ] && [ "$action" == "-d" ]
then
	log "Transferring tmp folder to app02."
	{ #try
	ssh app02 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else mv /root/Releases/tmp /root/Releases/tmp_`date +%Y_%m_%d__%H_%M_%S`; fi'
	ssh media01 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else mv /root/Releases/tmp /root/Releases/tmp_`date +%Y_%m_%d__%H_%M_%S`; fi'
	ssh media02 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else mv /root/Releases/tmp /root/Releases/tmp_`date +%Y_%m_%d__%H_%M_%S`; fi'
	scp -r /root/Releases/tmp  app02:/root/Releases/
	scp -r /root/Releases/tmp  media01:/root/Releases/
	scp -r /root/Releases/tmp  media02:/root/Releases/
	} || { # catch
		log "Could not connect to app02 server."
	}
fi
