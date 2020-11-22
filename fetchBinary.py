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
loginUser = sys.argv[12]
allowedUsers = sys.argv[13]
promotingFrom = sys.argv[14]
userAccessEnv = sys.argv[15]
userAllowedOperation = sys.argv[16]
task = sys.argv[17]
pageNameConfig = sys.argv[18]

path = os.path.join(workspace,'logs')
if os.path.isdir(path) != True:
    os.makedirs(path)
else:
    directory = workspace + '/logs/'
    for the_file in os.listdir(directory):
        file_path = os.path.join(directory, the_file)
        try:
            if os.path.isfile(file_path):
                os.unlink(file_path)
        except Exception as e:
            print(e)


logfile_path = workspace + '/logs/' + task + 'Stage.log'
with open(logfile_path, 'w+') as logfile:

    def log(text):
        print text
        logfile.write(text + "\n")

    def checkUserAccessRights():

        if loginUser in allowedUsers:
            log("User exists, checking Allowed Operations...")
        else:
            log("ERROR : User " + loginUser + " does not exist in the list of users able to perform any operation on the xiCMS Jenkins Pipeline")

        log("Allowed Operations for user " + loginUser + " are : " + userAllowedOperation)
        log("Allowed access environments for user " + loginUser + " are : " + userAccessEnv)

        if action in userAllowedOperation:
            log("User has access rights to perform " + action + " operation.")
        else:
            log("ERROR : User " + loginUser + " is not allowed to perform " + action + " on the xiCMS Jenkins Pipeline")

        promotingFromEnv  = promotingFrom.split('_')

        if action == "Promote":
            environment = promotingFromEnv[0]
        else:
            environment = deploymentEnv
        
        if environment in userAccessEnv:
            log("User " + loginUser + " is allowed to perform " + action + " operation in " + environment)
        else:
            log("ERROR : User " + loginUser + " is not allowed to perform " + action + " operation in " + environment + " environment of xiCMS using Jenkins pipeline.")

    # end of function checkUserAccessRights()

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

    def verifyConfluencePage(ContentId,headers,pageType):
        '''This function is used to validate all the column header names on the release confluence page.'''

        url = "https://carnival.atlassian.net/wiki/rest/api/content/" +str(ContentId) + "?expand=body.storage"

        response = requests.request(
        "GET",
        url,
        headers=headers
        )

        if response.status_code == 200:
            log ("Query successful:Confluence page exists")
        else:
            log(response)
            log ("ERROR : Confluence page does not exist or other error::" + url)
            exit(1)

        searchString = response.text
        subTable = re.findall(r'<tr>(.+?)</tr>',searchString)
        
        
        TAG_RE = re.compile(r'<[^>]+>')

        columnValue=TAG_RE.sub('  ', subTable[0])
        columnValue = columnValue.strip()

        firstRowColumnNames = re.split(r'\s{2,}', columnValue)

        if pageType == "Release":

            if len(firstRowColumnNames) != 7:    #count of columns headers on release page should be 7 fixed.
                log("ERROR : The table structure on release confluence page is not correct. There should be exactly seven column headers and in this order : Component, Revision Number, Build #, TAG, Artifact, md5sum, Modified over baseline")
                exit(1)

            tableHeaders=["Component","Revision Number","Build #","TAG","Artifact","md5sum","Modified over baseline"]
            #The column headers should only be the ones present in tableHeaders list and in that specific order.
            for i in range(7):
                if firstRowColumnNames[i] != tableHeaders[i]:
                    log("ERROR : The table structure on release confluence page is not correct. The seven column headers should have names and order as : Component, Revision Number, Build #, TAG, Artifact, md5sum, Modified over baseline")
                    exit(1)
                else:
                    continue

        elif pageType == "MW":

            if len(firstRowColumnNames) != 5:    #count of columns headers on MW page should be 5 fixed.
                log("ERROR : The table structure on MW confluence page is not correct. There should be exactly five column headers and in this order : Ship-Name, Release Path, Release-Version, Date(MM/DD/YYYY), Action")
                exit(1)

            tableHeaders=["Ship-Name","Release Path","Release-Version","Date(MM/DD/YYYY)","Action"]
            #The column headers should only be the ones present in tableHeaders list and in that specific order.
            for i in range(5):
                if firstRowColumnNames[i] != tableHeaders[i]:
                    log("ERROR : The table structure on MW confluence page is not correct. The five column headers should have names and order as : Ship-Name, Release Path, Release-Version, Date(MM/DD/YYYY), Action")
                    exit(1)
                else:
                    continue
        elif pageType == "Config":

            if len(firstRowColumnNames) != 5:    #count of columns headers on Config Changes page should be 5 fixed.
                log("ERROR : The table structure on Config Changes confluence page is not correct. There should be exactly five column headers and in this order : File-Name, File-Path, Server, Release-Version, Group")
                exit(1)

            tableHeaders=["File-Name", "File-Path", "Server", "Release-Version", "Group"]
            #The column headers should only be the ones present in tableHeaders list and in that specific order.
            for i in range(5):
                if firstRowColumnNames[i] != tableHeaders[i]:
                    log("ERROR : The table structure on Config Changes confluence page is not correct. The five column headers should have names and order as : File-Name, File-Path, Server, Release-Version, Group")
                    exit(1)
                  else:
                       continue
        elif pageType == "Config_Deployment_Schedule":
            if len(firstRowColumnNames) != 3:    #count of columns headers on Config Changes page should be 5 fixed.
                log("ERROR : The table structure on Config Changes confluence page is not correct. There should be exactly five column headers and in this order : File-Name, File-Path, Server, Release-Version, Group")
                exit(1)

            tableHeaders=["Ship-Name", "Date(MM/DD/YYYY)", "Comment"]
            #The column headers should only be the ones present in tableHeaders list and in that specific order.
            for i in range(3):
                if firstRowColumnNames[i] != tableHeaders[i]:
                    log("ERROR : The table structure on Config Changes confluence page is not correct. The five column headers should have names and order as : File-Name, File-Path, Server, Release-Version, Group")
                    exit(1)
                else:
                    continue
                    
        else:
            log("ERROR : Wrong input for pageType.")

        return("Confluence page validated successfully.")

    # end of function //verifyConfluencePage

    def GetContentInformation(ContentId,headers):
        '''This function is used to scrap through the confluence page and fetch different columns from the HTML table in that confluence page'''

        url = "https://carnival.atlassian.net/wiki/rest/api/content/" +str(ContentId) + "?expand=body.storage"

        response = requests.request(
        "GET",
        url,
        headers=headers
        )

        if response.status_code == 200:
            log ("Query successful:Confluence page exists")
        else:
            log(response)
            log ("ERROR : Confluence page does not exist or other error::" + url)
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


            if recordCount < 7:
                recordCount= recordCount + 1
                continue
            elif recordCount%7 == 0:  #Ignore first record
                applicationName.append(columnValue)
            elif recordCount%7== 1:
                applicationVersion.append(columnValue)
            elif recordCount%7== 2:
                applicationBuild.append(columnValue)
            elif recordCount%7== 4:
                artifactoryUrl.append(columnValue)
            elif recordCount%7== 5:
                confluence_md5sum.append(columnValue[:32])
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
            log ("Query successful:Confluence page exists")
        else:
            log(response)
            log ("ERROR : Confluence page does not exist or other error::" + url)
            exit(1)

        searchString = response.text
        subTable = re.findall(r'<td>(.+?)</td>',searchString)
        recordCount=0
        columnCount=0
        shipName=[]
        releasePage=[]
        releaseVersion=[]
        deploymentDate=[]
        transferAction=[]

        TAG_RE = re.compile(r'<[^>]+>')
        for x in subTable:

            columnValue=TAG_RE.sub('', x)
            columnValue = columnValue.strip()

            if recordCount < 5:
                recordCount= recordCount + 1
                continue
            if recordCount%5 == 0:  
                shipName.append(columnValue)
            elif recordCount%5== 1:
                releasePage.append(columnValue)
            elif recordCount%5== 2:
                releaseVersion.append(columnValue)
            elif recordCount%5== 3:
                deploymentDate.append(columnValue)
            elif recordCount%5== 4:
                transferAction.append(columnValue)


            recordCount= recordCount + 1
        return (shipName,releasePage,releaseVersion,deploymentDate,transferAction)

    # end of function //GetScheduleContentInformation


    def GetConfigChanges(ContentId,headers,releaseVersionScheduled):

        url = "https://carnival.atlassian.net/wiki/rest/api/content/" +str(ContentId) + "?expand=body.storage"

        response = requests.request(
        "GET",
        url,
        headers=headers
        )

        if response.status_code == 200:
            log ("Query successful:Confluence page exists")
        else:
            log(response)
            log ("ERROR : Confluence page does not exist or other error::" + url)
            exit(1)

        searchString = response.text
        subTable = re.findall(r'<td>(.+?)</td>',searchString)
        recordCount=0
        columnCount=0
        configFileNames=[]
        configFilePaths=[]
        configServerNames=[]
        configReleaseVersions = []
        configGroups = []      
        
        
        serverNames = []
        fileNames = []
        releaseVersions = []
        filePaths = []

        TAG_RE = re.compile(r'<[^>]+>')
        for x in subTable:

            columnValue=TAG_RE.sub('', x)
            columnValue = columnValue.strip()

            if recordCount < 5:
                recordCount= recordCount + 1
                continue
            if recordCount%5 == 0:  
                configFileNames.append(columnValue)
            elif recordCount%5== 1:
                configFilePaths.append(columnValue)
            elif recordCount%5== 2:
                configServerNames.append(columnValue)
            elif recordCount%5== 3:
                configReleaseVersions.append(columnValue)
            elif recordCount%5== 4:
                configGroups.append(columnValue)

            recordCount= recordCount + 1
                
        for i, configReleaseVersion in enumerate(configReleaseVersions):
            if configReleaseVersion in releaseVersionScheduled:
                serverNames.append(configServerNames[i])
                fileNames.append(configFileNames[i])
                releaseVersions.append(configReleaseVersion)
                filePaths.append(configFilePaths[i])

        return (releaseVersions,serverNames,fileNames,filePaths)

    # end of function GetConfigChanges()

    def GetConfigSchedule(ContentId,headers,releaseVersionScheduled):

        url = "https://carnival.atlassian.net/wiki/rest/api/content/" +str(ContentId) + "?expand=body.storage"

        response = requests.request(
        "GET",
        url,
        headers=headers
        )

        if response.status_code == 200:
            log ("Query successful:Confluence page exists")
        else:
            log(response)
            log ("ERROR : Confluence page does not exist or other error::" + url)
            exit(1)

        searchString = response.text
        subTable = re.findall(r'<td>(.+?)</td>',searchString)
        recordCount=0
        columnCount=0
        ship-name=[]
        Date=[]
        comment=[]

        TAG_RE = re.compile(r'<[^>]+>')
        for x in subTable:

            columnValue=TAG_RE.sub('', x)
            columnValue = columnValue.strip()

            if recordCount < 3:
                recordCount= recordCount + 1
                continue
            if recordCount%3 == 0:  
                ship-name.append(columnValue)
            elif recordCount%3== 1:
                Date.append(columnValue)
            elif recordCount%3== 2:
                comment.append(columnValue)

            recordCount= recordCount + 1
     return (ship-name,Date,comment)

           # end of function //GetScheduleContentInformation
    
    # def findIpAddress(env_dict, shipName):
    #     for environment in env_dict.keys():
    #         for group in env_dict[environment][0].keys():
    #             if shipName in env_dict[environment][0][group].keys():
    #                 ipaddr = env_dict[environment][0][group][shipName]
    #                 serverPass = env_dict[environment][1]["pwd"]
    #                 return (ipaddr, serverPass)
    #             else:
    #                 continue
    #     return ("None","None")

    # # end of function findIpAddress()

    def findIpAddress(env_dict, shipName):
        for environment, groupList in env_dict.items():
            for group, ships in groupList[0].items():
                if shipName in ships.keys():
                    ipaddr = ships[shipName]
                    serverPass = groupList[1]["pwd"]
                    return (ipaddr, serverPass)
                else:
                    continue
        return ("None","None")

    # end of function findIpAddress()

    
    #Main script
    log("Starting...\n")

    if task == "checkUserAccessRights":
        checkUserAccessRights()

    elif task == "fetchBinary":

        headers = {
                "Accept": "application/json",
                "Content-Type": "application/json",
                "Authorization": "Basic ZGVlcGFrLnJvaGlsbGFAaHNjLmNvbTpkMnl0NWJ4TGdmcFA4cG93S3VsOUQyNTE="
                }

        today = datetime.date.today()

        now = datetime.datetime.now()

        currentDate = now.strftime("%m/%d/%Y")

        deploymentType = "DEPLOY_ALL"

        scheduled_ships_path = workspace + "/tmp/scheduled_ships.txt"
        if os.path.exists(scheduled_ships_path):
            with open(scheduled_ships_path, 'w') as f:
                f.truncate()
        
        jenkinsconfig_path = workspace + "/jenkinsconfig.json"
        with open(jenkinsconfig_path) as f:
            r = json.load(f)
            config_json = ast.literal_eval(json.dumps(r))

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
            serverNames = []
            fileNames = []
            ship-name = []
            Date = []
            
            if contentID == 0:
                log(errorValue)
            else:
                verificationResult= verifyConfluencePage(contentID,headers,"MW")
                log(verificationResult)
                shipNames,releasePage,releaseVersion,deploymentDate,transferAction =GetScheduleContentInformation(contentID,headers)
                
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
                    config_files_hist = workspace + "/tmp/" + rls + "/config_path_mapping.txt"
                    if os.path.exists(config_files_hist):
                        with open(config_files_hist, 'w') as f:
                            f.truncate()
                     config_schedule_hist = workspace + "/tmp/" + rls + "/config_deployment_schedule.txt"
                    if os.path.exists(config_schedule_hist):
                        with open(config_schedule_hist, 'w') as f:
                            f.truncate()

                for i, shipName in enumerate(shipNames):

                    if len(deploymentDate[i]) != 0:
                        if action == "Deploy":
                            date_obj = datetime.datetime.strptime(deploymentDate[i], '%m/%d/%Y').strftime('%Y-%m-%d')
                            if date_obj == now.strftime('%Y-%m-%d'):
                                shipNamesScheduled.append(shipName)
                                releaseVersionScheduled.append(releaseVersion[i])
                        elif action == "ScheduleDeploy":
                            date_time_obj = datetime.datetime.strptime(deploymentDate[i], '%m/%d/%Y')
                            if date_time_obj >= now:
                                shipNamesScheduled.append(shipName)
                                releasePageScheduled.append(releasePage[i])
                                releaseVersionScheduled.append(releaseVersion[i])

                                env_dict = config_json["jenkins"]["environments"]
                                ipaddr, serverPass = findIpAddress(env_dict,shipName)
                                if ipaddr == "None" and serverPass == "None":
                                    log("ERROR : The server details were not found in the jenkinsconfig.json. Please add the details and try again.")
                                    exit(1)
                                    
                                log("\nShip " + shipName + " is ready for release deployment. Initiating transfer of artifacts to " + ipaddr)
                                with open(scheduled_ships_path, 'a+') as f:
                                    f.write(shipName + ":" + ipaddr + ":" +  releaseVersion[i]+ ":" + transferAction[i] + ":" + serverPass + "\n")
                
                if len(shipNamesScheduled) != 0:               
                    confContentID,confErrorValue = CheckConfluencePage(pageNameConfig)
                    confVerificationResult = verifyConfluencePage(confContentID,headers,"Config")
                    log(confVerificationResult)
                    releaseVersions, serverNames, fileNames, filePaths = GetConfigChanges(confContentID,headers,releaseVersionScheduled)                      
                    log("releaseVersions :" + str(releaseVersions) + "\nserverNames :" + str(serverNames) + "\nfileNames :" + str(fileNames) +"\nfilePaths :" + str(filePaths))
                    for i, release in enumerate(releaseVersions):
                        config_files_path = workspace + "/tmp/" + release + "/config_path_mapping.txt"
                        config_schedule_hist = workspace + "/tmp/" + release + "/config_deployment_schedule.txt"
                        log("Writing into config_path_mapping.txt")
                        with open(config_files_path, 'a+') as f:
                            f.write(serverNames[i] + ":" + fileNames[i].strip() + ":" + filePaths[i].strip() + "\n")
                        log ("Writing into config_deployment_schedule.txt")
                        with open(config_schedule_path, 'a+') as f:
                             f.write(ship-name[i] + ":" + Date[i].strip() + ":" + "\n")


        scheduledReleaseDict={}
        if action == "ScheduleDeploy":
            scheduledReleaseDict = dict(zip(releaseVersionScheduled,releasePageScheduled))
        else:
            scheduledReleaseDict.update({relName:pageNameRelease})

    
        if action == "Deploy" or action == "Promote" or action == "Rollback" or (action == "ScheduleDeploy" and len(shipNamesScheduled) != 0):

            if action == "Deploy" and deploymentEnv == "PRODUCTION" and targetShipName not in shipNamesScheduled:
                log("ERROR : The MW for deployment of " + relName + " on " + targetShipName + " is not scheduled for today.")
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
                        verificationResult= verifyConfluencePage(contentID,headers,"Release")
                        log(verificationResult)

                        applicationName,applicationVersion,applicationBuild,artifactoryUrl,confluence_md5sum,yesNo =GetContentInformation(contentID,headers)

                    if components == "All":
                        deploymentType = "DEPLOY_ALL"
                    else:
                        component_list = components.split(",")
                        deploymentType = "DEPLOY_PARTIAL"

                    if deploymentType == "DEPLOY_ALL":
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

                    log("Following are the artifacts in: " + releaseName)
                    for key, value in finalArtifactoryUrl.items():

                        if targetShipName in config_json["jenkins"]["environments"]["PRODUCTION"][0]["HAL"] and key == "EXM Notification plugin":
                            continue
                        elif targetShipName in config_json["jenkins"]["environments"]["PRODUCTION"][0]["PCL"] and key == "exm-v2-plugin-excursions":
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
                        elif componentConfluence == "exm-db-upgrade":
                            component = "exm-db-upgrade"
                        elif componentConfluence == "UIEWowzaLib":
                            component = "UIEWowzaLib"
                        elif componentConfluence == "exm-v2-plugin-excursions":
                            component = "exm-v2-plugin-excursions"
                        else:
                            continue


                        log( componentConfluence + ' -> ' + url + '\n')

                        path = os.path.join(newReleaseDir,component)
                        if os.path.isdir(path) != True:
                            os.makedirs(path)
                                    
                        with open(url_file_path, 'a+') as f:
                            f.write(componentConfluence + " > " + url + "\n")

                        target_path = releasesPath + releaseName + '/' + component + '/' + url.split("/")[-1]

/                        if (action == "Deploy" and transfer_flag == "true") or action == "ScheduleDeploy":

                            log("\nDownloading " + component +" ...\n")

                            response = requests.get(url, auth = HTTPBasicAuth(username,password), stream=True)
                            if response.status_code == 200:
                                with open(target_path, 'wb') as f:
                                    f.write(response.raw.read())
                                    log("File successfully stored at : " + target_path + "\n")
                            else:
                                log("Couldn't reach the provided url with response : "+ str(response.status_code) + "\n")
                                continue
                        compServer_dict = config_json["jenkins"]["components"]
                        for server, compList in compServer_dict.items():
                            if component in compList:
                                compServer = server
                                break
                            else:
                                continue
                        with open(builds_file_path, 'a+') as f:
                            f.write(component + " : " + str(component_build_mapping[componentConfluence]) + " : " + str(component_md5sum_mapping[componentConfluence]) + ":" + str(compServer) + "\n")
        else:
            log("There is no ship currently scheduled for deployment.")
