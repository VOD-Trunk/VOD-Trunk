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

        def ipaddr = jconf.jenkins.environments."${Deployment_env}"."${Ship_Name}"

        def user_role = jconf.jenkins.user_role.admin
        
     
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

           sh """
                #!/bin/bash

                ${env.WORKSPACE}/checkArtifactProperty.sh "${Deployment_env}" "${Activity}" "${Release_version}" "${env.USERNAME}" "${env.PASSWORD}" "$user_role" "${Set_status_done_on}"

                
                        
            """
        }


    }        
        
}
