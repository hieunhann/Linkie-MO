import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../models/wishwall_message.dart';
import '../providers/event_provider.dart';
import '../services/wishwall_service.dart';
import '../utils/theme.dart';

class WishwallPage extends StatefulWidget {
  final String eventId;
  const WishwallPage({super.key, required this.eventId});
  @override
  State<WishwallPage> createState() => _WishwallPageState();
}

class _WishwallPageState extends State<WishwallPage> {
  final _inputCtl = TextEditingController();
  final _wishwallService = WishwallService();
  final _rand = Random();

  bool _loading = true;
  bool _isTrayOpen = true;
  String _eventName = 'Sự kiện';
  List<WishwallMessage> _history = [];
  List<_Bubble> _bubbles = [];
  HubConnection? _connection;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final ep = context.read<EventProvider>();
      await ep.fetchEventById(widget.eventId);
      _eventName = ep.currentEvent?.name ?? 'Sự kiện';

      final messages = await _wishwallService.getMessages(widget.eventId);
      _history = messages;
      _bubbles = messages.map((m) => _Bubble(
        id: m.id, text: m.message,
        x: 0.1 + _rand.nextDouble() * 0.55,
        startY: 60 + _rand.nextDouble() * 20,
        sentiment: m.sentiment,
      )).toList();

      setState(() => _loading = false);
      _setupSignalR();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _setupSignalR() async {
    try {
      _connection = await _wishwallService.createConnection();
      await _connection!.start();
      await _connection!.invoke('JoinEvent', args: [widget.eventId]);

      _connection!.on('MessageApproved', (args) {
        if (args == null || args.isEmpty) return;
        final data = args[0] as Map<String, dynamic>;
        final msg = WishwallMessage.fromJson(data);
        setState(() {
          final idx = _history.indexWhere((m) => m.id == msg.id);
          if (idx >= 0) { _history[idx] = msg; } else { _history.insert(0, msg); if (_history.length > 50) _history = _history.sublist(0, 50); }
          final bIdx = _bubbles.indexWhere((b) => b.id == msg.id);
          if (bIdx >= 0) { _bubbles[bIdx] = _bubbles[bIdx].copyWith(sentiment: msg.sentiment); }
          else { _bubbles.add(_Bubble(id: msg.id, text: msg.message, x: 0.1 + _rand.nextDouble() * 0.55, startY: 60 + _rand.nextDouble() * 20, sentiment: msg.sentiment)); }
        });
      });

      _connection!.on('MessageRejected', (args) {
        if (args == null || args.isEmpty) return;
        final messageId = args[0].toString();
        setState(() {
          _history = _history.map((m) => m.id == messageId ? m.copyWith(sentiment: 'Negative') : m).toList();
          _bubbles = _bubbles.map((b) => b.id == messageId ? b.copyWith(sentiment: 'Negative') : b).toList();
        });
      });
    } catch (e) {
      debugPrint('SignalR error: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputCtl.text.trim();
    if (text.isEmpty) return;
    final tempId = 'local-${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _bubbles.add(_Bubble(id: tempId, text: text, x: 0.1 + _rand.nextDouble() * 0.55, startY: 60 + _rand.nextDouble() * 20));
      _history.insert(0, WishwallMessage(id: tempId, message: text, userName: 'Vui lòng chờ duyệt', sentiment: '', createdAt: DateTime.now().toIso8601String()));
      if (_history.length > 50) _history = _history.sublist(0, 50);
    });
    _inputCtl.clear();
    try {
      final res = await _wishwallService.sendMessage(widget.eventId, text);
      if (res != null) {
        setState(() {
          _history = _history.map((m) => m.id == tempId ? m.copyWith(id: res.id) : m).toList();
          _bubbles = _bubbles.map((b) => b.id == tempId ? b.copyWith(id: res.id) : b).toList();
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể gửi tin nhắn.')));
    }
  }

  @override
  void dispose() {
    _connection?.stop();
    _inputCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: AppTheme.bgDarkAlt, body: Center(child: CircularProgressIndicator(color: AppTheme.primaryTealLight)));
    return Scaffold(backgroundColor: AppTheme.bgDarkAlt, body: Stack(children: [
      // Bubble area
      Positioned.fill(child: Stack(children: _bubbles.map((b) => _FloatingBubbleWidget(key: ValueKey(b.id), bubble: b, onDone: (id) => setState(() => _bubbles.removeWhere((x) => x.id == id)))).toList())),
      // Header
      Positioned(top: MediaQuery.of(context).padding.top + 16, left: 24, right: 24,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(onTap: () => Navigator.of(context).pop(), child: const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.chevron_left, color: Colors.white, size: 24))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_eventName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
            const Text('WISHWALL', style: TextStyle(color: AppTheme.primaryPink, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ])),
        ]),
      ),
      // Tray
      if (_isTrayOpen) Positioned(bottom: 76, left: 16, right: 16,
        child: Container(height: MediaQuery.of(context).size.height * 0.4, decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.borderMedium)),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Tin nhắn gần đây', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              GestureDetector(onTap: () => setState(() => _isTrayOpen = false), child: Icon(Icons.close, color: Colors.white.withOpacity(0.3), size: 20)),
            ])),
            Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _history.length,
              itemBuilder: (ctx, i) {
                final msg = _history[i];
                return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    if (msg.sentiment == 'Positive') const Text('🔥', style: TextStyle(fontSize: 14))
                    else if (msg.sentiment == 'Neutral') Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF22C55E), boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.5), blurRadius: 5)]))
                    else Text('✓', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.primaryPink)),
                    const SizedBox(width: 8),
                    Text(msg.userName.isNotEmpty ? msg.userName : 'Ẩn danh', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                  Padding(padding: const EdgeInsets.only(left: 14, top: 2), child: Text(msg.message, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w300))),
                ]));
              },
            )),
          ]),
        ),
      ),
      // Input bar
      Positioned(bottom: 0, left: 0, right: 0, child: Container(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(color: AppTheme.bgDarkAlt.withOpacity(0.8), border: Border(top: BorderSide(color: AppTheme.borderLight))),
        child: Row(children: [
          GestureDetector(onTap: () => setState(() => _isTrayOpen = !_isTrayOpen),
            child: Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: _isTrayOpen ? Colors.white : Colors.white.withOpacity(0.05), border: Border.all(color: _isTrayOpen ? Colors.white : AppTheme.borderMedium)),
              child: Icon(Icons.chat_bubble_outline, color: _isTrayOpen ? Colors.black : Colors.white.withOpacity(0.6), size: 20))),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppTheme.borderLight)),
            child: TextField(controller: _inputCtl, maxLength: 80, style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(hintText: 'Nhập tin nhắn...', hintStyle: TextStyle(color: Color(0xFF6B7280)), border: InputBorder.none, counterText: ''),
              onSubmitted: (_) => _sendMessage()))),
          const SizedBox(width: 8),
          GestureDetector(onTap: _sendMessage,
            child: Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: _inputCtl.text.trim().isNotEmpty ? AppTheme.primaryPink : Colors.transparent, border: Border.all(color: _inputCtl.text.trim().isNotEmpty ? AppTheme.primaryPink : AppTheme.borderMedium, width: 2)),
              child: const Icon(Icons.send, color: Colors.white, size: 20))),
        ]),
      )),
    ]));
  }
}

class _Bubble {
  final String id;
  final String text;
  final double x;
  final double startY;
  final String? sentiment;
  _Bubble({required this.id, required this.text, required this.x, required this.startY, this.sentiment});
  _Bubble copyWith({String? id, String? sentiment}) => _Bubble(id: id ?? this.id, text: text, x: x, startY: startY, sentiment: sentiment ?? this.sentiment);
}

class _FloatingBubbleWidget extends StatefulWidget {
  final _Bubble bubble;
  final void Function(String id) onDone;
  const _FloatingBubbleWidget({super.key, required this.bubble, required this.onDone});
  @override
  State<_FloatingBubbleWidget> createState() => _FloatingBubbleWidgetState();
}

class _FloatingBubbleWidgetState extends State<_FloatingBubbleWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _yAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500));
    _yAnim = Tween<double>(begin: 0, end: -0.9).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacityAnim = Tween<double>(begin: 1, end: 0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.6, 1.0)));
    _ctrl.addStatusListener((s) { if (s == AnimationStatus.completed) widget.onDone(widget.bubble.id); });
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final b = widget.bubble;
    final gradient = b.sentiment == 'Positive' ? const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFB8860B)])
      : b.sentiment == 'Neutral' ? const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF15803D)])
      : b.sentiment == 'Negative' ? const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFC2410C)])
      : LinearGradient(colors: [const Color(0xFF0E7490).withOpacity(0.8), const Color(0xFF164E63).withOpacity(0.8)]);

    return AnimatedBuilder(animation: _ctrl, builder: (ctx, _) {
      final screenH = MediaQuery.of(ctx).size.height;
      return Positioned(
        left: MediaQuery.of(ctx).size.width * b.x,
        bottom: b.startY + _yAnim.value * screenH,
        child: Opacity(opacity: _opacityAnim.value.clamp(0.0, 1.0),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), constraints: BoxConstraints(maxWidth: MediaQuery.of(ctx).size.width * 0.65),
            decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(20)),
            child: Text(b.text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis))),
      );
    });
  }
}
