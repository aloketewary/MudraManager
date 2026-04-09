package com.mudramanager.app

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class TransactionNotificationListener : NotificationListenerService() {

    companion object {
        private const val PREFS_NAME = "notification_queue"
        private const val QUEUE_KEY = "pending_notifications"
        var methodChannel: MethodChannel? = null
        private val queueLock = Any()

        private val smsPackages = setOf(
            "com.google.android.apps.messaging",
            "com.samsung.android.messaging",
            "com.android.mms",
            "com.oneplus.mms",
            "com.xiaomi.mms",
            "com.miui.mms",
            "com.oppo.mms",
            "com.vivo.mms",
            "com.realme.mms",
            "com.asus.mms",
            "com.motorola.mms",
            "com.coloros.mms",
            "org.thoughtcrime.securesms",
        )

        fun drainQueue(context: Context): List<Map<String, Any>> {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val existing = prefs.getString(QUEUE_KEY, "[]")
            val array = JSONArray(existing)

            if (array.length() == 0) return emptyList()

            val result = mutableListOf<Map<String, Any>>()
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                result.add(mapOf(
                    "title" to obj.optString("title", ""),
                    "text" to obj.optString("text", ""),
                    "package" to obj.optString("package", ""),
                    "timestamp" to obj.optLong("timestamp", 0)
                ))
            }

            prefs.edit().putString(QUEUE_KEY, "[]").apply()
            return result
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn ?: return
        val packageName = sbn.packageName

        // Only process SMS app notifications
        if (!smsPackages.contains(packageName)) return
        if (packageName == applicationContext.packageName) return

        val extras = sbn.notification.extras
        val title = extras.getCharSequence("android.title")?.toString() ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: ""

        // Skip empty or very short messages (unlikely to be transactional)
        val body = text.ifEmpty { title }
        if (body.length < 10) return

        val timestamp = sbn.postTime

        val data = mapOf<String, Any>(
            "title" to title,
            "text" to text,
            "package" to packageName,
            "timestamp" to timestamp
        )

        // Always queue first to guarantee persistence
        queueNotification(data)

        // Then try to notify Flutter to drain (must be on main thread)
        try {
            Handler(Looper.getMainLooper()).post {
                methodChannel?.invokeMethod("onDrainQueue", null)
            }
        } catch (_: Exception) {}
    }

    private fun queueNotification(data: Map<String, Any>) {
        synchronized(queueLock) {
            val prefs = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val existing = prefs.getString(QUEUE_KEY, "[]")
            val array = JSONArray(existing)

            val obj = JSONObject()
            obj.put("title", data["title"])
            obj.put("text", data["text"])
            obj.put("package", data["package"])
            obj.put("timestamp", data["timestamp"])
            array.put(obj)

            // Cap queue at 1000 entries, drop oldest if exceeded
            while (array.length() > 1000) {
                array.remove(0)
            }

            prefs.edit().putString(QUEUE_KEY, array.toString()).apply()
        }
    }
}
