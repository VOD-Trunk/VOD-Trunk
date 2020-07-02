#Author : Abhishek Chadha
#Last modified : 7/1/2020

import sys
import requests
from requests.auth import HTTPBasicAuth
import json
import re
import os

#releasesPath = '/var/lib/jenkins/workspace/VOD-deployment/Releases/'

pageName = sys.argv[1]
relName = sys.argv[2]
action = sys.argv[3]
releasesPath = sys.argv[4]

releasesPath = releasesPath + '/Releases/'

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
            print(response.request.url)

            if response.status_code == 200:
                    print ("HTTP Query successful:")
                    searchResult=json.loads(response.text)['results']

                    if len(searchResult)==0:
                            errorValue=("Confluence Page not exist:" +pageName)
                            print ("No Record found for URL:" + response.request.url)
                            exit
                    elif len(searchResult)==1:
                            print(json.dumps((json.loads(response.text)['results'][0]['id']), sort_keys=True, indent=4, separators=(",", ": ")))
                            contentID=searchResult[0]['id']
                    else:
                            contentID =0
                            errorValue=("More then one record exist for page:",pageName)
                            print(response.text)

            else:
                    print(response)
                    errorValue=("HTTP request failed for page " ,pageName ,"reason:" ,response)
                    print ("Confluence page not exist or other error::",url)

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
                    print ("Query successful:Confluence page exist")
            else:
                    print(response)
                    print ("Confluence page not exist or other error::",url)
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
            print(len(subTable))
            for x in subTable:

                    #print(x)

                    columnValue=TAG_RE.sub('', x)

                    if recordCount%7 == 0:  #Ignore first record
                            applicationName.append(columnValue)
                            #print("applicationName:"+ columnValue)
                    elif recordCount%7== 1:
                            applicationVersion.append(columnValue)
                            #print("applicationVersion:"+ columnValue)
                    elif recordCount%7== 2:
                            applicationBuild.append(columnValue)
                            #print("applicationBuild:"+ columnValue)
                    elif recordCount%7== 4:
                            artifactoryUrl.append(columnValue)
                    elif recordCount%7== 6:
                            yesNo.append(columnValue)


                    recordCount= recordCount + 1
                    #print(recordCount)
            return (applicationName,applicationVersion,applicationBuild,artifactoryUrl,yesNo)

    # end of function //GetContentInformation

    #Main script
    print("Starting...\n")

    headers = {
               "Accept": "application/json",
               "Content-Type": "application/json",
               "Authorization": "Basic ZGVlcGFrLnJvaGlsbGFAaHNjLmNvbTpkMnl0NWJ4TGdmcFA4cG93S3VsOUQyNTE="
            }

    releaseComponents=[]
    releaseArtifactsUrl=[]

    #Page ID to get the page details
    contentID=0
    contentID,errorValue = CheckConfluencePage(pageName)
    if contentID ==0:
            print(errorValue)
    else:
            applicationName,applicationVersion,applicationBuild,artifactoryUrl,yesNo =GetContentInformation(contentID,headers)

    for index, element in enumerate(yesNo):
            if element == "Y":
                    releaseComponents.append(applicationName[index])
                    releaseArtifactsUrl.append(artifactoryUrl[index])
                    finalArtifactoryUrl = dict(zip(releaseComponents,releaseArtifactsUrl))

    print("\n\nFollowing are the artifacts to be deployed:\n")
    for key, value in finalArtifactoryUrl.items():
            print(str(key)+ ' -> ' + str(value))

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
            os.makedirs(path)
            
            print("\nDownloading " + component +" ...\n")

            url = str(value)
            target_path = releasesPath + relName + '/' + component + '/' + url.split("/")[-1]

            response = requests.get(url, auth = HTTPBasicAuth('admin', 'password'), stream=True)
            if response.status_code == 200:
                with open(target_path, 'wb') as f:
                    f.write(response.raw.read())
                    print("File successfully stored at : " + target_path + "\n")
            else:
                print("Couldn't reach the provided url with response : "+ str(response.status_code) + "\n")
else:
    print("fetchBinary stage is not required for actions other than Deploy.")
