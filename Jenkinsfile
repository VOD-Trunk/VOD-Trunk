node {

        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: '${Artifactory_Credentials}',
                    usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) {
            println(env.USERNAME)
        }

        stage('git-checkout') {
                
                checkout scm
                
                sh "chmod 755 ${env.WORKSPACE}/*"
        }

        if( "${Activity}" != "Promote" ){

            stage('checkArtifactProperty') {


                sh """
                    #!/bin/bash

                    echo "${Deployment_env}"

                    ${env.WORKSPACE}/checkArtifactProperty.sh "${Deployment_env}" "${Activity}" "${Release_version}" "${env.USERNAME}" "${env.PASSWORD}"

                    
                            
                """
            }
        
                   
            def jconf = readJSON file: "${env.WORKSPACE}/jenkinsconfig.json"

            def confluence_page = jconf.jenkins.Release."${Release_version}"

            def ipaddr = jconf.jenkins.environments."${Deployment_env}"
            
         
            stage('fetchBinary') {
                
                sh """
                    #!/bin/bash
                    python ${env.WORKSPACE}/fetchBinary.py "$confluence_page" $Release_version $Activity "${env.WORKSPACE}" "$Components" "${env.USERNAME}" "${env.PASSWORD}"
                    
                """
                
            }
           
           stage('deploy'){

                sh """
                    #!/bin/bash
                     ${env.WORKSPACE}/deployment_caller.sh "$ipaddr" $Release_version $Activity "$Components" "${env.WORKSPACE}" "$abort_on_failure"
                    
                """
           }
        } else {
            stage('Promote'){

                if( "${UserName}" == "dro7535" ) {

                 sh """
                    #!/bin/bash
                    echo "Setting Support = Done."
                    #curl -sS -u "${UserName}":"${Password}" -X PUT "http://artifactory.tools.ocean.com/artifactory/api/storage/libs-release-local/com/uievolution/exm/exm/"${Release_version}"?properties=Support=Done"
                """
                } else {

                    sh """
                        #!/bin/bash
                        echo "Setting QA = Done."
                        #curl -sS -u "${UserName}":"${Password}" -X PUT "http://artifactory.tools.ocean.com/artifactory/api/storage/libs-release-local/com/uievolution/exm/exm/"${Release_version}"?properties=QA=Done"
                    """
                }


            }
        }
        
}
