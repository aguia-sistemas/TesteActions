pipeline {
    agent any

    options {
        timeout(time: 30, unit: 'MINUTES')
    }

    environment {
        DOTNET_NOLOGO = 'true'
        DOTNET_CLI_TELEMETRY_OPTOUT = '1'
        DOCKER_REGISTRY_URL = 'wcs01.aguiasistemas.com.br'
        DOCKER_IMAGE_NAME = 'testeactions'
        DOCKER_REGISTRY_CREDENTIALS_ID = 'docker-registry-credentials'
        PUBLISH_DOCKER_BRANCH = 'develop'
    }

    stages {
        stage('Restore + Build') {
            steps {
                sh 'dotnet build --configuration Release -m:1'
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
                        --results-directory ./coverage \
                        -m:1
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
                    if (!env.GIT_COMMIT) {
                        error "GIT_COMMIT não disponível — não é possível gerar a tag"
                    }
                    def shortSha = env.GIT_COMMIT.take(7)
                    def versionTag = "dev_${shortSha}"
                    def imageRepository = "${env.DOCKER_REGISTRY_URL}/${env.DOCKER_IMAGE_NAME}"

                    withCredentials([
                        usernamePassword(
                            credentialsId: env.DOCKER_REGISTRY_CREDENTIALS_ID,
                            usernameVariable: 'REG_USER',
                            passwordVariable: 'REG_PASS'
                        )
                    ]) {
                        sh """
                            set -e

                            echo "\$REG_PASS" | docker login ${env.DOCKER_REGISTRY_URL} \
                                --username "\$REG_USER" \
                                --password-stdin

                            docker build \
                                --tag ${imageRepository}:${versionTag} \
                                .

                            docker push ${imageRepository}:${versionTag}

                            docker logout ${env.DOCKER_REGISTRY_URL}
                        """
                    }

                    echo "Imagem publicada: ${imageRepository}:${versionTag}"
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'diff-cover-report.md', allowEmptyArchive: true, fingerprint: false
        }
    }
}
