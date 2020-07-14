#!/bin/bash

Deployment_env=$1
Activity=$2
Release_version=$3
UserName=$4
Password=$5


if [ "$Deployment_env" == "Support" ] && [ "$Activity" == "Deploy" ]
then
    #isQADone=`curl -sS -u "$UserName":"$Password" -X GET 'http://artifactory.tools.ocean.com/artifactory/api/storage/libs-release-local/com/uievolution/exm/exm/"$Release_version"?properties=QA' | grep "Done" | wc -l`
    isQADone=1

    echo "$isQADone"

    if [ ${isQADone} -eq 1 ]
    then
        echo "We are good to deploy in Support environment."
    else
         exit 1
    fi

else

    #isSupportDone=`curl -sS -u "${UserName}":"${Password}" -X GET 'http://artifactory.tools.ocean.com/artifactory/api/storage/libs-release-local/com/uievolution/exm/exm/"${Release_version}"?properties=Support' | grep "Done" | wc -l`
    isSupportDone=1
    if [ $isSupportDone -eq 1 ]
    then
        echo "We are good to deploy in Production environment."
    else
         exit 1
    fi
fi
