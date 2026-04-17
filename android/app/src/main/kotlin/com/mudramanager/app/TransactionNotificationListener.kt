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
        private const val TAG = "MudraSMS"
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
            "com.nothing.mms",
            "org.thoughtcrime.securesms",
            "com.truecaller",
        )

        // Packages that support RCS
        private val rcsPackages = setOf(
            "com.google.android.apps.messaging",
            "com.samsung.android.messaging",
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
                    "bigText" to obj.optString("bigText", ""),
                    "subText" to obj.optString("subText", ""),
                    "package" to obj.optString("package", ""),
                    "timestamp" to obj.optLong("timestamp", 0),
                    "hash" to obj.optString("hash", ""),
                    "corrId" to obj.optString("corrId", ""),
                    "isRcs" to obj.optBoolean("isRcs", false),
                ))
            }

            prefs.edit().putString(QUEUE_KEY, "[]").apply()
            return result
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        isListenerConnected = true
        android.util.Log.i(TAG, "Notification listener connected")
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

        val flags = sbn.notification.flags
        if (flags and Notification.FLAG_GROUP_SUMMARY != 0) return
        if (flags and Notification.FLAG_ONGOING_EVENT != 0) return

        val extras = sbn.notification.extras
        val title = extras.getCharSequence("android.title")?.toString() ?: ""
        val isRcs = rcsPackages.contains(packageName)

        // Extract ALL text fields — Dart will build the best rawBody
        val extracted = extractAllText(extras)
        val primaryText = extracted.primary
        val bigText = extracted.bigText
        val subText = extracted.subText

        val body = primaryText.ifEmpty { title }
        if (body.length < 5) return

        // Sender: always use title (sender ID for SMS, display name for RCS)
        val senderHint = if (title.isNotEmpty() && title.length < 50) title else "UNKNOWN"

        android.util.Log.d(TAG, "Processing: rcs=$isRcs sender='$senderHint' body='${body.take(80)}'")

        val normalized = normalize(body)
        val raw = "$senderHint|$normalized|$packageName"
        val hash = sha256(raw)
        val corrId = hash.take(8)

        val data = mapOf(
            "title" to senderHint,
            "text" to primaryText,
            "bigText" to bigText,
            "subText" to subText,
            "package" to packageName,
            "timestamp" to sbn.postTime,
            "hash" to hash,
            "corrId" to corrId,
            "isRcs" to isRcs,
        )

        android.util.Log.d(TAG, "[$corrId] Queued: sender='$senderHint' rcs=$isRcs")

        queueNotification(data)

        Handler(Looper.getMainLooper()).post {
            val channel = methodChannel
            if (channel == null) {
                android.util.Log.w(TAG, "Channel not ready, queue will be drained on app resume")
                return@post
            }
            try {
                channel.invokeMethod("onDrainQueue", null)
            } catch (e: Exception) {
                android.util.Log.e(TAG, "invokeMethod failed", e)
            }
        }
    }

    /**
     * Extracts all available text from notification extras.
     * Returns structured data so Dart can build the best rawBody.
     */
    private fun extractAllText(extras: Bundle): ExtractedText {
        var primary = ""
        var bigText = ""
        var subText = ""

        // 1. MessagingStyle (RCS primary source)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val messages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                extras.getParcelableArray(Notification.EXTRA_MESSAGES, Bundle::class.java)
            } else {
                @Suppress("DEPRECATION")
                extras.getParcelableArray(Notification.EXTRA_MESSAGES)
            }

            if (messages != null && messages.isNotEmpty()) {
                val last = messages.last()
                if (last is Bundle) {
                    val msgText = last.getCharSequence("text")?.toString()
                        ?: last.getString("text")
                        ?: last.getCharSequence("message")?.toString()
                        ?: last.getString("message")
                    if (!msgText.isNullOrBlank()) primary = msgText
                }

                // If primary is empty, try concatenating all
                if (primary.isBlank()) {
                    val allTexts = messages.mapNotNull { msg ->
                        if (msg is Bundle) {
                            msg.getCharSequence("text")?.toString()
                                ?: msg.getString("text")
                                ?: msg.getCharSequence("message")?.toString()
                                ?: msg.getString("message")
                        } else null
                    }.filter { it.isNotBlank() }
                    if (allTexts.isNotEmpty()) primary = allTexts.last()
                }
            }
        }

        // 2. BigText (expanded notification — often has FULL message for both SMS and RCS)
        val bt = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
        if (!bt.isNullOrBlank()) {
            bigText = bt
            if (primary.isBlank()) primary = bt
        }

        // 3. SubText (SIM name on dual-SIM, or sender info on some RCS)
        val st = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()
        if (!st.isNullOrBlank()) subText = st

        // 4. Summary text
        val summary = extras.getCharSequence(Notification.EXTRA_SUMMARY_TEXT)?.toString()
        if (!summary.isNullOrBlank() && primary.isBlank()) primary = summary

        // 5. Info text (Samsung RCS)
        val info = extras.getCharSequence(Notification.EXTRA_INFO_TEXT)?.toString()
        if (!info.isNullOrBlank() && primary.isBlank()) primary = info

        // 6. Standard EXTRA_TEXT (final fallback)
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
        if (!text.isNullOrBlank() && primary.isBlank()) primary = text

        return ExtractedText(primary, bigText, subText)
    }

    private data class ExtractedText(
        val primary: String,
        val bigText: String,
        val subText: String,
    )

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
                put("bigText", data["bigText"])
                put("subText", data["subText"])
                put("package", data["package"])
                put("timestamp", data["timestamp"])
                put("hash", data["hash"])
                put("corrId", data["corrId"])
                put("isRcs", data["isRcs"])
            })

            prefs.edit().putString(QUEUE_KEY, trimmed.toString()).apply()
        }
    }
}
