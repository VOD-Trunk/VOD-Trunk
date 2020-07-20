node {

    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: '${Artifactory_Credentials}',
                usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) {
        println(env.USERNAME)
    }

    stage('git-checkout') {
            
            checkout scm
            
            sh "chmod 755 ${env.WORKSPACE}/*"
    }

    def jconf = readJSON file: "${env.WORKSPACE}/jenkinsconfig.json"

    def confluence_page = jconf.jenkins.Release."${Release_version}"

    def ipaddr = jconf.jenkins.environments."${Deployment_env}"."${Ship_Name}"

    def user_role = jconf.jenkins.user_env."${Artifactory_Credentials}"


    if( "${Activity}" != "Promote" ){

        stage('checkArtifactProperty') {


            sh """
                #!/bin/bash


                ${env.WORKSPACE}/checkArtifactProperty.sh "${Deployment_env}" "${Activity}" "${Release_version}" "${env.USERNAME}" "${env.PASSWORD}" "$user_role" "${Promoting_from}"

                
                        
            """
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

                sshpass -p "Carnival@123" ssh root@"$ipaddr" 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do rm -rf /root/Releases/$folder; done; fi'
                sshpass -p "Carnival@123" ssh -A -tt root@"$ipaddr" ssh -A -tt app02 'if [ ! -d /root/Releases ]; then mkdir -p /root/Releases; else for folder in `ls /root/Releases`; do rm -rf /root/Releases/$folder; done; fi'
                sshpass -p "Carnival@123" scp -r ${env.WORKSPACE}/Releases/"${Release_version}" ${env.WORKSPACE}/tmp root@"$ipaddr":/root/Releases
                sshpass -p "Carnival@123" scp -r ${env.WORKSPACE}/deploy_on_server.sh root@"$ipaddr":/root/bin
                sshpass -p "Carnival@123" ssh root@"$ipaddr" 'chmod +x /root/bin/deploy_on_server.sh && /root/bin/deploy_on_server.sh -d "${Release_version}" "$Components" "$abort_on_failure" "app01"'
                sshpass -p "Carnival@123" ssh -A -tt root@"$ipaddr" ssh -A -tt app02 'chmod +x /root/bin/deploy_on_server.sh && /root/bin/deploy_on_server.sh -d "${Release_version}" "$Components" "$abort_on_failure" "app01"'

                 ##${env.WORKSPACE}/deployment_caller.sh "$ipaddr" $Release_version $Activity "$Components" "${env.WORKSPACE}" "$abort_on_failure"
                
            """
       }
    } else {
        stage('Promote'){

           sh """
                #!/bin/bash

                ${env.WORKSPACE}/checkArtifactProperty.sh "${Deployment_env}" "${Activity}" "${Release_version}" "${env.USERNAME}" "${env.PASSWORD}" "$user_role" "${Promoting_from}"

                
                        
            """
        }


    }        
        
}
