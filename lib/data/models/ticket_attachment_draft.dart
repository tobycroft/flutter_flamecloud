/// 工单附件草稿（上传后、尚未提交前）。
///
/// 与 vue_flamecloud 的 `uploadedFiles` / `replyImages` 元素结构一致：
/// 上传三段式完成后得到 `{ name, url, hash }`，最终以 JSON 数组形式
/// 随 `attachments` 字段提交给后端（见 [TicketRepository.submit] /
/// [TicketRepository.reply]）。
class TicketAttachmentDraft {
  const TicketAttachmentDraft({
    required this.name,
    required this.url,
    required this.hash,
  });

  /// 文件名。
  final String name;

  /// 可访问地址，由 `user/file/upload` 用 hash 换取。
  final String url;

  /// 文件 hash，上传服务返回。
  final String hash;

  /// 序列化为后端要求的附件元素。
  Map<String, String> toJson() => <String, String>{
        'name': name,
        'url': url,
        'hash': hash,
      };
}
