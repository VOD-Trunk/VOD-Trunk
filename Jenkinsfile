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
                stage('Check user Access Rights') {
                   last_started = env.STAGE_NAME
						sh """
                            #!/bin/bash -e
							printf "Logged in user: ${LoginUser}" 
							if [ "` echo ""${AllowedUsers}"" | grep ${LoginUser} | wc -l`" -eq 1 ] 
							then
            					printf "User Exist,checking Allowed Operations"
        					else
                            
                                printf "User ${LoginUser}::not exist to perform any operation on the xiCMS Jenkins Pipeline"
								exit 1
                            fi
                        """
                       	UserAllowedOperation = Jconf.jenkins.user_access."${LoginUser}".operations
						USerAccessEnv = Jconf.jenkins.user_access."${LoginUser}".env
                        echo "User allowed Operations ${UserAllowedOperation}"
                		echo "User allowed Access Environment: ${USerAccessEnv}"
                  
                  		sh """
                            #!/bin/bash -e
							if [ "` echo ""${UserAllowedOperation}"" | grep ${Activity} | wc -l`" -eq 1 ] 
							then
            					printf "User have access right to perform ${Activity} operation"
        					else
								printf "User ${LoginUser}::not allowed to perform ${Activity} on the xiCMS Jenkins Pipeline"
								exit 1
                            fi
                        """     
                        
                  	if( "${Activity}" != "Promote" )
                  	{
                      sh """
                            #!/bin/bash -e
							if [ "` echo ""${USerAccessEnv}"" | grep ${Deployment_Environment} | wc -l`" -eq 1 ] 
							then
            					printf "User Allowed to perform required operation in ${Deployment_Environment}"
        					else
								printf "User ${LoginUser}::not allowed to perform ${Activity} operation in ${Deployment_Environment} environment of xiCMS using Jenkins pipeline"
								exit 1
                            fi
                        """
                  	}
                  	else
                    {
                      sh """
                            #!/bin/bash -e
							if [ "` echo ""${USerAccessEnv}"" | grep ${Promoting_From} | wc -l`" -eq 1 ] 
							then
            					printf "User Allowed to perform Promote operation in ${Promoting_From}"
        					else
								printf "User ${LoginUser}:: not allowed to perform ${Activity} operation in ${Promoting_From} environment of xiCMS using Jenkins pipeline"
								exit 1
                            fi
                        """
                    }
                    			
                }              
              
                if( "${Activity}" != "Promote" ){
                    
                    def User_Role = Jconf.jenkins.user_env."${LoginUser}"
					stage('Fetch binaries from artifactory') {

                        last_started = env.STAGE_NAME
                
                        sh """
                            #!/bin/bash -e
                            python ${env.WORKSPACE}/fetchBinary.py "$Confluence_Page" $Release_Version $Activity "${env.WORKSPACE}" "$Components" "${env.ArtifactoryUser}" "${env.ArtifactoryPassword}"
                            
                        """
                    }

                    stage('Check artifact property') {
                        
                        last_started = env.STAGE_NAME

                        sh """
                            #!/bin/bash -e      
                            ${env.WORKSPACE}/checkArtifactProperty.sh "${Deployment_Environment}" "${Activity}" "${Release_Version}" "${env.ArtifactoryUser}" "${env.ArtifactoryPassword}" "Check" "${Promoting_From}" "${env.WORKSPACE}"

                        """
                    }
                   
                   stage('Deploy'){

                        last_started = env.STAGE_NAME

                        Artifacts = "$Components"

                        Artifacts = Artifacts.replaceAll("\\(.*\\)", "");

                        sh """
                            #!/bin/bash -e

                            ${env.WORKSPACE}/deployment_caller.sh "$IpAddr" $Release_Version $Activity "$Artifacts" "${env.WORKSPACE}" "$Action_on_failure"
                            
                        """
                   }
                } else {
                    stage('Promote'){

                        def User_Role = Jconf.jenkins.user_env."${BUILD_USER_ID}"

                        last_started = env.STAGE_NAME

                        sh """
                            #!/bin/bash -e

                            python ${env.WORKSPACE}/fetchBinary.py "$Confluence_Page" $Release_Version $Activity "${env.WORKSPACE}" "$Components" "${env.ArtifactoryUser}" "${env.ArtifactoryPassword}"

                            ${env.WORKSPACE}/checkArtifactProperty.sh "${Deployment_Environment}" "${Activity}" "${Release_Version}" "${env.ArtifactoryUser}" "${env.ArtifactoryPassword}" "$User_Role" "${Promoting_From}" "${env.WORKSPACE}" "$LoginUser"

                        """
                    }
                }
            }
        }
      
      /*post {
        always {
	     
          if ( currentBuild.currentResult == "SUCCESS" ) {
            echo "Build Success"
    		slackSend color: "good", message: "Job: ${env.JOB_NAME} with buildnumber ${env.BUILD_NUMBER} was successful"
  		}
  		else  { 
          echo "Build Fail"
    		slackSend color: "danger", message: "Job: ${env.JOB_NAME} with buildnumber ${env.BUILD_NUMBER} was failed"
  		}     
        }
    }*/
       
    } catch(error) {

      echo "An exception has occured in the stage '$last_started'. This build has FAILED !! ${error}"
        currentBuild.result = 'FAILURE'
    }


}


