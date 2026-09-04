pipeline {
    agent any
    // 자주 쓰는 변수들을 묶어둡니다. (BUILD_NUMBER는 Jenkins가 자동 부여하는 빌드 번호입니다)
    environment {
        REGISTRY = "ghcr.io/treeone008"
        IMAGE_NAME = "payguard-api"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }
    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }
        stage('Docker Build') {
            steps {
                // 1. 코드를 도커 이미지로 구워냅니다.
                sh 'docker build -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} .'
            }
        }
        stage('Docker Push') {
            steps {
                // 2. 아까 등록한 Jenkins 크리덴셜(ghcr-login)을 꺼내서 GHCR에 로그인하고 이미지를 업로드합니다.
                withCredentials([usernamePassword(credentialsId: 'ghcr-login', passwordVariable: 'GHCR_PAT', usernameVariable: 'GHCR_USER')]) {
                    sh 'echo "${GHCR_PAT}" | docker login ghcr.io -u "${GHCR_USER}" --password-stdin'
                    sh 'docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}'
                }
            }
        }
        stage('Deploy to K8s') {
            steps {
                // 3. K8s yaml 파일 내의 가짜 image 경로를 '이번에 빌드된 진짜 이미지 경로'로 치환(sed)합니다.
                sh "sed -i 's|image: .*|image: ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}|g' k8s/payguard-api.yaml"
                
                // 4. 클러스터에 배포합니다.
                sh 'kubectl apply -f k8s/payguard-api.yaml'
            }
        }
    }
}
