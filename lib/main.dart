import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'firebase_options.dart';

bool isFirebaseInitialized = false;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Timezone
  tz.initializeTimeZones();
  try {
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  } catch (e) {
    debugPrint("Timezone initialization failed: $e");
    // Fallback to UTC if it fails
    tz.setLocalLocation(tz.getLocation('UTC'));
  }
  
  // Initialize Notifications
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseInitialized = true;
  } catch (e) {
    debugPrint("Firebase 초기화 실패: $e");
  }
  runApp(const HealingMomentsApp());
}

class NotificationManager {
  static Future<void> scheduleDailyNotification(int hour, int minute) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'daily_healing_id',
      'Daily Healing Notification',
      channelDescription: 'Daily quote notification for healing',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final List<String> quotes = [
      "당신은 누구보다 자신을 사랑할 자격이 있는 사람입니다.",
      "오늘 하루도 정말 고생 많았어요. 당신은 충분히 잘하고 있습니다.",
      "잠시 숨을 크게 들이마셔 보세요. 평온함이 당신과 함께할 거예요.",
      "당신은 생각보다 훨씬 더 강하고 아름다운 사람입니다.",
      "작은 발걸음들이 모여 커다란 변화를 만들어낼 거예요."
    ];
    final randomQuote = quotes[Random().nextInt(quotes.length)];

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      '오늘의 힐링 한 마디',
      randomQuote,
      _nextInstanceOfTime(hour, minute),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    debugPrint("Notification scheduled for $hour:$minute");
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
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
      home: isFirebaseInitialized ? const AuthWrapper() : const FirebaseErrorScreen(),
    );
  }
}

class FirebaseErrorScreen extends StatelessWidget {
  const FirebaseErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
              const SizedBox(height: 24),
              const Text(
                'Firebase 초기화 오류',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Firebase가 정상적으로 초기화되지 않았습니다. iOS 환경이라면 `lib/firebase_options.dart` 파일에 올바른 iOS App ID를 입력했는지 확인해 주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => main(), // Retry
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    if (!isFirebaseInitialized) {
      return const FirebaseErrorScreen();
    }
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
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() { 
    super.initState(); 
    _currentQuote = _quotes[Random().nextInt(_quotes.length)]; 
    // Schedule initial notification
    NotificationManager.scheduleDailyNotification(_notificationTime.hour, _notificationTime.minute);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFF472B6),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1512),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _notificationTime) {
      setState(() {
        _notificationTime = picked;
      });
      NotificationManager.scheduleDailyNotification(picked.hour, picked.minute);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('알림이 매일 ${picked.format(context)}에 울리도록 설정되었습니다.')),
      );
    }
  }

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
                        _buildSmallInfoCard(
                          Icons.notifications_active_outlined, 
                          '알림 시간', 
                          _notificationTime.format(context),
                          onTap: _selectTime,
                        ),
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

  Widget _buildSmallInfoCard(IconData icon, String title, String value, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
              Row(
                children: [
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (onTap != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
                  ]
                ],
              ),
            ],
          ),
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
        // Simple mapping for default tailwind-like classes if they exist in Firestore
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
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isSending = false;
  bool _isPublic = false;

  Future<String> _generateAIResponse(String content) async {
    try {
      // 신규 발급된 Gemini API 키와 확인된 최신 모델명(2.5)을 사용합니다.
      const apiKey = 'AIzaSyD27YqVil7gVOlaTwOe1h07Vk6cNzKxq94'; 
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      
      final prompt = [Content.text(
        "당신은 사용자의 마음을 깊이 읽고 문학적 감성으로 답하는 공감 상담가입니다. "
        "사용자의 기록: \"$content\"\n\n"
        "다음 지침을 반드시 따르세요:\n"
        "1. 사용자의 글에서 느껴지는 핵심 감정(예: 소소한 기쁨, 깊은 감사, 지친 하루, 상실감 등)을 정확히 포착하세요.\n"
        "2. 그 감정에 대해 진심 어린 공감을 담은 답장을 3문장 내외로 작성하세요. 사용자가 언급한 구체적인 단어를 활용해 답하세요.\n"
        "3. **가장 중요**: 이 구체적인 상황과 감정에 '완벽하게 어울리는' 시(Poem)의 한 구절이나 명언을 매번 새롭게 선정하여 포함하세요. (항상 똑같은 시를 쓰지 마세요)\n"
        "4. 인용구 끝에는 반드시 저자 또는 출처를 명시하세요.\n"
        "5. 전체적인 톤은 아주 다정하고 품격 있는 한국어로 유지하세요.\n"
        "6. 시 구절은 '[마음을 다독이는 한 구절]' 이라는 머리말을 붙여 구분해주세요."
      )];
      
      final response = await model.generateContent(prompt);
      final replyText = response.text;
      
      if (replyText == null || replyText.isEmpty) {
        throw Exception("AI 응답이 비어있습니다.");
      }
      return replyText;
    } catch (e) {
      debugPrint("AI 응답 생성 실패: $e");
      // Fallback: Even in fallback, try to be generic but warm
      return "당신의 소중한 마음이 담긴 기록을 잘 읽었습니다. "
          "지금 느끼시는 그 감정은 무엇보다 소중하며, 당신의 삶을 지탱하는 큰 힘이 될 것입니다. "
          "오늘은 잠시 모든 짐을 내려놓고 평온한 쉼을 누리시길 바랍니다.\n\n"
          "[마음을 다독이는 한 구절]\n"
          "\"자세히 보아야 예쁘다. 오래 보아야 사랑스럽다. 너도 그렇다.\" - 나태주, 〈풀꽃〉 중에서";
    }
  }

  Future<void> _add() async {
    if (_controller.text.isEmpty || _isSending || _user == null) return;
    setState(() => _isSending = true);
    final content = _controller.text;
    final aiReply = await _generateAIResponse(content);
    
    try {
      await FirebaseFirestore.instance.collection('journals').add({
        'content': content,
        'aiReply': aiReply,
        'userId': _user!.uid,
        'isPublic': _isPublic,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _controller.clear();
      if (mounted) {
        setState(() { 
          _isSending = false; 
          _isPublic = false; 
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canMakePublic = _user != null && !_user!.isAnonymous;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
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
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: '오늘 나를 웃게 했던 짧은 순간이나\n지금의 감정을 기록해보세요...', 
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 15), 
                                border: InputBorder.none
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (canMakePublic)
                                  GestureDetector(
                                    onTap: () => setState(() => _isPublic = !_isPublic),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
                                      child: Row(children: [Icon(Icons.public, size: 14, color: _isPublic ? const Color(0xFFF472B6) : Colors.grey), const SizedBox(width: 6), Text('공개 기록', style: TextStyle(fontSize: 12, color: _isPublic ? Colors.white : Colors.grey))]),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(20)),
                                    child: const Text('익명은 비공개로만 기록됩니다', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ),
                                const Spacer(),
                                const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFF472B6)),
                                const SizedBox(width: 6),
                                Text('AI 공감 답장 준비', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3))),
                              ],
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isSending ? null : _add,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A2522), 
                                foregroundColor: Colors.white, 
                                minimumSize: const Size(double.infinity, 56), 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                              ),
                              child: _isSending 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.send_outlined, size: 18), SizedBox(width: 10), Text('기록하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0), child: Row(children: [const Icon(Icons.calendar_today_outlined, color: Color(0xFFF472B6), size: 18), const SizedBox(width: 10), const Text('나의 힐링 조각들', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))])),
                    const SizedBox(height: 16),
                    _buildJournalList(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalList() {
    if (_user == null) return const Center(child: Text('로그인이 필요합니다.', style: TextStyle(color: Colors.grey)));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('journals')
          .where('userId', isEqualTo: _user!.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text('아직 기록된 순간이 없네요.', style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildJournalCard(data);
          },
        );
      },
    );
  }

  Widget _buildJournalCard(Map<String, dynamic> data) {
    final DateTime? createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final String dateStr = createdAt != null ? DateFormat('yyyy.MM.dd HH:mm').format(createdAt) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1512),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(dateStr, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
              const Spacer(),
              if (data['isPublic'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF472B6).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('공개', style: TextStyle(color: Color(0xFFF472B6), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(data['content'] ?? '', style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF472B6).withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: Color(0xFFF472B6)),
                    SizedBox(width: 8),
                    Text('AI의 공감 한마디', style: TextStyle(color: Color(0xFFF472B6), fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  data['aiReply'] ?? '',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
