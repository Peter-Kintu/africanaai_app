import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'ai_service.dart';

/// LocalSecretary handles on-device LLM inference without internet
/// Works with models downloaded by AIService
class LocalSecretary {
  static final LocalSecretary _instance = LocalSecretary._internal();
  
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _modelPath;
  final AIService _aiService = AIService();

  factory LocalSecretary() {
    return _instance;
  }

  LocalSecretary._internal();

  /// Check if model is initialized
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;

  /// Initialize the local model (uses model from AIService)
  Future<void> initModel() async {
    if (_isInitialized || _isInitializing) return;
    
    _isInitializing = true;
    
    try {
      // Get model path from AIService (downloaded model)
      _modelPath = await _aiService.getModelPath();
      
      if (_modelPath == null) {
        throw Exception('Secretary model not yet downloaded. Please wait...');
      }
      
      // Verify model file exists
      if (!await File(_modelPath!).exists()) {
        throw Exception('Model file missing: $_modelPath');
      }
      
      _isInitialized = true;
      print('LocalSecretary initialized with model: $_modelPath');
    } catch (e) {
      print('Error initializing local secretary model: $e');
      _isInitialized = false;
    } finally {
      _isInitializing = false;
    }
  }

  /// Get the path to the local model
  String? getModelPath() {
    return _modelPath;
  }

  /// Generate AI response locally without internet
  /// This is used for auto-replies to WhatsApp & Telegram messages
  Future<String> generateResponse(
    String prompt, {
    int maxTokens = 256,
    double temperature = 0.7,
  }) async {
    if (!_isInitialized) {
      return "Secretary is preparing... Please wait a moment.";
    }

    try {
      // For now, return a structured prompt-based response
      // In production, this would interface with the actual model inference engine
      return _generateLocalResponse(prompt, maxTokens, temperature);
    } catch (e) {
      print('Error generating response: $e');
      return "I'm having trouble thinking right now. Please try again.";
    }
  }

  /// Generate response locally using the initialized model
  /// This demonstrates the pattern - in production, call actual inference engine
  String _generateLocalResponse(
    String prompt,
    int maxTokens,
    double temperature,
  ) {
    // This is a placeholder implementation
    // In production, you would call the actual Mediapipe LLM inference here
    // For now, return a contextual response based on the prompt
    
    if (prompt.toLowerCase().contains('hello') ||
        prompt.toLowerCase().contains('hi')) {
      return "Hello! I'm Africana AI Secretary. How can I assist you today?";
    } else if (prompt.toLowerCase().contains('help')) {
      return "I'm here to help with your productivity. Feel free to ask me anything!";
    } else if (prompt.toLowerCase().contains('thank')) {
      return "You're welcome! Always happy to help.";
    } else {
      // Generic response for other prompts
      return "I understand: '$prompt'. I'm processing this locally on your device for privacy. How can I help further?";
    }
  }

  /// Format context for WhatsApp/Telegram messages
  String formatMessageContext({
    required String senderName,
    required String messageContent,
    String? previousContext,
  }) {
    final timestamp = DateTime.now().toString();
    
    var context = '''
Assistant: You are a helpful secretary for $senderName.
Context: Message received at $timestamp
Message: "$messageContent"
''';
    
    if (previousContext != null) {
      context += '\nPrevious Context: $previousContext';
    }
    
    return context;
  }

  /// Check if Secretary is ready for use
  Future<bool> isSecretaryReady() async {
    return _aiService.isReady || _isInitialized;
  }

  /// Get Secretary status for UI display
  String getSecretaryStatus() {
    if (_isInitialized) {
      return 'Secretary ready for duty!';
    } else if (_aiService.isDownloading) {
      final percent = (_aiService.downloadProgress * 100).toStringAsFixed(0);
      return 'Secretary initializing ($percent%)';
    } else if (_aiService.errorMessage != null) {
      return 'Secretary offline: ${_aiService.errorMessage}';
    } else {
      return 'Secretary starting up...';
    }
  }

  /// Clean up resources
  void dispose() {
    _isInitialized = false;
    _isInitializing = false;
    _modelPath = null;
  }
}
