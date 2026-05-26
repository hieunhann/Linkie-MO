import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  String _error = '';
  bool _loading = false;
  bool _googleLoading = false;

  Future<void> _handleLogin() async {
    if (_emailCtl.text.trim().isEmpty || _passCtl.text.trim().isEmpty) {
      setState(() => _error = 'Vui lòng nhập đầy đủ thông tin.');
      return;
    }
    setState(() { _error = ''; _loading = true; });
    try {
      await context.read<AuthProvider>().login(_emailCtl.text, _passCtl.text);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
    } catch (e) {
      setState(() => _error = 'Email hoặc mật khẩu không đúng.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() { _error = ''; _googleLoading = true; });
    try {
      await context.read<AuthProvider>().loginWithGoogle();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('hủy')) {
        // User cancelled, no error shown
      } else {
        setState(() => _error = 'Đăng nhập Google thất bại. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  void dispose() { _emailCtl.dispose(); _passCtl.dispose(); super.dispose(); }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: AppTheme.textTertiary),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderStrong)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryTeal)),
    filled: true, fillColor: Colors.transparent,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Column(children: [
        Container(height: MediaQuery.of(context).size.height * 0.38, decoration: const BoxDecoration(gradient: AppTheme.gradientHeader)),
        Expanded(child: Container(
          width: double.infinity, transform: Matrix4.translationValues(0, -32, 0),
          decoration: const BoxDecoration(color: AppTheme.bgDarkCard, borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))),
          child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 32, 24, 24), child: Column(children: [
            // Logo MO - kích thước nguyên bản
            Image.asset('assets/images/logo-mo.png'),
            const SizedBox(height: 16),
            Text('Hệ thống quản trị sự kiện', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 32),

            // Nút Google Sign-In
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _googleLoading ? null : _handleGoogleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: _googleLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: 2,
                            top: 2,
                            bottom: 2,
                            child: Container(
                              width: 46,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Image.asset('assets/images/google_logo.png', fit: BoxFit.contain),
                            ),
                          ),
                          const Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Sign in with Google',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Container(height: 1, color: Colors.white12)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('hoặc', style: TextStyle(color: AppTheme.textTertiary, fontSize: 12))),
              Expanded(child: Container(height: 1, color: Colors.white12)),
            ]),
            const SizedBox(height: 16),

            TextField(controller: _emailCtl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: _inputDeco('Nhập email')),
            const SizedBox(height: 12),
            TextField(controller: _passCtl, obscureText: true, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: _inputDeco('Mật khẩu')),
            if (_error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error, style: TextStyle(color: AppTheme.errorColorLight, fontSize: 12))),
            const SizedBox(height: 16),

            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primaryTeal), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: const FittedBox(fit: BoxFit.scaleDown, child: Text('QUAY LẠI', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 13))))),
              const SizedBox(width: 12),
              Expanded(child: Container(decoration: BoxDecoration(gradient: AppTheme.gradientPink, borderRadius: BorderRadius.circular(30)), child: ElevatedButton(onPressed: _loading ? null : _handleLogin, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: FittedBox(fit: BoxFit.scaleDown, child: Text(_loading ? '...' : 'ĐĂNG NHẬP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 13)))))),
            ]),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Bạn chưa có tài khoản? ', style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
              GestureDetector(onTap: () => Navigator.of(context).pushNamed('/register'), child: const Text('Đăng ký ngay', style: TextStyle(color: AppTheme.primaryTeal, fontSize: 12))),
            ]),
            const SizedBox(height: 32),
            Text('Bằng việc đăng nhập, bạn đồng ý với Điều khoản dịch vụ\nvà Chính sách bảo mật của Linkie.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textTertiary, fontSize: 11, height: 1.5)),
          ])),
        )),
      ]),
    );
  }
}
