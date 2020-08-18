node {

    try {

        wrap([$class: 'BuildUser']) {
        
            def LoginUser = env.BUILD_USER_ID
          
            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: '${Artifactory_Credentials}',
                    usernameVariable: 'ArtifactoryUser', passwordVariable: 'ArtifactoryPassword']]) {
        
                stage('Git Checkout') {
                        last_started = env.STAGE_NAME
                        checkout scm
                        sh "chmod 755 ${env.WORKSPACE}/*"
                }

                /*stage("speak") {
                slackSend color: '#BADA55', message: 'Hello, World!'
                }*/

                def Jconf = readJSON file: "${env.WORKSPACE}/jenkinsconfig.json"
                def Confluence_Page = Jconf.jenkins.Release."${Release_Version}"
                def IpAddr = Jconf.jenkins.environments."${Deployment_Environment}"."${Ship_Name}"
                def AllowedUsers = Jconf.jenkins.user_access
                def UserAllowedOperation
                def USerAccessEnv

                stage('Check User Access Rights') {
                    
                    last_started = env.STAGE_NAME
                    
                    sh """
                        #!/bin/bash
                        printf "Logged in user: ${LoginUser}" 
                        if [ "` echo ""${AllowedUsers}"" | grep ${LoginUser} | wc -l`" -eq 1 ] 
                        then
                            printf "User exists, checking Allowed Operations..."
                        else
                        
                            printf "User ${LoginUser} does not exist in the list of users able to perform any operation on the xiCMS Jenkins Pipeline"
                            exit 1
                        fi
                    """
                    UserAllowedOperation = Jconf.jenkins.user_access."${LoginUser}".operations
                    UserAccessEnv = Jconf.jenkins.user_access."${LoginUser}".env
                    
                    echo "Allowed Operations for user ${LoginUser} are : ${UserAllowedOperation}"
                    echo "Allowed access environments for user ${LoginUser} are : ${UserAccessEnv}"
              
                    sh """
                        #!/bin/bash
                        if [ "` echo ""${UserAllowedOperation}"" | grep ${Activity} | wc -l`" -eq 1 ] 
                        then
                            printf "User has access rights to perform ${Activity} operation."
                        else
                            printf "User ${LoginUser} is not allowed to perform ${Activity} on the xiCMS Jenkins Pipeline"
                            exit 1
                        fi
                    """     
                        
                    if( "${Activity}" != "Promote" )
                    {
                      sh """
                            #!/bin/bash
                            if [ "` echo ""${UserAccessEnv}"" | grep ${Deployment_Environment} | wc -l`" -eq 1 ] 
                            then
                                printf "User ${LoginUser} is allowed to perform ${Activity} operation in ${Deployment_Environment}"
                            else
                                printf "User ${LoginUser} is not allowed to perform ${Activity} operation in ${Deployment_Environment} environment of xiCMS using Jenkins pipeline."
                                exit 1
                            fi
                        """
                    }
                    else
                    {
                      sh """
                            #!/bin/bash
                            ${env.WORKSPACE}/checkPromotionRight.sh "${UserAccessEnv}" "${LoginUser}" "${Activity}" "${Promoting_From}" 
                            
                        """
                    }
                                
                }              
              
                if( "${Activity}" != "Promote" ){

                                     
                    stage('Fetch binaries from artifactory') {

                        last_started = env.STAGE_NAME
                
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
                            ${env.WORKSPACE}/checkArtifactProperty.sh "${Deployment_Environment}" "${Activity}" "${Release_Version}" "${env.ArtifactoryUser}" "${env.ArtifactoryPassword}" "${Promoting_From}" "${env.WORKSPACE}" "$LoginUser"

                        """
                    }

                    */
                   
                   stage('Deploy'){

                        last_started = env.STAGE_NAME

                        Artifacts = "$Components"

                        Artifacts = Artifacts.replaceAll("\\(.*\\)", "");

                        sh """
                            #!/bin/bash -e

                            ${env.WORKSPACE}/deployment_caller.sh "$IpAddr" $Release_Version $Activity "$Artifacts" "${env.WORKSPACE}" "$Action_on_failure" "${Transfer_Of_Artifacts}"
                            
                        """
                   }
                } else {
                    stage('Promote'){

                        last_started = env.STAGE_NAME

                        sh """
                            #!/bin/bash -e

                            python ${env.WORKSPACE}/fetchBinary.py "$Confluence_Page" $Release_Version $Activity "${env.WORKSPACE}" "$Components" "${env.ArtifactoryUser}" "${env.ArtifactoryPassword}" "${Transfer_Of_Artifacts}" "XICMS MW-Schedule" $Deployment_Environment "${Ship_Name}"

                            ${env.WORKSPACE}/checkArtifactProperty.sh "${Deployment_Environment}" "${Activity}" "${Release_Version}" "${env.ArtifactoryUser}" "${env.ArtifactoryPassword}"  "${Promoting_From}" "${env.WORKSPACE}" "$LoginUser"

                        """
                    }
                }
            }
        }
      
       
    } catch(error) {

      echo "An exception has occured in the stage '$last_started'. This build has FAILED !! ${error}"
        currentBuild.result = 'FAILURE'
        throw error
    }
    /*
    finally {
        // Success or failure, always send notifications
        notifyBuild(currentBuild.result)
    }
    */

}

/*

def notifyBuild(String buildStatus = 'STARTED') {
  // build status of null means successful
  buildStatus = buildStatus ?: 'SUCCESS'

  // Default values
  def colorName = 'RED'
  def colorCode = '#FF0000'
  def subject = "${buildStatus}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'"
  def summary = "${subject} (${env.BUILD_URL})"
  def details = """<p>STARTED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
    <p>Check console output at &QUOT;<a href='${env.BUILD_URL}'>${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>&QUOT;</p>"""

  // Override default values based on build status
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

  // Send notifications
  slackSend (color: colorCode,channel: '#exm-jenkins-tracking', message: summary)

  //hipchatSend (color: color, notify: true, message: summary)
 //to:'deepak.rohilla@hsc.com,xicms-support-list@hsc.com',
  emailext (
      subject: subject,
      body: details,
      
      recipientProviders: [[$class: 'DevelopersRecipientProvider']]
    )
}
*/