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
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0A0502),
        selectedItemColor: const Color(0xFFF472B6),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.air), label: '호흡'),
          BottomNavigationBarItem(icon: Icon(Icons.music_note), label: '사운드'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: '기록'),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          ListTile(leading: const Icon(Icons.person_outline), title: Text(user?.isAnonymous ?? true ? '익명 사용자' : user?.email ?? '이메일 없음'), subtitle: const Text('현재 로그인 계정')),
          const Divider(),
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _quotes = ["오늘 하루도 정말 고생 많았어요.", "잠시 숨을 크게 들이마셔 보세요.", "당신은 생각보다 훨씬 더 강합니다.", "작은 발걸음이 큰 변화를 만듭니다.", "당신은 존재 자체로 소중합니다."];
  late String _currentQuote;
  @override
  void initState() { super.initState(); _currentQuote = _quotes[Random().nextInt(_quotes.length)]; }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('힐링 모먼트', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())), icon: const Icon(Icons.settings_outlined, color: Colors.grey)),
            ]),
            const SizedBox(height: 60),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(32)),
              child: Text(_currentQuote, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic)),
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _audioUrl = 'https://cdn.pixabay.com/audio/2022/05/27/audio_1808fbf07a.mp3';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('breathing_audio').get();
      if (doc.exists) {
        String url = doc.data()?['url'] ?? _audioUrl;
        if (url.startsWith('gs://')) url = await FirebaseStorage.instance.refFromURL(url).getDownloadURL();
        if (mounted) setState(() => _audioUrl = url);
      }
    } catch (e) { debugPrint("설정 로드 에러: $e"); }
  }

  void _toggle() async {
    setState(() {
      _isActive = !_isActive;
      if (_isActive) {
        _seconds = 0;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() { _seconds++; if (_seconds % 12 == 0) _controller.forward(); else if (_seconds % 12 == 8) _controller.reverse(); });
        });
        _audioPlayer.setUrl(_audioUrl).then((_) { _audioPlayer.setLoopMode(LoopMode.one); _audioPlayer.play(); });
        _controller.forward();
      } else { _timer?.cancel(); _controller.stop(); _audioPlayer.stop(); }
    });
  }

  @override
  void dispose() { _timer?.cancel(); _controller.dispose(); _audioPlayer.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        ScaleTransition(
          scale: _animation,
          child: Container(
            width: 200, height: 200,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFF472B6), width: 4)),
            child: Center(child: Text(_isActive ? (_seconds % 12 < 4 ? '흡' : _seconds % 12 < 8 ? '정' : '호') : '시작')),
          ),
        ),
        const SizedBox(height: 40),
        IconButton(onPressed: _toggle, icon: Icon(_isActive ? Icons.pause : Icons.play_arrow, size: 48)),
      ]),
    );
  }
}

class SoundScreen extends StatefulWidget {
  const SoundScreen({super.key});
  @override
  State<SoundScreen> createState() => _SoundScreenState();
}

class _SoundScreenState extends State<SoundScreen> {
  final AudioPlayer _player = AudioPlayer();
  String? _playingUrl;

  Future<void> _play(String url) async {
    try {
      if (_playingUrl == url) { await _player.stop(); setState(() => _playingUrl = null); return; }
      String playUrl = url;
      if (url.startsWith('gs://')) playUrl = await FirebaseStorage.instance.refFromURL(url).getDownloadURL();
      await _player.setUrl(playUrl); _player.play();
      setState(() => _playingUrl = url);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('재생 에러: $e'))); }
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('soundscapes').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final url = data['url'] ?? '';
              final isPlaying = _playingUrl == url;
              return ListTile(
                leading: Icon(Icons.music_note, color: isPlaying ? Colors.white : const Color(0xFFF472B6)),
                title: Text(data['name'] ?? '사운드'),
                trailing: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                onTap: () => _play(url),
              );
            },
          );
        },
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
  final _controller = TextEditingController();
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isSending = false;
  bool _isPublic = false; // 공개 여부 선택 상태

  Future<String> _generateAIResponse(String content) async {
    await Future.delayed(const Duration(seconds: 2));
    if (content.contains('힘들어') || content.contains('지쳐') || content.length < 5) {
      return "짧은 한마디 속에 담긴 오늘의 무게가 제 마음에도 깊게 전해져 옵니다. 얼마나 고단하고 벅찬 하루였을지 다 헤아릴 순 없지만, 그 힘듦을 묵묵히 견뎌낸 당신의 시간을 진심으로 안아드리고 싶어요. 오늘은 다른 걱정은 잠시 내려두고, 고생한 당신의 마음이 편안한 쉼을 얻을 수 있도록 따뜻한 숨을 고르는 밤이 되시길 바랍니다.\n\n***\n**[마음을 다독이는 시]**\n\"흔들리지 않고 피는 꽃이 어디 있으랴 이 세상 그 어떤 아름다운 꽃들도 다 흔들리면서 피었나니\" - 도종환, 〈흔들리며 피는 꽃〉 중에서";
    } else {
      return "오늘 하루도 정말 고생 많으셨어요. 당신의 진솔한 마음을 이곳에 남겨주셔서 고마워요. 편안한 밤 되시길 바랍니다.";
    }
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
      'isPublic': _isPublic, // 공개 여부 저장
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    _controller.clear();
    setState(() { _isSending = false; _isPublic = false; });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(children: [
          TextField(
            controller: _controller, 
            decoration: InputDecoration(
              hintText: '오늘의 마음을 남겨보세요...', 
              suffixIcon: _isSending ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))) : IconButton(onPressed: _add, icon: const Icon(Icons.send))
            )
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                const Text("나만 보기", style: TextStyle(fontSize: 12, color: Colors.grey)),
                Switch(
                  value: _isPublic, 
                  onChanged: (v) => setState(() => _isPublic = v),
                  activeColor: const Color(0xFFF472B6),
                ),
                const Text("전체 공개", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // 내가 쓴 글이거나, 전체 공개된 글만 가져옴
              stream: FirebaseFirestore.instance.collection('journals').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final userId = data['userId'] ?? '';
                  final isPublic = data['isPublic'] ?? false;
                  return userId == _uid || isPublic == true;
                }).toList();

                return ListView(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final isMyPost = data['userId'] == _uid;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      color: isMyPost ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.03),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: isMyPost ? const BorderSide(color: Color(0xFFF472B6), width: 0.5) : BorderSide.none),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(isMyPost ? "나의 기록" : "누군가의 마음", style: TextStyle(fontSize: 12, color: isMyPost ? const Color(0xFFF472B6) : Colors.grey, fontWeight: FontWeight.bold)),
                                if (isMyPost) Icon(data['isPublic'] == true ? Icons.public : Icons.lock_outline, size: 14, color: Colors.grey),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(data['content'] ?? '', style: const TextStyle(fontSize: 16)),
                            if (data['aiReply'] != null) ...[
                              const Divider(height: 32, color: Colors.white10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.auto_awesome, size: 18, color: Color(0xFFF472B6)),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(data['aiReply'], style: const TextStyle(color: Color(0xFFE5E7EB), height: 1.6, fontSize: 14))),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
