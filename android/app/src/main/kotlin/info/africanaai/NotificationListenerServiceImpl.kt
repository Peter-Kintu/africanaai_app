package info.africanaai

import android.app.Notification
import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Notification Listener Service for monitoring WhatsApp, Telegram, and Messenger messages
 * Bridges Android notifications to Flutter for local Secretary processing
 */
class NotificationListenerServiceImpl : NotificationListenerService() {
    
    companion object {
        private const val TAG = "NotificationListener"
        private const val CHANNEL_ID = "info.africanaai/notifications"
        private var methodChannel: MethodChannel? = null

        fun setMethodChannel(channel: MethodChannel) {
            methodChannel = channel
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        
        if (sbn == null) return
        
        val notification = sbn.notification
        val extras = notification.extras
        
        // Extract notification details
        val title = extras.getString(Notification.EXTRA_TITLE) ?: "Unknown"
        val text = extras.getString(Notification.EXTRA_TEXT) ?: ""
        val subText = extras.getString(Notification.EXTRA_SUB_TEXT) ?: ""
        val packageName = sbn.packageName
        
        Log.d(TAG, "Notification from ${'$'}packageName: ${'$'}title - ${'$'}text")
        
        // Check if notification is from messaging apps
        val isMessenger = isFromMessengerApp(packageName)
        
        if (isMessenger) {
            sendToFlutter(
                packageName = packageName,
                title = title,
                content = text.ifEmpty { subText },
                sender = extractSender(title, packageName)
            )
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
        Log.d(TAG, "Notification removed: ${'$'}{sbn?.packageName}")
    }

    /**
     * Check if notification is from a messaging app
     */
    private fun isFromMessengerApp(packageName: String): Boolean {
        return packageName.contains("whatsapp", ignoreCase = true) ||
               packageName.contains("telegram", ignoreCase = true) ||
               packageName.contains("messenger", ignoreCase = true) ||
               packageName.contains("threema", ignoreCase = true) ||
               packageName.contains("signal", ignoreCase = true)
    }

    /**
     * Extract sender name from notification title
     */
    private fun extractSender(title: String, packageName: String): String {
        return when {
            title.contains(":") -> title.substringBefore(":").trim()
            packageName.contains("whatsapp") -> title.takeWhile { it != ',' }
            else -> title
        }
    }

    /**
     * Send notification data to Flutter via Method Channel
     */
    private fun sendToFlutter(
        packageName: String,
        title: String,
        content: String,
        sender: String
    ) {
        methodChannel?.invokeMethod(
            "onNotification",
            mapOf(
                "packageName" to packageName,
                "title" to title,
                "text" to content,
                "sender" to sender,
                "timestamp" to System.currentTimeMillis()
            )
        )
    }
}
