//Last modified : 8/25/2020
node {

    try {

        wrap([$class: 'BuildUser']) {

            if("$Components" == "")
            {
              echo "\n\nNo component selected. Please select atleast one component to move ahead.\n\n"
              error("No component selected.")
            }
        
            def LoginUser = env.BUILD_USER_ID
          
            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: '${Artifactory_Credentials}',
                    usernameVariable: 'ArtifactoryUser', passwordVariable: 'ArtifactoryPassword']]) {
        
                stage('Git Checkout') {
                        //last_started = env.STAGE_NAME
                        checkout scm
                        sh "chmod 755 ${env.WORKSPACE}/*"

                        sh "if [ ! -d ${env.WORKSPACE}/logs ]; then mkdir -p ${env.WORKSPACE}/logs; elif [ -d ${env.WORKSPACE}/logs ]; then for i in `ls ${env.WORKSPACE}/logs`; do rm -rf ${env.WORKSPACE}/logs/$i; done; fi"
                }

                def Jconf = readJSON file: "${env.WORKSPACE}/jenkinsconfig.json"
                def Confluence_Page = Jconf.jenkins.Release."${Release_Version}"
                def IpAddr = Jconf.jenkins.environments."${Deployment_Environment}"."${Ship_Name}"
                def AllowedUsers = Jconf.jenkins.user_access.keySet()
                UserAllowedOperation = Jconf.jenkins.user_access."${LoginUser}".operations
                UserAccessEnv = Jconf.jenkins.user_access."${LoginUser}".env

                stage('Check User Access Rights') {
                    
                    //last_started = env.STAGE_NAME

                    sh """
                        #!/bin/bash
                        ${env.WORKSPACE}/checkUserAccessRights.sh "${LoginUser}" "${AllowedUsers}" "${Activity}" "${Deployment_Environment}" "${Promoting_From}" "${UserAccessEnv}" "${UserAllowedOperation}" "${env.WORKSPACE}"
                            
                    """

                }              
              
                if( "${Activity}" != "Promote" ){

                                     
                    stage('Fetch binaries from artifactory') {

                        //last_started = env.STAGE_NAME
                
                        sh """
                            #!/bin/bash -e
                            python ${env.WORKSPACE}/fetchBinary.py "$Confluence_Page" $Release_Version $Activity "${env.WORKSPACE}" "$Components" "${env.ArtifactoryUser}" "${env.ArtifactoryPassword}" "${Transfer_Of_Artifacts}" "XICMS MW-Schedule" $Deployment_Environment "${Ship_Name}"
                            
                        """
                    }

                    /*

                    stage('Check artifact property') {
                        
                        last_started = env.STAGE_NAME

                        sh """
                            #!/bin/bash -e      
                            ${env.WORKSPACE}/checkArtifactProperty.sh "${Deployment_Environment}" "${Activity}" "${Release_Version}" "${env.ArtifactoryUser}" "${env.ArtifactoryPassword}" "${Promoting_From}" "${env.WORKSPACE}" "$LoginUser" "${Ship_Name}"

                        """
                    }
                    */

                   
                   stage('Deploy'){

                        //last_started = env.STAGE_NAME

                        Artifacts = "$Components"

                        Artifacts = Artifacts.replaceAll("\\(.*\\)", "");

                        sh """
                            #!/bin/bash -e

                            ${env.WORKSPACE}/deployment_caller.sh "$IpAddr" $Release_Version $Activity "$Artifacts" "${env.WORKSPACE}" "$Action_on_failure" "${Transfer_Of_Artifacts}" "${env.ArtifactoryUser}" "${env.ArtifactoryPassword}"
                            
                        """
                   }
                } else {
                    stage('Promote'){

                        //last_started = env.STAGE_NAME

                        sh """
                            #!/bin/bash -e

                            python ${env.WORKSPACE}/fetchBinary.py "$Confluence_Page" $Release_Version $Activity "${env.WORKSPACE}" "$Components" "${env.ArtifactoryUser}" "${env.ArtifactoryPassword}" "${Transfer_Of_Artifacts}" "XICMS MW-Schedule" $Deployment_Environment "${Ship_Name}"

                            ${env.WORKSPACE}/checkArtifactProperty.sh "${Deployment_Environment}" "${Activity}" "${Release_Version}" "${env.ArtifactoryUser}" "${env.ArtifactoryPassword}"  "${Promoting_From}" "${env.WORKSPACE}" "$LoginUser" "${Ship_Name}"

                        """
                    }
                }
            }
        }
      
       
    } catch(error) {

        echo "An exception has occured. This build has FAILED !! ${error}"
        currentBuild.result = 'FAILURE'
        throw error
    }


    /*
    finally {

        wrap([$class: 'BuildUser']) {
        
            def LoginUser = env.BUILD_USER_ID
        

        buildStatus = currentBuild.result
        buildStatus = buildStatus ?: 'SUCCESS'
        
        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: '${Artifactory_Credentials}',
                usernameVariable: 'ArtifactoryUser', passwordVariable: 'ArtifactoryPassword']]) {
          if( buildStatus == 'SUCCESS' && "${Deployment_Environment}" == "PRODUCTION" && "${Activity}" == "Deploy" )
          {
              sh """
                  #!/bin/bash -e
                  ${env.WORKSPACE}/checkArtifactProperty.sh "${Deployment_Environment}" "Promote" "${Release_Version}" "${env.ArtifactoryUser}" "${env.ArtifactoryPassword}"  "PRODUCTION" "${env.WORKSPACE}" "$LoginUser" "${Ship_Name}"
              """
          }
          
        }


        // Success or failure, always send notification

        if (buildStatus == 'STARTED') {
        color = 'YELLOW'
        colorCode = '#FFFF00'
        } else if (buildStatus == 'SUCCESS') {
        color = 'GREEN'
        colorCode = '#00FF00'
        } else {
        color = 'RED'
        colorCode = '#FF0000'
        }
        
        def exists = fileExists 'logs/email_body.txt'
          
        if (exists) {
            def data = readFile(file: 'logs/email_body.txt')
            email_body = "Job Name : ${env.JOB_NAME} \nLogin User : ${LoginUser} \nShip Name : ${Ship_Name} \nOperation : ${Activity} \nBuild# : ${BUILD_NUMBER} \nBuild URL : ${env.BUILD_URL} \nBuild Result : ${buildStatus}\n\n\nBelow given is a snippet from the console logs :\n\n\n" + data + "\n\n\nPlease find attached the console logs for this build.\n\n\nThank you."
        } else {
            email_body = "Job Name : ${env.JOB_NAME} \nLogin User : ${LoginUser} \nShip Name : ${Ship_Name} \nOperation : ${Activity} \nBuild# : ${BUILD_NUMBER} \nBuild URL : ${env.BUILD_URL} \nBuild Result : ${buildStatus}\n\n\nPlease find attached the console logs for this build.\n\n\nThank you."
        }

        slack_body = "Job Name : ${env.JOB_NAME} \nLogin User : ${LoginUser} \nShip Name : ${Ship_Name} \nOperation : ${Activity} \nBuild# : ${BUILD_NUMBER} \nBuild URL : ${env.BUILD_URL} \nBuild Result : ${buildStatus}"
        

        // Send notifications
        slackSend (color: colorCode,channel: '#exm-jenkins-tracking', message: slack_body)
        emailext attachLog: true, body: email_body, compressLog: true, subject: "Build Notification: ${env.JOB_NAME}-Build# ${env.BUILD_NUMBER} ${buildStatus}", to : 'abhishek.chadha@hsc.com, deepak.rohilla@hsc.com, pratyush.mishra@hsc.com'
       
        }

    }
    */

}