import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('설정'), backgroundColor: Colors.transparent),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline), 
            title: Text(user?.isAnonymous ?? true ? '익명 사용자' : user?.email ?? '이메일 없음'), 
            subtitle: const Text('현재 로그인 계정')
          ),
          const Divider(color: Colors.white10),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('로그아웃', style: TextStyle(color: Colors.redAccent)),
            onTap: () { 
              FirebaseAuth.instance.signOut(); 
              Navigator.pop(context); 
            },
          ),
        ],
      ),
    );
  }
}
