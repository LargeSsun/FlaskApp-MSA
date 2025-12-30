# FlaskApp-MSA

### 프로젝트 주요 내용

이 프로젝트는 기존 docker compose 기반의 파일을 kubernates & MSA의 구조에 맞게 수정하는 것이 목표임.

기존 docker-compose.yml 파일을 참고하여 k8s 폴더 내에 각각 서버에 맞는 yaml파일들을 제작하였음.

### [12/30]

현재는 ~~망할~~ gateway/app.py에서 문제가 발생한건지 이미지가 웹에 출력되질 않음.
자세한 내용은 가장 하단 6번 사례에 있으니 참고바람.

### 트러블슈팅

이 내용은 MSA 구조에서 Nginx, Gateway, Backend 간의 통신 설정을 맞추는 아주 전형적이고 중요한 트러블슈팅 사례임.

### 📝 MSA 프로젝트 트러블슈팅 및 수정 사항 정리

1. **Nginx - Gateway 경로 매핑 문제 (404/503 Error)**
    - 문제: Nginx의 proxy_pass 설정 시 끝에 슬래시(/) 유무에 따라 Gateway로 전달되는 URL 경로가 달라짐.
    - 원인: proxy_pass [http://gateway:5000/로](http://gateway:5000/%EB%A1%9C) 설정 시 /api/가 제거된 채로 전달되는데, Gateway 코드는 /api/auth/ 전체 경로를 기다리고 있어 경로 불일치 발생.
    - 해결: Nginx: proxy_pass [http://gateway:5000](http://gateway:5000/); (슬래시 제거)로 설정하여 전체 경로( /api/...)를 그대로 전달. 
    또는 Gateway: 코드의 엔드포인트를 Nginx가 깎아낸 경로에 맞춰 수정.

---

2. **컨테이너 내부 네트워크 통신 (Localhost 문제)**
    - 문제: Gateway에서 하위 서비스(Auth, Employee 등)를 호출할 때 localhost 사용 시 연결 실패.
    - 원인: 컨테이너 환경에서 localhost는 '자기 자신'을 의미함. 다른 파드에 접근하려면 쿠버네티스 서비스(Service) 이름을 사용해야 함.
    - 해결: [http://localhost:5001](http://localhost:5001/) → http://auth-server:5001로 서비스 명칭을 기반으로 한 DNS 호출 방식으로 변경.

---

3. **MySQL 데이터 디렉토리 초기화 오류 (DB Pod Error)**
    - 문제: DB 파드가 Error 또는 CrashLoopBackOff 상태에 빠짐.
    - 원인: MySQL 이미지 특성상 데이터 디렉토리(/var/lib/mysql)에 기존 파일이 남아있으면 초기화를 거부함 (--initialize specified but the data directory has files in it).
    - 해결: 호스트 노드의 마운트 경로( /mnt/data/mysql/*)에 있는 찌꺼기 데이터를 수동으로 삭제(rm -rf) 후 파드 재시작.

---

4. **Gateway 프록시 로직 및 에러 처리 (503 Error)**
    - 문제: 하위 서비스 연결 실패 시 브라우저에 503 Service Unavailable 노출.
    - 원인: Gateway의 httpx 비동기 요청 중 RequestError가 발생하면 코드가 503 예외를 던지도록 설계됨.
    - 해결: Gateway에서 하위 서비스로 보내는 URL 구성 시 슬래시(/)가 중복되거나 누락되지 않았는지 점검. 
    httpx.AsyncClient()를 사용하여 비동기 논블로킹(Non-blocking) 방식으로 통신 구조 최적화.

---

5. **쿠버네티스 인프라 정합성 체크**
    - 내용: 파드가 재시작되어 IP가 바뀌어도 통신이 유지되도록 Service Selector와 Pod Label의 일치 여부 확인.
    - 확인 도구: kubectl get endpoints 명령어를 통해 서비스가 실제 파드 IP를 제대로 가리키고 있는지 검증.

---

6. **사진 서비스 프록시 및 라우팅 문제 (422/405/Redirect Issue)**
    - 문제: 직원 사진 업로드 후 조회 시, 엑스박스가 뜨거나 사진 주소로 접속하면 홈페이지로 리다이렉트됨.
    - 원인:
        FastAPI 경로 매칭 오류 (422): Gateway의 엔드포인트 변수명과 함수 인자명이 불일치하여 FastAPI가 경로 변수를 쿼리 스트링으로 오인함.
    
        HTTP 메서드 미지원 (405): curl -I 등의 HEAD 요청에 대해 Gateway가 GET만 허용하여 발생.
    
        MIME 타입 미지정: 응답 시 Content-Type을 image/jpeg로 명시하지 않아 브라우저가 바이너리 데이터를 텍스트/HTML로 해석함.
    
        Nginx 라우팅 간섭 (리다이렉트): 브라우저가 접속하는 Nginx(Port 30080)가 /static/uploads 경로를 Gateway로 넘겨주지 않고 자기 선에서 처리(정적 파일 미존재 시 홈으로 리다이렉트)함.
    - 해결:
        Gateway 코드 수정: 경로 변수명({photo_name})과 함수 인자를 일치시키고, Response 객체 생성 시 media_type="image/jpeg"를 강제 지정함.
    
        백엔드 검증: curl -v를 통해 Gateway Pod IP에서 실제 30KB 이상의 바이너리 데이터와 image/jpeg 헤더가 넘어오는 것을 확인(백엔드 파이프라인 정상화).

---

### 향후 과제

Nginx 설정(default.conf)에 /static/uploads/ 경로에 대한 proxy_pass 규칙을 추가하여 Gateway(5000번 포트)로 요청이 전달되도록 인프라 설정 수정 필요.