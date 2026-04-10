package com.mudramanager.app

import android.app.Notification
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.security.MessageDigest

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
            "com.example.myapplication",
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
                    "timestamp" to obj.optLong("timestamp", 0),
                    "hash" to obj.optString("hash", "")
                ))
            }

            prefs.edit().putString(QUEUE_KEY, "[]").apply()
            return result
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
    sbn ?: return

    val packageName = sbn.packageName
    if (!smsPackages.contains(packageName)) return
    if (packageName == applicationContext.packageName) return

    val extras = sbn.notification.extras
    val title = extras.getCharSequence("android.title")?.toString() ?: ""
    val text = extractMessageText(extras)

    val body = if (text.isNotEmpty()) text else title
    if (body.length < 5) return

    val isBankMsg = body.contains("debited", true) ||
            body.contains("credited", true) ||
            body.contains("spent", true) ||
            body.contains("upi", true)

    if (!isBankMsg) return

    val normalized = normalize(body)
    val raw = "$title|$normalized|$packageName"
    val hash = sha256(raw)

    val data = mapOf(
        "title" to title,
        "text" to text,
        "package" to packageName,
        "timestamp" to sbn.postTime,
        "hash" to hash
    )

    queueNotification(data)

    // Notify Flutter to drain immediately
    try {
        Handler(Looper.getMainLooper()).post {
            methodChannel?.invokeMethod("onDrainQueue", null)
        }
    } catch (_: Exception) {}
}

    /**
     * Extract message text from notification extras.
     * RCS/chat messages use MessagingStyle which stores text in android.messages
     * rather than android.text.
     */
    private fun extractMessageText(extras: Bundle): String {
        // 1. Try MessagingStyle messages (RCS, chat messages)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val messages = extras.getParcelableArray(Notification.EXTRA_MESSAGES)
            if (messages != null && messages.isNotEmpty()) {
                // Try to get the last message's text
                val last = messages.last()
                if (last is Bundle) {
                    val msgText = last.getCharSequence("text")?.toString()
                        ?: last.getString("text")
                        ?: last.getCharSequence("message")?.toString()
                        ?: last.getString("message")
                    if (!msgText.isNullOrBlank()) return msgText
                }

                // If no text in last message, try to concatenate all messages
                val allTexts = messages.mapNotNull { msg ->
                    if (msg is Bundle) {
                        msg.getCharSequence("text")?.toString()
                            ?: msg.getString("text")
                            ?: msg.getCharSequence("message")?.toString()
                            ?: msg.getString("message")
                    } else null
                }.filter { it.isNotBlank() }

                if (allTexts.isNotEmpty()) {
                    return allTexts.joinToString("\n")
                }
            }
        }

        // 2. Try bigText (expanded notification text, often has full SMS/RCS body)
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
        if (!bigText.isNullOrBlank()) return bigText

        // 3. Try summary text (sometimes used for RCS)
        val summary = extras.getCharSequence(Notification.EXTRA_SUMMARY_TEXT)?.toString()
        if (!summary.isNullOrBlank()) return summary

        // 4. Standard text
        return extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
    }

    private fun normalize(text: String): String {
    return text
        .lowercase()
        .replace("\n", " ")
        .replace("rs.", "")
        .replace("rs", "")
        .replace(",", "")
        .replace("\\s+".toRegex(), " ")
        .trim()
}

    private fun sha256(input: String): String {
        return MessageDigest.getInstance("SHA-256")
            .digest(input.toByteArray())
            .joinToString("") { "%02x".format(it) }
    }

    private fun queueNotification(data: Map<String, Any>) {
        synchronized(queueLock) {
            val prefs = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val existing = prefs.getString(QUEUE_KEY, "[]") ?: "[]"
            val array = JSONArray(existing)

            // Cap queue before adding — drop oldest if at limit
            val maxSize = 1000
            val startIndex = if (array.length() >= maxSize) array.length() - maxSize + 1 else 0
            val trimmed = if (startIndex > 0) {
                val newArray = JSONArray()
                for (i in startIndex until array.length()) newArray.put(array.get(i))
                newArray
            } else array

            trimmed.put(JSONObject().apply {
                put("title", data["title"])
                put("text", data["text"])
                put("package", data["package"])
                put("timestamp", data["timestamp"])
                put("hash", data["hash"])
            })

            prefs.edit().putString(QUEUE_KEY, trimmed.toString()).apply()
        }
    }
}
