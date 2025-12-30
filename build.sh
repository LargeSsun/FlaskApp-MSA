docker build -t hyunhojang/auth_server:v0.6 ./auth_server
docker build -t hyunhojang/employee_server:v0.6 ./employee_server
docker build -t hyunhojang/gateway:v0.6 ./gateway
docker build -t hyunhojang/photo_service:v0.6 ./photo_service
docker build -t hyunhojang/frontend:v0.6 ./frontend
docker push hyunhojang/auth_server:v0.6
docker push hyunhojang/employee_server:v0.6
docker push hyunhojang/gateway:v0.6
docker push hyunhojang/photo_service:v0.6
docker push hyunhojang/frontend:v0.6