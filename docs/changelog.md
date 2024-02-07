# Changelog

## 0.0.10 (2024-02-06)

### Highlights for users

* The message list has a new layout, to better use the full width of
  the screen. (#446, toward #157)
* You can now star and unstar messages. (#170)
* The keyboard when typing a message now auto-capitalizes
  sentences. (#487)
* Headings like `# this` are now rendered in messages. (#192)
* Bold code (like **`this`**) is once again bold. (#498)
* (Android) Unicode emoji now use a consistent set of emoji glyphs
  across all Android devices. (#438)
* We now set a user-agent string in requests to the server,
  making login notifications more informative. (#406, #460)


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
