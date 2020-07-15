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

                    ${env.WORKSPACE}/checkArtifactProperty.sh "${Deployment_env}" "${Activity}" "${Release_version}" "${env.USERNAME}" "${env.PASSWORD}"

                    
                            
                """
            }
        
                   
            def jconf = readJSON file: "${env.WORKSPACE}/jenkinsconfig.json"

            def confluence_page = jconf.jenkins.Release."${Release_version}"

            if( "${Deployment_env}" == "Support" || "${Deployment_env}" == "QA" || "${Deployment_env}" == "XS" ) {

                def ip = jconf.jenkins.environments."${Deployment_env}"
            } else{

                def ip = jconf.jenkins.ips."${Deployment_env}"."${Ship_Name}"
            }
         
            stage('fetchBinary') {
                
                sh """
                    #!/bin/bash
                    python ${env.WORKSPACE}/fetchBinary.py "$confluence_page" $Release_version $Activity "${env.WORKSPACE}" "$Components" "${env.USERNAME}" "${env.PASSWORD}"
                    
                """
                
            }
           
           stage('deploy'){

                sh """
                    #!/bin/bash
                     ${env.WORKSPACE}/deployment_caller.sh "$ip" $Release_version $Activity "$Components" "${env.WORKSPACE}" "$abort_on_failure"
                    
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
