// Autogenerated from Pigeon (v20.0.1), do not edit directly.
// See also: https://pub.dev/packages/pigeon
// ignore_for_file: public_member_api_docs, non_constant_identifier_names, avoid_as, unused_import, unnecessary_parenthesis, prefer_null_aware_operators, omit_local_variable_types, unused_shown_name, unnecessary_import, no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:typed_data' show Float64List, Int32List, Int64List, Uint8List;

import 'package:flutter/foundation.dart' show ReadBuffer, WriteBuffer;
import 'package:flutter/services.dart';

PlatformException _createConnectionError(String channelName) {
  return PlatformException(
    code: 'channel-error',
    message: 'Unable to establish connection on channel: "$channelName".',
  );
}

/// Corresponds to `androidx.core.app.NotificationChannelCompat`
///
/// See: https://developer.android.com/reference/androidx/core/app/NotificationChannelCompat
class NotificationChannel {
  NotificationChannel({
    required this.id,
    required this.importance,
    this.name,
    this.lightsEnabled,
    this.vibrationPattern,
  });

  String id;

  /// Specifies the importance level of notifications
  /// to be posted on this channel.
  ///
  /// Must be a valid constant from [NotificationImportance].
  int importance;

  String? name;

  bool? lightsEnabled;

  Int64List? vibrationPattern;

  Object encode() {
    return <Object?>[
      id,
      importance,
      name,
      lightsEnabled,
      vibrationPattern,
    ];
  }

  static NotificationChannel decode(Object result) {
    result as List<Object?>;
    return NotificationChannel(
      id: result[0]! as String,
      importance: result[1]! as int,
      name: result[2] as String?,
      lightsEnabled: result[3] as bool?,
      vibrationPattern: result[4] as Int64List?,
    );
  }
}

/// Corresponds to `android.app.PendingIntent`.
///
/// See: https://developer.android.com/reference/android/app/PendingIntent
class PendingIntent {
  PendingIntent({
    required this.requestCode,
    required this.intentPayload,
    required this.flags,
  });

  int requestCode;

  /// A value set on an extra on the Intent, and passed to
  /// the on-notification-opened callback.
  String intentPayload;

  /// A combination of flags from [PendingIntent.flags], and others associated
  /// with `Intent`; see Android docs for `PendingIntent.getActivity`.
  int flags;

  Object encode() {
    return <Object?>[
      requestCode,
      intentPayload,
      flags,
    ];
  }

  static PendingIntent decode(Object result) {
    result as List<Object?>;
    return PendingIntent(
      requestCode: result[0]! as int,
      intentPayload: result[1]! as String,
      flags: result[2]! as int,
    );
  }
}

/// Corresponds to `androidx.core.app.NotificationCompat.InboxStyle`
///
/// See: https://developer.android.com/reference/androidx/core/app/NotificationCompat.InboxStyle
class InboxStyle {
  InboxStyle({
    required this.summaryText,
  });

  String summaryText;

  Object encode() {
    return <Object?>[
      summaryText,
    ];
  }

  static InboxStyle decode(Object result) {
    result as List<Object?>;
    return InboxStyle(
      summaryText: result[0]! as String,
    );
  }
}

/// Corresponds to `androidx.core.app.Person`
///
/// See: https://developer.android.com/reference/androidx/core/app/Person
class Person {
  Person({
    this.iconBitmap,
    required this.key,
    required this.name,
  });

  /// An icon for this person.
  ///
  /// This should be compressed image data, in a format to be passed
  /// to `androidx.core.graphics.drawable.IconCompat.createWithData`.
  /// Supported formats include JPEG, PNG, and WEBP.
  ///
  /// See:
  ///  https://developer.android.com/reference/androidx/core/graphics/drawable/IconCompat#createWithData(byte[],int,int)
  Uint8List? iconBitmap;

  String key;

  String name;

  Object encode() {
    return <Object?>[
      iconBitmap,
      key,
      name,
    ];
  }

  static Person decode(Object result) {
    result as List<Object?>;
    return Person(
      iconBitmap: result[0] as Uint8List?,
      key: result[1]! as String,
      name: result[2]! as String,
    );
  }
}

/// Corresponds to `androidx.core.app.NotificationCompat.MessagingStyle.Message`
///
/// See: https://developer.android.com/reference/androidx/core/app/NotificationCompat.MessagingStyle.Message
class MessagingStyleMessage {
  MessagingStyleMessage({
    required this.text,
    required this.timestampMs,
    required this.person,
  });

  String text;

  int timestampMs;

  Person person;

  Object encode() {
    return <Object?>[
      text,
      timestampMs,
      person,
    ];
  }

  static MessagingStyleMessage decode(Object result) {
    result as List<Object?>;
    return MessagingStyleMessage(
      text: result[0]! as String,
      timestampMs: result[1]! as int,
      person: result[2]! as Person,
    );
  }
}

/// Corresponds to `androidx.core.app.NotificationCompat.MessagingStyle`
///
/// See: https://developer.android.com/reference/androidx/core/app/NotificationCompat.MessagingStyle
class MessagingStyle {
  MessagingStyle({
    required this.user,
    this.conversationTitle,
    required this.messages,
    required this.isGroupConversation,
  });

  Person user;

  String? conversationTitle;

  List<MessagingStyleMessage?> messages;

  bool isGroupConversation;

  Object encode() {
    return <Object?>[
      user,
      conversationTitle,
      messages,
      isGroupConversation,
    ];
  }

  static MessagingStyle decode(Object result) {
    result as List<Object?>;
    return MessagingStyle(
      user: result[0]! as Person,
      conversationTitle: result[1] as String?,
      messages: (result[2] as List<Object?>?)!.cast<MessagingStyleMessage?>(),
      isGroupConversation: result[3]! as bool,
    );
  }
}

/// Corresponds to `android.app.Notification`.
///
/// See: https://developer.android.com/reference/kotlin/android/app/Notification
class Notification {
  Notification({
    this.group,
    required this.extras,
  });

  String? group;

  Map<String?, Object?> extras;

  Object encode() {
    return <Object?>[
      group,
      extras,
    ];
  }

  static Notification decode(Object result) {
    result as List<Object?>;
    return Notification(
      group: result[0] as String?,
      extras: (result[1] as Map<Object?, Object?>?)!.cast<String?, Object?>(),
    );
  }
}

/// Corresponds to `android.service.notification.StatusBarNotification`.
///
/// See: https://developer.android.com/reference/kotlin/android/service/notification/StatusBarNotification
class StatusBarNotification {
  StatusBarNotification({
    required this.id,
    required this.notification,
    this.tag,
  });

  int id;

  Notification notification;

  String? tag;

  Object encode() {
    return <Object?>[
      id,
      notification,
      tag,
    ];
  }

  static StatusBarNotification decode(Object result) {
    result as List<Object?>;
    return StatusBarNotification(
      id: result[0]! as int,
      notification: result[1]! as Notification,
      tag: result[2] as String?,
    );
  }
}


class _PigeonCodec extends StandardMessageCodec {
  const _PigeonCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is NotificationChannel) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else     if (value is PendingIntent) {
      buffer.putUint8(130);
      writeValue(buffer, value.encode());
    } else     if (value is InboxStyle) {
      buffer.putUint8(131);
      writeValue(buffer, value.encode());
    } else     if (value is Person) {
      buffer.putUint8(132);
      writeValue(buffer, value.encode());
    } else     if (value is MessagingStyleMessage) {
      buffer.putUint8(133);
      writeValue(buffer, value.encode());
    } else     if (value is MessagingStyle) {
      buffer.putUint8(134);
      writeValue(buffer, value.encode());
    } else     if (value is Notification) {
      buffer.putUint8(135);
      writeValue(buffer, value.encode());
    } else     if (value is StatusBarNotification) {
      buffer.putUint8(136);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 129: 
        return NotificationChannel.decode(readValue(buffer)!);
      case 130: 
        return PendingIntent.decode(readValue(buffer)!);
      case 131: 
        return InboxStyle.decode(readValue(buffer)!);
      case 132: 
        return Person.decode(readValue(buffer)!);
      case 133: 
        return MessagingStyleMessage.decode(readValue(buffer)!);
      case 134: 
        return MessagingStyle.decode(readValue(buffer)!);
      case 135: 
        return Notification.decode(readValue(buffer)!);
      case 136: 
        return StatusBarNotification.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

class AndroidNotificationHostApi {
  /// Constructor for [AndroidNotificationHostApi].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  AndroidNotificationHostApi({BinaryMessenger? binaryMessenger, String messageChannelSuffix = ''})
      : __pigeon_binaryMessenger = binaryMessenger,
        __pigeon_messageChannelSuffix = messageChannelSuffix.isNotEmpty ? '.$messageChannelSuffix' : '';
  final BinaryMessenger? __pigeon_binaryMessenger;

  static const MessageCodec<Object?> pigeonChannelCodec = _PigeonCodec();

  final String __pigeon_messageChannelSuffix;

  /// Corresponds to `androidx.core.app.NotificationManagerCompat.createNotificationChannel`.
  ///
  /// See: https://developer.android.com/reference/androidx/core/app/NotificationManagerCompat#createNotificationChannel(androidx.core.app.NotificationChannelCompat)
  Future<void> createNotificationChannel(NotificationChannel channel) async {
    final String __pigeon_channelName = 'dev.flutter.pigeon.zulip.AndroidNotificationHostApi.createNotificationChannel$__pigeon_messageChannelSuffix';
    final BasicMessageChannel<Object?> __pigeon_channel = BasicMessageChannel<Object?>(
      __pigeon_channelName,
      pigeonChannelCodec,
      binaryMessenger: __pigeon_binaryMessenger,
    );
    final List<Object?>? __pigeon_replyList =
        await __pigeon_channel.send(<Object?>[channel]) as List<Object?>?;
    if (__pigeon_replyList == null) {
      throw _createConnectionError(__pigeon_channelName);
    } else if (__pigeon_replyList.length > 1) {
      throw PlatformException(
        code: __pigeon_replyList[0]! as String,
        message: __pigeon_replyList[1] as String?,
        details: __pigeon_replyList[2],
      );
    } else {
      return;
    }
  }

  /// Corresponds to `android.app.NotificationManager.notify`,
  /// combined with `androidx.core.app.NotificationCompat.Builder`.
  ///
  /// The arguments `tag` and `id` go to the `notify` call.
  /// The rest go to method calls on the builder.
  ///
  /// The `color` should be in the form 0xAARRGGBB.
  /// This is the form returned by [Color.value].
  ///
  /// The `smallIconResourceName` is passed to `android.content.res.Resources.getIdentifier`
  /// to get a resource ID to pass to `Builder.setSmallIcon`.
  /// Whatever name is passed there must appear in keep.xml too:
  /// see https://github.com/zulip/zulip-flutter/issues/528 .
  ///
  /// See:
  ///   https://developer.android.com/reference/kotlin/android/app/NotificationManager.html#notify
  ///   https://developer.android.com/reference/androidx/core/app/NotificationCompat.Builder
  Future<void> notify({String? tag, required int id, bool? autoCancel, required String channelId, int? color, PendingIntent? contentIntent, String? contentText, String? contentTitle, Map<String?, String?>? extras, String? groupKey, InboxStyle? inboxStyle, bool? isGroupSummary, MessagingStyle? messagingStyle, int? number, String? smallIconResourceName,}) async {
    final String __pigeon_channelName = 'dev.flutter.pigeon.zulip.AndroidNotificationHostApi.notify$__pigeon_messageChannelSuffix';
    final BasicMessageChannel<Object?> __pigeon_channel = BasicMessageChannel<Object?>(
      __pigeon_channelName,
      pigeonChannelCodec,
      binaryMessenger: __pigeon_binaryMessenger,
    );
    final List<Object?>? __pigeon_replyList =
        await __pigeon_channel.send(<Object?>[tag, id, autoCancel, channelId, color, contentIntent, contentText, contentTitle, extras, groupKey, inboxStyle, isGroupSummary, messagingStyle, number, smallIconResourceName]) as List<Object?>?;
    if (__pigeon_replyList == null) {
      throw _createConnectionError(__pigeon_channelName);
    } else if (__pigeon_replyList.length > 1) {
      throw PlatformException(
        code: __pigeon_replyList[0]! as String,
        message: __pigeon_replyList[1] as String?,
        details: __pigeon_replyList[2],
      );
    } else {
      return;
    }
  }

  Future<List<StatusBarNotification?>> getActiveNotifications() async {
    final String __pigeon_channelName = 'dev.flutter.pigeon.zulip.AndroidNotificationHostApi.getActiveNotifications$__pigeon_messageChannelSuffix';
    final BasicMessageChannel<Object?> __pigeon_channel = BasicMessageChannel<Object?>(
      __pigeon_channelName,
      pigeonChannelCodec,
      binaryMessenger: __pigeon_binaryMessenger,
    );
    final List<Object?>? __pigeon_replyList =
        await __pigeon_channel.send(null) as List<Object?>?;
    if (__pigeon_replyList == null) {
      throw _createConnectionError(__pigeon_channelName);
    } else if (__pigeon_replyList.length > 1) {
      throw PlatformException(
        code: __pigeon_replyList[0]! as String,
        message: __pigeon_replyList[1] as String?,
        details: __pigeon_replyList[2],
      );
    } else if (__pigeon_replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (__pigeon_replyList[0] as List<Object?>?)!.cast<StatusBarNotification?>();
    }
  }

  /// Wraps `androidx.core.app.NotificationManagerCompat.getActiveNotifications`,
  /// combined with `androidx.core.app.NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification`.
  ///
  /// Returns the messaging style, if any, of an active notification
  /// that has tag `tag`.  If there are several such notifications,
  /// an arbitrary one of them is used.
  /// Returns null if there are no such notifications.
  ///
  /// See:
  ///   https://developer.android.com/reference/kotlin/androidx/core/app/NotificationManagerCompat#getActiveNotifications()
  ///   https://developer.android.com/reference/kotlin/androidx/core/app/NotificationCompat.MessagingStyle#extractMessagingStyleFromNotification(android.app.Notification)
  Future<MessagingStyle?> getActiveNotificationMessagingStyleByTag(String tag) async {
    final String __pigeon_channelName = 'dev.flutter.pigeon.zulip.AndroidNotificationHostApi.getActiveNotificationMessagingStyleByTag$__pigeon_messageChannelSuffix';
    final BasicMessageChannel<Object?> __pigeon_channel = BasicMessageChannel<Object?>(
      __pigeon_channelName,
      pigeonChannelCodec,
      binaryMessenger: __pigeon_binaryMessenger,
    );
    final List<Object?>? __pigeon_replyList =
        await __pigeon_channel.send(<Object?>[tag]) as List<Object?>?;
    if (__pigeon_replyList == null) {
      throw _createConnectionError(__pigeon_channelName);
    } else if (__pigeon_replyList.length > 1) {
      throw PlatformException(
        code: __pigeon_replyList[0]! as String,
        message: __pigeon_replyList[1] as String?,
        details: __pigeon_replyList[2],
      );
    } else {
      return (__pigeon_replyList[0] as MessagingStyle?);
    }
  }

  /// Corresponds to `android.app.NotificationManager.cancel`.
  ///
  /// See: https://developer.android.com/reference/kotlin/android/app/NotificationManager.html#cancel
  Future<void> cancel({String? tag, required int id}) async {
    final String __pigeon_channelName = 'dev.flutter.pigeon.zulip.AndroidNotificationHostApi.cancel$__pigeon_messageChannelSuffix';
    final BasicMessageChannel<Object?> __pigeon_channel = BasicMessageChannel<Object?>(
      __pigeon_channelName,
      pigeonChannelCodec,
      binaryMessenger: __pigeon_binaryMessenger,
    );
    final List<Object?>? __pigeon_replyList =
        await __pigeon_channel.send(<Object?>[tag, id]) as List<Object?>?;
    if (__pigeon_replyList == null) {
      throw _createConnectionError(__pigeon_channelName);
    } else if (__pigeon_replyList.length > 1) {
      throw PlatformException(
        code: __pigeon_replyList[0]! as String,
        message: __pigeon_replyList[1] as String?,
        details: __pigeon_replyList[2],
      );
    } else {
      return;
    }
  }
}
