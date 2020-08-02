import sys
import requests
from requests.auth import HTTPBasicAuth
import json
import re
import os
import shutil


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
                errorValue=("Confluence Page does not exist:" +pageName)
                print ("No Record found for URL:" + response.request.url)
                exit(1)
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
        exit(1)

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



pageName = sys.argv[1]
relName = sys.argv[2]
action = sys.argv[3]
workspace = sys.argv[4]
components = sys.argv[5]
username = sys.argv[6]
password = sys.argv[7]
partial_deploy = 2

builds_file_path = workspace + "/tmp/component_build_mapping.txt"

if os.path.exists(builds_file_path):
    with open(builds_file_path, 'w') as f:
        f.truncate()

url_file_path = workspace + "/tmp/urls.txt"

if os.path.exists(url_file_path):
    with open(url_file_path, 'w') as f:
        f.truncate()

releasesPath = workspace + '/Releases/'
newReleaseDir = releasesPath + relName

if os.path.isdir(newReleaseDir) == True:
    shutil.rmtree(newReleaseDir)

log_path = 'logs'
path = os.path.join(workspace,log_path)
if os.path.isdir(path) != True:
    os.makedirs(path)
else:
    folder = workspace + "/logs"
    for the_file in os.listdir(folder):
        file_path = os.path.join(folder, the_file)
        try:
            if os.path.isfile(file_path):
               os.unlink(file_path)
        except Exception as e:
            print(e)

tmp_path = 'tmp'
path = os.path.join(workspace,tmp_path)
if os.path.isdir(path) != True:
    os.makedirs(path)


if action == "Deploy" or action == "Promote":
    applicationName=[]
    applicationVersion=[]
    applicationBuild=[]
    yesNo=[]
    finalArtifactoryUrl={}
    

    #Main script
    print("Starting...\n")

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
            print(errorValue)
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
                    component_build_mapping = dict(zip(releaseComponents,releaseBuildNumbers))
    else:
        for index, element in enumerate(yesNo):
                if element == "Y" and applicationName[index] in component_list:
                    releaseComponents.append(applicationName[index])
                    releaseBuildNumbers.append(applicationBuild[index])
                    releaseArtifactsUrl.append(artifactoryUrl[index])
                    finalArtifactoryUrl = dict(zip(releaseComponents,releaseArtifactsUrl))
                    component_build_mapping = dict(zip(releaseComponents,releaseBuildNumbers))
                elif element == "N" and applicationName[index] in component_list:
                    print("INFO--->  Selected component " + applicationName[index] + " is not a part of Release : " + relName)
                    continue

    if len(finalArtifactoryUrl) == 0:
        print("None of the selected components is a part of Release : " + relName)
        exit(1)

    print("\n\nFollowing are the artifacts in: " + relName + "\n\n")
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


            print( componentConfluence + ' -> ' + url + '\n')

            path = os.path.join(newReleaseDir,component)
            if os.path.isdir(path) != True:
                os.makedirs(path)
                        
            with open(url_file_path, 'a+') as f:
                f.write(componentConfluence + " > " + url + "\n")

            target_path = releasesPath + relName + '/' + component + '/' + url.split("/")[-1]

            if action == "Deploy":

                print("\nDownloading " + component +" ...\n")

                response = requests.get(url, auth = HTTPBasicAuth(username,password), stream=True)
                if response.status_code == 200:
                    with open(target_path, 'wb') as f:
                        f.write(response.raw.read())
                        print("File successfully stored at : " + target_path + "\n")
                else:
                    print("Couldn't reach the provided url with response : "+ str(response.status_code) + "\n")
                    exit(1)

                with open(builds_file_path, 'a+') as f:
                    f.write(component + " : " + str(component_build_mapping[componentConfluence]) + "\n")
else:
    print("fetchBinary stage is not required for Rollback.")
