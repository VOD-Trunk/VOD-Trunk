node {

    try {

        stage('Git Checkout') {
                    checkout scm
                    sh "chmod 755 ${env.WORKSPACE}/*"
                }

        stage('Updating Master File and Collecting Configs from All Servers'){

                    sh"""
                        sh $WORKSPACE/update_master_file.sh $WORKSPACE
                    """
                }
        stage('Update Config Files'){
                    sh"""
                        sh $WORKSPACE/find_config_diff.sh $WORKSPACE
                    """
               }
       }
    catch(error) {

     echo "An exception has occured in stage . This build has FAILED !! ${error}"
        currentBuild.result = 'FAILURE'
        throw error
    }
}
