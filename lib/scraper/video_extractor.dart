// lib/scraper/video_extractor.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class VideoExtractor {
  /// استخراج رابط الفيديو المباشر من StreamHG أو hgcloud
  static Future<String> extractFromStreamHost(
    BuildContext context,
    String url,
  ) async {
    final completer = Completer<String>();

    // فتح شاشة WebView مخفية
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _VideoExtractorWebView(
          url: url,
          onVideoExtracted: (videoUrl) {
            if (!completer.isCompleted) {
              completer.complete(videoUrl);
            }
          },
          onError: (error) {
            if (!completer.isCompleted) {
              completer.completeError(error);
            }
          },
        ),
      ),
    );

    return completer.future;
  }

  /// استخراج رابط التحميل النهائي بعد الـ countdown
  static Future<String> extractDownloadLink(
    BuildContext context,
    String downloadPageUrl,
  ) async {
    final completer = Completer<String>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _DownloadExtractorWebView(
          url: downloadPageUrl,
          onLinkExtracted: (link) {
            if (!completer.isCompleted) {
              completer.complete(link);
            }
          },
          onError: (error) {
            if (!completer.isCompleted) {
              completer.completeError(error);
            }
          },
        ),
      ),
    );

    return completer.future;
  }
}

class _VideoExtractorWebView extends StatefulWidget {
  final String url;
  final Function(String videoUrl) onVideoExtracted;
  final Function(String error) onError;

  const _VideoExtractorWebView({
    required this.url,
    required this.onVideoExtracted,
    required this.onError,
  });

  @override
  State<_VideoExtractorWebView> createState() =>
      _VideoExtractorWebViewState();
}

class _VideoExtractorWebViewState extends State<_VideoExtractorWebView> {
  InAppWebViewController? _controller;
  Timer? _timeoutTimer;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer(const Duration(seconds: 20), () {
      if (!_isCompleted) {
        _isCompleted = true;
        widget.onError('Timeout extracting video');
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: 0,
        height: 0,
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.url)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            domStorageEnabled: true,
            useHybridComposition: true,
            userAgent:
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          ),
          onWebViewCreated: (controller) {
            _controller = controller;
          },
          onLoadStop: (controller, url) async {
            if (_isCompleted) return;

            await Future.delayed(const Duration(seconds: 3));

            try {
              // محاولة استخراج رابط الفيديو
              final videoUrl = await _extractVideoUrl(controller);
              
              if (videoUrl != null && videoUrl.isNotEmpty) {
                _isCompleted = true;
                _timeoutTimer?.cancel();
                widget.onVideoExtracted(videoUrl);
                Navigator.pop(context);
              }
            } catch (e) {
              if (!_isCompleted) {
                _isCompleted = true;
                _timeoutTimer?.cancel();
                widget.onError('Failed to extract video: $e');
                Navigator.pop(context);
              }
            }
          },
        ),
      ),
    );
  }

  Future<String?> _extractVideoUrl(InAppWebViewController controller) async {
    // 1. البحث عن video tag
    final videoSrc = await controller.runJavaScriptReturningResult('''
      (function() {
        var video = document.querySelector('video source[src]');
        if (video) return video.src;
        
        var videoTag = document.querySelector('video[src]');
        if (videoTag) return videoTag.src;
        
        return null;
      })()
    ''');

    if (videoSrc is String && videoSrc.isNotEmpty && videoSrc != 'null') {
      return videoSrc;
    }

    // 2. البحث في JavaScript variables
    final jsVideoUrl = await controller.runJavaScriptReturningResult('''
      (function() {
        // البحث عن متغيرات شائعة تحتوي على روابط فيديو
        var patterns = [
          /(?:file|src|url)\\s*[:=]\\s*["']([^"']+\\.(?:mp4|m3u8))["']/i,
          /https?:\\/\\/[^\\s"']+\\.(?:mp4|m3u8)[^\\s"']*/i
        ];
        
        var scripts = document.querySelectorAll('script');
        for (var script of scripts) {
          var content = script.textContent;
          for (var pattern of patterns) {
            var match = content.match(pattern);
            if (match) return match[1] || match[0];
          }
        }
        
        return null;
      })()
    ''');

    if (jsVideoUrl is String && jsVideoUrl.isNotEmpty && jsVideoUrl != 'null') {
      return jsVideoUrl;
    }

    return null;
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }
}

class _DownloadExtractorWebView extends StatefulWidget {
  final String url;
  final Function(String link) onLinkExtracted;
  final Function(String error) onError;

  const _DownloadExtractorWebView({
    required this.url,
    required this.onLinkExtracted,
    required this.onError,
  });

  @override
  State<_DownloadExtractorWebView> createState() =>
      _DownloadExtractorWebViewState();
}

class _DownloadExtractorWebViewState extends State<_DownloadExtractorWebView> {
  InAppWebViewController? _controller;
  Timer? _timeoutTimer;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer(const Duration(seconds: 90), () {
      if (!_isCompleted) {
        _isCompleted = true;
        widget.onError('Timeout extracting download link');
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: 0,
        height: 0,
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.url)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            domStorageEnabled: true,
            useHybridComposition: true,
            userAgent:
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          ),
          onWebViewCreated: (controller) {
            _controller = controller;
          },
          onLoadStop: (controller, url) async {
            if (_isCompleted) return;

            // التحقق من وجود countdown
            final hasCountdown = await _checkForCountdown(controller);
            
            if (hasCountdown) {
              // الانتظار حتى ينتهي الـ countdown
              await _waitForCountdown(controller);
            }

            await Future.delayed(const Duration(seconds: 2));

            try {
              // استخراج رابط التحميل
              final downloadLink = await _extractDownloadLink(controller);
              
              if (downloadLink != null && downloadLink.isNotEmpty) {
                _isCompleted = true;
                _timeoutTimer?.cancel();
                widget.onLinkExtracted(downloadLink);
                Navigator.pop(context);
              }
            } catch (e) {
              if (!_isCompleted) {
                _isCompleted = true;
                _timeoutTimer?.cancel();
                widget.onError('Failed to extract download link: $e');
                Navigator.pop(context);
              }
            }
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            // تتبع الـ redirects
            final url = navigationAction.request.url;
            if (url != null && _isDownloadLink(url.toString())) {
              _isCompleted = true;
              _timeoutTimer?.cancel();
              widget.onLinkExtracted(url.toString());
              Navigator.pop(context);
              return NavigationActionPolicy.CANCEL;
            }
            return NavigationActionPolicy.ALLOW;
          },
        ),
      ),
    );
  }

  Future<bool> _checkForCountdown(InAppWebViewController controller) async {
    final result = await controller.runJavaScriptReturningResult('''
      (function() {
        var countdownElement = document.querySelector('[id*="countdown"], [class*="countdown"], [id*="timer"]');
        return countdownElement !== null;
      })()
    ''');
    return result == true;
  }

  Future<void> _waitForCountdown(InAppWebViewController controller) async {
    // الانتظار حتى يختفي الـ countdown
    await controller.runJavaScript('''
      (function() {
        var checkInterval = setInterval(function() {
          var countdownElement = document.querySelector('[id*="countdown"], [class*="countdown"], [id*="timer"]');
          if (!countdownElement || countdownElement.style.display === 'none' || countdownElement.textContent === '0') {
            clearInterval(checkInterval);
            window.countdownFinished = true;
          }
        }, 1000);
      })()
    ''');

    // الانتظار حتى ينتهي الـ countdown
    while (true) {
      final isFinished = await controller.runJavaScriptReturningResult(
        'window.countdownFinished === true',
      );
      if (isFinished == true) break;
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<String?> _extractDownloadLink(InAppWebViewController controller) async {
    // البحث عن زر التحميل
    final downloadLink = await controller.runJavaScriptReturningResult('''
      (function() {
        var downloadButton = document.querySelector('a[href*="download"], button[id*="download"], a[class*="download"]');
        if (downloadButton) {
          return downloadButton.href || downloadButton.getAttribute('data-url');
        }
        
        // البحث عن رابط مباشر
        var links = document.querySelectorAll('a[href]');
        for (var link of links) {
          if (link.href.match(/\\.(mp4|mkv|avi|mov)(\\?|$)/i)) {
            return link.href;
          }
        }
        
        return null;
      })()
    ''');

    if (downloadLink is String && downloadLink.isNotEmpty && downloadLink != 'null') {
      return downloadLink;
    }

    return null;
  }

  bool _isDownloadLink(String url) {
    return url.endsWith('.mp4') ||
        url.endsWith('.mkv') ||
        url.endsWith('.avi') ||
        url.contains('download') ||
        url.contains('file');
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }
}
