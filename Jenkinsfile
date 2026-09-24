pipeline {
    agent any

    environment {
        SNYK_TOKEN = credentials('snyk-token-id')
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        KUBECONFIG = credentials('kubeconfig-credentials-id')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Security Scan') {
            steps {
                sh 'snyk test --all-projects'
            }
        }

        stage('Make Scripts Executable') {
            steps {
                sh 'chmod +x ./scripts/*.sh'
            }
        }

        stage('Terraform Provisioning') {
            steps {
                sh './scripts/deploy-terraform.sh'
            }
        }

        stage('Kubernetes & Helm Deployment') {
            steps {
                sh './scripts/deploy-helm.sh'
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}