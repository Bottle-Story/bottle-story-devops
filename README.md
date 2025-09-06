# 🌊 Bottle Story - 유리병 편지 서비스

## 📚 기술 스택

### 🖥 Backend
![Java](https://img.shields.io/badge/Java_17-007396?style=for-the-badge&logo=java&logoColor=white)
![Spring Boot](https://img.shields.io/badge/Spring_Boot_3.5.3-6DB33F?style=for-the-badge&logo=spring&logoColor=white)
![MyBatis](https://img.shields.io/badge/MyBatis-006D97?style=for-the-badge&logo=mybatis&logoColor=white)
![Apache Kafka](https://img.shields.io/badge/Apache_Kafka-231F20?style=for-the-badge&logo=apache-kafka&logoColor=white)
![Spring Batch](https://img.shields.io/badge/Spring_Batch-6DB33F?style=for-the-badge&logo=spring&logoColor=white)
![OAuth2](https://img.shields.io/badge/OAuth2-000000?style=for-the-badge&logo=auth0&logoColor=white)

### 🎨 Frontend
![React](https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB)
![Three.js](https://img.shields.io/badge/Three.js-000000?style=for-the-badge&logo=three.js&logoColor=white)

### 🗄 Database
![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Redis](https://img.shields.io/badge/Redis-DC382D?style=for-the-badge&logo=redis&logoColor=white)

### 🚀 DevOps
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2CA5E0?style=for-the-badge&logo=docker&logoColor=white)
![VirtualBox](https://img.shields.io/badge/VirtualBox-183A61?style=for-the-badge&logo=virtualbox&logoColor=white)

## 📖 프로젝트 개요

접속자들이 익명으로 자신의 고민이나 하고 싶은 말을 유리병 편지로 띄워서, 설정한 거리 반경에 들어있는 다른 사용자에게 실시간으로 전달되는 감성적인 소통 플랫폼입니다.

### 🌟 주요 기능

- **실시간 유리병 편지**: 사용자 위치 기반 유리병 편지 확산 시스템
- **3D 몰입형 UI**: React Three Fiber 기반 3D 바다 환경
- **날씨 연동 UI**: 실시간 날씨에 따른 바다, 하늘, 파티클 효과 자동 변화
- **시간대별 씬 전환**: 새벽 → 일출 → 낮 → 일몰 → 밤
- **실시간 접속자 수**: 현재 접속 중인 사용자 수 표시
- **답글 실시간 전송**: WebSocket을 통한 실시간 답글 애니메이션


### 1. 유리병 편지를 띄우는 화면
![](https://velog.velcdn.com/images/agida0413/post/89b60f0c-8ffb-4b1f-948d-869762a13708/image.png)
### 2.누군가 답장 글귀를 작성하여 하늘에 답장글귀가 뜨는 화면
![](https://velog.velcdn.com/images/agida0413/post/661ada84-fe80-4e09-8425-76afe5ae2d71/image.png)

### 3.일출 시간이 되어 UI가 변경되는 상황
![](https://velog.velcdn.com/images/agida0413/post/9a2fbf0c-937c-4d6c-b4b6-064f2adab476/image.png)




### 4. 답장 글귀를 작성하는 상황

![](https://velog.velcdn.com/images/agida0413/post/bdafb5ca-3dd8-4f09-99f3-4598072850d5/image.gif)

### 5. 답장글귀가 출력되는 상황

![](https://velog.velcdn.com/images/agida0413/post/f560704b-5da5-439d-bb33-65f574b50f0c/image.gif)

### 6. 새로운 유리병을 띄우는 상황
![](https://velog.velcdn.com/images/agida0413/post/0963104e-94ed-4efa-b8a2-07a9a259e59d/image.gif)


## 🏗 시스템 아키텍처

### MSA 서비스 구성

| 서비스 | 역할 | 주요 기술 |
|--------|------|-----------|
| **Member Service** | OAuth2 기반 인증/인가, 접속자 수 관리, 위치 기반 매칭 | Spring Security, OAuth2, JWT |
| **Weather-BGM Service** | 기상청 API 연동, Scene 이펙트 결정 | WebClient, 외부 API 연동 |
| **Batch Service** | 실시간 데이터 수집, 세션 생명주기 관리, 통계 처리 | Spring Batch |
| **Realtime Service** | WebSocket 연결 관리, 실시간 푸시, 사용자 위치 수집 | STOMP, SockJS |
| **Bottle Service** | 유리병 편지 CRUD, 좌표 이동 로직, 소멸 규칙 관리 | Redis GEO |

### 이벤트 기반 아키텍처
- **Kafka** 기반 비동기 메시지 처리
- 서비스 간 느슨한 결합으로 확장성 보장
- 이벤트 상태 추적을 통한 안정성 확보

## 💾 Redis 키 관리

| 키 이름 | 데이터 타입 | 용도 | TTL |
|---------|------------|------|-----|
| `WS_SESSIONS` | Sorted Set | 웹소켓 세션 생명주기 관리 | 5분 |
| `GEO:MEMBER` | GEO | 실시간 사용자 위치 저장 | - |
| `GEO:BOTTLE` | GEO | 유리병 편지 위치 저장 | - |
| `refresh:{userId}` | String | Refresh 토큰 저장 | 7일 |
| `blacklist:{token}` | String | 블랙리스트 토큰 저장 | 7일 |
| `CM_*_CODE` | Hash | 공통 코드 관리 (상태, 날씨, 파티클 등) | - |

### GEO 타입 활용
```java
// 사용자 위치 저장
redisTemplate.opsForGeo().add(RedisKey.GEO_MEMBER, 
    new GeoLocation<>(userId, new Point(longitude, latitude)));

// 반경 10km 내 유리병 검색
Circle circle = new Circle(userPoint, new Distance(10.0, Metrics.KILOMETERS));
List<String> nearbyBottles = redisTemplate.opsForGeo().radius(RedisKey.GEO_BOTTLE, circle);
```

## 🎯 핵심 비즈니스 로직

### 유리병 편지 플로우
1. 사용자가 유리병 편지를 작성하여 바다에 띄움
2. 편지는 가까운 사람에게 먼저 노출됨
3. 발견한 사용자는 **흘려보내기** 또는 **답글 작성** 선택
4. **흘려보내기**: 10km 범위 내 랜덤 위치로 이동하여 더 먼 사람에게 확산
5. **답글 작성**: 편지 소멸 후 원작성자에게 실시간 애니메이션으로 전달

### 실시간 데이터 수집
- **날씨 데이터**: 기상청 API 30분마다 배치 수집
- **일출/일몰 데이터**: sunrise-sunset.org API 일별 수집
- **AI BGM**: 날씨 + 시간대 조합으로 맞춤 배경음악 추천

### 시간대별 Scene 코드 산출
```
새벽 (Pre-dawn): now < sunrise
일출 (Sunrise): sunrise ≤ now < sunrise + 60분
낮 (Daytime): sunrise + 60분 ≤ now < sunset - 30분
일몰 (Sunset): sunset - 30분 ≤ now < sunset
밤 (Night): now ≥ sunset
```

## 🚀 개발 환경 및 배포

### 로컬 개발환경
- **VirtualBox** 기반 VM 클러스터
- **VPN** 을 통한 개발환경 네트워크 구축
- **Docker Compose** 를 통한 로컬 서비스 관리

### CI/CD 파이프라인
- **Kubernetes** 기반 컨테이너 오케스트레이션
- **DEV/PRD** 환경 분리 운영
- 자동화된 빌드 및 배포 프로세스

## 📊 데이터 모델링

### 주요 엔티티
- **MEMBER**: 사용자 정보 및 OAuth2 연동 데이터
- **BOTTLE_LETTER**: 유리병 편지 내용 및 상태 관리
- **WEATHER_BGM**: 날씨 히스토리 및 Scene 코드 관리
- **COMMON_CODE**: 시스템 공통 코드 관리

## 🎮 사용자 경험

### UI/UX 특징
- **3D 바다 환경**: React Three Fiber로 구현된 몰입감 있는 UI
- **날씨 반응형 UI**: 실시간 날씨에 따른 바다/하늘/파티클 효과 변화
- **감성적 애니메이션**: 답글 수신 시 바다에서 하늘로 올라가는 텍스트 애니메이션
- **직관적 인터랙션**: 유리병 클릭으로 편지 확인, 간단한 답글 작성

### 실시간 기능
- **WebSocket**: STOMP 프로토콜 기반 실시간 양방향 통신
- **접속자 수**: 실시간 온라인 사용자 수 표시
- **위치 추적**: 사용자 동의 하에 실시간 위치 정보 수집
- **생명주기 관리**: 지수 백오프 전략을 통한 안정적인 연결 관리

## 🔧 기술적 도전과 해결

### 성과
- **MSA 구조**에서 메시징 큐를 통한 서비스 간 통신 구현
- **Kafka** 브로드캐스팅을 통한 실시간 이벤트 처리
- **Kubernetes** 클러스터 구축 및 VM 환경 관리
- **개발환경 네트워크** 구축 (VPN)

### 향후 개선 사항
- **Saga 패턴** 적용을 통한 분산 트랜잭션 관리
- **CQRS 패턴** 도입으로 읽기/쓰기 성능 최적화
- **데이터 정합성** 보장을 위한 추가적인 아키텍처 개선

