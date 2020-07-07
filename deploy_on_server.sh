#!/bin/bash

#Author : Abhishek Chadha
#Last modified : 7/1/2020

ts=`date +'%s'`
logfile='/root/Releases/deployment-$ts.log'
new_release=$2
component_choice=$3
abort_on_fail=$4

err() {
    >&2 echo -e "$@"
}

log(){
    echo "$@" >&1 2>&1
    echo "$@" >> ${logfile}
}

get_current_build() {

	component=$1

	if [ $component == "exm-admin-tool" ]
	then
			current_build=`ls -la /apps/exm-admin-tool/ | grep current | cut -d '>' -f 2 | sed 's/ //g'`
			releases_path='/apps/exm-admin-tool'
	fi

	if [ $component == "exm-client-cruise" ]
	then
			current_build=`ls -la /apps/clientmap/exm-client-cruise | grep current | cut -d '>' -f 2 | sed 's/ //g'`
			releases_path='/apps/clientmap/exm-client-cruise'
	fi

	if [ $component == "exm-client-startup" ]
	then
			current_build=`ls -la /apps/clientmap/exm-client-startup/ | grep current | cut -d '>' -f 2 | sed 's/ //g'`
			releases_path='/apps/clientmap/exm-client-startup'
	fi

	if [ $component == "exm-client-leftnav2" ]
	then
			current_build=`ls -la /apps/clientmap/exm-client-leftnav2/ | grep current | cut -d '>' -f 2 | sed 's/ //g'`
			releases_path='/apps/clientmap/exm-client-leftnav2'
	fi

	if [ $component == "LeftNav_Signage" ]
	then
			current_build=`ls -la /apps/clientmap/exm-client-leftnav2-signage/ | grep current | cut -d '>' -f 2 | sed 's/ //g'`
			releases_path='/apps/clientmap/exm-client-leftnav2-signage'
	fi

	if [  $component == "v2" ]
	then
			current_build='/var/lib/tomcat7/hosts/prod.uiexm.com/webapps/v2.war'
			releases_path='/var/lib/tomcat7/hosts/prod.uiexm.com/webapps'
	fi

	if [ $component == "nacos" ]
	then
			current_build=`ls -la /usr/local/nacos/ | grep nacos.daemon.jar | cut -d '>' -f 2 | sed 's/ //g' | cut -d '/' -f 6`
			releases_path='/usr/local/nacos'
	fi

	if  [ $component == "exm-client-lite" ]
	then
			current_build=`ls -la /apps/clientmap/exm-client-lite/ | grep current | cut -d '>' -f 2 | sed 's/ //g'`
			releases_path='/apps/clientmap/exm-client-lite'
	fi

	if  [ $component == "Location_Service" ]
	then
			current_build='/var/lib/tomcat7/hosts/prod.uiexm.com/webapps/location.war'
			releases_path='/var/lib/tomcat7/hosts/prod.uiexm.com/webapps'
	fi

	echo "$current_build:$releases_path"
}

restart_services() {

	component=$1
	start_stop=$2
	
	if  ([ $component == "v2" ] || [ $component  == "location" ]) && [ $start_stop == "stop" ]
	then
		log "Stopping tomcat7 service for $component..."
		log
		pkill -9 -u tomcat java #Stop_Tomcat_Service
		sleep 5

		log
		log "============================================================================================================================="
		log	
	fi

	if  ([ $component == "v2" ] || [ $component  == "location" ]) && [ $start_stop == "start" ]
	then
		log "Starting tomcat7 service for $component..."
		log
		service tomcat7 start #Start_Tomcat_Service
		sleep 5
		tomcat_status=`service tomcat7 status | grep running | wc -l`
		
		if [ $tomcat_status == 1 ]
		then
			echo "tomcat7 started successfully."
		else
			echo "tomcat7 failed to start"
		fi	

		log
		log "============================================================================================================================="
		log	
	fi
	
	if [ $component == "nacos" ] && [ $start_stop == "stop" ]
	then
		log "Stopping nacos service..."
		log
		service nacos stop
		log
		sleep 5
		log
		log "============================================================================================================================="
		log	
	fi

	if [ $component == "nacos" ] && [ $start_stop == "start" ]
	then
		log "Starting nacos service..."
		log
		service nacos start
		sleep 5
		
		nacos_status=`ps -ef | grep nacos.daemon.jar | wc -l`
		
		if [ $nacos_status -gt 1 ]
		then
			log "nacos started successfully."
			log
		else
			log "nacos failed to start."
			log
		fi

		log
		log "============================================================================================================================="
		log
	fi
}

deploy_new_build() {

	new_release=$1
	component=$2
	releases_path=$3
	current_build=$4

	if  [ $component == "exm-admin-tool" ] || [ $component == "exm-client-cruise" ] || [ $component == "exm-client-startup" ] || [ $component == "exm-client-leftnav2" ] || [ $component == "LeftNav_Signage" ] || [ $component == "exm-client-lite" ]
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
	fi

	if  [ $component == "v2" ] || [ $component  == "location" ] || [ $component  == "excursion" ]
	then
		log "Starting deployment of $component"
		log
		log "Copying $releases_path/$component.war file to /tmp for backup."
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
		cp -r $current_build $releases_path/Backup/
		#cp $releases_path/$component.war /tmp/
		rm -rf $releases_path/$component*

		log "Copying new war file to $releases_path/$component.war"
		log

		cp /root/Releases/$new_release/$component/* $releases_path/$component.war
	fi

	if  [ $component  == "nacos" ]
	then
		log "Starting deployment of $component"
		log
		log "Making a new directory $releases_path/$new_release"
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
		cp -r $releases_path/releases/$current_build $releases_path/Backup/

		if [ ! -d $releases_path/releases/$new_release ]
		then
			mkdir -p $releases_path/releases/$new_release
		elif [ -d $releases_path/releases/$new_release ]
		then
			for i in `ls $releases_path/releases/$new_release`
			do
				rm -rf $releases_path/releases/$new_release/$i
			done
		fi
		
		new_build=`ls /root/Releases/$new_release/$component/*.jar | cut -d "/" -f 6`

		log "Copying $new_build to $releases_path/$new_release"
		log

		cp /root/Releases/$new_release/$component/$new_build $releases_path/releases/$new_release

		log "Unlinking nacos.daemon.jar symlink..."
		log
		log "Current nacos.daemon.jar symlink is :"
		log
		log "`ls -l $releases_path | grep "nacos.daemon.jar"`"
		log

		unlink $releases_path/nacos.daemon.jar

		log "Creating new symlink nacos.daemon.jar ..."
		log

		ln -s $releases_path/releases/$new_release/$new_build $releases_path/nacos.daemon.jar

		log "New nacos.daemon.jar symlink is :"
		log
		log "`ls -l $releases_path | grep "nacos.daemon.jar"`"
		log
		log "Copying properties.uie file to $releases_path/releases/$new_release"
		log

		cp $releases_path/properties.uie $releases_path/releases/$new_release

		log "Current properties.uie symlink is :"
		log
		log "`ls -l $releases_path | grep "properties.uie"`"
		log

		unlink $releases_path/properties.uie

		log "Creating new symlink properties.uie ..."
		log

		ln -s $releases_path/releases/$new_release/properties.uie $releases_path/properties.uie

		log "New properties.uie symlink is :"
		log
		log "`ls -l $releases_path | grep "properties.uie"`"
		log
	fi
}

rollback() {

	current_build=$1
	component=$2
	releases_path=$3

	if  [ "$component" == "exm-admin-tool" ] || [ "$component" == "exm-client-cruise" ] || [ "$component" == "exm-client-startup" ] || [ "$component" == "exm-client-leftnav2" ] || [ "$component" == "LeftNav_Signage" ] || [ "$component" == "exm-client-lite" ]
	then

		log "Starting rollback of $component"
		log

		rollback_build=`cd /$releases_path/Backup/ && find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'`

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

	if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "excursion" ]
	then

		log "Starting rollback of $component"
		log
		log "Removing current build"
		log

		rm -rf $releases_path/$component*

		log "Copying rollbcak build to $releases_path"
		log
		cp $releases_path/Backup/$component.war $releases_path/$component.war
	fi

	if  [ "$component"  == "nacos" ]
	then

		log "Starting rollback of $component"
		log

		rollback_build=`cd /$releases_path/Backup/ && find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'`

		log "Unlinking the current nacos.daemon.jar symlink..."
		log

		unlink $releases_path/nacos.daemon.jar

		log "Creating a new link using the Backup build..."
		log

		ln -s $releases_path/releases/$rollback_build/*.jar $releases_path/nacos.daemon.jar

		log "New nacos.daemon.jar symlink is :"
		log
		log "`ls -l $releases_path | grep "nacos.daemon.jar"`"
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
	
}

verify() {

	#This function is untested. Need to have the timestamp.txt updated in all artifacts of a single release.

	component=$1
	releases_path=$2
	current_build=$3
	abort_on_fail=$4
	services_status=1

	if  [ $component == "exm-admin-tool" ] || [ $component == "exm-client-cruise" ] || [ $component == "exm-client-startup" ] || [ $component == "exm-client-leftnav2" ] || [ $component == "LeftNav_Signage" ] || [ $component == "exm-client-lite" ]
	then
		timestamp_release=`cat $current_build/timestamp.txt | grep Branch | cut -d ":" -f 2 | sed 's/ //g'`
	fi

	if  [ $component == "v2" ] || [ $component  == "location" ] || [ $component  == "excursion" ]
	then
		timestamp_release=`cat $releases_path/$component/timestamp.txt | grep Branch | cut -d ":" -f 2 | sed 's/ //g'`
	fi

	if  [ $component == "v2" ] || [ $component  == "location" ] || [ $component  == "excursion" ]
	then
		PID_FILE_SIZE=`stat -c%s /var/run/tomcat7.pid`
		SIZE=0
		

		if (( PID_FILE_SIZE > SIZE ));
		then
			log "Service Having PID"
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

		
		tail -100 /var/log/tomcat7/catalina.out | grep -w "Starting Servlet Engine: Apache Tomcat"
		if [ $? -eq 0 ]
		then
			log "TOMCAT SERVICE Started"
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

	

	if [[ "$timestamp_release" == *"$new_release"* ]]
	then
		timestamp_status=1
	else
		timestamp_status=2
		if [ $abort_on_fail == "Abort" ]
		then
			log "Aborting mission during $component deployment as the timestamp is not updated. Please check $releases_path . Thanks."
			log
			exit 1
		fi
	fi

	if [ $timestamp_status -eq 1 ] && [ $services_status -eq 1 ]
	then
		log
		log
		log
		log "============================================================================================================================="
		log "The deployment of $component was successfull. New version : $timestamp_release"
		log "============================================================================================================================="
		log
		log
	else
		log
		log
		log
		log "============================================================================================================================="
		log "The deployment of $component was NOT successfull. New version : $timestamp_release"
		if [ $timestamp_status -eq 1 ]
		then
			log "Please check tomcat7 service."
		elif [ $services_status -eq 1 ]
		then
			log "The timestamp doesn't contain the new release number. Please check $releases_path"
		else
			log "The timestamp doesn't contain the new release number and tomcat is not running. Please check both"
		fi
		log "============================================================================================================================="
		log
		log

	fi
}

#main script
		log "==================================================`date`========================================================="

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
		elif [ "${choice_list[$i]}" == "EXM Lite Client (Serial)" ]
		then
			choice_list[$i]="exm-client-lite"
		elif [ "${choice_list[$i]}" == "Startup Client" ]
		then
			choice_list[$i]="exm-client-startup"
		elif [ "${choice_list[$i]}" == "NACOS Listener" ]
		then
			choice_list[$i]="nacos"
		elif [ "${choice_list[$i]}" == "LeftNav Signage" ]
		then
			choice_list[$i]="exm-client-leftnav2-signage"
		elif [ "${choice_list[$i]}" == "Exm-v2-plugin-location (Location Services Plugin)" ]
		then
			choice_list[$i]="location"
		fi
	done
fi



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
	  	  for component in `ls /root/Releases/$new_release`
		  do
		  	  releases_path=$(get_current_build $component | cut -d ":" -f 2)
			  current_build=$(get_current_build $component | cut -d ":" -f 1)

			  if [ $iter == 1 ]
			  then
				log "Starting deployment of $new_release all components"
				log
			  fi
			  if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "nacos" ] || [ "$component"  == "excursion" ]
			  then
			  	restart_services $component stop
			  fi

			  deploy_new_build $new_release $component $releases_path $current_build

			  if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "nacos" ] || [ "$component"  == "excursion" ]
			  then
			  	restart_services $component start
			  fi

			  current_build=$(get_current_build $component | cut -d ":" -f 1)
			  verify $component $releases_path $current_build $abort_on_fail

			  iter=$((iter+1))
		  done
	  else
	  	  iter=1
	  	  for component in "${choice_list[@]}"
		  do
		  	  releases_path=$(get_current_build $component | cut -d ":" -f 2)
			  current_build=$(get_current_build $component | cut -d ":" -f 1)

			  if [ $iter == 1 ]
			  then
				log "Starting deployment of $new_release selected components"
				log
			  fi
			  if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "nacos" ] || [ "$component"  == "excursion" ]
			  then
			  	restart_services $component stop
			  fi

			  deploy_new_build $new_release $component $releases_path $current_build

			  if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "nacos" ] || [ "$component"  == "excursion" ]
			  then
			  	restart_services $component start
			  fi

			  current_build=$(get_current_build $component | cut -d ":" -f 1)
			  verify $component $releases_path $current_build $abort_on_fail

			  iter=$((iter+1))
		  done
	  fi
	  ;;
	-r|--rollback)
	  if [ $partial_flag == 2 ]
	  then
	  	  iter=1
	  	  for component in `ls /root/Releases/$new_release`
		  do
		  	  releases_path=$(get_current_build $component | cut -d ":" -f 2)
			  current_build=$(get_current_build $component | cut -d ":" -f 1)

			  if [ $iter == 1 ]
			  then
				log "Starting rollback of $new_release : All components"
				log
			  fi
			  if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "nacos" ] || [ "$component"  == "excursion" ]
			  then
			  	restart_services $component stop
			  fi

			  rollback $current_build $component $releases_path

			  if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "nacos" ] || [ "$component"  == "excursion" ]
			  then
			  	restart_services $component start
			  fi

			  current_build=$(get_current_build $component | cut -d ":" -f 1)
			  verify $component $releases_path $current_build $abort_on_fail

			  iter=$((iter+1))
		  done
	  else
	  	  iter=1
	  	  for component in "${choice_list[@]}"
	  	  do
	  	  	  releases_path=$(get_current_build $component | cut -d ":" -f 2)
			  current_build=$(get_current_build $component | cut -d ":" -f 1)

			  if [ $iter == 1 ]
			  then
				log "Starting rollback of $new_release : Selected components"
				log
			  fi
			  if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "nacos" ] || [ "$component"  == "excursion" ]
			  then
			  	restart_services $component stop
			  fi

			  rollback $current_build $component $releases_path

			  if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "nacos" ] || [ "$component"  == "excursion" ]
			  then
			  	restart_services $component start
			  fi

			  current_build=$(get_current_build $component | cut -d ":" -f 1)
			  verify $component $releases_path $current_build $abort_on_fail

			  iter=$((iter+1))
		  done
	  fi
	  ;;
	*)
	  echo Unknown option ${1}
	  exit 1
	  ;;
esac
