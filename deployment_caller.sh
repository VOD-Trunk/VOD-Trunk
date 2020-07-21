#!/bin/bash

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
	sshpass -p "Carnival@123" ssh root@$env 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do rm -rf /root/Releases/$folder; done; fi'
	sshpass -p "Carnival@123" scp -r $workspace/Releases/$release $workspace/tmp root@$env:/root/Releases
	sshpass -p "Carnival@123" ssh root@$env "ssh -tt app02 \" rm -rf /root/Releases \"" 2>/dev/null
	sshpass -p "Carnival@123" ssh root@$env "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app01" > $workspace/logs/"${logfile}"
	sshpass -p "Carnival@123" ssh root@$env 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app02" >> $workspace/logs/"${logfile}"
	cat $workspace/logs/${logfile}
elif [ "$action" == "Rollback" ]
then
	sshpass -p "Carnival@123" ssh root@$env "bash -s" -- < $workspace/deploy_on_server.sh -r "$release" "$component" "$abort_on_fail" "app01"> $workspace/logs/"${logfile}"
	sshpass -p "Carnival@123" ssh root@$env 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -r "$release" "$component" "$abort_on_fail" "app02" >> $workspace/logs/"${logfile}"
	cat $workspace/logs/${logfile}
fi
