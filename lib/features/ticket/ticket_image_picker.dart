import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_surfaces.dart';
import '../../data/models/ticket_attachment_draft.dart';
import '../../data/repositories/file_upload_repository.dart';

/// 单个待上传图片的运行时状态。
class _PickerItem {
  _PickerItem(this.file);

  /// 本地文件。
  final XFile file;

  /// 上传成功后的附件草稿；未完成或失败为 null。
  TicketAttachmentDraft? draft;

  /// 是否正在上传。
  bool uploading = true;

  /// 失败原因；成功为 null。
  String? error;
}

/// 工单图片选择器。
///
/// 选中即按 Vue 端三段式流程立即上传，成功后把草稿加入列表；
/// 父组件可在提交 / 回复时通过 [attachments] 读取已上传附件，
/// 也可调用 [clear] 清空（如回复发送成功后）。
class TicketImagePicker extends ConsumerStatefulWidget {
  const TicketImagePicker({
    required this.onChanged,
    this.enabled = true,
    this.maxCount = 5,
    this.maxSizeBytes = 20 * 1024 * 1024,
    super.key,
  });

  /// 已上传附件集合变化回调。
  final ValueChanged<List<TicketAttachmentDraft>> onChanged;

  /// 是否可操作（如正在提交时禁用）。
  final bool enabled;

  /// 最多图片数。
  final int maxCount;

  /// 单张图片大小上限（字节）。
  final int maxSizeBytes;

  @override
  ConsumerState<TicketImagePicker> createState() => TicketImagePickerState();
}

/// 工单图片选择器运行时状态，供父组件通过 [GlobalKey] 读取已上传附件。
class TicketImagePickerState extends ConsumerState<TicketImagePicker> {
  final List<_PickerItem> _items = <_PickerItem>[];
  ImagePicker? _picker;

  /// 已上传成功的附件草稿。
  List<TicketAttachmentDraft> get attachments => _items
      .where((_PickerItem item) => item.draft != null)
      .map((_PickerItem item) => item.draft!)
      .toList(growable: false);

  /// 清空选择。
  void clear() {
    setState(() => _items.clear());
    widget.onChanged(<TicketAttachmentDraft>[]);
  }

  Future<void> _pick() async {
    if (!widget.enabled || !mounted) {
      return;
    }
    final ImagePicker picker = _picker ??= ImagePicker();
    final List<XFile> files;
    try {
      files = await picker.pickMultiImage();
    } on Exception {
      _toast('选择图片失败');
      return;
    }
    if (files.isEmpty) {
      return;
    }
    for (final XFile file in files) {
      if (_items.length >= widget.maxCount) {
        _toast('最多上传 ${widget.maxCount} 张图片');
        break;
      }
      final _PickerItem item = _PickerItem(file);
      setState(() => _items.add(item));
      unawaited(_upload(item));
    }
  }

  Future<void> _upload(_PickerItem item) async {
    try {
      final List<int> bytes = await item.file.readAsBytes();
      if (bytes.length > widget.maxSizeBytes) {
        if (!mounted) {
          return;
        }
        setState(() {
          item.uploading = false;
          item.error = '图片不得超过 ${widget.maxSizeBytes ~/ (1024 * 1024)}M';
        });
        return;
      }
      final TicketAttachmentDraft draft =
          await ref.read(fileUploadRepositoryProvider).upload(item.file.name, bytes);
      if (!mounted) {
        return;
      }
      setState(() {
        item.draft = draft;
        item.uploading = false;
      });
      widget.onChanged(attachments);
    } on Exception {
      if (!mounted) {
        return;
      }
      setState(() {
        item.uploading = false;
        item.error = '上传失败';
      });
      _toast('图片上传失败');
    }
  }

  void _remove(_PickerItem item) {
    setState(() => _items.remove(item));
    widget.onChanged(attachments);
  }

  void _toast(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color placeholder = isDark
        ? const Color(0xFF1F2937)
        : const Color(0xFFF3F4F6);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        for (final _PickerItem item in _items)
          _ThumbTile(
            item: item,
            placeholder: placeholder,
            onRemove: () => _remove(item),
          ),
        if (_items.length < widget.maxCount)
          _AddTile(
            enabled: widget.enabled,
            onTap: _pick,
          ),
      ],
    );
  }
}

/// 已选图片缩略图：本地预览 + 上传中遮罩 + 失败重试。
class _ThumbTile extends StatelessWidget {
  const _ThumbTile({
    required this.item,
    required this.placeholder,
    required this.onRemove,
  });

  final _PickerItem item;
  final Color placeholder;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final Widget background = Image.file(
      File(item.file.path),
      width: 72,
      height: 72,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        width: 72,
        height: 72,
        color: placeholder,
        child: const Icon(Icons.image_outlined, size: 24, color: Color(0xFF9CA3AF)),
      ),
    );

    return SizedBox(
      width: 72,
      height: 72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            background,
            if (item.uploading)
              Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else if (item.error != null)
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: const Center(
                    child: Icon(Icons.refresh, size: 22, color: Colors.white),
                  ),
                ),
              ),
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 虚线「添加图片」格子。
class _AddTile extends StatelessWidget {
  const _AddTile({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color border = context.surfaces.line;
    final Color icon = enabled
        ? (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF64748B)
            : const Color(0xFF9CA3AF))
        : const Color(0xFFCBD5E1);

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          border: Border.all(color: border, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.add_photo_alternate_outlined, size: 24, color: icon),
            const SizedBox(height: 2),
            Text(
              '图片',
              style: TextStyle(fontSize: 10, color: icon),
            ),
          ],
        ),
      ),
    );
  }
}
