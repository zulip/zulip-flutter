# Making releases

This doc explains how to make a release of the Zulip mobile app to the
iOS App Store, to the Google Play Store, and as APKs on the web.

If you're reading this page for the first time, see the sections on
[terminology](#terminology) and [setup](#setup) below.

(Some additional information can be found in the [legacy app's release
instructions][].  Incorporating those remaining pieces into this doc
is an open TODO.

The main release process, however, is all fully set forth below.)

[legacy app's release instructions]: https://github.com/zulip/zulip-mobile/blob/main/docs/howto/release.md


## Prepare source tree

* If we haven't recently (like in the last week) upgraded our
  Flutter and packages dependencies, do that first.
  For details of how, see our README.

* Update translations from Weblate:
  * Run the [GitHub action][weblate-github-action] to create a PR
    (or update an existing bot PR) with translation updates.
  * CI doesn't run on the bot's PRs.  So if you suspect the PR might
    break anything (e.g. if this is the first sync since changing
    something in our Weblate setup), run `tools/check` on it yourself.
  * Merge the PR.

* Write an entry in `docs/changelog.md`, under "Unreleased".
  Commit that change.

* Run `tools/bump-version` to update the version number.
  Inspect the resulting commit and tag, and push.

[weblate-github-action]: https://github.com/zulip/zulip-flutter/actions/workflows/update-translations.yml


## Build and upload alpha: Android

* Decrypt the upload key temporarily:

  ```
  ../mobile/tools/checkout-keystore
  ```

* Build both an Android App Bundle (AAB) and an APK, signed:

  ```
  flutter build appbundle -Psigned && flutter build apk -Psigned
  ```

* Upload the AAB to Google Play via the "Create new release" button
  at the top of the
  [Release > Testing > Internal testing][play-internaltesting]
  page.

  * For the release notes, start with `tools/format-changelog user`.
    Edit as needed to resolve "(Android)" and "(iOS)" labels
    and for formatting.

[play-internaltesting]: https://play.google.com/console/developers/8060868091387311598/app/4976350040864490411/tracks/internal-testing


## Build and upload alpha: iOS

* Build an app archive:

  ```
  flutter build ipa
  ```

* Upload the archive:

  * If `flutter build ipa` successfully built an IPA file:

    * Run `open -a Transporter build/ios/ipa/Zulip.ipa`.

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

  * Check the box "Set as a pre-release".


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

  * Also submit for App Store review, to save latency in the prod rollout:

    * In App Store Connect for the app, [go to the "Distribution"
      tab][asc-main], and hit the "+" button next to "iOS App" at the
      top of the left sidebar.  Enter the version number.  This
      creates a new draft listing.

    * In the draft listing:

      * Near the top, fill in "What's New in This Version",
        using the same release notes as for TestFlight.

      * In the "Build" section, hit the "+" icon next to the "Build"
        heading.  Select the desired build.

      * Under "Version Release" near the bottom, make sure "Manually
        release this version" is selected (vs. "Automatically release
        this version").

      * Back at the top, hit "Save" and then "Add for Review", and hit
        "Submit for Review" in the resulting modal sidebar.

    * The draft listing should enter state "Waiting for Review".  From
      here, it typically takes a day or so to get a result from the
      Apple review process; if it passes review, we can push one more
      button to roll it out.

[asc-external]: https://appstoreconnect.apple.com/apps/1203036395/testflight/groups/1bf18c25-da12-4bad-8384-9dd872ce447f
[asc-main]: https://appstoreconnect.apple.com/apps/1203036395/distribution/info


## Release to production

Historically we would wait a couple of days after sending to beta
before sending to production.  More recently (since 2025) we've
been sending a typical release to production promptly after beta.
Discussion thread: [#mobile-team > mobile releases @ 💬](https://chat.zulip.org/#narrow/channel/243-mobile-team/topic/mobile.20releases/near/2218205)


* Android via Play Store:

  * In the Play Console, go to [Release > Testing >
    Open testing][play-open-testing].

  * Under the release you want to promote, choose "Promote release >
    Production".

  * Under "Staged roll-out", set 100% as the roll-out percentage.

    * Occasionally we start with a smaller percentage.  In that case,
      remember to come back later to make a 100% rollout.

  * Confirm and send to Google for review.

[play-open-testing]: https://play.google.com/console/developers/8060868091387311598/app/4976350040864490411/tracks/open-testing


* Android via GitHub:

  * Edit the release [on GitHub][gh-releases].  Uncheck
    "Set as a pre-release", and check "Set as the latest release".

[gh-releases]: https://github.com/zulip/zulip-flutter/releases


* iOS via App Store:

  * (This assumes the new version was submitted for App Store review
    at the time of the beta rollout, and accepted.  See beta steps
    above for how to submit it.)

  * In App Store Connect for the app, go to [Distribution > iOS App >
    (the draft release)][asc-inflight].

  * Hit the big blue button at top right to release to the App Store.

[asc-inflight]: https://appstoreconnect.apple.com/apps/1203036395/appstore/ios/version/inflight


## Announce

* Announce the updated beta in
  [#announce > mobile releases][releases-thread].

  For release notes, use `tools/format-changelog czo`.

[releases-thread]: https://chat.zulip.org/#narrow/stream/1-announce/topic/mobile.20releases

* For any fixed issues that were tagged "user feedback", or otherwise
  had people outside the mobile team specifically interested in them,
  follow up with the requesters: post on the relevant thread (in
  GitHub or Zulip) and @-mention the individuals who asked for the
  change.

  In particular, for each fixed issue 123, do a Zulip search for
  "f123".  This efficiently finds any threads that mentioned "#F123".


## Preview releases

Sometimes we make a release that includes some experimental changes
not yet merged to the `main` branch, i.e. a "preview release".

Steps specific to this type of release are:

* To prepare the tree, start from main and use commands like
  `git merge --no-ff pr/123456` to merge together the desired PRs.

  The use of `--no-ff` ensures that each such step creates an actual
  merge commit.  This is helpful because it means that a command like
  `git log --first-parent --oneline origin..`
  can print a list of exactly which PRs were included, by number.
  That record is useful for understanding the relationship between
  releases, and for re-creating a similar branch with updated versions
  of the same PRs.

* The changelog should distinguish, outside the "for users" section,
  between changes in main and changes not yet in main.
  See past examples; search for "experimental".

* After the new release is uploaded, the changelog and version number
  in main should be updated to match the new release.

  Try `git checkout -p v12.34.567 docs/changelog.md pubspec.yaml`.
  Use the `-p` prompt to skip any other pubspec updates, such as
  dependencies.  Then
  `git commit -am "version: Sync version and changelog from v12.34.567 release"`
  (with the correct version number), and push.


## Security releases

Very occasionally, we find a security vulnerability in the app.
When a release fixes a vulnerability which isn't already public,
we follow a variation of the process above.

The goal is to get the update onto most users' phones almost before
the issue is disclosed, minimizing the window where the issue is
public and users are still vulnerable.

### Preparing commit

* Write the fixes on a private branch, but don't push to the main repo (or
  other public repos.)

* Prepare and QA the commit as usual.  We'll be skipping the beta phase, so
  be especially diligent with the QA, and choosy in what commits to include.
  Definitely make it a stable release, with only hand-picked changes on top
  of the last release.

* Tag the commit, but don't push it yet.

### Android prep

* Build and upload to Google Play, but release only to alpha for now.
  Repeat manual QA with the alpha.

* Also send for Google's review to promote to both beta and
  production, but adjust settings so that it will wait to roll out
  until we later hit a button saying so.

  (The last time we needed this procedure was years ago, before the
  Play Store had blocking reviews on updates, so we've not yet
  actually done this step in practice.)

* Don't upload to GitHub yet.

### iOS prep

* Build and upload to App Store Connect, but release only to alpha for now.
  Repeat manual QA with the alpha.

* Follow the steps to release to production, with one change: in the draft
  listing, find the option for "Manually release this version", and select it.

### Release

* Wait for Apple's review; on success, the app will enter state "Pending
  Developer Release".  (On failure, try to fix the issue, then resubmit.)
  Similarly wait for Google's review.

* Now release the app to both the App Store and the Play Store.

* Also now submit to TestFlight, for beta users on iOS.
  Wait for that to go out before discussing further in public.

### Followup

* Wait for the release to be approved for TestFlight.
  (On failure, try to fix, then resubmit.)

* Push the tagged commit, and also push the corresponding changes to main.

* Upload the APKs to GitHub as usual.

* Discuss freely.


<div id="setup" />

## One-time or annual setup

### Prepare Android

You'll need the Google Play upload key.
This key also serves as the [app signing key][] for
the APK and AAB files we publish directly via GitHub releases.
As the linked upstream doc explains, this is a highly sensitive secret
which it's very important to handle securely.

[app signing key]: https://developer.android.com/studio/publish/app-signing#secure_key

(This setup is similar to what we used for the legacy mobile app,
but the key is a fresh one.)

* Get the keystore file, and the keystore properties file.
  An existing/previous release manager can send these to you,
  encrypted to your PGP key.

  * Never make an unencrypted version visible to the network or to a
    cloud service (including Zulip).

* Put the release-signing keystore, PGP-encrypted to yourself,
  at `android/release.keystore.pgp`.

  * Don't leave an unencrypted version on disk, except temporarily.
    The script `tools/checkout-keystore` will help manage this; see
    `tools/checkout-keystore --help` and release instructions above.

* Put the keystore properties file at
  `android/release-keystore.properties`.
  It looks like this (passwords redacted):

```
storeFile=release.keystore
keyAlias=zulip-mobile
storePassword=*****
keyPassword=*****
```


### Prepare iOS

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


## Terminology

This section defines the terms **alpha**, **beta**, and **production**
(or **prod**) as used in this document and in our release process.

Google and Apple each have different terminology for the various
channels of progressively wider release.  We don't use or need the
full complexity of either one, and for sanity's sake we use a common,
simple terminology for the process we follow with both.

* **Alpha**: A release only to active developers of the app.
  See [instructions][join-alpha] for joining.

  * What this means on each platform:
    * Google Play: release to "Internal testing"
    * iOS: release in TestFlight to "App Store Connect Users"
    * GitHub: a Git tag

  * On both Google Play and TestFlight, a new version in this channel
    is available for update immediately on devices.  We use it for
    final manual QA before releasing to beta or production.

  * NB Google Play has its own feature it calls "Alpha"
    (aka "Closed testing"), which is sort of intermediate between
    "Internal testing" and "Open testing".
    We don't use that feature.

[join-alpha]: https://github.com/zulip/zulip-mobile/blob/main/docs/howto/alpha.md


* **Beta**: A release to users who have volunteered to get new versions
  early and give us feedback.  See
  [instructions](https://github.com/zulip/zulip-mobile#using-the-beta) for
  joining.

  * What this means on each platform:
    * Google Play: release to "Open testing"
    * iOS: release to all our TestFlight users (through the
      "External Testers" group)
    * GitHub: a GitHub release with binaries and description,
      marked as pre-release

  * We sometimes use this channel for wider testing of a release
    before sending to production: historically about 2-4 days for a
    typical new release.  More recently we tend to leave a release in
    beta for at most 1 day before sending to prod; see discussion
    above.

  * NB Google Play also calls this "Beta track" or "Open track", as
    well as "Open testing".


* **Production** (aka **prod**): A general release to all users.

  * What this means on each platform:
    * Google Play: release to "Production"
    * iOS: release to the App Store
    * GitHub: a GitHub release with binaries and description,
      not marked pre-release

  * On iOS there is a gotcha we've occasionally fallen for in the
    past: because releasing to the App Store is mostly a separate
    process from releasing to TestFlight, it's easy to release a given
    version to the App Store without ever interacting with TestFlight.
    If we do, our beta users will simply never get that version, and
    stay on the (older) last version we gave them.
    Naturally this isn't good for our kind beta users, nor for us; so
    don't do this. :)
