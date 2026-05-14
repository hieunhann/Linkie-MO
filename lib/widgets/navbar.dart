import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';

class LkNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBack;
  final VoidCallback? onBack;

  const LkNavbar({
    super.key,
    this.title,
    this.showBack = false,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Container(
      height: preferredSize.height + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: AppTheme.bgDark.withOpacity(0.9),
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Logo
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo-linkie-black.png', height: 28),
                  const SizedBox(height: 4),
                  Image.asset('assets/images/Linkie.png', height: 10),
                ],
              ),
            ),

            const Spacer(),

            // Nav links
            _NavLink(label: 'Trang chủ', onTap: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false)),
            const SizedBox(width: 20),
            _NavLink(label: 'Sự kiện', onTap: () => Navigator.of(context).pushNamed('/events')),
            const SizedBox(width: 20),

            // User section
            if (user != null)
              _AvatarMenu(user: user, auth: auth)
            else
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/login'),
                child: const Text(
                  'ĐĂNG NHẬP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _AvatarMenu extends StatelessWidget {
  final dynamic user;
  final AuthProvider auth;

  const _AvatarMenu({required this.user, required this.auth});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      color: const Color(0xFF12122A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderMedium),
      ),
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppTheme.primaryTeal, AppTheme.primaryPink],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryTeal, AppTheme.primaryPink],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(user.email, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'change_password',
          child: Row(
            children: [
              Icon(Icons.key, color: AppTheme.textSecondary, size: 16),
              const SizedBox(width: 8),
              Text('Đổi mật khẩu', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: AppTheme.errorColorLight, size: 16),
              const SizedBox(width: 8),
              Text('Đăng xuất', style: TextStyle(color: AppTheme.errorColorLight, fontSize: 14)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'change_password') {
          Navigator.of(context).pushNamed('/change-password');
        } else if (value == 'logout') {
          auth.logout();
          Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
        }
      },
    );
  }
}
