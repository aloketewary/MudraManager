package com.mudramanager.app

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.mudramanager.app/widget"
    private var methodChannel: MethodChannel? = null

    override fun onResume() {
        super.onResume()
        TransactionNotificationListener.ensureRunning(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Existing widget channel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "getWidgetAction") {
                val action = intent?.action ?: intent?.getStringExtra("widget_action")
                result.success(action)
            } else {
                result.notImplemented()
            }
        }
        
        handleIntent(intent)

        // Notification listener channel
        val notifChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.mudramanager.app/notifications"
        )
        TransactionNotificationListener.methodChannel = notifChannel

        notifChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isListenerEnabled" -> {
                    val enabled = android.provider.Settings.Secure.getString(
                        contentResolver,
                        "enabled_notification_listeners"
                    )?.contains(packageName) == true
                    result.success(enabled)
                }
                "openListenerSettings" -> {
                    startActivity(Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS"))
                    result.success(null)
                }
                "drainQueue" -> {
                    val queued = TransactionNotificationListener.drainQueue(applicationContext)
                    result.success(queued)
                }
                else -> result.notImplemented()
            }
        }

    }


    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val action = intent?.action ?: intent?.getStringExtra("widget_action")
        if (action != null) {
            methodChannel?.invokeMethod("widgetAction", action)
        }
    }

}