# Hướng dẫn khởi chạy dự án và kiểm thử chất lượng, bảo mật (SonarQube & Trivy)

Tài liệu này cung cấp hướng dẫn khởi chạy các dịch vụ trong dự án Ecom Shop dưới local, đồng thời hướng dẫn chi tiết cách tự thiết lập và chạy quét chất lượng mã nguồn bằng **SonarQube** và quét bảo mật mã nguồn/container bằng **Trivy** ngay tại môi trường phát triển cá nhân của bạn.

---

## 1. Khởi chạy dự án dưới Local (Development)

Dự án gồm **ecom-frontend** (React) và **ecom-backend** (3 microservices Spring Boot: `user-service`, `product-service`, `shopping-cart-service`).

### 1.1 Yêu cầu cài đặt sẵn
* **JDK 17** (cho backend)
* **Node.js v18** trở lên & **npm** (cho frontend)
* **Docker & Docker Compose** (để khởi chạy database và các công cụ bảo mật)

### 1.2 Khởi động Cơ sở dữ liệu (PostgreSQL)
Mã nguồn backend đã tích hợp sẵn docker-compose để chạy PostgreSQL.
1. Mở terminal tại thư mục `ecom-backend/`.
2. Chạy lệnh:
   ```bash
   docker-compose up -d postgres
   ```
   *Lưu ý:* Cơ sở dữ liệu PostgreSQL sẽ chạy tại cổng local `6543` (mapping vào container port `5432`). Mật khẩu mặc định là `admin`, tài khoản là `postgres`.

3. Import dữ liệu sản phẩm mẫu:
   * Chạy import file `ecom-backend/product-data.sql` vào database `postgres` để khởi tạo dữ liệu mẫu cho `product-service`.

### 1.3 Khởi chạy các Microservices (Backend)
Chạy độc lập từng service qua Maven:

* **User Service** (Cổng `5865`):
  ```bash
  cd ecom-backend/user-service
  ./mvnw spring-boot:run
  ```
* **Product Service** (Cổng `5861`):
  ```bash
  cd ecom-backend/product-service
  ./mvnw spring-boot:run
  ```
* **Shopping Cart Service** (Cổng `5863`):
  ```bash
  cd ecom-backend/shopping-cart-service
  ./mvnw spring-boot:run
  ```

### 1.4 Khởi chạy Frontend (React)
1. Di chuyển vào thư mục:
   ```bash
   cd ecom-frontend
   ```
2. Cài đặt thư viện:
   ```bash
   npm install
   ```
3. Khởi chạy dev server:
   ```bash
   npm start
   ```
   Ứng dụng React sẽ chạy tại địa chỉ `http://localhost:3000`.

---

## 2. Hướng dẫn chạy quét SonarQube dưới Local

### Bước 1: Khởi động SonarQube Container
Cách nhanh nhất để có một máy chủ SonarQube dưới local là khởi chạy thông qua Docker:
```bash
docker run -d --name sonarqube -p 9000:9000 sonarqube:community
```
* Đợi khoảng 1-2 phút để SonarQube khởi động hoàn chỉnh.
* Mở trình duyệt truy cập: `http://localhost:9000`.
* Tài khoản mặc định: **Username:** `admin` | **Password:** `admin` (Hệ thống sẽ yêu cầu đổi mật khẩu ở lần đăng nhập đầu tiên).

### Bước 2: Tạo Token quét mã nguồn
1. Sau khi đăng nhập, chọn **Manually** để tạo dự án mới hoặc vào góc phải màn hình chọn **My Account > Security**.
2. Tại mục **Tokens**, nhập tên token (ví dụ: `ecom-token`), loại token chọn `User Token`, và bấm **Generate**.
3. Sao chép Token được tạo (được hiển thị một lần duy nhất).

### Bước 3: Chạy quét dự án Backend (Maven)
Tại thư mục gốc của các microservice tương ứng, chạy lệnh Maven sau:
```bash
# Quét cho user-service
cd ecom-backend/user-service
../mvnw clean verify sonar:sonar \
  -Dsonar.projectKey=ecom-user-service \
  -Dsonar.projectName="Ecom User Service" \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=<TOKEN_CỦA_BẠN>

# Quét cho product-service
cd ecom-backend/product-service
../mvnw clean verify sonar:sonar \
  -Dsonar.projectKey=ecom-product-service \
  -Dsonar.projectName="Ecom Product Service" \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=<TOKEN_CỦA_BẠN>
```

### Bước 4: Chạy quét dự án Frontend (Node)
Tại thư mục `ecom-frontend/`, bạn dùng `npx` để kích hoạt quét:
```bash
cd ecom-frontend
npx sonar-scanner \
  -Dsonar.projectKey=ecom-frontend \
  -Dsonar.projectName="Ecom Frontend" \
  -Dsonar.sources=src \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=<TOKEN_CỦA_BẠN>
```
Kết quả quét chất lượng mã nguồn (bug, bảo mật, độ phủ test, nợ kỹ thuật) sẽ hiển thị ngay tại giao diện `http://localhost:9000`.

---

## 3. Hướng dẫn chạy quét bảo mật bằng Trivy dưới Local

Trivy được khuyên dùng chạy qua Docker để không cần cài đặt phức tạp lên hệ điều hành Windows.

### 3.1 Quét lỗ hổng Hệ thống tệp tin (Filesystem Scan)
Để quét các lỗ hổng mã nguồn và thư viện lỗi thời (package.json, pom.xml), đứng tại thư mục gốc dự án và chạy:

* **Quét toàn bộ dự án**:
  ```bash
  docker run --rm -v ${PWD}:/apps aquasec/trivy fs /apps
  ```

* **Quét riêng lẻ backend microservice (ví dụ: product-service)**:
  ```bash
  docker run --rm -v ${PWD}/ecom-backend/product-service:/apps aquasec/trivy fs /apps
  ```

* **Quét riêng lẻ frontend**:
  ```bash
  docker run --rm -v ${PWD}/ecom-frontend:/apps aquasec/trivy fs /apps
  ```

### 3.2 Quét lỗ hổng Docker Image (Container Image Scan)
Sau khi bạn build Docker Image dưới local, bạn có thể kiểm tra các lỗ hổng hệ điều hành và thư viện đóng gói bên trong image:

1. Biên dịch ứng dụng và build Docker Image cho một dịch vụ:
   ```bash
   cd ecom-backend/product-service
   # Build image dưới local với tag 'product-service:local'
   docker build -t product-service:local .
   ```
2. Chạy Trivy quét Docker Image:
   * **Trên Linux/macOS hoặc Windows (WSL/Git Bash)**:
     ```bash
     docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image product-service:local
     ```
   * **Trên Windows PowerShell**:
     ```powershell
     docker run --rm -v //./pipe/docker_engine://./pipe/docker_engine aquasec/trivy image product-service:local
     ```

Trivy sẽ xuất ra bảng phân tích chi tiết mức độ nghiêm trọng (LOW, MEDIUM, HIGH, CRITICAL) của các lỗ hổng bảo mật giúp bạn kịp thời vá lỗi.

---

## 4. Quét bảo mật hạ tầng Terraform (Checkov)
Bạn có thể quét bảo mật hạ tầng Terraform bằng Docker mà không cần cài đặt Python/Pip:
```bash
docker run --rm -v ${PWD}/terraform:/tf bridgecrew/checkov -d /tf
```
 Lệnh này sẽ tự động tìm kiếm lỗi cấu hình sai trong tất cả các module Terraform trong dự án.
