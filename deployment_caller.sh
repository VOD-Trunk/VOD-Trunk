#!/bin/bash
#Author : Abhishek Chadha
#Last modified : 7/1/2020
ts=`date +'%s'`
logfile=deployment-$ts.log
env=$1
release=$2
action=$3
component=$4
component=`echo $component | sed "s/ /_/g"`
workspace=$5
abort_on_fail=$6

if [ "$action" == "Deploy" ]
then
	echo "Transferring artifacts to the target server ( $env )"
	echo
	sshpass -p "Carnival@123" ssh root@$env 'for folder in `ls /root/Releases`; do rm -rf /root/Releases/$folder; done'
	sshpass -p "Carnival@123" scp -r $workspace/Releases/$release $workspace/tmp root@$env:/root/Releases
	sshpass -p "Carnival@123" ssh root@$env "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" > $workspace/logs/"${logfile}"
	cat $workspace/logs/${logfile}
elif [ "$action" == "Rollback" ]
then
	sshpass -p "Carnival@123" ssh root@$env "bash -s" -- < $workspace/deploy_on_server.sh -r "$release" "$component" "$abort_on_fail" > $workspace/logs/"${logfile}"
	cat $workspace/logs/${logfile}
fi
