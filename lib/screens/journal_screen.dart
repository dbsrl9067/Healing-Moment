import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../widgets/common_ui.dart';
import 'settings_screen.dart';

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
            buildTopBar(context, onSettingsTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            }),
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
