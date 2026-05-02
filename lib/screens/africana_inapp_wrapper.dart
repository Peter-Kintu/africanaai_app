import 'dart:async';
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
  bool _isOffline = false;
  String _errorMessage = "";
  Timer? _errorTimer;
  Timer? _secretaryErrorTimer;
  bool _secretaryErrorShown = false;

  // URLs for different sections
  final String _url = "https://www.africanaai.info/";

  // Optimized settings for a smooth AI platform experience
  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: true, // Allows debugging in Chrome/Safari dev tools
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    useHybridComposition: true, // Better performance for Android
    allowsBackForwardNavigationGestures: true, // Native swipe-to-back for iOS
    verticalScrollBarEnabled: false,
    supportZoom: false, // Keeps the UI consistent with mobile app feel
    supportMultipleWindows: true,
    useShouldOverrideUrlLoading: true,
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

  void _startErrorTimer() {
    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isOffline = false;
          _errorMessage = "";
        });
      }
    });
  }

  Widget _buildSecretaryError() {
    if (_aiService.errorMessage != null && !_secretaryErrorShown) {
      _secretaryErrorShown = true;
      _secretaryErrorTimer?.cancel();
      _secretaryErrorTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _secretaryErrorShown = false;
          });
        }
      });
    }
    if (_aiService.errorMessage != null && _secretaryErrorShown) {
      return Positioned(
        bottom: 80,
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
              TextButton(
                onPressed: () {
                  _aiService.retryDownload().then((_) {
                    setState(() {});
                  });
                  setState(() {
                    _secretaryErrorShown = false;
                  });
                  _secretaryErrorTimer?.cancel();
                },
                child: const Text('Retry', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
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
    _errorTimer?.cancel();
    _secretaryErrorTimer?.cancel();
    _notificationService.dispose();
    _secretary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  child: _isOffline
                      ? _buildOfflineScreen()
                      : InAppWebView(
                          key: webViewKey,
                          initialUrlRequest: URLRequest(
                            url: WebUri(_url),
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
                          // ignore: deprecated_member_use
                          onLoadError: (controller, url, code, message) {
                            setState(() {
                              _isOffline = true;
                              _errorMessage = "Unable to connect. Please check your internet or try again later.";
                            });
                            _startErrorTimer();
                          },
                          // ignore: deprecated_member_use
                          onLoadHttpError: (controller, url, statusCode, description) {
                            setState(() {
                              _isOffline = true;
                              _errorMessage = "Service unavailable. Please try again later.";
                            });
                            _startErrorTimer();
                          },
                          onReceivedError: (controller, request, error) {
                            setState(() {
                              _isOffline = true;
                              _errorMessage = "Unable to connect. Please check your internet or try again later.";
                            });
                            _startErrorTimer();
                          },
                          onReceivedHttpError: (controller, request, errorResponse) {
                            setState(() {
                              _isOffline = true;
                              _errorMessage = "Service unavailable. Please try again later.";
                            });
                            _startErrorTimer();
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
                              source: """
                                header { display: none !important; }
                                footer { display: none !important; }
                                nav { display: none !important; }
                                .header-glass { display: none !important; }
                                #mobile-bottom-nav { display: none !important; }
                                .web-only-header { display: none !important; }
                                .download-app-banner { display: none !important; }
                                body { padding-bottom: 0 !important; }
                              """,
                            );
                          },
                          shouldOverrideUrlLoading: (controller, navigationAction) async {
                            final uri = navigationAction.request.url;
                            if (uri == null) {
                              return NavigationActionPolicy.CANCEL;
                            }
                            return NavigationActionPolicy.ALLOW;
                          },
                          onCreateWindow: (controller, createWindowAction) async {
                            final requestUrl = createWindowAction.request.url;
                            if (requestUrl != null) {
                              controller.loadUrl(urlRequest: URLRequest(url: requestUrl));
                            }
                            return false;
                          },
                        ),
                ),
              ],
            ),
            // Show error message if download failed
            _buildSecretaryError(),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Internet Connection',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isOffline = false;
                  _errorMessage = "";
                });
                _errorTimer?.cancel();
                webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(_url)));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
