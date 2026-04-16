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
        @Volatile
        private var isListenerConnected = false

        fun ensureRunning(context: Context) {
            if (!isListenerConnected && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                try {
                    requestRebind(android.content.ComponentName(context, TransactionNotificationListener::class.java))
                } catch (_: Exception) {}
            }
        }

        private val smsPackages = setOf(
            // Google Messages (SMS + RCS)
            "com.google.android.apps.messaging",
            // Samsung Messages (SMS + RCS on Samsung)
            "com.samsung.android.messaging",
            // AOSP/Stock SMS
            "com.android.mms",
            // OEM SMS apps
            "com.oneplus.mms",
            "com.xiaomi.mms",
            "com.miui.mms",
            "com.oppo.mms",
            "com.vivo.mms",
            "com.realme.mms",
            "com.asus.mms",
            "com.motorola.mms",
            "com.coloros.mms",
            // Nothing Phone
            "com.nothing.mms",
            // Signal (SMS fallback)
            "org.thoughtcrime.securesms",
            // Truecaller (SMS mode)
            "com.truecaller",
        )

        fun getSupportedPackages(): Set<String> = smsPackages

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
                    "hash" to obj.optString("hash", ""),
                    "corrId" to obj.optString("corrId", "")
                ))
            }

            prefs.edit().putString(QUEUE_KEY, "[]").apply()
            return result
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        isListenerConnected = true
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        isListenerConnected = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            requestRebind(android.content.ComponentName(applicationContext, TransactionNotificationListener::class.java))
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn ?: return

        val packageName = sbn.packageName
        if (!smsPackages.contains(packageName)) return
        if (packageName == applicationContext.packageName) return

        // Skip group summary notifications — they duplicate individual messages
        val flags = sbn.notification.flags
        if (flags and Notification.FLAG_GROUP_SUMMARY != 0) {
            android.util.Log.d("MudraSMS", "Skipping group summary notification")
            return
        }

        // Skip ongoing/foreground notifications (not actual messages)
        if (flags and Notification.FLAG_ONGOING_EVENT != 0) return

        val extras = sbn.notification.extras
        val title = extras.getCharSequence("android.title")?.toString() ?: ""
        val text = extractMessageText(extras)

        val body = if (text.isNotEmpty()) text else title
        if (body.length < 5) return

        // Sender detection:
        // SMS: title = sender ID ("HDFCBK", "AD-ICICIB") — always use this
        // RCS: title = display name ("HDFC Bank") — also fine, parsers use .contains()
        // EXTRA_SUB_TEXT is often the SIM name ("SIM 1", "Jio") on dual-SIM — never use as sender
        val senderHint = if (title.isNotEmpty() && title.length < 50) {
            title
        } else {
            "UNKNOWN"
        }

        android.util.Log.d("MudraSMS", "Processing: sender='$senderHint' body='${body.take(80)}'")

        val normalized = normalize(body)
        val raw = "$senderHint|$normalized|$packageName"
        val hash = sha256(raw)

        val corrId = hash.take(8)

        val data = mapOf(
            "title" to senderHint,
            "text" to text,
            "package" to packageName,
            "timestamp" to sbn.postTime,
            "hash" to hash,
            "corrId" to corrId
        )

        android.util.Log.d("MudraSMS", "[$corrId] Queued: sender='$senderHint'")

        queueNotification(data)

        Handler(Looper.getMainLooper()).post {
            val channel = methodChannel
            if (channel == null) {
                android.util.Log.w("NotifListener", "Channel not ready, queue will be drained later")
                return@post
            }

            try {
                channel.invokeMethod("onDrainQueue", null)
            } catch (e: Exception) {
                android.util.Log.e("NotifListener", "invokeMethod failed", e)
            }
        }
    }

    /**
     * Extract message text from notification extras.
     * Handles:
     *  - RCS/MessagingStyle (android.messages) — primary for Google Messages RCS
     *  - BigText (expanded notification) — common for SMS
     *  - SummaryText — fallback for some RCS implementations
     *  - Standard EXTRA_TEXT — final fallback
     */
    private fun extractMessageText(extras: Bundle): String {
        // 1. Try MessagingStyle messages (RCS, chat messages)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val messages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                extras.getParcelableArray(Notification.EXTRA_MESSAGES, Bundle::class.java)
            } else {
                @Suppress("DEPRECATION")
                extras.getParcelableArray(Notification.EXTRA_MESSAGES)
            }

            if (messages != null && messages.isNotEmpty()) {
                // Get the LAST message only (most recent in conversation)
                val last = messages.last()
                if (last is Bundle) {
                    val msgText = last.getCharSequence("text")?.toString()
                        ?: last.getString("text")
                        ?: last.getCharSequence("message")?.toString()
                        ?: last.getString("message")
                    if (!msgText.isNullOrBlank()) return msgText
                }

                // Fallback: concatenate all messages if last is empty
                val allTexts = messages.mapNotNull { msg ->
                    if (msg is Bundle) {
                        msg.getCharSequence("text")?.toString()
                            ?: msg.getString("text")
                            ?: msg.getCharSequence("message")?.toString()
                            ?: msg.getString("message")
                    } else null
                }.filter { it.isNotBlank() }

                if (allTexts.isNotEmpty()) {
                    return allTexts.last() // Still prefer last
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

            val trimmed = if (array.length() >= maxSize) {
                val newArray = JSONArray()
                val start = array.length() - maxSize + 1
                for (i in start until array.length()) {
                    newArray.put(array.get(i))
                }
                newArray
            } else array

            trimmed.put(JSONObject().apply {
                put("title", data["title"])
                put("text", data["text"])
                put("package", data["package"])
                put("timestamp", data["timestamp"])
                put("hash", data["hash"])
                put("corrId", data["corrId"])
            })

            prefs.edit().putString(QUEUE_KEY, trimmed.toString()).apply()
        }
    }
}
