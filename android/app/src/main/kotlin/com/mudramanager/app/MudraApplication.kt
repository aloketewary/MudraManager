package com.mudramanager.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.app.FlutterApplication

class MudraApplication : FlutterApplication() {

    override fun onCreate() {
        super.onCreate()
        createSilentWorkManagerChannel()
        cancelStaleNotifications()
    }

    private fun createSilentWorkManagerChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NotificationManager::class.java)

            // Create a silent channel that WorkManager's foreground service can use
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Background Tasks",
                NotificationManager.IMPORTANCE_MIN
            ).apply {
                description = "Silent channel for background processing"
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
                setSound(null, null)
            }
            nm.createNotificationChannel(channel)

            // Also delete any old/unknown channels that may be showing stale notifications
            val knownChannels = setOf(
                "mudra_channel_id", "sms_transactions", "budget_alerts",
                "bill_reminders", "summaries", "gamification",
                "daily_reminder_channel", "weekly_summary_channel",
                "goal_reminder_channel", "streak_reminder_channel",
                "pending_transactions", "smart_alerts", "re_engagement",
                CHANNEL_ID,
            )
            for (ch in nm.notificationChannels) {
                if (!knownChannels.contains(ch.id)) {
                    nm.deleteNotificationChannel(ch.id)
                }
            }
        }
    }

    /**
     * Cancel any stale/orphaned notifications from previous builds
     * that may show generic text like "Recurring transaction notification".
     */
    private fun cancelStaleNotifications() {
        val nm = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            for (sbn in nm.activeNotifications) {
                val title = sbn.notification.extras?.getCharSequence("android.title")?.toString() ?: ""
                val text = sbn.notification.extras?.getCharSequence("android.text")?.toString() ?: ""
                // Cancel notifications with generic/stale text that shouldn't be showing
                if (title.contains("Recurring transaction", ignoreCase = true) ||
                    text.contains("Processing recurring", ignoreCase = true)) {
                    nm.cancel(sbn.id)
                }
            }
        }
    }

    companion object {
        const val CHANNEL_ID = "mudra_background_silent"
    }
}
