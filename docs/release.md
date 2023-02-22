# Releasing alpha versions

This is a prototype, so we make releases only to an alpha channel.

This document is a work in progress, as we haven't yet
completed such a release.


## For both platforms

* Increment the version number in `pubspec.yaml`:

  Take the line near the top that looks like `version: 0.0.42+42`,
  and increment both numbers.  They should remain equal to each other.


## Android

* Decrypt the upload key temporarily:

  ```
  ../mobile/tools/checkout-keystore
  ```

* Build an Android App Bundle, signed:

  ```
  flutter build appbundle -Psigned
  ```

* Upload to the "Zulip (Flutter prototype)" app on the Play Console,
  as an "Internal testing" release.

  Don't worry about release notes; "An alpha release." is plenty.


## iOS

* Build an app archive:

  ```
  flutter build ipa
  ```

* Upload the archive:

  * Open in Xcode:

    ```
    open build/ios/archive/Runner.xcarchive
    ```

  * Select the "Distribute App" button, and answer the prompts.

    * When asked, choose "Manually manage app signing".  Choose the
      only available app provisioning profile.

* The build will go automatically to the alpha users in a few minutes,
  provided all goes well with the "processing" step.


## One-time setup

* You'll need the Google Play upload key.  The setup is similar to
  what we use for the React Native app, but the key is a fresh one.
