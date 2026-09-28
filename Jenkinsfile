pipeline {
    agent any

    parameters {
        choice(name: 'CLOUD', choices: ['aws', 'gcp', 'azure'],
               description: 'Cloud provider to provision ($0 free tier)')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'],
               description: 'Environment to provision and deploy')
        choice(name: 'ACTION', choices: ['up', 'apply', 'plan'],
               description: "Pipeline action: 'up' = build + push + terraform apply (full $0 deploy)")
        string(name: 'IMAGE_TAG', defaultValue: '',
               description: 'Container image tag (defaults to BUILD_NUMBER)')
    }

    environment {
        SNYK_TOKEN            = credentials('snyk-token-id')
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        GOOGLE_CLOUD_PROJECT  = credentials('gcp-project-id')
        ARM_CLIENT_ID         = credentials('azure-client-id')
        ARM_CLIENT_SECRET     = credentials('azure-client-secret')
        ARM_TENANT_ID         = credentials('azure-tenant-id')
        ARM_SUBSCRIPTION_ID   = credentials('azure-subscription-id')
        CLOUDFLARE_API_TOKEN  = credentials('cloudflare-api-token')
        // $0 container registry: GHCR public repo (no ACR bill)
        REGISTRY              = 'ghcr.io/nikhilsrh07'
        IMAGE_REPOSITORY      = "${REGISTRY}/portfolio-website"
        GITHUB_TOKEN          = credentials('github-token')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Security Scan') {
            steps {
                sh 'snyk test --all-projects --severity-threshold=high'
            }
        }

        stage('Build & Push Image') {
            steps {
                script {
                    def tag = params.IMAGE_TAG?.trim() ? params.IMAGE_TAG.trim() : env.BUILD_NUMBER
                    env.EFFECTIVE_IMAGE_TAG = tag
                }
                sh "echo ${GITHUB_TOKEN} | docker login ghcr.io -u nikhilsrh07 --password-stdin"
                sh "docker build -t ${IMAGE_REPOSITORY}:${EFFECTIVE_IMAGE_TAG} ./src"
                sh "docker push ${IMAGE_REPOSITORY}:${EFFECTIVE_IMAGE_TAG}"
            }
        }

        stage('Make Scripts Executable') {
            steps {
                sh 'chmod +x ./scripts/*.sh'
            }
        }

        stage('Terraform Provisioning & Deploy') {
            when { expression { params.ACTION in ['up', 'apply'] } }
            steps {
                sh """
                    GITOPS_IMAGE_REPOSITORY=${IMAGE_REPOSITORY} \
                    GITOPS_IMAGE_TAG=${EFFECTIVE_IMAGE_TAG} \
                    ./scripts/gitops.sh --action apply \
                        --cloud ${params.CLOUD} \
                        --environment ${params.ENVIRONMENT} \
                        --auto-approve
                """
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
