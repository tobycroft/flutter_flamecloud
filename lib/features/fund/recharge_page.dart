import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/net/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_surfaces.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ticket_attachment_draft.dart';
import '../../data/repositories/file_upload_repository.dart';
import '../../data/repositories/recharge_repository.dart';
import 'recharge_controller.dart';

/// 充值页：在线充值（支付宝）/ 线下充值两个 Tab。
class RechargePage extends StatelessWidget {
  const RechargePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('充值'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: '在线充值'),
              Tab(text: '线下充值'),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            RechargeOnlineTab(),
            RechargeOfflineTab(),
          ],
        ),
      ),
    );
  }
}

/// 在线充值 Tab：金额 + 支付宝（当前唯一支付方式）。
class RechargeOnlineTab extends ConsumerStatefulWidget {
  const RechargeOnlineTab({super.key});

  @override
  ConsumerState<RechargeOnlineTab> createState() => _RechargeOnlineTabState();
}

class _RechargeOnlineTabState extends ConsumerState<RechargeOnlineTab> {
  final TextEditingController _amountCtl = TextEditingController();
  final FocusNode _amountFocus = FocusNode();

  String _sanitize(String value) {
    String result = value.replaceAll(RegExp(r'[^0-9.]'), '');
    final int dot = result.indexOf('.');
    if (dot != -1) {
      result =
          result.substring(0, dot + 1) + result.substring(dot + 1).replaceAll('.', '');
    }
    return result;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final String raw = _amountCtl.text.trim();
    final double? amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      _toast('请输入有效的充值金额');
      return;
    }
    if (amount > 6000) {
      _toast('单笔单日限额6000元，请选择其他方式充值');
      return;
    }
    final String? payUrl =
        await ref.read(rechargeControllerProvider.notifier).submitOnline(amount);
    if (!mounted) {
      return;
    }
    if (payUrl != null && payUrl.isNotEmpty) {
      unawaited(
        Navigator.of(context).pushNamed(
          AppRoutes.rechargeWebPay,
          arguments: payUrl,
        ),
      );
    } else if (payUrl != null && payUrl.isEmpty) {
      // 后端未配置支付通道（先留空状态），不拉起 WebView。
      _toast('支付通道待配置，请稍后再试');
    }
    // payUrl == null：错误见 state.errorMessage，由下方统一展示。
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RechargeState state = ref.watch(rechargeControllerProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color labelColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.info_outline, size: 16, color: Color(0xFFF59E0B)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '因支付平台虚拟商品单笔限额，单笔单日6000元，超额请选择其他方式充值。',
                    style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('充值金额', style: TextStyle(fontSize: 13, color: labelColor)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: context.surfaces.inset,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: TextField(
              controller: _amountCtl,
              focusNode: _amountFocus,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.deny(RegExp(r'[^0-9.]')),
              ],
              onChanged: (String v) {
                final String sanitized = _sanitize(v);
                if (sanitized != v) {
                  _amountCtl.value = TextEditingValue(
                    text: sanitized,
                    selection:
                        TextSelection.collapsed(offset: sanitized.length),
                  );
                }
                if (state.errorMessage != null) {
                  ref.read(rechargeControllerProvider.notifier).clearError();
                }
              },
              decoration: InputDecoration(
                prefixText: '¥ ',
                prefixStyle: const TextStyle(fontSize: 16, color: Colors.grey),
                hintText: '请输入充值金额',
                hintStyle: TextStyle(color: labelColor),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ),
          if (state.errorMessage != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              state.errorMessage!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
            ),
          ],
          const SizedBox(height: 20),
          Text('支付方式', style: TextStyle(fontSize: 13, color: labelColor)),
          const SizedBox(height: 8),
          _AlipayMethodCard(),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: state.loading ? null : _submit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: state.loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('立即充值'),
          ),
        ],
      ),
    );
  }
}

/// 支付宝支付方式卡片（当前唯一选项，固定选中）。
class _AlipayMethodCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Color border = const Color(0xFF3B82F6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: border.withValues(alpha: 0.06),
        border: Border.all(color: border, width: 1.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1677FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                '支',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '支付宝',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Icon(Icons.check_circle, color: border, size: 20),
        ],
      ),
    );
  }
}

/// 线下充值 Tab：汇款信息 + 收款凭证上传。
class RechargeOfflineTab extends ConsumerStatefulWidget {
  const RechargeOfflineTab({super.key});

  @override
  ConsumerState<RechargeOfflineTab> createState() =>
      _RechargeOfflineTabState();
}

class _RechargeOfflineTabState extends ConsumerState<RechargeOfflineTab> {
  final TextEditingController _amountCtl = TextEditingController();
  final TextEditingController _accountNameCtl = TextEditingController();
  final TextEditingController _bankAccountCtl = TextEditingController();
  final TextEditingController _bankNameCtl = TextEditingController();
  final TextEditingController _transactionIdCtl = TextEditingController();
  final TextEditingController _remarkCtl = TextEditingController();

  String? _remitMethod;
  final List<XFile> _vouchers = <XFile>[];
  bool _uploading = false;

  static const List<Map<String, String>> _remitOptions = <Map<String, String>>[
    <String, String>{'value': 'bank_transfer', 'label': '银行转账'},
    <String, String>{'value': 'alipay_transfer', 'label': '支付宝转账'},
    <String, String>{'value': 'wechat_transfer', 'label': '微信转账'},
  ];

  bool get _showBankFields => _remitMethod == 'bank_transfer';

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickVoucher() async {
    if (_vouchers.length >= 5) {
      _toast('最多上传5张凭证');
      return;
    }
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (picked != null && mounted) {
      setState(() => _vouchers.add(picked));
    }
  }

  void _removeVoucher(int index) =>
      setState(() => _vouchers.removeAt(index));

  Future<void> _submit() async {
    final String? method = _remitMethod;
    if (method == null || method.isEmpty) {
      _toast('请选择汇款方式');
      return;
    }
    final double? amount = double.tryParse(_amountCtl.text.trim());
    if (amount == null || amount <= 0) {
      _toast('请输入有效的充值金额');
      return;
    }
    if (_transactionIdCtl.text.trim().isEmpty) {
      _toast('请输入交易流水号');
      return;
    }
    if (_showBankFields) {
      if (_bankAccountCtl.text.trim().isEmpty) {
        _toast('银行转账请填写银行账户');
        return;
      }
      if (_bankNameCtl.text.trim().isEmpty) {
        _toast('银行转账请填写支付银行');
        return;
      }
    }

    // 上传凭证（如有）。
    String? voucherJson;
    if (_vouchers.isNotEmpty) {
      setState(() => _uploading = true);
      try {
        final FileUploadRepository repo =
            ref.read(fileUploadRepositoryProvider);
        final List<Map<String, String>> drafts =
            <Map<String, String>>[];
        for (final XFile file in _vouchers) {
          final List<int> bytes = await file.readAsBytes();
          final TicketAttachmentDraft draft =
              await repo.upload(file.name, bytes);
          drafts.add(<String, String>{
            'name': draft.name,
            'url': draft.url,
            'hash': draft.hash,
          });
        }
        voucherJson = jsonEncode(drafts);
      } on ApiException catch (error) {
        if (mounted) _toast(error.message.isEmpty ? '凭证上传失败' : error.message);
        setState(() => _uploading = false);
        return;
      } on Exception {
        if (mounted) _toast('凭证上传失败');
        setState(() => _uploading = false);
        return;
      } finally {
        if (mounted) setState(() => _uploading = false);
      }
    }

    final bool ok = await ref
        .read(rechargeControllerProvider.notifier)
        .submitOffline(
          RechargeOfflineForm(
            remitMethod: method,
            amount: _amountCtl.text.trim(),
            accountName: _accountNameCtl.text.trim().isEmpty
                ? null
                : _accountNameCtl.text.trim(),
            bankAccount: _showBankFields
                ? _bankAccountCtl.text.trim()
                : null,
            bankName:
                _showBankFields ? _bankNameCtl.text.trim() : null,
            transactionId: _transactionIdCtl.text.trim(),
            remark: _remarkCtl.text.trim().isEmpty
                ? null
                : _remarkCtl.text.trim(),
            voucherJson: voucherJson,
          ),
        );
    if (!mounted) {
      return;
    }
    if (ok) {
      _toast('线下充值申请已提交，请等待审核');
      _amountCtl.clear();
      _accountNameCtl.clear();
      _bankAccountCtl.clear();
      _bankNameCtl.clear();
      _transactionIdCtl.clear();
      _remarkCtl.clear();
      setState(() {
        _remitMethod = null;
        _vouchers.clear();
      });
    } else {
      final String? err =
          ref.read(rechargeControllerProvider).errorMessage;
      if (err != null) {
        _toast(err);
      }
    }
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    _accountNameCtl.dispose();
    _bankAccountCtl.dispose();
    _bankNameCtl.dispose();
    _transactionIdCtl.dispose();
    _remarkCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RechargeState state = ref.watch(rechargeControllerProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color labelColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _FieldLabel('汇款方式'),
          DropdownButtonFormField<String>(
            value: _remitMethod,
            items: _remitOptions
                .map(
                  (Map<String, String> m) => DropdownMenuItem<String>(
                    value: m['value'],
                    child: Text(m['label']!),
                  ),
                )
                .toList(),
            onChanged: (String? v) => setState(() => _remitMethod = v),
            decoration: _inputDecoration(labelColor),
          ),
          const SizedBox(height: 16),
          _FieldLabel('充值金额'),
          _AmountField(controller: _amountCtl),
          const SizedBox(height: 16),
          _FieldLabel('账户名称（选填）'),
          _TextField(controller: _accountNameCtl, hint: '请输入账户名称'),
          if (_showBankFields) ...<Widget>[
            const SizedBox(height: 16),
            _FieldLabel('银行账户'),
            _TextField(controller: _bankAccountCtl, hint: '请输入银行账户'),
            const SizedBox(height: 16),
            _FieldLabel('支付银行'),
            _TextField(controller: _bankNameCtl, hint: '请输入支付银行'),
          ],
          const SizedBox(height: 16),
          _FieldLabel('交易流水号'),
          _TextField(
            controller: _transactionIdCtl,
            hint: '请输入交易流水号',
          ),
          const SizedBox(height: 20),
          _FieldLabel('收款凭证（选填，最多5张）'),
          const SizedBox(height: 8),
          _VoucherPicker(
            vouchers: _vouchers,
            uploading: _uploading,
            onPick: _pickVoucher,
            onRemove: _removeVoucher,
          ),
          const SizedBox(height: 16),
          _FieldLabel('备注（选填）'),
          TextField(
            controller: _remarkCtl,
            maxLines: 3,
            decoration: _inputDecoration(labelColor).copyWith(
              hintText: '请输入备注信息',
              hintStyle: TextStyle(color: labelColor),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: state.loading || _uploading ? null : _submit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: state.loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('立即充值'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(Color labelColor) {
    return InputDecoration(
      filled: true,
      fillColor: context.surfaces.inset,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: context.surfaces.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: context.surfaces.line),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}

/// 字段标签。
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
        ),
      ),
    );
  }
}

/// 金额输入框（带 ¥ 前缀，仅允许数字与小数点）。
class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller});
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color labelColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    return Container(
      decoration: BoxDecoration(
        color: context.surfaces.inset,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: TextField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.deny(RegExp(r'[^0-9.]')),
        ],
        decoration: InputDecoration(
          prefixText: '¥ ',
          prefixStyle: const TextStyle(fontSize: 16, color: Colors.grey),
          hintText: '请输入充值金额',
          hintStyle: TextStyle(color: labelColor),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }
}

/// 普通文本输入框。
class _TextField extends StatelessWidget {
  const _TextField({required this.controller, this.hint});
  final TextEditingController controller;
  final String? hint;
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color labelColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    return Container(
      decoration: BoxDecoration(
        color: context.surfaces.inset,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: labelColor),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }
}

/// 收款凭证选择区：网格缩略图 + 添加按钮。
class _VoucherPicker extends StatelessWidget {
  const _VoucherPicker({
    required this.vouchers,
    required this.uploading,
    required this.onPick,
    required this.onRemove,
  });

  final List<XFile> vouchers;
  final bool uploading;
  final VoidCallback onPick;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        for (int i = 0; i < vouchers.length; i++)
          Stack(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: Image.file(
                  File(vouchers[i].path),
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 88,
                    height: 88,
                    color: context.surfaces.inset,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => onRemove(i),
                  child: const CircleAvatar(
                    radius: 11,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        if (vouchers.length < 5)
          GestureDetector(
            onTap: uploading ? null : onPick,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                border: Border.all(color: context.surfaces.line),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: uploading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.add, color: Colors.grey),
                        SizedBox(height: 4),
                        Text('上传图片',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
            ),
          ),
      ],
    );
  }
}

/// 充值入口按钮（用于资金管理页 AppBar）。
class RechargeEntryButton extends StatelessWidget {
  const RechargeEntryButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () =>
          unawaited(Navigator.of(context).pushNamed(AppRoutes.recharge)),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('充值'),
    );
  }
}
