# Making releases

## Prepare source tree

* If we haven't recently (like in the last week) upgraded our
  Flutter and packages dependencies, do that first.
  For details of how, see our README.

* Write an entry in `docs/changelog.md`, under "Unreleased".
  Commit that change.

* Run `tools/bump-version` to update the version number.
  Inspect the resulting commit and tag, and push.


## Build and upload alpha: Android

* Decrypt the upload key temporarily:

  ```
  ../mobile/tools/checkout-keystore
  ```

* Build both an Android App Bundle (AAB) and an APK, signed:

  ```
  flutter build appbundle -Psigned && flutter build apk -Psigned
  ```

* Upload the AAB to the "Zulip (Flutter beta)" app on the Play Console,
  at [Release > Testing > Internal testing][play-internaltesting],
  using the "Create new release" button there.

  * For the release notes, start with `tools/format-changelog user`.
    Edit as needed to resolve "(Android)" and "(iOS)" labels
    and for formatting.

[play-internaltesting]: https://play.google.com/console/developers/8060868091387311598/app/4972181690507348330/tracks/internal-testing


## Build and upload alpha: iOS

* Build an app archive:

  ```
  flutter build ipa
  ```

* Upload the archive:

  * If `flutter build ipa` successfully built an IPA file:

    * Run `open -a Transporter build/ios/ipa/'Zulip beta'.ipa`.

    * Hit the big blue "Deliver" button in the Transporter app.

  * Otherwise:

    * Open in Xcode:

      ```
      open build/ios/archive/Runner.xcarchive
      ```

    * Select the "Distribute App" button, and answer the prompts.

      * Start with "Custom".

      * When asked, choose "Manually manage app signing".
        Choose the only available app provisioning profile.

        (It's not clear why Xcode isn't able to make this same choice
        when asked to automatically manage app signing.)

* The build will go automatically to the alpha users in a few minutes,
  provided all goes well with the "processing" step.


## Promote to beta

* Android via Play Store:

  * Go to [Release > Testing > Internal testing][play-internaltesting]
    in the Google Play Console.  (If you just uploaded the alpha, that
    took you here already.)

  * Under the release you want to promote, choose "Promote release >
    Open testing".

  * Confirm and send to Google for review.


* Android via GitHub:

  * [Create a GitHub release](https://github.com/zulip/zulip-flutter/releases/new),
    named the same as the tag.

  * For the release notes, use `tools/format-changelog notes`,
    and fix formatting as needed.

    * The hashes printed at the bottom are based on the files found at
      the usual build-output locations.  Those should be the same
      files you upload.

  * Upload both the AAB and the APK.

  * Check the box "This is a pre-release".


* iOS via TestFlight:

  * After the build reaches alpha, you can add it to TestFlight so it
    goes to our beta users.  Go in App Store Connect to [TestFlight >
    Testers & Groups > External Testers][asc-external],
    and hit the "+" icon at the top of the list of builds to enter a
    modal dialog.

    * For the "What to Test" notes, see remark above about release notes.

  * The same External Testers page should now show the build in status
    "Waiting for Review".  This typically comes back the next morning,
    California time.  If successful, the app is out in beta!

[asc-external]: https://appstoreconnect.apple.com/apps/1672696023/testflight/groups/87223480-4e5d-4007-a3a1-542cd410546c


## Announce

* Announce the updated beta in
  [#announce > mobile beta][releases-thread].

  For release notes, use `tools/format-changelog czo`.

[releases-thread]: https://chat.zulip.org/#narrow/stream/1-announce/topic/mobile.20beta

* For any fixed issues that were tagged "beta feedback", or otherwise
  had people outside the mobile team specifically interested in them,
  follow up with the requesters: post on the relevant thread (in
  GitHub or Zulip) and @-mention the individuals who asked for the
  change.

  In particular, for each fixed issue 123, do a Zulip search for
  "f123".  This efficiently finds any threads that mentioned "#F123".


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

* For iOS uploads, you'll want the Transporter app — it's published by
  Apple but doesn't come with macOS or Xcode, and instead is its own
  item in the Mac App Store:
  <https://apps.apple.com/us/app/transporter/id1450874784>

  Install the app, open it, and log in.
