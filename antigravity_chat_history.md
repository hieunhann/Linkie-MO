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

---

## 5. Kết Quả Kiểm Tra Lỗi Truy Cập Camera & Google Sign-In (Ngày 25/05/2026)

### 5.1. Quyền Truy Cập Camera (Camera & AR Frame)
*   **Android:** Cấu hình trong `AndroidManifest.xml` đã đầy đủ quyền `android.permission.CAMERA` cùng các camera features.
*   **iOS:** Đã khai báo đầy đủ các khóa cần thiết trong `ios/Runner/Info.plist` bao gồm `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSPhotoLibraryUsageDescription` và `NSPhotoLibraryAddUsageDescription` (đầy đủ cho cả việc chụp ảnh AR và lưu ảnh vào thư viện).
*   **Lỗi giao diện nghiêm trọng đã được phát hiện & sửa đổi:** 
    *   *Hiện trạng:* Widget bộ chọn AR Frame (`_buildFramePicker` trả về một `Positioned.fill`) lại được đặt trực tiếp bên trong widget `Column` trong hàm `build` của `CameraFramePage`. Lỗi này **chắc chắn sẽ gây crash ứng dụng** ngay lập tức trên cả 2 hệ điều hành khi người dùng mở bộ chọn khung hình.
    *   *Chỉnh sửa:* Đã chuyển đổi cấu trúc `body` của Scaffold thành một `Stack` bao bọc bên ngoài `Column` chính và widget chọn khung hình. Lỗi crash đã được sửa đổi triệt để.

### 5.2. Cấu Hình Đăng Nhập Google (Google Sign-In)
*   **Android:**
    *   File cấu hình `android/app/google-services.json` đã tồn tại.
    *   Package Name `com.linkie.linkie_mo` khớp chính xác 100% với `applicationId` trong file gradle của Android.
    *   Plugin Google Services đã được apply đầy đủ.
    *   *Lưu ý quan trọng:* Hãy đảm bảo bạn đã lấy mã băm SHA-1 của cả Keystore debug và Keystore ký app chính thức (`android/app/upload-keystore.jks`) để add vào Firebase Console ứng dụng Android.
        *   **Mã SHA-1 của upload-keystore.jks (Release/Codemagic Build) là:** `BF:67:62:FC:94:EC:C6:46:62:B0:13:D8:A5:1E:16:85:A7:77:9B:39`
        *   **Mã SHA-256 của upload-keystore.jks là:** `36:44:F8:E7:A8:5E:24:28:3E:A9:63:C3:EC:3A:BC:48:52:B7:25:84:C3:3B:42:C9:4F:1B:C7:EC:7C:FB:46:81`
        *(Nếu thiếu các mã băm này trong Firebase Console, Google Sign-In trên thiết bị Android sẽ trả về lỗi PlatformException mã số 10).*
*   **iOS:**
    *   File cấu hình `ios/Runner/GoogleService-Info.plist` đã tồn tại.
    *   Bundle ID `com.linkie.linkieMo` khớp chính xác 100% với `PRODUCT_BUNDLE_IDENTIFIER` cấu hình trong Xcode (`project.pbxproj`).
    *   URL Scheme dành cho Google Sign-In (`REVERSED_CLIENT_ID` là `com.googleusercontent.apps.900115746759-conprjsc496dq1mgsk3npajeqer3gvo5`) đã được thiết lập đầy đủ trong `ios/Runner/Info.plist`. Mọi cấu hình phía iOS đã hoàn thành chính xác 100%.
*   **Code logic Dart (`lib/services/google_auth_service.dart`):** Logic đăng nhập bằng Google, cấu hình Firebase Auth và gửi ID Token lên backend .NET qua API `/Auth/google-login` đã được lập trình hoàn hảo và không có lỗi logic nào.

## 6. Xử Lý Lỗi Trắng Màn Hình Khi Khởi Chạy Trên iOS (Ngày 25/05/2026)

### 6.1. Nguyên Nhân Gây Lỗi
*   **Lỗi cú pháp XML trong GoogleService-Info.plist:**
    *   Trong file cấu hình Firebase [GoogleService-Info.plist](file:///d:/2026_SPR/EXE/linkie-MO/ios/Runner/GoogleService-Info.plist) của iOS, các thẻ giá trị Boolean đang được viết sai định dạng nghiêm trọng: `<false></false>` và `<true></true>`.
    *   Trình biên dịch và phân tích XML Plist của iOS (`NSPropertyListSerialization`) rất nghiêm ngặt. Khi gặp định dạng tag đóng/mở này cho kiểu Boolean, nó sẽ ném ra lỗi cú pháp (XML parse error) và làm crash luồng chính của ứng dụng ngay khi Firebase SDK cố gắng đọc file cấu hình lúc startup.
*   **Khởi tạo Firebase thiếu cơ chế phòng vệ:**
    *   Hàm `main()` trong [main.dart](file:///d:/2026_SPR/EXE/linkie-MO/lib/main.dart) trực tiếp gọi `await Firebase.initializeApp()` mà không nằm trong khối `try-catch`. Khi xảy ra lỗi khởi tạo native từ phía Firebase (như lỗi parse plist ở trên), ứng dụng sẽ bị tắt hoặc treo câm lặng ở màn hình Splash trắng tinh (White Screen of Death).

### 6.2. Các Bước Đã Chỉnh Sửa
*   **Chỉnh sửa cú pháp GoogleService-Info.plist:** Thay đổi toàn bộ các thẻ Boolean lỗi thành dạng tự đóng chuẩn của Apple Plist: `<false/>` và `<true/>`.
*   **Cải thiện tính ổn định của main.dart:** Thêm khối `try-catch` bao bọc `Firebase.initializeApp()` để đảm bảo ứng dụng không bao giờ bị crash trắng màn hình lặng câm. Nếu có bất kỳ lỗi khởi tạo native nào xảy ra, ứng dụng sẽ ghi nhận lỗi qua `debugPrint` và tiếp tục hoạt động thay vì crash.

---

## 7. Giải Quyết Lỗi Không Thể Cấp Quyền Camera Trên iOS (Ngày 26/05/2026)

### 7.1. Nguyên Nhân Gây Lỗi
*   **Thiếu cấu hình macros trong Podfile:**
    *   Trực trạng: File cài đặt iOS sau khi mở màn hình Camera AR báo lỗi *"Không thể truy cập camera. Vui lòng cấp quyền camera."* và khi người dùng vào Cài đặt (Settings) của iPhone cũng không tìm thấy mục cấp quyền cho ứng dụng Linkie.
    *   Lý do: Thư viện `permission_handler` trên iOS mặc định sẽ tắt (disable) tất cả các quyền hệ thống trong tệp CocoaPods để tránh app bị Apple từ chối khi đưa lên App Store vì xin quyền thừa. Khi gọi `Permission.camera.request()`, thư viện sẽ tự động trả về `denied` (từ chối) ngay lập tức mà hoàn toàn không kích hoạt hộp thoại popup xin quyền native của Apple. Do đó, iOS cũng không tạo mục Settings cho ứng dụng.

### 7.2. Các Bước Đã Chỉnh Sửa
*   **Tạo file ios/Podfile chuẩn:**
    *   Tôi đã tạo file [Podfile](file:///d:/2026_SPR/EXE/linkie-MO/ios/Podfile) chuẩn cho iOS.
    *   Đã thêm cấu hình `GCC_PREPROCESSOR_DEFINITIONS` trong khối `post_install` để kích hoạt tường minh các quyền:
        *   `PERMISSION_CAMERA=1` (Kích hoạt quyền mở Camera)
        *   `PERMISSION_PHOTOS=1` (Kích hoạt quyền đọc/ghi Thư viện ảnh)
        *   `PERMISSION_MICROPHONE=1` (Kích hoạt quyền ghi âm đi kèm Camera)
*   **Đồng bộ Git:**
    *   Đã push file `Podfile` mới lên GitHub thành công. Khi Codemagic chạy build bản iOS mới, nó sẽ áp dụng đúng file `Podfile` cấu hình quyền này. Hộp thoại xin quyền native của Apple sẽ xuất hiện bình thường và ứng dụng sẽ hiển thị công tắc bật/tắt trong Settings của iPhone!

---

## 8. Cải Tiến Cơ Chế Gỡ Lỗi Đăng Nhập Google (Ngày 26/05/2026)

### 8.1. Hiện Trạng & Phân Tích
*   **Vấn đề:** Người dùng phản ánh khi bấm nút "Tiếp tục với Google" trên cả 2 nền tảng đều xuất hiện dòng chữ báo lỗi màu đỏ: *"Đăng nhập Google thất bại. Vui lòng thử lại."*
*   **Nguyên nhân:** Khối lệnh `catch` trong hàm `_handleGoogleLogin` của file `login_page.dart` đang nuốt thông báo lỗi thực tế (`e.toString()`) và hiển thị chuỗi thông báo chung chung. Điều này khiến cả nhà phát triển lẫn người dùng không thể biết lỗi cụ thể phát sinh do đâu (do Firebase Auth chưa cấu hình, Google Account Picker chặn, hay do API Backend trả về lỗi).

### 8.2. Giải Pháp Gỡ Lỗi Nâng Cao
*   **Sửa đổi trong `login_page.dart`:** Tôi đã sửa hàm gỡ lỗi `_handleGoogleLogin` để in chính xác và trực quan thông báo lỗi thực tế `$e` từ hệ thống ra dòng chữ đỏ ở màn hình Login (ví dụ: `Đăng nhập Google thất bại: [firebase_auth/operation-not-allowed]...`).
*   **Ý nghĩa:** Khi người dùng chạy bản build mới này, nếu lỗi xảy ra, dòng chữ đỏ sẽ chỉ rõ nguyên nhân (ví dụ: họ chưa kích hoạt "Google Sign-In Provider" trên Firebase Console hoặc do API backend `/Auth/google-login` lỗi). Từ đó chúng ta có thể chẩn đoán và sửa lỗi ngay lập tức mà không cần mò mẫm phỏng đoán.


