node {

        if( "${Activity}" != "Promote" ){

            stage('checkArtifactProperty') {


                sh """
                    #!/bin/bash

                    echo "${Deployment_env}"
                    echo "${Activity}"

                    if [ "${Deployment_env}" == "Support" ] && [ "${Activity}" == "Deploy" ]
                    then
                        #isQADone=`curl -sS -u "${UserName}":"${Password}" -X GET 'http://artifactory.tools.ocean.com/artifactory/api/storage/libs-release-local/com/uievolution/exm/exm/"${Release_version}"?properties=QA' | grep "Done" | wc -l`
                        isQADone=1

                        echo "${isQADone}"

                        if [ ${isQADone} -eq 1 ]
                        then
                            echo "We are good to deploy in Support environment."
                        else
                             exit 1
                        fi

                    else

                        #isSupportDone=`curl -sS -u "${UserName}":"${Password}" -X GET 'http://artifactory.tools.ocean.com/artifactory/api/storage/libs-release-local/com/uievolution/exm/exm/"${Release_version}"?properties=Support' | grep "Done" | wc -l`
                        isSupportDone=1
                        if [ $isSupportDone -eq 1 ]
                        then
                            echo "We are good to deploy in Production environment."
                        else
                             exit 1
                        fi
                    fi
                            
                """
            }
        
            stage('git-checkout') {
                
                checkout scm
                
                sh "chmod 755 ${env.WORKSPACE}/*"
            }
            
            def jconf = readJSON file: "${env.WORKSPACE}/jenkinsconfig.json"

            def confluence_page = jconf.jenkins.Release."${Release_version}"

            def ip = jconf.jenkins.ips."${Deployment_env}"
         
            stage('fetchBinary') {
                
                sh """
                    #!/bin/bash
                    python ${env.WORKSPACE}/fetchBinary.py "$confluence_page" $Release_version $Activity "${env.WORKSPACE}" "$Components"
                    
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
