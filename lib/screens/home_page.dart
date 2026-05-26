import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../utils/theme.dart';
import '../widgets/navbar.dart';
import '../widgets/footer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().fetchEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final events = eventProvider.events;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Column(
        children: [
          const LkNavbar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Hero Banner ──
                  _buildHero(context),

                  // ── About Section ──
                  _buildAboutSection(),

                  // ── Features Title ──
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Tính năng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // ── Wishwall Feature Banner ──
                  _buildFeatureBanner(
                    context,
                    image: 'assets/images/banner-wishwall.jpg',
                    title: 'WISHWALL',
                    subtitle: 'Một phần không thể thiếu của sự kiện',
                    steps: ['Viết lời chúc', 'Gửi đi', 'Hiện trên LED'],
                  ),

                  const SizedBox(height: 8),

                  // ── Camera AR Feature Banner ──
                  _buildFeatureBanner(
                    context,
                    image: 'assets/images/banner-CameraFrame.jpg',
                    title: 'Camera AR',
                    subtitle: 'Lưu giữ khoảnh khắc cùng AR Frame độc quyền',
                    steps: ['Chọn AR Frame', 'Chụp ảnh', 'Lưu & Chia sẻ'],
                  ),

                  // ── Events Section ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      children: [
                        const Text(
                          'Hôm nay có gì?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (eventProvider.loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(color: AppTheme.primaryTealLight),
                          )
                        else if (events.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              'Hiện không có sự kiện nào đang hoạt động.',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                          )
                        else
                          ...events.map((event) => _buildEventCard(context, event)),
                      ],
                    ),
                  ),

                  // Space for footer
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          const LkFooter(),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.55,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/banner-intro.jpg', fit: BoxFit.cover),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppTheme.bgDark,
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.4),
                ],
              ),
            ),
          ),
          // Content
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NHẬP CUỘC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryTealLight),
                    foregroundColor: AppTheme.primaryTealLight,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text(
                    'Trải nghiệm ngay',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(
        children: [
          const Text(
            'Về chúng tôi',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset('assets/images/Linkie.png', height: 40),
                    const SizedBox(height: 8),
                    Text(
                      'Linkie là nền tảng kết nối tương tác trực tiếp tại sự kiện thông qua công nghệ Camera và Wishwall, giúp biến mỗi cá nhân trở thành một phần di sản của không gian nghệ thuật.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Logo Card
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFF00D5FF), width: 3),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10)],
                ),
                padding: const EdgeInsets.all(12),
                child: Image.asset('assets/images/logo-linkie-white.png', fit: BoxFit.contain),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Vision & Mission cards
          Row(
            children: [
              _buildInfoCard(
                'Tầm nhìn',
                'Trở thành nền tảng tương tác cho mọi không gian sự kiện, nơi mỗi cá nhân đều có thể chia sẻ trải nghiệm và lưu giữ ký ức cùng xúc cảm riêng mình.',
              ),
              const SizedBox(width: 12),
              _buildInfoCard(
                'Sứ mệnh',
                'Xóa nhòa khoảng cách giữa khán giả và sân khấu thông qua những điểm chạm công nghệ sáng tạo.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String text) {
    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.fromLTRB(14, 24, 14, 14),
            decoration: BoxDecoration(
              color: AppTheme.cardBgAlt,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFFD7E1FF), fontSize: 10, height: 1.5),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppTheme.gradientVisionMission,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00D8FF), width: 1),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBanner(
    BuildContext context, {
    required String image,
    required String title,
    required String subtitle,
    required List<String> steps,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed('/events'),
        child: Container(
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.25)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(image, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.black.withOpacity(0.45),
                      Colors.black.withOpacity(0.2),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Color(0xFFE5E5E5), fontSize: 12)),
                    const SizedBox(height: 20),
                    Row(
                      children: steps.asMap().entries.map((entry) {
                        return Padding(
                          padding: EdgeInsets.only(right: entry.key < steps.length - 1 ? 24 : 0),
                          child: Column(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.primaryTealLight, width: 2.5),
                                  color: AppTheme.primaryTealLight.withOpacity(0.2),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: 62,
                                child: Text(
                                  entry.value,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontSize: 10, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, dynamic event) {
    final status = event.eventStatus;
    final startDate = DateTime.parse(event.startTime);
    final isLive = status == 'live';

    return GestureDetector(
      onTap: isLive ? () => Navigator.of(context).pushNamed('/events/${event.id}') : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 176,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLive ? AppTheme.primaryTeal.withOpacity(0.4) : Colors.white.withOpacity(0.1),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Opacity(
          opacity: isLive ? 1.0 : 0.7,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail
              if (event.thumbnailUrl != null && event.thumbnailUrl!.isNotEmpty)
                Image.network(event.thumbnailUrl!, fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(color: AppTheme.cardBg))
              else
                Container(color: AppTheme.cardBg),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
              ),

              // Status badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isLive ? AppTheme.bgDark.withOpacity(0.8) : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLive) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                        ),
                        const SizedBox(width: 6),
                        const Text('Đang diễn ra', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ] else
                        Text(
                          'Sắp diễn ra',
                          style: TextStyle(color: AppTheme.bgDark, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom info
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            event.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${startDate.year}',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Date badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDark.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderStrong),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Tháng ${startDate.month}',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9),
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              startDate.day.toString().padLeft(2, '0'),
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
