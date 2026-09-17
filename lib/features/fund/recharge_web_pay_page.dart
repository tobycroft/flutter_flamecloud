import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 支付宝支付页：用 WebView 加载后端返回的手机网站支付链接。
///
/// 支付宝没有官方 Flutter SDK，移动端采用「手机网站支付」方案——
/// 后端 `recharge/online` 返回 `pay_url`（支付宝网关页），App 内用 WebView 打开，
/// 用户在网页内完成支付；支付完成回跳后由用户手动关闭本页。
class RechargeWebPayPage extends StatefulWidget {
  const RechargeWebPayPage({super.key, required this.payUrl});

  /// 支付宝手机网站支付链接。
  final String payUrl;

  @override
  State<RechargeWebPayPage> createState() => _RechargeWebPayPageState();
}

class _RechargeWebPayPageState extends State<RechargeWebPayPage> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.payUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('支付宝支付'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: <Widget>[
          if (_loading)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
