# Africana AI - Background Streaming Deployment Guide

## Quick Start (30 Minutes)

### Step 1: Choose Model Hosting (5 min)

Pick one based on your needs:

#### Option A: Firebase Storage (Easiest for African users) ✅ Recommended
```bash
# 1. Create Firebase project
firebase init storage

# 2. Download model
# From: https://huggingface.co/google/gemma-270m-it
# File: gemma-270m-int4.bin (~150MB)

# 3. Upload to Firebase
gsutil cp gemma-270m-int4.bin gs://your-project.appspot.com/

# 4. Get public URL
# Go to Firebase Console → Storage → Click file → Copy URL
# Format: https://firebasestorage.googleapis.com/v0/b/...
```

#### Option B: Hugging Face (Simplest) ✅ Recommended
```
Already public, no upload needed!
URL: https://huggingface.co/google/gemma-270m-it/resolve/main/model.bin
```

#### Option C: AWS S3 (For scale)
```bash
# Upload to S3
aws s3 cp gemma-270m-int4.bin s3://your-bucket/

# Get public URL
# Format: https://your-bucket.s3.amazonaws.com/gemma-270m-int4.bin
```

### Step 2: Update Code (5 min)

Edit `lib/services/ai_service.dart`:

```dart
static const String modelUrl = 
    'https://your-hosting-service.com/gemma-270m-int4.bin';
    
// If using Hugging Face:
// static const String modelUrl = 
//     'https://huggingface.co/google/gemma-270m-it/resolve/main/model.bin';
```

### Step 3: Build & Test (10 min)

```bash
# Clean and rebuild
flutter clean
flutter pub get

# Run on device
flutter run

# Watch the download progress!
# Should see: "Downloading Secretary (15%)" etc.
```

### Step 4: Verify (10 min)

**On First Launch:**
- ✅ App opens quickly (no bloat)
- ✅ WebView loads africanaai.info
- ✅ AppBar shows "Downloading... (0%)"
- ✅ Progress bar visible (2px height)
- ✅ Model downloads in background (2-5 min)
- ✅ AppBar changes to "Secretary Ready"

**On Restart:**
- ✅ App opens immediately
- ✅ AppBar shows "Secretary Ready" instantly
- ✅ No download bar visible (cached)

---

## Step-by-Step Setup

### Using Firebase Storage (Detailed)

#### 1. Create Firebase Project
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Create project
firebase init storage
```

#### 2. Download Model
```bash
# Create models directory
mkdir models
cd models

# Download Gemma 270M (150MB)
# From: https://huggingface.co/google/gemma-270m-it
# Download: model.bin

# Or use curl (if available)
# curl -L -o model.bin https://huggingface.co/...
```

#### 3. Upload to Firebase
```bash
# Using gsutil
gsutil cp model.bin gs://your-project-id.appspot.com/models/

# Verify upload
gsutil ls gs://your-project-id.appspot.com/models/
```

#### 4. Get Public URL
```
Firebase Console → Storage → your-project-id.appspot.com
→ Click the model.bin file
→ Copy Download URL
→ Format: https://firebasestorage.googleapis.com/v0/b/...
```

#### 5. Update App
Edit `lib/services/ai_service.dart`:
```dart
static const String modelUrl = 
    'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/models%2Fmodel.bin?alt=media';
```

---

### Using Hugging Face (Simplest)

#### 1. Find Model
- Go to: https://huggingface.co/google/gemma-270m-it
- Click: "Files and versions"
- Find: model.bin (150MB)

#### 2. Copy URL
- Right-click → "Copy link"
- Or construct: `https://huggingface.co/google/gemma-270m-it/resolve/main/model.bin`

#### 3. Update App
Edit `lib/services/ai_service.dart`:
```dart
static const String modelUrl = 
    'https://huggingface.co/google/gemma-270m-it/resolve/main/model.bin';
```

#### 4. Done!
That's it. No uploads needed, already public.

---

### Using Your Own Server

#### 1. Upload Model
```bash
# SSH to your server
ssh user@your-server.com

# Create models directory
mkdir -p /var/www/models/

# Upload model file
# scp gemma-270m-int4.bin user@your-server.com:/var/www/models/
```

#### 2. Make Public
```bash
# Ensure it's accessible via HTTP
# URL: https://your-server.com/models/gemma-270m-int4.bin
```

#### 3. Update App
```dart
static const String modelUrl = 
    'https://your-server.com/models/gemma-270m-int4.bin';
```

---

## Configuration Options

### Adjust Download Timeout (slow networks)

Edit `lib/services/ai_service.dart`:

```dart
// Default: 30 seconds (good for 4G)
dio.options.connectTimeout = const Duration(seconds: 30);
dio.options.receiveTimeout = const Duration(seconds: 30);

// For 3G (slower):
dio.options.connectTimeout = const Duration(seconds: 60);
dio.options.receiveTimeout = const Duration(seconds: 60);

// For 2G (very slow):
dio.options.connectTimeout = const Duration(seconds: 120);
dio.options.receiveTimeout = const Duration(seconds: 120);
```

### Use Different Model
```dart
// Instead of Gemma 270M (~150MB):
static const String modelUrl = 
    'https://...gemma-2b-it-gpu.bin';  // 1.2GB (more powerful)
    // or
    'https://...llama-2-7b-int4.bin';  // 3.5GB (best quality)
```

---

## Testing Checklist

### ✅ Fresh Installation
```
1. Delete app from device
2. Install fresh build
3. Open app
4. Should show "Downloading Secretary (0%)" immediately
5. Progress increases: 10%... 25%... 50%... 100%
6. Takes 2-5 minutes on 4G
7. Shows "Secretary Ready" when complete
```

### ✅ Cached Model
```
1. Close app
2. Reopen app
3. Should show "Secretary Ready" immediately
4. No progress bar visible
5. Instant access to Secretary
```

### ✅ Network Error
```
1. Start download
2. Disable WiFi mid-download
3. App shows error message
4. Red error box at bottom
5. Tap "Retry" in AppBar
6. Download resumes from where it stopped
```

### ✅ Interrupt & Resume
```
1. Kill app during download (force stop)
2. Reopen app
3. Should resume from last position (not restart at 0%)
4. Should eventually complete
```

---

## Deployment to Play Store

### Before Publishing

1. **Test on Multiple Devices**
   - Android 12 (minimum)
   - Android 13+
   - Different RAM (4GB, 6GB, 8GB)
   - Different networks (WiFi, 4G, 3G)

2. **Verify APK Size**
   ```bash
   flutter build apk --release
   # Should be: 20-50MB (NOT 600MB+)
   ```

3. **Check Storage**
   - Requires 300MB+ free space on device
   - Model: ~150-200MB
   - Cache: ~50MB
   - Total: ~250MB

### Store Listing

Update your Play Store description:

```
New: Africana AI Secretary (AI-Powered Auto-Replies)
- On-device LLM for WhatsApp & Telegram
- First launch downloads AI model (~150MB, one-time)
- 100% private - no data sent to servers
- Works offline after first download

Requirements:
- Android 12+ 
- 4GB+ RAM recommended
- 300MB free storage
- Internet for first model download
```

### Build Release APK

```bash
# With split ABIs (smaller per-device downloads)
flutter build apk --release --split-per-abi

# Will create:
# - app-armeabi-v7a-release.apk  (~15MB each)
# - app-arm64-v8a-release.apk    (~18MB each)
# - app-x86-release.apk          (~17MB each)
# - app-x86_64-release.apk       (~18MB each)

# Upload all to Play Store
# Users download only their architecture (~15-20MB)
```

### Upload to Play Store

```bash
# Build App Bundle (recommended for Play Store)
flutter build appbundle --release

# Upload in Play Console:
# 1. Open Play Console
# 2. Your app → Release → Create release
# 3. Upload app-release.aab
# 4. Review content rating, pricing, etc.
# 5. Submit for review

# Google typically approves within 24-48 hours
```

---

## Post-Launch Monitoring

### Track Downloads

Add analytics to `ai_service.dart`:

```dart
Future<void> prepareSecretaryModel() async {
  // Log start
  print('Download started');
  
  // ... existing code ...
  
  // Log completion
  if (isReady) {
    print('Download succeeded');
    // Send to analytics
    // analytics.logEvent('model_download_success');
  }
}
```

### Monitor Errors

Check Play Console:
- Crash reports
- User reviews mentioning download issues
- ANR (Application Not Responding) reports

---

## Optimization Tips

### For African Users

1. **Use Firebase with African regions**
   - Google Cloud CDN reaches Uganda
   - Fast downloads (2-5 min on 4G)

2. **Allow retry for slow networks**
   - Already implemented in AIService
   - Shows user "Retry" button

3. **Show download progress**
   - AppBar: "Downloading... (45%)"
   - Subtitle: estimated time
   - Progress bar: visual feedback

### For APK Size

Use `--split-per-abi` when building:
```bash
flutter build apk --release --split-per-abi
# Saves 15-20% per device
```

---

## Troubleshooting

### "Download URL returns 404"
```
→ Verify URL is accessible: curl https://your-url
→ Check Firebase URL format
→ Verify model file still exists on server
```

### "Download completes but Secretary shows offline"
```
→ Check model file wasn't corrupted
→ Verify file size matches expected (~150MB)
→ Delete app data and retry
→ Check: adb shell ls -l app_documents/
```

### "Very slow download speed"
```
→ Use Firebase (global CDN)
→ Use Hugging Face (already optimized for African regions)
→ Check user's internet connection quality
→ Increase timeout values
```

### "App crashes during download"
```
→ Check free disk space (need 300MB+)
→ Verify INTERNET permission in AndroidManifest.xml
→ Check for memory pressure (other apps running)
→ Check dio version compatibility
```

---

## Performance Metrics

### Expected Timeline

| Event | Time | Notes |
|-------|------|-------|
| App startup | 0s | Instant |
| Download start | 0-1s | Check if model exists |
| Download progress | 0-5min | Depends on connection |
| Secretary ready | 5-10min | First launch |
| Secretary ready | 0s | Subsequent launches |

### Storage on Device

| Component | Size | Notes |
|-----------|------|-------|
| App executable | 20-50MB | Varies by architecture |
| Model file | 150-200MB | Gemma 270M |
| Cache/temp | 50MB | WebView & app data |
| **Total** | **~250MB** | Per installation |

---

## Success Indicators ✅

After deployment, you should see:

- ✅ APK download: 15-50MB (not 600MB+)
- ✅ First launch download: 2-5 minutes
- ✅ AppBar progress: "Downloading... (50%)"
- ✅ Second launch: Instant, no download
- ✅ Secretary generates responses offline
- ✅ WhatsApp/Telegram auto-replies working
- ✅ No error messages in logs

---

## Next Steps

1. **Choose hosting** (Firebase, Hugging Face, or your server)
2. **Upload model file**
3. **Update AIService URL**
4. **Build and test** on real device
5. **Deploy to Play Store**
6. **Monitor for issues**

---

**Status**: ✅ Ready for Production

Your Africana AI Secretary is now optimized for the African app market!
