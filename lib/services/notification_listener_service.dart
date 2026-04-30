import 'dart:async';
import 'package:flutter/services.dart';

/// Notification event model
class NotificationEvent {
  final String? packageName;
  final String? title;
  final String? content;
  final String? sender;
  final DateTime timestamp;

  NotificationEvent({
    required this.packageName,
    required this.title,
    required this.content,
    this.sender,
  }) : timestamp = DateTime.now();

  bool get isWhatsApp => packageName?.contains('whatsapp') ?? false;
  bool get isTelegram => packageName?.contains('telegram') ?? false;
  bool get isMessenger => packageName?.contains('messenger') ?? false;
}

/// Service for listening to and processing notifications
class NotificationListenerService {
  static const platform = MethodChannel('com.africanaai/notifications');
  
  static final NotificationListenerService _instance =
      NotificationListenerService._internal();
  
  final StreamController<NotificationEvent> _notificationController =
      StreamController<NotificationEvent>.broadcast();

  factory NotificationListenerService() {
    return _instance;
  }

  NotificationListenerService._internal() {
    _setupNotificationChannel();
  }

  /// Stream of incoming notifications
  Stream<NotificationEvent> get notificationsStream =>
      _notificationController.stream;

  /// Setup the method channel to receive notifications from native code
  void _setupNotificationChannel() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onNotification') {
        final notification = NotificationEvent(
          packageName: call.arguments['packageName'] as String?,
          title: call.arguments['title'] as String?,
          content: call.arguments['text'] as String?,
          sender: call.arguments['sender'] as String?,
        );
        _notificationController.add(notification);
      }
    });
  }

  /// Filter notifications for specific apps
  Stream<NotificationEvent> getNotificationsFromApp(String appName) {
    return notificationsStream.where((event) {
      return event.packageName?.toLowerCase().contains(appName.toLowerCase()) ??
          false;
    });
  }

  /// Get WhatsApp and Telegram notifications specifically
  Stream<NotificationEvent> getMessengerNotifications() {
    return notificationsStream.where((event) {
      return event.isWhatsApp || event.isTelegram || event.isMessenger;
    });
  }

  /// Start listening for notifications (requires permission on Android 31+)
  Future<bool> startListening() async {
    try {
      final result = await platform.invokeMethod<bool>('startListening');
      return result ?? false;
    } catch (e) {
      print('Error starting notification listener: $e');
      return false;
    }
  }

  /// Stop listening for notifications
  Future<void> stopListening() async {
    try {
      await platform.invokeMethod('stopListening');
    } catch (e) {
      print('Error stopping notification listener: $e');
    }
  }

  /// Check if notification access permission is granted
  Future<bool> hasNotificationAccess() async {
    try {
      final result = await platform.invokeMethod<bool>('hasNotificationAccess');
      return result ?? false;
    } catch (e) {
      print('Error checking notification access: $e');
      return false;
    }
  }

  /// Request notification access permission (opens settings)
  Future<void> requestNotificationAccess() async {
    try {
      await platform.invokeMethod('requestNotificationAccess');
    } catch (e) {
      print('Error requesting notification access: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _notificationController.close();
  }
}
