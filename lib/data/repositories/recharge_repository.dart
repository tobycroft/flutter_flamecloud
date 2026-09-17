import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../core/net/api_envelope.dart';
import '../../core/net/api_exception.dart';
import '../../core/net/dio_client.dart';
import '../../core/net/http_providers.dart';
import '../../core/utils/json_value.dart';
import '../models/recharge_order.dart';

/// 充值订单接口仓库。
///
/// 搬迁自 vue_flamecloud/RechargeOrdersPage：订单号搜索 + 真分页，
/// 接口路径与 API_ENDPOINTS.user.recharge.orders 保持一致。
class RechargeRepository {
  const RechargeRepository(this._dio);

  final Dio _dio;

  /// 拉取充值订单列表，对应 `GET /v1/user/recharge/orders`。
  ///
  /// [page] 页码从 1 开始；[keyword] 为空时不做订单号过滤。
  /// 返回 data.list 与 data.total（真分页）。
  Future<RechargeOrderResult> fetchOrders({
    required int page,
    int pageSize = 10,
    String? keyword,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        ApiEndpoints.user.rechargeOrders,
        queryParameters: <String, Object?>{
          'page': page,
          'page_size': pageSize,
          'keyword': ?keyword,
        },
      );
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      final List<dynamic>? list = data?['list'] is List
          ? data!['list'] as List<dynamic>
          : null;
      final List<RechargeOrderItem> items =
          list
              ?.whereType<Map<dynamic, dynamic>>()
              .map(
                (Map<dynamic, dynamic> item) =>
                    RechargeOrderItem.fromMap(item.cast<String, dynamic>()),
              )
              .toList(growable: false) ??
          const <RechargeOrderItem>[];
      final int total = JsonValue.integer(data?['total']) ?? 0;
      return RechargeOrderResult(items: items, total: total);
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 在线充值下单，对应 `POST /v1/user/recharge/online`。
  ///
  /// [payMethod] 当前固定为 `alipay`。成功返回 [RechargeOnlineResult]，
  /// 其中 [RechargeOnlineResult.payUrl] 为支付宝手机网站支付链接，
  /// 为空表示后端尚未配置支付通道（留空待接入）。
  Future<RechargeOnlineResult> rechargeOnline(
    double amount,
    String payMethod,
  ) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        ApiEndpoints.user.rechargeOnline,
        data: FormData.fromMap(<String, Object?>{
          'amount': amount.toString(),
          'pay_method': payMethod,
        }),
      );
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      if (data == null) {
        throw const ApiFormatException();
      }
      return RechargeOnlineResult(
        orderNo: JsonValue.string(data['order_no']) ?? '',
        amount: JsonValue.string(data['amount']) ?? amount.toString(),
        payUrl: JsonValue.string(data['pay_url']) ?? '',
      );
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 线下充值申请，对应 `POST /v1/user/recharge/offline`。
  Future<void> rechargeOffline(RechargeOfflineForm form) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        ApiEndpoints.user.rechargeOffline,
        data: FormData.fromMap(<String, Object?>{
          'remit_method': form.remitMethod,
          'amount': form.amount,
          if (form.accountName != null) 'account_name': form.accountName,
          if (form.bankAccount != null) 'bank_account': form.bankAccount,
          if (form.bankName != null) 'bank_name': form.bankName,
          'transaction_id': form.transactionId,
          if (form.remitTime != null) 'remit_time': form.remitTime,
          if (form.remark != null) 'remark': form.remark,
          if (form.voucherJson != null) 'voucher': form.voucherJson,
        }),
      );
      _unwrap(response);
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 解析统一响应包。
  ApiEnvelope _unwrap(Response<dynamic> response) {
    final Object? data = response.data;
    if (data is ApiEnvelope) {
      return data;
    }
    throw const ApiFormatException();
  }
}

/// 充值订单仓库实例。
final Provider<RechargeRepository> rechargeRepositoryProvider =
    Provider<RechargeRepository>((Ref ref) {
      return RechargeRepository(ref.watch(dioProvider));
    });

/// 在线充值下单结果。
class RechargeOnlineResult {
  const RechargeOnlineResult({
    required this.orderNo,
    required this.amount,
    this.payUrl = '',
  });

  /// 订单号。
  final String orderNo;

  /// 金额（字符串，与后端保持一致）。
  final String amount;

  /// 支付宝手机网站支付链接；为空表示后端尚未配置支付通道。
  final String payUrl;
}

/// 线下充值申请表单。
class RechargeOfflineForm {
  const RechargeOfflineForm({
    required this.remitMethod,
    required this.amount,
    this.accountName,
    this.bankAccount,
    this.bankName,
    required this.transactionId,
    this.remitTime,
    this.remark,
    this.voucherJson,
  });

  /// 汇款方式：bank_transfer / alipay_transfer / wechat_transfer。
  final String remitMethod;

  /// 充值金额（字符串）。
  final String amount;

  /// 账户名称（选填）。
  final String? accountName;

  /// 银行账户（银行转账必填）。
  final String? bankAccount;

  /// 支付银行（银行转账必填）。
  final String? bankName;

  /// 交易流水号（必填）。
  final String transactionId;

  /// 汇款时间，格式 `2006-01-02 15:04:05`（选填，后端默认当前时间）。
  final String? remitTime;

  /// 备注（选填）。
  final String? remark;

  /// 收款凭证 JSON 数组字符串：[{name,url,hash}]（选填）。
  final String? voucherJson;
}
