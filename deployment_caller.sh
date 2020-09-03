#!/bin/bash

#Last modified : 8/31/2020

env=$1
release=$2
action=$3
component=$4
component=`echo $component | sed "s/ /_/g"`
workspace=$5
abort_on_fail=$6
transfer_flag=$7
ArtifactoryUser=$8
ArtifactoryPassword=$9
logfile='deployStage.log'

log(){
    #echo "$@" >&1 2>&1
    echo "$@" >> $workspace/logs/"${logfile}"
}

if [ -f $workspace/logs/email_body.txt ]
then
    rm -f $workspace/logs/email_body.txt
fi

{ #try
if [ "$action" == "Deploy" ] && [ "$transfer_flag" == "true" ]
then
    log "Transferring artifacts to the target server ( $env )"
    log
    if [ "$env" == "192.168.248.161" ]
    then
        sshpass -p "Carnival@123" ssh -o "StrictHostKeyChecking=no"  root@$env 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do if [ `echo ${folder} | grep "_" | wc -l` -eq 0 ]; then mv /root/Releases/${folder} /root/Releases/${folder}_`date +%Y_%m_%d__%H_%M_%S`; fi; done; fi'
        sshpass -p "Carnival@123" scp -o "StrictHostKeyChecking=no" -r $workspace/Releases/$release $workspace/tmp root@$env:/root/Releases
        #sshpass -p "Carnival@123" ssh -o "StrictHostKeyChecking=no" root@$env "ssh -tt app02 \" rm -rf /root/Releases \"" 2>/dev/null
        sshpass -p "Carnival@123" ssh -o "StrictHostKeyChecking=no" root@$env "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app01" "$transfer_flag" >> $workspace/logs/"${logfile}"
        #sshpass -p "Carnival@123" ssh -o "StrictHostKeyChecking=no" root@$env 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app02" "$transfer_flag" >> $workspace/logs/"${logfile}"
        
        if [ -f $workspace/logs/${logfile} ]
        then
            #cat $workspace/logs/${logfile}
            transfer_status=`grep "has not been transferred" $workspace/logs/${logfile} | wc -l`

            if [ $transfer_status -gt 0 ]
            then
                exit 125
            fi
        else
            log "ERROR : Log file not present at $workspace/logs/${logfile}"
            exit 1
        fi
    else
        sshpass -p "not4dev!" ssh  -o "StrictHostKeyChecking=no"  root@$env 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do if [ `echo ${folder} | grep "_" | wc -l` -eq 0 ]; then mv /root/Releases/${folder} /root/Releases/${folder}_`date +%Y_%m_%d__%H_%M_%S`; fi; done; fi'
        sshpass -p "not4dev!" scp  -o "StrictHostKeyChecking=no" -r $workspace/Releases/$release $workspace/tmp root@$env:/root/Releases
        #sshpass -p "not4dev!" ssh -o "StrictHostKeyChecking=no" root@$env "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app01" "$transfer_flag" >> $workspace/logs/"${logfile}"
        #sshpass -p "not4dev!" ssh -o "StrictHostKeyChecking=no" root@$env 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app02" "$transfer_flag" >> $workspace/logs/"${logfile}"
        
        if [ -f $workspace/logs/${logfile} ]
        then
            #cat $workspace/logs/${logfile}
            transfer_status=`grep "has not been transferred" $workspace/logs/${logfile} | wc -l`

            if [ $transfer_status -gt 0 ]
            then
                exit 125
            fi
        else
            log "ERROR : Log file not present at $workspace/logs/${logfile}"
            exit 1
        fi
        
    fi
elif [ "$action" == "Deploy" ] && [ "$transfer_flag" == "false" ]
then
    if [ "$env" == "192.168.248.161" ]
    then
        sshpass -p "Carnival@123" ssh -o "StrictHostKeyChecking=no"  root@$env 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else mv /root/Releases/tmp /root/Releases/tmp_`date +%Y_%m_%d__%H_%M_%S`; fi'
        sshpass -p "Carnival@123" scp -o "StrictHostKeyChecking=no" -r $workspace/Releases/$release $workspace/tmp
        sshpass -p "Carnival@123" ssh -o "StrictHostKeyChecking=no" root@$env "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app01" "$transfer_flag" >> $workspace/logs/"${logfile}"
        #sshpass -p "Carnival@123" ssh -o "StrictHostKeyChecking=no" root@$env 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app02" "$transfer_flag" >> $workspace/logs/"${logfile}"
        
        
        if [ -f $workspace/logs/${logfile} ]
        then
            #cat $workspace/logs/${logfile}
            transfer_status=`grep "has not been transferred" $workspace/logs/${logfile} | wc -l`

            if [ $transfer_status -gt 0 ]
            then
                exit 125
            fi
        else
            log "ERROR : Log file not present at $workspace/logs/${logfile}"
            exit 1
        fi
    else
        sshpass -p "not4dev!" ssh -o "StrictHostKeyChecking=no"  root@$env 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else mv /root/Releases/tmp /root/Releases/tmp_`date +%Y_%m_%d__%H_%M_%S`; fi'
        sshpass -p "not4dev!" scp -o "StrictHostKeyChecking=no" -r $workspace/Releases/$release $workspace/tmp
        #sshpass -p "not4dev!" ssh -o "StrictHostKeyChecking=no" root@$env "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app01" >> $workspace/logs/"${logfile}"
        #sshpass -p "not4dev!" ssh -o "StrictHostKeyChecking=no" root@$env 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app02" "$transfer_flag" >> $workspace/logs/"${logfile}"
        
        if [ -f $workspace/logs/${logfile} ]
        then
            #cat $workspace/logs/${logfile}
            transfer_status=`grep "has not been transferred" $workspace/logs/${logfile} | wc -l`

            if [ $transfer_status -gt 0 ]
            then
                exit 125
            fi
        else
            log "ERROR : Log file not present at $workspace/logs/${logfile}"
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
            ship_name=`echo $ship | cut -d: -f1`
            log
            log "Transferring artifacts to the target server ( $ipaddr )"
            log
            if [ "$ipaddr" == "192.168.248.161" ]
            then
                sshpass -p "Carnival@123" ssh -o "StrictHostKeyChecking=no"  root@$ipaddr 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do if [ `echo ${folder} | grep "_" | wc -l` -eq 0 ]; then mv /root/Releases/${folder} /root/Releases/${folder}_`date +%Y_%m_%d__%H_%M_%S`; fi; done; fi'
                sshpass -p "Carnival@123" scp -o "StrictHostKeyChecking=no" -r $workspace/Releases/$release $workspace/tmp root@$ipaddr:/root/Releases
                sshpass -p "Carnival@123" ssh -o "StrictHostKeyChecking=no" root@$ipaddr "bash -s" -- < $workspace/deploy_on_server.sh -t "$release" "$component" "$abort_on_fail" "app01" "$transfer_flag" >> $workspace/logs/"${logfile}"
                
            else
                sshpass -p "not4dev!" ssh  -o "StrictHostKeyChecking=no" -r root@$ipaddr 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do if [ `echo ${folder} | grep "_" | wc -l` -eq 0 ]; then mv /root/Releases/${folder} /root/Releases/${folder}_`date +%Y_%m_%d__%H_%M_%S`; fi; done; fi'
                sshpass -p "not4dev!" scp  -o "StrictHostKeyChecking=no" -r $workspace/Releases/$release $workspace/tmp root@$ipaddr:/root/Releases
                sshpass -p "not4dev!" ssh -o "StrictHostKeyChecking=no" root@$ipaddr "bash -s" -- < $workspace/deploy_on_server.sh -t "$release" "$component" "$abort_on_fail" "app01" "$transfer_flag" >> $workspace/logs/"${logfile}"
                
            fi

            if [ -f $workspace/logs/${logfile} ]
            then

                chksum_status=`grep "md5sum is not matching" $workspace/logs/${logfile} | wc -l`

                if [ $chksum_status -gt 0 ]
                then
                    log "Property setting not required as artifacts were not transferred properly."
                else
                    $workspace/checkArtifactProperty.sh "NA" "ScheduleDeploy" "$release" "$ArtifactoryUser" "$ArtifactoryPassword" "$ship_name" "$workspace" "NA"
                fi
            else
                log "ERROR : Failed in transfer of artifacts on $ship_name. md5sum was different for $component on ship when compared to confluece."
                exit 1
            fi
        done
    else
        log "There is no ship currently scheduled for deployment."
    fi

    if [ -f $workspace/logs/${logfile} ]
    then
        #cat $workspace/logs/${logfile}
        transfer_status=`grep "md5sum is not matching" $workspace/logs/${logfile} | wc -l`

        if [ $transfer_status -gt 0 ]
        then
            exit 125
        fi
    else
        log "ERROR : Log file not present at $workspace/logs/${logfile}"
        exit 1
    fi
    
elif [ "$action" == "Rollback" ]
then
    if [ "$env" == "192.168.248.161" ]
    then
        #sshpass -p "Carnival@123" ssh root@$env "bash -s" -- < $workspace/deploy_on_server.sh -r "$release" "$component" "$abort_on_fail" "app01"> $workspace/logs/"${logfile}"
        #sshpass -p "Carnival@123" ssh root@$env 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -r "$release" "$component" "$abort_on_fail" "app02" "$transfer_flag" >> $workspace/logs/"${logfile}"
        
        if [ -f $workspace/logs/${logfile} ]
        then
            cat $workspace/logs/${logfile}
        fi
    else
        #sshpass -p "not4dev!" ssh root@$env "bash -s" -- < $workspace/deploy_on_server.sh -r "$release" "$component" "$abort_on_fail" "app01"> $workspace/logs/"${logfile}"
        #sshpass -p "not4dev!" ssh root@$env 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -r "$release" "$component" "$abort_on_fail" "app02" "$transfer_flag" >> $workspace/logs/"${logfile}"
        
        if [ -f $workspace/logs/${logfile} ]
        then
            cat $workspace/logs/${logfile}
        fi
    fi
fi

if [ -f $workspace/logs/${logfile} ] && ([ "$action" == "Deploy" ] || [ "$action" == "Rollback" ])
then
    sed -n '/STATUS( app01 )/,/Checking if components/p' $workspace/logs/${logfile} >> $workspace/logs/email_body.txt
    sed -n '/STATUS( app02 )/,$p' $workspace/logs/${logfile} >> $workspace/logs/email_body.txt
    sed -i '/Transferring artifacts to app02/d' $workspace/logs/email_body.txt
    sed -i '/UTC 20/d' $workspace/logs/email_body.txt
    sed -i '/Checking if components are present/d' $workspace/logs/email_body.txt
fi

if [ -f $workspace/logs/"${logfile}" ]
then
    cat $workspace/logs/"${logfile}"
fi

} || { # catch
    log "ERROR : An exception occured in making ssh connections."
    exit 1

}