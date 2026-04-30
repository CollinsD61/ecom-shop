#!/bin/bash

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
PRODUCT_POD=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=ecom-shop-chart-product-service -o jsonpath='{.items[0].metadata.name}')

if [ -z "$PRODUCT_POD" ]; then
    echo "❌ Không tìm thấy Product Service Pod. Ứng dụng đã được deploy chưa?"
    exit 1
fi

# Lấy biến môi trường từ Pod
ENV_VARS=$(kubectl exec -n $NAMESPACE $PRODUCT_POD -- env)
DB_URL=$(echo "$ENV_VARS" | grep "^SPRING_DATASOURCE_URL=" | cut -d '=' -f2 | tr -d '\r')
DB_PASS=$(echo "$ENV_VARS" | grep "^SPRING_DATASOURCE_PASSWORD=" | cut -d '=' -f2 | tr -d '\r')

# Bóc tách Host từ chuỗi JDBC URL (jdbc:postgresql://<host>:5432/...)
DB_HOST=$(echo "$DB_URL" | sed -E 's|jdbc:postgresql://([^:]+).*|\1|')

if [ -z "$DB_HOST" ] || [ -z "$DB_PASS" ]; then
    echo "❌ Không thể trích xuất Database Host hoặc Password từ Pod $PRODUCT_POD"
    exit 1
fi

echo "✅ Đã lấy được Host: $DB_HOST"

# 3. Khởi tạo Pod PostgreSQL Client
echo "⏳ Đang tạo Pod PostgreSQL Client..."
kubectl run $CLIENT_POD --image=postgres:15 -n $NAMESPACE --restart=Never -- sleep 3600 > /dev/null

echo "⏳ Đang chờ Pod sẵn sàng..."
kubectl wait --for=condition=ready pod/$CLIENT_POD -n $NAMESPACE --timeout=60s > /dev/null

# 4. Copy file SQL vào Pod
echo "📂 Đang copy file SQL vào Pod..."
kubectl cp $SQL_FILE $NAMESPACE/$CLIENT_POD:/tmp/product-data.sql

# 5. Thực thi câu lệnh SQL
echo "⚙️ Đang thực thi dữ liệu..."
kubectl exec -it -n $NAMESPACE $CLIENT_POD -- bash -c "PGPASSWORD='$DB_PASS' psql -h $DB_HOST -U ecomadmin -d ecomdb -p 5432 -f /tmp/product-data.sql"

# 6. Dọn dẹp
echo "🧹 Đang dọn dẹp Pod tạm thời..."
kubectl delete pod $CLIENT_POD -n $NAMESPACE > /dev/null

echo "🎉 NẠP DỮ LIỆU THÀNH CÔNG! Hãy refresh lại trình duyệt."
