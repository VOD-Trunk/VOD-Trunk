#!/bin/bash
#Author : Abhishek Chadha
#Last modified : 7/1/2020
ts=`date +'%s'`
logfile=deployment-$ts.log
env=$1
release=$2
action=$3
component=$4
workspace=$5

if [ "$action" == "Deploy" ]
then
	echo "Transferring artifacts to the target server ( $env )"
	echo
	sshpass -p "Carnival@123" scp -r $workspace/Releases/$release root@$env:/root/Releases
	sshpass -p "Carnival@123" ssh root@$env "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" > $workspace/logs/"${logfile}"
	cat $workspace/logs/${logfile}
	
elif [ "$action" == "Rollback" ]
then
	sshpass -p "Carnival@123" ssh root@$env "bash -s" -- < $workspace/deploy_on_server.sh -r "$release" "$component" > $workspace/logs/"${logfile}"
	cat $workspace/logs/${logfile}
fi
