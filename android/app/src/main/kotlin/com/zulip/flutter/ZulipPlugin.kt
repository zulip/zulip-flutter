package com.zulip.flutter

import android.annotation.SuppressLint
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.provider.MediaStore.Audio.Media as AudioStore
import android.util.Log
import androidx.annotation.Keep
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.graphics.drawable.IconCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import androidx.core.net.toUri

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
    // The directory we store our notification sounds into,
    // expressed as a relative path suitable for:
    //   https://developer.android.com/reference/kotlin/android/provider/MediaStore.MediaColumns#RELATIVE_PATH:kotlin.String
    val notificationSoundsDirectoryPath = "${Environment.DIRECTORY_NOTIFICATIONS}/Zulip/"

    class ResolverFailedException(msg: String) : RuntimeException(msg)

    override fun createNotificationChannel(channel: NotificationChannel) {
        val notificationChannel = NotificationChannelCompat
            .Builder(channel.id, channel.importance.toInt()).apply {
                channel.name?.let { setName(it) }
                channel.lightsEnabled?.let { setLightsEnabled(it) }
                channel.soundUrl?.let {
                    setSound(it.toUri(),
                        AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_NOTIFICATION).build())
                }
                channel.vibrationPattern?.let { setVibrationPattern(it) }
            }.build()
        NotificationManagerCompat.from(context).createNotificationChannel(notificationChannel)
    }

    override fun getNotificationChannels(): List<NotificationChannel> {
        return NotificationManagerCompat.from(context)
            .notificationChannelsCompat
            .map { NotificationChannel(
                id = it.id,
                importance =  it.importance.toLong(),
                name = it.name?.toString(),
                lightsEnabled = it.shouldShowLights()
            ) }
    }

    override fun deleteNotificationChannel(channelId: String) {
        NotificationManagerCompat.from(context).deleteNotificationChannel(channelId)
    }

    override fun listStoredSoundsInNotificationsDirectory(): List<StoredNotificationSound> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            throw UnsupportedOperationException()
        }

        // Query and cursor-loop based on:
        //   https://developer.android.com/training/data-storage/shared/media#query-collection
        val collection = AudioStore.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val projection = arrayOf(AudioStore._ID, AudioStore.DISPLAY_NAME, AudioStore.OWNER_PACKAGE_NAME)
        val selection = "${AudioStore.RELATIVE_PATH}=?"
        val selectionArgs = arrayOf(notificationSoundsDirectoryPath)
        val sortOrder = "${AudioStore._ID} ASC"

        val sounds = mutableListOf<StoredNotificationSound>()
        val cursor = context.contentResolver.query(
            collection,
            projection,
            selection,
            selectionArgs,
            sortOrder,
        ) ?: throw ResolverFailedException("resolver.query failed")
        cursor.use {
            val idColumn = cursor.getColumnIndexOrThrow(AudioStore._ID)
            val nameColumn = cursor.getColumnIndexOrThrow(AudioStore.DISPLAY_NAME)
            val ownerColumn = cursor.getColumnIndexOrThrow(AudioStore.OWNER_PACKAGE_NAME)
            while (cursor.moveToNext()) {
                val id = cursor.getLong(idColumn)
                val fileName = cursor.getString(nameColumn)
                val ownerPackageName = cursor.getString(ownerColumn)

                val contentUrl = ContentUris.withAppendedId(collection, id)
                sounds.add(StoredNotificationSound(
                    fileName = fileName,
                    isOwned = context.packageName == ownerPackageName,
                    contentUrl = contentUrl.toString()
                ))
            }
        }
        return sounds
    }

    @SuppressLint(
        // For `getIdentifier`.  TODO make a cleaner API.
        "DiscouragedApi")
    override fun copySoundResourceToMediaStore(
        targetFileDisplayName: String,
        sourceResourceName: String
    ): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            throw UnsupportedOperationException()
        }

        class ResolverFailedException(msg: String) : RuntimeException(msg)

        val resolver = context.contentResolver
        val collection = AudioStore.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)

        // Based on: https://developer.android.com/training/data-storage/shared/media#add-item
        val url = resolver.insert(collection, ContentValues().apply {
            put(AudioStore.DISPLAY_NAME, targetFileDisplayName)
            put(AudioStore.RELATIVE_PATH, notificationSoundsDirectoryPath)
            put(AudioStore.IS_NOTIFICATION, 1)
            put(AudioStore.IS_PENDING, 1)
        }) ?: throw ResolverFailedException("resolver.insert failed")

        (resolver.openOutputStream(url, "wt")
            ?: throw ResolverFailedException("resolver.open… failed"))
            .use { outputStream ->
                val resourceId = context.resources.getIdentifier(
                    sourceResourceName, "raw", context.packageName)
                context.resources.openRawResource(resourceId)
                    .use { it.copyTo(outputStream) }
            }

        resolver.update(
            url, ContentValues().apply { put(AudioStore.IS_PENDING, 0) },
            null, null)

        return url.toString()
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
        extras: Map<String, String>?,
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
                    it.intent.let { intent -> Intent(
                        intent.action,
                        intent.dataUrl.toUri(),
                        context,
                        MainActivity::class.java
                    ).apply {
                        flags = intent.flags.toInt()
                    } },
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
                messagingStyle.messages.forEach {
                    style.addMessage(NotificationCompat.MessagingStyle.Message(
                        it.text,
                        it.timestampMs,
                        toAndroidPerson(it.person),
                    ))
                }
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
                        .mapNotNull { key ->
                            it.notification.extras.getString(key)?.let { value ->
                                key to value
                            } }
                        .toMap()
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
