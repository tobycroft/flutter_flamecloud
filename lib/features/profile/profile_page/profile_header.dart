import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_surfaces.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_info.dart';

/// 账户信息头部：头像、昵称、UID/手机号与账户余额。
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({this.user, super.key});

  final UserInfo? user;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaces.panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.flame500,
            child: Text(
              _initial(user),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  user?.displayName ?? '未获取到用户信息',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitle(user),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                _balanceText(user),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.flame500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '账户余额',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _subtitle(UserInfo? user) {
    final String? uid = user?.uid;
    if (uid != null && uid.isNotEmpty) {
      return 'UID $uid';
    }
    final String? phone = user?.phone;
    if (phone != null && phone.isNotEmpty) {
      return phone;
    }
    return '';
  }

  /// 余额展示文案，未加载到时展示占位符。
  String _balanceText(UserInfo? user) {
    final String? balance = user?.balance;
    if (balance != null && balance.isNotEmpty) {
      return '¥$balance';
    }
    return '--';
  }

  String _initial(UserInfo? user) {
    final String name = user?.displayName ?? '';
    return name.isEmpty ? '火' : name.characters.first.toUpperCase();
  }
}
