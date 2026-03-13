import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

Widget buildTopBar(BuildContext context, {required VoidCallback onSettingsTap}) {
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
        buildIconButton(Icons.logout, () => FirebaseAuth.instance.signOut()),
        const SizedBox(width: 8),
        buildIconButton(Icons.settings_outlined, onSettingsTap),
      ],
    ),
  );
}

Widget buildIconButton(IconData icon, VoidCallback onTap) {
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
