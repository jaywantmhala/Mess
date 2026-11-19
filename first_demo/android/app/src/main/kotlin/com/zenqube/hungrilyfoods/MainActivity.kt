package com.zenqube.hungrilyfoods

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.zenqube.hungrilyfoods/notifications"
    private var methodChannel: MethodChannel? = null
    private var pendingOrderId: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "showCustomNotification" -> {
                    val orderId = call.argument<String>("orderId") ?: ""
                    val title = call.argument<String>("title") ?: ""
                    val body = call.argument<String>("body") ?: ""
                    val otp = call.argument<String>("otp")
                    
                    HungrilyNotificationHelper.showCustomNotification(
                        context = this,
                        orderId = orderId,
                        title = title,
                        body = body,
                        otp = otp
                    )
                    result.success(true)
                }
                "showMealReminder" -> {
                    val isLunch = call.argument<Boolean>("isLunch") ?: true
                    val title   = call.argument<String>("title")   ?: ""
                    val body    = call.argument<String>("body")    ?: ""
                    HungrilyNotificationHelper.showMealReminderNotification(
                        context = this,
                        isLunch = isLunch,
                        title   = title,
                        body    = body
                    )
                    result.success(true)
                }
                "checkInitialNotification" -> {
                    val orderId = pendingOrderId ?: getOrderIdFromIntent(intent)
                    pendingOrderId = null // Clear after checked
                    result.success(orderId)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val orderId = getOrderIdFromIntent(intent)
        if (orderId != null) {
            pendingOrderId = orderId
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val orderId = getOrderIdFromIntent(intent)
        if (orderId != null) {
            methodChannel?.invokeMethod("onNotificationTap", orderId)
        }
    }

    private fun getOrderIdFromIntent(intent: Intent?): String? {
        if (intent == null) return null
        if (intent.getBooleanExtra("from_notification", false)) {
            return intent.getStringExtra("order_id")
        }
        return null
    }
}
