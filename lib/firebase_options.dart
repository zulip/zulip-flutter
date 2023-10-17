import 'package:firebase_core/firebase_core.dart';

/// Configuration used for receiving notifications on Android.
///
/// This set of options is used for receiving notifications
/// through the Zulip notification bouncer service:
///   https://zulip.readthedocs.io/en/latest/production/mobile-push-notifications.html
///
/// These values represent public identifiers for that service
/// as an application registered with the relevant Google service:
/// we deliver Android notifications through Firebase Cloud Messaging (FCM).
/// The values are derived from a `google-services.json` file.
/// For details, see:
///   https://developers.google.com/android/guides/google-services-plugin#processing_the_json_file
const kFirebaseOptionsAndroid = FirebaseOptions(
  // This `appId` and `messagingSenderId` are the same as in zulip-mobile;
  // see zulip-mobile:android/app/src/main/res/values/firebase.xml .
  appId: '1:835904834568:android:6ae61ae43a7c3410',
  messagingSenderId: '835904834568',

  projectId: 'zulip-android',

  // Despite the name, this Google Cloud "API key" is a very different kind
  // of thing from a Zulip "API key".  In particular, it's designed to be
  // included in published builds of client applications, and therefore
  // fundamentally public.  See docs:
  //   https://cloud.google.com/docs/authentication/api-keys
  //
  // This key was created fresh for this use in zulip-flutter.
  // It's easy to create additional keys associated with the same `appId`
  // and other details above, and to enable or disable individual keys.
  //
  // TODO: Perhaps use a different key in published builds; still fundamentally
  //   public, but would avoid accidental reuse in dev or modified builds.
  apiKey: 'AIzaSyC6kw5sqCYjxQl2Lbd_8MDmc1lu2EG0pY4',
);
