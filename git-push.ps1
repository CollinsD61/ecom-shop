param (
    [string]$CommitMessage = "Update frontend and backend code"
)

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "🚀 BAT DAU PUSH CODE LEN GITHUB 🚀" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Kiem tra thu muc hien tai co phai la git repo khong
if (-Not (Test-Path ".git")) {
    Write-Host "❌ Loi: Ban phai chay script nay tu thu muc goc cua du an (d:\WorkSpace\ecom_shop)" -ForegroundColor Red
    exit 1
}

# Add tat ca cac file thay doi (tru cac file trong .gitignore)
Write-Host "`n[1/3] Dang add tat ca file vao git..." -ForegroundColor Yellow
git add .

# Kiem tra xem co file nao de commit khong
$status = git status --porcelain
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "✅ Khong co thay doi nao de push. Code hien tai da dong bo!" -ForegroundColor Green
    exit 0
}

# Commit voi tin nhan (mac dinh la "Update frontend and backend code")
Write-Host "`n[2/3] Dang commit code voi tin nhan: '$CommitMessage'..." -ForegroundColor Yellow
git commit -m $CommitMessage

# Push len nhanh hien tai
Write-Host "`n[3/3] Dang push len Github..." -ForegroundColor Yellow
git push

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n🎉 XONG! Code cua ban da duoc push len Github thanh cong." -ForegroundColor Green
    Write-Host "👉 Github Actions se tu dong build va cap nhat len S3 / ECR ngay lap tuc!" -ForegroundColor Green
} else {
    Write-Host "`n❌ Loi: Push code that bai. Kiem tra lai ket noi hoac conflict git." -ForegroundColor Red
}
