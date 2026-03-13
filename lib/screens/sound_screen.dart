import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../widgets/common_ui.dart';
import 'settings_screen.dart';

class SoundScreen extends StatefulWidget {
  const SoundScreen({super.key});
  @override
  State<SoundScreen> createState() => _SoundScreenState();
}

class _SoundScreenState extends State<SoundScreen> {
  final AudioPlayer _player = AudioPlayer();
  String? _playingUrl;
  double _volume = 0.5;

  Future<void> _play(String url) async {
    try {
      if (_playingUrl == url) { 
        await _player.stop(); 
        setState(() => _playingUrl = null); 
        return; 
      }
      String playUrl = url;
      if (url.startsWith('gs://')) {
        playUrl = await FirebaseStorage.instance.refFromURL(url).getDownloadURL();
      }
      await _player.setUrl(playUrl); 
      _player.setVolume(_volume); 
      _player.play();
      setState(() => _playingUrl = url);
    } catch (e) { 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('재생 에러: $e'))
        ); 
      }
    }
  }

  @override
  void dispose() { 
    _player.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            buildTopBar(context, onSettingsTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            }),
            const SizedBox(height: 20),
            const Text('ASMR 사운드스케이프', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('공간의 입체감을 살린 고품질 오디오 컨텐츠입니다.', style: TextStyle(color: Colors.white.withOpacity(0.5))),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('soundscapes').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final url = data['url'] ?? '';
                      final isPlaying = _playingUrl == url;
                      final colorStr = data['color'];
                      return _buildSoundCard(
                        data['name'] ?? '사운드', 
                        isPlaying, 
                        () => _play(url), 
                        data['iconName'],
                        colorStr,
                      );
                    },
                  );
                },
              ),
            ),
            Padding(padding: const EdgeInsets.all(24.0), child: _buildVolumeCard()),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String? colorStr, {Color defaultColor = const Color(0xFFF472B6)}) {
    if (colorStr == null || colorStr.isEmpty) return defaultColor;
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
      } else if (colorStr.startsWith('0x')) {
        return Color(int.parse(colorStr));
      } else if (colorStr.contains('bg-')) {
        if (colorStr.contains('blue')) return Colors.blue;
        if (colorStr.contains('orange')) return Colors.orange;
        if (colorStr.contains('cyan')) return Colors.cyan;
        if (colorStr.contains('amber')) return Colors.amber;
        if (colorStr.contains('green')) return Colors.green;
        if (colorStr.contains('pink')) return const Color(0xFFF472B6);
      }
    } catch (e) {
      debugPrint("Color parsing error: $e");
    }
    return defaultColor;
  }

  Widget _buildSoundCard(String title, bool isPlaying, VoidCallback onTap, String? iconName, String? colorStr) {
    final themeColor = _parseColor(colorStr);
    
    IconData getIcon() {
      switch(iconName) {
        case 'flame': return Icons.local_fire_department;
        case 'rain': return Icons.umbrella;
        case 'waves': return Icons.waves;
        case 'library': return Icons.menu_book;
        case 'coffee': return Icons.coffee;
        case 'cloudRain': return Icons.cloud_queue;
        default: return Icons.music_note;
      }
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1512),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isPlaying ? themeColor.withOpacity(0.5) : Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPlaying ? themeColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(getIcon(), color: isPlaying ? themeColor : Colors.white.withOpacity(0.7), size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('"$title"', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('AMBIENT SOUNDSCAPE', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, letterSpacing: 1.2)),
            ]),
          ),
          GestureDetector(
            onTap: onTap, 
            child: Container(
              padding: const EdgeInsets.all(10), 
              decoration: BoxDecoration(
                color: isPlaying ? themeColor : Colors.white.withOpacity(0.05), 
                shape: BoxShape.circle
              ), 
              child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: isPlaying ? Colors.black : Colors.white, size: 20)
            )
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF1A1512), borderRadius: BorderRadius.circular(32)),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.volume_up_outlined, color: Colors.grey, size: 20), 
          const SizedBox(width: 12), 
          const Text('볼륨 조절', style: TextStyle(color: Colors.white, fontSize: 14)), 
          const Spacer(), 
          Text('${(_volume * 100).toInt()}%', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12))
        ]),
        Slider(
          value: _volume, 
          activeColor: const Color(0xFFF472B6), 
          inactiveColor: Colors.white.withOpacity(0.05), 
          onChanged: (v) { setState(() { _volume = v; _player.setVolume(_volume); }); }
        ),
      ]),
    );
  }
}
