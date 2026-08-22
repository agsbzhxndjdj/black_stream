// lib/scraper/base_scraper.dart

import '../core/models.dart';

abstract class BaseScraper {
  /// سحب الصفحة الرئيسية (أحدث الأفلام، المسلسلات، التصنيفات)
  Future<Map<String, List<MediaItem>>> getHomePage();

  /// سحب تفاصيل فيلم أو مسلسل (الوصف، المواسم، الحلقات)
  Future<MediaDetails> getDetails(String url);

  /// البحث عن محتوى معين
  Future<List<MediaItem>> search(String query);

  /// استخراج رابط الفيديو المباشر من صفحة المشاهدة
  Future<String> extractVideoUrl(String watchUrl);
}
