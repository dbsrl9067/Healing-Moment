import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
          seedColor: const Color(0xFFF472B6),
          brightness: Brightness.dark,
          surface: const Color(0xFF1A1512),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const MainNavigationScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

// --- Common UI Components ---
Widget _buildTopBar(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: const Icon(Icons.favorite_border, color: Color(0xFFF472B6), size: 24),
        ),
        const SizedBox(width: 12),
        const Text(
          '힐링 모먼트',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const Spacer(),
        _buildIconButton(Icons.logout, () => FirebaseAuth.instance.signOut()),
        const SizedBox(width: 8),
        _buildIconButton(Icons.settings_outlined, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
        }),
      ],
    ),
  );
}

Widget _buildIconButton(IconData icon, VoidCallback onTap) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
    ),
    child: IconButton(
      icon: Icon(icon, color: Colors.white.withOpacity(0.7), size: 22),
      onPressed: onTap,
    ),
  );
}

// --- Login Screen ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  Future<void> _submit() async {
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: _emailController.text.trim(), password: _passwordController.text.trim());
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _emailController.text.trim(), password: _passwordController.text.trim());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('인증 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.favorite, color: Color(0xFFF472B6), size: 64),
            const SizedBox(height: 24),
            Text(_isLogin ? '반가워요!' : '환영합니다!', textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: '이메일')),
            const SizedBox(height: 16),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: '비밀번호'), obscureText: true),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF472B6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(_isLogin ? '로그인' : '회원가입'),
            ),
            TextButton(onPressed: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? '계정이 없으신가요? 회원가입' : '이미 계정이 있으신가요? 로그인')),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signInAnonymously();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('익명 로그인 실패: $e')));
                }
              },
              child: const Text('익명으로 시작하기', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Main Navigation ---
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [const HomeScreen(), const BreathingScreen(), const SoundScreen(), const JournalScreen()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFF0A0502),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFFF472B6),
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_outlined)), activeIcon: Icon(Icons.home), label: '홈'),
            BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.air)), label: '호흡'),
            BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.music_note_outlined)), activeIcon: Icon(Icons.music_note), label: '사운드'),
            BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.favorite_border)), activeIcon: Icon(Icons.favorite), label: '기록'),
          ],
        ),
      ),
    );
  }
}

// --- Settings Screen ---
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('설정'), backgroundColor: Colors.transparent),
      body: ListView(
        children: [
          ListTile(leading: const Icon(Icons.person_outline), title: Text(user?.isAnonymous ?? true ? '익명 사용자' : user?.email ?? '이메일 없음'), subtitle: const Text('현재 로그인 계정')),
          const Divider(color: Colors.white10),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('로그아웃', style: TextStyle(color: Colors.redAccent)),
            onTap: () { FirebaseAuth.instance.signOut(); Navigator.pop(context); },
          ),
        ],
      ),
    );
  }
}

// --- Home Screen ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _quotes = ["당신은 누구보다 자신을 사랑할 자격이 있는 사람입니다.", "오늘 하루도 정말 고생 많았어요.", "잠시 숨을 크게 들이마셔 보세요.", "당신은 생각보다 훨씬 더 강합니다."];
  late String _currentQuote;
  @override
  void initState() { super.initState(); _currentQuote = _quotes[Random().nextInt(_quotes.length)]; }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.email?.split('@')[0] ?? "사용자";

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTopBar(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // User Support Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: const Color(0xFF1A1512), borderRadius: BorderRadius.circular(24)),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFFF472B6).withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.person_outline, color: Color(0xFFF472B6), size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Text('$displayName님을 위한 응원', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                          const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    const Text('TODAY\'S REFLECTION', style: TextStyle(color: Colors.cyan, letterSpacing: 2, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('오늘의 한 줄 위로', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 32),
                    // Quote Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1512),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        children: [
                          Align(alignment: Alignment.centerLeft, child: Text('“', style: TextStyle(fontSize: 60, color: const Color(0xFFF472B6).withOpacity(0.3), height: 0.5))),
                          const SizedBox(height: 10),
                          Text(_currentQuote, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, height: 1.6, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 10),
                          Align(alignment: Alignment.centerRight, child: Text('”', style: TextStyle(fontSize: 60, color: const Color(0xFFF472B6).withOpacity(0.3), height: 0.5))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _buildSmallInfoCard(Icons.notifications_none, '알림 시간', '오전 9:00'),
                        const SizedBox(width: 16),
                        _buildSmallInfoCard(Icons.format_quote, '등록된 문구', '0개'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallInfoCard(IconData icon, String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFF1A1512), borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF472B6).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFFF472B6), size: 18)),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// --- Breathing Screen ---
class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});
  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen> with SingleTickerProviderStateMixin {
  bool _isActive = false;
  double _volume = 0.5;
  int _seconds = 0;
  Timer? _timer;
  late AnimationController _controller;
  late Animation<double> _animation;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _animation = Tween<double>(begin: 1.0, end: 1.25).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void _toggle() async {
    setState(() {
      _isActive = !_isActive;
      if (_isActive) {
        _seconds = 0;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() { _seconds++; if (_seconds % 12 == 0) _controller.forward(); else if (_seconds % 12 == 8) _controller.reverse(); });
        });
        _audioPlayer.setUrl('https://cdn.pixabay.com/audio/2022/05/27/audio_1808fbf07a.mp3').then((_) {
          _audioPlayer.setVolume(_volume); _audioPlayer.setLoopMode(LoopMode.one); _audioPlayer.play();
        });
        _controller.forward();
      } else { _timer?.cancel(); _controller.stop(); _audioPlayer.stop(); }
    });
  }

  @override
  void dispose() { _timer?.cancel(); _controller.dispose(); _audioPlayer.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              _buildTopBar(context),
              const SizedBox(height: 48),
              const Text('마이 콰이어트 타임', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('단 1분이라도 온전히 나에게 집중해보세요.', style: TextStyle(color: Colors.white.withOpacity(0.5))),
              const Spacer(),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(width: 260, height: 260, child: CircularProgressIndicator(value: _isActive ? (_seconds % 12) / 12 : 0, strokeWidth: 2, color: const Color(0xFFF472B6).withOpacity(0.3), backgroundColor: Colors.white.withOpacity(0.05))),
                  ScaleTransition(
                    scale: _animation,
                    child: Container(
                      width: 220, height: 220,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFF472B6), width: 1.5), color: Colors.white.withOpacity(0.02)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.air, color: Colors.white.withOpacity(0.3), size: 36),
                        const SizedBox(height: 16),
                        Text(!_isActive ? '준비하기' : (_seconds % 12 < 4 ? '숨 들이마시기' : _seconds % 12 < 8 ? '잠시 멈추기' : '숨 내뱉기'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                        if (_isActive) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                          ),
                        ]
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCircleBtn(_isActive ? Icons.pause : Icons.play_arrow, _toggle),
                  const SizedBox(width: 24),
                  _buildCircleBtn(Icons.refresh, () { _timer?.cancel(); _controller.reset(); _audioPlayer.stop(); setState(() { _isActive = false; _seconds = 0; }); }),
                ],
              ),
              const Spacer(),
              _buildVolumeCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(width: 68, height: 64, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 30)));
  }

  Widget _buildVolumeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF1A1512), borderRadius: BorderRadius.circular(32)),
      child: Column(children: [
        Row(children: [const Icon(Icons.volume_up_outlined, color: Colors.grey, size: 20), const SizedBox(width: 12), const Text('볼륨 조절', style: TextStyle(color: Colors.white, fontSize: 14)), const Spacer(), Text('${(_volume * 100).toInt()}%', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12))]),
        Slider(value: _volume, activeColor: const Color(0xFFF472B6), inactiveColor: Colors.white.withOpacity(0.05), onChanged: (v) { setState(() { _volume = v; _audioPlayer.setVolume(_volume); }); }),
      ]),
    );
  }
}

// --- Sound Screen ---
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
      if (_playingUrl == url) { await _player.stop(); setState(() => _playingUrl = null); return; }
      String playUrl = url;
      if (url.startsWith('gs://')) playUrl = await FirebaseStorage.instance.refFromURL(url).getDownloadURL();
      await _player.setUrl(playUrl); _player.setVolume(_volume); _player.play();
      setState(() => _playingUrl = url);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('재생 에러: $e'))); }
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
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
                      return _buildSoundCard(data['name'] ?? '사운드', isPlaying, () => _play(url), data['iconName']);
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

  Widget _buildSoundCard(String title, bool isPlaying, VoidCallback onTap, String? iconName) {
    IconData getIcon() {
      switch(iconName) {
        case 'flame': return Icons.local_fire_department;
        case 'rain': return Icons.umbrella;
        case 'waves': return Icons.waves;
        default: return Icons.music_note;
      }
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1512),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isPlaying ? const Color(0xFFF472B6).withOpacity(0.5) : Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(getIcon(), color: isPlaying ? const Color(0xFFF472B6) : Colors.white.withOpacity(0.7), size: 28),
          const SizedBox(width: 20),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('"$title"', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('AMBIENT SOUNDSCAPE', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, letterSpacing: 1.2)),
            ]),
          ),
          GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle), child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 20))),
        ],
      ),
    );
  }

  Widget _buildVolumeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF1A1512), borderRadius: BorderRadius.circular(32)),
      child: Column(children: [
        Row(children: [const Icon(Icons.volume_up_outlined, color: Colors.grey, size: 20), const SizedBox(width: 12), const Text('볼륨 조절', style: TextStyle(color: Colors.white, fontSize: 14)), const Spacer(), Text('${(_volume * 100).toInt()}%', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12))]),
        Slider(value: _volume, activeColor: const Color(0xFFF472B6), inactiveColor: Colors.white.withOpacity(0.05), onChanged: (v) { setState(() { _volume = v; _player.setVolume(_volume); }); }),
      ]),
    );
  }
}

// --- Journal Screen ---
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _controller = TextEditingController();
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isSending = false;
  bool _isPublic = false;

  Future<String> _generateAIResponse(String content) async {
    await Future.delayed(const Duration(seconds: 2));
    return "짧은 한마디 속에 담긴 오늘의 무게가 제 마음에도 깊게 전해져 옵니다. 얼마나 고단하고 벅찬 하루였을지 다 헤아릴 순 없지만, 그 힘듦을 묵묵히 견뎌낸 당신의 시간을 진심으로 안아드리고 싶어요. 오늘은 다른 걱정은 잠시 내려두고, 고생한 당신의 마음이 편안한 쉼을 얻을 수 있도록 따뜻한 숨을 고르는 밤이 되시길 바랍니다.\n\n***\n**[마음을 다독이는 시]**\n\"흔들리지 않고 피는 꽃이 어디 있으랴 이 세상 그 어떤 아름다운 꽃들도 다 흔들리면서 피었나니\" - 도종환, 〈흔들리며 피는 꽃〉 중에서";
  }

  Future<void> _add() async {
    if (_controller.text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    final content = _controller.text;
    final aiReply = await _generateAIResponse(content);
    await FirebaseFirestore.instance.collection('journals').add({
      'content': content,
      'aiReply': aiReply,
      'userId': _uid,
      'isPublic': _isPublic,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _controller.clear();
    setState(() { _isSending = false; _isPublic = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            const SizedBox(height: 20),
            const Text('감정 기록 & 한 줄 확인', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('그날의 ‘결정적 힐링 순간’을 기록해보세요.', style: TextStyle(color: Colors.white.withOpacity(0.5))),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: const Color(0xFF1A1512), borderRadius: BorderRadius.circular(32)),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      maxLines: 3,
                      decoration: InputDecoration(hintText: '오늘 나를 웃게 했던 짧은 순간이나\n지금의 감정을 기록해보세요...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 15), border: InputBorder.none),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _isPublic = !_isPublic),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
                            child: Row(children: [Icon(Icons.public, size: 14, color: _isPublic ? const Color(0xFFF472B6) : Colors.grey), const SizedBox(width: 6), Text('공개 기록', style: TextStyle(fontSize: 12, color: _isPublic ? Colors.white : Colors.grey))]),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFF472B6)),
                        const SizedBox(width: 6),
                        Text('AI가 따뜻한 공감 답장을 준비합니다', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _add,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A2522), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.send_outlined, size: 18), SizedBox(width: 10), Text('기록하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0), child: Row(children: [const Icon(Icons.calendar_today_outlined, color: Color(0xFFF472B6), size: 18), const SizedBox(width: 10), const Text('나의 힐링 조각들', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))])),
            const Expanded(
              child: Center(
                child: Text('아직 기록된 순간이 없네요.', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
