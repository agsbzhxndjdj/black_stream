// tools/setup.dart
import 'dart:io';

void main() async {
  print(' بدء إعداد مشروع Black Stream...\n');

  try {
    // 1. إنشاء المجلدات المفقودة
    print(' إنشاء مجلدات Assets...');
    await _createDir('assets/images');
    await _createDir('assets/icons');
    await _createDir('assets/fonts');
    await _createDir('android/app/src/main/res/xml');

    // 2. إنشاء ملف network_security_config.xml
    print('🔒 إنشاء network_security_config.xml...');
    await _writeFile(
      'android/app/src/main/res/xml/network_security_config.xml',
      _networkSecurityConfig,
    );

    // 3. تحديث AndroidManifest.xml
    print('️ تحديث AndroidManifest.xml...');
    await _writeFile(
      'android/app/src/main/AndroidManifest.xml',
      _manifestContent,
    );

    // 4. تحديث build.gradle
    print('🔧 تحديث build.gradle...');
    await _updateBuildGradle();

    // 5. تحديث pubspec.yaml
    print('⚙️ تحديث pubspec.yaml...');
    await _writeFile('pubspec.yaml', _pubspecContent);

    // 6. تنظيف وجلب الحزم
    print('🧹 تنظيف المشروع وجلب الحزم...');
    await Process.run('flutter', ['clean']);
    await Process.run('flutter', ['pub', 'get']);

    print('\n✅ تم الإعداد بنجاح!');
    print('💡 الآن يمكنك تشغيل: flutter run');
  } catch (e) {
    print('\n❌ خطأ: $e');
  }
}

Future<void> _createDir(String path) async {
  final dir = Directory(path);
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }
}

Future<void> _writeFile(String path, String content) async {
  final file = File(path);
  await file.create(recursive: true);
  await file.writeAsString(content);
}

Future<void> _updateBuildGradle() async {
  final file = File('android/app/build.gradle');
  if (file.existsSync()) {
    var content = await file.readAsString();
    content = content.replaceAll(
      RegExp(r'minSdkVersion\s+\d+'), 
      'minSdkVersion 21',
    );
    content = content.replaceAll(
      RegExp(r'applicationId\s+"[^"]+"'), 
      'applicationId "com.blackstream.app"',
    );
    content = content.replaceAll(
      RegExp(r'targetSdkVersion\s+\d+'), 
      'targetSdkVersion 34',
    );
    await file.writeAsString(content);
  }
}

const String _pubspecContent = '''
name: black_stream
description: تطبيق Black Stream لمشاهدة الأفلام والمسلسلات بدون إعلانات.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  dio: ^5.4.0
  html: ^0.15.4
  flutter_inappwebview: ^6.0.0
  video_player: ^2.8.1
  chewie: ^1.7.4
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.1
  cached_network_image: ^3.3.0
  flutter_staggered_grid_view: ^0.7.0
  shimmer: ^3.0.0
  google_fonts: ^6.1.0
  connectivity_plus: ^6.0.1
  url_launcher: ^6.2.2
  permission_handler: ^11.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
''';

const String _manifestContent = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application
        android:label="Black Stream"
        android:name="\${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true"
        android:networkSecurityConfig="@xml/network_security_config">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
''';

const String _networkSecurityConfig = '''
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
</network-security-config>
''';
