pipeline {
    agent any
    environment {
        REGISTRY   = "nikhilsrh07acr.azurecr.io"
        IMAGE_NAME = "nodejs-multi-cloud-app"
        IMAGE_TAG  = "${BUILD_NUMBER}"
    }
    stages {
        stage('Snyk Vulnerability Scan') {
            steps { sh 'snyk test --severity-threshold=high ./src' }
        }
        stage('Release & Push Image') {
            when { branch 'main' }
            steps {
                sh "docker build -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} ./src"
                sh "docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }
    }
}
