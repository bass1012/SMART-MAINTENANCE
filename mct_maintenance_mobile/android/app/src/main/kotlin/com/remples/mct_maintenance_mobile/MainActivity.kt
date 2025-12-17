package com.remples.mct_maintenance_mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Créer les canaux de notification pour Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            
            // Canal par défaut pour les notifications générales
            val defaultChannel = NotificationChannel(
                "default_channel",
                "Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications MCT Maintenance"
                enableVibration(true)
                enableLights(true)
            }
            
            // Canal pour les messages de chat
            val chatChannel = NotificationChannel(
                "chat_channel",
                "Messages",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Messages du support MCT Maintenance"
                enableVibration(true)
                enableLights(true)
            }
            
            // Enregistrer les canaux
            notificationManager.createNotificationChannel(defaultChannel)
            notificationManager.createNotificationChannel(chatChannel)
        }
    }
}
