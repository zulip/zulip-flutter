# Releasing alpha versions

This is a prototype, so we make releases only to an alpha channel.

This document is a work in progress, as we haven't yet
completed such a release.


## Android

* Decrypt the upload key temporarily:

  ```
  ../mobile/tools/checkout-keystore
  ```

* Build an Android App Bundle, signed:

  ```
  flutter build appbundle -Psigned
  ```


## One-time setup

* You'll need the Google Play upload key.  The setup is similar to
  what we use for the React Native app, but the key is a fresh one.
