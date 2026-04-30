import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// AIService handles silent background download of the Secretary model
/// Keeps initial app download small (~20-50MB) while downloading model in background
/// Model is downloaded once and cached indefinitely
class AIService {
  static final AIService _instance = AIService._internal();
  
  bool isReady = false;
  bool isDownloading = false;
  double downloadProgress = 0.0;
  String? errorMessage;
  
  // Model configuration
  static const String modelFileName = 'secretary_model.bin';
  // Replace with your actual model URL (Firebase Storage, AWS S3, your server, etc.)
  static const String modelUrl = 
      'https://huggingface.co/google/gemma-2b-it/resolve/main/model.bin';
  
  // Optional: Model hash for integrity verification
  static const String? modelHash = null; // Add if you want to verify downloads

  factory AIService() {
    return _instance;
  }

  AIService._internal();

  /// Check if model file exists locally
  Future<bool> modelExists() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final modelFile = File('${directory.path}/$modelFileName');
      return await modelFile.exists();
    } catch (e) {
      print('Error checking model existence: $e');
      return false;
    }
  }

  /// Get the path to the local model file
  Future<String?> getModelPath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final modelFile = File('${directory.path}/$modelFileName');
      
      if (await modelFile.exists()) {
        return modelFile.path;
      }
      return null;
    } catch (e) {
      print('Error getting model path: $e');
      return null;
    }
  }

  /// Prepare the Secretary model: check if exists, download if needed
  /// This runs silently in background on app startup
  Future<void> prepareSecretaryModel() async {
    if (isReady) return; // Already ready
    
    // Check if model already exists
    if (await modelExists()) {
      isReady = true;
      downloadProgress = 1.0;
      print('Secretary model already available locally');
      return;
    }

    // Model doesn't exist, start background download
    isDownloading = true;
    errorMessage = null;
    
    try {
      await _downloadModel();
      isReady = true;
      isDownloading = false;
      downloadProgress = 1.0;
      print('Secretary model downloaded and ready');
    } catch (e) {
      isDownloading = false;
      errorMessage = 'Model download failed: $e';
      isReady = false;
      print(errorMessage);
      // Don't throw - allow app to continue with offline mode
    }
  }

  /// Download the model file with progress tracking
  Future<void> _downloadModel() async {
    final directory = await getApplicationDocumentsDirectory();
    final savePath = '${directory.path}/$modelFileName';
    final dio = Dio();

    // Configure timeouts for reliable downloads
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);

    // Check if partial download exists (for resumption)
    final partialFile = File('$savePath.partial');
    int startBytes = 0;
    
    if (await partialFile.exists()) {
      startBytes = await partialFile.length();
      print('Resuming download from byte: $startBytes');
    }

    try {
      // Download with progress tracking and resumable support
      await dio.download(
        modelUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgress = (received + startBytes) / (total + startBytes);
            print('Download progress: ${(downloadProgress * 100).toStringAsFixed(1)}%');
          }
        },
        deleteOnError: false, // Keep partial file for resumption
      );

      // Verify file was created
      final modelFile = File(savePath);
      if (!await modelFile.exists()) {
        throw Exception('Model file not created after download');
      }

      print('Model download completed: $savePath');
    } on DioException catch (e) {
      print('Dio download error: ${e.message}');
      throw Exception('Download failed: ${e.message}');
    } catch (e) {
      print('Unexpected download error: $e');
      rethrow;
    }
  }

  /// Retry download if it failed (user can trigger manually)
  Future<void> retryDownload() async {
    if (isDownloading) return; // Already downloading
    
    // Clear error state
    errorMessage = null;
    downloadProgress = 0.0;
    
    // Check again if model somehow exists
    if (await modelExists()) {
      isReady = true;
      return;
    }

    await prepareSecretaryModel();
  }

  /// Get user-friendly status message
  String getStatusMessage() {
    if (isReady && downloadProgress >= 1.0) {
      return 'Secretary Ready';
    } else if (isDownloading) {
      final percent = (downloadProgress * 100).toStringAsFixed(0);
      return 'Downloading Secretary Model ($percent%)';
    } else if (errorMessage != null) {
      return 'Secretary Offline - Tap to retry';
    } else {
      return 'Initializing Secretary...';
    }
  }

  /// Cleanup resources
  void dispose() {
    isReady = false;
    isDownloading = false;
    downloadProgress = 0.0;
    errorMessage = null;
  }

  /// Get estimated download time (for UX feedback)
  String getEstimatedTimeRemaining() {
    if (downloadProgress <= 0 || downloadProgress >= 1.0) {
      return '';
    }
    
    // This is a simple heuristic - in production you'd track actual speed
    final percentRemaining = (1.0 - downloadProgress) * 100;
    
    if (percentRemaining > 90) {
      return '~5 minutes';
    } else if (percentRemaining > 50) {
      return '~2 minutes';
    } else if (percentRemaining > 25) {
      return '~1 minute';
    } else {
      return '~30 seconds';
    }
  }
}
