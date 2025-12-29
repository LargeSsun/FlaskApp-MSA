# Nginx 베이스 이미지 사용
FROM nginx:latest

# 기본 제공되는 설정 및 파일 삭제 (선택 사항)
RUN rm /etc/nginx/conf.d/default.conf

# 내 로컬의 frontend 파일들을 컨테이너 안으로 복사
COPY . /usr/share/nginx/html/

# Nginx 실행
CMD ["nginx", "-g", "daemon off;"]