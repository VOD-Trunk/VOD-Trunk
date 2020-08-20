#!/bin/bash

Deployment_Env=$1
Activity=$2
ReleaseVersion=$3
ArtifactoryUser=$4
ArtifactoryPassword=$5
PromotingFrom=$6
JenkinsWorkspace=$7
LoginUser=$8

export DateTimeStamp=$(date +%Y%m%d-%H%M)

UrlPart1="http://artifactory.tools.ocean.com/artifactory/api/storage"
urls=`cat $JenkinsWorkspace/tmp/urls.txt`
IFS=$'\n'
printf "Current Date: $DateTimeStamp\n"
for row in $urls
do
    Component=`echo $row | cut -d '>' -f 1 | awk '{$1=$1};1'`
    UrlPart2=`echo $row | cut -d '>' -f 2 | awk '{$1=$1};1' | cut -d '/' -f5-`

    if [ "$Deployment_Env" == "SUPPORT" ] && [ "$Activity" == "Deploy" ]
    then
        isQADone=`curl -sS -u "$ArtifactoryUser":"$ArtifactoryPassword" -X GET ''${UrlPart1}/${UrlPart2}'?properties=QA_PROMOTION_TIME' | grep "QA_PROMOTION_TIME" | wc -l`
        #isQADone=1

        if [ ${isQADone} -eq 1 ]
        then
            printf "\n\nQA=Done is the property set on $Component of $ReleaseVersion\n\n"
            continue
            #echo "We are good to deploy in Support environment."
        else
            printf "\n\nTesting not completed in QA environment for $Component of ${ReleaseVersion}. $ReleaseVersion is not ready to be deployed in Support setup.\n\n"
            echo `curl -sS -v -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X GET ''${UrlPart1}/${UrlPart2}'?properties=QA_PROMOTION_TIME'`
            exit 1
        fi

    elif [ "$Deployment_Env" == "PRODUCTION" ] && [ "$Activity" == "Deploy" ]
    then
        isSupportDone=`curl -sS -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X GET ''${UrlPart1}/${UrlPart2}'?properties=SUPPORT_PROMOTION_TIME' | grep "SUPPORT_PROMOTION_TIME" | wc -l`
        #isSupportDone=1
        if [ $isSupportDone -eq 1 ]
        then
            printf "\n\nSupport=Done is the property set on $Component of $ReleaseVersion\n\n"
            continue
            #echo "We are good to deploy in Production environment."
        else
             printf "\n\nDeployment is not completed in Support environment for $Component of ${ReleaseVersion}. $ReleaseVersion is not ready to be deployed in Production.\n\n"
             
             echo `curl -sS -v -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X GET ''${UrlPart1}/${UrlPart2}'?properties=SUPPORT_PROMOTION_TIME'`
             exit 1
        fi
    elif [ "$Deployment_Env" == "QA" ] && [ "$Activity" == "Deploy" ]
    then
        isDevDone=`curl -sS -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X GET ''${UrlPart1}/${UrlPart2}'?properties=DEV_PROMOTION_TIME' | grep "DEV_PROMOTION_TIME" | wc -l`
        #isSupportDone=1
        if [ $isDevDone -eq 1 ]
        then
            printf "\n\Development=Done is the property set on $Component of $ReleaseVersion\n\n"
            continue
            #echo "We are good to deploy in Production environment."
        else
             printf "\n\nDeployment is not completed in Development environment for $Component of ${ReleaseVersion}. $ReleaseVersion is not ready to be deployed in QA.\n\n"
             
             echo `curl -sS -v -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X GET ''${UrlPart1}/${UrlPart2}'?properties=DEV_PROMOTION_TIME'`
             exit 1
        fi
    elif ([ "$Deployment_Env" == "NA" ] || [ "$Deployment_Env" == "DEV" ]) && [ "$Activity" == "Deploy" ]
    then
    	printf "\n\nProperty checking not required.\n\n"
    fi


    if [ "$Activity" == "Promote" ] && [ "$PromotingFrom" == "QA_TO_SUPPORT" ]
    then
    	  printf "\nPromoting $Component of $ReleaseVersion to Support Setup ...\n\n"
        curl -sS -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X PUT ''${UrlPart1}/${UrlPart2}'?properties=XS=Done;QA_PROMOTION_TIME='${DateTimeStamp}';QA_USER='${LoginUser}''
        isQADone=`curl -sS -u "$ArtifactoryUser":"$ArtifactoryPassword" -X GET ''${UrlPart1}/${UrlPart2}'?properties=QA_PROMOTION_TIME' | grep "QA_PROMOTION_TIME" | wc -l`
        echo `curl -sS  -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X GET ''${UrlPart1}/${UrlPart2}'?properties=QA_PROMOTION_TIME'`
      	if [ ${isQADone} -eq 1 ]
        then
           	printf "\n\nSuccessfully set property QA = Done on $Component of $ReleaseVersion\n\n"
        else
           	printf "\n\nError in setting Property for QA environment for $Component of $ReleaseVersion. Please try again.\n\n"
           	continue
        fi

    elif [ "$Activity" == "Promote" ] && [ "$PromotingFrom" == "SUPPORT_TO_PROD" ]
    then
    	  printf "Promoting $Component of $ReleaseVersion to Production ...\n\n"
        isQADone=`curl -sS -u "$ArtifactoryUser":"$ArtifactoryPassword" -X GET ''${UrlPart1}/${UrlPart2}'?properties=QA_PROMOTION_TIME' | grep "QA_PROMOTION_TIME" | wc -l`
      	if [ ${isQADone} -eq 1 ]
        then
            curl -sS -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X PUT ''${UrlPart1}/${UrlPart2}'?properties=SUPPORT=Done;SUPPORT_PROMOTION_TIME='${DateTimeStamp}';SUPPORT_USER='${LoginUser}''
          	isSupportDone=`curl -sS -u "$ArtifactoryUser":"$ArtifactoryPassword" -X GET ''${UrlPart1}/${UrlPart2}'?properties=SUPPORT_PROMOTION_TIME' | grep "SUPPORT_PROMOTION_TIME" | wc -l`
            echo `curl -sS -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X GET ''${UrlPart1}/${UrlPart2}'?properties=SUPPORT_PROMOTION_TIME'`
      		  if [ ${isSupportDone} -eq 1 ]
            then
             		printf "\n\nSuccessfully set property SUPPORT = Done on $Component of $ReleaseVersion\n\n"
          	else
             		printf "\n\nError in setting Property SUPPORT=Done on $Component of $ReleaseVersion. Please try again.\n\n"
            		exit 1
          	fi	
        else
            printf "\n\n$Component of $ReleaseVersion is not promoted in QA environment, can't be promoted directly from Support Environment to Production\n\n"
            exit 1
        fi

	  elif [ "$Activity" == "Promote" ] && [ "$PromotingFrom" == "DEV_TO_QA" ]
    then
   		  printf "Promoting $Component of $ReleaseVersion to QA ...\n\n"
        curl -sS -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X PUT ''${UrlPart1}/${UrlPart2}'?properties=DEV=Done;DEV_PROMOTION_TIME='${DateTimeStamp}';DEV_USER='${LoginUser}''
        isDevDone=`curl -sS -u "$ArtifactoryUser":"$ArtifactoryPassword" -X GET ''${UrlPart1}/${UrlPart2}'?properties=DEV_PROMOTION_TIME' | grep "DEV_PROMOTION_TIME" | wc -l`
        echo `curl -sS -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X GET ''${UrlPart1}/${UrlPart2}'?properties=DEV_PROMOTION_TIME'`
      	if [ ${isDevDone} -eq 1 ]
        then
            printf "\n\nSuccessfully set property DEV = Done on $Component of $ReleaseVersion\n\n"
        else
            printf "\n\nError in setting Property DEV=Done on $Component of $ReleaseVersion. Please try again.\n\n"
            exit 1
        fi	
    
    elif [ "$Activity" == "ScheduleDeploy" ]
    then
        printf "Setting property $PromotingFrom_transfer = Done on $Component of $ReleaseVersion ...\n\n"
        curl -sS -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X PUT ''${UrlPart1}/${UrlPart2}'?properties='${PromotingFrom}'_transfer=Done'
        isTransferDone=`curl -sS -u "$ArtifactoryUser":"$ArtifactoryPassword" -X GET ''${UrlPart1}/${UrlPart2}'?properties='${PromotingFrom}'_transfer=Done' | grep "${PromotingFrom}" | wc -l`
        echo `curl -sS -u "$ArtifactoryUser":"$ArtifactoryPassword" -X GET ''${UrlPart1}/${UrlPart2}'?properties='${PromotingFrom}'_transfer=Done'`
        if [ ${isTransferDone} -eq 1 ]
        then
            printf "\n\nSuccessfully set property $PromotingFrom_transfer = Done on $Component of $ReleaseVersion\n\n"
        else
            printf "\n\nError in setting Property $PromotingFrom_transfer = Done on $Component of $ReleaseVersion. Please try again.\n\n"
            exit 1
        fi
    fi 
done
