package com.zenqube.hungrilyfoods

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat

object HungrilyNotificationHelper {
    private const val CHANNEL_ID = "high_importance_channel"
    private const val CHANNEL_NAME = "Hungrily Order Notifications"
    private const val TAG = "HungrilyNotif"

    fun showCustomNotification(
        context: Context,
        orderId: String,
        title: String,
        body: String,
        otp: String?
    ) {
        try {
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Ensure channel exists
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Live order status updates from Hungrily."
                    enableLights(true)
                    lightColor = Color.parseColor("#FF6B35")
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 250, 100, 250)
                }
                notificationManager.createNotificationChannel(channel)
            }

            val intent = (context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, MainActivity::class.java)).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("order_id", orderId)
                putExtra("from_notification", true)
            }

            val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }

            val notifId = orderId.toIntOrNull() ?: (orderId.hashCode() and 0x7FFFFFFF)

            val pendingIntent = PendingIntent.getActivity(
                context,
                notifId,
                intent,
                pendingIntentFlags
            )

            val displayText = if (!otp.isNullOrEmpty() && !body.contains(otp)) {
                "$body (OTP: $otp)"
            } else {
                body
            }

            val builder = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentTitle(title)
                .setContentText(displayText)
                .setStyle(NotificationCompat.BigTextStyle().bigText(displayText))
                .setContentIntent(pendingIntent)
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_MESSAGE)
                .setColor(Color.parseColor("#FF6B35"))

            notificationManager.notify("hungrily_order", notifId, builder.build())
            Log.d(TAG, "Notification posted for order $orderId (id=$notifId)")
        } catch (e: Exception) {
            Log.e(TAG, "showCustomNotification FAILED for order $orderId: ${e.message}", e)
        }
    }

    // ── Meal Reminder Notification ────────────────────────────────────────────
    private const val MEAL_CHANNEL_ID   = "meal_reminder_channel"
    private const val MEAL_CHANNEL_NAME = "Meal Reminders"

    fun showMealReminderNotification(
        context: Context,
        isLunch: Boolean,
        title: String,
        body: String
    ) {
        try {
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    MEAL_CHANNEL_ID,
                    MEAL_CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Reminds you to order lunch and dinner on time."
                    enableLights(true)
                    lightColor = if (isLunch) Color.parseColor("#FF6B35")
                                 else         Color.parseColor("#7C3AED")
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 200, 100, 200)
                }
                notificationManager.createNotificationChannel(channel)
            }

            val intent = (context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, MainActivity::class.java)).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("from_meal_reminder", true)
                putExtra("is_lunch", isLunch)
            }
            val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            else
                PendingIntent.FLAG_UPDATE_CURRENT

            val notifId = if (isLunch) 9001 else 9002

            val pendingIntent = PendingIntent.getActivity(
                context,
                notifId,
                intent,
                pendingIntentFlags
            )

            val builder = NotificationCompat.Builder(context, MEAL_CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setContentIntent(pendingIntent)
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_REMINDER)
                .setColor(
                    if (isLunch) Color.parseColor("#FF6B35")
                    else         Color.parseColor("#7C3AED")
                )

            notificationManager.notify("hungrily_meal", notifId, builder.build())
            Log.d(TAG, "Meal reminder notification posted (id=$notifId, isLunch=$isLunch)")
        } catch (e: Exception) {
            Log.e(TAG, "showMealReminderNotification FAILED: ${e.message}", e)
        }
    }
}
