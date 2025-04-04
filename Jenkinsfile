@Library('Shared') _
pipeline {
    agent any
    
    environment{
        SONAR_HOME = tool "Sonar"
        AWS_REGION = "us-east-1" // Change this to your AWS region if different
        ECR_REPOSITORY_URI = "277707132368.dkr.ecr.us-east-1.amazonaws.com" // Replace 123456789012 with your AWS account ID
    }
    
    parameters {
        string(name: 'FRONTEND_DOCKER_TAG', defaultValue: '', description: 'Setting docker image for latest push')
        string(name: 'BACKEND_DOCKER_TAG', defaultValue: '', description: 'Setting docker image for latest push')
    }
    
    stages {
        stage("Validate Parameters") {
            steps {
                script {
                    if (params.FRONTEND_DOCKER_TAG == '' || params.BACKEND_DOCKER_TAG == '') {
                        error("FRONTEND_DOCKER_TAG and BACKEND_DOCKER_TAG must be provided.")
                    }
                }
            }
        }
        stage("Workspace cleanup"){
            steps{
                script{
                    cleanWs()
                }
            }
        }
        
        stage('Git: Code Checkout') {
            steps {
                script{
                    code_checkout("https://github.com/LondheShubham153/Wanderlust-Mega-Project.git","main")
                }
            }
        }
        
        stage("Trivy: Filesystem scan"){
            steps{
                script{
                    trivy_scan()
                }
            }
        }

        stage("OWASP: Dependency check"){
            steps{
                script{
                    owasp_dependency()
                }
            }
        }
        
        stage("SonarQube: Code Analysis"){
            steps{
                script{
                    withCredentials([string(credentialsId: 'Sonar', variable: 'SONAR_TOKEN')]) {
                        sonarqube_analysis("Sonar","wanderlust","wanderlust")
                    }
                }
            }
        }
        
        stage("SonarQube: Code Quality Gates"){
            steps{
                script{
                    echo "Running SonarQube Analysis..."
                    withCredentials([string(credentialsId: 'Sonar', variable: 'SONAR_TOKEN')]) {
                        sh "/opt/sonar-scanner/bin/sonar-scanner -Dsonar.projectKey=wanderlust -Dsonar.sources=. -Dsonar.host.url=http://54.152.241.32:9000 -Dsonar.login=${SONAR_TOKEN}"
                    }
                    sonarqube_code_quality()
                }
            }
        }
        
        stage('Exporting environment variables') {
            parallel{
                stage("Backend env setup"){
                    steps {
                        script{
                            dir("Automations"){
                                sh "bash updatebackendnew.sh"
                            }
                        }
                    }
                }
                
                stage("Frontend env setup"){
                    steps {
                        script{
                            dir("Automations"){
                                sh "bash updatefrontendnew.sh"
                            }
                        }
                    }
                }
            }
        }
        
        stage("Docker: Build Images"){
            steps{
                script{
                    dir('backend'){
                        docker_build("wanderlust-backend-beta","${params.BACKEND_DOCKER_TAG}","gibranf")
                    }
                
                    dir('frontend'){
                        docker_build("wanderlust-frontend-beta","${params.FRONTEND_DOCKER_TAG}","gibranf")
                    }
                }
            }
        }
        
        stage("ECR: Push Images"){
            steps{
                script{
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                    credentialsId: 'aws-credentials', 
                                    accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                        ecr_push("wanderlust-backend-beta", "${params.BACKEND_DOCKER_TAG}", "${AWS_REGION}", "${ECR_REPOSITORY_URI}", "gibranf")
                        ecr_push("wanderlust-frontend-beta", "${params.FRONTEND_DOCKER_TAG}", "${AWS_REGION}", "${ECR_REPOSITORY_URI}", "gibranf")
                    }
                }
            }
        }
    }
    post{
        success{
            archiveArtifacts artifacts: '*.xml', followSymlinks: false
            build job: "Wanderlust-CD", parameters: [
                string(name: 'FRONTEND_DOCKER_TAG', value: "${params.FRONTEND_DOCKER_TAG}"),
                string(name: 'BACKEND_DOCKER_TAG', value: "${params.BACKEND_DOCKER_TAG}")
            ]
        }
    }
}
