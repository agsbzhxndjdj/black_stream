// lib/core/models.dart

enum MediaType { movie, series, anime }

class MediaItem {
  final String id;
  final String title;
  final String posterUrl;
  final String? rating;
  final String? year;
  final String? quality; // HD, WEB-DL, etc.
  final String url; // رابط صفحة التفاصيل
  final MediaType type;
  final List<String> genres;

  MediaItem({
    required this.id,
    required this.title,
    required this.posterUrl,
    this.rating,
    this.year,
    this.quality,
    required this.url,
    required this.type,
    this.genres = const [],
  });

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      posterUrl: map['posterUrl'] ?? '',
      rating: map['rating'],
      year: map['year'],
      quality: map['quality'],
      url: map['url'] ?? '',
      type: MediaType.values.firstWhere((e) => e.toString() == map['type'], orElse: () => MediaType.movie),
      genres: List<String>.from(map['genres'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'posterUrl': posterUrl,
      'rating': rating,
      'year': year,
      'quality': quality,
      'url': url,
      'type': type.toString(),
      'genres': genres,
    };
  }
}

class MediaDetails {
  final MediaItem media;
  final String description;
  final String? duration;
  final String? country;
  final String? network;
  final List<Season> seasons; // للمسلسلات فقط
  final List<Server> servers; // سيرفرات المشاهدة والتحميل

  MediaDetails({
    required this.media,
    required this.description,
    this.duration,
    this.country,
    this.network,
    this.seasons = const [],
    this.servers = const [],
  });
}

class Season {
  final int number;
  final List<Episode> episodes;

  Season({required this.number, required this.episodes});
}

class Episode {
  final int number;
  final String title;
  final String url; // رابط صفحة الحلقة
  final String? thumbnail;

  Episode({
    required this.number,
    required this.title,
    required this.url,
    this.thumbnail,
  });
}

class Server {
  final String name; // اسم السيرفر (مثال: StreamHG, Mixdrop)
  final String quality; // 1080p, 720p
  final String watchUrl; // رابط المشاهدة المباشرة (iframe)
  final String downloadUrl; // رابط صفحة التحميل

  Server({
    required this.name,
    required this.quality,
    required this.watchUrl,
    required this.downloadUrl,
  });
}
