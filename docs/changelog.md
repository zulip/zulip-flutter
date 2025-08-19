# Changelog

## Unreleased


## 0.0.34 (2025-08-18)

This is a release from the "beta-prelaunch" branch, with selected
changes atop the previous pre-launch beta release 0.0.33.


### Highlights for users

Thanks for being a beta tester of the new Zulip app!

This app became the main Zulip mobile app in June 2025, and this
beta version is no longer maintained.  We recommend uninstalling
this beta after switching to the main Zulip app, in order to get
the latest features and bug fixes.

Changes in this version from the previous beta:
* Give a notice on startup that this beta version is no longer
  maintained, with links to switch to the main Zulip app. (#1603)


### Highlights for developers

* Resolved in this beta branch: #1603


## 0.0.33 (2025-06-13)

This is a preview beta, including some experimental changes
not yet merged to the main branch.


### Highlights for users

This app is nearing ready to replace the legacy Zulip mobile app,
planned for next week.

In addition to all the features in the last beta:
* Messages are automatically marked read as you scroll through
  a conversation. (#81)
* More translations.


### Highlights for developers

* User-visible changes not described above:
  * "Quote message" button label rather than "Quote and reply"
    (PR #1575)

* Resolved in main: PR #1575, #81

* Resolved in the experimental branch:
  * more toward #46 via PR #1452
  * further toward #46 via PR #1559
  * #296 via PR #1561


## 0.0.32 (2025-06-12)

This is a preview beta, including some experimental changes
not yet merged to the main branch.


### Highlights for users

This app is nearing ready to replace the legacy Zulip mobile app,
planned for next week.

In addition to all the features in the last beta:
* The keyboard opens immediately when you start a
  new conversation. (#1543)
* Translation updates, including new near-complete translations
  for Slovenian (sl) and Chinese (Simplified, China) (zh_Hans_CN).
* Several small improvements to the newest features:
  muted users (#296), message links going directly to message (#82).


### Highlights for developers

* User-visible changes not described above:
  * upgraded Flutter and deps (PR #1568)
  * suppress long-press on muted-sender message,
    and hide muted users in new-DM list (part of #296)
  * reject internal links with malformed /near/ operands
    (part of #82)

* Resolved in main: #276 (though external to the tree),
  #1543, #82, #80, #1147, #1441

* Resolved in the experimental branch:
  * more toward #46 via PR #1452
  * further toward #46 via PR #1559
  * #296 via PR #1561


## 0.0.31 (2025-06-11)

This is a preview beta, including some experimental changes
not yet merged to the main branch.


### Highlights for users

This app is nearing ready to replace the legacy Zulip mobile app,
planned for next week.

In addition to all the features in the last beta:
* Conversations open at your first unread message. (#80)
* TeX support now enabled by default, and covers a larger
  set of expressions.  More to come later. (#46)
* Numerous small improvements to the newest features:
  muted users (#296), start a DM thread (#127),
  recover failed send (#1441), open mid-history (#82).


### Highlights for developers

* Resolved in main: #1540, #385, #386, #127

* Resolved in the experimental branch:
  * #82 via PR #1566
  * #80 via PR #1517
  * #1441 via PR #1453
  * more toward #46 via PR #1452
  * further toward #46 via PR #1559
  * #1147 via PR #1379
  * #296 via PR #1561


## 0.0.30 (2025-05-28)

This is a preview beta, including some experimental changes
not yet merged to the main branch.


### Highlights for users

We're nearing ready to have this new app replace the legacy
Zulip mobile app, a few weeks from now.

In addition to all the features in the last beta:
* Muted users are now muted. (#296)
* Improved logic to recover from failed send. (#1441)
* Numerous small improvements to the newest features.


### Highlights for developers

* Resolved in main: #83, #1495, #1456, #1158

* Resolved in the experimental branch:
  * #82, and #80 behind a flag, via PR #1517
  * #1441 via PR #1453
  * #127 via PR #1322
  * more toward #46 via PR #1452
  * #1147 via PR #1379
  * #296 via PR #1429


## 0.0.29 (2025-05-19)

This is a preview beta, including some experimental changes
not yet merged to the main branch.


### Highlights for users

This is a feature-packed release, as this new app gets near ready to
replace the legacy Zulip mobile app a few weeks from now.
Please try out the new features, and as always report anything broken.

* Initial support for TeX math!  Try enabling the
  experimental flag, in settings. (#46)
* Edit a message. (#126)
* Initial support to open at first unread message;
  try enabling in settings. (#80)
* List of topics in channel. (#1158)
* (iOS) Go to conversation on opening notification. (#1147)


### Highlights for developers

* Further user highlights that didn't fit in 500 characters:
  * #1441 simplified local echo, enabling recovery from failed send
  * #82 on following a message link, go to specific message
    in middle of history
  * #930 no more images moving around when you navigate from
    one message list to another
  * #1250 general chat
  * #1470 when you re-open the app after a while and start typing
    a message, your draft is preserved across the app's reloading
    its data from the server

* Resolved in main: #1470, #407, #1485, #930, #44, #1250, #126

* Resolved in the experimental branch:
  * #82, and #80 behind a flag, via PR #1517
  * #1441 via PR #1453
  * #1158 via PR #1500
  * #1495 via PR #1506
  * #127 via PR #1322
  * more toward #46 via PR #1452
  * #1147 via PR #1379


## 0.0.28 (2025-04-21)

### Highlights for users

* (Android) If you log out of a Zulip account, the app clears that
  account's notifications. (#1264)
* Connecting to a very old, unsupported server (Zulip Server 3.x and
  older) produces a clear error message. (#267)
* Translation updates, and a new translation: Ukrainian.


### Highlights for developers

* The app now gives an error for servers older than 4.0. (#267)

* If you switch from a later version of the app to a commit in a
  certain range (2365bb3f2..f03630805^, 23 commits), then the
  database schema downgrade will fail.  See issue for workaround.
  (#1427)

* Resolved: #1427, #1409, #267, #1264


## 0.0.27 (2025-03-17)

### Highlights for users

* Handle website previews in messages. (#1016)
* Settings for dark vs. light theme, or opening links
  in a browser within or outside the app. (#1216, #1228)
* Better handle moved or resolved topics: follow topic permalinks
  (#1028), and update inbox (#901).
* Design updates including dark-theme contrast (#973), autocomplete
  results (#913), and app icons (#1254, #415, (Android: #1402, #1401)).
* Too many other improvements and fixes to describe them all here.


### Highlights for developers

* We now have a GitHub action making a weekly PR to update
  translations from Weblate. (#276)

* All user-facing strings are now wired up for translation, or else
  have a comment saying why translation wouldn't be appropriate or
  is currently difficult. (#277)

* Resolved: #277, part of #1210, #1319, #1358, #1130, #1247, #737,
  #1246, #1172, #1028, #1016, PR #1380, #1178, #59, #1356, #973,
  PR #1315, #913, #1225, #1357, #1226, #1216, #1354, #1254, #415,
  #1402, #1401, #1228, #901


## 0.0.26 (2025-02-07)

### Highlights for users

* Resolve or unresolve a topic, from the menu after you
  press and hold the topic. (#744)
* Autocomplete now offers `@all`, `@topic`, and other
  wildcards. (#234)
* Channel names starting with emoji go at the start of the
  list. (#1202)
* Too many other improvements and fixes to describe them all here.


### Highlights for developers

* Resolved: #1205, #1289, #942, #1238, #1202, #1219, #1204, #1171,
  PR #1296, #234, #1207, #1330, #1309, #725, #744


## 0.0.25 (2025-01-13)

### Highlights for users

* The combined feed is now conveniently accessible from the app's main
  navigation bar. (#1164)
* Messages with @-topic mentions now show them properly. (#892)
* The lightbox now shows the sender's avatar. (#41)
* The About Zulip screen is now available from the main menu. (#1128)
* Too many other improvements and fixes to describe them all here.


### Highlights for developers

* Resolved in main: #892, #1177, #1164, #1177, #1128, #1189, #1116,
  #739, #41


## 0.0.24 (2024-12-11)

This is a preview beta, including some experimental changes
not yet merged to the main branch.


### Highlights for users (coming from legacy app)

Welcome to Zulip's next-gen mobile app!  In this beta:

* Much faster and smoother: try opening a busy channel and scrolling
  back through history.
* Fresh new design, matching this year's updates to Zulip on the
  desktop and web.
* Full multi-account support.

Please let us know what you think — and especially any missing
features that are critical to how you use the old Zulip mobile app.


### Highlights for users (since last beta, v0.0.23)

* All the improvements from the previous beta 0.0.23,
  plus several small fixes to its new features.
* Translations have begun: first out of the gate are contributors
  translating many strings for Polish and Russian.


### Highlights for developers

* Resolved in main: #348, #1035, #388, #945, #845

* Resolved in the experimental branch:
  * #913 via PR #995


## 0.0.23 (2024-12-09)

This is a preview beta, including some experimental changes
not yet merged to the main branch.


### Highlights for users

* New navigation structure for the app. (#1035)
* Big emoji improvements: use any emoji for reactions;
  better emoji search results; :heart: appears properly.
  (#388, #1068, #1113, #1104)
* Fixed channel-wildcard mentions for Zulip Server 10. (#1064)
* Mute, unmute, or follow topics. (#348)


### Highlights for developers

* The Flutter commit ID is recorded in pubspec.yaml alongside the
  Flutter version number, to help reproduce the exact build. (#1118)

* Resolved in main: #1064, #1104, #1115, #1113, #1118, #1119, #1068

* Resolved in the experimental branch:
    #1035, #388, #913, #845, #945, #348
  via PRs:
    #1076, #1103, #995, #1059, #1050, #1041


## 0.0.22 (2024-11-26)

### Highlights for users

* (Android) Notifications now use Zulip's custom sound by default. (#340)
* New visual design for the compose box. (#915)
* Autocomplete for emoji (":smile:"). (#670)
* Support for logging out of an account. (#463)
* Too many other improvements and fixes to describe them all here.


### Highlights for developers

* The generated localization files are now tracked in version control
  instead of going in an ephemeral `flutter_gen` package, so switching
  branches should no longer cause analysis issues (which used to
  require running `flutter pub get` or another command to
  resolve). (PR #1058)

* Resolved: #463, #340, #674, #915, PR #1058, #563, #1040, #1082,
  #669, #670, #360


## 0.0.21 (2024-11-13)

### Highlights for users

* You can now vote in polls. (#166)
* Design improvements: new bottom sheet, new bot icon,
  adjusted dark-theme colors, others. (#90, #978, #955)
* Support Zulip's new "message links". (#1046)
* Fix bug affecting code blocks in YAML and some other
  languages. (#933)
* Communicate more when unable to connect to server. (#555)
* Show others when you're typing. (#666)
* Too many other improvements and fixes to list them all here.


### Highlights for developers

* The new `tools/content/check-features` script fetches public Zulip
  messages from a server like chat.zulip.org, and identifies any
  features of Zulip message content that the app's parser calls
  unimplemented. (#190)

* Expanded developer documentation, including on setup and on
  implementing UI designs.

* Resolved: PR #972, PR #983, PR #955, #978, #90, #190, #555, #614,
  #933, #1026, #351, #166, #1046, #666, #1052, #1045, #941


## 0.0.20 (2024-10-01)

### Highlights for users

* (Android) Notifications are removed when you read the
  message. (#341)
* Show polls and their results. (#165)
* (Android) Videos play in higher quality. (#951)
* The screen stays on when you're watching a video. (#763)
* Clearer emoji in dark theme; "Starred messages" feed;
  new "edited"/"moved" labels on messages. (#953, #251, #900)
* Too many other improvements and fixes to describe them all here.


### Highlights for developers

* In tests, "matchers" from Flutter upstream can now be conveniently
  used, via `package:flutter_checks`. (#232)

* Resolved: #182, #251, #341, #905, #926, PR #919, #810, #232,
  PR #951, #763, #953, #165


## 0.0.19 (2024-08-15)

### Highlights for users

* Introducing dark theme!  The app now follows your system-wide
  dark/light setting. (#95)
* The app is snappier to re-connect to your Zulip server after
  being offline, and shows a loading indicator when doing so.
  (#554, #465)
* Handle messages being moved, muted, or unmuted while the app
  is open. (#150, #421)
* Autocomplete for topics; show "typing…" status;
  offer the "Mentions" message feed. (#310, #665, #250)
* Too many other improvements and fixes to describe them all here.


### Highlights for developers

* Many "stream" names in the codebase have been renamed to
  say "channel". (toward #631)

* Resolved: #803, #351, #613, #665, #250, #675, #858, #228,
  #712, #291, #150, #465, #554, #131, #421, #310, #879


## 0.0.18 (2024-07-25)

### Highlights for users

* Attaching an image or video to a message works properly with
  the new Zulip Server 9.0. (#829)
* When opening an image in the lightbox with the new
  Zulip Server 9.0, the image is shown at full scale from the
  beginning. (#830)
* Autocomplete for @-mentions now prioritizes showing users
  recently active in the same conversation or channel. (#828)


### Highlights for developers

* New supplemental setup instructions for doing development on
  a remote cloud server. (PR #802)

* Resolved: #829, PR #828, #830


## 0.0.17 (2024-07-19)

### Highlights for users

* (Android) Much richer notifications: multiple messages per
  conversation, sender names and avatars, and more. (#128, #569,
  #571, #572)
* Full support for image thumbnails, a feature of the upcoming Zulip Server
  9.0 which should greatly reduce Zulip's network consumption on messages
  with images. (#799)
* New "Copy link to message" option in message menu. (#673)
* The channels screen shows muted channels as muted. (#424)
* Too many other improvements and fixes to describe them all here.


### Highlights for developers

* New test suite `tools/check android` that does the Android
  build and runs the Android linter. (#772, PR #797)

* The User-Agent header in HTTP requests to the server now includes
  the app version and the OS name and version. (#467)

* Resolved: PR #728, PR #727, #736, #569, #571, #572, #393, #749,
  #771, #120, #673, #732, PR #789, #772, PR #797, #743, #467, #424,
  #128, #616, #815, #799


## 0.0.16 (2024-06-13)

### Highlights for users

* To simplify Zulip for new users, streams have been renamed to
  channels. (#630)
* When typing an @-mention, users you've DMed with recently are
  suggested first. (#693)
* Too many other improvements and fixes to describe them all here.


### Highlights for developers

* Our test suite now gets run as part of the Flutter project's
  own CI checks. (#239; PRs #696, #700)

* We've enabled Dart analyzer rules that should prevent most
  implicit use of `dynamic`. (#719)

* Resolved: #690, PR #686, PR #689, PR #687, PR #701, PR #695,
  #239, #458, #697, #77, #676, PR #709, #719, #705, #455, #602,
  #630, PR #693, PR #730, #632, #684


## 0.0.15 (2024-05-15)

### Highlights for users

* Videos in messages are now supported. (#356)
* The screen formerly known as "All messages" has a new,
  more accurate name: "Combined feed". (#634)
* (Android) Fixed bug when using third-party auth with Firefox as
  default browser. (#620)


### Highlights for developers

* The tree includes configuration for Android Studio / IntelliJ,
  which should help exclude extraneous results from search. (PR #637)

* Starting with this release, we post releases on GitHub, as well as
  on Google Play and TestFlight. (#640)

Resolved: #548, #620, #538, #612, #356, #309, #634, PR #680, #640


## 0.0.14 (2024-04-25)

### Highlights for users

* More Zulip message features: divider lines, and four-space-indented
  code blocks. (#353, #355)
* Mark bots with a bot icon, when they appear as message
  senders. (#156)


### Highlights for developers

* Dropped support for Android versions older than Android 9 Pie,
  bumping minSdkVersion from 24 to 28. (400f1a5da, PR #621)

Resolved: #353, #552 (possibly earlier), #156, #355, #518, ~~#612~~


## 0.0.13 (2024-04-02)

### Highlights for users

* You can now log in with third-party auth methods! (#36)
* (iOS) For now you may have to uninstall the main Zulip app to do
  that, though.
* Autocomplete for mentions shows avatars, and hides deactivated
  users. (#227, #451)
* Too many other improvements to describe them all here.  Those
  specifically requested by you, our beta users, include: #562
  adjusting layout, #568 on sorting streams, and #573 on notification
  titles.


### Highlights for developers

* We've started using Pigeon to generate our own thin bindings for
  platform APIs, with our own plugin `zulip_plugin` for the app's
  ad hoc needs. (PR #592)

Resolved: #108, #280, #575, #391, #562, #227, PR #592, #451, #100,
  #357, #568, #573, #36, #609, #606


## 0.0.12 (2024-03-12)

### Highlights for users

* The app should now (take 2) always get back to showing live data
  once your device is back on the Internet. (#556)
* Adjusted letter spacing to zero, particularly in messages. (#545)
* Fixed blurry avatars on the profile screen. (#301)
* Other fixes and improvements too as usual.


### Highlights for developers

Resolved: #545, #550, #301, PR #553, #556


## 0.0.11 (2024-02-29)

### Highlights for users

* The app should now always get back to showing live data once your
  device is back on the Internet. (#184)
* (Android) Notifications now work, after several fixes.  If they
  don't for you, please report the issue. (#520, #342, #528)
* The app navigates straight to the inbox upon launch. (#516)
* Larger font size for reading Zulip messages. (#512)
* More Zulip message features: global times, spoiler blocks,
  and image thumbnails side by side. (#354, #358, #193)
* Other fixes and improvements too as usual.


### Highlights for developers

* Upgrading dependencies is more automated. (#523)
* Content tests are easier to write, especially for widgets. (#511)

Resolved: #354, #507, #441, PR #511, #384, #193, #520, #516, PR #523,
  #184, PR #522, #342, #528, #358, #512, #513


## 0.0.10 (2024-02-06)

### Highlights for users

* New layout for message list, to better use the width of
  the screen. (#446)
* Starring and unstarring messages. (#170)
* Auto-capitalization when typing a message. (#487)
* Headings like `# this` are now rendered in messages. (#192)
* Bold code (like **`this`**) is once again bold. (#498)
* (Android) Unicode emoji now have a consistent appearance
  across all Android devices. (#438)
* Login notification emails are more informative, as we now
  send the server a more helpful user-agent string. (#406, #460)


### Highlights for developers

Resolved: PR #446 (toward #157), #170, #487, PR #496 (toward #80),
  #192, #294, #438, #499, #498, #406, #460, PR #375, #497


## 0.0.9 (2024-01-08)

### Highlights for users

* The message list shows date separators. (#173, #479)
* Messages with math in TeX now show the TeX source. (#359)
* Fixed issue where touching the bottom of the message list
  effectively touched the sticky header at the top instead. (#327)
* We now set up a fresh supply of new messages and other
  updated data from the server if our old supply expires. (#185)
* (Android) User-added certificate authorities are now trusted. (#461)


### Highlights for developers

Resolved: #327, #185, #214, #475, ~~#461~~, #443, #173, #359, #479


## 0.0.8 (2023-12-22)

First beta release.
