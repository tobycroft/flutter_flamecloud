import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_info.dart';
import '../auth/session_controller.dart';
import 'ticket_meta.dart';
import 'ticket_submit_controller.dart';

/// 提交工单页，搬迁自 vue_flamecloud/TicketSubmitPage。
///
/// 两种类型：标准工单（`/submit`，需选分类与紧急性）与在线客服
/// （`/submit_chat`，仅描述）；联系手机默认带出账号手机号。
/// 提交成功后进入工单详情，并向上返回 true 触发列表刷新。
class TicketSubmitPage extends ConsumerStatefulWidget {
  const TicketSubmitPage({super.key});

  @override
  ConsumerState<TicketSubmitPage> createState() => _TicketSubmitPageState();
}

class _TicketSubmitPageState extends ConsumerState<TicketSubmitPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _otherCategoryController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isChat = false;
  String _urgency = 'fault';
  String _category = 'ecs';
  bool _phonePrefilled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillPhone());
  }

  /// 用当前登录用户的手机号预填联系方式。
  void _prefillPhone() {
    if (_phonePrefilled || !mounted) {
      return;
    }
    final UserInfo? user =
        ref.read(sessionControllerProvider).asData?.value?.user;
    final String? phone = user?.phone;
    if (phone != null && phone.isNotEmpty) {
      _phoneController.text = phone;
    }
    _phonePrefilled = true;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _otherCategoryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('请输入问题描述')));
      return;
    }
    final int id;
    if (_isChat) {
      id = await ref
          .read(ticketSubmitControllerProvider.notifier)
          .submitChat(
            description: description,
            contactPhone: _phoneController.text.trim(),
          );
    } else {
      id = await ref
          .read(ticketSubmitControllerProvider.notifier)
          .submitStandard(
            description: description,
            urgency: _urgency,
            category: _category,
            otherCategory: _category == 'other'
                ? _otherCategoryController.text.trim()
                : null,
            contactPhone: _phoneController.text.trim(),
          );
    }
    if (!mounted || id == 0) {
      return;
    }
    Navigator.of(context).pop(true);
    await Navigator.of(context).pushNamed(
      AppRoutes.ticketDetail,
      arguments: id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TicketSubmitState state = ref.watch(ticketSubmitControllerProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('提交工单'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            '工单类型',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _TypeCard(
                  icon: Icons.description_outlined,
                  title: '标准工单',
                  subtitle: '提交产品相关问题，走工单流程处理',
                  selected: !_isChat,
                  onTap: () => setState(() => _isChat = false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeCard(
                  icon: Icons.forum_outlined,
                  title: '在线客服',
                  subtitle: '创建聊天工单，客服实时回复',
                  selected: _isChat,
                  onTap: () => setState(() => _isChat = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _descriptionController,
            minLines: 5,
            maxLines: 8,
            maxLength: 1024,
            decoration: const InputDecoration(
              hintText: '请详细描述您遇到的问题',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          if (!_isChat) ...<Widget>[
            Text(
              '紧急性',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: <Widget>[
                for (final (String, String) item in TicketMeta.urgencies)
                  ChoiceChip(
                    label: Text(item.$2),
                    selected: _urgency == item.$1,
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() => _urgency = item.$1);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '问题分类',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(hintText: '选择问题分类'),
              items: <DropdownMenuItem<String>>[
                for (final (String, String) item
                    in TicketMeta.categories.where((e) => e.$1 != 'chat'))
                  DropdownMenuItem<String>(
                    value: item.$1,
                    child: Text(item.$2),
                  ),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),
            if (_category == 'other') ...<Widget>[
              const SizedBox(height: 12),
              TextField(
                controller: _otherCategoryController,
                decoration: const InputDecoration(hintText: '请填写具体分类'),
              ),
            ],
          ],
          const SizedBox(height: 20),
          Text(
            '联系手机',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: '留空则使用账号绑定的手机号',
            ),
          ),
          if (state.errorMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              state.errorMessage!,
              style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626)),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: state.submitting ? null : () => unawaited(_submit()),
            child: state.submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('提交工单'),
          ),
        ],
      ),
    );
  }
}

/// 工单类型选择卡。
class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: selected
          ? AppColors.flame500.withValues(alpha: 0.08)
          : (isDark ? AppColors.dark500 : Colors.white),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: selected
                  ? AppColors.flame500
                  : (isDark ? AppColors.dark300 : const Color(0xFFE5E7EB)),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                icon,
                size: 22,
                color: selected ? AppColors.flame500 : const Color(0xFF9CA3AF),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.flame500 : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
