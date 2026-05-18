import 'package:dio/dio.dart';

/// AIService handles communication with the deployed cloud Gemma LLM
class AIService {
  static final AIService _instance = AIService._internal();
  
  final Dio _dio = Dio();
  
  // Deployed Gemma API endpoint
  static const String baseUrl = 'https://sing-sjf2.onrender.com/v1/chat';
  
  // SECRETS: Pass via build-args or secure storage in production.
  static const String _apiBearerToken = '';

  factory AIService() {
    return _instance;
  }

  AIService._internal() {
    // Configure default timeouts for LLM Generation
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    // Add Auth Headers if token exists
    if (_apiBearerToken.isNotEmpty && _apiBearerToken != 'YOUR_HUGGING_FACE_OR_BACKEND_TOKEN') {
      _dio.options.headers['Authorization'] = 'Bearer $_apiBearerToken';
    }
    _dio.options.headers['Content-Type'] = 'application/json';
  }

  // Legacy fields preserved to prevent compilation breaks in your WebView UI
  bool get isReady => true; 
  bool get isDownloading => false;
  double get downloadProgress => 1.0;
  String? get errorMessage => null;

  /// Sends the conversation context to your deployed Gemma model
  Future<String> fetchGemmaResponse(String prompt, {int maxTokens = 256, double temperature = 0.7}) async {
    try {
      final Map<String, dynamic> payload = {
        'prompt': prompt,
      };

      final response = await _dio.post('', data: payload);

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is String) {
          return data;
        } else if (data is Map<String, dynamic>) {
          if (data.containsKey('translated_text')) {
            return data['translated_text'].toString();
          }
          if (data.containsKey('result')) {
            return data['result'].toString();
          }
          if (data.containsKey('output')) {
            return data['output'].toString();
          }
          if (data.containsKey('generated_text')) {
            return data['generated_text'].toString();
          }
          if (data.containsKey('text')) {
            return data['text'].toString();
          }
          if (data.containsKey('translation')) {
            return data['translation'].toString();
          }
        } else if (data is List && data.isNotEmpty) {
          final first = data.first;
          if (first is Map<String, dynamic>) {
            return first['generated_text']?.toString() ?? first['text']?.toString() ?? first.toString();
          }
          return first.toString();
        }

        return data.toString();
      } else {
        throw Exception('Server returned code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('Network Error targeting Gemma Cloud: ${e.message}');
      if (e.response != null) {
        print('Server error data: ${e.response?.data}');
      }
      return "The AI agent is currently busy. Please try again soon.";
    } catch (e) {
      print('Unexpected API error: $e');
      return "Failed to establish secure handshake with cloud server.";
    }
  }

  // Placeholder definitions to keep UI references compatible without crashing
  Future<void> prepareSecretaryModel() async {}
  Future<void> retryDownload() async {}
  String getStatusMessage() => 'Secretary Cloud Active';
  String getEstimatedTimeRemaining() => '';
  void dispose() {}
}
