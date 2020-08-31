#Last modified : 8/25/2020

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


logfile_path = workspace + '/logs/fetchBinaryStage.log'
with open(logfile_path, 'w') as logfile:

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
            log ("HTTP Query successful: Confluence page exists ::" +pageName)
            searchResult=json.loads(response.text)['results']

            if len(searchResult)==0:
                    errorValue=("Confluence Page does not exist:" +pageName)
                    log ("No Record found for URL:" + response.request.url)
                    exit(1)
            elif len(searchResult)==1:
                    log(json.dumps((json.loads(response.text)['results'][0]['id']), sort_keys=True, indent=4, separators=(",", ": ")))
                    contentID=searchResult[0]['id']
            else:
                    contentID =0
                    errorValue=("More then one record exist for page:",pageName)
                    log(response.text)

        else:
            log(response)
            errorValue=("HTTP request failed for page " ,pageName ,"reason:" ,response)
            log ("Confluence page not exist or other error::",url)

        return  (contentID,errorValue)

    # end of function //CheckConfluencePage



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
            log ("Confluence page not exist or other error::",url)
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
        log(len(subTable))
        for x in subTable:

            columnValue=TAG_RE.sub('', x)

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
            log ("Confluence page not exist or other error::",url)
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

            if recordCount%7 == 0:  
                    shipName.append(columnValue)
            elif recordCount%7== 1:
                    releasePage.append(columnValue)
            elif recordCount%7== 2:
                    releaseVersion.append(columnValue)
            elif recordCount%7== 3:
                    deploymentDate.append(columnValue)
            elif recordCount%7== 4:
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
    log("Today's date:", today)

    now = datetime.datetime.now()

    currentDate = now.strftime("%m/%d/%Y")

    partial_deploy = 2

    releasesPath = workspace + '/Releases/'
    newReleaseDir = releasesPath + relName

    if os.path.isdir(newReleaseDir) == True:
        shutil.rmtree(newReleaseDir)

    scheduled_ships_path = workspace + "/tmp/scheduled_ships.txt"

    if os.path.exists(scheduled_ships_path):
        with open(scheduled_ships_path, 'w') as f:
            f.truncate()

    builds_file_path = workspace + "/tmp/component_build_mapping.txt"

    if os.path.exists(builds_file_path):
        with open(builds_file_path, 'w') as f:
            f.truncate()

    url_file_path = workspace + "/tmp/urls.txt"

    if os.path.exists(url_file_path):
        with open(url_file_path, 'w') as f:
            f.truncate()

    log_path = 'logs'
    path = os.path.join(workspace,log_path)
    if os.path.isdir(path) != True:
        os.makedirs(path)
    else:
        folder = workspace + "/logs/deployment"
        if os.path.isdir(folder):
            for the_file in os.listdir(folder):
                file_path = os.path.join(folder, the_file)
                try:
                    if os.path.isfile(file_path):
                       os.unlink(file_path)
                except Exception as e:
                    log(e)

    tmp_path = 'tmp'
    path = os.path.join(workspace,tmp_path)
    if os.path.isdir(path) != True:
        os.makedirs(path)

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
        shipNamesFinal=[]
        if contentID == 0:
          log(errorValue)
        else:
          shipNames,releasePage,releaseVersion,deploymentDate,deploymentStatus =GetScheduleContentInformation(contentID,headers)
          for i, shipName in enumerate(shipNames):
            if i == 0 :
                continue
            if len(deploymentDate[i]) != 0:
                if action == "Deploy":
                    date_obj = datetime.datetime.strptime(deploymentDate[i], '%m/%d/%Y').strftime('%Y-%m-%d')
                    if date_obj == now.strftime('%Y-%m-%d'):
                        shipNamesFinal.append(shipName)
                elif action == "ScheduleDeploy":
                    date_time_obj = datetime.datetime.strptime(deploymentDate[i], '%m/%d/%Y')
                    if date_time_obj >= now:
                        shipNamesFinal.append(shipName)
                        jenkinsconfig_path = workspace + "/jenkinsconfig.json"
                        with open(jenkinsconfig_path) as f:
                            r = json.load(f)
                            ipaddr_json = ast.literal_eval(json.dumps(r))
                            if shipName == "XS":
                                ipaddr = ipaddr_json["jenkins"]["environments"]["QA"][shipName]
                            else:
                                ipaddr = ipaddr_json["jenkins"]["environments"]["PRODUCTION"][shipName]
                            log("\nShip " + shipName + " is ready for release deployment. Initiating transfer of artifacts to " + ipaddr)

                        with open(scheduled_ships_path, 'a+') as f:
                            f.write(shipName + ":" + ipaddr +"\n")
                    else:
                        log("\nShip " +shipName +" is not ready for release Deployment.")

    if action == "Deploy" or action == "Promote" or (action == "ScheduleDeploy" and len(shipNamesFinal) != 0):

        if action == "Deploy" and targetShipName not in shipNamesFinal:
            log("\n\nThe MW for deployment of " + relName + " on " + targetShipName + " is not scheduled for today.\n\n")
            exit(1)
        else:
        
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

            #Page ID to get the page details
            contentID=0
            pageName = pageNameRelease
            contentID,errorValue = CheckConfluencePage(pageName)
            if contentID ==0:
                    log(errorValue)
            else:
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
                            log("INFO--->  Selected component " + applicationName[index] + " is not a part of Release : " + relName)
                            continue

            if len(finalArtifactoryUrl) == 0:
                log("None of the selected components is a part of Release : " + relName)
                exit(1)

            log("\n\nFollowing are the artifacts in: " + relName + "\n\n")
            for key, value in finalArtifactoryUrl.items():
                    
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
                else:
                    continue


                log( componentConfluence + ' -> ' + url + '\n')

                path = os.path.join(newReleaseDir,component)
                if os.path.isdir(path) != True:
                    os.makedirs(path)
                            
                with open(url_file_path, 'a+') as f:
                    f.write(componentConfluence + " > " + url + "\n")

                target_path = releasesPath + relName + '/' + component + '/' + url.split("/")[-1]

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
    elif action == "Rollback":
        log("\n\nfetchBinary stage is not required for Rollback.\n\n")
    else:
        log("\n\nThere is no ship currently scheduled for deployment.\n\n")