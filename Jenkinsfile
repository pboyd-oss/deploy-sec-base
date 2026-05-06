@Library('jenkins-library') _

pipeline {
    agent {
        kubernetes {
            cloud 'kubernetes'
            inheritFrom 'kaniko-builder'
        }
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    stages {
        stage('Build & Push') {
            steps {
                script {
                    buildAndPushImage(
                        image: 'harbor.tuxgrid.com/platform/build-sec-base',
                        tag:   env.GIT_COMMIT?.take(7) ?: 'dev'
                    )
                }
            }
        }
    }
}
