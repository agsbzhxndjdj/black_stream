// lib/scraper/m6o3p_scraper_final.dart

import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../core/models.dart';
import 'base_scraper.dart';
import 'hidden_webview_screen.dart';
import 'video_extractor.dart';

class M6o3pScraper implements BaseScraper {
  static const String baseUrl = 'https://m6o3p.sbs';
  final BuildContext _context;

  M6o3pScraper(this._context);

  @override
  Future<Map<String, List<MediaItem>>> getHomePage() async {
    final htmlContent = await _fetchHtml('$baseUrl/h1/');
    final document = html_parser.parse(htmlContent);
    
    return {
      'featured': _extractMediaList(document, '.main-box .post-item, .featured-posts .post'),
      'latest_movies': _extractMediaList(document, '.movies-list .post-item, .latest-movies .post'),
      'latest_episodes': _extractMediaList(document, '.episodes-list .post-item, .latest-episodes .post'),
      'latest_seasons': _extractMediaList(document, '.seasons-list .post-item, .latest-seasons .post'),
    };
  }

  Future<String> _fetchHtml(String url) async {
    final completer = Completer<String>();
    final errorCompleter = Completer<String>();

    Navigator.push(
      _context,
      MaterialPageRoute(
        builder: (context) => HiddenWebViewScreen(
          url: url,
          onHtmlExtracted: (html) {
            if (!completer.isCompleted) {
              completer.complete(html);
            }
          },
          onError: (error) {
            if (!errorCompleter.isCompleted) {
              errorCompleter.complete(error ?? 'Unknown error');
            }
          },
        ),
      ),
    );

    try {
      return await completer.future.timeout(const Duration(seconds: 20));
    } catch (e) {
      if (!errorCompleter.isCompleted) {
        return await errorCompleter.future;
      }
      throw Exception('Failed to fetch HTML: $e');
    }
  }

  List<MediaItem> _extractMediaList(Document doc, String selector) {
    final List<MediaItem> items = [];
    final elements = doc.querySelectorAll(selector);

    for (var element in elements) {
      try {
        final titleElement = element.querySelector('h2 a, h3 a, .title a, a[itemprop="url"]');
        if (titleElement == null) continue;

        final imgElement = element.querySelector('img');
        String posterUrl = imgElement?.attributes['src'] ?? 
                          imgElement?.attributes['data-src'] ?? 
                          imgElement?.attributes['data-lazy-src'] ?? '';
        
        if (!posterUrl.startsWith('http') && posterUrl.isNotEmpty) {
          posterUrl = '$baseUrl$posterUrl';
        }

        final title = titleElement.text.trim();
        String url = titleElement.attributes['href'] ?? '';
        if (!url.startsWith('http') && url.isNotEmpty) {
          url = '$baseUrl$url';
        }

        MediaType type = MediaType.movie;
        if (title.contains('مسلسل') || title.contains('انمي') || url.contains('episode') || url.contains('series')) {
          type = MediaType.series;
        }

        String? quality;
        final qualityElement = element.querySelector('.quality, .badge, .hd-quality');
        if (qualityElement != null) {
          quality = qualityElement.text.trim();
        }

        String? year;
        final yearMatch = RegExp(r'\b(19|20)\d{2}\b').firstMatch(title);
        if (yearMatch != null) {
          year = yearMatch.group(0);
        }

        items.add(MediaItem(
          id: url.hashCode.toString(),
          title: title.replaceAll(RegExp(r'مشاهدة|فيلم|مترجم|مدبلج|اون لاين'), '').trim(),
          posterUrl: posterUrl,
          year: year,
          quality: quality,
          url: url,
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
    final htmlContent = await _fetchHtml(url);
    final document = html_parser.parse(htmlContent);

    final titleElement = document.querySelector('h1, .title h1, .post-title, h1[itemprop="name"]');
    final title = titleElement?.text.trim() ?? '';

    final posterElement = document.querySelector('.poster img, .thumbnail img, img[itemprop="image"], .post-image img');
    String posterUrl = posterElement?.attributes['src'] ?? 
                      posterElement?.attributes['data-src'] ?? '';
    if (!posterUrl.startsWith('http') && posterUrl.isNotEmpty) {
      posterUrl = '$baseUrl$posterUrl';
    }

    final descElement = document.querySelector('.story, .description, .post-content, .entry-content');
    final description = descElement?.text.trim() ?? '';

    final metaElements = document.querySelectorAll('.meta-info li, .info-table tr, .post-info span, .movie-info li');
    String? duration, country, network, year, genre;

    for (var meta in metaElements) {
      final text = meta.text;
      if (text.contains('مدة') || text.contains('Duration')) {
        duration = text.split(':').last.trim();
      }
      if (text.contains('بلد') || text.contains('Country')) {
        country = text.split(':').last.trim();
      }
      if (text.contains('قناة') || text.contains('Network') || text.contains('شبكة')) {
        network = text.split(':').last.trim();
      }
      if (text.contains('تصنيف') || text.contains('Genre') || text.contains('النوع')) {
        genre = text.split(':').last.trim();
      }
    }

    final servers = _extractServers(document);
    final seasons = _extractSeasonsAndEpisodes(document);

    MediaType type = MediaType.movie;
    if (seasons.isNotEmpty || title.contains('مسلسل') || title.contains('انمي') || url.contains('episode')) {
      type = MediaType.series;
    }

    return MediaDetails(
      media: MediaItem(
        id: url.hashCode.toString(),
        title: title.replaceAll(RegExp(r'مشاهدة|فيلم|مترجم|مدبلج|اون لاين'), '').trim(),
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
    
    final serverElements = doc.querySelectorAll(
      '.servers-list .server-item, .download-links a, .server-box a, .watch-servers a'
    );

    for (var element in serverElements) {
      final name = element.text.trim();
      if (name.isEmpty) continue;

      String href = element.attributes['href'] ?? '';
      if (href.isEmpty) continue;
      if (!href.startsWith('http')) {
        href = '$baseUrl$href';
      }

      String quality = '1080p';
      if (name.contains('720') || href.contains('720')) quality = '720p';
      if (name.contains('480') || href.contains('480')) quality = '480p';
      if (name.contains('4k') || name.contains('2160')) quality = '2160p';

      final isDownload = name.contains('تحميل') || name.toLowerCase().contains('download');
      
      servers.add(Server(
        name: name.replaceAll(RegExp(r'حمل الآن|تحميل|مشاهدة|Watch|Download'), '').trim(),
        quality: quality,
        watchUrl: isDownload ? '' : href,
        downloadUrl: isDownload ? href : '',
      ));
    }

    return servers;
  }

  List<Season> _extractSeasonsAndEpisodes(Document doc) {
    final List<Season> seasons = [];
    
    final seasonElements = doc.querySelectorAll('.season, .season-item, .tabs-content > div, .episodes-list');
    
    for (var seasonElement in seasonElements) {
      final seasonTitle = seasonElement.querySelector('.season-title, h3, h4');
      int seasonNumber = 1;
      
      if (seasonTitle != null) {
        final match = RegExp(r'الموسم\s+(\d+)|Season\s+(\d+)').firstMatch(seasonTitle.text);
        if (match != null) {
          seasonNumber = int.tryParse(match.group(1) ?? match.group(2) ?? '1') ?? 1;
        }
      }

      final episodes = <Episode>[];
      final episodeElements = seasonElement.querySelectorAll('.episode, .episode-item, a[href*="episode"]');
      
      for (var epElement in episodeElements) {
        final epTitle = epElement.text.trim();
        String epUrl = epElement.attributes['href'] ?? '';
        
        if (epTitle.isNotEmpty && epUrl.isNotEmpty) {
          if (!epUrl.startsWith('http')) {
            epUrl = '$baseUrl$epUrl';
          }

          int epNumber = 1;
          final epMatch = RegExp(r'الحلقة\s+(\d+)|Episode\s+(\d+)').firstMatch(epTitle);
          if (epMatch != null) {
            epNumber = int.tryParse(epMatch.group(1) ?? epMatch.group(2) ?? '1') ?? 1;
          }

          episodes.add(Episode(
            number: epNumber,
            title: epTitle.replaceAll(RegExp(r'الحلقة|\d+|مترجم|مدبلج'), '').trim(),
            url: epUrl,
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
    final htmlContent = await _fetchHtml('$baseUrl/?s=${Uri.encodeComponent(query)}');
    final document = html_parser.parse(htmlContent);
    return _extractMediaList(document, '.search-results .post-item, .main-box .post');
  }

  @override
  Future<String> extractVideoUrl(String watchUrl) async {
    // 1. جلب HTML صفحة المشاهدة
    final htmlContent = await _fetchHtml(watchUrl);
    final document = html_parser.parse(htmlContent);

    // 2. البحث عن iframe
    final iframe = document.querySelector('iframe[src]');
    if (iframe == null) {
      throw Exception('No iframe found in watch page');
    }

    String iframeSrc = iframe.attributes['src'] ?? '';
    if (iframeSrc.isEmpty) {
      throw Exception('Empty iframe src');
    }

    // 3. إذا كان من StreamHG أو hgcloud أو hanerix
    if (iframeSrc.contains('streamhg') || 
        iframeSrc.contains('hgcloud') || 
        iframeSrc.contains('hanerix') ||
        iframeSrc.contains('hg')) {
      return await VideoExtractor.extractFromStreamHost(_context, iframeSrc);
    }

    // 4. إذا كان رابط مباشر
    if (iframeSrc.endsWith('.mp4') || iframeSrc.contains('.m3u8')) {
      return iframeSrc;
    }

    // 5. محاولة فتحه مباشرة
    return await VideoExtractor.extractFromStreamHost(_context, iframeSrc);
  }

  Future<String> extractDownloadLink(String downloadUrl) async {
    return await VideoExtractor.extractDownloadLink(_context, downloadUrl);
  }
}
