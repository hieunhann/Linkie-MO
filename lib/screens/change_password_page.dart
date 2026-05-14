import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentCtl = TextEditingController();
  final _newCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  String _error = '';
  bool _success = false;
  bool _loading = false;

  Future<void> _handleSubmit() async {
    if (_currentCtl.text.isEmpty || _newCtl.text.isEmpty || _confirmCtl.text.isEmpty) { setState(() => _error = 'Vui lòng nhập đầy đủ thông tin.'); return; }
    if (_newCtl.text != _confirmCtl.text) { setState(() => _error = 'Mật khẩu xác nhận không khớp.'); return; }
    if (_newCtl.text.length < 6) { setState(() => _error = 'Mật khẩu mới phải có ít nhất 6 ký tự.'); return; }
    if (_newCtl.text == _currentCtl.text) { setState(() => _error = 'Mật khẩu mới phải khác mật khẩu cũ.'); return; }
    setState(() { _error = ''; _loading = true; });
    try {
      await context.read<AuthProvider>().changePassword(_currentCtl.text, _newCtl.text);
      setState(() => _success = true);
    } catch (e) {
      setState(() => _error = 'Có lỗi xảy ra. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _currentCtl.dispose(); _newCtl.dispose(); _confirmCtl.dispose(); super.dispose(); }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: AppTheme.textTertiary),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderStrong)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryTeal)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppTheme.bgDark, body: Column(children: [
      Container(height: MediaQuery.of(context).size.height * 0.30, decoration: const BoxDecoration(gradient: AppTheme.gradientHeader)),
      Expanded(child: Container(width: double.infinity, transform: Matrix4.translationValues(0, -32, 0),
        decoration: const BoxDecoration(color: AppTheme.bgDarkCard, borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))),
        child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 32, 24, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('THAY ĐỔI MẬT KHẨU', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 28),
          if (_success) ...[
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.successColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.successColor.withOpacity(0.2))),
              child: Text('Mật khẩu đã được thay đổi thành công!', style: TextStyle(color: AppTheme.successColor, fontSize: 14), textAlign: TextAlign.center)),
            const SizedBox(height: 16),
            Container(width: double.infinity, decoration: BoxDecoration(gradient: AppTheme.gradientPink, borderRadius: BorderRadius.circular(30)),
              child: ElevatedButton(onPressed: () => Navigator.of(context).pop(), style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                child: const Text('QUAY LẠI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)))),
          ] else ...[
            TextField(controller: _currentCtl, obscureText: true, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: _inputDeco('Mật khẩu hiện tại')),
            const SizedBox(height: 12),
            TextField(controller: _newCtl, obscureText: true, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: _inputDeco('Mật khẩu mới')),
            const SizedBox(height: 12),
            TextField(controller: _confirmCtl, obscureText: true, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: _inputDeco('Xác nhận mật khẩu mới')),
            if (_error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error, style: TextStyle(color: AppTheme.errorColorLight, fontSize: 12))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primaryTeal), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: const Text('QUAY LẠI', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 14)))),
              const SizedBox(width: 12),
              Expanded(child: Container(decoration: BoxDecoration(gradient: AppTheme.gradientPink, borderRadius: BorderRadius.circular(30)), child: ElevatedButton(onPressed: _loading ? null : _handleSubmit, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: Text(_loading ? '...' : 'XÁC NHẬN', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 14))))),
            ]),
          ],
          const SizedBox(height: 32),
          Row(children: [Expanded(child: Container(height: 1, color: AppTheme.borderMedium)), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('hoặc', style: TextStyle(color: AppTheme.textTertiary, fontSize: 12))), Expanded(child: Container(height: 1, color: AppTheme.borderMedium))]),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: OutlinedButton(
            onPressed: () { context.read<AuthProvider>().logout(); Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false); },
            style: OutlinedButton.styleFrom(side: BorderSide(color: AppTheme.borderStrong), foregroundColor: AppTheme.textSecondary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            child: const Text('ĐĂNG XUẤT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 14)))),
        ])),
      )),
    ]));
  }
}
