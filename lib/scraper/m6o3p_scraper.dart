// lib/scraper/m6o3p_scraper.dart

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../core/models.dart';
import 'base_scraper.dart';

class M6o3pScraper implements BaseScraper {
  static const String baseUrl = 'https://m6o3p.sbs';
  
  // WebView مخفي لتجاوز Cloudflare
  late InAppWebViewController _webViewController;
  bool _isWebViewReady = false;

  Future<void> _initWebView() async {
    if (_isWebViewReady) return;
    
    // إنشاء WebView مخفي في الخلفية
    // في التطبيق الفعلي، سيتم تهيئته في شاشة مخفية أو Service
    _isWebViewReady = true;
  }

  /// دالة مساعدة لجلب HTML بعد تجاوز Cloudflare
  Future<String> _fetchHtml(String url) async {
    await _initWebView();
    // هنا سيتم استخدام _webViewController.loadUrl(url)
    // ثم انتظار تحميل الصفحة
    // ثم إرجاع document.documentElement.outerHTML
    // سأكتب المنطق الكامل لاحقاً عند بناء الـ UI
    return ''; 
  }

  @override
  Future<Map<String, List<MediaItem>>> getHomePage() async {
    final htmlContent = await _fetchHtml('$baseUrl/h1/');
    final document = html_parser.parse(htmlContent);
    
    final Map<String, List<MediaItem>> homeData = {};

    // 1. استخراج المواضيع المميزة (Featured)
    homeData['featured'] = _extractMediaList(document, '.featured-section'); // اسم الكلاس تقريبي

    // 2. أحدث الأفلام
    homeData['latest_movies'] = _extractMediaList(document, '.latest-movies');

    // 3. أحدث الحلقات
    homeData['latest_episodes'] = _extractMediaList(document, '.latest-episodes');

    return homeData;
  }

  List<MediaItem> _extractMediaList(Document document, String sectionClass) {
    final List<MediaItem> items = [];
    final elements = document.querySelectorAll('$sectionClass .post-item'); // تعديل حسب الكلاس الحقيقي

    for (var element in elements) {
      final titleElement = element.querySelector('h3 a');
      final imgElement = element.querySelector('img');
      final qualityElement = element.querySelector('.quality');
      
      if (titleElement != null && imgElement != null) {
        items.add(MediaItem(
          id: titleElement.attributes['href'] ?? '',
          title: titleElement.text.trim(),
          posterUrl: imgElement.attributes['src'] ?? imgElement.attributes['data-src'] ?? '',
          quality: qualityElement?.text.trim(),
          url: titleElement.attributes['href'] ?? '',
          type: titleElement.text.contains('فيلم') ? MediaType.movie : MediaType.series,
        ));
      }
    }
    return items;
  }

  @override
  Future<MediaDetails> getDetails(String url) async {
    final htmlContent = await _fetchHtml(url);
    final document = html_parser.parse(htmlContent);

    // استخراج البيانات الأساسية
    final title = document.querySelector('h1')?.text ?? '';
    final poster = document.querySelector('.poster img')?.attributes['src'] ?? '';
    final description = document.querySelector('.story p')?.text ?? '';
    final metaInfo = document.querySelectorAll('.meta-info li');

    String? duration, country, network;
    for (var info in metaInfo) {
      if (info.text.contains('مدة العرض')) duration = info.text.split(':').last.trim();
      if (info.text.contains('البلد')) country = info.text.split(':').last.trim();
      if (info.text.contains('القناة')) network = info.text.split(':').last.trim();
    }

    // استخراج السيرفرات
    final servers = _extractServers(document);

    // استخراج المواسم والحلقات (للمسلسلات فقط)
    final seasons = _extractSeasons(document);

    return MediaDetails(
      media: MediaItem(
        id: url,
        title: title,
        posterUrl: poster,
        url: url,
        type: url.contains('movie') ? MediaType.movie : MediaType.series,
      ),
      description: description,
      duration: duration,
      country: country,
      network: network,
      seasons: seasons,
      servers: servers,
    );
  }

  List<Server> _extractServers(Document document) {
    final List<Server> servers = [];
    final serverElements = document.querySelectorAll('.servers-list .server-item');
    
    for (var element in serverElements) {
      final name = element.querySelector('.server-name')?.text ?? '';
      final quality = element.querySelector('.server-quality')?.text ?? '1080p';
      final watchUrl = element.querySelector('a.watch-btn')?.attributes['href'] ?? '';
      final downloadUrl = element.querySelector('a.download-btn')?.attributes['href'] ?? '';
      
      servers.add(Server(
        name: name,
        quality: quality,
        watchUrl: watchUrl,
        downloadUrl: downloadUrl,
      ));
    }
    return servers;
  }

  List<Season> _extractSeasons(Document document) {
    final List<Season> seasons = [];
    // منطق استخراج المواسم والحلقات
    return seasons;
  }

  @override
  Future<List<MediaItem>> search(String query) async {
    final htmlContent = await _fetchHtml('$baseUrl/?s=$query');
    final document = html_parser.parse(htmlContent);
    return _extractMediaList(document, '.search-results');
  }

  @override
  Future<String> extractVideoUrl(String watchUrl) async {
    await _initWebView();
    // 1. فتح watchUrl في الـ WebView المخفي
    // 2. انتظار تحميل الـ iframe
    // 3. استخراج رابط src من الـ iframe
    // 4. إذا كان الرابط من StreamHG أو hgcloud، نحتاج لفتحه واستخراج رابط .mp4 المباشر
    return '';
  }
}
