import 'package:flutter/material.dart';
import '../utils/theme.dart';

class LkFooter extends StatelessWidget {
  const LkFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/Linkie.png', height: 24),
          const SizedBox(height: 2),
          Text(
            'Xóa nhòa khoảng cách giữa sân khấu và khán giả.',
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
