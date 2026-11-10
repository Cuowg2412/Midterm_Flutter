# BÁO CÁO ĐỒ ÁN GIỮA KỲ - LẬP TRÌNH ĐA NỀN TẢNG
**Đề tài:** Xây dựng ứng dụng quản lý người dùng (Admin) đa nền tảng (Web & Mobile) sử dụng Flutter + Node.js + MongoDB Atlas.

---

## 1. Kiến trúc hệ thống & Công nghệ sử dụng

- **Frontend (Đa nền tảng Web & Mobile):** Flutter (Dart)
- **Backend API:** Node.js + Express.js
- **Cơ sở dữ liệu:** MongoDB Atlas Cloud (Mongoose ODM)
- **Xác thực:** JWT (JSON Web Token) + lưu phiên `shared_preferences`
- **Upload hình ảnh:** Multer (lưu trữ ảnh trên server tại `backend/uploads/` và trả về đường dẫn lưu vào trường `hinhanh`)

### Cấu trúc CSDL MongoDB (`database: giuaki_flutter`, `collection: users`)
Đảm bảo đúng yêu cầu đề bài **chỉ gồm 4 trường** (`versionKey: false`, không thêm `timestamps`):
| Tên trường | Kiểu dữ liệu | Mô tả |
|---|---|---|
| `email` | String (unique, required) | Địa chỉ email người dùng |
| `matkhau` | String (required) | Mật khẩu người dùng |
| `hoten` | String (required) | Họ tên người dùng |
| `hinhanh` | String | Đường dẫn hoặc URL hình ảnh |

---

## 2. Các lệnh cài đặt thư viện & Khởi tạo dự án

### 2.1. Khởi tạo dự án Flutter và cài thư viện
```bash
flutter create giuaki_flutter --platforms web,android,ios
cd giuaki_flutter
flutter pub add http http_parser file_picker shared_preferences
flutter pub get
```

### 2.2. Cài đặt thư viện Backend (Node.js + Express + MongoDB)
```bash
cd backend
npm init -y
npm install express mongoose cors dotenv jsonwebtoken multer
npm install --save-dev nodemon
```

### 2.3. Khởi tạo dữ liệu mẫu lên MongoDB Atlas
```bash
cd backend
node seed.js
```
Tài khoản đăng nhập mặc định:
- **Email:** `admin@gmail.com`
- **Mật khẩu:** `123456`

---

## 3. Chức năng đã hoàn thiện

1. **Chạy trên nền tảng Web & Di động (8.0 + 0.5 điểm):**
   - Giao diện tự động co giãn (Responsive): hiển thị dạng bảng (`DataTable`) trên Web/Desktop và dạng thẻ (`ListView`) trên Mobile.
   - Thêm mới người dùng với đầy đủ 4 trường: `email`, `matkhau`, `hoten`, `hinhanh`.
   - Hỗ trợ nhập hình ảnh linh hoạt bằng **2 cách**: chọn file ảnh từ thiết bị (trên cả Web và Mobile) qua `file_picker` + `POST /api/upload` hoặc dán link URL ảnh trực tiếp.
   - Xử lý tải ảnh an toàn (`loadingBuilder`, `errorBuilder`) và bấm vào ảnh để phóng to xem rõ nét.

2. **Đăng nhập, Sửa, Xóa & Chức năng nâng cao (1.5 điểm):**
   - **Đăng nhập / Đăng ký:** Xác thực JWT Token (`POST /api/auth/login`, `POST /api/auth/register`), tự động ghi nhớ phiên đăng nhập khi tải lại trang.
   - **Sửa & Xóa người dùng:** Sửa thông tin, đổi ảnh (tự động xóa ảnh cũ trên server), xác nhận trước khi xóa.
   - **Chọn nhiều & Xóa hàng loạt (`POST /api/users/batch-delete`):** Tích chọn nhiều người dùng để xóa cùng lúc.
   - **Tìm kiếm, Lọc & Sắp xếp:** Tìm kiếm tức thì theo họ tên/email; lọc theo trạng thái ảnh (**Tất cả / Có ảnh / Chưa có ảnh**) kèm thanh tiến độ %; sắp xếp theo mới nhất, tên A→Z, tên Z→A, email A→Z.
   - **Phân trang:** Tùy chọn hiển thị 6, 10 hoặc 20 người dùng/trang.
   - **Kiểm tra dữ liệu & Bảo mật giao diện:** Thanh đo độ mạnh mật khẩu (Yếu / Trung bình / Khá / Mạnh), validate email chuẩn Regex, ẩn/hiện mật khẩu từng dòng trên bảng Web.
   - **Giao diện Sáng / Tối (Dark Mode):** Chuyển đổi nhanh ngay trên thanh AppBar.
   - **Xem / Xuất JSON CSDL (`GET /api/users/export`):** Xem và sao chép dữ liệu JSON chuẩn 4 trường trực tiếp trong ứng dụng.
   - **Cấu hình Server URL linh hoạt:** Hỗ trợ nhập IP LAN ngay trên màn hình đăng nhập khi chạy demo trên điện thoại thật.

---

## 4. Hướng dẫn chạy dự án & Kịch bản quay Video Demo

### Bước 1: Chạy Backend API (kết nối MongoDB Atlas)
```bash
cd backend
npm start
```

### Bước 2: Chạy Flutter Web (Chrome)
```bash
flutter run -d chrome
```

### Bước 3: Chạy Flutter Mobile (Android Emulator)
```bash
flutter run -d emulator-5554
```

### Kịch bản quay Video Demo gợi ý (~2–3 phút):
1. Mở MongoDB Atlas → **Browse Collections** → cho thấy collection `users` chỉ có 4 trường `email`, `matkhau`, `hoten`, `hinhanh`.
2. Trên **Flutter Web**: Đăng nhập `admin@gmail.com` / `123456` → thử Tìm kiếm, Lọc có ảnh/chưa có ảnh, Sắp xếp, Dark Mode → Thêm 1 người dùng có chọn ảnh → Xem chi tiết (phóng to ảnh) → Sửa → Thử Chọn nhiều & Xóa → Bấm nút Export JSON.
3. Trên **Android Emulator**: Mở app → Thêm 1 người dùng có chọn ảnh trên máy ảo → Hiển thị danh sách & chi tiết người dùng vừa thêm → Quay lại Web/Atlas bấm Làm mới để thấy dữ liệu đồng bộ thời gian thực.

---

## 5. File cơ sở dữ liệu nộp kèm
- File JSON dữ liệu mẫu: `database/users.json`
- Trước khi nộp bài, có thể xuất file JSON mới nhất trực tiếp từ MongoDB Atlas hoặc từ nút **Xem / Xuất JSON CSDL** trong ứng dụng.
