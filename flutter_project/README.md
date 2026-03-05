# Healing Moments Flutter Wrapper

이 프로젝트는 기존의 React 웹 애플리케이션을 Flutter 앱으로 감싸서 iOS 및 Android 앱으로 출시할 수 있게 해주는 **WebView Wrapper** 프로젝트입니다.

## 🚀 시작하기

1. **Flutter 설치**: 본인의 컴퓨터에 Flutter SDK가 설치되어 있어야 합니다.
2. **프로젝트 생성**:
   ```bash
   flutter create healing_moments
   ```
3. **코드 복사**:
   - `pubspec.yaml` 내용을 이 폴더의 파일 내용으로 교체하세요.
   - `lib/main.dart` 내용을 이 폴더의 파일 내용으로 교체하세요.
4. **의존성 설치**:
   ```bash
   flutter pub get
   ```
5. **네이티브 설정**:
   - **Android**: `android/app/src/main/AndroidManifest.xml`에 인터넷 및 알림 권한을 추가하세요.
   - **iOS**: `ios/Runner/Info.plist`에 필요한 권한 설명을 추가하세요.

## 📱 주요 기능
- **WebView**: 현재 개발된 React 앱을 풀스크린으로 로드합니다.
- **Permission Handling**: 알림 권한 등을 요청합니다.
- **Loading Screen**: 앱 로딩 중 커스텀 스플래시 화면을 보여줍니다.
- **External Links**: 외부 링크는 브라우저로 열리도록 처리되어 있습니다.

## 🛠️ 빌드 및 실행
- 실행: `flutter run`
- 안드로이드 빌드: `flutter build apk` 또는 `flutter build appbundle`
- iOS 빌드: `flutter build ios` (Mac 필요)
