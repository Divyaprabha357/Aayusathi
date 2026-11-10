package com.example.aayusathi

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.aayusathi/patient_notifications"
    private val PERMISSION_REQUEST_CODE = 1010
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "createNotificationChannel" -> {
                    val channelId = call.argument<String>("channelId") ?: "aayusathi_followups"
                    val channelName = call.argument<String>("channelName") ?: "AAYUSATHI Follow-ups"
                    val channelDescription = call.argument<String>("channelDescription") ?: "Follow-up visit reminders"
                    createNotificationChannel(channelId, channelName, channelDescription)
                    result.success(true)
                }
                "requestPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
                            result.success(true)
                        } else {
                            pendingPermissionResult = result
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                                PERMISSION_REQUEST_CODE
                            )
                        }
                    } else {
                        val enabled = NotificationManagerCompat.from(this).areNotificationsEnabled()
                        result.success(enabled)
                    }
                }
                "areNotificationsEnabled" -> {
                    val enabled = NotificationManagerCompat.from(this).areNotificationsEnabled()
                    result.success(enabled)
                }
                "openNotificationSettings" -> {
                    val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        }
                    } else {
                        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.fromParts("package", packageName, null)
                        }
                    }
                    startActivity(intent)
                    result.success(true)
                }
                "scheduleNotification" -> {
                    val id = call.argument<Int>("id") ?: 1001
                    val title = call.argument<String>("title") ?: "AAYUSATHI Follow-up Reminder"
                    val body = call.argument<String>("body") ?: "Your follow-up visit is scheduled for tomorrow."
                    val triggerTimestamp = call.argument<Long>("triggerTimestamp") ?: (System.currentTimeMillis() + 60000)
                    val payload = call.argument<String>("payload") ?: ""

                    scheduleNotification(id, title, body, triggerTimestamp, payload)
                    result.success(true)
                }
                "cancelNotification" -> {
                    val id = call.argument<Int>("id") ?: 1001
                    cancelNotification(id)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun createNotificationChannel(channelId: String, name: String, desc: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(channelId, name, importance).apply {
                description = desc
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun scheduleNotification(id: Int, title: String, body: String, triggerTimestamp: Long, payload: String) {
        val intent = Intent(this, NotificationReceiver::class.java).apply {
            putExtra("id", id)
            putExtra("title", title)
            putExtra("body", body)
            putExtra("payload", payload)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager

        if (triggerTimestamp <= System.currentTimeMillis()) {
            // Trigger immediately if scheduled time has arrived
            val receiver = NotificationReceiver()
            receiver.onReceive(this, intent)
        } else {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTimestamp, pendingIntent)
                } else {
                    alarmManager.set(AlarmManager.RTC_WAKEUP, triggerTimestamp, pendingIntent)
                }
            } catch (e: Exception) {
                alarmManager.set(AlarmManager.RTC_WAKEUP, triggerTimestamp, pendingIntent)
            }
        }
    }

    private fun cancelNotification(id: Int) {
        val intent = Intent(this, NotificationReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pendingIntent)
        NotificationManagerCompat.from(this).cancel(id)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }
}
