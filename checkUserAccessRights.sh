#!/bin/bash

LoginUser=$1
AllowedUsers=$2
Activity=$3
Deployment_Environment=$4
Promoting_From=$5
Promoting_From=`echo $Promoting_From |cut -d'_' -f1`
UserAccessEnv=$6
UserAllowedOperation=$7

isUserListed=`echo "$AllowedUsers" | grep "$LoginUser" | wc -l`
isAllowedOperation=`echo "$UserAllowedOperation" | grep "$Activity" | wc -l`

printf "Logged in user is : $LoginUser"

if [ "$isUserListed" -eq 1 ] 
then
    printf "User exists, checking Allowed Operations..."
else
    printf "User ${LoginUser} does not exist in the list of users able to perform any operation on the xiCMS Jenkins Pipeline"
    exit 1
fi

echo "Allowed Operations for user $LoginUser are : $UserAllowedOperation"
echo "Allowed access environments for user $LoginUser are : $UserAccessEnv"

if [ "$isAllowedOperation" -eq 1 ] 
then
    printf "User has access rights to perform ${Activity} operation."
else
    printf "User ${LoginUser} is not allowed to perform ${Activity} on the xiCMS Jenkins Pipeline"
    exit 1
fi  

if [ "$Activity" == "Promote" ]
then
    EnvAccess=`echo "$UserAccessEnv" | grep "$Promoting_From" | wc -l`

    if [ "$EnvAccess" -eq 1 ]
    then
        printf "User $LoginUser is allowed to perform $Activity operation in $Promoting_From"
    else
        printf "User $LoginUser is not allowed to perform $Activity operation in $Promoting_From environment of xiCMS using Jenkins pipeline."
        exit 1
    fi
else
    EnvAccess=`echo "$UserAccessEnv" | grep "$Deployment_Environment" | wc -l`

    if [ "$EnvAccess" -eq 1 ]
    then
        printf "User $LoginUser is allowed to perform $Activity operation in $Deployment_Environment"
    else
        printf "User $LoginUser is not allowed to perform $Activity operation in $Deployment_Environment environment of xiCMS using Jenkins pipeline."
        exit 1
    fi
fi