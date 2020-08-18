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
transfer_flag=$7

{ #try
if [ "$action" == "Deploy" ] && [ "$transfer_flag" == "true" ]
then
	echo "Transferring artifacts to the target server ( $env )"
	echo
	if [ "$env" == "10.127.136.31" ]
	then
		sshpass -p "Trident123" ssh -o "StrictHostKeyChecking=no"  root@$env 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do if [ `echo ${folder} | grep "_" | wc -l` -eq 0 ]; then mv /root/Releases/${folder} /root/Releases/${folder}_`date +%Y_%m_%d__%H_%M_%S`; fi; done; fi'
		sshpass -p "Trident123" scp -o "StrictHostKeyChecking=no" -r $workspace/Releases/$release $workspace/tmp root@$env:/root/Releases
		#sshpass -p "Trident123" ssh -o "StrictHostKeyChecking=no" root@$env "ssh -tt app02 \" rm -rf /root/Releases \"" 2>/dev/null
		sshpass -p "Trident123" ssh -o "StrictHostKeyChecking=no" root@$env "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app01" > $workspace/logs/"${logfile}"
		#sshpass -p "Trident123" ssh -o "StrictHostKeyChecking=no" root@$env 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app02" >> $workspace/logs/"${logfile}"
		if [ -f $workspace/logs/${logfile} ]
        then
        	cat $workspace/logs/${logfile}
            transfer_status=`grep "has not been transferred" $workspace/logs/${logfile} | wc -l`

            if [ $transfer_status -gt 0 ]
            then
                exit 125
            fi
        else
        	echo "Log file not present at $workspace/logs/${logfile}"
            exit 1
        fi
    else
		sshpass -p "Carnival@123" ssh  -o "StrictHostKeyChecking=no"  root@$env 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do if [ `echo ${folder} | grep "_" | wc -l` -eq 0 ]; then mv /root/Releases/${folder} /root/Releases/${folder}_`date +%Y_%m_%d__%H_%M_%S`; fi; done; fi'
		sshpass -p "Carnival@123" scp  -o "StrictHostKeyChecking=no" -r $workspace/Releases/$release $workspace/tmp root@$env:/root/Releases
		sshpass -p "Carnival@123" ssh -o "StrictHostKeyChecking=no" root@$env "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app01" > $workspace/logs/"${logfile}"
		sshpass -p "Carnival@123" ssh -o "StrictHostKeyChecking=no" root@$env 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app02" >> $workspace/logs/"${logfile}"
		if [ -f $workspace/logs/${logfile} ]
        then
        	cat $workspace/logs/${logfile}
            transfer_status=`grep "has not been transferred" $workspace/logs/${logfile} | wc -l`

            if [ $transfer_status -gt 0 ]
            then
                exit 125
            fi
        else
        	echo "Log file not present at $workspace/logs/${logfile}"
            exit 1
        fi
        
	fi
elif [ "$action" == "Deploy" ] && [ "$transfer_flag" == "false" ]
then
	if [ "$env" == "10.127.136.31" ]
	then
		sshpass -p "Trident123" ssh -o "StrictHostKeyChecking=no" root@$env "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app01" > $workspace/logs/"${logfile}"
		#sshpass -p "Trident123" ssh -o "StrictHostKeyChecking=no" root@$env 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app02" >> $workspace/logs/"${logfile}"
        
		if [ -f $workspace/logs/${logfile} ]
        then
        	cat $workspace/logs/${logfile}
            transfer_status=`grep "has not been transferred" $workspace/logs/${logfile} | wc -l`

            if [ $transfer_status -gt 0 ]
            then
                exit 125
            fi
        else
        	echo "Log file not present at $workspace/logs/${logfile}"
            exit 1
        fi
	else
		sshpass -p "Carnival@123" ssh -o "StrictHostKeyChecking=no" root@$env "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app01" > $workspace/logs/"${logfile}"
		sshpass -p "Carnival@123" ssh -o "StrictHostKeyChecking=no" root@$env 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app02" >> $workspace/logs/"${logfile}"
		if [ -f $workspace/logs/${logfile} ]
        then
        	cat $workspace/logs/${logfile}
            transfer_status=`grep "has not been transferred" $workspace/logs/${logfile} | wc -l`

            if [ $transfer_status -gt 0 ]
            then
                exit 125
            fi
        else
        	echo "Log file not present at $workspace/logs/${logfile}"
            exit 1
        fi
    fi
    
elif [ "$action" == "ScheduleDeploy" ]
then
	if [ -f $workspace/tmp/scheduled_ships.txt ]
	then
		ships=`cat $workspace/tmp/scheduled_ships.txt`
		IFS=$'\n'
		for ship in $ships
		do
			ipaddr=`echo $ship | cut -d: -f2`
            echo
            echo "Transferring artifacts to the target server ( $ipaddr )"
            echo
            if [ "$ipaddr" == "10.127.136.31" ]
			then
				sshpass -p "Trident123" ssh -o "StrictHostKeyChecking=no"  root@$ipaddr 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do if [ `echo ${folder} | grep "_" | wc -l` -eq 0 ]; then mv /root/Releases/${folder} /root/Releases/${folder}_`date +%Y_%m_%d__%H_%M_%S`; fi; done; fi'
				sshpass -p "Trident123" scp -o "StrictHostKeyChecking=no" -r $workspace/Releases/$release $workspace/tmp root@$ipaddr:/root/Releases
                sshpass -p "Trident123" ssh -o "StrictHostKeyChecking=no" root@$ipaddr "bash -s" -- < $workspace/deploy_on_server.sh -t "$release" "$component" "$abort_on_fail" "app01" > $workspace/logs/"${logfile}"
            else
				sshpass -p "Carnival@123" ssh  -o "StrictHostKeyChecking=no" -r root@$ipaddr 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do if [ `echo ${folder} | grep "_" | wc -l` -eq 0 ]; then mv /root/Releases/${folder} /root/Releases/${folder}_`date +%Y_%m_%d__%H_%M_%S`; fi; done; fi'
				sshpass -p "Carnival@123" scp  -o "StrictHostKeyChecking=no" -r $workspace/Releases/$release $workspace/tmp root@$ipaddr:/root/Releases
                sshpass -p "Carnival@123" ssh -o "StrictHostKeyChecking=no" root@$ipaddr "bash -s" -- < $workspace/deploy_on_server.sh -t "$release" "$component" "$abort_on_fail" "app01" > $workspace/logs/"${logfile}"
                
            fi
		done
	else
		echo "There is no ship currently scheduled for deployment."
	fi
	
elif [ "$action" == "Rollback" ]
then
	if [ "$env" == "10.127.136.31" ]
	then
		sshpass -p "Trident123" ssh root@$env "bash -s" -- < $workspace/deploy_on_server.sh -r "$release" "$component" "$abort_on_fail" "app01"> $workspace/logs/"${logfile}"
		#sshpass -p "Trident123" ssh root@$env 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -r "$release" "$component" "$abort_on_fail" "app02" >> $workspace/logs/"${logfile}"
		if [ -f $workspace/logs/${logfile} ]
        then
        	cat $workspace/logs/${logfile}
        fi
	else
		#sshpass -p "not4dev!" ssh root@$env "bash -s" -- < $workspace/deploy_on_server.sh -r "$release" "$component" "$abort_on_fail" "app01"> $workspace/logs/"${logfile}"
		#sshpass -p "not4dev!" ssh root@$env 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -r "$release" "$component" "$abort_on_fail" "app02" >> $workspace/logs/"${logfile}"
		if [ -f $workspace/logs/${logfile} ]
        then
        	cat $workspace/logs/${logfile}
        fi
	fi
fi

} || { # catch
	echo "An exception occured in making ssh connections."
	exit 1

}
