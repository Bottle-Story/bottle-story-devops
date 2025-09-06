# Bottle Story Production Environment

이 디렉토리는 Bottle Story 마이크로서비스의 운영 환경 배포 설정을 포함합니다.

## 🏗️ 아키텍처 개요

### AWS 인프라 구성
- **EKS**: Kubernetes 클러스터 (마스터 노드 1개, 워커 노드 2개)
- **RDS MySQL**: 관계형 데이터베이스
- **ElastiCache Redis**: 캐싱 및 세션 저장소
- **EC2 Kafka**: 메시징 시스템
- **ALB**: Application Load Balancer
- **Route 53**: DNS 관리
- **ECR**: 컨테이너 레지스트리

### 마이크로서비스 구성
- **Member Service**: 회원 관리 (`/api/v1/member`)
- **Bottle Service**: 메인 비즈니스 로직 (`/api/v1/bottle`)
- **Realtime Service**: 실시간 처리 (`/api/v1/realtime`)
- **Weather Service**: 날씨/음악 (`/api/v1/weather`, `/api/v1/bgm`)
- **Batch Service**: 배치 작업 (`/api/v1/admin`)
- **Frontend**: React 애플리케이션 (`/`)




## 🚀 배포 방법

### 1. 사전 준비

#### AWS 인프라 설정
```bash
# EKS 클러스터 생성
eksctl create cluster --name bottle-story-prod --region ap-northeast-2 --nodegroup-name workers --node-type t3.medium --nodes 2

# ECR 리포지토리 생성
aws ecr create-repository --repository-name bottle-story/member --region ap-northeast-2
aws ecr create-repository --repository-name bottle-story/bottle --region ap-northeast-2
# ... (기타 서비스들)
```

#### 환경 변수 설정
```bash
export AWS_ACCOUNT_ID="123456789012"
export CERTIFICATE_ID="your-acm-certificate-id"
export WAF_ID="your-waf-id"
export DB_USERNAME="your-db-username"
export DB_PASSWORD="your-db-password"
export JWT_SECRET_KEY="your-jwt-secret"
# ... (기타 시크릿 값들)
```

### 2. 전체 서비스 배포
```bash
cd common/
./deploy-all.sh all
```

### 3. 개별 서비스 배포
```bash
# 특정 서비스만 배포
./deploy-all.sh member
./deploy-all.sh bottle
./deploy-all.sh frontend

# Ingress만 배포
./deploy-all.sh ingress
```

### 4. 배포 확인
```bash
# 배포 상태 확인
./deploy-all.sh verify

# 또는 직접 확인
kubectl get pods -n bottle-story-prod
kubectl get svc -n bottle-story-prod
kubectl get ingress -n bottle-story-prod
```

## 🔧 Jenkins CI/CD 설정

### Jenkins 필수 플러그인
- Docker Pipeline
- Kubernetes CLI
- AWS Steps
- Slack Notification
- HTML Publisher

### Jenkins Credentials 설정
```
- aws-account-id: AWS 계정 ID
- k8s-prod-config: EKS kubeconfig 파일
- docker_password: ECR 접근용 AWS 자격증명
- slack-token: Slack 알림용 토큰
```

### 파이프라인 트리거 설정
```groovy
triggers {
    // GitHub webhook으로 product 브랜치 push 시 트리거
    githubPush()
}
```

## 🔐 보안 설정

### 네트워크 정책
- 네임스페이스 격리
- 인그레스/이그레스 트래픽 제어
- 서비스간 통신 허용

### Pod 보안
- Non-root 사용자 실행
- Security Context 설정
- 리소스 제한 적용

### Secrets 관리
- 모든 민감 정보는 Kubernetes Secret으로 관리
- 환경 변수를 통한 주입
- AWS Secrets Manager 통합 (선택사항)



## 🔄 운영 가이드

### 스케일링
```bash
# 수동 스케일링
kubectl scale deployment member-service-deployment --replicas=5 -n bottle-story-prod

# HPA 설정 확인
kubectl get hpa -n bottle-story-prod
```

### 롤백
```bash
# 서비스 롤백
./deploy-all.sh rollback member

# Helm 롤백
helm rollback member-service-prod -n bottle-story-prod
```

### 디버깅
```bash
# 로그 확인
kubectl logs -f deployment/member-service-deployment -n bottle-story-prod

# Pod 접속
kubectl exec -it <pod-name> -n bottle-story-prod -- /bin/sh

# 서비스 상태 확인
kubectl describe svc member-service -n bottle-story-prod
```

## 🛠️ 트러블슈팅

### 일반적인 문제들

1. **Pod가 시작되지 않는 경우**
   - 이미지 pull 오류: ECR 권한 확인
   - 리소스 부족: 노드 리소스 확인
   - ConfigMap/Secret 누락: 설정 파일 확인

2. **ALB가 동작하지 않는 경우**
   - AWS Load Balancer Controller 설치 확인
   - 보안 그룹 및 서브넷 설정 확인
   - 인증서 및 WAF 설정 확인

3. **서비스간 통신 문제**
   - Network Policy 설정 확인
   - Service Discovery 동작 확인
   - DNS 해상도 문제 확인

### 성능 최적화

1. **JVM 튜닝**
   - 적절한 힙 메모리 설정
   - GC 알고리즘 선택
   - JIT 컴파일러 최적화

2. **컨테이너 최적화**
   - 멀티 스테이지 빌드 활용
   - 이미지 크기 최소화
   - 레이어 캐싱 활용

3. **Kubernetes 최적화**
   - 리소스 요청/제한 적절히 설정
   - 노드 어피니티 활용
   - Pod Disruption Budget 설정
