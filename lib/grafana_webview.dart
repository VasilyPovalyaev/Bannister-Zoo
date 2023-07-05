import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewApp extends StatefulWidget {
  const WebViewApp({super.key});

  @override
  State<WebViewApp> createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..loadRequest(
        Uri.parse('https://koopa.grafana.net/d/JoROtTf4z/koopa-s-vivarium?orgId=1&from=now-24h&to=now'),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(
        controller: controller,
      ),
      // body: WebView(
      //   initialUrl: 'https://abdulrazakzakieh.com/',
      //   userAgent: 'random',
      // )
    );
  }
}
