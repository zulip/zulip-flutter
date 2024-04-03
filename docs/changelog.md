# Changelog

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

Resolved: #327, #185, #214, #475, #461, #443, #173, #359, #479


## 0.0.8 (2023-12-22)

First beta release.
