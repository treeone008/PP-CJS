pipeline {
    agent any
    stages {
        stage('Checkout Code') {
            steps {
                // 깃허브에서 최신 코드를 당겨옵니다.
                checkout scm
            }
        }
        stage('Deploy to K8s') {
            steps {
                // K8s 마스터 노드로 배포 명령을 전송합니다.
                sh 'kubectl apply -f k8s/payguard-api.yml'
                
                // 배포된 파드의 상태를 출력하여 로그로 남깁니다.
                sh 'kubectl get pods -o wide'
            }
        }
    }
}
