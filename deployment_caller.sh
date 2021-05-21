#!/bin/bash

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
export pwd=${10}
shipName=${11}
serverPassword=`echo "$pwd" | base64 -d`

logfile='deployStage.log'

log(){
    #echo "$@" >&1 2>&1
    echo "$@" >> $workspace/logs/"${logfile}"
}

{ #try
if [ "$action" == "Deploy" ] && [ "$transfer_flag" == "true" ]
then
    log "Transferring artifacts to the target server ( "$shipName":"$env" )"
    
    if [ "$shipName" == "NTDM" ]
    then
    sshpass -p $serverPassword ssh  -o "StrictHostKeyChecking=no" root@$env -p 2220 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do if [ `echo ${folder} | grep "_" | wc -l` -eq 0 ]; then mv /root/Releases/${folder} /root/Releases/${folder}_`date +%Y_%m_%d__%H_%M_%S`; fi; done; fi'
    sshpass -p $serverPassword scp -o "StrictHostKeyChecking=no" -P 2220 -r $workspace/Releases/$release root@$env:/root/Releases
    sshpass -p $serverPassword scp -o "StrictHostKeyChecking=no" -P 2220 -r $workspace/tmp/$release root@$env:/root/Releases/tmp
    sshpass -p $serverPassword ssh -o "StrictHostKeyChecking=no" root@$env -p 2220 "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app01" "$transfer_flag" >> $workspace/logs/"${logfile}"
    sshpass -p $serverPassword ssh -o "StrictHostKeyChecking=no" root@$env -p 2220 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app02" "$transfer_flag" >> $workspace/logs/"${logfile}"
    
    else
   	
    sshpass -p $serverPassword ssh  -o "StrictHostKeyChecking=no" root@$env 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do if [ `echo ${folder} | grep "_" | wc -l` -eq 0 ]; then mv /root/Releases/${folder} /root/Releases/${folder}_`date +%Y_%m_%d__%H_%M_%S`; fi; done; fi'
    sshpass -p $serverPassword scp -o "StrictHostKeyChecking=no" -r $workspace/Releases/$release root@$env:/root/Releases
    sshpass -p $serverPassword scp -o "StrictHostKeyChecking=no" -r $workspace/tmp/$release root@$env:/root/Releases/tmp
    sshpass -p $serverPassword ssh -o "StrictHostKeyChecking=no" root@$env "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app01" "$transfer_flag" >> $workspace/logs/"${logfile}"
    sshpass -p $serverPassword ssh -o "StrictHostKeyChecking=no" root@$env 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app02" "$transfer_flag" >> $workspace/logs/"${logfile}" 
    
    fi
    
    if [ `grep "UIEWowzaLib" $workspace/tmp/$release/component_build_mapping.txt | wc -l` -eq 1 ]
    then
    	if [ "$shipName" == "NTDM" ]
        then
    	sshpass -p $serverPassword ssh -o "StrictHostKeyChecking=no" root@$env -p 2220 'ssh media01' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "UIEWowzaLib" "$abort_on_fail" "media01" "$transfer_flag" >> $workspace/logs/"${logfile}"
        sshpass -p $serverPassword ssh -o "StrictHostKeyChecking=no" root@$env -p 2220 'ssh media02' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "UIEWowzaLib" "$abort_on_fail" "media02" "$transfer_flag" >> $workspace/logs/"${logfile}"
    	else
        sshpass -p $serverPassword ssh -o "StrictHostKeyChecking=no" root@$env 'ssh media01' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "UIEWowzaLib" "$abort_on_fail" "media01" "$transfer_flag" >> $workspace/logs/"${logfile}"
        sshpass -p $serverPassword ssh -o "StrictHostKeyChecking=no" root@$env 'ssh media02' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "UIEWowzaLib" "$abort_on_fail" "media02" "$transfer_flag" >> $workspace/logs/"${logfile}"
    	fi
    fi
elif [ "$action" == "Deploy" ] && [ "$transfer_flag" == "false" ]
then
	if [ "$shipName" == "NTDM" ]
    then
    sshpass -p $serverPassword ssh -o "StrictHostKeyChecking=no" root@$env -p 2220 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else mv /root/Releases/tmp /root/Releases/tmp_`date +%Y_%m_%d__%H_%M_%S`; fi'
    sshpass -p $serverPassword scp -o "StrictHostKeyChecking=no" -P 2220 -r $workspace/tmp/$release root@$env:/root/Releases/tmp
    sshpass -p $serverPassword ssh -o "StrictHostKeyChecking=no" root@$env -p 2220 "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app01" "$transfer_flag" >> $workspace/logs/"${logfile}"
    sshpass -p $serverPassword ssh -o "StrictHostKeyChecking=no" root@$env -p 2220 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app02" "$transfer_flag" >> $workspace/logs/"${logfile}"
	
    else
    echo "inside  deploy caller "
    sshpass -p $serverPassword ssh -o "StrictHostKeyChecking=no"  root@$env 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else mv /root/Releases/tmp /root/Releases/tmp_`date +%Y_%m_%d__%H_%M_%S`; fi'
    sshpass -p $serverPassword scp -o "StrictHostKeyChecking=no" -r $workspace/tmp/$release root@$env:/root/Releases/tmp
    sshpass -p $serverPassword ssh -o "StrictHostKeyChecking=no" root@$env "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app01" "$transfer_flag" >> $workspace/logs/"${logfile}"
    sshpass -p $serverPassword ssh -o "StrictHostKeyChecking=no" root@$env 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "$component" "$abort_on_fail" "app02" "$transfer_flag" >> $workspace/logs/"${logfile}" 
   
   	fi
    
   if [ `grep "UIEWowzaLib" $workspace/tmp/$release/component_build_mapping.txt | wc -l` -eq 1 ]
    then
        if [ "$shipName" == "NTDM" ]
        then
    	sshpass -p $serverPassword ssh -o "StrictHostKeyChecking=no" root@$env -p 2220 'ssh media01' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "UIEWowzaLib" "$abort_on_fail" "media01" "$transfer_flag" >> $workspace/logs/"${logfile}"
        sshpass -p $serverPassword ssh -o "StrictHostKeyChecking=no" root@$env -p 2220 'ssh media02' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "UIEWowzaLib" "$abort_on_fail" "media02" "$transfer_flag" >> $workspace/logs/"${logfile}"
    	else
        sshpass -p $serverPassword ssh -o "StrictHostKeyChecking=no" root@$env 'ssh media01' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "UIEWowzaLib" "$abort_on_fail" "media01" "$transfer_flag" >> $workspace/logs/"${logfile}"
        sshpass -p $serverPassword ssh -o "StrictHostKeyChecking=no" root@$env 'ssh media02' "bash -s" -- < $workspace/deploy_on_server.sh -d "$release" "UIEWowzaLib" "$abort_on_fail" "media02" "$transfer_flag" >> $workspace/logs/"${logfile}"
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
            if [ "$ship_name" == "XS" ]
            then
            	serverPassword="#0veAdmn!!"	
            fi
            relName=`echo $ship | cut -d: -f3`
            transferAction=`echo $ship | cut -d: -f4`
            if [ "$transferAction" != "Force" ]
            then
                log "Checking if transfer of artifacts is done already for $ship_name"
                $workspace/checkArtifactProperty.sh "NA" "checkTransferStatus" "$relName" "$ArtifactoryUser" "$ArtifactoryPassword" "$ship_name" "$workspace" "NA"
                if [ $? -eq 0 ]
                then
                    :
                else
                    log "Artifacts have already been transferred to $ship_name. Moving ahead."

                    if [ -f $workspace/logs/checkArtifactPropertyStage.log ]
                    then
                        cat $workspace/logs/checkArtifactPropertyStage.log
                    fi

                    continue
                fi
            fi
            log
            log "Transferring artifacts to the target server ( $ship_name:$ipaddr )"
            log
            #ship_name extracted from MW schedule,not using the parameter passed to called Deployment_caller
            if [ "$ship_name" == "NTDM" ]
            then
            sshpass -p $serverPassword ssh  -o StrictHostKeyChecking=no root@$ipaddr -p 2220 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do if [ `echo ${folder} | grep "_" | wc -l` -eq 0 ]; then mv /root/Releases/${folder} /root/Releases/${folder}_`date +%Y_%m_%d__%H_%M_%S`; fi; done; fi'
            sshpass -p $serverPassword scp -o StrictHostKeyChecking=no -P 2220 -r $workspace/Releases/$relName root@$ipaddr:/root/Releases
            sshpass -p $serverPassword scp -o StrictHostKeyChecking=no -P 2220 -r $workspace/tmp/$relName root@$ipaddr:/root/Releases/tmp
            sshpass -p $serverPassword ssh -o StrictHostKeyChecking=no root@$ipaddr -p 2220 "bash -s" -- < $workspace/deploy_on_server.sh -t "$relName" "$component" "$abort_on_fail" "app01" "$transfer_flag" >> $workspace/logs/"${logfile}"
			
            else
            
            sshpass -p $serverPassword ssh  -o "StrictHostKeyChecking=no" root@$ipaddr 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do if [ `echo ${folder} | grep "_" | wc -l` -eq 0 ]; then mv /root/Releases/${folder} /root/Releases/${folder}_`date +%Y_%m_%d__%H_%M_%S`; fi; done; fi'
            sshpass -p $serverPassword scp -o "StrictHostKeyChecking=no" -r $workspace/Releases/$relName root@$ipaddr:/root/Releases
            sshpass -p $serverPassword scp -o "StrictHostKeyChecking=no" -r $workspace/tmp/$relName root@$ipaddr:/root/Releases/tmp
            sshpass -p $serverPassword ssh -o "StrictHostKeyChecking=no" root@$ipaddr "bash -s" -- < $workspace/deploy_on_server.sh -t "$relName" "$component" "$abort_on_fail" "app01" "$transfer_flag" >> $workspace/logs/"${logfile}"
			
            fi
            
            if [ -f $workspace/logs/"${logfile}" ]
            then

                chksum_status=`grep "md5sum is not matching" $workspace/logs/${logfile} | wc -l`

                if [ $chksum_status -gt 0 ]
                then
                    log "Property setting not required as artifacts were not transferred properly."
                else
                    $workspace/checkArtifactProperty.sh "NA" "ScheduleDeploy" "$relName" "$ArtifactoryUser" "$ArtifactoryPassword" "$ship_name" "$workspace" "NA"

                    if [ -f $workspace/logs/checkArtifactPropertyStage.log ]
                    then
                        cat $workspace/logs/checkArtifactPropertyStage.log
                    fi
                fi
            else
                log "ERROR : Failed in transfer of artifacts on $ship_name. md5sum was different for $component on ship when compared to confluece."
                cat $workspace/logs/"${logfile}"
                exit 1
            fi
        done
    else
        log "There is no ship currently scheduled for deployment."
    fi

    if [ -f $workspace/logs/"${logfile}" ]
    then
        transfer_status=`grep "md5sum is not matching" $workspace/logs/${logfile} | wc -l`

        if [ $transfer_status -gt 0 ]
        then
            cat $workspace/logs/"${logfile}"
            exit 125
        fi
    else
        log "ERROR : Log file not present at $workspace/logs/${logfile}"
        cat $workspace/logs/"${logfile}"
        exit 1
    fi
    
elif [ "$action" == "Rollback" ]
then
	if [ "$shipName" == "NTDM" ]
    
    then
    
    sshpass -p $serverPassword scp -o "StrictHostKeyChecking=no" -P 2220 -r $workspace/tmp/$release root@$ipaddr:/root/Releases/tmp
    sshpass -p $serverPassword ssh -P 2220 root@$ipaddr "bash -s" -- < $workspace/deploy_on_server.sh -r "$release" "$component" "$abort_on_fail" "app01"> $workspace/logs/"${logfile}"
    sshpass -p $serverPassword ssh -P 2220 root@$ipaddr 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -r "$release" "$component" "$abort_on_fail" "app02" "$transfer_flag" >> $workspace/logs/"${logfile}"
	
    else
    
    sshpass -p $serverPassword scp -o "StrictHostKeyChecking=no" -r $workspace/tmp/$release root@$env:/root/Releases/tmp
    sshpass -p $serverPassword ssh root@$env "bash -s" -- < $workspace/deploy_on_server.sh -r "$release" "$component" "$abort_on_fail" "app01"> $workspace/logs/"${logfile}"
    sshpass -p $serverPassword ssh root@$env 'ssh app02' "bash -s" -- < $workspace/deploy_on_server.sh -r "$release" "$component" "$abort_on_fail" "app02" "$transfer_flag" >> $workspace/logs/"${logfile}"
	
    fi
    
fi

if [ -f $workspace/logs/${logfile} ] && ([ "$action" == "Deploy" ] || [ "$action" == "Rollback" ])
then
    sed -n '/STATUS( app01 )/,/Checking if components/p' $workspace/logs/${logfile} >> $workspace/logs/email_body.txt
    echo >> $workspace/logs/email_body.txt

    mediaCount=`grep "STATUS( media01 )" $workspace/logs/${logfile} | wc -l`
    if [ $mediaCount -eq 1 ]
    then
        sed -n '/STATUS( app02 )/,/Checking if components/p' $workspace/logs/${logfile} >> $workspace/logs/email_body.txt
        echo >> $workspace/logs/email_body.txt
        sed -n '/STATUS( media01 )/,/Checking if components/p' $workspace/logs/${logfile} >> $workspace/logs/email_body.txt
        echo >> $workspace/logs/email_body.txt
        sed -n '/STATUS( media02 )/,$p' $workspace/logs/${logfile} >> $workspace/logs/email_body.txt
    else
        sed -n '/STATUS( app02 )/,$p' $workspace/logs/${logfile} >> $workspace/logs/email_body.txt
    fi
    sed -i '/Transferring artifacts to app02/d' $workspace/logs/email_body.txt
    sed -i '/Transferring tmp folder to app02 and media servers.../d' $workspace/logs/email_body.txt
    sed -i '/UTC 20/d' $workspace/logs/email_body.txt
    sed -i '/Checking if components are present/d' $workspace/logs/email_body.txt
fi

if [ -f $workspace/logs/${logfile} ]
then
    transfer_status=`grep "has not been transferred" $workspace/logs/${logfile} | wc -l`
    abort_status=`grep "Aborting mission" $workspace/logs/${logfile} | wc -l`
    dbUpgradeStatus=`grep "DB upgrade was unsuccessful" $workspace/logs/${logfile} | wc -l`
    chksum_status=`grep "md5sum is not matching" $workspace/logs/${logfile} | wc -l`
    dbbackupStatus=`grep "DB backup failed" $workspace/logs/${logfile} | wc -l`

    if [ $transfer_status -gt 0 ] || [ $abort_status -gt 0 ] || [ $dbUpgradeStatus -gt 0 ] || [ $chksum_status -gt 0 ] || [ $dbbackupStatus -gt 0 ]
    then
        if [ -f $workspace/logs/"${logfile}" ]
        then
            cat $workspace/logs/"${logfile}"
        fi
        exit 1
    fi
else
    log "ERROR : Log file not present at $workspace/logs/${logfile}"
    exit 1
fi

if [ -f $workspace/logs/"${logfile}" ]
then
    cat $workspace/logs/"${logfile}"
fi

} || { # catch
    log "ERROR : An exception occured in making ssh connections."
    exit 1

}
