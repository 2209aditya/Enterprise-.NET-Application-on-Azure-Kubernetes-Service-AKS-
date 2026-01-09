pipeline {
    agent any

    tools {
        dotnet 'dotnet8'
    }

    environment {
        ACR = "dotnetacrprod.azurecr.io"
        IMAGE = "dotnet-app"
        TAG = "${BUILD_NUMBER}"
        SONAR_PROJECT = "dotnet-app"
    }

    stages {
        stage('🔍 Checkout') {
            steps {
                echo '📥 Checking out code from GitHub...'
                git branch: 'main', url: 'https://github.com/org/dotnet-app.git'
            }
        }

        stage('🔧 Restore Dependencies') {
            steps {
                echo '📦 Restoring NuGet packages...'
                sh 'dotnet restore'
            }
        }

        stage('🏗️ Build Application') {
            steps {
                echo '🔨 Building .NET application...'
                sh 'dotnet build --no-restore --configuration Release'
            }
        }

        stage('🧪 Run Unit Tests') {
            steps {
                echo '🧪 Running xUnit tests with code coverage...'
                sh '''
                    dotnet test \
                        --no-build \
                        --configuration Release \
                        --collect:"XPlat Code Coverage" \
                        --logger "trx;LogFileName=test-results.trx"
                '''
            }
            post {
                always {
                    junit '**/test-results.trx'
                }
            }
        }

        stage('📊 SonarQube Analysis') {
            steps {
                echo '📊 Running SonarQube code analysis...'
                withSonarQubeEnv('sonarqube') {
                    sh '''
                        dotnet sonarscanner begin \
                            /k:"${SONAR_PROJECT}" \
                            /d:sonar.host.url="${SONAR_HOST_URL}" \
                            /d:sonar.login="${SONAR_AUTH_TOKEN}"
                        dotnet build --configuration Release
                        dotnet sonarscanner end /d:sonar.login="${SONAR_AUTH_TOKEN}"
                    '''
                }
            }
        }

        stage('🛡️ OWASP Dependency Check') {
            steps {
                echo '🔍 Scanning for vulnerable dependencies...'
                sh '''
                    dependency-check.sh \
                        --project "${IMAGE}" \
                        --scan . \
                        --format HTML \
                        --format JSON \
                        --out dependency-check-report
                '''
            }
            post {
                always {
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'dependency-check-report',
                        reportFiles: 'dependency-check-report.html',
                        reportName: 'OWASP Dependency Check'
                    ])
                }
            }
        }

        stage('📦 Publish Application') {
            steps {
                echo '📦 Publishing .NET application...'
                sh 'dotnet publish -c Release -o publish'
            }
        }

        stage('🐳 Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                sh '''
                    docker build \
                        -t ${ACR}/${IMAGE}:${TAG} \
                        -t ${ACR}/${IMAGE}:latest \
                        .
                '''
            }
        }

        stage('🔒 Trivy Security Scan') {
            steps {
                echo '🔍 Scanning Docker image for vulnerabilities...'
                sh '''
                    trivy image \
                        --severity HIGH,CRITICAL \
                        --exit-code 1 \
                        --no-progress \
                        ${ACR}/${IMAGE}:${TAG}
                '''
            }
        }

        stage('🚀 Push to ACR') {
            steps {
                echo '📤 Pushing image to Azure Container Registry...'
                withCredentials([usernamePassword(
                    credentialsId: 'acr-credentials',
                    usernameVariable: 'ACR_USER',
                    passwordVariable: 'ACR_PASSWORD'
                )]) {
                    sh '''
                        echo ${ACR_PASSWORD} | docker login ${ACR} -u ${ACR_USER} --password-stdin
                        docker push ${ACR}/${IMAGE}:${TAG}
                        docker push ${ACR}/${IMAGE}:latest
                    '''
                }
            }
        }

        stage('📝 Update Manifest') {
            steps {
                echo '📝 Updating Kubernetes manifest with new image tag...'
                sh '''
                    sed -i "s|image: .*|image: ${ACR}/${IMAGE}:${TAG}|g" k8s/deployment.yaml
                    git add k8s/deployment.yaml
                    git commit -m "Update image to ${TAG}" || true
                '''
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully!'
            slackSend(
                color: 'good',
                message: "✅ Build #${BUILD_NUMBER} succeeded for ${IMAGE}:${TAG}"
            )
        }
        failure {
            echo '❌ Pipeline failed!'
            slackSend(
                color: 'danger',
                message: "❌ Build #${BUILD_NUMBER} failed for ${IMAGE}"
            )
        }
        always {
            cleanWs()
        }
    }
}
