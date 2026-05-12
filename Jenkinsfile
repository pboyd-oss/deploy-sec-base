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
                container('kaniko') {
                    withCredentials([usernamePassword(
                            credentialsId: 'harbor-robot-platform',
                            usernameVariable: 'HARBOR_USER',
                            passwordVariable: 'HARBOR_PASS')]) {
                        sh '''
                            mkdir -p /kaniko/.docker
                            AUTH=$(printf '%s:%s' "${HARBOR_USER}" "${HARBOR_PASS}" | base64 | tr -d '\n')
                            printf '{"auths":{"harbor.tuxgrid.com":{"auth":"%s"}}}' "${AUTH}" \
                                > /kaniko/.docker/config.json
                            PLATFORM_CA_B64=$(base64 -w0 /mitm-data/ca.pem 2>/dev/null || true)
                            /kaniko/executor \
                                --context=dir://. \
                                --dockerfile=Dockerfile \
                                --build-arg SYFT_VERSION=${SYFT_VERSION} \
                                --build-arg TRIVY_VERSION=${TRIVY_VERSION} \
                                --build-arg TFSEC_VERSION=${TFSEC_VERSION} \
                                --build-arg CHECKOV_VERSION=${CHECKOV_VERSION} \
                                --build-arg PYTHON_VERSION=${PYTHON_VERSION} \
                                --destination=${IMAGE}:${GIT_COMMIT:0:7} \
                                --destination=${IMAGE}:latest \
                                --digest-file=${WORKSPACE}/image.digest \
                                --snapshot-mode=redo \
                                --compressed-caching=false \
                                --cache=true \
                                --cache-repo=harbor.tuxgrid.com/platform/cache/deploy-sec-base
                        '''
                    }
                }
            }
        }

        stage('Archive') {
            steps {
                script {
                    env.IMAGE_DIGEST = readFile("${WORKSPACE}/image.digest").trim()
                    writeJSON file: 'artifacts.json', json: [
                        builds: [[tag: "${env.IMAGE}@${env.IMAGE_DIGEST}", number: env.BUILD_NUMBER]]
                    ]
                    archiveArtifacts artifacts: 'artifacts.json', fingerprint: true
                }
            }
        }

        stage('Sign') {
            steps {
                container('cosign') {
                    withCredentials([
                        string(credentialsId: 'cosign-key', variable: 'COSIGN_PRIVATE_KEY'),
                        usernamePassword(
                            credentialsId: 'harbor-robot-platform',
                            usernameVariable: 'HARBOR_USER',
                            passwordVariable: 'HARBOR_PASS'),
                    ]) {
                        sh '''
                            printf '%s' "${COSIGN_PRIVATE_KEY}" > /tmp/cosign.key
                            chmod 600 /tmp/cosign.key
                            AUTH=$(printf '%s:%s' "${HARBOR_USER}" "${HARBOR_PASS}" | base64 | tr -d '\n')
                            mkdir -p ~/.docker
                            printf '{"auths":{"harbor.tuxgrid.com":{"auth":"%s"}}}' "${AUTH}" \
                                > ~/.docker/config.json
                            COSIGN_PASSWORD="" cosign sign --key /tmp/cosign.key --yes \
                                "${IMAGE}@${IMAGE_DIGEST}"
                            rm -f /tmp/cosign.key ~/.docker/config.json
                        '''
                    }
                }
            }
        }

        stage('Provenance') {
            steps {
                container('cosign') {
                    withCredentials([
                        string(credentialsId: 'cosign-key', variable: 'COSIGN_PRIVATE_KEY'),
                        usernamePassword(
                            credentialsId: 'harbor-robot-platform',
                            usernameVariable: 'HARBOR_USER',
                            passwordVariable: 'HARBOR_PASS'),
                    ]) {
                        sh '''
                            printf '%s' "${COSIGN_PRIVATE_KEY}" > /tmp/cosign.key
                            chmod 600 /tmp/cosign.key
                            AUTH=$(printf '%s:%s' "${HARBOR_USER}" "${HARBOR_PASS}" | base64 | tr -d '\\n')
                            mkdir -p ~/.docker
                            printf '{"auths":{"harbor.tuxgrid.com":{"auth":"%s"}}}' "${AUTH}" \
                                > ~/.docker/config.json

                            NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
                            cat > /tmp/provenance.json << EOF
{
  "buildDefinition": {
    "buildType": "https://tuxgrid.com/buildType/jenkins-kaniko/v1",
    "externalParameters": {
      "ref": "${GIT_COMMIT}",
      "repository": "${GIT_URL}",
      "dockerfile": "Dockerfile"
    },
    "resolvedDependencies": [
      {"uri": "${GIT_URL}", "digest": {"gitCommit": "${GIT_COMMIT}"}}
    ]
  },
  "runDetails": {
    "builder": {"id": "https://jenkins.tuxgrid.com/job/${JOB_NAME}/${BUILD_NUMBER}"},
    "metadata": {
      "invocationId": "${BUILD_URL}",
      "startedOn": "${NOW}",
      "finishedOn": "${NOW}"
    }
  }
}
EOF

                            COSIGN_PASSWORD="" cosign attest --key /tmp/cosign.key --yes \
                                --type slsaprovenance1 \
                                --predicate /tmp/provenance.json \
                                "${IMAGE}@${IMAGE_DIGEST}"

                            rm -f /tmp/cosign.key ~/.docker/config.json /tmp/provenance.json
                        '''
                    }
                }
            }
        }
    }
}
