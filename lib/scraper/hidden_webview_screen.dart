// lib/scraper/hidden_webview_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class HiddenWebViewScreen extends StatefulWidget {
  final String url;
  final Function(String html) onHtmlExtracted;
  final Function(String? error) onError;

  const HiddenWebViewScreen({
    Key? key,
    required this.url,
    required this.onHtmlExtracted,
    required this.onError,
  }) : super(key: key);

  @override
  State<HiddenWebViewScreen> createState() => _HiddenWebViewScreenState();
}

class _HiddenWebViewScreenState extends State<HiddenWebViewScreen> {
  InAppWebViewController? _webViewController;
  Timer? _timeoutTimer;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _setupTimeout();
  }

  void _setupTimeout() {
    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (!_isCompleted) {
        _isCompleted = true;
        widget.onError('Timeout: Failed to load page');
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // حجم 0x0 لإخفاء الشاشة
      body: SizedBox(
        width: 0,
        height: 0,
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri(widget.url),
          ),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            domStorageEnabled: true,
            useHybridComposition: true,
            cacheEnabled: true,
            userAgent:
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            transparentBackground: true,
            disableHorizontalScroll: true,
            disableVerticalScroll: true,
          ),
          onWebViewCreated: (controller) {
            _webViewController = controller;
          },
          onLoadStop: (controller, url) async {
            if (_isCompleted) return;

            // الانتظار قليلاً للتأكد من تحميل JavaScript
            await Future.delayed(const Duration(seconds: 2));

            try {
              // استخراج HTML الكامل
              final html = await controller.runJavaScriptReturningResult(
                'document.documentElement.outerHTML',
              );
              
              if (html is String) {
                _isCompleted = true;
                _timeoutTimer?.cancel();
                widget.onHtmlExtracted(html);
                Navigator.pop(context);
              }
            } catch (e) {
              if (!_isCompleted) {
                _isCompleted = true;
                _timeoutTimer?.cancel();
                widget.onError('Failed to extract HTML: $e');
                Navigator.pop(context);
              }
            }
          },
          onReceivedError: (controller, request, error) {
            if (!_isCompleted) {
              _isCompleted = true;
              _timeoutTimer?.cancel();
              widget.onError('Error loading page: ${error.description}');
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _webViewController?.dispose();
    super.dispose();
  }
}
