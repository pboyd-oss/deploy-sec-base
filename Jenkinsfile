pipeline {
    agent {
        kubernetes {
            cloud 'kubernetes'
            inheritFrom 'platform-builder'
        }
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    environment {
        IMAGE = "harbor.tuxgrid.com/platform/build-sec-base"
        TAG   = "${env.GIT_COMMIT?.take(7) ?: 'dev'}"
    }

    stages {
        stage('Build & Push') {
            steps {
                container('kaniko') {
                    sh """
                        /kaniko/executor \
                            --context=dir://\${WORKSPACE} \
                            --dockerfile=Dockerfile \
                            --destination=\${IMAGE}:\${TAG} \
                            --destination=\${IMAGE}:latest \
                            --cache=true \
                            --cache-repo=\${IMAGE}/cache
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Built and pushed \${IMAGE}:\${TAG}"
        }
    }
}
