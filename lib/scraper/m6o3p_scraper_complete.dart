// lib/scraper/m6o3p_scraper_complete.dart

import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../core/models.dart';
import 'base_scraper.dart';
import 'webview_manager.dart';

class M6o3pScraper implements BaseScraper {
  static const String baseUrl = 'https://m6o3p.sbs';
  final WebViewManager _webViewManager = WebViewManager();

  @override
  Future<Map<String, List<MediaItem>>> getHomePage() async {
    final htmlContent = await _webViewManager.fetchHtml('$baseUrl/h1/');
    final document = html_parser.parse(htmlContent);
    
    return {
      'featured': _extractFromSection(document, '.main-box'),
      'latest_movies': _extractFromSection(document, '.movies-list'),
      'latest_episodes': _extractFromSection(document, '.episodes-list'),
      'latest_seasons': _extractFromSection(document, '.seasons-list'),
    };
  }

  List<MediaItem> _extractFromSection(Document doc, String selector) {
    final List<MediaItem> items = [];
    final elements = doc.querySelectorAll(selector);

    for (var element in elements) {
      try {
        final titleElement = element.querySelector('h2 a, h3 a, .title a');
        if (titleElement == null) continue;

        final imgElement = element.querySelector('img');
        final posterUrl = imgElement?.attributes['src'] ?? 
                         imgElement?.attributes['data-src'] ?? 
                         imgElement?.attributes['data-lazy-src'] ?? '';

        final title = titleElement.text.trim();
        final url = titleElement.attributes['href'] ?? '';
        
        // تحديد النوع
        MediaType type = MediaType.movie;
        if (title.contains('مسلسل') || title.contains('انمي')) {
          type = MediaType.series;
        }

        // استخراج الجودة
        String? quality;
        final qualityElement = element.querySelector('.quality, .badge');
        if (qualityElement != null) {
          quality = qualityElement.text.trim();
        }

        // استخراج السنة
        String? year;
        final yearMatch = RegExp(r'\b(19|20)\d{2}\b').firstMatch(title);
        if (yearMatch != null) {
          year = yearMatch.group(0);
        }

        items.add(MediaItem(
          id: url.hashCode.toString(),
          title: title.replaceAll(RegExp(r'مشاهدة|مترجم|مدبلج'), '').trim(),
          posterUrl: posterUrl.startsWith('http') ? posterUrl : '$baseUrl$posterUrl',
          year: year,
          quality: quality,
          url: url.startsWith('http') ? url : '$baseUrl$url',
          type: type,
        ));
      } catch (e) {
        print('Error extracting item: $e');
        continue;
      }
    }

    return items;
  }

  @override
  Future<MediaDetails> getDetails(String url) async {
    final htmlContent = await _webViewManager.fetchHtml(url);
    final document = html_parser.parse(htmlContent);

    // استخراج العنوان
    final titleElement = document.querySelector('h1, .title h1, .post-title');
    final title = titleElement?.text.trim() ?? '';

    // استخراج البوستر
    final posterElement = document.querySelector('.poster img, .thumbnail img, img[itemprop="image"]');
    String posterUrl = posterElement?.attributes['src'] ?? 
                      posterElement?.attributes['data-src'] ?? '';
    if (!posterUrl.startsWith('http') && posterUrl.isNotEmpty) {
      posterUrl = '$baseUrl$posterUrl';
    }

    // استخراج الوصف
    final descElement = document.querySelector('.story, .description, .post-content');
    final description = descElement?.text.trim() ?? '';

    // استخراج المعلومات الإضافية
    final metaElements = document.querySelectorAll('.meta-info li, .info-table tr, .post-info span');
    String? duration, country, network, year, genre;

    for (var meta in metaElements) {
      final text = meta.text;
      if (text.contains('مدة') || text.contains('Duration')) {
        duration = text.split(':').last.trim();
      }
      if (text.contains('بلد') || text.contains('Country')) {
        country = text.split(':').last.trim();
      }
      if (text.contains('قناة') || text.contains('Network')) {
        network = text.split(':').last.trim();
      }
      if (text.contains('تصنيف') || text.contains('Genre')) {
        genre = text.split(':').last.trim();
      }
    }

    // استخراج السيرفرات
    final servers = _extractServers(document);

    // استخراج المواسم والحلقات
    final seasons = _extractSeasonsAndEpisodes(document);

    // تحديد النوع
    MediaType type = MediaType.movie;
    if (seasons.isNotEmpty || title.contains('مسلسل') || title.contains('انمي')) {
      type = MediaType.series;
    }

    return MediaDetails(
      media: MediaItem(
        id: url.hashCode.toString(),
        title: title.replaceAll(RegExp(r'مشاهدة|فيلم|مترجم|مدبلج'), '').trim(),
        posterUrl: posterUrl,
        url: url,
        type: type,
        year: year,
      ),
      description: description,
      duration: duration,
      country: country,
      network: network,
      seasons: seasons,
      servers: servers,
    );
  }

  List<Server> _extractServers(Document doc) {
    final List<Server> servers = [];
    
    // البحث عن جميع أزرار السيرفرات
    final serverButtons = doc.querySelectorAll(
      '.servers-list a, .download-links a, .server-item a, button[name="server"]'
    );

    for (var button in serverButtons) {
      final name = button.text.trim();
      if (name.isEmpty) continue;

      final href = button.attributes['href'] ?? '';
      if (href.isEmpty) continue;

      // تحديد الجودة
      String quality = '1080p';
      if (name.contains('720') || href.contains('720')) quality = '720p';
      if (name.contains('480') || href.contains('480')) quality = '480p';
      if (name.contains('4k') || name.contains('2160')) quality = '2160p';

      // تحديد نوع الرابط (مشاهدة أو تحميل)
      final isDownload = name.contains('تحميل') || name.contains('download');
      
      servers.add(Server(
        name: name.replaceAll(RegExp(r'حمل الآن|تحميل|مشاهدة'), '').trim(),
        quality: quality,
        watchUrl: isDownload ? '' : (href.startsWith('http') ? href : '$baseUrl$href'),
        downloadUrl: isDownload ? (href.startsWith('http') ? href : '$baseUrl$href') : '',
      ));
    }

    return servers;
  }

  List<Season> _extractSeasonsAndEpisodes(Document doc) {
    final List<Season> seasons = [];
    
    // البحث عن قائمة المواسم
    final seasonElements = doc.querySelectorAll('.season, .season-item, .tabs-content > div');
    
    for (var seasonElement in seasonElements) {
      final seasonTitle = seasonElement.querySelector('.season-title, h3, h4');
      int seasonNumber = 1;
      
      if (seasonTitle != null) {
        final match = RegExp(r'الموسم\s+(\d+)|Season\s+(\d+)').firstMatch(seasonTitle.text);
        if (match != null) {
          seasonNumber = int.tryParse(match.group(1) ?? match.group(2) ?? '1') ?? 1;
        }
      }

      // استخراج الحلقات
      final episodes = <Episode>[];
      final episodeElements = seasonElement.querySelectorAll('.episode, .episode-item, a');
      
      for (var epElement in episodeElements) {
        final epTitle = epElement.text.trim();
        final epUrl = epElement.attributes['href'] ?? '';
        
        if (epTitle.isNotEmpty && epUrl.isNotEmpty) {
          // استخراج رقم الحلقة
          int epNumber = 1;
          final epMatch = RegExp(r'الحلقة\s+(\d+)|Episode\s+(\d+)').firstMatch(epTitle);
          if (epMatch != null) {
            epNumber = int.tryParse(epMatch.group(1) ?? epMatch.group(2) ?? '1') ?? 1;
          }

          episodes.add(Episode(
            number: epNumber,
            title: epTitle.replaceAll(RegExp(r'الحلقة|\d+'), '').trim(),
            url: epUrl.startsWith('http') ? epUrl : '$baseUrl$epUrl',
          ));
        }
      }

      if (episodes.isNotEmpty) {
        seasons.add(Season(number: seasonNumber, episodes: episodes));
      }
    }

    return seasons;
  }

  @override
  Future<List<MediaItem>> search(String query) async {
    final htmlContent = await _webViewManager.fetchHtml('$baseUrl/?s=${Uri.encodeComponent(query)}');
    final document = html_parser.parse(htmlContent);
    return _extractFromSection(document, '.search-results, .main-box');
  }

  @override
  Future<String> extractVideoUrl(String watchUrl) async {
    // 1. فتح صفحة المشاهدة
    final htmlContent = await _webViewManager.fetchHtml(watchUrl);
    final document = html_parser.parse(htmlContent);

    // 2. البحث عن iframe
    final iframe = document.querySelector('iframe[src]');
    if (iframe == null) {
      throw Exception('No iframe found');
    }

    String iframeSrc = iframe.attributes['src'] ?? '';
    
    // 3. إذا كان الرابط من StreamHG أو hgcloud
    if (iframeSrc.contains('streamhg') || iframeSrc.contains('hgcloud') || iframeSrc.contains('hanerix')) {
      // نحتاج لفتحه واستخراج رابط .mp4
      return await _extractFromStreamHost(iframeSrc);
    }

    // 4. إذا كان رابط مباشر
    if (iframeSrc.endsWith('.mp4') || iframeSrc.contains('.m3u8')) {
      return iframeSrc;
    }

    return iframeSrc;
  }

  Future<String> _extractFromStreamHost(String url) async {
    // فتح صفحة StreamHG/hgcloud
    final htmlContent = await _webViewManager.fetchHtml(url);
    final document = html_parser.parse(htmlContent);

    // البحث عن رابط الفيديو
    // عادة يكون في video tag أو في JavaScript
    final videoElement = document.querySelector('video source[src]');
    if (videoElement != null) {
      return videoElement.attributes['src'] ?? '';
    }

    // البحث في JavaScript
    final scripts = document.querySelectorAll('script');
    for (var script in scripts) {
      final content = script.text;
      // البحث عن روابط .mp4 أو .m3u8
      final mp4Match = RegExp(r'https?://[^\s"\']+\.mp4').firstMatch(content);
      if (mp4Match != null) {
        return mp4Match.group(0)!;
      }
      
      final m3u8Match = RegExp(r'https?://[^\s"\']+\.m3u8').firstMatch(content);
      if (m3u8Match != null) {
        return m3u8Match.group(0)!;
      }
    }

    throw Exception('Video URL not found');
  }
                              }
