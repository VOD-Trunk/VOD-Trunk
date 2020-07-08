#!/bin/bash

#Author : Abhishek Chadha
#Last modified : 7/1/2020

ts=`date +'%s'`
logfile='/root/Releases/deployment-$ts.log'
new_release=$2
component_choice=$3
abort_on_fail=$4
action=$1
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

	if [ $component == "mutedaemon" ]
	then
			current_build=`ls -la /usr/local/mutedaemon/ | grep mutedaemon.jar | cut -d '>' -f 2 | sed 's/ //g' | cut -d '/' -f 6`
			releases_path='/usr/local/mutedaemon'
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

	#####Deployment of all clients have the same steps. So using the same code for both in below code block.

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



	#####Deployment of all .war files have the same steps. So usinf the same code for both in below code block.

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
		cp -r $releases_path/$component* $releases_path/Backup/
		#cp $releases_path/$component.war /tmp/
		rm -rf $releases_path/$component*

		log "Copying new war file to $releases_path/$component.war"
		log

		cp /root/Releases/$new_release/$component/* $releases_path/$component.war
	fi

	#####Deployment of nacos and mutedaemon have the same steps. So usinf the same code for both in below code block.

	if  [ $component  == "nacos" ] || [ $component  == "mutedaemon" ]
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

		if [ ! -d $releases_path/releases ]
		then
			mkdir -p $releases_path/releases
		elif [ -d $releases_path/releases ]
		then
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
		fi
		
		log "Taking backup of the current build."
		log
		
		cp -r $releases_path/releases/$current_build $releases_path/Backup/

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

		log "Current $jar_symlink symlink is :"
		log
		log "`ls -l $releases_path | grep "$jar_symlink"`"
		log
		log "Unlinking $jar_symlink symlink..."
		log
		unlink $releases_path/nacos.daemon.jar

		log "Creating new symlink $jar_symlink ..."
		log

		ln -s $releases_path/releases/$new_release/$new_build $releases_path/$jar_symlink

		log "New $jar_symlink symlink is :"
		log
		log "`ls -l $releases_path | grep "$jar_symlink"`"
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
	
}

verify() {

	#This function is untested. Need to have the timestamp.txt updated in all artifacts of a single release.

	component=$1
	releases_path=$2
	current_build=$3
	abort_on_fail=$4
	action=$5
	services_status=1

	if  [ $component == "exm-admin-tool" ] || [ $component == "exm-client-cruise" ] || [ $component == "exm-client-startup" ] || [ $component == "exm-client-leftnav2" ] || [ $component == "LeftNav_Signage" ] || [ $component == "exm-client-lite" ]
	then
		timestamp_build=`cat $current_build/timestamp.txt | grep "Build Number" | cut -d ":" -f 2 | sed 's/ //g'`
		if [ "$action" == "deploy" ]
		then
			release_build=`cat /root/Releases/tmp/component_build_mapping.txt | grep $component | cut -d ":" -f 2 | sed 's/ //g'`
		else
			rollback_build=`cd $releases_path/Backup/ && find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n'`
			release_build=`cat $releases_path/Backup/$rollback_build/timestamp.txt | grep "Build Number" | cut -d ":" -f 2 | sed 's/ //g'`
		fi

	fi

	if  [ $component == "v2" ] || [ $component  == "location" ] || [ $component  == "excursion" ]
	then
		timestamp_build=`cat $releases_path/$component/timestamp.txt | grep "Build Number" | cut -d ":" -f 2 | sed 's/ //g'`
		if [ "$action" == "deploy" ]
		then
			release_build=`cat /root/Releases/tmp/component_build_mapping.txt | grep $component | cut -d ":" -f 2 | sed 's/ //g'`
		else
			release_build=`cat cat $releases_path/Backup/$component/timestamp.txt | grep "Build Number" | cut -d ":" -f 2 | sed 's/ //g'`
		fi
	fi

	if [ $component == "nacos" ] || [ $component  == "mutedaemon" ]
	then
		timestamp_build=`ls -l $releases_path | grep ".jar" | cut -d '>' -f 2 | cut -d '/' -f 6`
		release_build=$new_release
	fi

	if  [ $component == "v2" ] || [ $component  == "location" ] || [ $component  == "excursion" ]
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

		
		tail -100 /var/log/tomcat7/catalina.out | grep -w "Starting Servlet Engine: Apache Tomcat"
		if [ $? -eq 0 ]
		then
			log "tomcat7 service has been started."
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

	if [ $component == "nacos" ] || [ $component  == "mutedaemon" ]
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
		if [ $component == "nacos" ] || [ $component  == "mutedaemon" ]
		then 
			statusArray[$component]="Successful( Release Number : $timestamp_build )"
		else
			statusArray[$component]="Successful( Build Number : $timestamp_build )"
		fi
		log
		log
		log
		log "============================================================================================================================="
		log "The deployment/rollback of $component was successful."
		log "============================================================================================================================="
		log
		log
		#echo "Successful( Version : $timestamp_release )"
	else
		if [ $component == "nacos" ] || [ $component  == "mutedaemon" ]
		then 
			statusArray[$component]="Failed( Release Number : $timestamp_build )"
		else
			statusArray[$component]="Failed( Build Number : $timestamp_build )"
		fi
		log
		log
		log
		log "============================================================================================================================="
		log "The deployment/rollback of $component has failed."
		if [ $timestamp_status -eq 1 ]
		then
			log "Tomcat7 service is not running. Please check and deploy/rollback $component."
		elif [ $services_status -eq 1 ]
		then
			log "The desired build of $component has not been deployed/rolled back. Please check the symlink at $releases_path."
		fi
		log "============================================================================================================================="
		log
		log
		#echo "Failed( Version : $timestamp_release )"
	fi
}

deploy_master() {

	component=$1
	abort_on_fail=$2
	action=$3

	releases_path=$(get_current_build $component | cut -d ":" -f 2)
	current_build=$(get_current_build $component | cut -d ":" -f 1)

	if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "nacos" ] || [ "$component"  == "excursion" ]
	then
		restart_services $component stop
	fi
	if [ "$action" == "deploy" ]
	then
		deploy_new_build $new_release $component $releases_path $current_build
	else
		rollback $new_release $component $releases_path $current_build
	fi

	if  [ "$component" == "v2" ] || [ "$component"  == "location" ] || [ "$component"  == "nacos" ] || [ "$component"  == "excursion" ]
	then
		restart_services $component start
	fi

	current_build=$(get_current_build $component | cut -d ":" -f 1)
	verify $component $releases_path $current_build $abort_on_fail $action
}

#main script
		log "==================================================`date`========================================================="

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
		  	if [ $iter == 1 ]
			then
			log "Starting deployment of $new_release all components"
			log
			fi
		  	deploy_master $component $abort_on_fail deploy
			iter=$((iter+1))
		  done
	  else
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
	  fi
	  ;;
	*)
	  echo Unknown option ${1}
	  exit 1
	  ;;
esac

log
log
log
log "=================================FINAL DEPLOYMENT STATUS================================"
log
log
log "=============================================================="
for key in ${!statusArray[@]};
do
	log "${key} : ${statusArray[${key}]}"
	log "=============================================================="
done
