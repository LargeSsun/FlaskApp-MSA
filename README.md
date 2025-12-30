# FlaskApp-MSA
### 프로젝트 주요 내용

이 프로젝트는 기존 docker compose 기반의 파일을 kubernates & MSA의 구조에 맞게 수정하는 것이 목표임.

### 트러블슈팅

이 내용은 MSA 구조에서 Nginx, Gateway, Backend 간의 통신 설정을 맞추는 아주 전형적이고 중요한 트러블슈팅 사례임.

📝 MSA 프로젝트 트러블슈팅 및 수정 사항 정리
1. Nginx - Gateway 경로 매핑 문제 (404/503 Error)
문제: Nginx의 proxy_pass 설정 시 끝에 슬래시(/) 유무에 따라 Gateway로 전달되는 URL 경로가 달라짐.

원인: proxy_pass http://gateway:5000/로 설정 시 /api/가 제거된 채로 전달되는데, Gateway 코드는 /api/auth/ 전체 경로를 기다리고 있어 경로 불일치 발생.

해결:

Nginx: proxy_pass http://gateway:5000; (슬래시 제거)로 설정하여 전체 경로( /api/...)를 그대로 전달.

또는 Gateway: 코드의 엔드포인트를 Nginx가 깎아낸 경로에 맞춰 수정.

2. 컨테이너 내부 네트워크 통신 (Localhost 문제)
문제: Gateway에서 하위 서비스(Auth, Employee 등)를 호출할 때 localhost 사용 시 연결 실패.

원인: 컨테이너 환경에서 localhost는 '자기 자신'을 의미함. 다른 파드에 접근하려면 쿠버네티스 서비스(Service) 이름을 사용해야 함.

해결: http://localhost:5001 → http://auth-server:5001로 서비스 명칭을 기반으로 한 DNS 호출 방식으로 변경.

3. MySQL 데이터 디렉토리 초기화 오류 (DB Pod Error)
문제: DB 파드가 Error 또는 CrashLoopBackOff 상태에 빠짐.

원인: MySQL 이미지 특성상 데이터 디렉토리(/var/lib/mysql)에 기존 파일이 남아있으면 초기화를 거부함 (--initialize specified but the data directory has files in it).

해결: 호스트 노드의 마운트 경로( /mnt/data/mysql/*)에 있는 찌꺼기 데이터를 수동으로 삭제(rm -rf) 후 파드 재시작.

4. Gateway 프록시 로직 및 에러 처리 (503 Error)
문제: 하위 서비스 연결 실패 시 브라우저에 503 Service Unavailable 노출.

원인: Gateway의 httpx 비동기 요청 중 RequestError가 발생하면 코드가 503 예외를 던지도록 설계됨.

해결:

Gateway에서 하위 서비스로 보내는 URL 구성 시 슬래시(/)가 중복되거나 누락되지 않았는지 점검.

httpx.AsyncClient()를 사용하여 비동기 논블로킹(Non-blocking) 방식으로 통신 구조 최적화.

5. 쿠버네티스 인프라 정합성 체크
내용: 파드가 재시작되어 IP가 바뀌어도 통신이 유지되도록 Service Selector와 Pod Label의 일치 여부 확인.

확인 도구: kubectl get endpoints 명령어를 통해 서비스가 실제 파드 IP를 제대로 가리키고 있는지 검증.

💡 현재 환경 최종 아키텍처 흐름
Browser: POST /api/auth/login

Nginx (Port 30080): 요청 수신 후 gateway:5000으로 바이패스

Gateway (Port 5000): 요청 경로 인식 후 auth-server:5001/login으로 비동기 프록시

Auth-Server (Port 5001): db:3306 접속 후 사용자 인증 수행