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

{ #try
if [ "$action" == "Deploy" ]
then
	echo "Transferring artifacts to the target server ( $env )"
	echo
	if [ "$env" == "192.168.248.161" ]
	then
		sshpass -p "Carnival@123" ssh -o "StrictHostKeyChecking=no"  root@$env 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do rm -rf /root/Releases/$folder; done; fi'
		sshpass -p "Carnival@123" scp -o "StrictHostKeyChecking=no" -r $workspace/Releases/$release $workspace/tmp root@$env:/root/Releases
		#sshpass -p "Trident123" ssh -o "StrictHostKeyChecking=no" root@$env "ssh -tt app02 \" rm -rf /root/Releases \"" 2>/dev/null
		sshpass -p "Carnival@123" ssh -o "StrictHostKeyChecking=no" root@$env "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app01" > $workspace/logs/"${logfile}"
		#sshpass -p "Trident123" ssh -o "StrictHostKeyChecking=no" root@$env 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app02" >> $workspace/logs/"${logfile}"
		cat $workspace/logs/${logfile}
	else
		sshpass -p "not4dev!" ssh  -o "StrictHostKeyChecking=no" -v root@$env 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do rm -rf /root/Releases/$folder; done; fi'
		sshpass -p "not4dev!" scp  -o "StrictHostKeyChecking=no" -v -r $workspace/Releases/$release $workspace/tmp root@$env:/root/Releases
        #sshpass -p "not4dev!" ssh -o "StrictHostKeyChecking=no" root@$env "ssh -tt app02 \" rm -rf /root/Releases \"" 2>/dev/null
		#sshpass -p "not4dev!" ssh -o "StrictHostKeyChecking=no" root@$env "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app01" > $workspace/logs/"${logfile}"
		#sshpass -p "not4dev!" ssh -o "StrictHostKeyChecking=no" root@$env 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app02" >> $workspace/logs/"${logfile}"
		#cat $workspace/logs/${logfile}
        
	fi
	
elif [ "$action" == "Rollback" ]
then
	if [ "$env" == "10.127.136.31" ]
	then
		sshpass -p "Trident123" ssh root@$env "bash -s" -- < $workspace/deploy_on_server.sh -r "$release" "$component" "$abort_on_fail" "app01"> $workspace/logs/"${logfile}"
		#sshpass -p "Trident123" ssh root@$env 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -r "$release" "$component" "$abort_on_fail" "app02" >> $workspace/logs/"${logfile}"
		cat $workspace/logs/${logfile}
	else
		#sshpass -p "not4dev!" ssh root@$env "bash -s" -- < $workspace/deploy_on_server.sh -r "$release" "$component" "$abort_on_fail" "app01"> $workspace/logs/"${logfile}"
		#sshpass -p "not4dev!" ssh root@$env 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -r "$release" "$component" "$abort_on_fail" "app02" >> $workspace/logs/"${logfile}"
		cat $workspace/logs/${logfile}
	fi
fi
} || { # catch
	echo "An exception occured in making ssh connections."
	exit 1

}

