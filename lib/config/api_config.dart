import 'package:flutter/foundation.dart';

/// 后端接口地址与端点常量。
///
/// 与 vue_flamecloud/src/config/api.ts 一一对应，方便后续按 Vue 页面逐个搬迁。
/// 地址不硬编码：默认与 Vue 端保持一致（http://127.0.0.1），
/// 可通过 `flutter run --dart-define=API_BASE_URL=xxx` 覆盖。
class ApiConfig {
  const ApiConfig._();

  /// 后端网关地址，对应 Vue 端
  /// `import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1'`。
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1',
  );

  /// 连接超时。
  static const Duration connectTimeout = Duration(seconds: 15);

  /// 接收超时。
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// 发送超时。
  static const Duration sendTimeout = Duration(seconds: 20);

  /// 是否输出网络日志，默认跟随构建模式。
  static const bool enableHttpLog = bool.fromEnvironment(
    'ENABLE_HTTP_LOG',
    defaultValue: kDebugMode,
  );

  /// 鉴权请求头名（后端 HeaderAuthMode = true，走自定义 Header 而非 Bearer）。
  static const String headerUid = 'uid';

  /// 鉴权请求头名。
  static const String headerToken = 'token';

  /// 调试请求头名（仅后端 TestMode 开启时有效，客户端默认不传）。
  static const String headerDebug = 'debug';
}

/// 接口路径常量表，结构与 Vue 端 API_ENDPOINTS 保持一致。
class ApiEndpoints {
  const ApiEndpoints._();

  /// 验证码。
  static const captcha = _CaptchaEndpoints();

  /// 用户。
  static const user = _UserEndpoints();

  /// 站内通知。
  static const notification = _NotificationEndpoints();

  /// 安全设置。
  static const security = _SecurityEndpoints();

  /// 通知设置。
  static const notificationSetting = _NotificationSettingEndpoints();

  /// 实名认证。
  static const verification = _VerificationEndpoints();

  /// 密码。
  static const password = _PasswordEndpoints();

  /// AccessKey。
  static const accessKey = _AccessKeyEndpoints();

  /// 操作日志。
  static const actionLog = _ActionLogEndpoints();

  /// 工单。
  static const ticket = _TicketEndpoints();

  /// 客服会话。
  static const chat = _ChatEndpoints();

  /// 云服务器。
  static const ecs = _EcsEndpoints();
}

/// 验证码接口。
class _CaptchaEndpoints {
  const _CaptchaEndpoints();

  /// 生成图形验证码。
  final String create = '/v1/user/captcha/create';

  /// 校验验证码。
  final String verify = '/v1/user/captcha/verify';

  /// 生成点选验证码。
  final String clickCreate = '/v1/user/captcha/click_create';

  /// 校验点选验证码。
  final String clickVerify = '/v1/user/captcha/click_verify';
}

/// 用户接口。
class _UserEndpoints {
  const _UserEndpoints();

  /// 注册。
  final String register = '/v1/user/register';

  /// 登录。
  final String login = '/v1/user/login';

  /// 个人信息（GET 读取 / POST 更新）。
  final String info = '/v1/user/info';

  /// 头像。
  final String avatar = '/v1/user/avatar';

  /// 文件上传。
  final String fileUpload = '/v1/user/file/upload';

  /// 余额。
  final String balance = '/v1/user/balance';

  /// 余额流水。
  final String balanceLog = '/v1/user/balance/log';

  /// 在线充值。
  final String rechargeOnline = '/v1/user/recharge/online';

  /// 线下充值。
  final String rechargeOffline = '/v1/user/recharge/offline';

  /// 充值订单列表。
  final String rechargeOrders = '/v1/user/recharge/orders';

  /// 充值订单详情。
  final String rechargeDetail = '/v1/user/recharge/detail';
}

/// 站内通知接口。
class _NotificationEndpoints {
  const _NotificationEndpoints();

  /// 列表。
  final String list = '/v1/notification/list';

  /// 未读数。
  final String unreadCount = '/v1/notification/unread_count';

  /// 标记已读。
  final String read = '/v1/notification/read';

  /// 全部已读。
  final String readAll = '/v1/notification/read_all';

  /// 删除。
  final String delete = '/v1/notification/delete';

  /// 全部删除。
  final String deleteAll = '/v1/notification/delete_all';

  /// 创建。
  final String create = '/v1/notification/create';
}

/// 安全设置接口。
class _SecurityEndpoints {
  const _SecurityEndpoints();

  /// 安全信息。
  final String info = '/v1/user/security';
}

/// 通知设置接口。
class _NotificationSettingEndpoints {
  const _NotificationSettingEndpoints();

  /// 通知设置。
  final String info = '/v1/user/notification_setting';
}

/// 实名认证接口。
class _VerificationEndpoints {
  const _VerificationEndpoints();

  /// 认证信息。
  final String info = '/v1/user/verification';

  /// 提交认证。
  final String submit = '/v1/user/verification/submit';

  /// 更新认证。
  final String update = '/v1/user/verification/update';

  /// 上传凭证 token。
  final String uploadToken = '/v1/user/verification/upload/token';

  /// 上传凭证解析。
  final String uploadResolve = '/v1/user/verification/upload/resolve';
}

/// 密码接口。
class _PasswordEndpoints {
  const _PasswordEndpoints();

  /// 修改密码。
  final String change = '/v1/user/password';
}

/// AccessKey 接口。
class _AccessKeyEndpoints {
  const _AccessKeyEndpoints();

  /// 列表。
  final String list = '/v1/user/access_key';

  /// 调用日志。
  final String log = '/v1/user/access_key/log';

  /// 全部调用日志。
  final String logAll = '/v1/user/access_key/log/all';

  /// 权限。
  final String permission = '/v1/user/access_key/permission';
}

/// 操作日志接口。
class _ActionLogEndpoints {
  const _ActionLogEndpoints();

  /// 列表。
  final String list = '/v1/actionlog/list';

  /// 类型。
  final String type = '/v1/actionlog/type';
}

/// 工单接口。
class _TicketEndpoints {
  const _TicketEndpoints();

  /// 列表。
  final String list = '/v1/ticket/list';

  /// 提交。
  final String submit = '/v1/ticket/submit';

  /// 以会话方式提交。
  final String submitChat = '/v1/ticket/submit_chat';

  /// 详情。
  final String detail = '/v1/ticket/detail';

  /// 回复。
  final String reply = '/v1/ticket/reply';

  /// 删除。
  final String delete = '/v1/ticket/delete';

  /// 批量删除。
  final String deleteBatch = '/v1/ticket/delete_batch';

  /// 关闭。
  final String close = '/v1/ticket/close';

  /// 重开。
  final String reopen = '/v1/ticket/reopen';

  /// 轮询。
  final String poll = '/v1/ticket/poll';

  /// 转工单。
  final String convert = '/v1/ticket/convert';
}

/// 客服会话接口。
class _ChatEndpoints {
  const _ChatEndpoints();

  /// 会话列表。
  final String list = '/v1/chat/list';

  /// 发送消息。
  final String send = '/v1/chat/send';

  /// 轮询消息。
  final String poll = '/v1/chat/poll';

  /// 客服在线状态。
  final String kfOnline = '/v1/chat/kf_online';
}

/// 云服务器接口。
class _EcsEndpoints {
  const _EcsEndpoints();

  /// 下单配置（ECS 页面搬迁后启用）。
  // ignore: unused_field
  static const config = _EcsConfigEndpoints();

  /// 实例（ECS 页面搬迁后启用）。
  // ignore: unused_field
  static const instance = _EcsInstanceEndpoints();

  /// 订单（ECS 页面搬迁后启用）。
  // ignore: unused_field
  static const order = _EcsOrderEndpoints();
}

/// 云服务器下单配置接口。
class _EcsConfigEndpoints {
  const _EcsConfigEndpoints();

  /// 地域。
  final String regions = '/v1/ecs/config/regions';

  /// 可用区。
  final String zones = '/v1/ecs/config/zones';

  /// 规格。
  final String specs = '/v1/ecs/config/specs';

  /// 镜像。
  final String images = '/v1/ecs/config/images';

  /// 磁盘。
  final String disks = '/v1/ecs/config/disks';

  /// 线路。
  final String lines = '/v1/ecs/config/lines';

  /// 带宽。
  final String bandwidth = '/v1/ecs/config/bandwidth';

  /// 专有网络。
  final String vpcs = '/v1/ecs/config/vpcs';
}

/// 云服务器实例接口。
class _EcsInstanceEndpoints {
  const _EcsInstanceEndpoints();

  /// 列表。
  final String list = '/v1/ecs/instance/list';

  /// 详情。
  final String detail = '/v1/ecs/instance/detail';

  /// 创建。
  final String create = '/v1/ecs/instance/create';
}

/// 云服务器订单接口。
class _EcsOrderEndpoints {
  const _EcsOrderEndpoints();

  /// 创建。
  final String create = '/v1/ecs/order/create';

  /// 支付。
  final String pay = '/v1/ecs/order/pay';

  /// 列表。
  final String list = '/v1/ecs/order/list';

  /// 详情。
  final String detail = '/v1/ecs/order/detail';
}
