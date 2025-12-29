docker build -t hyunhojang/auth_server:v1 ./auth_server
docker build -t hyunhojang/employee_server:v1 ./employee_server
docker build -t hyunhojang/gateway:v1 ./gateway
docker build -t hyunhojang/photo_service:v1 ./photo_service
docker build -t hyunhojang/frontend:v1 ./frontend

docker push hyunhojang/auth_server:v1
docker push hyunhojang/employee_server:v1
docker push hyunhojang/gateway:v1
docker push hyunhojang/photo_service:v1
docker push hyunhojang/frontend:v1