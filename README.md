# Quản Lý Người Dùng Đa Nền Tảng (Flutter + Node.js + MongoDB Atlas)

Ứng dụng Admin quản lý người dùng chạy đa nền tảng (**Flutter Web & Android/iOS**) kết nối **MongoDB Atlas** qua **Node.js + Express REST API**.

## Cấu trúc Cơ sở dữ liệu (`giuaki_flutter.users`)
Chỉ gồm đúng **4 trường** theo yêu cầu đề bài:
- `email`: Email người dùng (unique)
- `matkhau`: Mật khẩu
- `hoten`: Họ và tên
- `hinhanh`: Đường dẫn hoặc URL hình ảnh

## Tính năng chính
- **Đa nền tảng Web & Mobile:** Giao diện responsive (`DataTable` trên Web, `ListView` trên Mobile), hỗ trợ chọn ảnh từ máy tính/điện thoại hoặc dán link URL ảnh.
- **Xác thực Admin (JWT):** Đăng nhập, Đăng ký, tự động ghi nhớ phiên đăng nhập (`shared_preferences`).
- **Quản lý người dùng (CRUD):** Thêm, Xem chi tiết, Sửa, Xóa 1 hoặc **Chọn nhiều & Xóa hàng loạt**, tự động xóa ảnh cũ trên server.
- **Chức năng nâng cao:**
  - Tìm kiếm tức thì theo tên / email.
  - Bộ lọc nhanh theo trạng thái ảnh (**Tất cả / Có ảnh / Chưa có ảnh**) kèm thanh tiến độ %.
  - Sắp xếp (Mới nhất, Tên A→Z, Tên Z→A, Email A→Z) & Phân trang (`6 / 10 / 20` mục/trang).
  - Kiểm tra độ mạnh mật khẩu trực quan & Validate email chuẩn Regex.
  - Ẩn/Hiện mật khẩu từng dòng, phóng to xem ảnh đại diện (Lightbox Zoom).
  - Chuyển đổi giao diện Sáng / Tối (**Dark Mode**).
  - Xem & sao chép dữ liệu JSON CSDL chuẩn 4 trường.

## Cấu trúc thư mục
```text
giuaki_flutter/
├── backend/                # Node.js + Express + Mongoose API
│   ├── middleware/auth.js  # Xác thực JWT
│   ├── models/User.js      # Schema 4 trường (email, matkhau, hoten, hinhanh)
│   ├── routes/auth.js      # /api/auth/login, /api/auth/register
│   ├── routes/users.js     # CRUD, batch-delete, export JSON
│   ├── seed.js             # Tạo dữ liệu mẫu
│   └── server.js           # Express server + upload ảnh (multer)
├── database/
│   └── users.json          # File JSON CSDL mẫu (4 trường)
├── lib/                    # Mã nguồn Flutter (Web & Mobile)
│   ├── config/             # Cấu hình API URL & ThemeController
│   ├── models/             # UserModel
│   ├── screens/            # Login, Home, Add, Edit, Detail
│   ├── services/           # AuthService, UserService
│   ├── utils/              # FormValidators
│   └── widgets/            # UserAvatar, ImageInputPicker, PasswordStrengthBar
└── BAO_CAO_THUC_HIEN.md    # Báo cáo chi tiết các bước thực hiện
```

## Hướng dẫn chạy nhanh
1. **Chạy Backend:**
   ```bash
   cd backend
   npm install
   node seed.js
   npm start
   ```
2. **Chạy Flutter Web:**
   ```bash
   flutter pub get
   flutter run -d chrome
   ```
3. **Chạy Flutter Mobile (Android):**
   ```bash
   flutter run
   ```
4. **Tài khoản đăng nhập mẫu:** `admin@gmail.com` / `123456`
