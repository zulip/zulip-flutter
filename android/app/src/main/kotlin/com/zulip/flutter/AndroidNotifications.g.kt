// Autogenerated from Pigeon (v25.0.0), do not edit directly.
// See also: https://pub.dev/packages/pigeon
@file:Suppress("UNCHECKED_CAST", "ArrayInDataClass")

package com.zulip.flutter

import android.util.Log
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MessageCodec
import io.flutter.plugin.common.StandardMethodCodec
import io.flutter.plugin.common.StandardMessageCodec
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

private fun wrapResult(result: Any?): List<Any?> {
  return listOf(result)
}

private fun wrapError(exception: Throwable): List<Any?> {
  return if (exception is FlutterError) {
    listOf(
      exception.code,
      exception.message,
      exception.details
    )
  } else {
    listOf(
      exception.javaClass.simpleName,
      exception.toString(),
      "Cause: " + exception.cause + ", Stacktrace: " + Log.getStackTraceString(exception)
    )
  }
}

/**
 * Error class for passing custom error details to Flutter via a thrown PlatformException.
 * @property code The error code.
 * @property message The error message.
 * @property details The error details. Must be a datatype supported by the api codec.
 */
class FlutterError (
  val code: String,
  override val message: String? = null,
  val details: Any? = null
) : Throwable()

/**
 * Corresponds to `androidx.core.app.NotificationChannelCompat`
 *
 * See: https://developer.android.com/reference/androidx/core/app/NotificationChannelCompat
 *
 * Generated class from Pigeon that represents data sent in messages.
 */
data class NotificationChannel (
  val id: String,
  /**
   * Specifies the importance level of notifications
   * to be posted on this channel.
   *
   * Must be a valid constant from [NotificationImportance].
   */
  val importance: Long,
  val name: String? = null,
  val lightsEnabled: Boolean? = null,
  val soundUrl: String? = null,
  val vibrationPattern: LongArray? = null
)
 {
  companion object {
    fun fromList(pigeonVar_list: List<Any?>): NotificationChannel {
      val id = pigeonVar_list[0] as String
      val importance = pigeonVar_list[1] as Long
      val name = pigeonVar_list[2] as String?
      val lightsEnabled = pigeonVar_list[3] as Boolean?
      val soundUrl = pigeonVar_list[4] as String?
      val vibrationPattern = pigeonVar_list[5] as LongArray?
      return NotificationChannel(id, importance, name, lightsEnabled, soundUrl, vibrationPattern)
    }
  }
  fun toList(): List<Any?> {
    return listOf(
      id,
      importance,
      name,
      lightsEnabled,
      soundUrl,
      vibrationPattern,
    )
  }
}

/**
 * Corresponds to `android.content.Intent`
 *
 * See:
 *   https://developer.android.com/reference/android/content/Intent
 *   https://developer.android.com/reference/android/content/Intent#Intent(java.lang.String,%20android.net.Uri,%20android.content.Context,%20java.lang.Class%3C?%3E)
 *
 * Generated class from Pigeon that represents data sent in messages.
 */
data class AndroidIntent (
  val action: String,
  val dataUrl: String,
  /** A combination of flags from [IntentFlag]. */
  val flags: Long,
  val extrasData: Map<String, String>
)
 {
  companion object {
    fun fromList(pigeonVar_list: List<Any?>): AndroidIntent {
      val action = pigeonVar_list[0] as String
      val dataUrl = pigeonVar_list[1] as String
      val flags = pigeonVar_list[2] as Long
      val extrasData = pigeonVar_list[3] as Map<String, String>
      return AndroidIntent(action, dataUrl, flags, extrasData)
    }
  }
  fun toList(): List<Any?> {
    return listOf(
      action,
      dataUrl,
      flags,
      extrasData,
    )
  }
}

/**
 * Corresponds to `android.app.PendingIntent`.
 *
 * See: https://developer.android.com/reference/android/app/PendingIntent
 *
 * Generated class from Pigeon that represents data sent in messages.
 */
data class PendingIntent (
  val requestCode: Long,
  val intent: AndroidIntent,
  /**
   * A combination of flags from [PendingIntent.flags], and others associated
   * with `Intent`; see Android docs for `PendingIntent.getActivity`.
   */
  val flags: Long
)
 {
  companion object {
    fun fromList(pigeonVar_list: List<Any?>): PendingIntent {
      val requestCode = pigeonVar_list[0] as Long
      val intent = pigeonVar_list[1] as AndroidIntent
      val flags = pigeonVar_list[2] as Long
      return PendingIntent(requestCode, intent, flags)
    }
  }
  fun toList(): List<Any?> {
    return listOf(
      requestCode,
      intent,
      flags,
    )
  }
}

/**
 * Corresponds to `androidx.core.app.NotificationCompat.InboxStyle`
 *
 * See: https://developer.android.com/reference/androidx/core/app/NotificationCompat.InboxStyle
 *
 * Generated class from Pigeon that represents data sent in messages.
 */
data class InboxStyle (
  val summaryText: String
)
 {
  companion object {
    fun fromList(pigeonVar_list: List<Any?>): InboxStyle {
      val summaryText = pigeonVar_list[0] as String
      return InboxStyle(summaryText)
    }
  }
  fun toList(): List<Any?> {
    return listOf(
      summaryText,
    )
  }
}

/**
 * Corresponds to `androidx.core.app.Person`
 *
 * See: https://developer.android.com/reference/androidx/core/app/Person
 *
 * Generated class from Pigeon that represents data sent in messages.
 */
data class Person (
  /**
   * An icon for this person.
   *
   * This should be compressed image data, in a format to be passed
   * to `androidx.core.graphics.drawable.IconCompat.createWithData`.
   * Supported formats include JPEG, PNG, and WEBP.
   *
   * See:
   *  https://developer.android.com/reference/androidx/core/graphics/drawable/IconCompat#createWithData(byte[],int,int)
   */
  val iconBitmap: ByteArray? = null,
  val key: String,
  val name: String
)
 {
  companion object {
    fun fromList(pigeonVar_list: List<Any?>): Person {
      val iconBitmap = pigeonVar_list[0] as ByteArray?
      val key = pigeonVar_list[1] as String
      val name = pigeonVar_list[2] as String
      return Person(iconBitmap, key, name)
    }
  }
  fun toList(): List<Any?> {
    return listOf(
      iconBitmap,
      key,
      name,
    )
  }
}

/**
 * Corresponds to `androidx.core.app.NotificationCompat.MessagingStyle.Message`
 *
 * See: https://developer.android.com/reference/androidx/core/app/NotificationCompat.MessagingStyle.Message
 *
 * Generated class from Pigeon that represents data sent in messages.
 */
data class MessagingStyleMessage (
  val text: String,
  val timestampMs: Long,
  val person: Person
)
 {
  companion object {
    fun fromList(pigeonVar_list: List<Any?>): MessagingStyleMessage {
      val text = pigeonVar_list[0] as String
      val timestampMs = pigeonVar_list[1] as Long
      val person = pigeonVar_list[2] as Person
      return MessagingStyleMessage(text, timestampMs, person)
    }
  }
  fun toList(): List<Any?> {
    return listOf(
      text,
      timestampMs,
      person,
    )
  }
}

/**
 * Corresponds to `androidx.core.app.NotificationCompat.MessagingStyle`
 *
 * See: https://developer.android.com/reference/androidx/core/app/NotificationCompat.MessagingStyle
 *
 * Generated class from Pigeon that represents data sent in messages.
 */
data class MessagingStyle (
  val user: Person,
  val conversationTitle: String? = null,
  val messages: List<MessagingStyleMessage>,
  val isGroupConversation: Boolean
)
 {
  companion object {
    fun fromList(pigeonVar_list: List<Any?>): MessagingStyle {
      val user = pigeonVar_list[0] as Person
      val conversationTitle = pigeonVar_list[1] as String?
      val messages = pigeonVar_list[2] as List<MessagingStyleMessage>
      val isGroupConversation = pigeonVar_list[3] as Boolean
      return MessagingStyle(user, conversationTitle, messages, isGroupConversation)
    }
  }
  fun toList(): List<Any?> {
    return listOf(
      user,
      conversationTitle,
      messages,
      isGroupConversation,
    )
  }
}

/**
 * Corresponds to `android.app.Notification`
 *
 * See: https://developer.android.com/reference/kotlin/android/app/Notification
 *
 * Generated class from Pigeon that represents data sent in messages.
 */
data class Notification (
  val group: String,
  val extras: Map<String, String>
)
 {
  companion object {
    fun fromList(pigeonVar_list: List<Any?>): Notification {
      val group = pigeonVar_list[0] as String
      val extras = pigeonVar_list[1] as Map<String, String>
      return Notification(group, extras)
    }
  }
  fun toList(): List<Any?> {
    return listOf(
      group,
      extras,
    )
  }
}

/**
 * Corresponds to `android.service.notification.StatusBarNotification`
 *
 * See: https://developer.android.com/reference/android/service/notification/StatusBarNotification
 *
 * Generated class from Pigeon that represents data sent in messages.
 */
data class StatusBarNotification (
  val id: Long,
  val tag: String,
  val notification: Notification
)
 {
  companion object {
    fun fromList(pigeonVar_list: List<Any?>): StatusBarNotification {
      val id = pigeonVar_list[0] as Long
      val tag = pigeonVar_list[1] as String
      val notification = pigeonVar_list[2] as Notification
      return StatusBarNotification(id, tag, notification)
    }
  }
  fun toList(): List<Any?> {
    return listOf(
      id,
      tag,
      notification,
    )
  }
}

/**
 * Represents details about a notification sound stored in the
 * shared media store.
 *
 * Returned as a list entry by
 * [AndroidNotificationHostApi.listStoredSoundsInNotificationsDirectory].
 *
 * Generated class from Pigeon that represents data sent in messages.
 */
data class StoredNotificationSound (
  /** The display name of the sound file. */
  val fileName: String,
  /**
   * Specifies whether this file was created by the app.
   *
   * It is true if the `MediaStore.Audio.Media.OWNER_PACKAGE_NAME` key in the
   * metadata matches the app's package name.
   */
  val isOwned: Boolean,
  /** A `content://…` URL pointing to the sound file. */
  val contentUrl: String
)
 {
  companion object {
    fun fromList(pigeonVar_list: List<Any?>): StoredNotificationSound {
      val fileName = pigeonVar_list[0] as String
      val isOwned = pigeonVar_list[1] as Boolean
      val contentUrl = pigeonVar_list[2] as String
      return StoredNotificationSound(fileName, isOwned, contentUrl)
    }
  }
  fun toList(): List<Any?> {
    return listOf(
      fileName,
      isOwned,
      contentUrl,
    )
  }
}
private open class AndroidNotificationsPigeonCodec : StandardMessageCodec() {
  override fun readValueOfType(type: Byte, buffer: ByteBuffer): Any? {
    return when (type) {
      129.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          NotificationChannel.fromList(it)
        }
      }
      130.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          AndroidIntent.fromList(it)
        }
      }
      131.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          PendingIntent.fromList(it)
        }
      }
      132.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          InboxStyle.fromList(it)
        }
      }
      133.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          Person.fromList(it)
        }
      }
      134.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          MessagingStyleMessage.fromList(it)
        }
      }
      135.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          MessagingStyle.fromList(it)
        }
      }
      136.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          Notification.fromList(it)
        }
      }
      137.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          StatusBarNotification.fromList(it)
        }
      }
      138.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          StoredNotificationSound.fromList(it)
        }
      }
      else -> super.readValueOfType(type, buffer)
    }
  }
  override fun writeValue(stream: ByteArrayOutputStream, value: Any?)   {
    when (value) {
      is NotificationChannel -> {
        stream.write(129)
        writeValue(stream, value.toList())
      }
      is AndroidIntent -> {
        stream.write(130)
        writeValue(stream, value.toList())
      }
      is PendingIntent -> {
        stream.write(131)
        writeValue(stream, value.toList())
      }
      is InboxStyle -> {
        stream.write(132)
        writeValue(stream, value.toList())
      }
      is Person -> {
        stream.write(133)
        writeValue(stream, value.toList())
      }
      is MessagingStyleMessage -> {
        stream.write(134)
        writeValue(stream, value.toList())
      }
      is MessagingStyle -> {
        stream.write(135)
        writeValue(stream, value.toList())
      }
      is Notification -> {
        stream.write(136)
        writeValue(stream, value.toList())
      }
      is StatusBarNotification -> {
        stream.write(137)
        writeValue(stream, value.toList())
      }
      is StoredNotificationSound -> {
        stream.write(138)
        writeValue(stream, value.toList())
      }
      else -> super.writeValue(stream, value)
    }
  }
}

/** Generated interface from Pigeon that represents a handler of messages from Flutter. */
interface AndroidNotificationHostApi {
  /**
   * Corresponds to `androidx.core.app.NotificationManagerCompat.createNotificationChannel`.
   *
   * See: https://developer.android.com/reference/androidx/core/app/NotificationManagerCompat#createNotificationChannel(androidx.core.app.NotificationChannelCompat)
   */
  fun createNotificationChannel(channel: NotificationChannel)
  /**
   * Corresponds to `androidx.core.app.NotificationManagerCompat.getNotificationChannelsCompat`.
   *
   * See: https://developer.android.com/reference/kotlin/androidx/core/app/NotificationManagerCompat#getNotificationChannelsCompat()
   */
  fun getNotificationChannels(): List<NotificationChannel>
  /**
   * Corresponds to `androidx.core.app.NotificationManagerCompat.deleteNotificationChannel`
   *
   * See: https://developer.android.com/reference/kotlin/androidx/core/app/NotificationManagerCompat#deleteNotificationChannel(java.lang.String)
   */
  fun deleteNotificationChannel(channelId: String)
  /**
   * The list of notification sound files present under `Notifications/Zulip/`
   * in the device's shared media storage,
   * found with `android.content.ContentResolver.query`.
   *
   * This is a complex ad-hoc method.
   * For detailed behavior, see its implementation.
   *
   * Requires minimum of Android 10 (API 29) or higher.
   *
   * See: https://developer.android.com/reference/android/content/ContentResolver#query(android.net.Uri,%20java.lang.String[],%20java.lang.String,%20java.lang.String[],%20java.lang.String)
   */
  fun listStoredSoundsInNotificationsDirectory(): List<StoredNotificationSound>
  /**
   * Wraps `android.content.ContentResolver.insert` combined with
   * `android.content.ContentResolver.openOutputStream` and
   * `android.content.res.Resources.openRawResource`.
   *
   * Copies a raw resource audio file to `Notifications/Zulip/`
   * directory in device's shared media storage. Returns the URL
   * of the target file in media store.
   *
   * Requires minimum of Android 10 (API 29) or higher.
   *
   * See:
   *   https://developer.android.com/reference/android/content/ContentResolver#insert(android.net.Uri,%20android.content.ContentValues)
   *   https://developer.android.com/reference/android/content/ContentResolver#openOutputStream(android.net.Uri)
   *   https://developer.android.com/reference/android/content/res/Resources#openRawResource(int)
   */
  fun copySoundResourceToMediaStore(targetFileDisplayName: String, sourceResourceName: String): String
  /**
   * Corresponds to `android.app.NotificationManager.notify`,
   * combined with `androidx.core.app.NotificationCompat.Builder`.
   *
   * The arguments `tag` and `id` go to the `notify` call.
   * The rest go to method calls on the builder.
   *
   * The `color` should be in the form 0xAARRGGBB.
   * See [ColorExtension.argbInt].
   *
   * The `smallIconResourceName` is passed to `android.content.res.Resources.getIdentifier`
   * to get a resource ID to pass to `Builder.setSmallIcon`.
   * Whatever name is passed there must appear in keep.xml too:
   * see https://github.com/zulip/zulip-flutter/issues/528 .
   *
   * See:
   *   https://developer.android.com/reference/kotlin/android/app/NotificationManager.html#notify
   *   https://developer.android.com/reference/androidx/core/app/NotificationCompat.Builder
   */
  fun notify(tag: String?, id: Long, autoCancel: Boolean?, channelId: String, color: Long?, contentIntent: PendingIntent?, contentText: String?, contentTitle: String?, extras: Map<String, String>?, groupKey: String?, inboxStyle: InboxStyle?, isGroupSummary: Boolean?, messagingStyle: MessagingStyle?, number: Long?, smallIconResourceName: String?)
  /**
   * Wraps `androidx.core.app.NotificationManagerCompat.getActiveNotifications`,
   * combined with `androidx.core.app.NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification`.
   *
   * Returns the messaging style, if any, of an active notification
   * that has tag `tag`.  If there are several such notifications,
   * an arbitrary one of them is used.
   * Returns null if there are no such notifications.
   *
   * See:
   *   https://developer.android.com/reference/kotlin/androidx/core/app/NotificationManagerCompat#getActiveNotifications()
   *   https://developer.android.com/reference/kotlin/androidx/core/app/NotificationCompat.MessagingStyle#extractMessagingStyleFromNotification(android.app.Notification)
   */
  fun getActiveNotificationMessagingStyleByTag(tag: String): MessagingStyle?
  /**
   * Corresponds to `androidx.core.app.NotificationManagerCompat.getActiveNotifications`.
   *
   * The keys of entries to fetch from notification's extras bundle must be
   * specified in the [desiredExtras] list. If this list is empty, then
   * [Notifications.extras] will also be empty. If value of the matched entry
   * is not of type string or is null, then that entry will be skipped.
   *
   * See: https://developer.android.com/reference/kotlin/androidx/core/app/NotificationManagerCompat?hl=en#getActiveNotifications()
   */
  fun getActiveNotifications(desiredExtras: List<String>): List<StatusBarNotification>
  /**
   * Corresponds to `androidx.core.app.NotificationManagerCompat.cancel`.
   *
   * See: https://developer.android.com/reference/kotlin/androidx/core/app/NotificationManagerCompat?hl=en#cancel(java.lang.String,int)
   */
  fun cancel(tag: String?, id: Long)

  companion object {
    /** The codec used by AndroidNotificationHostApi. */
    val codec: MessageCodec<Any?> by lazy {
      AndroidNotificationsPigeonCodec()
    }
    /** Sets up an instance of `AndroidNotificationHostApi` to handle messages through the `binaryMessenger`. */
    @JvmOverloads
    fun setUp(binaryMessenger: BinaryMessenger, api: AndroidNotificationHostApi?, messageChannelSuffix: String = "") {
      val separatedMessageChannelSuffix = if (messageChannelSuffix.isNotEmpty()) ".$messageChannelSuffix" else ""
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.zulip.AndroidNotificationHostApi.createNotificationChannel$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { message, reply ->
            val args = message as List<Any?>
            val channelArg = args[0] as NotificationChannel
            val wrapped: List<Any?> = try {
              api.createNotificationChannel(channelArg)
              listOf(null)
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.zulip.AndroidNotificationHostApi.getNotificationChannels$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { _, reply ->
            val wrapped: List<Any?> = try {
              listOf(api.getNotificationChannels())
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.zulip.AndroidNotificationHostApi.deleteNotificationChannel$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { message, reply ->
            val args = message as List<Any?>
            val channelIdArg = args[0] as String
            val wrapped: List<Any?> = try {
              api.deleteNotificationChannel(channelIdArg)
              listOf(null)
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.zulip.AndroidNotificationHostApi.listStoredSoundsInNotificationsDirectory$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { _, reply ->
            val wrapped: List<Any?> = try {
              listOf(api.listStoredSoundsInNotificationsDirectory())
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.zulip.AndroidNotificationHostApi.copySoundResourceToMediaStore$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { message, reply ->
            val args = message as List<Any?>
            val targetFileDisplayNameArg = args[0] as String
            val sourceResourceNameArg = args[1] as String
            val wrapped: List<Any?> = try {
              listOf(api.copySoundResourceToMediaStore(targetFileDisplayNameArg, sourceResourceNameArg))
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.zulip.AndroidNotificationHostApi.notify$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { message, reply ->
            val args = message as List<Any?>
            val tagArg = args[0] as String?
            val idArg = args[1] as Long
            val autoCancelArg = args[2] as Boolean?
            val channelIdArg = args[3] as String
            val colorArg = args[4] as Long?
            val contentIntentArg = args[5] as PendingIntent?
            val contentTextArg = args[6] as String?
            val contentTitleArg = args[7] as String?
            val extrasArg = args[8] as Map<String, String>?
            val groupKeyArg = args[9] as String?
            val inboxStyleArg = args[10] as InboxStyle?
            val isGroupSummaryArg = args[11] as Boolean?
            val messagingStyleArg = args[12] as MessagingStyle?
            val numberArg = args[13] as Long?
            val smallIconResourceNameArg = args[14] as String?
            val wrapped: List<Any?> = try {
              api.notify(tagArg, idArg, autoCancelArg, channelIdArg, colorArg, contentIntentArg, contentTextArg, contentTitleArg, extrasArg, groupKeyArg, inboxStyleArg, isGroupSummaryArg, messagingStyleArg, numberArg, smallIconResourceNameArg)
              listOf(null)
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.zulip.AndroidNotificationHostApi.getActiveNotificationMessagingStyleByTag$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { message, reply ->
            val args = message as List<Any?>
            val tagArg = args[0] as String
            val wrapped: List<Any?> = try {
              listOf(api.getActiveNotificationMessagingStyleByTag(tagArg))
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.zulip.AndroidNotificationHostApi.getActiveNotifications$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { message, reply ->
            val args = message as List<Any?>
            val desiredExtrasArg = args[0] as List<String>
            val wrapped: List<Any?> = try {
              listOf(api.getActiveNotifications(desiredExtrasArg))
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.zulip.AndroidNotificationHostApi.cancel$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { message, reply ->
            val args = message as List<Any?>
            val tagArg = args[0] as String?
            val idArg = args[1] as Long
            val wrapped: List<Any?> = try {
              api.cancel(tagArg, idArg)
              listOf(null)
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
    }
  }
}
