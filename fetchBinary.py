#Author : Abhishek Chadha
#Last modified : 7/1/2020

import sys
import requests
from requests.auth import HTTPBasicAuth
import json
import re
import os
import logging



pageName = sys.argv[1]
relName = sys.argv[2]
action = sys.argv[3]
workspace = sys.argv[4]
components = sys.argv[5]
partial_deploy = 2

logging.basicConfig(filename= workspace +'/logs/fetchBinaryLogs.log', filemode='a', format='%(asctime)s,%(msecs)d %(name)s %(levelname)s %(message)s', datefmt='%H:%M:%S', level=logging.DEBUG)
releasesPath = workspace + '/Releases/'

if action == "Deploy":
    applicationName=[]
    applicationVersion=[]
    applicationBuild=[]

    def CheckConfluencePage(pageName):

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
            logging.info(response.request.url)

            if response.status_code == 200:
                    logging.info ("HTTP Query successful:")
                    searchResult=json.loads(response.text)['results']

                    if len(searchResult)==0:
                            errorValue=("Confluence Page not exist:" +pageName)
                            logging.info ("No Record found for URL:" + response.request.url)
                            exit
                    elif len(searchResult)==1:
                            logging.info(json.dumps((json.loads(response.text)['results'][0]['id']), sort_keys=True, indent=4, separators=(",", ": ")))
                            contentID=searchResult[0]['id']
                    else:
                            contentID =0
                            errorValue=("More then one record exist for page:",pageName)
                            logging.info(response.text)

            else:
                    logging.info(response)
                    errorValue=("HTTP request failed for page " ,pageName ,"reason:" ,response)
                    logging.info ("Confluence page not exist or other error::",url)

            return  (contentID,errorValue)

    # end of function //CheckConfluencePage



    def GetContentInformation(ContentId,headers):

            url = "https://carnival.atlassian.net/wiki/rest/api/content/" +str(ContentId) + "?expand=body.storage"

            response = requests.request(
               "GET",
               url,
               headers=headers
            )

            if response.status_code == 200:
                    logging.info ("Query successful:Confluence page exist")
            else:
                    logging.info(response)
                    logging.info ("Confluence page not exist or other error::",url)
                    exit()

            searchString = response.text
            subTable = re.findall(r'<td>(.+?)</td>',searchString)
            recordCount=0
            columnCount=0
            applicationName=[]
            applicationVersion=[]
            applicationBuild=[]
            artifactoryUrl=[]
            yesNo=[]
            test=[]
            TAG_RE = re.compile(r'<[^>]+>')
            logging.info(len(subTable))
            for x in subTable:

                    #logging.info(x)

                    columnValue=TAG_RE.sub('', x)

                    if recordCount%7 == 0:  #Ignore first record
                            applicationName.append(columnValue)
                            #logging.info("applicationName:"+ columnValue)
                    elif recordCount%7== 1:
                            applicationVersion.append(columnValue)
                            #logging.info("applicationVersion:"+ columnValue)
                    elif recordCount%7== 2:
                            applicationBuild.append(columnValue)
                            #logging.info("applicationBuild:"+ columnValue)
                    elif recordCount%7== 4:
                            artifactoryUrl.append(columnValue)
                    elif recordCount%7== 6:
                            yesNo.append(columnValue)


                    recordCount= recordCount + 1
                    #logging.info(recordCount)
            return (applicationName,applicationVersion,applicationBuild,artifactoryUrl,yesNo)

    # end of function //GetContentInformation

    #Main script
    logging.info("Starting...\n")

    headers = {
               "Accept": "application/json",
               "Content-Type": "application/json",
               "Authorization": "Basic ZGVlcGFrLnJvaGlsbGFAaHNjLmNvbTpkMnl0NWJ4TGdmcFA4cG93S3VsOUQyNTE="
            }

    releaseComponents=[]
    releaseArtifactsUrl=[]
    releaseBuildNumbers=[]

    #Page ID to get the page details
    contentID=0
    contentID,errorValue = CheckConfluencePage(pageName)
    if contentID ==0:
            logging.info(errorValue)
    else:
            applicationName,applicationVersion,applicationBuild,artifactoryUrl,yesNo =GetContentInformation(contentID,headers)

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
                        finalArtifactoryUrl = dict(zip(releaseComponents,releaseArtifactsUrl))
    else:
        for index, element in enumerate(yesNo):
                if element == "Y" and applicationName[index] in component_list:
                        releaseComponents.append(applicationName[index])
                        releaseBuildNumbers.append(applicationBuild[index])
                        releaseArtifactsUrl.append(artifactoryUrl[index])
                        finalArtifactoryUrl = dict(zip(releaseComponents,releaseArtifactsUrl))

    logging.info("\n\nFollowing are the artifacts to be deployed:\n")
    for key, value in finalArtifactoryUrl.items():
            logging.info(str(key)+ ' -> ' + str(value))

            componentConfluence = str(key)
            
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

            newReleaseDir = releasesPath + relName

            path = os.path.join(newReleaseDir,component)
            if os.path.isdir(path) != True:
                os.makedirs(path)
            log_path = 'logs'
            path = os.path.join(workspace,log_path)
            if os.path.isdir(path) != True:
                os.makedirs(path)
            
            logging.info("\nDownloading " + component +" ...\n")

            url = str(value)
            target_path = releasesPath + relName + '/' + component + '/' + url.split("/")[-1]

            response = requests.get(url, auth = HTTPBasicAuth('admin', 'password'), stream=True)
            if response.status_code == 200:
                with open(target_path, 'wb') as f:
                    f.write(response.raw.read())
                    logging.info("File successfully stored at : " + target_path + "\n")
            else:
                logging.info("Couldn't reach the provided url with response : "+ str(response.status_code) + "\n")

    print(releaseBuildNumbers)
else:
    logging.info("fetchBinary stage is not required for actions other than Deploy.")
