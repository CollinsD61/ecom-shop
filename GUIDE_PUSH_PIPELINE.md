# Hướng dẫn Đẩy Code (Push) và Kích hoạt Pipeline an toàn

Việc bạn thấy thông báo `warning: LF will be replaced by CRLF...` khi gõ lệnh `git add .` là **hoàn toàn bình thường** trên hệ điều hành Windows. Nó chỉ là cảnh báo về định dạng dấu xuống dòng (Line Ending) và sẽ **không** làm lỗi code hay lỗi pipeline của bạn.

Dưới đây là 2 cách để bạn push code lên Github một cách an toàn và tự động kích hoạt Pipeline:

---

## CÁCH 1: Dùng lệnh Git tiêu chuẩn (Khuyên dùng)
Bạn mở Terminal (PowerShell) ngay tại thư mục dự án `d:\WorkSpace\ecom_shop` và chạy lần lượt 3 lệnh sau:

```powershell
# Bước 1: Thêm tất cả thay đổi (Bạn đã làm bước này rồi)
git add .

# Bước 2: Tạo một commit với tin nhắn giải thích những gì bạn vừa sửa
git commit -m "fix: update frontend code and skill scripts"

# Bước 3: Đẩy code lên Github (Pipeline sẽ tự động kích hoạt ngay sau lệnh này)
git push origin main
```

---

## CÁCH 2: Dùng script tự động `git-push.ps1` có sẵn
Bạn đã có sẵn một file script tên là `git-push.ps1` trong dự án. Để chạy nó, bạn gõ lệnh sau vào Terminal:

```powershell
.\git-push.ps1 -CommitMessage "Cập nhật code và tài liệu skill mới"
```
*Script này sẽ tự động chạy lệnh add, commit, push và thông báo màu xanh đỏ cho bạn biết trạng thái thành công.*

---

## 🛑 KIỂM TRA QUAN TRỌNG TRƯỚC KHI ĐỢI PIPELINE CHẠY XONG
Sau khi bạn chạy lệnh Push xong, code sẽ được đẩy lên Github. Ngay lập tức, `frontend-ci.yml` sẽ bắt đầu chạy. 

Để đảm bảo bước **Configure AWS credentials** màu xanh (Pass), bạn hãy nhớ lại bước mình đã nhắc trước đó:
Chắc chắn rằng bạn **đã tạo 2 biến Secret** trên Github nhé:
- `AWS_ACCESS_KEY_ID` 
- `AWS_SECRET_ACCESS_KEY` 

Nếu bạn đã tạo 2 biến này rồi thì bạn cứ yên tâm Push code, Pipeline sẽ tự động deploy thành công lên Amazon S3!
