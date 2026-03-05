
# 📱 플랫폼별 필수 설정 가이드

Flutter 소스 코드를 프로젝트에 적용한 후, 각 OS의 보안 정책에 따라 아래 설정을 반드시 수동으로 진행해야 알림 기능이 작동합니다.

## 1. Android (안드로이드)
`android/app/src/main/AndroidManifest.xml` 파일의 `<manifest>` 태그 안에 다음 권한들을 추가하세요.

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

## 2. iOS (아이폰)
`ios/Runner/Info.plist` 파일의 `<dict>` 태그 안에 다음 설정을 추가하세요.

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
<key>NSUserNotificationsUsageDescription</key>
<string>매일 따뜻한 응원 문구를 보내드리기 위해 알림 권한이 필요합니다.</string>
```

`ios/Runner/AppDelegate.swift` 파일에서 알림 플러그인을 초기화하는 코드가 필요할 수 있습니다.

## 3. 아이콘 설정
- 기본 아이콘(`@mipmap/ic_launcher`)은 Flutter 프로젝트 생성 시 기본 제공되는 것을 사용합니다.
- 나만의 아이콘을 쓰려면 `assets/` 폴더에 이미지를 넣고 `flutter_launcher_icons` 패키지를 사용해 교체하는 것을 추천합니다.
