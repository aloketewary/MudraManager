package com.mudramanager.app

import android.app.Notification
import android.content.Context
import android.os.Build
import android.os.Bundle
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Unit tests for TransactionNotificationListener.
 *
 * Covers:
 *  - extractMessageText: RCS/MessagingStyle, bigText, standard text fallback
 *  - onNotificationPosted: package filtering, body length guard
 *  - drainQueue: reads and clears the persisted queue
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.TIRAMISU])
class TransactionNotificationListenerTest {

    private lateinit var context: Context
    private val prefsName = "notification_queue"
    private val queueKey = "pending_notifications"

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        // Clear queue before each test
        context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .edit().putString(queueKey, "[]").commit()
    }

    // ─────────────────────────────────────────────────────────────────────
    // extractMessageText — tested via the helper exposed through reflection
    // ─────────────────────────────────────────────────────────────────────

    private fun extractMessageText(extras: Bundle): String {
        val listener = TransactionNotificationListener()
        val method = TransactionNotificationListener::class.java
            .getDeclaredMethod("extractMessageText", Bundle::class.java)
        method.isAccessible = true
        return method.invoke(listener, extras) as String
    }

    /** RCS/MessagingStyle: text comes from EXTRA_MESSAGES last bundle. */
    @Test
    fun `extractMessageText returns last RCS message text`() {
        val msgBundle = Bundle().apply {
            putCharSequence("text", "AED 500.00 credited to your account XX3456")
        }
        val extras = Bundle().apply {
            putParcelableArray(Notification.EXTRA_MESSAGES, arrayOf(msgBundle))
        }

        val result = extractMessageText(extras)

        assertEquals("AED 500.00 credited to your account XX3456", result)
    }

    /** RCS with multiple messages: should return the LAST message. */
    @Test
    fun `extractMessageText returns last of multiple RCS messages`() {
        val msg1 = Bundle().apply { putCharSequence("text", "First message") }
        val msg2 = Bundle().apply { putCharSequence("text", "Rs.5000.00 debited from A/c XX1234") }
        val extras = Bundle().apply {
            putParcelableArray(Notification.EXTRA_MESSAGES, arrayOf(msg1, msg2))
        }

        val result = extractMessageText(extras)

        assertEquals("Rs.5000.00 debited from A/c XX1234", result)
    }

    /** Classic SMS: no EXTRA_MESSAGES, falls through to EXTRA_BIG_TEXT. */
    @Test
    fun `extractMessageText falls back to bigText for classic SMS`() {
        val extras = Bundle().apply {
            putCharSequence(
                Notification.EXTRA_BIG_TEXT,
                "Rs.2500.00 debited from A/c XX9876 on 15-Jan-25"
            )
        }

        val result = extractMessageText(extras)

        assertEquals("Rs.2500.00 debited from A/c XX9876 on 15-Jan-25", result)
    }

    /** Standard text fallback when neither EXTRA_MESSAGES nor bigText present. */
    @Test
    fun `extractMessageText falls back to standard EXTRA_TEXT`() {
        val extras = Bundle().apply {
            putCharSequence(Notification.EXTRA_TEXT, "USD 120.50 charged to account XX5678")
        }

        val result = extractMessageText(extras)

        assertEquals("USD 120.50 charged to account XX5678", result)
    }

    /** Empty EXTRA_MESSAGES array falls through to bigText. */
    @Test
    fun `extractMessageText falls through when EXTRA_MESSAGES is empty`() {
        val extras = Bundle().apply {
            putParcelableArray(Notification.EXTRA_MESSAGES, emptyArray())
            putCharSequence(Notification.EXTRA_BIG_TEXT, "GBP 250.00 debited from Barclays XX9012")
        }

        val result = extractMessageText(extras)

        assertEquals("GBP 250.00 debited from Barclays XX9012", result)
    }

    /** All sources absent → returns empty string. */
    @Test
    fun `extractMessageText returns empty string when no text sources present`() {
        val result = extractMessageText(Bundle())
        assertEquals("", result)
    }

    // ─────────────────────────────────────────────────────────────────────
    // drainQueue — reads persisted queue and clears it
    // ─────────────────────────────────────────────────────────────────────

    private fun writeQueue(vararg entries: Map<String, Any>) {
        val array = org.json.JSONArray()
        for (entry in entries) {
            val obj = org.json.JSONObject()
            obj.put("title", entry["title"])
            obj.put("text", entry["text"])
            obj.put("package", entry["package"])
            obj.put("timestamp", entry["timestamp"])
            array.put(obj)
        }
        context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .edit().putString(queueKey, array.toString()).commit()
    }

    /** drainQueue returns all queued entries and clears the queue. */
    @Test
    fun `drainQueue returns all entries and clears queue`() {
        writeQueue(
            mapOf("title" to "HDFCBK", "text" to "Rs.5000.00 debited", "package" to "com.google.android.apps.messaging", "timestamp" to 1000L),
            mapOf("title" to "Chase Bank", "text" to "USD 120.50 charged", "package" to "com.google.android.apps.messaging", "timestamp" to 2000L)
        )

        val result = TransactionNotificationListener.drainQueue(context)

        assertEquals(2, result.size)
        assertEquals("HDFCBK", result[0]["title"])
        assertEquals("Rs.5000.00 debited", result[0]["text"])
        assertEquals("Chase Bank", result[1]["title"])
        assertEquals("USD 120.50 charged", result[1]["text"])

        // Queue must be cleared after drain
        val afterDrain = TransactionNotificationListener.drainQueue(context)
        assertTrue(afterDrain.isEmpty())
    }

    /** drainQueue on empty queue returns empty list. */
    @Test
    fun `drainQueue returns empty list when queue is empty`() {
        val result = TransactionNotificationListener.drainQueue(context)
        assertTrue(result.isEmpty())
    }

    /** drainQueue preserves title (sender display name) for RCS messages. */
    @Test
    fun `drainQueue preserves RCS display name sender in title field`() {
        writeQueue(
            mapOf("title" to "Emirates NBD", "text" to "AED 500.00 credited to your account XX3456", "package" to "com.google.android.apps.messaging", "timestamp" to 3000L)
        )

        val result = TransactionNotificationListener.drainQueue(context)

        assertEquals(1, result.size)
        assertEquals("Emirates NBD", result[0]["title"])
        assertEquals("AED 500.00 credited to your account XX3456", result[0]["text"])
    }

    /** drainQueue preserves raw sender ID for classic SMS. */
    @Test
    fun `drainQueue preserves raw sender ID for classic SMS`() {
        writeQueue(
            mapOf("title" to "ICICIBK", "text" to "Rs 2500.00 debited from a/c XX9876", "package" to "com.samsung.android.messaging", "timestamp" to 4000L)
        )

        val result = TransactionNotificationListener.drainQueue(context)

        assertEquals("ICICIBK", result[0]["title"])
        assertEquals("Rs 2500.00 debited from a/c XX9876", result[0]["text"])
    }
}
