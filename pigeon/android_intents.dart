import 'package:pigeon/pigeon.dart';

// To rebuild this pigeon's output after editing this file,
// run `tools/check pigeon --fix`.
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/host/android_intents.g.dart',
  kotlinOut: 'android/app/src/main/kotlin/com/zulip/flutter/AndroidIntents.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.zulip.flutter',
    // One error class is already generated in AndroidNotifications.g.kt ,
    // so avoid generating another one, preventing duplicate classes under
    // the same namespace.
    includeErrorClass: false)))

// TODO separate out API calls for resolving file name, getting mimetype, getting bytes?
class IntentSharedFile {
  const IntentSharedFile({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String? name;
  final String? mimeType;
  final Uint8List bytes;
}

sealed class AndroidIntentEvent {
  const AndroidIntentEvent();

  // Pigeon doesn't seem to allow fields in sealed classes.
  // final String action;
}

class AndroidIntentSendEvent extends AndroidIntentEvent {
  const AndroidIntentSendEvent({
    required this.action,
    required this.extraText,
    required this.extraStream,
  });

  // This would be either 'android.intent.action.SEND' or
  // 'android.intent.action.SEND_MULTIPLE' for this event type.
  final String action;

  final String? extraText;
  final List<IntentSharedFile>? extraStream;
}

@EventChannelApi()
abstract class AndroidIntentsEventChannelApi {
  AndroidIntentEvent androidIntentEvents();
}
