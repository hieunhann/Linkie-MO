import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  String _error = '';
  bool _loading = false;

  Future<void> _handleRegister() async {
    if (_nameCtl.text.trim().isEmpty || _emailCtl.text.trim().isEmpty || _passCtl.text.isEmpty || _confirmCtl.text.isEmpty) {
      setState(() => _error = 'Vui lòng nhập đầy đủ thông tin.');
      return;
    }
    if (_passCtl.text != _confirmCtl.text) { setState(() => _error = 'Mật khẩu xác nhận không khớp.'); return; }
    if (_passCtl.text.length < 6) { setState(() => _error = 'Mật khẩu phải có ít nhất 6 ký tự.'); return; }
    setState(() { _error = ''; _loading = true; });
    try {
      await context.read<AuthProvider>().register(_nameCtl.text, _emailCtl.text, _passCtl.text);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
    } catch (e) {
      setState(() => _error = 'Đăng ký thất bại. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _nameCtl.dispose(); _emailCtl.dispose(); _passCtl.dispose(); _confirmCtl.dispose(); super.dispose(); }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: AppTheme.textTertiary),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderStrong)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryTeal)),
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
            Image.asset('assets/images/logo-linkie-black.png', height: 64),
            const SizedBox(height: 16),
            Image.asset('assets/images/Linkie.png', height: 40),
            const SizedBox(height: 8),
            Text('Tạo tài khoản mới', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 32),
            TextField(controller: _nameCtl, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: _inputDeco('Họ và tên')),
            const SizedBox(height: 12),
            TextField(controller: _emailCtl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: _inputDeco('Email')),
            const SizedBox(height: 12),
            TextField(controller: _passCtl, obscureText: true, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: _inputDeco('Mật khẩu')),
            const SizedBox(height: 12),
            TextField(controller: _confirmCtl, obscureText: true, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: _inputDeco('Xác nhận mật khẩu')),
            if (_error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error, style: TextStyle(color: AppTheme.errorColorLight, fontSize: 12))),
            const SizedBox(height: 16),
            Container(width: double.infinity, decoration: BoxDecoration(gradient: AppTheme.gradientPink, borderRadius: BorderRadius.circular(30)),
              child: ElevatedButton(onPressed: _loading ? null : _handleRegister, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                child: Text(_loading ? '...' : 'ĐĂNG KÝ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 14)))),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Bạn đã có tài khoản? ', style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
              GestureDetector(onTap: () => Navigator.of(context).pushNamed('/login'), child: const Text('Đăng nhập', style: TextStyle(color: AppTheme.primaryTeal, fontSize: 12))),
            ]),
            const SizedBox(height: 32),
            Text('Bằng việc đăng ký, bạn đồng ý với Điều khoản dịch vụ\nvà Chính sách bảo mật của Linkie.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textTertiary, fontSize: 11, height: 1.5)),
          ])),
        )),
      ]),
    );
  }
}
