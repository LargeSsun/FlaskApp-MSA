docker build -t hyunhojang/auth_server:v0.7 ./auth_server
docker build -t hyunhojang/employee_server:v0.7 ./employee_server
docker build -t hyunhojang/gateway:v1.6 ./gateway
docker build -t hyunhojang/photo_service:v0.9 ./photo_service
docker build -t hyunhojang/frontend:v0.8 ./frontend
docker push hyunhojang/auth_server:v0.7
docker push hyunhojang/employee_server:v0.7
docker push hyunhojang/gateway:v1.6
docker push hyunhojang/photo_service:v0.9
docker push hyunhojang/frontend:v0.8