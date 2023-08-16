# Releasing alpha versions

This is a prototype, so we make releases only to an alpha channel.


## Prepare source tree

* If we haven't recently (like in the last week) upgraded our
  Flutter and packages dependencies, do that first.
  For details of how, see our README.

* Increment the version number in `pubspec.yaml`:

  Take the line near the top that looks like `version: 0.0.42+42`,
  and increment both of the last two numbers.
  They should remain equal to each other.

* Commit the version-number change, and tag:
  `git commit pubspec.yaml -m 'version: Bump version to 0.0.NNN'
  && git tag v0.0.NNN`

* Push the tag to our central repo: `git push origin main v0.0.NNN`


## Build and upload: Android

* Decrypt the upload key temporarily:

  ```
  ../mobile/tools/checkout-keystore
  ```

* Build an Android App Bundle, signed:

  ```
  flutter build appbundle -Psigned
  ```

* Upload to the "Zulip (Flutter prototype)" app on the Play Console,
  at [Release -> Testing -> Internal testing][play-internaltesting],
  using the "Create new release" button there.

  * Don't worry about release notes; "An alpha release." is plenty.

[play-internaltesting]: https://play.google.com/console/developers/8060868091387311598/app/4972181690507348330/tracks/internal-testing


## Build and upload: iOS

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


## Announce

* Announce the updated alpha in
  [#mobile-team > zulip-flutter releases][releases-thread].

[releases-thread]: https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/zulip-flutter.20releases


## One-time or annual setup

* You'll need the Google Play upload key.  The setup is similar to
  what we use for the React Native app, but the key is a fresh one.

* You'll need an "Apple Distribution" certificate and its key,
  and also an iOS "provisioning profile" that refers to that
  certificate.  The cert expires after a year; the profile
  can be edited to refer to a new cert.

  To create these, see <https://developer.apple.com/account/resources>.
  Or for a bit more automation: go in Xcode to Settings -> Accounts
  -> (your Apple ID) -> "Kandra Labs, Inc.".  Hit the "add" icon,
  and choose "Apple Distribution", to create a key and cert.
  Then use the website only to create or edit the profile.
