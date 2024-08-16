package com.zulip.flutter

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.annotation.Keep
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.graphics.drawable.IconCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin

private const val TAG = "ZulipPlugin"

fun toAndroidPerson(person: Person): androidx.core.app.Person {
    return androidx.core.app.Person.Builder().apply {
        person.iconBitmap?.let { setIcon(IconCompat.createWithData(it, 0, it.size)) }
        setKey(person.key)
        setName(person.name)
    }.build()
}

fun toPigeonPerson(person: androidx.core.app.Person): Person {
    return Person(
        // The API doesn't provide a way to retrieve the icon data,
        // so we set this to null.
        //
        // Notably, Android retains a limited number [1] of messages
        // in the messaging style, and it also retains the icon data
        // for persons within those messages. Therefore, there's no
        // need to include the person's icon data in each message.
        // Only one icon data instance is needed for each unique
        // person's key in the retained messages.
        //
        // [1]: https://developer.android.com/reference/androidx/core/app/NotificationCompat.MessagingStyle#MAXIMUM_RETAINED_MESSAGES()
        null,
        person.key!!,
        person.name!!.toString(),
    )
}

private class AndroidNotificationHost(val context: Context)
        : AndroidNotificationHostApi {
    override fun createNotificationChannel(channel: NotificationChannel) {
        val notificationChannel = NotificationChannelCompat
            .Builder(channel.id, channel.importance.toInt()).apply {
                channel.name?.let { setName(it) }
                channel.lightsEnabled?.let { setLightsEnabled(it) }
                channel.vibrationPattern?.let { setVibrationPattern(it) }
            }.build()
        NotificationManagerCompat.from(context).createNotificationChannel(notificationChannel)
    }

    @SuppressLint(
        // If permission is missing, `notify` will throw an exception.
        // Which hopefully will propagate to Dart, and then it's up to Dart code to handle it.
        "MissingPermission",
        // For `getIdentifier`.  TODO make a cleaner API.
        "DiscouragedApi")
    override fun notify(
        tag: String?,
        id: Long,
        autoCancel: Boolean?,
        channelId: String,
        color: Long?,
        contentIntent: PendingIntent?,
        contentText: String?,
        contentTitle: String?,
        extras: Map<String?, String?>?,
        groupKey: String?,
        inboxStyle: InboxStyle?,
        isGroupSummary: Boolean?,
        messagingStyle: MessagingStyle?,
        number: Long?,
        smallIconResourceName: String?
    ) {
        val notification = NotificationCompat.Builder(context, channelId).apply {
            autoCancel?.let { setAutoCancel(it) }
            color?.let { setColor(it.toInt()) }
            contentIntent?.let { setContentIntent(
                android.app.PendingIntent.getActivity(context,
                    it.requestCode.toInt(),
                    Intent(context, MainActivity::class.java).apply {
                        // This action name and extra name are special to
                        // FlutterLocalNotificationsPlugin, which handles receiving the Intent.
                        // TODO take care of receiving the notification-opened Intent ourselves
                        action = "SELECT_NOTIFICATION"
                        putExtra("payload", it.intentPayload)
                    },
                    it.flags.toInt())
            ) }
            contentText?.let { setContentText(it) }
            contentTitle?.let { setContentTitle(it) }
            extras?.let { setExtras(
                Bundle().apply { it.forEach { (k, v) -> putString(k, v) } } ) }
            groupKey?.let { setGroup(it) }
            inboxStyle?.let { setStyle(
                NotificationCompat.InboxStyle()
                    .setSummaryText(it.summaryText)
            ) }
            isGroupSummary?.let { setGroupSummary(it) }
            messagingStyle?.let { messagingStyle ->
                val style = NotificationCompat.MessagingStyle(toAndroidPerson(messagingStyle.user))
                    .setConversationTitle(messagingStyle.conversationTitle)
                    .setGroupConversation(messagingStyle.isGroupConversation)
                messagingStyle.messages.forEach { it?.let {
                    style.addMessage(NotificationCompat.MessagingStyle.Message(
                        it.text,
                        it.timestampMs,
                        toAndroidPerson(it.person),
                    ))
                } }
                setStyle(style)
            }
            number?.let { setNumber(it.toInt()) }
            smallIconResourceName?.let { setSmallIcon(context.resources.getIdentifier(
                it, "drawable", context.packageName)) }
        }.build()
        NotificationManagerCompat.from(context).notify(tag, id.toInt(), notification)
    }

    override fun getActiveNotificationMessagingStyleByTag(tag: String): MessagingStyle? {
        val activeNotification = NotificationManagerCompat.from(context)
            .activeNotifications
            .find { it.tag == tag }
        activeNotification?.notification?.let { notification ->
            NotificationCompat.MessagingStyle
                .extractMessagingStyleFromNotification(notification)
                ?.let { style ->
                    return MessagingStyle(
                        toPigeonPerson(style.user),
                        style.conversationTitle!!.toString(),
                        style.messages.map { MessagingStyleMessage(
                            it.text!!.toString(),
                            it.timestamp,
                            toPigeonPerson(it.person!!)
                        ) },
                        style.isGroupConversation,
                    )
                }
        }
        return null
    }

    override fun getActiveNotifications(desiredExtras: List<String>): List<StatusBarNotification> {
        return NotificationManagerCompat.from(context).activeNotifications.map {
            StatusBarNotification(
                it.id.toLong(),
                it.tag,
                Notification(
                    it.notification.group,
                    desiredExtras
                        .associateWith { key -> it.notification.extras.getString(key) }
                        .filter { entry -> entry.value != null }
                ),
            )
        }
    }

    override fun cancel(tag: String?, id: Long) {
        NotificationManagerCompat.from(context).cancel(tag, id.toInt())
    }
}

/** A Flutter plugin for the Zulip app's ad-hoc needs. */
// @Keep is needed because this class is used only
// from ZulipShimPlugin, via reflection.
@Keep
class ZulipPlugin : FlutterPlugin { // TODO ActivityAware too?
    private var notificationHost: AndroidNotificationHost? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "Attaching to Flutter engine.")
        notificationHost = AndroidNotificationHost(binding.applicationContext)
        AndroidNotificationHostApi.setUp(binding.binaryMessenger, notificationHost)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        if (notificationHost == null) {
            Log.wtf(TAG, "Already detached from the engine.")
            return
        }
        AndroidNotificationHostApi.setUp(binding.binaryMessenger, null)
        notificationHost = null
    }
}
