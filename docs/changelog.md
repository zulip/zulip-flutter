# Changelog

## Unreleased

### Highlights for users

* The app should now always get back to showing live data once your
  device is back on the Internet, regardless of any previous lack of
  connection. (#184)
* (Android) Notifications now work, after several fixes.  If they
  don't for you, please report the issue. (#520, #342, #528)
* The app navigates straight to the inbox upon launch. (#516)
* More Zulip message features: global times, spoiler blocks,
  and image thumbnails side by side. (#354, #358, #193)
* Other fixes and improvements too as usual.


### Highlights for developers

* Upgrading dependencies is more automated. (#523)
* Content tests are easier to write, especially for widgets. (#511)

Resolved: #354, #507, #441, PR #511, #384, #193, #520, #516, PR #523,
  #184, PR #522, #342, #528, #358


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

Resolved: #327, #185, #214, #475, #461, #443, #173, #359, #479


## 0.0.8 (2023-12-22)

First beta release.
