import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

class WidgetService {
  // 앱과 위젯이 공유할 ID (iOS App Groups 설정 시 사용됨)
  static const String _groupId = 'group.com.example.healingmoments';
  
  // 위젯 데이터에 접근할 키값 (네이티브 코드와 일치해야 함)
  static const String _quoteKey = 'healing_quote';
  static const String _authorKey = 'healing_author';

  static Future<void> updateWidget({required String quote, String author = '힐링 모먼트'}) async {
    try {
      // 1. 데이터 저장 (Flutter -> Shared Storage)
      await HomeWidget.saveWidgetData<String>(_quoteKey, quote);
      await HomeWidget.saveWidgetData<String>(_authorKey, author);
      
      // 2. 위젯 화면 갱신 요청 (Shared Storage -> Native Widget)
      // androidName과 iOSName은 각 플랫폼별 프로젝트에서 설정할 위젯 클래스명과 일치해야 합니다.
      await HomeWidget.updateWidget(
        androidName: 'HealingWidgetProvider',
        iOSName: 'HealingWidget',
      );
    } on PlatformException catch (e) {
      print('Widget Update Error: ${e.message}');
    }
  }
}
