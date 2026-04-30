# Hướng dẫn khởi tạo dữ liệu mồi (Database Seeding) cho RDS

Khi bạn sử dụng `terraform destroy` và `terraform apply` lại, toàn bộ hạ tầng (bao gồm cả database Amazon RDS) sẽ bị xóa và tạo mới hoàn toàn. Do đó, database mới sẽ trống rỗng và giao diện ứng dụng sẽ không hiển thị sản phẩm nào.

Dưới đây là hướng dẫn các bước để bơm dữ liệu (Seed Data) từ file `product-data.sql` vào cơ sở dữ liệu RDS PostgreSQL từ máy tính của bạn thông qua một Pod tạm thời trong Kubernetes.

## Các bước thực hiện:

### Bước 1: Khởi tạo một Pod PostgreSQL Client tạm thời
Do RDS nằm trong mạng nội bộ (Private Subnet) của AWS, cách an toàn nhất để truy cập là tạo một Pod trung gian bên trong cụm EKS.

Mở terminal tại thư mục gốc của dự án (`d:\WorkSpace\ecom_shop`) và chạy lệnh:
```bash
kubectl run psql-client --image=postgres:15 -n ecom-dev --restart=Never -- sleep 3600
```

Chờ khoảng 10-20 giây để pod khởi động thành công:
```bash
kubectl wait --for=condition=ready pod/psql-client -n ecom-dev --timeout=60s
```

### Bước 2: Copy file SQL vào Pod
Tiếp theo, bạn copy file `product-data.sql` từ máy tính vào bên trong pod vừa tạo:
```bash
kubectl cp ecom-backend/product-data.sql ecom-dev/psql-client:/tmp/product-data.sql
```

### Bước 3: Lấy thông tin kết nối RDS (Host, Mật khẩu)
Do ứng dụng `product-service` đã được nối với Database và được nạp Secret đầy đủ, bạn có thể xem các biến môi trường của Pod `product-service` để lấy mật khẩu và địa chỉ Host RDS.

Đầu tiên lấy tên pod của `product-service`:
```bash
kubectl get pods -n ecom-dev | findstr product-service
```

Sau đó xem các biến môi trường (Thay `<ten_pod>` bằng tên pod lấy được ở trên):
```bash
kubectl exec -n ecom-dev <ten_pod> -- env | findstr SPRING_DATASOURCE
```
Ghi lại 2 giá trị quan trọng:
- `SPRING_DATASOURCE_URL`: (VD: `jdbc:postgresql://dev-ecom-postgres.xxxxxx.rds.amazonaws.com:5432/ecomdb`) -> Bạn chỉ cần lấy phần **host**: `dev-ecom-postgres.xxxxxx.rds.amazonaws.com`
- `SPRING_DATASOURCE_PASSWORD`: Đây là mật khẩu kết nối.

### Bước 4: Chạy file SQL để nạp dữ liệu
Chạy lệnh sau để thực thi file SQL. Thay `<MAT_KHAU_CUA_BAN>` bằng password và `<RDS_HOST>` bằng host bạn vừa lấy ở Bước 3:

```bash
kubectl exec -it -n ecom-dev psql-client -- bash -c "PGPASSWORD='<MAT_KHAU_CUA_BAN>' psql -h <RDS_HOST> -p 5432 -U ecomadmin -d ecomdb -f /tmp/product-data.sql"
```

Nếu thành công, terminal sẽ trả về nhiều dòng `INSERT 0 1` hoặc `INSERT 0 8`.

### Bước 5: Dọn dẹp
Sau khi chạy xong, hãy xóa pod tạm thời để giải phóng tài nguyên:
```bash
kubectl delete pod psql-client -n ecom-dev
```

Sau khi hoàn tất, bạn ra trình duyệt ấn **Ctrl + F5** là giao diện sẽ hiển thị đầy đủ thông tin sản phẩm!

---
*Ghi chú: Nếu trong tương lai bạn muốn tự động hóa hoàn toàn quy trình này, bạn có thể thiết lập `Flyway`, `Liquibase` hoặc sử dụng cơ chế `spring.sql.init.mode=always` trong file `application.yaml` của Spring Boot để nó tự động bơm dữ liệu ngay khi Service khởi động.*
