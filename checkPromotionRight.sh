#!/bin/bash
UserAccessEnv=$1
LoginUser=$2
Activity=$3
Promoting_From=$4
CURRENT_ENV=`echo $Promoting_From |cut -d'_' -f1`
isUserAllowed=`echo ${UserAccessEnv} | grep ${CURRENT_ENV} | wc -l`
echo "user Allowed::${isUserAllowed}"
echo "CURRENT_ENV::${CURRENT_ENV}"
if [ $isUserAllowed -eq 1 ]
then
    echo "User $LoginUser is allowed to perform Promote operation in $Promoting_From"
else
    echo "User $LoginUser is not allowed to perform $Activity operation in $Promoting_From environment of xiCMS using Jenkins pipeline."
    exit 1
fi 
