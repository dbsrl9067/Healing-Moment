import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../widgets/common_ui.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _quotes = [
    "당신은 누구보다 자신을 사랑할 자격이 있는 사람입니다.", 
    "오늘 하루도 정말 고생 많았어요.", 
    "잠시 숨을 크게 들이마셔 보세요.", 
    "당신은 생각보다 훨씬 더 강합니다."
  ];
  late String _currentQuote;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() { 
    super.initState(); 
    _currentQuote = _quotes[Random().nextInt(_quotes.length)]; 
    
    // Schedule initial notification
    NotificationService.scheduleDailyNotification(_notificationTime.hour, _notificationTime.minute);
    
    // Update Home Screen Widget
    WidgetService.updateWidget(quote: _currentQuote);
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
      NotificationService.scheduleDailyNotification(picked.hour, picked.minute);
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
              buildTopBar(context, onSettingsTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
              }),
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
