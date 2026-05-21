# Lịch Sử Trò Chuyện & Hướng Dẫn CI/CD Linkie-MO (Antigravity)

Tài liệu này lưu trữ lại toàn bộ nội dung và các bước chúng ta đã thực hiện để bạn có thể dễ dàng theo dõi trực tiếp từ IDE.

---

## 1. Thông Tin Git & Dự Án
*   **Repository:** [https://github.com/hieunhann/Linkie-MO.git](https://github.com/hieunhann/Linkie-MO.git)
*   **Trạng thái hiện tại:** Đã kết nối Remote và push thành công toàn bộ mã nguồn lên nhánh `main`. 
*   **Commit mới nhất:** `Update to Android-only free build workflow` (Đã đồng bộ sạch sẽ giữa Local và GitHub).

---

## 2. Thông Tin Khóa Ký Ứng Dụng (Android Keystore) - QUAN TRỌNG
Tôi đã tạo thành công file Keystore để ký ứng dụng Android của bạn hoàn toàn miễn phí.
*   **Đường dẫn file Keystore:** `android/app/upload-keystore.jks`
*   **Mật khẩu Store (Store Password):** `linkie123456`
*   **Mật khẩu Khóa (Key Password):** `linkie123456`
*   **Tên định danh (Alias):** `upload`
*   **Thông tin đăng ký:** `CN=Hieu Nhan, OU=Linkie, O=Linkie, L=Hanoi, S=Hanoi, C=VN`

> [!WARNING]
> Hãy giữ an toàn cho file `upload-keystore.jks` và các thông tin mật khẩu trên. Nếu mất, bạn sẽ không thể cập nhật phiên bản mới cho ứng dụng Android sau này.

---

## 3. Cấu Hình Codemagic Hiện Tại (Bản Miễn Phí Rẻ Nhất)
Chúng ta đã thống nhất phương án **tối ưu chi phí (0 đồng)** bằng cách chỉ tập trung build Android trước và gửi file cài đặt trực tiếp qua email thay vì đưa lên Store (để tránh các chi phí của Apple/Google).

File `codemagic.yaml` ở thư mục gốc đã được cập nhật tự động build APK và gửi về email của bạn:
*   **Email nhận file APK:** `tahieunhann@gmail.com`
*   **Workflow hoạt động:** `android-free-workflow`

---

## 4. Các Bước Tiếp Theo Cần Làm Trên Codemagic
Ngày mai khi bạn tiếp tục, hãy mở trình duyệt và làm theo các bước này:
1.  Truy cập [Codemagic.io](https://codemagic.io/) và đăng nhập bằng GitHub của bạn.
2.  Chọn dự án **Linkie-MO** > Chuyển sang chế độ **YAML configuration** (Nhấn nút *Switch to YAML configuration* ở góc trên bên phải nếu chưa bật).
3.  Vào phần **Environment variables** bên menu trái, tạo Group tên là `signing_credentials`.
4.  Thêm các biến môi trường sau để Codemagic nhận diện mã ký Android:
    *   `CM_KEYSTORE`: Upload file `android/app/upload-keystore.jks` lên.
    *   `CM_KEYSTORE_PASSWORD`: Điền `linkie123456`.
    *   `CM_KEY_ALIAS`: Điền `upload`.
    *   `CM_KEY_PASSWORD`: Điền `linkie123456`.
5.  Nhấn **Start new build** và chờ 5-10 phút để nhận file APK cài đặt qua email `tahieunhann@gmail.com`.

---
*Tài liệu được khởi tạo và lưu trữ tự động bởi Antigravity AI.*
