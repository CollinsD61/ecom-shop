#!/bin/bash

# Disable MSYS/Git Bash automatic path conversion (Windows)
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL="*"

# ==============================================================================
# Script: seed_database.sh
# Tự động nạp dữ liệu mồi (Seed Data) vào Amazon RDS thông qua EKS
# ==============================================================================

NAMESPACE="ecom-dev"
SQL_FILE="ecom-backend/product-data.sql"
CLIENT_POD="psql-client-job"

echo "🚀 Bắt đầu quá trình nạp dữ liệu mồi..."

# 1. Kiểm tra file SQL
if [ ! -f "$SQL_FILE" ]; then
    echo "❌ Không tìm thấy file $SQL_FILE! Vui lòng chạy script tại thư mục gốc của dự án."
    exit 1
fi

# 2. Tìm Product Service Pod để lấy thông tin kết nối
echo "🔍 Đang trích xuất thông tin kết nối RDS từ Product Service..."
PRODUCT_POD=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/component=product-service -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$PRODUCT_POD" ]; then
    echo "❌ Không tìm thấy Product Service Pod. Ứng dụng đã được deploy chưa?"
    exit 1
fi

echo "✅ Tìm thấy Pod: $PRODUCT_POD"

# Lấy biến môi trường từ Pod
DB_URL=$(kubectl exec -n "$NAMESPACE" "$PRODUCT_POD" -- printenv SPRING_DATASOURCE_URL 2>/dev/null | tr -d '\r')
DB_PASS=$(kubectl exec -n "$NAMESPACE" "$PRODUCT_POD" -- printenv SPRING_DATASOURCE_PASSWORD 2>/dev/null | tr -d '\r')
DB_USER=$(kubectl exec -n "$NAMESPACE" "$PRODUCT_POD" -- printenv SPRING_DATASOURCE_USERNAME 2>/dev/null | tr -d '\r')

# Fallback username
DB_USER=${DB_USER:-ecomadmin}

# Bóc tách Host và DB name từ chuỗi JDBC URL (jdbc:postgresql://<host>:5432/<dbname>)
DB_HOST=$(echo "$DB_URL" | sed -E 's|jdbc:postgresql://([^:/]+).*|\1|')
DB_NAME=$(echo "$DB_URL" | sed -E 's|.*:5432/([^?]+).*|\1|')
DB_NAME=${DB_NAME:-ecomdb}

if [ -z "$DB_HOST" ] || [ -z "$DB_PASS" ]; then
    echo "❌ Không thể trích xuất Database Host hoặc Password từ Pod $PRODUCT_POD"
    echo "   Kiểm tra ExternalSecret đã sync thành công chưa:"
    echo "   kubectl get externalsecrets -n $NAMESPACE"
    exit 1
fi

echo "✅ Đã lấy được Host: $DB_HOST"
echo "✅ Database: $DB_NAME, User: $DB_USER"

# 3. Dọn dẹp Pod cũ nếu còn tồn tại
kubectl delete pod "$CLIENT_POD" -n "$NAMESPACE" --ignore-not-found > /dev/null 2>&1

# 4. Khởi tạo Pod PostgreSQL Client
echo "⏳ Đang tạo Pod PostgreSQL Client..."
kubectl run "$CLIENT_POD" --image=postgres:15 -n "$NAMESPACE" --restart=Never -- sleep 3600 > /dev/null

echo "⏳ Đang chờ Pod sẵn sàng..."
kubectl wait --for=condition=ready "pod/$CLIENT_POD" -n "$NAMESPACE" --timeout=120s > /dev/null

if [ $? -ne 0 ]; then
    echo "❌ Pod PostgreSQL Client không sẵn sàng sau 120 giây."
    kubectl delete pod "$CLIENT_POD" -n "$NAMESPACE" --ignore-not-found > /dev/null 2>&1
    exit 1
fi

# 5. Đưa SQL data vào Pod qua stdin (tránh vấn đề kubectl cp trên Windows)
echo "📂 Đang đưa file SQL vào Pod..."
kubectl exec -n "$NAMESPACE" "$CLIENT_POD" -i -- tee //tmp//product-data.sql < "$SQL_FILE" > /dev/null

# 6. Thực thi câu lệnh SQL — truyền password qua biến môi trường an toàn
echo "⚙️ Đang thực thi dữ liệu..."
kubectl exec -n "$NAMESPACE" "$CLIENT_POD" -- \
    env PGPASSWORD="$DB_PASS" \
    psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -p 5432 -f //tmp//product-data.sql

if [ $? -ne 0 ]; then
    echo "❌ Thực thi SQL thất bại!"
    kubectl delete pod "$CLIENT_POD" -n "$NAMESPACE" --ignore-not-found > /dev/null 2>&1
    exit 1
fi

# 7. Dọn dẹp
echo "🧹 Đang dọn dẹp Pod tạm thời..."
kubectl delete pod "$CLIENT_POD" -n "$NAMESPACE" > /dev/null

echo "🎉 NẠP DỮ LIỆU THÀNH CÔNG! Hãy refresh lại trình duyệt."
