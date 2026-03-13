import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../widgets/common_ui.dart';
import 'settings_screen.dart';

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
          setState(() { 
            _seconds++; 
            if (_seconds % 12 == 0) _controller.forward(); 
            else if (_seconds % 12 == 8) _controller.reverse(); 
          });
        });
        _audioPlayer.setUrl('https://cdn.pixabay.com/audio/2022/05/27/audio_1808fbf07a.mp3').then((_) {
          _audioPlayer.setVolume(_volume); 
          _audioPlayer.setLoopMode(LoopMode.one); 
          _audioPlayer.play();
        });
        _controller.forward();
      } else { 
        _timer?.cancel(); 
        _controller.stop(); 
        _audioPlayer.stop(); 
      }
    });
  }

  @override
  void dispose() { 
    _timer?.cancel(); 
    _controller.dispose(); 
    _audioPlayer.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              buildTopBar(context, onSettingsTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
              }),
              const SizedBox(height: 48),
              const Text('마이 콰이어트 타임', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('단 1분이라도 온전히 나에게 집중해보세요.', style: TextStyle(color: Colors.white.withOpacity(0.5))),
              const Spacer(),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 260, height: 260, 
                    child: CircularProgressIndicator(
                      value: _isActive ? (_seconds % 12) / 12 : 0, 
                      strokeWidth: 2, 
                      color: const Color(0xFFF472B6).withOpacity(0.3), 
                      backgroundColor: Colors.white.withOpacity(0.05)
                    )
                  ),
                  ScaleTransition(
                    scale: _animation,
                    child: Container(
                      width: 220, height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, 
                        border: Border.all(color: const Color(0xFFF472B6), width: 1.5), 
                        color: Colors.white.withOpacity(0.02)
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.air, color: Colors.white.withOpacity(0.3), size: 36),
                        const SizedBox(height: 16),
                        Text(!_isActive ? '준비하기' : (_seconds % 12 < 4 ? '숨 들이마시기' : _seconds % 12 < 8 ? '잠시 멈추기' : '숨 내뱉기'), 
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)
                        ),
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
                  buildIconButton(_isActive ? Icons.pause : Icons.play_arrow, _toggle),
                  const SizedBox(width: 24),
                  buildIconButton(Icons.refresh, () { 
                    _timer?.cancel(); 
                    _controller.reset(); 
                    _audioPlayer.stop(); 
                    setState(() { _isActive = false; _seconds = 0; }); 
                  }),
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

  Widget buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap, 
      child: Container(
        width: 68, height: 64, 
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle), 
        child: Icon(icon, color: Colors.white, size: 30)
      )
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
          onChanged: (v) { setState(() { _volume = v; _audioPlayer.setVolume(_volume); }); }
        ),
      ]),
    );
  }
}
