import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase 초기화 실패: $e");
  }
  runApp(const HealingMomentsApp());
}

class HealingMomentsApp extends StatelessWidget {
  const HealingMomentsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Healing Moments',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0502),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          brightness: Brightness.dark,
          surface: const Color(0xFF1A1512),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const BreathingScreen(),
    const SoundScreen(),
    const JournalScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF0A0502),
          selectedItemColor: Colors.pinkAccent,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: '홈'),
            BottomNavigationBarItem(icon: Icon(Icons.air), label: '호흡'),
            BottomNavigationBarItem(icon: Icon(Icons.music_note_outlined), activeIcon: Icon(Icons.music_note), label: '사운드'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite_border), activeIcon: Icon(Icons.favorite), label: '기록'),
          ],
        ),
      ),
    );
  }
}

class Quote {
  final int id;
  final String text;
  Quote({required this.id, required this.text});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Quote> _quotes = [
    Quote(id: 1, text: "오늘 하루도 정말 고생 많았어요. 당신은 충분히 잘하고 있습니다."),
    Quote(id: 2, text: "잠시 숨을 크게 들이마셔 보세요. 평온함이 당신과 함께할 거예요."),
    Quote(id: 3, text: "당신은 생각보다 훨씬 더 강하고 아름다운 사람입니다."),
    Quote(id: 4, text: "작은 발걸음들이 모여 커다란 변화를 만들어낼 거예요. 조급해하지 마세요."),
    Quote(id: 5, text: "어제의 실수보다는 오늘의 가능성에 집중해보는 건 어떨까요?"),
    Quote(id: 6, text: "당신은 존재 자체만으로도 소중하고 가치 있는 사람입니다."),
    Quote(id: 7, text: "지치고 힘들 때는 잠시 쉬어가도 괜찮아요. 그것도 용기입니다."),
    Quote(id: 8, text: "당신의 노력은 결코 헛되지 않아요. 언젠가 밝게 빛날 거예요."),
    Quote(id: 9, text: "오늘 하루, 스스로에게 '고마워'라고 한마디 건네주세요."),
    Quote(id: 10, text: "세상의 속도에 맞추려 애쓰지 마세요. 당신만의 속도가 가장 소중합니다."),
  ];

  late Quote _currentQuote;

  @override
  void initState() {
    super.initState();
    _currentQuote = _quotes[Random().nextInt(_quotes.length)];
  }

  void _refreshQuote() {
    setState(() {
      _currentQuote = _quotes[Random().nextInt(_quotes.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.favorite, color: Colors.pinkAccent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text('힐링 모먼트', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 40),
            const Text('Today\'s Reflection', style: TextStyle(color: Colors.pinkAccent, letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('오늘의 한 줄 위로', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: _refreshQuote,
                  icon: const Icon(Icons.refresh, color: Colors.pinkAccent, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Opacity(
                    opacity: 0.3,
                    child: const Icon(Icons.format_quote, color: Colors.pinkAccent, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentQuote.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic, height: 1.6),
                  ),
                  const SizedBox(height: 16),
                  Opacity(
                    opacity: 0.3,
                    child: const Icon(Icons.format_quote, color: Colors.pinkAccent, size: 48),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen> with SingleTickerProviderStateMixin {
  bool _isActive = false;
  int _seconds = 0;
  Timer? _timer;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void _toggleBreathing() {
    setState(() {
      _isActive = !_isActive;
      if (_isActive) {
        _seconds = 0;
        _startTimer();
      } else {
        _timer?.cancel();
        _controller.stop();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        int cycle = _seconds % 12;
        if (cycle == 0) { _controller.forward(); } 
        else if (cycle == 8) { _controller.reverse(); }
      });
    });
    _controller.forward();
  }

  String _getPhaseText() {
    if (!_isActive) return '준비하기';
    int cycle = _seconds % 12;
    if (cycle < 4) return '숨 들이마시기';
    if (cycle < 8) return '잠시 멈추기';
    return '숨 내뱉기';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('마이 콰이어트 타임', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('단 1분이라도 온전히 나에게 집중해보세요.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 60),
          ScaleTransition(
            scale: _animation,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isActive && (_seconds % 12 < 4) ? Colors.pinkAccent : Colors.pinkAccent.withOpacity(0.3),
                  width: 4,
                ),
                color: Colors.white.withOpacity(0.05),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.air, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(_getPhaseText(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  if (_isActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _toggleBreathing,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(_isActive ? Icons.pause : Icons.play_arrow, size: 32),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  _timer?.cancel();
                  _controller.reset();
                  setState(() { _isActive = false; _seconds = 0; });
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                  child: const Icon(Icons.refresh, size: 32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Soundscape {
  final String id;
  final String name;
  final IconData icon;
  final String url;
  final Color color;

  Soundscape({required this.id, required this.name, required this.icon, required this.url, required this.color});
}

class SoundScreen extends StatefulWidget {
  const SoundScreen({super.key});

  @override
  State<SoundScreen> createState() => _SoundScreenState();
}

class _SoundScreenState extends State<SoundScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingId;

  final List<Soundscape> _sounds = [
    Soundscape(id: 'rain', name: '비 오는 날의 도서관', icon: Icons.umbrella, url: 'https://cdn.pixabay.com/audio/2022/07/04/audio_2463276710.mp3', color: Colors.blue),
    Soundscape(id: 'fire', name: '모닥불 타오르는 밤', icon: Icons.local_fire_department, url: 'https://cdn.pixabay.com/audio/2021/09/06/audio_173872019b.mp3', color: Colors.orange),
    Soundscape(id: 'waves', name: '제주도 바다 파도', icon: Icons.waves, url: 'https://cdn.pixabay.com/audio/2022/02/07/audio_6e53745425.mp3', color: Colors.cyan),
    Soundscape(id: 'cafe', name: '조용한 오후의 카페', icon: Icons.coffee, url: 'https://cdn.pixabay.com/audio/2022/03/23/audio_07b2a04be3.mp3', color: Colors.brown),
    Soundscape(id: 'forest', name: '바람 부는 숲 속', icon: Icons.forest, url: 'https://cdn.pixabay.com/audio/2021/09/06/audio_9c05c0a27d.mp3', color: Colors.green),
  ];

  Future<void> _toggleSound(Soundscape sound) async {
    if (_playingId == sound.id) {
      await _audioPlayer.stop();
      setState(() { _playingId = null; });
    } else {
      try {
        await _audioPlayer.setUrl(sound.url);
        await _audioPlayer.setLoopMode(LoopMode.one);
        _audioPlayer.play();
        setState(() { _playingId = sound.id; });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('사운드를 불러올 수 없습니다.')));
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('힐링 사운드', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('마음을 편안하게 해주는 소리를 골라보세요.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: _sounds.length,
                itemBuilder: (context, index) {
                  final sound = _sounds[index];
                  final isPlaying = _playingId == sound.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: GestureDetector(
                      onTap: () => _toggleSound(sound),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isPlaying ? sound.color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: isPlaying ? sound.color.withOpacity(0.5) : Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: sound.color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                              child: Icon(sound.icon, color: sound.color),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: Text(sound.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500))),
                            Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: isPlaying ? sound.color : Colors.grey, size: 32),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final String? entriesJson = prefs.getString('journal_entries');
    if (entriesJson != null) {
      setState(() {
        _entries = List<Map<String, String>>.from(
          json.decode(entriesJson).map((item) => Map<String, String>.from(item)),
        );
      });
    }
  }

  Future<void> _saveEntry() async {
    if (_controller.text.trim().isEmpty) return;

    final newEntry = {
      'content': _controller.text.trim(),
      'date': DateFormat('yyyy.MM.dd HH:mm').format(DateTime.now()),
    };

    setState(() {
      _entries.insert(0, newEntry);
      _controller.clear();
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('journal_entries', json.encode(_entries));
    
    if (mounted) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기록이 저장되었습니다.')),
      );
    }
  }

  Future<void> _deleteEntry(int index) async {
    setState(() {
      _entries.removeAt(index);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('journal_entries', json.encode(_entries));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('기록 저널', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('오늘 하루 당신의 마음은 어땠나요?', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: '여기에 마음을 남겨보세요...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.white24),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: _saveEntry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('저장하기'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('이전 기록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            Expanded(
              child: _entries.isEmpty 
                ? const Center(child: Text('아직 남겨진 기록이 없습니다.', style: TextStyle(color: Colors.white24)))
                : ListView.builder(
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry['date']!, style: const TextStyle(color: Colors.pinkAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                GestureDetector(
                                  onTap: () => _deleteEntry(index),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white24),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(entry['content']!, style: const TextStyle(color: Colors.white70, height: 1.5)),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
