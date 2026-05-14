pipeline {
    agent {
        kubernetes {
            inheritFrom 'deploy-sec-base-builder'
        }
    }

    environment {
        IMAGE = 'harbor.tuxgrid.com/platform/deploy-sec-base'
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    triggers {
        pollSCM('H/5 * * * *')
    }

    stages {
        stage('Build') {
            steps {
                script {
                    platformBuild(
                        tag:           env.GIT_COMMIT?.take(7) ?: env.BUILD_NUMBER,
                        cache:         true,
                        cacheRepo:     'harbor.tuxgrid.com/platform/cache/deploy-sec-base',
                        extraBuildArgs: ['SYFT_VERSION', 'TRIVY_VERSION', 'TFSEC_VERSION', 'CHECKOV_VERSION', 'PYTHON_VERSION']
                    )
                }
            }
        }
        stage('Archive')    { steps { script { platformArchive(includeDeps: false) } } }
        stage('Sign')       { steps { script { platformSign(container: 'cosign') } } }
        stage('Provenance') { steps { script { platformBuildProvenance(simple: true, container: 'cosign') } } }
    }
}
