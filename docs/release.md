# Making releases

## Prepare source tree

* If we haven't recently (like in the last week) upgraded our
  Flutter and packages dependencies, do that first.
  For details of how, see our README.

* Add an entry in `docs/changelog.md`.  Commit that change.

* Increment the version number in `pubspec.yaml`:

  Take the line near the top that looks like `version: 0.0.42+42`,
  and increment both of the last two numbers.
  They should remain equal to each other.

* Commit the version-number change, and tag:
  `git commit pubspec.yaml -m 'version: Bump version to 0.0.NNN'
  && git tag v0.0.NNN`

* Push the tag to our central repo: `git push origin main v0.0.NNN`


## Build and upload alpha: Android

* Decrypt the upload key temporarily:

  ```
  ../mobile/tools/checkout-keystore
  ```

* Build an Android App Bundle, signed:

  ```
  flutter build appbundle -Psigned
  ```

* Upload to the "Zulip (Flutter beta)" app on the Play Console,
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
