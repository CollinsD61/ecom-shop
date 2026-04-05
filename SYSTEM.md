# SYSTEM

## 1. TONG QUAN HE THONG (TARGET)

Tai lieu nay mo ta kien truc muc tieu khi dua he thong len AWS EKS voi:

- Khong dung `api-gateway` trong codebase.
- Khong dung `discovery-server` (Eureka).
- Khong dung `keycloak` + `keycloak-mysql`.
- Thay `config-server` bang `AWS Secrets Manager` de luu tru secrets.
- Su dung `ALB Ingress Controller` + `Cognito` de xu ly vao/ra va auth.
- Trien khai bang `ArgoCD` theo GitOps, image luu tren `ECR`.
- Su dung `IRSA` + `External Secrets Operator` de cap secrets vao Kubernetes.

Phan ung dung chinh con lai:

- `ecom-frontend` (React)
- `user-service`
- `product-service`
- `shopping-cart-service`

## 2. KIEN TRUC MICROSERVICES TREN AWS

### 2.1 So do tong the

```text
┌───────────────────────────────────────────────────────────────────────────────────────────────┐
│                                   INTERNET / END USER                                        │
└──────────────────────────────────────────────┬────────────────────────────────────────────────┘
                                               │ HTTPS
                                               ▼
┌──────────────────────────────────────────────┐
│            CLOUDFLARE (DNS + Proxy)          │
│  shop.dohoangdevops.io.vn / argocd...         │
└──────────────────────────────────────────────┬┘
                                               │
                                               ▼
┌───────────────────────────────────────────────────────────────────────────────────────────────┐
│                                AWS (ap-southeast-1 / Singapore)                              │
│                                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │ VPC: 10.0.0.0/16                                                                        │  │
│  │                                                                                         │  │
│  │  ┌──────────────────────────────────── AZ-a ─────────────────────────────────────┐      │  │
│  │  │ Public subnet-1: 10.0.0.0/22                                                 │      │  │
│  │  │  - ALB node (internet-facing)                                                │      │  │
│  │  │  - NAT Gateway #1 (EIP)                                                      │      │  │
│  │  └───────────────────────────────────────────────────────────────────────────────┘      │  │
│  │                                                                                         │  │
│  │  ┌──────────────────────────────────── AZ-b ─────────────────────────────────────┐      │  │
│  │  │ Public subnet-2: 10.0.4.0/22                                                 │      │  │
│  │  │  - ALB node (internet-facing)                                                │      │  │
│  │  │  - NAT Gateway #2 (EIP)                                                      │      │  │
│  │  └───────────────────────────────────────────────────────────────────────────────┘      │  │
│  │                                                                                         │  │
│  │  ┌──────────────────────────────────── AZ-a ─────────────────────────────────────┐      │  │
│  │  │ Private subnet-1: 10.0.8.0/22                                                │      │  │
│  │  │  - EKS worker node (nodegroup)                                               │      │  │
│  │  │  - Pods: user-service / product-service / shopping-cart-service              │      │  │
│  │  │  - Pods: aws-load-balancer-controller / external-dns / argocd-server         │      │  │
│  │  └───────────────────────────────────────────────────────────────────────────────┘      │  │
│  │                                                                                         │  │
│  │  ┌──────────────────────────────────── AZ-b ─────────────────────────────────────┐      │  │
│  │  │ Private subnet-2: 10.0.12.0/22                                               │      │  │
│  │  │  - EKS worker node (nodegroup)                                               │      │  │
│  │  │  - Pods scale/failover across AZ                                             │      │  │
│  │  └───────────────────────────────────────────────────────────────────────────────┘      │  │
│  │                                                                                         │  │
│  │  ┌───────────────────────────────────────────────────────────────────────────────────┐   │  │
│  │  │ Amazon RDS PostgreSQL (Multi-AZ, private DB subnet group)                       │   │  │
│  │  │  - Khong public IP                                                               │   │  │
│  │  │  - Chi cho phep SG tu EKS workload truy cap (5432)                              │   │  │
│  │  └───────────────────────────────────────────────────────────────────────────────────┘   │  │
│  └─────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                               │
│  Cognito User Pool + App Client  <---- ALB authentication (OIDC/Cognito)                     │
│  ECR: <account>.dkr.ecr.ap-southeast-1.amazonaws.com/ecom-shop                                │
│  Secret flow: EKS Pods (IRSA) -> AWS Secrets Manager                                           │
└───────────────────────────────────────────────────────────────────────────────────────────────┘
                                               ▲
                                               │ GitOps Pull
┌───────────────────────────────────────────────────────────────────────────────────────────────┐
│ GitHub Repo (manifests/helm) -> ArgoCD sync -> EKS                                            │
└───────────────────────────────────────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────────────────────────────────────┐
│ Secret Management Plane (AWS Managed)                                                         │
│  - External Secrets Operator (trong EKS)                                                      │
│  - IRSA role cho tung service account                                                         │
│  - AWS Secrets Manager (luu DB creds, app secrets, API keys)                                 │
└───────────────────────────────────────────────────────────────────────────────────────────────┘
```

CIDR theo thiet ke:

- VPC: 10.0.0.0/16
- public subnet-1: 10.0.0.0/22
- public subnet-2: 10.0.4.0/22
- private subnet-1: 10.0.8.0/22
- private subnet-2: 10.0.12.0/22

### 2.2 So do luong request chi tiet

```text
[User Browser]
    |
    | 1) HTTPS request (GET/POST /api/*)
    v
[Cloudflare]
    |
    | 2) Forward request to ALB origin
    v
[AWS ALB + Ingress Rules]
    |
    | 3) Check authentication session/token
    |    - Neu chua auth -> redirect Cognito
    v
[Amazon Cognito Hosted UI]
    |
    | 4) User login thanh cong
    |    return auth code/token/session
    v
[AWS ALB + Ingress Rules]
    |
    | 5) Route theo host/path
    |    /api/user/* -> user-service
    |    /api/product/* -> product-service
    |    /api/shopping-cart/* -> shopping-cart-service
    v
[Service Pod trong EKS private subnet]
    |
    | 6) Xu ly business logic
    |    (co the goi service khac trong cluster)
    v
[Amazon RDS PostgreSQL - private DB subnet group]
    |
    | 7) Query/Update data
    v
[Service Pod] -> [ALB] -> [Cloudflare] -> [User Browser]
```

### 2.3 So do luong lay secret tu AWS Secrets Manager (thay Config Server)

```text
[Service Pod trong EKS]
    |
    | 1) App khoi dong / can doc secret
    |    (db url, db user, db password, api keys...)
    v
[External Secrets Operator / CSI Driver]
    |
    | 2) Assume IAM role qua IRSA
    |    (service account -> IAM role)
    v
[AWS Secrets Manager]
    |
    | 3) IAM policy check + tra secret value
    v
[Kubernetes Secret]
    |
    | 4) Inject vao pod (ENV hoac volume)
    v
[App Runtime]
```

### 2.4 Luong hoat dong

1. End user thao tac tren frontend va gui request HTTPS den domain shop.
2. Cloudflare nhan request va forward vao ALB cua EKS.
3. ALB ap dung rule Ingress theo host/path de route vao service dung trong cluster.
4. Neu chua dang nhap, ALB redirect user sang Cognito.
5. User dang nhap xong, Cognito redirect ve lai ALB kem token/session hop le.
6. ALB tiep tuc route request vao service dich (`user-service`, `product-service`, `shopping-cart-service`).
7. Service xu ly nghiep vu, neu can thi goi service khac trong cluster qua Kubernetes DNS.
8. Ket qua tra nguoc: service -> ALB -> Cloudflare -> end user.

### 2.5 Lien ket giua cac service

- `shopping-cart-service` goi `product-service` de lay gia moi nhat khi tinh tong tien gio hang.
- `user-service` co the goi `shopping-cart-service` de tim/xoa gio hang theo user.
- `user-service`, `product-service`, `shopping-cart-service` doc/ghi du lieu tren PostgreSQL (RDS trong production).
- Cac service khong con phu thuoc `api-gateway` va `discovery-server`.
- Secrets cua services khong lay tu `config-server` nua ma lay tu `AWS Secrets Manager` thong qua IRSA.

### 2.6 Vi tri dat RDS trong mang

- Nen dat RDS trong private subnets (khong public IP), toi thieu 2 AZ de dam bao HA.
- RDS nen nam trong DB subnet group rieng (gom cac private subnets), khong dat cung public subnet voi ALB.
- ALB nam public subnets, con EKS worker node va RDS nam private subnets.
- Service trong EKS ket noi RDS qua private route va Security Group cho phep dung port 5432.
- Khong mo inbound RDS ra Internet.

### 2.7 Cac thanh phan bi loai bo trong kien truc moi

- `api-gateway`
- `discovery-server`
- `keycloak-realms`
- `mysql_keycloak_data`
- `config-server` (thay bang AWS Secrets Manager)

Ghi chu:

- Moi service nen co IAM role rieng (least privilege), chi duoc doc dung secret cua service do.
- Frontend da duoc tach API URL theo tung service (`USER`, `PRODUCT`, `CART`) de khong con phu thuoc URL gateway duy nhat.

### 2.8 Mapping secret de xuat (AWS Secrets Manager)

Quy uoc dat ten secret (dung environment `prod`):

- `/ecom/prod/shared/rds`
    - `host`
    - `port`
    - `database`

- `/ecom/prod/user-service/db`
    - `username`
    - `password`
    - `jdbc_url`

- `/ecom/prod/product-service/db`
    - `username`
    - `password`
    - `jdbc_url`

- `/ecom/prod/shopping-cart-service/db`
    - `username`
    - `password`
    - `jdbc_url`

- `/ecom/prod/user-service/cognito`
    - `hosted_ui_login_url`
    - `hosted_ui_signup_url`

IRSA de xuat:

- `sa-user-service` -> read `/ecom/prod/user-service/*` va `/ecom/prod/shared/*`
- `sa-product-service` -> read `/ecom/prod/product-service/*` va `/ecom/prod/shared/*`
- `sa-shopping-cart-service` -> read `/ecom/prod/shopping-cart-service/*` va `/ecom/prod/shared/*`
