#!/bin/bash
#Author : Abhishek Chadha
#Last modified : 6/30/2020
ts=`date +'%s'`
logfile=deployment-$ts.log
env=$1
release=$2
action=$3
component=$4

if [ "$action" == "Deploy" ]
then
	echo "Transferring artifacts to the target server ( $env )"
	echo
	sshpass -p "Carnival@123" scp -r /var/lib/jenkins/workspace/VOD-pipeline-abhi/Releases/$release root@$env:/root/Releases
	sshpass -p "Carnival@123" ssh root@$env "bash -s" -- < /var/lib/jenkins/workspace/VOD-pipeline-abhi/deploy_on_server.sh -d "$release" "$component" > /var/lib/jenkins/workspace/VOD-pipeline-abhi/logs/"${logfile}"
	cat /var/lib/jenkins/workspace/VOD-pipeline-abhi/logs/${logfile}
	
elif [ "$action" == "Rollback" ]
then
	sshpass -p "Carnival@123" ssh root@$env "bash -s" -- < /var/lib/jenkins/workspace/VOD-pipeline-abhi/deploy_on_server.sh -r "$release" "$component" > /var/lib/jenkins/workspace/VOD-pipeline-abhi/logs/"${logfile}"
	cat /var/lib/jenkins/workspace/VOD-pipeline-abhi/logs/${logfile}
fi
