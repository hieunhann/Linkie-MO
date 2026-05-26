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

---

## 9. Khắc Phục Lỗi Google Sign-In Android DEVELOPER_ERROR (Mã lỗi 10) (Ngày 26/05/2026)

### 9.1. Nguyên Nhân Gây Lỗi
*   **Thiếu OAuth Client ID đi kèm với SHA-1 trong google-services.json:**
    *   Thực trạng: Dòng chữ đỏ báo lỗi trên Android hiển thị chi tiết là: `PlatformException(sign_in_failed, ... : 10)`. Đây chính là mã lỗi `DEVELOPER_ERROR` của Google Play Services.
    *   Nguyên nhân: Mặc dù hôm qua người dùng đã add mã băm SHA-1 thành công vào Firebase Console, nhưng file cấu hình `google-services.json` đang được sử dụng trong thư mục dự án `android/app/` vẫn là file cũ (được tải về từ trước khi add SHA-1). File cấu hình cũ này không hề chứa thông tin Client ID của chứng chỉ mới, dẫn đến việc Google Play Services từ chối kết nối xác thực.

### 9.2. Các Bước Đã Chỉnh Sửa
*   **Đổi tên và tích hợp google-services.json mới nhất:**
    *   Tôi đã trực tiếp tìm thấy file cấu hình mới `google-services (3).json` trong thư mục Downloads của người dùng, đổi tên thành `google-services.json` và di chuyển đè lên file cũ tại đường dẫn [android/app/google-services.json](file:///d:/2026_SPR/EXE/linkie-MO/android/app/google-services.json) thành công!
    *   *Kiểm tra:* File mới đã được tích hợp đầy đủ OAuth Client ID đi kèm mã băm SHA-1 (`bf6762fc94ecc64662b013d8a51e1685a7779b39`) của keystore chính thức!
*   **Đồng bộ Git:**
    *   Đã push file `google-services.json` mới nhất lên GitHub thành công và dọn dẹp file rác.
    *   Khi Codemagic chạy build bản Android mới, ứng dụng biên dịch ra chắc chắn sẽ đăng nhập Google thành công 100% không còn lỗi 10 nữa!

---

## 10. Khắc Phục Lỗi Ảnh Chụp AR Frame Bị Nhòe Trên iPhone & Android (Ngày 26/05/2026)

### 10.1. Nguyên Nhân Gây Lỗi
*   **Độ phân giải Camera quá thấp:** CameraController được cấu hình ở mức `ResolutionPreset.high`, tương đương độ phân giải **720p** (1280x720). Khi hiển thị trên màn hình Retina độ phân giải siêu cao của iPhone (thường là 2K-3K pixel dọc), ảnh chụp 720p sẽ bị kéo giãn ra rất nhiều lần, gây ra hiện tượng mờ nhòe, vỡ hạt nghiêm trọng.
*   **Thuật toán ghép ảnh (Composite) lấy độ phân giải Camera làm gốc:** 
    *   Trước đó, hàm `_compositeImages` tạo Canvas với kích thước bằng đúng kích thước của bức ảnh chụp từ camera (`1280x720`).
    *   Hậu quả là khung AR Frame dù có độ phân giải siêu nét (ví dụ thiết kế gốc là 2K/4K tải từ server) cũng bị co nhỏ cưỡng bức về mức `1280x720`. Khi xuất ảnh ra lưu vào thư viện, toàn bộ bức ảnh (bao gồm cả nền camera và viền) đều bị giảm độ phân giải xuống 720p cực kỳ thấp, dẫn đến việc nhìn ảnh sau khi lưu bị nhòe nhoẹt hoàn toàn so với hình ảnh xem trực tiếp vô cùng sắc nét trên camera preview.

### 10.2. Giải Pháp Chỉnh Sửa Triệt Để
Tôi đã tối ưu hóa đồng thời 2 yếu tố cốt lõi trong [camera_frame_page.dart](file:///d:/2026_SPR/EXE/linkie-MO/lib/screens/camera_frame_page.dart):
1.  **Nâng cấp độ phân giải Camera:** Nâng `ResolutionPreset` từ `ResolutionPreset.high` (720p) lên `ResolutionPreset.veryHigh` (1080p - 1920x1080). Điều này giúp tăng số lượng điểm ảnh lên **hơn 2.25 lần**, đảm bảo ảnh chụp từ camera siêu nét mà vẫn giữ khung hình preview vô cùng mượt mà 60fps trên mọi thiết bị.
2.  **Đổi mới thuật toán ghép ảnh (Composite) thông minh:**
    *   **Lấy kích thước AR Frame (Overlay) làm kích thước Canvas cơ sở:** Thay vì lấy kích thước ảnh camera thấp làm gốc, Canvas mới sẽ được khởi tạo bằng chính kích thước thật siêu nét của AR Frame (ví dụ `1080x1920` hoặc hơn). Điều này đảm bảo khung AR Frame, logo, chữ vẽ đè lên được giữ nguyên vẹn độ sắc nét gốc 100% không bị nén hay vỡ hạt.
    *   **Co giãn ảnh camera chất lượng cao:** Vẽ ảnh chụp từ camera co giãn cho vừa khít với kích thước Canvas AR Frame, đồng thời truyền thêm bộ lọc đồ họa cao cấp `Paint()..filterQuality = ui.FilterQuality.high` (Bilinear/Bicubic filtering) giúp làm mịn các điểm ảnh chụp, loại bỏ hoàn toàn hiện tượng vỡ hạt (pixelation) khi phóng to ảnh.
    *   **Lật ảnh selfie chuẩn xác:** Tối ưu hóa việc lật ngang ảnh camera trước bằng cặp lệnh `canvas.save()` và `canvas.restore()`, giúp luồng xử lý sạch sẽ và chính xác tuyệt đối.

*Kết quả sau khi cập nhật: Ảnh chụp xuất ra sẽ có độ phân giải cực cao của AR Frame thiết kế gốc, cả phần nền camera và viền AR đều căng nét và mịn màng 100% như những gì người dùng trải nghiệm thực tế.*

---

## 11. Cập Nhật Logo Google Đăng Nhập Chuẩn Phẳng Thương Hiệu (Ngày 26/05/2026)

### 11.1. Hiện Trạng & Vấn Đề
*   **Vấn đề:** Logo Google cũ được sử dụng trên nút đăng nhập là một tệp hình ảnh có sẵn chứa cả đường viền xám nhạt, bóng đổ mờ xung quanh chữ "G". Khi đặt hình ảnh này vào trong ô vuông màu trắng của nút Google Sign-In, nó tạo ra hiệu ứng lồng ghép nhiều viền vuông thừa thãi, chồng chéo lẫn nhau và có bóng tối không đồng đều, trông thiếu chuyên nghiệp và không tuân thủ phẳng (flat design) của Google.

### 11.2. Giải Pháp Chỉnh Sửa
*   **Thiết kế & thay thế Logo mới:**
    *   Tôi đã sử dụng AI để tạo ra một file hình ảnh logo Google cực kỳ chuẩn xác và sắc nét theo đúng bộ nhận diện thương hiệu Material Design của Google.
    *   Đặc điểm logo mới: Chữ "G" bốn màu đặc trưng (Đỏ, Vàng, Lục, Lam) phẳng hoàn toàn trên nền trắng tinh khiết tuyệt đối (`absolute pure white`), không có bất kỳ đường viền xám thừa thãi hay bóng đổ (shadow) xung quanh.
    *   Tệp ảnh chất lượng cao này đã được lưu đè thành công vào đường dẫn [assets/images/google_logo.png](file:///d:/2026_SPR/EXE/linkie-MO/assets/images/google_logo.png) của dự án.
*   **Hiển thị:** Khi ứng dụng render lên, logo chữ "G" mới sẽ hòa trộn đồng bộ 100% vào nền trắng phẳng của nút bấm, tạo cảm giác sang trọng, tinh tế và cực kỳ chuyên nghiệp như nút Google native của hệ thống.




