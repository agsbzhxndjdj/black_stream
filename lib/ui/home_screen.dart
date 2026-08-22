// lib/ui/home_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/models.dart';
import '../scraper/m6o3p_scraper_complete.dart';
import 'details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final M6o3pScraper _scraper = M6o3pScraper();
  Map<String, List<MediaItem>> _homeData = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _scraper.getHomePage();
      setState(() {
        _homeData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل في تحميل البيانات: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Black Stream',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _showSearch(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadHomeData,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHomeData,
                  child: ListView(
                    children: [
                      if (_homeData.containsKey('featured') && _homeData['featured']!.isNotEmpty)
                        _buildSection('المواضيع المميزة', _homeData['featured']!),
                      if (_homeData.containsKey('latest_movies') && _homeData['latest_movies']!.isNotEmpty)
                        _buildSection('أحدث الأفلام', _homeData['latest_movies']!),
                      if (_homeData.containsKey('latest_episodes') && _homeData['latest_episodes']!.isNotEmpty)
                        _buildSection('أحدث الحلقات', _homeData['latest_episodes']!),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSection(String title, List<MediaItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildMediaCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMediaCard(MediaItem item) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailsScreen(mediaItem: item),
        ),
      ),
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.posterUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[900],
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[900],
                    child: const Icon(Icons.movie, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.quality != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.quality!,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: SearchDelegate(
        scraper: _scraper,
      ),
    );
  }
}

class SearchDelegate extends BaseSearchDelegate {
  final M6o3pScraper scraper;
  List<MediaItem> _results = [];
  bool _isSearching = false;

  SearchDelegate({required this.scraper});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          _results = [];
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchContent();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchContent();
  }

  Widget _buildSearchContent() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty && query.isNotEmpty) {
      return const Center(child: Text('لا توجد نتائج', style: TextStyle(color: Colors.white)));
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];
        return ListTile(
          leading: CachedNetworkImage(
            imageUrl: item.posterUrl,
            width: 50,
            height: 75,
            fit: BoxFit.cover,
          ),
          title: Text(item.title, style: const TextStyle(color: Colors.white)),
          subtitle: Text(item.year ?? '', style: const TextStyle(color: Colors.grey)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DetailsScreen(mediaItem: item)),
            );
          },
        );
      },
    );
  }
}
