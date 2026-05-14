import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import '../widgets/navbar.dart';
import '../widgets/footer.dart';

class EventDetailPage extends StatefulWidget {
  final String eventId;
  const EventDetailPage({super.key, required this.eventId});
  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().fetchEventById(widget.eventId);
    });
  }

  void _navigateWithAuth(String route) {
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      Navigator.of(context).pushNamed(route);
    } else {
      Navigator.of(context).pushNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<EventProvider>();
    final event = ep.currentEvent;

    if (ep.loading) {
      return const Scaffold(backgroundColor: AppTheme.bgDark, body: Center(child: CircularProgressIndicator(color: AppTheme.primaryTealLight)));
    }
    if (event == null) {
      return const Scaffold(backgroundColor: AppTheme.bgDark, body: Center(child: Text('Sự kiện không tồn tại.', style: TextStyle(color: Colors.white))));
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDarkAlt,
      body: Column(children: [
        const LkNavbar(),
        // Header
        Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(onTap: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false),
            child: const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.chevron_left, color: Colors.white, size: 24))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(event.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text('Lựa chọn tiện ích trải nghiệm', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
          ])),
        ])),
        // Feature cards
        Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 0), child: Column(children: [
          // Camera AR Card
          Expanded(child: GestureDetector(
            onTap: () => _navigateWithAuth('/events/${widget.eventId}/camera-frame'),
            child: Container(
              decoration: BoxDecoration(gradient: AppTheme.gradientTeal, borderRadius: BorderRadius.circular(40), border: Border.all(color: AppTheme.borderMedium)),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
                  child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.camera_alt, color: AppTheme.primaryTeal, size: 32))),
                const SizedBox(height: 16),
                const Text('CAMERA AR', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text('Lưu giữ khoảnh khắc cùng AR Frame độc quyền', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
              ])),
            ),
          )),
          const SizedBox(height: 24),
          // Wishwall Card
          Expanded(child: GestureDetector(
            onTap: () => _navigateWithAuth('/events/${widget.eventId}/wishwall'),
            child: Container(
              decoration: BoxDecoration(gradient: AppTheme.gradientPink, borderRadius: BorderRadius.circular(40), border: Border.all(color: AppTheme.borderMedium)),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
                  child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.chat_bubble, color: AppTheme.primaryPink, size: 32))),
                const SizedBox(height: 16),
                const Text('WISHWALL', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text('Gửi lời tâm tình đến màn hình LED', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
              ])),
            ),
          )),
          const SizedBox(height: 80),
        ]))),
        const LkFooter(),
      ]),
    );
  }
}
