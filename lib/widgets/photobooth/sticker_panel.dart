import 'package:flutter/material.dart';
import '../../models/sticker_item.dart';
import '../../utils/theme.dart';

/// Bottom panel for selecting stickers — tabs: Emoji | Decorative | Text
class StickerPanel extends StatefulWidget {
  final ValueChanged<StickerItem> onStickerSelected;
  final int currentCount;
  final int maxCount;

  const StickerPanel({
    super.key,
    required this.onStickerSelected,
    this.currentCount = 0,
    this.maxCount = 3,
  });

  @override
  State<StickerPanel> createState() => _StickerPanelState();
}

class _StickerPanelState extends State<StickerPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtl;

  final _tabs = const [
    Tab(text: '😍 Emoji'),
    Tab(text: '✨ Trang trí'),
    Tab(text: '💬 Chữ'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMaxed = widget.currentCount >= widget.maxCount;

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C23),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppTheme.borderMedium)),
      ),
      child: Column(
        children: [
          // Header with counter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sticker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isMaxed
                        ? Colors.red.withOpacity(0.15)
                        : AppTheme.primaryPink.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMaxed
                          ? Colors.red.withOpacity(0.3)
                          : AppTheme.primaryPink.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${widget.currentCount}/${widget.maxCount}',
                    style: TextStyle(
                      color: isMaxed ? Colors.red : AppTheme.primaryPink,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab bar
          TabBar(
            controller: _tabCtl,
            tabs: _tabs,
            labelColor: AppTheme.primaryPink,
            unselectedLabelColor: AppTheme.textTertiary,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            indicatorColor: AppTheme.primaryPink,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),

          // Sticker grid
          Expanded(
            child: TabBarView(
              controller: _tabCtl,
              children: [
                _buildStickerList(StickerCategory.emoji, isMaxed),
                _buildStickerList(StickerCategory.decorative, isMaxed),
                _buildStickerList(StickerCategory.text, isMaxed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickerList(StickerCategory category, bool isMaxed) {
    final stickers = StickerCatalog.getByCategory(category);

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: stickers.length,
      itemBuilder: (context, index) {
        final sticker = stickers[index];
        return GestureDetector(
          onTap: isMaxed ? null : () => widget.onStickerSelected(sticker),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isMaxed ? 0.3 : 1.0,
            child: Container(
              width: category == StickerCategory.text ? 100 : 64,
              height: 64,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Center(
                child: category == StickerCategory.text
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (sticker.textColor ?? AppTheme.primaryPink).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          sticker.content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      )
                    : Text(
                        sticker.content,
                        style: const TextStyle(fontSize: 32),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
