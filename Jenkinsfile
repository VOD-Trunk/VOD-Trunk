node {

    try {

        stage('Git Checkout') {
                    //last_started = env.STAGE_NAME
                    checkout scm
                    sh "chmod 755 ${env.WORKSPACE}/*"
                }

        stage('Read COnfluence Page'){

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