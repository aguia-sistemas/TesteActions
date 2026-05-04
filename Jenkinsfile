pipeline {
    agent any

    options {
        timeout(time: 30, unit: 'MINUTES')
    }

    environment {
        DOTNET_NOLOGO = 'true'
        DOTNET_CLI_TELEMETRY_OPTOUT = '1'
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
    }

    post {
        always {
            // Arquiva o relatório de diff-cover (se existir) pra ver no Jenkins
            archiveArtifacts artifacts: 'diff-cover-report.md', allowEmptyArchive: true, fingerprint: false
        }
    }
}
