node {
    
    stage('git-checkout') {
        
        checkout scm
        
        sh "chmod 755 ${env.WORKSPACE}/*
    }
    
    def jconf = readJSON file: "${env.WORKSPACE}/jenkinsconfig.json"

    def confluence_page = jconf.jenkins.Release."${Release_version}"

    def ip = jconf.jenkins.ips."${Deployment_env}"
 
    stage('fetchBinary') {
        
        sh """
            #!/bin/bash
            python ${env.WORKSPACE}/fetchBinary.py "$confluence_page" $Release_version $Activity "${env.WORKSPACE}"
            
        """
        
    }
   
   stage('deploy'){

        sh """
            #!/bin/bash
             ${env.WORKSPACE}/deployment_caller.sh "$ip" $Release_version $Activity $Components "${env.WORKSPACE}"
            
        """
   }
   
   stage('test'){
       
   }
   
   stage('promote'){
       
   }
}
