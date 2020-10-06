#Last modified : 9/01/2020

import sys
import requests
from requests.auth import HTTPBasicAuth
import json
import re
import os
import shutil
import datetime
import ast

pageNameRelease = sys.argv[1]
relName = sys.argv[2]
action = sys.argv[3]
workspace = sys.argv[4]
components = sys.argv[5]
username = sys.argv[6]
password = sys.argv[7]
transfer_flag = sys.argv[8]
pageNameMW = sys.argv[9]
deploymentEnv = sys.argv[10]
targetShipName = sys.argv[11]

log_path = 'logs'
path = os.path.join(workspace,log_path)
if os.path.isdir(path) != True:
   os.makedirs(path)


logfile_path = workspace + '/logs/fetchBinaryStage.log'
with open(logfile_path, 'w+') as logfile:

    def log(text):
        print text
        logfile.write(text + "\n")

    def CheckConfluencePage(pageName):
        '''This function checks if the confluence page with pageName exists or not. If exists it returns the contentID.'''

        PARAMS=(('title',pageName),('spaceKey','MGLN'),('expand','history'))

        url = "https://carnival.atlassian.net/wiki/rest/api/content"
        contentID=0;
        errorValue=""
        response = requests.request(
           "GET",
           url,
           params=PARAMS,
           headers=headers,
        )
        log(response.request.url)

        if response.status_code == 200:
            log ("HTTP Query successful: Confluence page exists ::" + pageName)
            searchResult=json.loads(response.text)['results']

            if len(searchResult)==0:
                    errorValue=("Confluence Page does not exist:" + pageName)
                    log ("ERROR : No Record found for URL:" + response.request.url)
                    exit(1)
            elif len(searchResult)==1:
                    log(json.dumps((json.loads(response.text)['results'][0]['id']), sort_keys=True, indent=4, separators=(",", ": ")))
                    contentID=searchResult[0]['id']
            else:
                    contentID =0
                    errorValue=("More then one record exist for page:" + pageName)
                    log(response.text)

        else:
            log(response)
            errorValue=("HTTP request failed for page " + pageName  + "reason:"  + response)
            log ("Confluence page not exist or other error::" + url)

        return  (contentID,errorValue)

    # end of function //CheckConfluencePage

    def verifyConfluenceTable(ContentId,headers):
        '''This function is used to scrap through the confluence page and fetch different columns from the HTML table in that confluence page'''

        url = "https://carnival.atlassian.net/wiki/rest/api/content/" +str(ContentId) + "?expand=body.storage"

        response = requests.request(
           "GET",
           url,
           headers=headers
        )

        if response.status_code == 200:
            log ("Query successful:Confluence page exist")
        else:
            log(response)
            log ("ERROR : Confluence page not exist or other error::" + url)
            exit(1)

        searchString = response.text
        subTable = re.findall(r'<tr>(.+?)</tr>',searchString)
        recordCount=0
        columnCount=0
        
        TAG_RE = re.compile(r'<[^>]+>')
        for x in subTable:

            columnValue=TAG_RE.sub(' ', x)
            columnValue = columnValue.strip()
            
            if recordCount == 0:
                firstRowColumnNames = columnValue.split()
                if len(firstRowColumnNames) != 7:    #count of columns headers should be 7 fixed.
                    log("\n\nERROR : The table structure on confluence page is not correct. There should only be seven column headers and in this order : Component, Revision Number, Build #, TAG, Artifact, md5sum, Modified over baseline \n\n")
                    exit(1)

                tableHeaders=["Component","Revision Number","Build #","TAG","Artifact","md5sum","Modified over baseline"]
                #The column headers should only be the ones present in tableHeaders list and in that specific order.
                for i in range(7):
                    if firstRowColumnNames[i] != tableHeaders[i]:
                        log("\n\nERROR : The table structure on confluence page is not correct. The seven column headers should be in this order : Component, Revision Number, Build #, TAG, Artifact, md5sum, Modified over baseline \n\n")
                        exit(1)
                    else:
                        continue

            recordCount= recordCount + 1
        return("\nConfluence page validated successfully.\n")



    def GetContentInformation(ContentId,headers):
        '''This function is used to scrap through the confluence page and fetch different columns from the HTML table in that confluence page'''

        url = "https://carnival.atlassian.net/wiki/rest/api/content/" +str(ContentId) + "?expand=body.storage"

        response = requests.request(
           "GET",
           url,
           headers=headers
        )

        if response.status_code == 200:
            log ("Query successful:Confluence page exist")
        else:
            log(response)
            log ("ERROR : Confluence page not exist or other error::" + url)
            exit(1)

        searchString = response.text
        subTable = re.findall(r'<td>(.+?)</td>',searchString)
        recordCount=0
        columnCount=0
        applicationName=[]
        applicationVersion=[]
        applicationBuild=[]
        artifactoryUrl=[]
        confluence_md5sum=[]
        yesNo=[]
        test=[]
        TAG_RE = re.compile(r'<[^>]+>')
        for x in subTable:

            columnValue=TAG_RE.sub('', x)
            columnValue = columnValue.strip()                

            if recordCount%7 == 0:  #Ignore first record
                    applicationName.append(columnValue)
            elif recordCount%7== 1:
                    applicationVersion.append(columnValue)
            elif recordCount%7== 2:
                    applicationBuild.append(columnValue)
            elif recordCount%7== 4:
                    artifactoryUrl.append(columnValue)
            elif recordCount%7== 5:
                    confluence_md5sum.append(columnValue)
            elif recordCount%7== 6:
                    yesNo.append(columnValue)


            recordCount= recordCount + 1
        return (applicationName,applicationVersion,applicationBuild,artifactoryUrl,confluence_md5sum,yesNo)

    # end of function //GetContentInformation

    def GetScheduleContentInformation(ContentId,headers):

        url = "https://carnival.atlassian.net/wiki/rest/api/content/" +str(ContentId) + "?expand=body.storage"

        response = requests.request(
           "GET",
           url,
           headers=headers
        )

        if response.status_code == 200:
            log ("Query successful:Confluence page exist")
        else:
            log(response)
            log ("ERROR : Confluence page not exist or other error::" + url)
            exit(1)

        searchString = response.text
        subTable = re.findall(r'<td>(.+?)</td>',searchString)
        recordCount=0
        columnCount=0
        shipName=[]
        releasePage=[]
        releaseVersion=[]
        deploymentDate=[]
        deploymentStatus=[]

        TAG_RE = re.compile(r'<[^>]+>')
        for x in subTable:

            columnValue=TAG_RE.sub('', x)
            columnValue = columnValue.strip()
            if recordCount%5 == 0 and columnValue != "Ship-Name":  
                shipName.append(columnValue)
            elif recordCount%5== 1 and columnValue != "Release Path":
                releasePage.append(columnValue)
            elif recordCount%5== 2 and columnValue != "Release-Version":
                releaseVersion.append(columnValue)
            elif recordCount%5== 3 and columnValue != "Date":
                deploymentDate.append(columnValue)
            elif recordCount%5== 4 and columnValue != "Status":
                deploymentStatus.append(columnValue)


            recordCount= recordCount + 1
        return (shipName,releasePage,releaseVersion,deploymentDate,deploymentStatus)

    # end of function //GetScheduleContentInformation

    #Main script
    log("Starting...\n")

    headers = {
               "Accept": "application/json",
               "Content-Type": "application/json",
               "Authorization": "Basic ZGVlcGFrLnJvaGlsbGFAaHNjLmNvbTpkMnl0NWJ4TGdmcFA4cG93S3VsOUQyNTE="
              }

    today = datetime.date.today()

    now = datetime.datetime.now()

    currentDate = now.strftime("%m/%d/%Y")

    partial_deploy = 2

    scheduled_ships_path = workspace + "/tmp/scheduled_ships.txt"
    if os.path.exists(scheduled_ships_path):
        with open(scheduled_ships_path, 'w') as f:
            f.truncate()

    if action == "ScheduleDeploy" or action == "Deploy":
        #Page ID to get the page details
        contentID=0
        pageName = pageNameMW
        contentID,errorValue = CheckConfluencePage(pageName)
        shipNames=[]
        releasePage=[]
        releaseVersion=[]
        deploymentDate=[]
        deploymentStatus=[]
        shipNamesScheduled=[]
        releasePageScheduled=[]
        releaseVersionScheduled=[]
        if contentID == 0:
            log(errorValue)
        else:
            shipNames,releasePage,releaseVersion,deploymentDate,deploymentStatus =GetScheduleContentInformation(contentID,headers)
            
            for rls in releaseVersion:

                tmp_abs_path = os.path.join(workspace,'tmp')
                if os.path.isdir(path) != True:
                    os.makedirs(tmp_abs_path)

                tmp_rls_path = os.path.join(tmp_abs_path,rls)
                if os.path.isdir(tmp_rls_path) != True:
                    os.makedirs(tmp_rls_path)

                builds_file_hist = workspace + "/tmp/" + rls + "/component_build_mapping.txt"
                if os.path.exists(builds_file_hist):
                    with open(builds_file_hist, 'w') as f:
                        f.truncate()
                url_file_hist = workspace + "/tmp/" + rls + "/urls.txt"
                if os.path.exists(url_file_hist):
                    with open(url_file_hist, 'w') as f:
                        f.truncate()

            for i, shipName in enumerate(shipNames):

                if len(deploymentDate[i]) != 0:
                    if action == "Deploy":
                        date_obj = datetime.datetime.strptime(deploymentDate[i], '%m/%d/%Y').strftime('%Y-%m-%d')
                        if date_obj == now.strftime('%Y-%m-%d'):
                            shipNamesScheduled.append(shipName)
                    elif action == "ScheduleDeploy":
                        date_time_obj = datetime.datetime.strptime(deploymentDate[i], '%m/%d/%Y')
                        if date_time_obj >= now:
                            shipNamesScheduled.append(shipName)
                            releasePageScheduled.append(releasePage[i])
                            releaseVersionScheduled.append(releaseVersion[i])
                            jenkinsconfig_path = workspace + "/jenkinsconfig.json"
                            with open(jenkinsconfig_path) as f:
                                r = json.load(f)
                                ipaddr_json = ast.literal_eval(json.dumps(r))
                                if shipName == "XS" or shipName == "HSC_Test":
                                    ipaddr = ipaddr_json["jenkins"]["environments"]["QA"][0][shipName]
                                elif shipName == "SUPPORT":
                                    ipaddr = ipaddr_json["jenkins"]["environments"]["SUPPORT"][0][shipName]
                                else:
                                    ipaddr = ipaddr_json["jenkins"]["environments"]["PRODUCTION"][0][shipName]
                                log("\nShip " + shipName + " is ready for release deployment. Initiating transfer of artifacts to " + ipaddr)

                            with open(scheduled_ships_path, 'a+') as f:
                                f.write(shipName + ":" + ipaddr + ":" +  releaseVersion[i]+"\n")
                        else:
                            log("\nShip " +shipName +" is not ready for release Deployment.")

    scheduledReleaseDict={}
    if action == "ScheduleDeploy":
        scheduledReleaseDict = dict(zip(releaseVersionScheduled,releasePageScheduled))
    else:
        scheduledReleaseDict.update({relName:pageNameRelease})

  
    if action == "Deploy" or action == "Promote" or action == "Rollback" or (action == "ScheduleDeploy" and len(shipNamesScheduled) != 0):

        if action == "Deploy" and deploymentEnv == "PRODUCTION" and targetShipName not in shipNamesScheduled:
            log("\n\nERROR : The MW for deployment of " + relName + " on " + targetShipName + " is not scheduled for today.\n\n")
            exit(1)
        else:
            #Page ID to get the page details
            contentID=0
            for releaseName, pageName in scheduledReleaseDict.items():

                applicationName=[]
                applicationVersion=[]
                applicationBuild=[]
                yesNo=[]
                finalArtifactoryUrl={}
                component_md5sum_mapping={}
                component_build_mapping={}
                

                releaseComponents=[]
                releaseArtifactsUrl=[]
                releaseBuildNumbers=[]
                releaseArtifactMd5sum=[]

                releasesPath = workspace + '/Releases/'
                newReleaseDir = releasesPath + releaseName

                if os.path.isdir(newReleaseDir) == True:
                    shutil.rmtree(newReleaseDir)

                builds_file_path = workspace + "/tmp/" + releaseName + "/component_build_mapping.txt"
                url_file_path = workspace + "/tmp/" + releaseName + "/urls.txt"

                contentID,errorValue = CheckConfluencePage(pageName)
                log("Content id is " + contentID)
                if contentID ==0:
                    log(errorValue)
                else:
                    verificationResult= verifyConfluenceTable(contentID,headers)

                    log(verificationResult)

                    applicationName,applicationVersion,applicationBuild,artifactoryUrl,confluence_md5sum,yesNo =GetContentInformation(contentID,headers)

                if components == "All":
                    partial_deploy = 2
                else:
                    component_list = components.split(",")
                    partial_deploy = 1

                if partial_deploy == 2:
                    for index, element in enumerate(yesNo):
                            if element == "Y":
                                releaseComponents.append(applicationName[index])
                                releaseBuildNumbers.append(applicationBuild[index])
                                releaseArtifactsUrl.append(artifactoryUrl[index])
                                releaseArtifactMd5sum.append(confluence_md5sum[index])
                                finalArtifactoryUrl = dict(zip(releaseComponents,releaseArtifactsUrl))
                                component_build_mapping = dict(zip(releaseComponents,releaseBuildNumbers))
                                component_md5sum_mapping = dict(zip(releaseComponents,releaseArtifactMd5sum))
                else:
                    for index, element in enumerate(yesNo):
                            if element == "Y" and applicationName[index] in component_list:
                                releaseComponents.append(applicationName[index])
                                releaseBuildNumbers.append(applicationBuild[index])
                                releaseArtifactsUrl.append(artifactoryUrl[index])
                                releaseArtifactMd5sum.append(confluence_md5sum[index])
                                finalArtifactoryUrl = dict(zip(releaseComponents,releaseArtifactsUrl))
                                component_build_mapping = dict(zip(releaseComponents,releaseBuildNumbers))
                                component_md5sum_mapping = dict(zip(releaseComponents,releaseArtifactMd5sum))
                            elif element == "N" and applicationName[index] in component_list:
                                log("INFO--->  Selected component " + applicationName[index] + " is not a part of Release : " + releaseName)
                                continue

                if len(finalArtifactoryUrl) == 0:
                    log("ERROR : None of the selected components is a part of Release : " + releaseName)
                    exit(1)

                log("\n\nFollowing are the artifacts in: " + releaseName + "\n\n")
                for key, value in finalArtifactoryUrl.items():

                    if targetShipName in ["KODM","NADM","EUDM","WEDM","NSDM","NODM","VODM","ZUDM","OSDM","Ovation","Encore","Odyssey"]:
                        if key == "EXM Notification plugin":
                            continue
                        
                    componentConfluence = str(key)
                    url = str(value)
                    
                    if componentConfluence == "EXM V2":
                        component = "v2"
                    elif componentConfluence == "LeftNav":
                        component = "exm-client-leftnav2"
                    elif componentConfluence == "Admin Tool":
                        component = "exm-admin-tool"
                    elif componentConfluence == "Cruise Client":
                        component = "exm-client-cruise"
                    elif componentConfluence == "EXM Lite Client (Serial)":
                        component = "exm-client-lite"
                    elif componentConfluence == "Startup Client":
                        component = "exm-client-startup"
                    elif componentConfluence == "NACOS Listener":
                        component = "nacos"
                    elif componentConfluence == "LeftNav Signage":
                        component = "exm-client-leftnav2-signage"
                    elif componentConfluence == "Exm-v2-plugin-location (Location Services Plugin)":
                        component = "location"
                    elif componentConfluence == "Mute Daemon":
                        component = "mutedaemon"
                    elif componentConfluence == "EXM Diagnostic Application":
                        component = "exm-diagnostic-app"
                    elif componentConfluence == "EXM Diagnostic plugin":
                        component = "diagnostics"
                    elif componentConfluence == "EXM Notification plugin":
                        component = "notification-service"
                    elif componentConfluence == "Mute Status Service":
                        component = "mute"
                    elif componentConfluence == "DB":
                        component = "db-upgrade-dir"
                    elif componentConfluence == "UIEWowzaLib":
                        component = "UIEWowzaLib"
                    else:
                        continue


                    log( componentConfluence + ' -> ' + url + '\n')

                    path = os.path.join(newReleaseDir,component)
                    if os.path.isdir(path) != True:
                        os.makedirs(path)
                                
                    with open(url_file_path, 'a+') as f:
                        f.write(componentConfluence + " > " + url + "\n")

                    target_path = releasesPath + releaseName + '/' + component + '/' + url.split("/")[-1]

                    if (action == "Deploy" and transfer_flag == "true") or action == "ScheduleDeploy":

                        log("\nDownloading " + component +" ...\n")

                        response = requests.get(url, auth = HTTPBasicAuth(username,password), stream=True)
                        if response.status_code == 200:
                            with open(target_path, 'wb') as f:
                                f.write(response.raw.read())
                                log("File successfully stored at : " + target_path + "\n")
                        else:
                            log("Couldn't reach the provided url with response : "+ str(response.status_code) + "\n")
                            continue

                    with open(builds_file_path, 'a+') as f:
                        f.write(component + " : " + str(component_build_mapping[componentConfluence]) + " : " + str(component_md5sum_mapping[componentConfluence]) + "\n")
    else:
        log("\n\nThere is no ship currently scheduled for deployment.\n\n")