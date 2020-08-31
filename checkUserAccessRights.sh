#!/bin/bash

#Last modified : 8/25/2020

LoginUser=$1
AllowedUsers=$2
Activity=$3
Deployment_Environment=$4
Promoting_From=$5
Promoting_From=`echo $Promoting_From |cut -d'_' -f1`
UserAccessEnv=$6
UserAllowedOperation=$7
logfile=checkUserAccessRights_stage.log

isUserListed=`echo "$AllowedUsers" | grep "$LoginUser" | wc -l`
isAllowedOperation=`echo "$UserAllowedOperation" | grep "$Activity" | wc -l`

log(){
    log "$@" >&1 2>&1
    log "$@" >> logs/${logfile}
}

log
log "Logged in user is : $LoginUser"
log

if [ "$isUserListed" -eq 1 ] 
then
    log "User exists, checking Allowed Operations..."
    log
else
    log "User ${LoginUser} does not exist in the list of users able to perform any operation on the xiCMS Jenkins Pipeline"
    log
    exit 1
fi

log "Allowed Operations for user $LoginUser are : $UserAllowedOperation"
log
log "Allowed access environments for user $LoginUser are : $UserAccessEnv"
log

if [ "$isAllowedOperation" -eq 1 ] 
then
    log "User has access rights to perform ${Activity} operation."
    log
else
    log "User ${LoginUser} is not allowed to perform ${Activity} on the xiCMS Jenkins Pipeline"
    log
    exit 1
fi  

if [ "$Activity" == "Promote" ]
then
    EnvAccess=`log "$UserAccessEnv" | grep "$Promoting_From" | wc -l`

    if [ "$EnvAccess" -eq 1 ]
    then
        log "User $LoginUser is allowed to perform $Activity operation in $Promoting_From"
        log
    else
        log "User $LoginUser is not allowed to perform $Activity operation in $Promoting_From environment of xiCMS using Jenkins pipeline."
        log
        exit 1
    fi
else
    EnvAccess=`log "$UserAccessEnv" | grep "$Deployment_Environment" | wc -l`

    if [ "$EnvAccess" -eq 1 ]
    then
        log "User $LoginUser is allowed to perform $Activity operation in $Deployment_Environment"
        log
    else
        log "User $LoginUser is not allowed to perform $Activity operation in $Deployment_Environment environment of xiCMS using Jenkins pipeline."
        log
        exit 1
    fi