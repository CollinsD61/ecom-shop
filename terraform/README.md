# Terraform — ecom-shop Infrastructure

Terraform code quản lý toàn bộ hạ tầng AWS cho hệ thống ecom-shop microservices.

## 📁 Cấu trúc thư mục

```
terraform/
├── modules/                    # Reusable modules
│   ├── vpc/                    # VPC, subnets, NAT Gateway, route tables
│   ├── eks/                    # EKS cluster, node group, OIDC provider
│   ├── rds/                    # RDS PostgreSQL, security group
│   ├── ecr/                    # ECR repositories, lifecycle policies
│   ├── alb_controller/         # AWS Load Balancer Controller (Helm)
│   ├── external_dns/           # External DNS với Cloudflare (Helm)
│   ├── argocd/                 # ArgoCD GitOps (Helm)
│   ├── cognito/                # AWS Cognito User Pool + App Client
│   ├── secrets/                # AWS Secrets Manager entries
│   └── irsa/                   # IAM Roles for Service Accounts (reusable)
│
├── environments/               # Per-environment configs
│   ├── shared/                 # Tài nguyên dùng chung (ECR)
│   ├── dev/                    # Môi trường Development
│   └── prod/                   # Môi trường Production
│
└── README.md
```

## 🚀 Cách sử dụng

### Bước 0: Tạo S3 Bucket cho Terraform State

```bash
aws s3 mb s3://ecom-shop-terraform-state --region ap-southeast-1
```

### Bước 1: Deploy ECR (shared)

```bash
cd terraform/environments/shared
terraform init
terraform plan
terraform apply
```

### Bước 2: Deploy Infrastructure (dev hoặc prod)

```bash
cd terraform/environments/dev   # hoặc prod

terraform init
terraform plan -var="cloudflare_api_token=YOUR_CF_TOKEN"
terraform apply -var="cloudflare_api_token=YOUR_CF_TOKEN"
```

### Bước 2.1 (khuyen nghi): 1 lenh apply + tu dong sync Cognito annotation vao Helm values

```powershell
# Cach 1: truyen token qua environment variable
$env:TF_VAR_cloudflare_api_token="YOUR_CF_TOKEN"
./terraform/scripts/apply-env-and-sync-cognito.ps1 -Environment dev

# Cach 2: truyen token truc tiep
./terraform/scripts/apply-env-and-sync-cognito.ps1 -Environment prod -CloudflareApiToken "YOUR_CF_TOKEN"

# Cach 3 (local): tao file .env.local o repo root
# TF_VAR_cloudflare_api_token=YOUR_CF_TOKEN
# Script se tu dong doc .env.local va khong can nhap token moi lan
./terraform/scripts/apply-env-and-sync-cognito.ps1 -Environment dev
```

Script nay se:
- Chay terraform init/apply cho environment da chon
- Lay output alb_auth_idp_cognito_annotation
- Tu dong cap nhat vao ecom-shop-chart/values/<env>.yaml

### Bước 3: Cấu hình kubectl

```bash
# Lệnh này được in ra khi terraform apply xong
aws eks update-kubeconfig --region ap-southeast-1 --name dev-ecom-cluster
```

## 🔐 Sensitive Variables

Biến `cloudflare_api_token` không được lưu trong `.tfvars`. Truyền qua CLI hoặc environment variable:

```bash
# Option 1: CLI
terraform apply -var="cloudflare_api_token=xxx"

# Option 2: Environment variable
export TF_VAR_cloudflare_api_token="xxx"
terraform apply
```

## 🏗️ Dependency Flow

```
VPC ──► EKS ──► ALB Controller
  │       │         
  │       ├──► External DNS
  │       │         
  │       ├──► ArgoCD
  │       │         
  │       ├──► IRSA (x3 services)
  │       │         
  ├───────┼──► RDS ──► Secrets Manager
```

## ⚖️ Dev vs Prod

| Config              | Dev            | Prod           |
|---------------------|----------------|----------------|
| NAT Gateway         | 1 (tiết kiệm)  | 2 (HA per AZ)  |
| Node Instance       | t2.medium      | t3.medium      |
| Node Scaling        | 1 → 2          | 2 → 3          |
| RDS Instance        | db.t3.micro    | db.t3.small    |
| RDS Multi-AZ        | ❌             | ✅             |
| RDS Storage         | 20 GB          | 50 GB          |
| RDS Backup          | 1 ngày         | 7 ngày         |
| RDS Final Snapshot   | Skip           | Bắt buộc       |

## 🌐 Domain Mapping

| Service    | Domain                              |
|------------|-------------------------------------|
| Frontend   | `ecom-shop.dohoangdevops.io.vn`     |
| ArgoCD     | `argocd.dohoangdevops.io.vn`        |

## 🗑️ Destroy Infrastructure

```bash
# Destroy environment
cd terraform/environments/dev
terraform destroy -var="cloudflare_api_token=xxx"

# Destroy shared (ECR) — CHỈ khi không còn dùng
cd terraform/environments/shared
terraform destroy
```