pipeline {
    agent any

    options {
        timeout(time: 30, unit: 'MINUTES')
    }

    environment {
        DOTNET_NOLOGO = 'true'
        DOTNET_CLI_TELEMETRY_OPTOUT = '1'
        DOCKER_REGISTRY_URL = '172.210.56.254:21114'
        DOCKER_IMAGE_NAME = 'testeactions'
        DOCKER_REGISTRY_CREDENTIALS_ID = 'docker-registry-credentials'
        PUBLISH_DOCKER_BRANCH = 'develop'
    }

    stages {
        stage('Restore + Build') {
            steps {
                sh 'dotnet build --configuration Release'
            }
        }

        stage('Tests + Coverage') {
            steps {
                sh '''
                    rm -rf coverage
                    dotnet test \
                        --no-build \
                        --configuration Release \
                        --collect:"XPlat Code Coverage" \
                        --results-directory ./coverage
                '''
            }
        }

        stage('Diff Coverage (apenas em PR)') {
            when {
                changeRequest()
            }
            steps {
                sh '''
                    set -e

                    # Garante que temos o histórico da branch destino para o diff
                    git fetch origin ${CHANGE_TARGET}:refs/remotes/origin/${CHANGE_TARGET} || true

                    COVERAGE_FILE=$(find ./coverage -name 'coverage.cobertura.xml' -type f | head -1)
                    if [ -z "$COVERAGE_FILE" ]; then
                        echo "::error::Nenhum coverage.cobertura.xml encontrado"
                        exit 1
                    fi

                    diff-cover "$COVERAGE_FILE" \
                        --compare-branch=origin/${CHANGE_TARGET} \
                        --markdown-report=diff-cover-report.md \
                        --fail-under=80

                    echo "--- Relatório de cobertura do diff ---"
                    cat diff-cover-report.md
                '''
            }
        }

        stage('Docker Build + Push') {
            when {
                expression {
                    return !env.CHANGE_ID && env.BRANCH_NAME == env.PUBLISH_DOCKER_BRANCH
                }
            }
            steps {
                script {
                    if (env.DOCKER_REGISTRY_URL == 'IP_DA_SUA_VM:21114') {
                        error 'Configure DOCKER_REGISTRY_URL no Jenkinsfile antes de publicar no registry da VM.'
                    }

                    def commitTag = env.GIT_COMMIT ? env.GIT_COMMIT.take(7) : env.BUILD_NUMBER
                    def versionTag = "${env.BUILD_NUMBER}-${commitTag}"
                    def imageRepository = "${env.DOCKER_REGISTRY_URL}/${env.DOCKER_IMAGE_NAME}"

                    withCredentials([
                        usernamePassword(
                            credentialsId: env.DOCKER_REGISTRY_CREDENTIALS_ID,
                            usernameVariable: 'DOCKER_REGISTRY_USERNAME',
                            passwordVariable: 'DOCKER_REGISTRY_PASSWORD'
                        )
                    ]) {
                        sh """
                            set -e

                            echo "\$DOCKER_REGISTRY_PASSWORD" | docker login ${env.DOCKER_REGISTRY_URL} \
                                --username "\$DOCKER_REGISTRY_USERNAME" \
                                --password-stdin

                            docker build \
                                --tag ${imageRepository}:${versionTag} \
                                --tag ${imageRepository}:latest \
                                .

                            docker push ${imageRepository}:${versionTag}
                            docker push ${imageRepository}:latest

                            docker logout ${env.DOCKER_REGISTRY_URL}
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            // Arquiva o relatório de diff-cover (se existir) pra ver no Jenkins
            archiveArtifacts artifacts: 'diff-cover-report.md', allowEmptyArchive: true, fingerprint: false
        }
    }
}
