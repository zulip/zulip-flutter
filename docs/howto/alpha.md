# Joining the alpha channel

If you're actively developing the app, you should join the [alpha
channel](../release.md#terminology) so that when we make an alpha
release you get it on your normal devices you use daily.  This means
you'll see any regressions we have, so you can help find and fix them
before they go out wider.

* **Android**: A maintainer will add you to the list, and then give
  you a link you'll use to confirm.

  (Maintainer: see [Release > Testing > Internal testing >
  Testers][play-internal-testers] in the Play Console.)

* **iOS**: A maintainer will send you an invite to join App Store Connect.
  Then after you join, there's a second step to join the list of users that
  get alpha updates.

  (Maintainer: that list is confusingly labeled in the UI as simply
  ["App Store Connect Users"][] — don't be fooled.  Confirm the
  person is on it; if not, see the plus-sign icon next to the
  "Testers" heading, which lets you send an invite for that step.)

[join-beta]: https://github.com/zulip/zulip-mobile#using-the-beta
[play-internal-testers]: https://play.google.com/console/developers/8060868091387311598/app/4976350040864490411/tracks/internal-testing?tab=testers
["App Store Connect Users"]: https://appstoreconnect.apple.com/apps/1203036395/testflight/groups/d246e92d-76a2-4b3e-8293-347a1a6e27ab


## Joining the beta channel

Historically we also used a [beta channel](../release.md#terminology).
Our current practice is that the beta channel is nearly equivalent to
the prod channel, though, so there's little effect to be had from
joining the beta.

Here are the instructions for joining the beta channel, mostly for the
purpose of internal notes in case we decide to revive the use of it:

* Android: install the app, then just
  [join the testing program](https://play.google.com/apps/testing/com.zulipmobile/)
  on Google Play.
  * Or if you don't use Google Play, you can [download an
    APK](https://github.com/zulip/zulip-flutter/releases/); the latest
    release on GitHub (including "pre-releases") is the current beta.

* iOS: install [TestFlight](https://developer.apple.com/testflight/testers/),
  then open [this public invitation link](https://testflight.apple.com/join/ZuzqwXGf)
  on your device.
