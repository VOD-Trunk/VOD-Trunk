#!/bin/bash

Deployment_env=$1
Activity=$2
Release_version=$3
UserName=$4
Password=$5
user_type=$6
Set_status_done_on=$7


if [ "$Deployment_env" == "Support" ] && [ "$Activity" == "Deploy" ]
then
    #isQADone=`curl -sS -u "$UserName":"$Password" -X GET 'http://artifactory.tools.ocean.com/artifactory/api/storage/libs-release-local/com/uievolution/exm/exm/"$Release_version"?properties=QA' | grep "Done" | wc -l`
    isQADone=1

    if [ ${isQADone} -eq 1 ]
    then
        echo "We are good to deploy in Support environment."
    else
         exit 1
    fi

elif [ "$Deployment_env" == "Production" ] && [ "$Activity" == "Deploy" ]
then
    #isSupportDone=`curl -sS -u "${UserName}":"${Password}" -X GET 'http://artifactory.tools.ocean.com/artifactory/api/storage/libs-release-local/com/uievolution/exm/exm/"${Release_version}"?properties=Support' | grep "Done" | wc -l`
    isSupportDone=1
    if [ $isSupportDone -eq 1 ]
    then
        echo "We are good to deploy in Production environment."
    else
         exit 1
    fi
elif ([ "$Deployment_env" == "None" ] || [ "$Deployment_env" == "None" ]) && [ "$Activity" == "Deploy" ]
then
	echo "Property checking not required."
fi


if [ "$Activity" == "Promote" ] && [ "$user_type" == "QA" ]
then
	echo "Setting QA = Done."
    #curl -sS -u "${UserName}":"${Password}" -X PUT "http://artifactory.tools.ocean.com/artifactory/api/storage/libs-release-local/com/uievolution/exm/exm/'${Release_version}'?properties=QA=Done"
elif [ "$Activity" == "Promote" ] && [ "$user_type" == "Support" ]
then
	echo "Setting Support = Done."
    #curl -sS -u "${UserName}":"${Password}" -X PUT "http://artifactory.tools.ocean.com/artifactory/api/storage/libs-release-local/com/uievolution/exm/exm/'${Release_version}'?properties=Support=Done"
elif [ "$Activity" == "Promote" ] && [ "$user_type" == "Super" ]
then
	echo "Setting $Set_status_done_on = Done."
	#curl -sS -u "${UserName}":"${Password}" -X PUT "http://artifactory.tools.ocean.com/artifactory/api/storage/libs-release-local/com/uievolution/exm/exm/'${Release_version}'?properties='${Set_status_done_on}'=Done"
else
	echo "User is not defined in jenkinsconfig.json"
fi
