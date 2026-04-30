package com.example.africanaai

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Main Activity for Africana AI
 * Sets up Flutter engine and handles method channels for native Android features
 */
class MainActivity: FlutterActivity() {
    
    companion object {
        private const val NOTIFICATION_CHANNEL = "com.africanaai/notifications"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup notification method channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startListening" -> {
                    result.success(startNotificationListening())
                }
                "stopListening" -> {
                    result.success(stopNotificationListening())
                }
                "hasNotificationAccess" -> {
                    result.success(checkNotificationAccess())
                }
                "requestNotificationAccess" -> {
                    openNotificationAccessSettings()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        
        // Connect the method channel to the notification listener service
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_CHANNEL
        )
        NotificationListenerServiceImpl.setMethodChannel(channel)
    }

    /**
     * Start listening for notifications
     */
    private fun startNotificationListening(): Boolean {
        return try {
            val intent = Intent(this, NotificationListenerServiceImpl::class.java)
            startService(intent)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    /**
     * Stop listening for notifications
     */
    private fun stopNotificationListening(): Boolean {
        return try {
            val intent = Intent(this, NotificationListenerServiceImpl::class.java)
            stopService(intent)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    /**
     * Check if app has notification access permission
     */
    private fun checkNotificationAccess(): Boolean {
        val enabledNotificationListeners = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        ) ?: ""
        val packageName = "$packageName/com.example.africanaai.NotificationListenerServiceImpl"
        return enabledNotificationListeners.contains(packageName)
    }

    /**
     * Open Android Settings to grant notification access
     */
    private fun openNotificationAccessSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        startActivity(intent)
    }
}
