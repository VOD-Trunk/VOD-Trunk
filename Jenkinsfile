node {

    try {

        stage('Git Checkout') {
                    checkout scm
                    sh "chmod 755 ${env.WORKSPACE}/*"
                }

        stage('Updating Master File and Collecting Configs from All Servers'){

                    sh"""
                        sh $WORKSPACE/update_master_file.sh $WORKSPACE
                        sh $WORKSPACE/fetch_files.sh $WORKSPACE
                    """
                }
    }
    catch(error) {

     echo "An exception has occured in stage . This build has FAILED !! ${error}"
        currentBuild.result = 'FAILURE'
        throw error
    }
}
