// lib/ui/details_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/models.dart';
import '../scraper/m6o3p_scraper_complete.dart';
import 'player_screen.dart';

class DetailsScreen extends StatefulWidget {
  final MediaItem mediaItem;

  const DetailsScreen({Key? key, required this.mediaItem}) : super(key: key);

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final M6o3pScraper _scraper = M6o3pScraper();
  MediaDetails? _details;
  bool _isLoading = true;
  Season? _selectedSeason;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final details = await _scraper.getDetails(widget.mediaItem.url);
      setState(() {
        _details = details;
        _isLoading = false;
        if (details.seasons.isNotEmpty) {
          _selectedSeason = details.seasons.first;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل التفاصيل: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    if (_details == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('فشل في تحميل البيانات', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.black87,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: _details!.media.posterUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[900]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _details!.media.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // معلومات إضافية
                  if (_details!.duration != null || _details!.country != null || _details!.network != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          if (_details!.duration != null) _buildInfoRow('المدة', _details!.duration!),
                          if (_details!.country != null) _buildInfoRow('البلد', _details!.country!),
                          if (_details!.network != null) _buildInfoRow('القناة', _details!.network!),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // الوصف
                  const Text('القصة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    _details!.description,
                    style: const TextStyle(color: Colors.white70, height: 1.5),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // زر المشاهدة الرئيسي
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _playVideo(_details!.servers.first.watchUrl),
                      icon: const Icon(Icons.play_arrow, color: Colors.black),
                      label: const Text('مشاهدة الآن', style: TextStyle(color: Colors.black, fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // قائمة السيرفرات
                  if (_details!.servers.isNotEmpty) ...[
                    const Text('السيرفرات', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ..._details!.servers.map((server) => _buildServerCard(server)),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // المواسم والحلقات (للمسلسلات فقط)
                  if (_details!.media.type == MediaType.series && _details!.seasons.isNotEmpty) ...[
                    const Text('الحلقات', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    
                    // اختيار الموسم
                    DropdownButton<Season>(
                      value: _selectedSeason,
                      dropdownColor: Colors.grey[900],
                      items: _details!.seasons.map((season) {
                        return DropdownMenuItem(
                          value: season,
                          child: Text('الموسم ${season.number}', style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (season) {
                        setState(() => _selectedSeason = season);
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // قائمة الحلقات
                    if (_selectedSeason != null)
                      ..._selectedSeason!.episodes.map((episode) => _buildEpisodeCard(episode)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildServerCard(Server server) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(server.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(server.quality, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          ElevatedButton(
            onPressed: () => _playVideo(server.watchUrl),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('مشاهدة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeCard(Episode episode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () => _loadEpisodeDetails(episode),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[900],
          padding: const EdgeInsets.all(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.play_circle_outline, color: Colors.red),
            const SizedBox(width: 12),
            Text('الحلقة ${episode.number}', style: const TextStyle(color: Colors.white)),
            if (episode.title.isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(child: Text(episode.title, style: const TextStyle(color: Colors.white70), overflow: TextOverflow.ellipsis)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loadEpisodeDetails(Episode episode) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.red)),
    );

    try {
      final details = await _scraper.getDetails(episode.url);
      Navigator.pop(context);
      
      if (details.servers.isNotEmpty) {
        _playVideo(details.servers.first.watchUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد سيرفرات متاحة')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل الحلقة: $e')),
      );
    }
  }

  void _playVideo(String url) {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد رابط تشغيل متاح')),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(videoUrl: url),
      ),
    );
  }
}
