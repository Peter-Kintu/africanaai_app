# Africana AI - Pre-Launch Verification Checklist

## Code Verification ✅

### pubspec.yaml
```
☐ flutter_inappwebview: ^6.1.5
☐ mediapipe_genai: ^0.0.1
☐ path_provider: ^2.1.5
☐ dio: ^5.4.0
```

### lib/main.dart
```
☐ Import: import 'package:africanaai/screens/africana_inapp_wrapper.dart';
☐ Home: MyApp → AfricanaInAppWrapper
☐ Title: "Africana AI"
☐ Theme: Material3 with blue color scheme
```

### lib/services/ai_service.dart
```
☐ File exists at correct path
☐ modelUrl configured with actual hosting URL (not placeholder)
☐ Download timeout set appropriately for network speed
☐ Progress callbacks implemented
☐ Dio error handling for network failures
☐ Resumable download support (.partial files)
```

### lib/services/local_secretary.dart
```
☐ File exists at correct path
☐ Calls AIService for model path
☐ Waits for download completion
☐ generateResponse() method implemented
☐ formatMessageContext() for message formatting
☐ getSecretaryStatus() for UI feedback
```

### lib/services/notification_listener_service.dart
```
☐ File exists at correct path
☐ MethodChannel name: "com.africanaai/notifications"
☐ Filters WhatsApp, Telegram, Signal, Threema
☐ Stream returns NotificationEvent objects
☐ hasNotificationAccess() checks Android permission
☐ requestNotificationAccess() opens settings
```

### lib/screens/africana_inapp_wrapper.dart
```
☐ File exists at correct path
☐ WebView loads "https://www.africanaai.info/"
☐ AIService import and initialization
☐ _initializeSecretary() called in initState()
☐ _monitorDownloadProgress() tracks download
☐ AppBar shows Secretary status icon + percentage
☐ Progress bar visible during download (2px height)
☐ Error handling with retry button
☐ NotificationListener integration
```

### Android Native Code
```
☐ NotificationListenerServiceImpl.kt exists
☐ MainActivity.kt has MethodChannel setup
☐ AndroidManifest.xml has all permissions
☐ AndroidManifest.xml has service registration
```

---

## Android Configuration ✅

### AndroidManifest.xml Permissions
```xml
☐ <uses-permission android:name="android.permission.INTERNET" />
☐ <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
☐ <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
☐ <uses-permission android:name="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE" />
☐ <uses-permission android:name="android.permission.ACCESS_NOTIFICATION_POLICY" />
☐ <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### AndroidManifest.xml Service Registration
```xml
☐ <service android:name=".NotificationListenerServiceImpl"
    android:label="@string/notification_listener"
    android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE">
  <intent-filter>
    <action android:name="android.service.notification.NotificationListenerService" />
  </intent-filter>
</service>
```

### build.gradle (app level)
```gradle
☐ compileSdkVersion: 34+
☐ targetSdkVersion: 34+
☐ minSdkVersion: 31+ (Android 12)
```

---

## Model Hosting ✅

### Choose One:
```
☐ Firebase Storage URL configured
  - Format: https://firebasestorage.googleapis.com/v0/b/...
  - Model uploaded and verified
  
OR

☐ Hugging Face URL configured
  - Format: https://huggingface.co/google/gemma-270m-it/resolve/main/model.bin
  - Public access confirmed
  
OR

☐ Custom server URL configured
  - Format: https://your-domain.com/models/gemma-270m-int4.bin
  - File accessible via browser
```

### Verify URL Access
```bash
# Test the URL before building
curl -I https://your-hosting-url

# Should return:
# HTTP/1.1 200 OK
# Content-Length: 157286400 (or similar)
# Content-Type: application/octet-stream
```

### AIService Configuration
```dart
☐ static const String modelUrl = 'https://...';  // NOT a placeholder
☐ Model URL tested and working
☐ No trailing query parameters that might break
☐ URL resolves to actual model file (not redirect page)
```

---

## Device Requirements ✅

### Minimum Specs
```
☐ Android 12+ (API 31+)
☐ 4GB RAM minimum
☐ 300MB free storage
☐ 4G or WiFi connection
```

### Recommended Specs
```
☐ Android 13+
☐ 6GB+ RAM
☐ 500MB+ free storage
☐ LTE or WiFi for testing
```

---

## Build & Runtime ✅

### Pre-Build Cleanup
```bash
☐ flutter clean
☐ flutter pub get
☐ rm -rf build/
☐ rm -rf .dart_tool/
```

### Build APK
```bash
☐ flutter build apk --release
☐ APK size: 20-50MB (not 600MB+)
☐ No build errors
☐ No compilation warnings for our code
```

### Test on Device
```bash
☐ flutter run -v  (watch for any red errors)
☐ Device has USB debugging enabled
☐ Device has 300MB+ free space
☐ Device is Android 12+
```

---

## First Launch Behavior ✅

### Expected Timeline (First Time)

| Time | Event | Indicator |
|------|-------|-----------|
| 0s | App starts | Splash screen |
| 1-2s | WebView loads | africanaai.info page visible |
| 2-3s | Download starts | AppBar: "Downloading Secretary (0%)" |
| 10s | Download 10% | Progress bar shows movement |
| 1-2m | Download 50% | AppBar: "Downloading Secretary (50%)" |
| 2-5m | Download 100% | AppBar: "Secretary Ready" |
| 5m+ | Ready | Can send WhatsApp test message |

### Visual Indicators
```
☐ AppBar shows Secretary status icon (check mark when ready)
☐ AppBar shows download percentage during download
☐ Subtle 2px progress bar visible
☐ No app freeze or ANR (Application Not Responding)
☐ WebView remains responsive during download
```

### No Download on Restart
```
☐ Close app completely
☐ Reopen app
☐ AppBar immediately shows "Secretary Ready"
☐ No progress bar visible
☐ Download didn't happen again
☐ Model cached on disk
```

---

## Functionality Testing ✅

### WebView Testing
```
☐ africanaai.info loads in WebView
☐ Buttons clickable
☐ Navigation works
☐ Page content visible
☐ No errors in logs (adb logcat)
```

### Secretary Initialization
```
☐ AIService starts download silently
☐ LocalSecretary waits for download
☐ After completion, Secretary becomes "Ready"
☐ Status visible in AppBar
```

### Notification Listener
```
☐ First prompt: "Allow notification access?"
☐ Grant access in Android settings
☐ SendWhatsApp message
☐ Notification received by app
☐ Secretary generates response
☐ Snackbar shows suggested reply
```

### Error Scenarios
```
☐ Disable network → Download fails → Error shown
☐ Tap retry → Download resumes
☐ Network returns → Download completes
☐ No crashes or force closes
```

---

## Log Verification ✅

### Check Logs for Errors
```bash
# In Android Studio or terminal
adb logcat | grep -i "africana\|error\|exception"

# Should NOT see:
❌ "FileNotFoundException"
❌ "ConnectionException"
❌ "ClassNotFoundException"
❌ "NullPointerException"
❌ "Could not download model"

# Should see:
✅ "Download started"
✅ "Download progress: 25%"
✅ "Download completed"
✅ "Secretary ready"
```

---

## Permissions Verification ✅

### Android Settings
```
Settings → Apps → Africana AI → Permissions
☐ Storage: Granted (for model caching)
☐ Notifications: Granted (for listener)
☐ Network: Granted (for downloads)
```

### Runtime Permission Requests
```
☐ App requests notification access on first run
☐ Dialog shows: "Allow Africana AI to access notifications?"
☐ User can grant/deny
☐ Permission flows correctly to MethodChannel
```

---

## APK Size Check ✅

### Size Verification
```bash
# Build APK
flutter build apk --release

# Check size
du -h build/app/outputs/apk/release/app-release.apk

# Should be: 20-50MB
# NOT: 600MB+ (would indicate model bundled)
```

### Split APKs (For Play Store)
```bash
flutter build apk --release --split-per-abi

# Results:
# app-armeabi-v7a-release.apk    ~15-20MB
# app-arm64-v8a-release.apk      ~18-25MB
# app-x86-release.apk            ~17-24MB
# app-x86_64-release.apk         ~20-28MB
```

---

## Before Submitting to Play Store ✅

### Final Checks
```
☐ APK tested on Android 12 device
☐ APK tested on Android 13+ device
☐ Download completes successfully
☐ No crashes in 5 minute usage test
☐ Secretary responds to test message
☐ All permissions requested and working
☐ No "ANR" errors in logs
☐ UI responsive during download
```

### Store Listing
```
☐ Title: "Africana AI"
☐ Description mentions: AI Secretary, WhatsApp, Telegram, offline
☐ Short description: "Your private AI assistant for messaging"
☐ Target Android version: 12+
☐ Required RAM: 4GB
☐ Required storage: 300MB
☐ Network: Required (for model download)
```

### Version & Build Number
```
☐ Version code: 1+ (first release)
☐ Version name: "1.0.0"
☐ Build flavor: release
☐ No debug symbols (release build)
```

---

## Troubleshooting Checklist ✅

### If Download Fails
```
☐ Test URL with curl: curl -I <URL>
☐ Check firewall/proxy settings
☐ Try different network (WiFi vs 4G)
☐ Increase timeout in AIService
☐ Check device storage space (need 300MB+)
```

### If Secretary Doesn't Work
```
☐ Verify model file exists: adb shell ls -l app_documents/
☐ Check file size: should be ~150MB (not 0 bytes)
☐ Verify LocalSecretary initializes: watch logs
☐ Check notification listener: granted in settings?
☐ Send test WhatsApp/Telegram message
```

### If Download Resumes from 0%
```
☐ Check if .partial file exists: adb shell ls -l app_documents/
☐ Verify resumable download enabled in Dio
☐ Check Response headers include: Accept-Ranges: bytes
```

---

## Final Sign-Off ✅

Before marking as "Ready for Launch":

```
☐ All code checklist items verified
☐ Android manifest complete
☐ Model hosting URL configured and tested
☐ Device requirements met
☐ First launch behavior matches expectations
☐ Download completes successfully
☐ Secretary becomes "Ready"
☐ No crashes or errors
☐ WhatsApp/Telegram auto-replies working
☐ APK size is 20-50MB
☐ All logs clean
```

---

## Quick Reference Commands

### Build
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Test
```bash
flutter run -v
```

### View Logs
```bash
adb logcat | grep africana
```

### Check Model
```bash
adb shell ls -l app_documents/
```

### Install APK
```bash
adb install build/app/outputs/apk/release/app-release.apk
```

### Uninstall App
```bash
adb uninstall com.example.africanaai
```

---

**Status**: ✅ Complete Verification Checklist

Run through this checklist before launching to ensure everything is working correctly!
