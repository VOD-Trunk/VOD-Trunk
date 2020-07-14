node {

    try {

        stage('checkArtifactProperty') {
            def res = 0
            res = sh (script: '''
                        #!/bin/bash
                        if [ "${Deployment_env}" == "Support" ] && [ "${Activity}" == "Deploy" ]
                        then

                            #isQADone=`curl -sS -u dro7535:Hsc@start1 -X GET 'http://artifactory.tools.ocean.com/artifactory/api/storage/libs-release-local/com/uievolution/exm/exm/"${Release_version}"?properties=QA' | grep "Done" | wc -l`
                            isQADone=0
                            if [ $isQADone -eq 1 ]
                            then
                                echo "We are good to deploy in Support environment."
                            else
                                 exit 1
                            fi

                        else

                            #isSupportDone=`curl -sS -u dro7535:Hsc@start1 -X GET 'http://artifactory.tools.ocean.com/artifactory/api/storage/libs-release-local/com/uievolution/exm/exm/"${Release_version}"?properties=Support' | grep "Done" | wc -l`
                            isSupportDone=0
                            if [ $isSupportDone -eq 1 ]
                            then
                                echo "We are good to deploy in Production environment."
                            else
                                 exit 1
                            fi
                        fi
                        
                    '''
                    , returnStatus:true)
        if (res != 0) {
          currentBuild.result = 'ABORTED'
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
        
    } catch(Exception err) {
        echo "[FAILURE] Aborting deployment!! Please deploy and test in a lower environment first."
        currentBuild.result = 'FAILURE'
    }

}
