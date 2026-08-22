// Black Stream 🖤 - نماذج البيانات

enum MediaType { movie, series, anime, program, unknown }

enum VideoType { hls, mp4, unknown }

MediaType typeFromInt(int i) =>
    (i >= 0 && i < MediaType.values.length) ? MediaType.values[i] : MediaType.unknown;

VideoType videoTypeFromInt(int i) =>
    (i >= 0 && i < VideoType.values.length) ? VideoType.values[i] : VideoType.unknown;

/* ======== 🎬 عنصر وسائط (فيلم / مسلسل / أنمي / حلقة) ======== */
class MediaItem {
  final String id;
  final String title;
  final String url;
  final String poster;
  final MediaType type;
  final String category;
  final int year;
  final int episodeNumber;
  final String quality;
  final bool isDubbed;
  final bool isLastEpisode;

  MediaItem({
    required this.title,
    required this.url,
    this.poster = '',
    this.type = MediaType.unknown,
    this.category = '',
    this.year = 0,
    this.episodeNumber = 0,
    this.quality = '',
    this.isDubbed = false,
    this.isLastEpisode = false,
  }) : id = _hash(url);

  static String _hash(String s) {
    if (s.isEmpty) return '0';
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h.toString();
  }

  bool get isMovie => type == MediaType.movie;
  bool get isSeries => type == MediaType.series;
  bool get isAnime => type == MediaType.anime;
  bool get isEpisode => episodeNumber > 0;

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'poster': poster,
        'type': type.index,
        'category': category,
        'year': year,
        'ep': episodeNumber,
        'quality': quality,
        'dubbed': isDubbed,
        'last': isLastEpisode,
      };

  factory MediaItem.fromJson(Map<String, dynamic> j) => MediaItem(
        title: (j['title'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
        poster: (j['poster'] ?? '').toString(),
        type: typeFromInt((j['type'] ?? 0) as int),
        category: (j['category'] ?? '').toString(),
        year: (j['year'] ?? 0) as int,
        episodeNumber: (j['ep'] ?? 0) as int,
        quality: (j['quality'] ?? '').toString(),
        isDubbed: j['dubbed'] == true,
        isLastEpisode: j['last'] == true,
      );
}

/* ======== 📺 حلقة ======== */
class Episode {
  final int number;
  final String title;
  final String url;

  const Episode({required this.number, required this.title, required this.url});

  Map<String, dynamic> toJson() => {'n': number, 't': title, 'u': url};

  factory Episode.fromJson(Map<String, dynamic> j) => Episode(
        number: (j['n']
