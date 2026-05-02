# K6 Runner — Hướng Dẫn Sử Dụng

## Tổng quan

EC2 `k6-runner` nằm trong **public subnet** cùng VPC với EKS cluster, được cài sẵn k6. Kết nối qua **SSM Session Manager** (không cần SSH key, không cần mở port 22).

---

## 1. Bật k6 runner

Trong `terraform/environments/dev/terraform.tfvars`, thêm:

```hcl
k6_enabled       = true
k6_instance_type = "t3.small"   # t3.medium nếu muốn bắn nhiều VU hơn
```

Rồi apply:

```bash
cd terraform/environments/dev
terraform apply -var-file=terraform.tfvars
```

Sau khi apply, lấy lệnh kết nối:

```bash
terraform output k6_runner_ssm_command
# => aws ssm start-session --target i-0abc1234 --region ap-southeast-1
```

---

## 2. Kết nối vào EC2

```bash
aws ssm start-session --target <instance-id> --region ap-southeast-1
```

> **Yêu cầu**: máy cục bộ cần cài `session-manager-plugin`.
> Cài: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

---

## 3. Chạy spike test

```bash
# Bên trong EC2 (qua SSM session)
sudo su - ec2-user
cd /home/ec2-user/k6-scripts

# Chạy với ALB DNS của dev
k6 run -e ENDPOINT=http://shop-dev.dohoangdevops.io.vn spike-test.js

# Hoặc dùng script từ repo (copy lên EC2 qua SSM)
```

### Profile mặc định (spike-test.js)

| Stage | Duration | VUs |
|-------|----------|-----|
| Warm-up | 30s | 5 |
| Ramp-up | 1m | 30 |
| **SPIKE** | **30s** | **150** |
| Giữ spike | 2m | 150 |
| Ramp-down | 1m | 30 |
| Cool-down | 30s | 0 |

---

## 4. Tắt k6 runner (tiết kiệm chi phí)

```hcl
# terraform.tfvars
k6_enabled = false
```

```bash
terraform apply -var-file=terraform.tfvars
# EC2 sẽ bị destroy, không mất tiền
```

---

## 5. Metrics Server (cho HPA)

`metrics_server` được bật tự động cùng với cluster. Kiểm tra:

```bash
kubectl top nodes
kubectl top pods -A
```

Nếu HPA cần scale theo CPU:

```bash
kubectl get hpa -A
```

---

## 6. Datadog Alert Setup (thủ công trên UI)

Sau khi spike test chạy, CPU sẽ tăng. Tạo monitor trong Datadog:

```
Metric:  avg:kubernetes.cpu.usage.total{cluster_name:dev-ecom-cluster}
Threshold: > 70% trong 5 phút
Alert:   gửi notification đến Slack/Email
```

Hoặc dùng Datadog Terraform provider để tạo monitor dưới dạng code (tuỳ chọn nâng cao).

---

## Sơ đồ luồng

```
k6 runner EC2 (public subnet)
    │
    │  HTTP traffic (spike 150 VUs)
    ▼
AWS ALB (internet-facing)
    │
    ▼
EKS Pods (user-service / product-service / shopping-cart-service)
    │
    ▼  CPU spike → HPA triggers scale-out
Datadog Agent (DaemonSet trên mỗi node)
    │
    ▼
Datadog Monitor → Alert (Slack / Email / PagerDuty)
```
