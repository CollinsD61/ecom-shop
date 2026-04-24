# 🌐 Traffic Flow — Ecom Shop trên EKS & S3

---

## 1. Tổng thể: Từ Internet vào Hệ thống

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│  INTERNET                                                                        │
│                                                                                  │
│   Browser  ──HTTPS──►  Cloudflare (CDN / Edge)                                   │
└─────────────────────────────────────────────────────────────────────────────────┘
                                │ (1) Load tĩnh        │ (2) Gọi API
                                ▼                      ▼
                    ┌──────────────────┐    ┌──────────────────────────────────────┐
                    │  Amazon S3       │    │  AWS ALB                             │
                    │  (Static Host)   │    │  (internet-facing, public subnet)    │
                    │  React Build     │    └──────────────────────────────────────┘
                    └──────────────────┘                       │
                                                               │
                               ┌───────────────▼───────────────┴───────────────────────────────────┐
                               │  KUBERNETES CLUSTER (EKS — private subnet)                         │
                               │                                                                     │
                               │  ┌─── Gateway API Stack ─────────────────────────────────────────┐  │
                               │  │                                                                 │  │
                               │  │  GatewayClass (aws-alb-gateway-class)                        │  │
                               │  │       │                                                       │  │
                               │  │       ▼                                                       │  │
                               │  │  Gateway (HTTPS :443)                                        │  │
                               │  │       │                                                       │  │
                               │  │       ├──► HTTPRoute (user)     path: /api/user/*             │  │
                               │  │       ├──► HTTPRoute (product)  path: /api/product/*          │  │
                               │  │       └──► HTTPRoute (cart)     path: /api/shopping-cart/*    │  │
                               │  │                                                                 │  │
                               │  └─────────────────────────────────────────────────────────────────┘  │
                               │          │                  │                   │                    │
                               │          ▼                  ▼                   ▼                    │
                               │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐      │
                               │  │K8s Service   │  │K8s Service   │  │K8s Service           │      │
                               │  │user-service  │  │product-svc   │  │shopping-cart-svc      │      │
                               │  │ClusterIP:5865│  │ClusterIP:5861│  │ClusterIP:5863         │      │
                               │  └──────┬───────┘  └──────┬───────┘  └──────────┬────────────┘      │
                               │         │ kube-proxy        │ kube-proxy          │ kube-proxy        │
                               │         ▼                   ▼                     ▼                   │
                               │  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────┐       │
                               │  │  Pod(s)      │  │  Pod(s)      │  │  Pod(s)             │       │
                               │  │  user-svc    │  │  product-svc │  │  shopping-cart-svc  │       │
                               │  └──────┬───────┘  └──────┬───────┘  └──────────┬──────────┘       │
                               │         │                   │                     │                   │
                               │         └───────────────────┴─────────────────────┘                   │
                               │                             │                                          │
                               │                             ▼                                          │
                               │                    ┌────────────────┐                                 │
                               │                    │  Amazon RDS    │                                 │
                               │                    │  PostgreSQL    │                                 │
                               │                    │  :5432         │                                 │
                               │                    └────────────────┘                                 │
                               └───────────────────────────────────────────────────────────────────────┘
```

---

## 2. Chi tiết: Gateway API routing (Backend)

```mermaid
flowchart TD
    Browser["🌐 Browser (chạy React)"]
    CF["☁️ Cloudflare\nProxy API"]
    ALB["⚡ AWS ALB\n(internet-facing)\npublic subnet"]

    subgraph EKS ["☸️ EKS Cluster — private subnet"]
        GC["GatewayClass\naws-alb-gateway-class"]
        GW["Gateway\nlistener: HTTPS :443\nhostname: shop.dohoangdevops.io.vn"]

        HR_U["HTTPRoute: user\npath prefix: /api/user/*\n→ backendRef: user-service:5865"]
        HR_P["HTTPRoute: product\npath prefix: /api/product/*\n→ backendRef: product-service:5861"]
        HR_C["HTTPRoute: cart\npath prefix: /api/shopping-cart/*\n→ backendRef: shopping-cart-service:5863"]

        SVC_U["K8s Service\nuser-service\ntype: ClusterIP\nport: 5865"]
        SVC_P["K8s Service\nproduct-service\ntype: ClusterIP\nport: 5861"]
        SVC_C["K8s Service\nshopping-cart-service\ntype: ClusterIP\nport: 5863"]

        POD_U1["Pod: user-service"]
        POD_P1["Pod: product-service"]
        POD_C1["Pod: shopping-cart-service"]
    end

    Browser -->|HTTPS /api/*| CF
    CF -->|Forward| ALB
    ALB -->|"AWS LBC"| GC
    GC --> GW
    GW --> HR_U & HR_P & HR_C
    HR_U --> SVC_U
    HR_P --> SVC_P
    HR_C --> SVC_C
    SVC_U -->|"kube-proxy"| POD_U1
    SVC_P -->|"kube-proxy"| POD_P1
    SVC_C -->|"kube-proxy"| POD_C1

    style GC fill:#ff9900,color:#000
    style GW fill:#ff9900,color:#000
    style HR_U fill:#232f3e,color:#fff
    style HR_P fill:#232f3e,color:#fff
    style HR_C fill:#232f3e,color:#fff
```

---

## 3. Service-to-Service giao tiếp (nội bộ qua CoreDNS)

(Không đổi so với kiến trúc trước, sử dụng `http://service-name:port` qua K8s CoreDNS)

---

## 4. Cơ chế Service Discovery qua CoreDNS

(Không đổi, sử dụng CoreDNS trong Cluster EKS)

---

## 5. Secret injection — Trước khi Pod khởi động

(Không đổi, External Secrets Operator kéo credentials từ AWS Secrets Manager thông qua IRSA)

---

## 6. Tóm tắt các lớp mạng

| Lớp | Resource K8s | IP Type | Ai dùng |
|---|---|---|---|
| **Internet → S3** | N/A | Public IP | Browser lấy static files (HTML/JS/CSS) |
| **Internet → ALB** | AWS ALB | Public IP | Browser gọi REST API → Gateway |
| **ALB → Pod** | Gateway + HTTPRoute | Trực tiếp Pod IP | ALB gọi thẳng Pod |
| **Pod → Pod** | K8s Service + CoreDNS | Cluster-internal IP | service-to-service calls |
| **Pod → RDS** | DNS endpoint RDS | Private VPC IP | JPA/JDBC connection |
| **Pod → Secrets Manager**| ExternalSecret + IRSA | AWS API | External Secrets Operator |
