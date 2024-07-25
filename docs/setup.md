# Dev setup

For general instructions on setting up to do development
on this app, [see the README][readme-setup].

This file covers specific topics in more detail.

[readme-setup]: https://github.com/zulip/zulip-flutter#setting-up


## Android without Android Studio

The standard [Flutter installation guide](https://docs.flutter.dev/get-started/install)
calls for installing Android Studio in order to build for Android.
This is the recommended option where possible; but for use cases
like building the app on a remote server in the cloud, you may want
to set things up without Android Studio.

To set up the development environment on Linux without Android Studio:

1. Follow the [Flutter installation guide](https://docs.flutter.dev/get-started/install),
   up until the step calling for Android Studio.

2. Install Java, specifically JDK 17 (or later?):
   `sudo apt install openjdk-17-jdk`

3. Install the Android SDK.  This might look like the following:

   ```
       # Download Android SDK cmdline-tools: https://developer.android.com/studio#command-line-tools-only
   $ curl -LO https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
   $ mkdir -p ~/Android/Sdk/cmdline-tools/latest
   $ unzip commandlinetools-linux-11076708_latest.zip -d ~/Android/Sdk/cmdline-tools/latest
   $ mv ~/Android/Sdk/cmdline-tools/latest/cmdline-tools/* ~/Android/Sdk/cmdline-tools/latest
   $ rmdir ~/Android/Sdk/cmdline-tools/latest/cmdline-tools
       # Add "$HOME/Android/Sdk/cmdline-tools/latest/bin" to PATH.
       # Set environment variable ANDROID_HOME to "$HOME/Android/Sdk".
   $ sdkmanager platform-tools
   ```

4. Resume following the Flutter installation guide
   starting from the step after installing Android Studio.
   Use the Flutter `main` channel, just like in
   [our standard setup instructions][readme-setup].

5. Build the app with `flutter build apk`
   or `flutter build apk --debug`, and
   download the resulting APK file to your local machine.
   Then use `adb install` (see `adb help` for help)
   to install it on either a physical or emulated device,
   and run it.

   (Have you tried setting things up so that you can use
   `flutter run` on the remote machine, and get hot reload?
   If so, we'd be glad to hear instructions for it;
   please start a thread in our [`#mobile-dev-help`][] channel,
   or send a PR.)

[`#mobile-dev-help`]: https://chat.zulip.org/#narrow/stream/516-mobile-dev-help
