# ArgoCD Setup Guide

Hướng dẫn từng bước để deploy ArgoCD và truy cập giao diện.

---

## Bước 1: Apply Terraform (deploy ArgoCD lên EKS)

```powershell
cd D:\WorkSpace\ecom_shop\terraform\environments\dev

terraform apply -auto-approve -var="cloudflare_api_token=YOUR_CF_TOKEN"
```

> Chờ ~2-3 phút để ArgoCD deploy xong.

---

## Bước 2: Cập nhật kubeconfig

```bash
aws eks update-kubeconfig --region ap-southeast-1 --name dev-ecom-cluster
```

Kiểm tra kết nối:

```bash
kubectl get nodes
```

---

## Bước 3: Kiểm tra ArgoCD đã chạy chưa

```bash
kubectl get pods -n argocd
```

Chờ tất cả pods ở trạng thái `Running`:

```
NAME                                                READY   STATUS    RESTARTS
argocd-application-controller-0                     1/1     Running   0
argocd-applicationset-controller-xxx                1/1     Running   0
argocd-dex-server-xxx                               1/1     Running   0
argocd-redis-xxx                                    1/1     Running   0
argocd-repo-server-xxx                              1/1     Running   0
argocd-server-xxx                                   1/1     Running   0
```

---

## Bước 4: Lấy mật khẩu admin ArgoCD

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d; echo
```

**Windows PowerShell:**

```powershell
$encoded = kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}"
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encoded))
```

> Ghi lại mật khẩu này để đăng nhập.
> Username mặc định: **`admin`**

---

## Bước 5: Port-forward để truy cập giao diện

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

> Giữ terminal này mở trong khi dùng ArgoCD.

---

## Bước 6: Mở giao diện ArgoCD

Mở trình duyệt và vào:

```
http://localhost:8080
```

Đăng nhập:
- **Username:** `admin`
- **Password:** *(lấy từ Bước 4)*

> ⚠️ Trình duyệt có thể hiện cảnh báo SSL — nhấn **Advanced → Proceed** để tiếp tục (do dùng self-signed cert nội bộ).

---

## Bước 7 (Tuỳ chọn): Đổi mật khẩu admin

Sau khi đăng nhập lần đầu, vào:

```
User Info (góc trên phải) → Update Password
```

Hoặc qua CLI:

```bash
argocd login localhost:8080 --username admin --password <MẬT_KHẨU> --insecure

argocd account update-password \
  --current-password <MẬT_KHẨU_CŨ> \
  --new-password <MẬT_KHẨU_MỚI>
```

---

## Tóm tắt nhanh (copy-paste)

```bash
# 1. Apply terraform
cd D:\WorkSpace\ecom_shop\terraform\environments\dev
terraform apply -auto-approve -var="cloudflare_api_token=YOUR_TOKEN"

# 2. Cập nhật kubeconfig
aws eks update-kubeconfig --region ap-southeast-1 --name dev-ecom-cluster

# 3. Kiểm tra pods
kubectl get pods -n argocd

# 4. Lấy mật khẩu (Linux/Mac)
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d; echo

# 4. Lấy mật khẩu (Windows PowerShell)
$encoded = kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}"
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encoded))

# 5. Port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# 6. Mở browser → http://localhost:8080 (admin / <mật khẩu>)
```
kubectl apply -f argocd/applications/ecom-shop-dev.yaml