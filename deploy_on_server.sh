#!/bin/bash

ts=`date +'%s'`
logfile='/root/Releases/deployment-$ts.log'
new_release=$2
component_choice=$3
abort_on_fail=$4
action=$1

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
		elif [ "${choice_list[$i]}" == "NACOS Listener" ]
		then
			choice_list[$i]="nacos"
		elif [ "${choice_list[$i]}" == "Mute Daemon" ]
		then
			choice_list[$i]="mutedaemon"
		elif [ "${choice_list[$i]}" == "LeftNav Signage" ]
		then
			choice_list[$i]="exm-client-leftnav2-signage"
		elif [ "${choice_list[$i]}" == "Exm-v2-plugin-location " ]
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
				mkdir -p /apps/exm-admin-tool/releases
			fi
			current_build=`ls -la /apps/exm-admin-tool/ | grep current | cut -d '>' -f 2 | sed 's/ //g'`
			releases_path='/apps/exm-admin-tool'
	fi

	if [ "$component" == "exm-client-cruise" ]
	then
			if [ ! -d /apps/exm-client/releases ]
			then
				mkdir -p /apps/exm-client/releases
			fi
			current_build=`ls -la /apps/exm-client/ | grep current | cut -d '>' -f 2 | sed 's/ //g'`
			releases_path='/apps/exm-client'
	fi

	if [ "$component" == "exm-client-startup" ]
	then
			if [ ! -d /apps/clientmap/exm-client-startup/releases ]
			then
				mkdir -p /apps/clientmap/exm-client-startup/releases
			fi
			current_build=`ls -la /apps/clientmap/exm-client-startup/ | grep current | cut -d '>' -f 2 | sed 's/ //g'`
			releases_path='/apps/clientmap/exm-client-startup'
	fi

	if [ "$component" == "exm-client-leftnav2" ]
	then
			if [ ! -d /apps/clientmap/exm-client-leftnav2/releases ]
			then
				mkdir -p /apps/clientmap/exm-client-leftnav2/releases
			fi
			current_build=`ls -la /apps/clientmap/exm-client-leftnav2/ | grep current | cut -d '>' -f 2 | sed 's/ //g'`
			releases_path='/apps/clientmap/exm-client-leftnav2'
	fi

	if [ "$component" == "exm-client-leftnav2-signage" ]
	then
			if [ ! -d /apps/clientmap/exm-client-leftnav2-signage/releases ]
			then
				mkdir -p /apps/clientmap/exm-client-leftnav2-signage/releases
			fi
			current_build=`ls -la /apps/clientmap/exm-client-leftnav2-signage/ | grep current | cut -d '>' -f 2 | sed 's/ //g'`
			releases_path='/apps/clientmap/exm-client-leftnav2-signage'
	fi

	if [ "$component" == "exm-diagnostic-app" ]
	then
			if [ ! -d /apps/exm-diagnostic-app/releases ]
			then
				mkdir -p /apps/exm-diagnostic-app/releases
			fi
			current_build=`ls -la /apps/exm-diagnostic-app/ | grep current | cut -d '>' -f 2 | sed 's/ //g'`
			releases_path='/apps/exm-diagnostic-app'
	fi

	if  [ "$component" == "exm-client-lite" ]
	then
			if [ ! -d /apps/clientmap/exm-client-lite/releases ]
			then
				mkdir -p /apps/clientmap/exm-client-lite/releases
			fi
			current_build=`ls -la /apps/clientmap/exm-client-lite/ | grep current | cut -d '>' -f 2 | sed 's/ //g'`
			releases_path='/apps/clientmap/exm-client-lite'
	fi

	if  [ "$component" == "mute" ]
	then
			if [ ! -d /apps/mute/releases ]
			then
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

	if [ "$component" == "nacos" ]
	then
			if [ ! -d /usr/local/nacos/releases ]
			then
				mkdir -p /usr/local/nacos/releases
			fi
			current_build=`ls -la /usr/local/nacos/ | grep "nacos.daemon.jar " | cut -d '>' -f 2 | sed 's/ //g' | cut -d '/' -f 6`
			releases_path='/usr/local/nacos'
	fi

	if [ "$component" == "mutedaemon" ]
	then
			if [ ! -d /usr/local/mutedaemon/releases ]
			then
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
	
	if  ([ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component" == "diagnostics" ] || [ "$component" == "notification-service" ]) && [ "$start_stop" == "stop" ]
	then
		log "Stopping tomcat7 service for $component..."
		log
		pkill -9 -u tomcat java #Stop_Tomcat_Service
		sleep 5

		log
		log "================================================================================================================"
		log	
	fi

	if  ([ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component" == "diagnostics" ] || [ "$component" == "notification-service" ]) && [ "$start_stop" == "start" ]
	then
		log "Starting tomcat7 service for $component..."
		log
		service tomcat7 start #Start_Tomcat_Service
		sleep 35
		tomcat_status=`service tomcat7 status | grep running | wc -l`
		
		if [ $tomcat_status == 1 ]
		then
			echo "tomcat7 started successfully."
		else
			echo "tomcat7 failed to start"
		fi	

		log
		log "================================================================================================================"
		log	
	fi
	
	if ([ "$component" == "nacos" ] || [ "$component" == "mutedaemon" ]) && [ "$start_stop" == "stop" ]
	then
		log "Stopping $component service..."
		log
		service $component stop
		log
		sleep 5
		log
		log "================================================================================================================"
		log	
	fi

	if ([ "$component" == "nacos" ] || [ "$component" == "mutedaemon" ]) && [ "$start_stop" == "start" ]
	then
		log "Starting $component service..."
		log
		service $component start
		sleep 5
		
		service_status=`ps -ef | grep "$component" | wc -l`
		
		if [ $service_status -gt 1 ]
		then
			log "$component started successfully."
			log
		else
			log "$component failed to start."
			log
		fi

		log
		log "================================================================================================================"
		log
	fi
}

deploy_new_build() {

	### This function contains all the deployment steps for each type of component. All tar files are deployed in one way and similarly all jar files in one way and all war files in one way.

	new_release=$1
	component=$2
	releases_path=$3
	current_build=$4

	#####Deployment of all clients have the same steps. So using the same code for both in below code block.

	if  [ "$component" == "exm-admin-tool" ] || [ "$component" == "exm-client-cruise" ] || [ "$component" == "exm-client-startup" ] || [ "$component" == "exm-client-leftnav2" ] || [ "$component" == "exm-client-leftnav2-signage" ] || [ "$component" == "exm-client-lite" ] || [ "$component" == "exm-diagnostic-app" ]
	then

		log "Starting the deployment of $component"
		log
		log "Taking backup of the current build."
		log

		if [ ! -d $releases_path/Backup ]
		then
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
		log

		tar -xf /root/Releases/$new_release/$component/$file_name -C /root/Releases/$new_release/$component/
		new_build=`cd /root/Releases/$new_release/$component/ && find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'`

		log "Copying $new_build to $releases_path/releases"
		log

		cp -r /root/Releases/$new_release/$component/$new_build $releases_path/releases/
		link_present=`ls $releases_path | grep current | wc -l`
		if [ $link_present == 1 ]
		then 
			log "Unlinking current symlink..."
			log
			log "current symlink is :"
			log "`ls -l $releases_path | grep current`"
			log

			unlink $releases_path/current
		fi

		log "Creating new symlink current ..."
		log

		ln -s $releases_path/releases/$new_build $releases_path/current

		log "New symlink is:"
		log "`ls -l $releases_path | grep current`"
		log

		if [ "$component" == "exm-client-cruise" ]
		then
			log "Setting permission on new release folder for cruise client..."
			log
			chmod -R 777 $releases_path/releases/$new_build
			chown -R apache:apache $releases_path/releases/$new_build

		fi
	fi



	#####Deployment of all .war files have the same steps. So using the same code for all in below code block.

	if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "excursion" ] || [ "$component" == "diagnostics" ] || [ "$component" == "notification-service" ]
	then
		log "Starting deployment of $component"
		log
		log "Copying $releases_path/$component.war file to $releases_path/Backup for backup."
		log
		log "Taking backup of the current build."
		log

		if [ ! -d /root/War_Backup/$component ]
		then
			mkdir -p /root/War_Backup/$component
		elif [ -d /root/War_Backup/$component ]
		then
			for i in `ls /root/War_Backup/$component`
			do
				rm -rf /root/War_Backup/$component/$i
			done
		fi
		cp -r $releases_path/$component* /root/War_Backup/$component
		#cp $releases_path/$component.war /tmp/
		rm -rf $releases_path/$component*

		log "Copying new war file to $releases_path/$component.war"
		log

		cp /root/Releases/$new_release/$component/* $releases_path/$component.war
	fi

	#####Deployment of nacos and mutedaemon have the same steps. So using the same code for both in below code block.

	if  [ "$component"  == "nacos" ] || [ "$component"  == "mutedaemon" ]
	then
		log "Starting deployment of $component"
		log
				
		if [ ! -d $releases_path/Backup ]
		then
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
			mkdir -p $releases_path/releases/$new_release
		elif [ -d $releases_path/releases/$new_release ]
		then
			log "Taking backup of the current build."
			log
	
			cp -r $releases_path/releases/$current_build $releases_path/Backup/

			for i in `ls $releases_path/releases/$new_release`
			do
				rm -rf $releases_path/releases/$new_release/$i
			done
		fi
		
		

		new_build=`ls /root/Releases/$new_release/$component/*.jar | cut -d "/" -f 6`

		log "Copying $new_build to $releases_path/$new_release"
		log

		if [ $component  == "nacos" ]
		then
			jar_symlink="nacos.daemon.jar"
		elif [ $component  == "mutedaemon" ]
		then
			jar_symlink="mutedaemon.jar"
		fi


		cp /root/Releases/$new_release/$component/$new_build $releases_path/releases/$new_release

		log "Unzipping the $component jar file"
		log

		unzip -qq $releases_path/releases/$new_release/$new_build -d $releases_path/releases/$new_release

		log "Current $jar_symlink symlink is :"
		log
		log "`ls -l $releases_path | grep "$jar_symlink "`"
		log
		log "Unlinking $jar_symlink symlink..."
		log
		unlink $releases_path/$jar_symlink
		log "Creating new symlink $jar_symlink ..."
		log

		ln -s $releases_path/releases/$new_release/$new_build $releases_path/$jar_symlink

		log "New $jar_symlink symlink is :"
		log
		log "`ls -l $releases_path | grep "$jar_symlink"`"
		log
		log "Copying properties.uie file to $releases_path/releases/$new_release"
		log
		if [ "$component" == "nacos" ]
		then
			cp $releases_path/Backup/$new_release/properties.uie $releases_path/releases/$new_release
		else
			cp $releases_path/Backup/$new_release/*.properties $releases_path/releases/$new_release
		fi

		log "Current properties.uie symlink is :"
		log
		log "`ls -l $releases_path | grep "properties.uie"`"
		log

		unlink $releases_path/properties.uie

		log "Creating new symlink properties.uie ..."
		log

		if [ "$component" == "nacos" ]
		then
			ln -s $releases_path/releases/$new_release/properties.uie $releases_path/properties.uie
		else
			ln -s $releases_path/releases/$new_release/*.properties $releases_path/properties.uie
		fi

		log "New properties.uie symlink is :"
		log
		log "`ls -l $releases_path | grep "properties.uie"`"
		log

		
	fi

	### Steps for node-mute service is different from all others. It is a zip file.

	if [ "$component" == "mute" ]
	then
		log "Starting the deployment of $component"
		log
		log "Taking backup of the current build."
		log

		if [ ! -d $releases_path/Backup ]
		then
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
			mkdir -p $releases_path/releases
		elif [ -d $releases_path/releases ]
		then
			mkdir -p $releases_path/releases/
		fi

		file_name=`ls /root/Releases/$new_release/$component/*.zip | cut -d "/" -f 6`

		log "Unzipping $file_name ..."
		log

		unzip -qq /root/Releases/$new_release/$component/$file_name -d /root/Releases/$new_release/$component/

		new_build=`cd /root/Releases/$new_release/$component/ && find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'`

		log "Copying $new_build to $releases_path/releases/"
		log

		cp -r /root/Releases/$new_release/$component/$new_build $releases_path/releases/

		link_present=`ls $releases_path/current | grep "server.js" | wc -l`

		if [ $link_present == 1 ]
		then 
			log "Unlinking current symlink..."
			log
			log "current symlink is :"
			log "`ls -l $releases_path/current | grep 'server.js'`"
			log

			unlink $releases_path/current/server.js
		fi

		log "Creating new symlink current ..."
		log

		ln -s $releases_path/releases/$new_build/*.js $releases_path/current/server.js

		log "New symlink is:"
		log "`ls -l $releases_path/current | grep 'server.js'`"
		log
	fi




}

rollback() {

	### Rollback function makes use of the Backup folder which contains the build that was there prior to this deployment.

	current_build=$1
	component=$2
	releases_path=$3

	if  [ "$component" == "exm-admin-tool" ] || [ "$component" == "exm-client-cruise" ] || [ "$component" == "exm-client-startup" ] || [ "$component" == "exm-client-leftnav2" ] || [ "$component" == "exm-client-leftnav2-signage" ] || [ "$component" == "exm-client-lite" ] || [ "$component" == "exm-diagnostic-app" ]
	then

		log "Starting rollback of $component"
		log

		rollback_build=`cd $releases_path/Backup/ && find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'`

		log "Unlinking the current link..."
		log

		unlink $releases_path/current

		log "Creating a new link using the Backup build..."
		log

		ln -s $releases_path/releases/$rollback_build $releases_path/current

		log "New symlink is:"
		log "`ls -l $releases_path | grep current`"
		log
		
	fi



	if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "excursion" ] || [ "$component" == "diagnostics" ] || [ "$component" == "notification-service" ]
	then

		log "Starting rollback of $component"
		log
		log "Removing current build"
		log

		rm -rf $releases_path/$component*

		log "Copying rollbcak build to $releases_path"
		log
		cp /root/War_Backup/$component/$component.war $releases_path/$component.war
	fi



	if  [ "$component"  == "nacos" ] || [ "$component"  == "mutedaemon" ]
	then

		log "Starting rollback of $component"
		log

		if [ $component  == "nacos" ]
		then
			jar_symlink="nacos.daemon.jar"
		elif [ $component  == "mutedaemon" ]
		then
			jar_symlink="mutedaemon.jar"
		fi


		rollback_build=`cd /$releases_path/Backup/ && find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'`

		log "Unlinking the current $jar_symlink symlink..."
		log

		unlink $releases_path/$jar_symlink

		log "Creating a new link using the Backup build..."
		log

		ln -s $releases_path/releases/$rollback_build/*.jar $releases_path/nacos.daemon.jar

		log "New $jar_symlink symlink is :"
		log
		log "`ls -l $releases_path | grep "$jar_symlink"`"
		log


		log "Unlinking the current properties.uie symlink..."
		log

		unlink $releases_path/properties.uie

		log "Creating a new link using the Backup build..."
		log

		ln -s $releases_path/releases/$rollback_build/*.uie $releases_path/properties.uie

		log "New properties.uie symlink is :"
		log
		log "`ls -l $releases_path | grep "properties.uie"`"
		log

	fi

	if  [ "$component"  == "mute" ]
	then
		log "Starting rollback of $component"
		log

		rollback_build=`cd /$releases_path/Backup/ && find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'`

		link_present=`ls $releases_path/current | grep "server.js" | wc -l`

		if [ $link_present == 1 ]
		then 
			log "Unlinking current symlink..."
			log
			log "current symlink is :"
			log "`ls -l $releases_path/current | grep 'server.js'`"
			log

			unlink $releases_path/current/server.js
		fi

		log "Creating new symlink current ..."
		log

		ln -s $releases_path/releases/$rollback_build/*.js $releases_path/current/server.js

		log "New symlink is:"
		log "`ls -l $releases_path/current | grep 'server.js'`"
		log
	fi
}

verify() {

	### This function compares the Build Number present in the component after deployment/rollback and also tests whether related service has been restarted or not. If both checks are satisfied it marks the activity successful.

	component=$1
	releases_path=$2
	current_build=$3
	abort_on_fail=$4
	action=$5
	services_status=1

	if  [ "$component" == "exm-admin-tool" ] || [ "$component" == "exm-client-cruise" ] || [ "$component" == "exm-client-startup" ] || [ "$component" == "exm-client-leftnav2" ] || [ "$component" == "exm-client-leftnav2-signage" ] || [ "$component" == "exm-client-lite" ] || [ "$component" == "exm-diagnostic-app" ]
	then
		timestamp_build=`cat $current_build/timestamp.txt | grep "Build Number" | cut -d ":" -f 2 | sed 's/ //g'`
		if [ "$action" == "deploy" ]
		then
			release_build=`cat /root/Releases/tmp/component_build_mapping.txt | grep -w "$component " | cut -d ":" -f 2 | sed 's/ //g'`
		else
			rollback_build=`cd $releases_path/Backup/ && find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'`
			release_build=`cat $releases_path/Backup/$rollback_build/timestamp.txt | grep "Build Number" | cut -d ":" -f 2 | sed 's/ //g'`
		fi

	fi

	if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "excursion" ] || [ "$component" == "diagnostics" ] || [ "$component" == "notification-service" ]
	then
		timestamp_build=`cat $releases_path/$component/timestamp.txt | grep "Build Number" | cut -d ":" -f 2 | sed 's/ //g'`
		if [ "$action" == "deploy" ]
		then
			release_build=`cat /root/Releases/tmp/component_build_mapping.txt | grep -w "$component " | cut -d ":" -f 2 | sed 's/ //g'`
		else
			release_build=`cat cat /root/War_Backup/$component/$component/timestamp.txt | grep "Build Number" | cut -d ":" -f 2 | sed 's/ //g'`
		fi
	fi

	if [ "$component" == "mute" ]
	then
		timestamp_build=`cat $current_build/timestamp.txt | grep "Build Number" | cut -d ":" -f 2 | sed 's/ //g'`
		if [ "$action" == "deploy" ]
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
		if [ "$action" == "deploy" ]
		then
			release_build=`cat /root/Releases/tmp/component_build_mapping.txt | grep -w "$component " | cut -d ":" -f 2 | sed 's/ //g'`
		else
			rollback_build=`cd $releases_path/Backup/ && find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'`
			release_build=`cat $releases_path/Backup/$rollback_build/timestamp.txt | grep "Build Number" | cut -d ":" -f 2 | sed 's/ //g'`
		fi
	fi

	if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "excursion" ] || [ "$component" == "diagnostics" ] || [ "$component" == "notification-service" ]
	then
		PID_FILE_SIZE=`stat -c%s /var/run/tomcat7.pid`
		SIZE=0
		

		if (( PID_FILE_SIZE > SIZE ));
		then
			log "tomcat7 service has a PID."
			log
		else
			services_status=2
			if [ $abort_on_fail == "Abort" ]
			then
				log "Aborting the deployment as tomcat was not restarted properly. Please check tomcat7 service. Thanks."
				log
				exit 1
			fi

		fi

		
		#tail -100 /var/log/tomcat7/catalina.out | grep -w "Starting Servlet Engine: Apache Tomcat"
		#if [ $? -eq 0 ]
		#then
		#	log "tomcat7 service has been started."
		#	log
		#else
		#	services_status=2
		#	if [ $abort_on_fail == "Abort" ]
		#	then
		#		log "Aborting the deployment as tomcat was not restarted properly. Please check tomcat7 service. Thanks."
		#		log
		#		exit 1
		#	fi
		#fi

		ps -elf | grep -v grep | grep -q tomcat7
		if [ $? -eq 0 ]
		then
			log "Tomcat Service Running"
			log
		else
			services_status=2
			if [ $abort_on_fail == "Abort" ]
			then
				log "Aborting mission during $component deployment as tomcat was not restarted properly. Please check tomcat7 service. Thanks."
				log
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
			log
		else
			services_status=2
			if [ $abort_on_fail == "Abort" ]
			then
				log "Aborting mission during $component deployment as $component service was not restarted properly. Please check $component service. Thanks."
				log
				exit 1
			fi

		fi


		ps -elf | grep -v grep | grep -q $component
		if [ $? -eq 0 ]
		then
			log "$component service is running"
			log
		else
			services_status=2
			if [ $abort_on_fail == "Abort" ]
			then
				log "Aborting mission during $component deployment as $component service was not restarted properly. Please check $component service. Thanks."
				log
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
			log "Aborting mission during $component deployment as the timestamp is not updated. Please check $releases_path . Thanks."
			exit 1
		fi
	fi

	if [ $timestamp_status -eq 1 ] && [ $services_status -eq 1 ]
	then
		statusArray[$component]="Successful( Deployed Build Number : $timestamp_build, Build Number on Confluence :  $release_build )"
		log
		log
		log
		log "================================================================================================================"
		log "The deployment/rollback of $component was successful."
		log "================================================================================================================"
		log
		log
		#echo "Successful( Version : $timestamp_release )"
	else
		statusArray[$component]="Failed( Deployed Build Number : $timestamp_build, Build Number on Confluence :  $release_build )"
		log
		log
		log
		log "================================================================================================================"
		log "The deployment/rollback of $component has failed."
		if [ $timestamp_status -eq 1 ]
		then
			log "Tomcat7 service is not running. Please check and deploy/rollback $component."
		elif [ $services_status -eq 1 ]
		then
			log "The desired build of $component has not been deployed/rolled back. Please check the symlink at $releases_path."
		fi
		log "================================================================================================================"
		log
		log
		#echo "Failed( Version : $timestamp_release )"
	fi
}

deploy_master() {

	### This is the main function which calls all the other functions according to the script arguments like 1) Component to be deployed. 2) To abort mission on failure or proceed 3) To deploy or rollabck  etc etc...

	component=$1
	abort_on_fail=$2
	action=$3

	releases_path=$(get_current_build $component | cut -d ":" -f 2)
	current_build=$(get_current_build $component | cut -d ":" -f 1)
    

	if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "nacos" ] || [ "$component"  == "excursion" ] || [  "$component" == "diagnostics" ] || [ "$component" == "notification-service" ]
	then
		restart_services $component stop
	fi
	if [ "$action" == "deploy" ]
	then
		deploy_new_build $new_release $component $releases_path $current_build
	else
		rollback $new_release $component $releases_path $current_build
	fi

	if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "nacos" ] || [ "$component"  == "excursion" ] || [  "$component" == "diagnostics" ] || [ "$component" == "notification-service" ]
	then
		restart_services $component start
	fi

	current_build=$(get_current_build $component | cut -d ":" -f 1)
	verify $component $releases_path $current_build $abort_on_fail $action
}

checkComponent() {

	component=$1
	
	log "Checking if $component has been transferred..."
    log
    DIR="/root/Releases/$new_release/$component"
    if [ "$(ls -A $DIR)" ]
    then
        log "$component has been transferred."
        log
    else
        log "$component has not been transferred. Please transfer it from artifactory and then deploy."
        log
        exit 1
    fi
}

#main script
		log
		log
		log "================================`date`================================"

if [[ $# -eq 0 ]]; then
	err "Usage: ${0} {option}"
	err "\t--deploy|-d"
	err "\t--rollback|-r"
	err
			exit 1
fi

case "${1}" in
	-d|--deploy)
	  if [ $partial_flag == 2 ]
	  then
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
			log "Starting deployment of $new_release all components"
			log
			fi
		  	deploy_master $component $abort_on_fail deploy
			iter=$((iter+1))
		  done
		  log
		  log
		  log "=================================FINAL DEPLOYMENT STATUS( $server )================================"
	  else
          for component in "${choice_list[@]}"
	  	  do
          	checkComponent $component
          done
	  	  iter=1
	  	  for component in "${choice_list[@]}"
		  do
			if [ $iter == 1 ]
			then
			log "Starting deployment of $new_release selected components"
			log
			fi
			deploy_master $component $abort_on_fail deploy
			iter=$((iter+1))
		  done
		  log
		  log
		  log "=================================FINAL DEPLOYMENT STATUS( $server )================================"
	  fi
	  ;;
	-r|--rollback)
	  if [ $partial_flag == 2 ]
	  then
	  	  iter=1
	  	  for component in `ls /root/Releases/$new_release`
		  do
		  	 if [ $iter == 1 ]
			  then
				log "Starting rollback of $new_release : All components"
				log
			  fi
			  deploy_master $component $abort_on_fail rollback
			  iter=$((iter+1))
		  done
		  log
		  log
		  log "=================================FINAL ROLLBACK STATUS( $server )================================"
	  else
	  	  iter=1
	  	  for component in "${choice_list[@]}"
	  	  do
	  	  	  if [ $iter == 1 ]
			  then
				log "Starting rollback of $new_release : Selected components"
				log
			  fi
			  deploy_master $component $abort_on_fail rollback
			  iter=$((iter+1))
		  done
		  log
		  log
		  log "=================================FINAL ROLLBACK STATUS( $server )================================"
	  fi
	  ;;
	-t|--transfer)
	  if [ "$server" == "app01" ]
	  then
		ssh app02 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do if [ `echo ${folder} | grep "_" | wc -l` -eq 0 ]; then mv /root/Releases/${folder} /root/Releases/${folder}_`date +%Y_%m_%d__%H_%M_%S`; fi; done; fi' && scp -r /root/Releases/$new_release /root/Releases/tmp  app02:/root/Releases
	  fi
	  ;;
	  *)
	  echo Unknown option ${1}
	  exit 1
	  ;;
esac

log
log
log "==============================================================================================="
for key in ${!statusArray[@]};
do
	log "${key} : ${statusArray[${key}]}"
	log "==============================================================================================="
done

if [ "$server" == "app01" ] && [ "$action" == "-d" ] && [ $transfer_flag == "true" ]
then
	ssh app02 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do if [ `echo ${folder} | grep "_" | wc -l` -eq 0 ]; then mv /root/Releases/${folder} /root/Releases/${folder}_`date +%Y_%m_%d__%H_%M_%S`; fi; done; fi' && scp -r /root/Releases/$new_release /root/Releases/tmp  app02:/root/Releases
fi