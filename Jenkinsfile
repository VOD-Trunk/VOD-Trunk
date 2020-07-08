node {

    try {
    
        stage('git-checkout') {
            
            checkout scm
            
            sh "chmod 755 ${env.WORKSPACE}/*"
        }
        
        def jconf = readJSON file: "${env.WORKSPACE}/jenkinsconfig.json"

        def confluence_page = jconf.jenkins.Release."${Release_version}"

        def ip = jconf.jenkins.ips."${Deployment_env}"
     
        stage('fetchBinary') {
            
            def build_numbers = sh( script : 'python ${env.WORKSPACE}/fetchBinary.py "$confluence_page" $Release_version $Activity "${env.WORKSPACE}" "$Components"',returnStdout: true )
            def builds_array = build_numbers.split('\n')
            echo "$builds_array"
        }
       
       stage('deploy'){

            sh """
                #!/bin/bash
                 ${env.WORKSPACE}/deployment_caller.sh "$ip" $Release_version $Activity "$Components" "${env.WORKSPACE}" "$abort_on_failure"
                
            """
       }
    } catch(Exception err) {
        currentBuild.result = 'FAILURE'
    }

}
