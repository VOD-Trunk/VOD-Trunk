#!/bin/bash

#Last modified : 9/01/2020

Deployment_Env=$1
Activity=$2
ReleaseVersion=$3
ArtifactoryUser=$4
ArtifactoryPassword=$5
PromotingFrom=$6
JenkinsWorkspace=$7
LoginUser=$8
ship_name=$9
logfile=checkArtifactPropertyStage.log

log(){
    echo "$@" >&1 2>&1
    echo "$@" >> $JenkinsWorkspace/logs/"${logfile}"
}

export DateTimeStamp=$(date +%Y%m%d-%H%M)

UrlPart1="http://artifactory.tools.ocean.com/artifactory/api/storage"
urls=`cat $JenkinsWorkspace/tmp/urls.txt`
IFS=$'\n'
for row in $urls
do
    Component=`echo $row | cut -d '>' -f 1 | awk '{$1=$1};1'`
    UrlPart2=`echo $row | cut -d '>' -f 2 | awk '{$1=$1};1' | cut -d '/' -f5-`

    if [ "$Deployment_Env" == "SUPPORT" ] && [ "$Activity" == "Deploy" ]
    then
        isQADone=`curl -sS -u "$ArtifactoryUser":"$ArtifactoryPassword" -X GET ''${UrlPart1}/${UrlPart2}'?properties=QA_PROMOTION_TIME' | grep "QA_PROMOTION_TIME" | wc -l`
        
        if [ ${isQADone} -eq 1 ]
        then
            log
            log
            log "QA=Done is the property set on $Component of $ReleaseVersion"
            log
            log
            continue
        else
            log
            log
            log "ERROR : Testing not completed in QA environment for $Component of ${ReleaseVersion}. $ReleaseVersion is not ready to be deployed in Support setup."
            log
            log
            log `curl -sS -v -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X GET ''${UrlPart1}/${UrlPart2}'?properties=QA_PROMOTION_TIME'`
            exit 1
        fi

    elif [ "$Deployment_Env" == "PRODUCTION" ] && [ "$Activity" == "Deploy" ]
    then
        isProdDone=`curl -sS -u "$ArtifactoryUser":"$ArtifactoryPassword" -X GET ''${UrlPart1}/${UrlPart2}'?properties='${ship_name}'_DEPLOYMENT_TIME' | grep "${ship_name}_DEPLOYMENT_TIME" | wc -l`

        if [ $isProdDone -eq 1 ]
        then
            log
            log
            log "ERROR : The release $ReleaseVersion has already been deployed on ship $ship_name. Aborting build !!"
            log
            log
            exit 1
        else
             log
             log "Deployment of ${ReleaseVersion} is pending on $ship_name. Moving ahead..."
             log
        fi

        isSupportDone=`curl -sS -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X GET ''${UrlPart1}/${UrlPart2}'?properties=SUPPORT_PROMOTION_TIME' | grep "SUPPORT_PROMOTION_TIME" | wc -l`
        
        if [ $isSupportDone -eq 1 ]
        then
            log
            log
            log "Support=Done is the property set on $Component of $ReleaseVersion"
            log
            log
            continue
            #echo "We are good to deploy in Production environment."
        else
             log
             log
             log "ERROR : Deployment is not completed in Support environment for $Component of ${ReleaseVersion}. $ReleaseVersion is not ready to be deployed in Production."
             log
             log
             
             log `curl -sS -v -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X GET ''${UrlPart1}/${UrlPart2}'?properties=SUPPORT_PROMOTION_TIME'`
             exit 1
        fi
    # elif [ "$Deployment_Env" == "QA" ] && [ "$Activity" == "Deploy" ]
    # then
    #     isDevDone=`curl -sS -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X GET ''${UrlPart1}/${UrlPart2}'?properties=DEV_PROMOTION_TIME' | grep "DEV_PROMOTION_TIME" | wc -l`
        
    #     if [ $isDevDone -eq 1 ]
    #     then
    #         printf "\n\Development=Done is the property set on $Component of $ReleaseVersion\n\n"
    #         continue
    #     else
    #          printf "\n\nERROR : Deployment is not completed in Development environment for $Component of ${ReleaseVersion}. $ReleaseVersion is not ready to be deployed in QA.\n\n"
             
    #          echo `curl -sS -v -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X GET ''${UrlPart1}/${UrlPart2}'?properties=DEV_PROMOTION_TIME'`
    #          exit 1
    #     fi
    elif ([ "$Deployment_Env" == "QA" ] || [ "$Deployment_Env" == "NA" ] || [ "$Deployment_Env" == "DEV" ]) && [ "$Activity" == "Deploy" ]
    then
        log
        log
        log "Property checking not required."
        log
        log
    fi


    if [ "$Activity" == "Promote" ] && [ "$PromotingFrom" == "QA_TO_SUPPORT" ]
    then
        log
        log "Promoting $Component of $ReleaseVersion to Support Setup ..."
        log
        log
        curl -sS -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X PUT ''${UrlPart1}/${UrlPart2}'?properties=XS=Done;QA_PROMOTION_TIME='${DateTimeStamp}';QA_USER='${LoginUser}''
        isQADone=`curl -sS -u "$ArtifactoryUser":"$ArtifactoryPassword" -X GET ''${UrlPart1}/${UrlPart2}'?properties=QA_PROMOTION_TIME' | grep "QA_PROMOTION_TIME" | wc -l`
        log `curl -sS  -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X GET ''${UrlPart1}/${UrlPart2}'?properties=QA_PROMOTION_TIME'`
        if [ ${isQADone} -eq 1 ]
        then
            log
            log
            log "Successfully set property QA = Done on $Component of $ReleaseVersion"
            log
            log
        else
            log
            log
            log "Error in setting Property for QA environment for $Component of $ReleaseVersion. Please try again."
            log
            log
            continue
        fi

    elif [ "$Activity" == "Promote" ] && [ "$PromotingFrom" == "SUPPORT_TO_PROD" ]
    then
        log "Promoting $Component of $ReleaseVersion to Production ..."
        log
        isQADone=`curl -sS -u "$ArtifactoryUser":"$ArtifactoryPassword" -X GET ''${UrlPart1}/${UrlPart2}'?properties=QA_PROMOTION_TIME' | grep "QA_PROMOTION_TIME" | wc -l`
        if [ ${isQADone} -eq 1 ]
        then
            curl -sS -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X PUT ''${UrlPart1}/${UrlPart2}'?properties=SUPPORT=Done;SUPPORT_PROMOTION_TIME='${DateTimeStamp}';SUPPORT_USER='${LoginUser}''
            isSupportDone=`curl -sS -u "$ArtifactoryUser":"$ArtifactoryPassword" -X GET ''${UrlPart1}/${UrlPart2}'?properties=SUPPORT_PROMOTION_TIME' | grep "SUPPORT_PROMOTION_TIME" | wc -l`
            log `curl -sS -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X GET ''${UrlPart1}/${UrlPart2}'?properties=SUPPORT_PROMOTION_TIME'`
            if [ ${isSupportDone} -eq 1 ]
            then
                log
                log
                log "Successfully set property SUPPORT = Done on $Component of $ReleaseVersion"
                log
                log
            else
                log
                log
                log "ERROR : Error in setting Property SUPPORT=Done on $Component of $ReleaseVersion. Please try again."
                log
                log
                exit 1
            fi  
        else
            log
            log
            log "ERROR : $Component of $ReleaseVersion is not promoted in QA environment, can't be promoted directly from Support Environment to Production"
            log
            log
            exit 1
        fi

    elif [ "$Activity" == "Promote" ] && [ "$PromotingFrom" == "DEV_TO_QA" ]
    then
        log "ERROR : Promotion from DEV to QA is not supported at the moment."
        log
        log
        exit 1
    #     printf "Promoting $Component of $ReleaseVersion to QA ...\n\n"
    #     curl -sS -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X PUT ''${UrlPart1}/${UrlPart2}'?properties=DEV=Done;DEV_PROMOTION_TIME='${DateTimeStamp}';DEV_USER='${LoginUser}''
    #     isDevDone=`curl -sS -u "$ArtifactoryUser":"$ArtifactoryPassword" -X GET ''${UrlPart1}/${UrlPart2}'?properties=DEV_PROMOTION_TIME' | grep "DEV_PROMOTION_TIME" | wc -l`
    #     echo `curl -sS -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X GET ''${UrlPart1}/${UrlPart2}'?properties=DEV_PROMOTION_TIME'`
    #     if [ ${isDevDone} -eq 1 ]
    #     then
    #         printf "\n\nSuccessfully set property DEV = Done on $Component of $ReleaseVersion\n\n"
    #     else
    #         printf "\n\nERROR : Error in setting Property DEV=Done on $Component of $ReleaseVersion. Please try again.\n\n"
    #         exit 1
    #     fi

    elif [ "$Activity" == "Promote" ] && [ "$PromotingFrom" == "PRODUCTION" ] && [ "$Deployment_Env" == "PRODUCTION" ]
    then
        log "Setting ${ship_name}_deployment=Done property on the artifact ..."
        log
        log
        curl -sS -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X PUT ''${UrlPart1}/${UrlPart2}'?properties='${ship_name}'_deployment=Done;'${ship_name}'_DEPLOYMENT_TIME='${DateTimeStamp}';'${ship_name}'_USER='${LoginUser}''
        isProdDone=`curl -sS -u "$ArtifactoryUser":"$ArtifactoryPassword" -X GET ''${UrlPart1}/${UrlPart2}'?properties='${ship_name}'_DEPLOYMENT_TIME' | grep "${ship_name}_PROMOTION_TIME" | wc -l`
        log `curl -sS -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X GET ''${UrlPart1}/${UrlPart2}'?properties='${ship_name}'_DEPLOYMENT_TIME'`
        if [ ${isProdDone} -eq 1 ]
        then
            log
            log
            log "Successfully set property ${ship_name}_deployment=Done on $Component of $ReleaseVersion"
            log
            log
        else
            log
            log
            log "ERROR : Error in setting Property ${ship_name}_deployment=Done on $Component of $ReleaseVersion. Please try again."
            log
            log
            exit 1
        fi
    
    elif [ "$Activity" == "ScheduleDeploy" ]
    then
        log "Setting property ${PromotingFrom}_transfer = Done on $Component of $ReleaseVersion ..."
        log
        log
        curl -sS -u "${ArtifactoryUser}":"${ArtifactoryPassword}" -X PUT ''${UrlPart1}/${UrlPart2}'?properties='${PromotingFrom}'_transfer=Done;'${PromotingFrom}'_TRANSFER_TIME='${DateTimeStamp}''
        isTransferDone=`curl -sS -u "$ArtifactoryUser":"$ArtifactoryPassword" -X GET ''${UrlPart1}/${UrlPart2}'?properties='${PromotingFrom}'_TRANSFER_TIME' | grep "${PromotingFrom}_TRANSFER_TIME" | wc -l`
        log `curl -sS -u "$ArtifactoryUser":"$ArtifactoryPassword" -X GET ''${UrlPart1}/${UrlPart2}'?properties='${PromotingFrom}'_TRANSFER_TIME'`
        if [ ${isTransferDone} -eq 1 ]
        then
            log
            log
            log "Successfully set property ${PromotingFrom}_transfer = Done on $Component of $ReleaseVersion"
            log
            log
        else
            log
            log
            log "ERROR : Error in setting Property ${PromotingFrom}_transfer = Done on $Component of $ReleaseVersion. Please try again."
            log
            log
            exit 1
        fi
    fi 
done