import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/ai_service.dart';
import '../services/local_secretary.dart';
import '../services/notification_listener_service.dart';

class AfricanaInAppWrapper extends StatefulWidget {
  const AfricanaInAppWrapper({super.key});

  @override
  State<AfricanaInAppWrapper> createState() => _AfricanaInAppWrapperState();
}

class _AfricanaInAppWrapperState extends State<AfricanaInAppWrapper> {
  final GlobalKey webViewKey = GlobalKey();
  final AIService _aiService = AIService();
  final LocalSecretary _secretary = LocalSecretary();
  final NotificationListenerService _notificationService =
      NotificationListenerService();
  
  InAppWebViewController? webViewController;
  double progress = 0;
  bool _secretaryReady = false;
  String _secretaryStatus = "Initializing Secretary...";

  // Optimized settings for a smooth AI platform experience
  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: true, // Allows debugging in Chrome/Safari dev tools
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    useHybridComposition: true, // Better performance for Android
    allowsBackForwardNavigationGestures: true, // Native swipe-to-back for iOS
    verticalScrollBarEnabled: false,
    supportZoom: false, // Keeps the UI consistent with mobile app feel
  );

  @override
  void initState() {
    super.initState();
    _initializeSecretary();
    _setupNotificationListener();
  }

  /// Initialize Secretary: start background model download silently
  Future<void> _initializeSecretary() async {
    try {
      // 1. Start background model download (if not already cached)
      // This happens silently while user browses the WebView
      _aiService.prepareSecretaryModel().then((_) {
        if (mounted) {
          setState(() {
            _secretaryReady = _aiService.isReady;
            _secretaryStatus = "Secretary ready for duty!";
          });
        }
        // 2. Initialize LocalSecretary once model is ready
        _secretary.initModel();
      });
      
      // 3. Monitor download progress for UI updates
      _monitorDownloadProgress();
    } catch (e) {
      if (mounted) {
        setState(() {
          _secretaryReady = false;
          _secretaryStatus = "Secretary initialization: $e";
        });
      }
    }
  }

  /// Monitor download progress and update UI
  Future<void> _monitorDownloadProgress() async {
    while (!_aiService.isReady && mounted) {
      if (_aiService.isDownloading) {
        setState(() {
          progress = _aiService.downloadProgress;
          final percent = (progress * 100).toStringAsFixed(0);
          _secretaryStatus = "Downloading Secretary ($percent%)";
        });
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Setup WhatsApp & Telegram notification listener
  void _setupNotificationListener() {
    // Listen for messenger notifications
    _notificationService.getMessengerNotifications().listen(
      (notification) async {
        if (!_secretaryReady) return;
        
        // Format the message context
        final context = _secretary.formatMessageContext(
          senderName: notification.sender ?? notification.title ?? "Unknown",
          messageContent: notification.content ?? "",
        );
        
        // Generate AI response locally
        final aiResponse = await _secretary.generateResponse(context);
        
        // In production, you would send the reply back to the messenger app
        _showSecretaryNotification(
          sender: notification.sender ?? "Secretary",
          message: aiResponse,
        );
      },
    );
    
    // Check if we have notification access
    _notificationService.hasNotificationAccess().then((hasAccess) {
      if (!hasAccess && mounted) {
        _showNotificationAccessDialog();
      }
    });
  }

  /// Show dialog requesting notification access
  void _showNotificationAccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Enable Notification Access"),
        content: const Text(
          "The Secretary needs notification access to auto-reply to WhatsApp and Telegram messages. "
          "This is completely private - responses are generated locally on your device.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Deny"),
          ),
          TextButton(
            onPressed: () {
              _notificationService.requestNotificationAccess();
              Navigator.pop(ctx);
            },
            child: const Text("Enable"),
          ),
        ],
      ),
    );
  }

  /// Display a notification that the secretary processed a message
  void _showSecretaryNotification({
    required String sender,
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Secretary replied to $sender:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }

  @override
  void dispose() {
    _notificationService.dispose();
    _secretary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Africana AI"),
        elevation: 0,
        actions: [
          // Secretary status indicator with tap-to-retry
          GestureDetector(
            onTap: _aiService.errorMessage != null
                ? () => _aiService.retryDownload().then((_) {
                      setState(() {});
                    })
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Center(
                child: Tooltip(
                  message: _secretaryStatus,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _secretaryReady ? Icons.check_circle : 
                        _aiService.isDownloading ? Icons.download :
                        _aiService.errorMessage != null ? Icons.error :
                        Icons.schedule,
                        color: _secretaryReady ? Colors.green :
                        _aiService.errorMessage != null ? Colors.red :
                        Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _secretaryReady ? "Secretary Ready" :
                        _aiService.isDownloading ? "Downloading..." :
                        _aiService.errorMessage != null ? "Retry" :
                        "Loading...",
                        style: TextStyle(
                          fontSize: 12,
                          color: _secretaryReady ? Colors.green :
                          _aiService.errorMessage != null ? Colors.red :
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Subtle download progress bar (only shown during download)
                if (_aiService.isDownloading && !_secretaryReady)
                  LinearProgressIndicator(
                    value: _aiService.downloadProgress,
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.blue,
                    minHeight: 2,
                  )
                else if (progress < 1.0)
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.blue,
                    minHeight: 2,
                  )
                else
                  const SizedBox.shrink(),
                Expanded(
                  child: InAppWebView(
                    key: webViewKey,
                    initialUrlRequest: URLRequest(
                      url: WebUri("https://www.africanaai.info/"),
                    ),
                    initialSettings: settings,
                    onWebViewCreated: (controller) {
                      webViewController = controller;
                    },
                    onProgressChanged: (controller, progress) {
                      setState(() {
                        this.progress = progress / 100;
                      });
                    },
                    // Handles file uploads (e.g., for JobCopilot CV uploads)
                    onPermissionRequest: (controller, request) async {
                      return PermissionResponse(
                        resources: request.resources,
                        action: PermissionResponseAction.GRANT,
                      );
                    },
                    onLoadStop: (controller, url) async {
                      // Hide web-only UI elements that shouldn't appear in the app
                      await controller.injectCSSCode(
                        source:
                            ".web-only-header { display: none !important; } .download-app-banner { display: none !important; }",
                      );
                    },
                  ),
                ),
              ],
            ),
            // Show error message if download failed
            if (_aiService.errorMessage != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Secretary Model: ${_aiService.errorMessage}',
                          style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
