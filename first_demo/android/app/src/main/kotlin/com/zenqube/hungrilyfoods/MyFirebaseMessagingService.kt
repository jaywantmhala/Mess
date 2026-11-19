package com.zenqube.hungrilyfoods

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        val data = remoteMessage.data
        val orderId: String? = data["order_id"]
        val status: String? = data["status"]

        val title: String = if (status != null) {
            getStatusTitle(status)
        } else {
            data["title"] ?: remoteMessage.notification?.title ?: "Hungrily Foods"
        }

        val body: String = data["body"] ?: remoteMessage.notification?.body ?: "You have a new update."

        var finalOtp: String? = data["otp"]
        if (finalOtp.isNullOrEmpty()) {
            val match = Regex("""\b\d{4}\b""").find(body)
            finalOtp = match?.value
        }

        HungrilyNotificationHelper.showCustomNotification(
            context = this,
            orderId = orderId ?: "",
            title = title,
            body = body,
            otp = finalOtp
        )
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
    }

    private fun getStatusTitle(status: String): String = when (status) {
        "created_order" -> "Order Placed!"
        "accepted"      -> "Order Accepted!"
        "preparing"     -> "Chef is Cooking!"
        "ready"         -> "Out for Delivery!"
        "completed"     -> "Order Delivered!"
        else            -> "Order Updated!"
    }
}
