# Dev setup

For general instructions on setting up to do development
on this app, [see the README][readme-setup].

This file covers specific topics in more detail.

[readme-setup]: https://github.com/zulip/zulip-flutter#setting-up


<div id="autocrlf" />

## Windows

If you've checked out the repo on Windows, then by default
Git will convert the `\n` character at the end of each line
to the `\r\n` sequence that is traditional on Windows.
These are also called LF and CRLF line endings.

You'll need to disable this Git behavior.  To do that, run
the command
`git config core.autocrlf input`
from inside your checkout.

If you want to disable this behavior for all your Git checkouts
of other projects, the command
`git config --global core.autocrlf input`
will do that.

With the default behavior, you may see Git report certain files
as modified when nothing should have changed them.  For details,
or to fix such modifications once they're present,
see the troubleshooting section
["Unexpected modified files on Windows"](#windows-modified-files)
below.


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


## Troubleshooting

<div id="dart-sdk" />

### Dart SDK version

You might see an error message about the Dart SDK version,
like so:
```
$ flutter pub get
Resolving dependencies...
The current Dart SDK version is 3.6.0-216.1.beta.

Because zulip requires SDK version >=3.6.0-279.0.dev <4.0.0,
version solving failed.
Failed to update packages.
```

This error message says your Dart SDK version is too old.
Because Flutter provides its own Dart SDK,
that means your Flutter version is too old.

To fix the issue, follow [our setup instructions][readme-setup]
by running `flutter channel main` and `flutter upgrade`.

For previous discussion of this symptom, see
[this chat thread](https://chat.zulip.org/#narrow/stream/516-mobile-dev-help/topic/setup.3A.20Dart.20SDK.20dev.20version/near/1831351).


<div id="windows-modified-files" />

### Unexpected modified files on Windows

On Windows, you might find Git reporting certain files are modified
when you haven't made any changes that should affect them.  For
example:
```
$ git status
…
        modified:   linux/flutter/generated_plugin_registrant.cc
        modified:   linux/flutter/generated_plugin_registrant.h
        modified:   linux/flutter/generated_plugins.cmake
        modified:   macos/Flutter/GeneratedPluginRegistrant.swift
        modified:   windows/flutter/generated_plugin_registrant.cc
        modified:   windows/flutter/generated_plugin_registrant.h
        modified:   windows/flutter/generated_plugins.cmake
```

or:
```
$ git status
…
        modified:   lib/api/model/events.g.dart
        modified:   lib/api/model/initial_snapshot.g.dart
        modified:   lib/api/model/model.g.dart
…
        modified:   lib/model/internal_link.g.dart
```

When seeing this issue, `git diff` will report lines like:
```
warning: in the working copy of 'linux/flutter/generated_plugin_registrant.cc', LF will be replaced by CRLF the next time Git touches it
```

To fix the issue, run the command `git config core.autocrlf input`.

Then use `git restore` or `git reset` to restore the affected files
to the version that Git expects.
For example you can run `git reset --hard` to restore all files
in the checkout to the version from the current HEAD commit.

The background of the issue is described [above](#autocrlf).
Specifically, the affected files are generated files,
and the tools from the Flutter and Dart ecosystems that
generate the files are generating them with LF line endings (`\n`)
regardless of platform.  When Git is translating line endings
to CRLF (`\r\n`), which it does by default, this means the
freshly generated files don't match what Git expects.

Even though CRLF line endings are traditional for Windows,
most Windows tools today work just as well with LF line endings.
So the fix is to use the same LF line endings that we use
on Linux and macOS.

A similar effect can be gotten with `git config core.eol lf`.
The reason we recommend a different fix above is that
the `core.eol` setting is overridden if you happen to have
`core.autocrlf` set to `true` in your global Git config.

For the original reports and debugging of this issue, see
chat threads
[here](https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/flutter.20json_annotation.20unexpected.20behavior/near/1824410)
and [here](https://chat.zulip.org/#narrow/stream/516-mobile-dev-help/topic/generated.20plugin.20files.20changed/near/1944826).


<div id="libdrm" />

### Lack of libdrm on Linux target

This item applies only when building the app to run as a Linux desktop
app.  (This is an unsupported configuration which is sometimes
convenient in development.)  It does not affect using Linux for a
development environment when building or running Zulip as an Android
app.

When building or running as a Linux desktop app, you may see an error
about `/usr/include/libdrm`, like this:
```
$ flutter run -d linux
Launching lib/main.dart on Linux in debug mode...
CMake Error in CMakeLists.txt:
  Imported target "PkgConfig::GTK" includes non-existent path

    "/usr/include/libdrm"

  in its INTERFACE_INCLUDE_DIRECTORIES.  Possible reasons include:
…
```

This means you need to install the header files for "DRM", part of the
Linux graphics infrastructure.

To resolve the issue, install the appropriate package from your OS
distribution.  For example, on Debian or Ubuntu:
```
$ sudo apt install libdrm-dev
```
