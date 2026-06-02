import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '900115746759-uojqjahlvdc76q3t13ditan72d298bs3.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ApiClient _api = ApiClient();

  /// Đăng nhập Google qua Firebase → lấy Firebase ID Token → gửi lên backend
  Future<Map<String, dynamic>> signInWithGoogle() async {
    // Đăng xuất phiên cũ để luôn hiện account picker
    await _googleSignIn.signOut();

    // Mở Google Account Picker
    final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
    if (googleAccount == null) {
      throw Exception('Người dùng hủy đăng nhập Google.');
    }

    // Lấy Google Auth Credentials
    final GoogleSignInAuthentication googleAuth =
        await googleAccount.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Đăng nhập vào Firebase với credential Google
    final UserCredential userCredential =
        await _firebaseAuth.signInWithCredential(credential);

    // Lấy Firebase ID Token (đây là token backend sẽ xác thực)
    final String? firebaseIdToken =
        await userCredential.user?.getIdToken();

    if (firebaseIdToken == null) {
      throw Exception('Không thể lấy Firebase ID Token.');
    }

    // Gửi Firebase ID Token lên backend .NET
    final response = await _api.postNoAuth('/Auth/google-login', body: {
      'idToken': firebaseIdToken,
    });

    final data = response['data'] ?? response;

    // Lưu app tokens
    final prefs = await SharedPreferences.getInstance();
    if (data['accessToken'] != null) {
      await prefs.setString(ApiConfig.accessTokenKey, data['accessToken']);
    }
    if (data['refreshToken'] != null) {
      await prefs.setString(ApiConfig.refreshTokenKey, data['refreshToken']);
    }

    return data;
  }

  /// Đăng xuất Firebase + Google
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }
}
