import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../utils/theme.dart';
import '../widgets/navbar.dart';
import '../widgets/footer.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});
  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().fetchEvents();
    });
  }

  String _formatDate(String iso) {
    final d = DateTime.parse(iso);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<EventProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bgDarkCard,
      body: Column(children: [
        const LkNavbar(),
        // Header
        Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 8), child: Row(children: [
          GestureDetector(onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.chevron_left, color: Colors.white, size: 28)),
          const SizedBox(width: 16),
          const Text('Sự kiện', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ])),
        // Event list
        Expanded(child: ep.loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal))
          : ep.events.isEmpty
            ? Center(child: Container(padding: const EdgeInsets.all(40), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.borderMedium)), child: Text('Hiện chưa có sự kiện nào.', style: TextStyle(color: AppTheme.textSecondary))))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: ep.events.length,
                itemBuilder: (ctx, i) => _buildCard(ep.events[i]),
              ),
        ),
        const LkFooter(),
      ]),
    );
  }

  Widget _buildCard(dynamic event) {
    final status = event.eventStatus;
    final isLive = status == 'live';
    return GestureDetector(
      onTap: isLive ? () => Navigator.of(context).pushNamed('/events/${event.id}') : null,
      child: Container(margin: const EdgeInsets.only(bottom: 24), height: 224,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(32),
          border: Border.all(color: isLive ? AppTheme.primaryTeal.withOpacity(0.3) : AppTheme.borderLight),
          boxShadow: isLive ? [BoxShadow(color: AppTheme.primaryTeal.withOpacity(0.1), blurRadius: 20)] : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Opacity(opacity: isLive ? 1.0 : 0.8, child: Stack(fit: StackFit.expand, children: [
          if (event.thumbnailUrl != null && event.thumbnailUrl!.isNotEmpty)
            Image.network(event.thumbnailUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: AppTheme.cardBg))
          else Container(color: AppTheme.cardBg),
          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [AppTheme.bgDarkCard, AppTheme.bgDarkCard.withOpacity(0.4), Colors.transparent]))),
          // Badge
          Positioned(top: 16, left: 16, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: isLive ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: isLive ? AppTheme.primaryTeal.withOpacity(0.3) : AppTheme.borderMedium)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (isLive) ...[Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red)), const SizedBox(width: 8)],
              Text(isLive ? 'Đang diễn ra' : 'Sắp diễn ra', style: TextStyle(color: isLive ? Colors.white : const Color(0xFFD1D5DB), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ]),
          )),
          // Content
          Positioned(bottom: 0, left: 0, right: 0, child: Padding(padding: const EdgeInsets.all(24), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('${DateTime.parse(event.startTime).year}', style: TextStyle(color: AppTheme.primaryTeal, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text(event.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(_formatDate(event.startTime), style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
            ])),
            if (isLive) Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.primaryTeal, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppTheme.primaryTeal.withOpacity(0.2), blurRadius: 10)]),
              child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20)),
          ]))),
        ])),
      ),
    );
  }
}
