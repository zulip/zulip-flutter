# Push notifications

This doc describes how to test and develop changes to Zulip's mobile
push notifications.

#### Contents (with permalinks)

* [General tips](#general-tips)
* [Testing server-side changes (iOS or Android)](#server)
* [Testing client-side changes on Android](#android)
* [Testing client-side changes on iOS](#ios)


<div id="general-tips" />

## General tips

When testing Zulip's push notifications:

* Try simulating a DM conversation between two users: one on the
  mobile device, and one from your desktop.  For example, if you've
  logged in as "Iago" on your mobile device, log in as "Polonius" via
  a web browser, and send a DM from Polonius to Iago.

* Test different types of messages that will cause different types of
  notifications: a 1:1 DM conversation, a group DM conversation, an
  @-mention in a channel, a channel with notifications turned on, even
  an @-mention in a 1:1 or group DM conversation.

* Make sure "mobile push notifications" are on in the mobile user's
  Zulip settings!

  * Try also turning on [the "even while online"
    setting](https://zulip.com/help/test-mobile-notifications) --
    this is extremely helpful for testing notifications effectively,
    with basically the one exception of if you're specifically working
    on the "if online" aspect of the system.

* Make sure notifications are enabled for Zulip in the device's system
  settings!

  * To get to these, find "Notifications" or "Apps & Notifications" in
    the system settings app, depending on OS and version; then find
    Zulip in the list.  Or on Android, in the launcher give the app's
    icon a long-press -> "App Info" -> "Notifications".

  * Also check the settings there for whether and how the app's
    notifications will pop on the screen, make a sound, etc.

  * Particularly for the debug build on one's personal device, it's
    natural to disable notifications between development sessions to
    suppress duplicates... then forget to re-enable them.

* Leave the app in the background: that is, switch to the launcher /
  home screen or to a different app to get it off the screen.  Or
  keep it on screen, or force-kill it, to test different scenarios!


<div id="server" />

## Testing server-side changes (iOS or Android)

When making changes to the Zulip server, use these steps to test how
they affect notifications.

First, three one-time setup steps:

1. [Set up the dev server for mobile development](dev-server.md).

2. Create a `zproject/custom_dev_settings.py` with the following line:

   ```python
   ZULIP_SERVICES_URL = 'https://push.zulipchat.com'
   ```

   This matches the normal setting for a production install of the
   Zulip server (set by `zproject/default_settings.py`).

   The Zulip server will helpfully print a line on startup to remind
   you that this settings override file exists.

3. Register your development server with our production bouncer by
   running a command like this one, but with `[yourname]` replaced by
   your name:

   ```
   EXTERNAL_HOST=[yourname].zulipdev.com:9991 python manage.py register_server --agree-to-terms-of-service
   ```

   (The exact value of `EXTERNAL_HOST` doesn't matter; in particular
   it doesn't need to match the `EXTERNAL_HOST` that you use when
   actually running the server, with `tools/run-dev`.  It does need to
   be distinct from any names that others have already registered.)

   This is a variation of our [instructions for production
   deployments](https://zulip.readthedocs.io/en/latest/production/mobile-push-notifications.html),
   adapted for the Zulip dev environment.

   You should only have to do this step once, unless you build a new
   Zulip server dev environment from scratch.  The credentials which
   this command registers with the bouncer are kept in the
   `zproject/dev-secrets.conf` file.

4. If you were already running `tools/run-dev`, quit and restart it
   after these setup steps.


Then, each time you test:

1. Run `tools/run-dev` according to the instructions in
   [dev-server.md](dev-server.md).  Then follow that doc's
   instructions to log into the dev server.  Use the release build of
   the app -- that is, the Zulip app installed from the App Store or
   Play Store.

2. Follow the general tips above to cause a push notification.  For
   example, log in from a browser as a different user, and send the
   mobile user a DM.

   You should see a push notification appear on the mobile device!

   If you don't, check the general tips above.  Then ask in chat and
   let's debug.


<div id="android" />

## Testing client-side changes on Android

Happily, this is straightforward: just edit, build, and run the app
the same as for any other change.

If you're editing Kotlin code (not only Dart), then
Flutter's hot reload and hot restart won't pick that up;
you'll need to stop the app and use `flutter run` afresh.


<div id="ios" />

## Testing client-side changes on iOS

Apple makes this much more of a pain than it is on Android: APNs (*)
does not allow our production bouncer to send notifications to a
development build of the app.

(*) i.e. "Apple Push Notification service" -- Apple is very Apple
about this name, styling it without an article and with the
idiosyncratic capitalization shown.


### Current workaround

This workaround means using a development server.  You'll first need
to [set up the dev server for mobile development](dev-server.md).

You can tell your development server to talk to Apple's APNs "sandbox"
server, instead of its server meant for production, but you'll need a
certificate signed by Apple authorizing you to do so. Some background
on that is
[here](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/sending_notification_requests_to_apns/#2947606).

1. First, generate a certificate signing request (CSR) and
   corresponding private key.  Use the `tools/setup/apns/prep-cert`
   script from the Zulip server tree:
   ```
   $ tools/setup/apns/prep-cert request /tmp/apns.key /tmp/apns.csr
   ```

2. Greg is authorized in Apple Developer to upload the CSR and obtain
   the actual certificate, so you should send `apns.csr` to him and
   ask him to do that.  He'll follow the steps at
   https://developer.apple.com/account/resources/certificates/add
   with:
   * Cert type: “Apple Push Notification service SSL (Sandbox)"
     (not "Sandbox & Production")
   * App ID: 66KHCWMEYB.org.zulip.Zulip

   to obtain a certificate file `aps_development.cer`,
   and send it back to you.

3. Combine the certificate with the key using the same tool:
   ```
   $ tools/setup/apns/prep-cert combine \
       /tmp/apns.key /tmp/aps_development.cer zproject/apns-dev.pem
   ```

   The file `zproject/apns-dev.pem` is the output of all the steps
   up to this point.
   You can now delete the other files `/tmp/apns.key`, `/tmp/apns.csr`,
   and `/tmp/aps_development.cer`.

4. Restart `tools/run-dev` to let the server pick up the change.
   It should automatically see the file `zproject/apns-dev.pem`
   and use it to communicate with the APNs sandbox server.

You should now be getting notifications on your iOS development build!


#### Troubleshooting

If it's not working, first check that mobile notification settings are
on, using the web app's settings interface.  See also the
troubleshooting items below.

If none of those resolve the issue, please ask for help
in [#mobile-dev-help](https://chat.zulip.org/#narrow/channel/516-mobile-dev-help) on
chat.zulip.org, so we can debug.


##### Error: Your plan doesn't allow sending push notifications

After the above setup is done, when the dev server tries to send a
notification (e.g. because you had some other user send a DM to the
user you've logged in as from the mobile app), you might get an error
like this one (reformatted for readability):

```
INFO [zerver.lib.push_notifications] Sending push notifications to mobile clients for user 11
INFO [zr] 127.0.0.1       POST    400   8ms (db: 3ms/6q) /api/v1/remotes/push/notify [can_push=False/Missing data] (zulip-server:… via ZulipServer/11.0-dev+git)
INFO [zr] status=400, data=b'{"result":"error","msg":"Your plan doesn\'t allow sending push notifications.","code":"INVALID_ZULIP_SERVER"}\n', uid=zulip-server:…
WARN [django.server] "POST /api/v1/remotes/push/notify HTTP/1.1" 400 109
ERR  [] Problem handling data on queue missedmessage_mobile_notifications
Traceback (most recent call last):
…
  File "/srv/zulip/zerver/lib/remote_server.py", line 195, in send_to_push_bouncer
    raise PushNotificationBouncerError(
zerver.lib.remote_server.PushNotificationBouncerError:
  Push notifications bouncer error: Your plan doesn't allow sending push notifications.
```

It's not clear why this happens.  Try stopping the server
(i.e. `tools/run-dev`) and starting it again.  On the
[one occasion][error-plan-missing] this error has been seen
as of this writing, the error went away after doing so.

[error-plan-missing]: https://chat.zulip.org/#narrow/channel/243-mobile-team/topic/notifications.20from.20dev.20server/near/2163051


##### Error: BadDeviceToken

When the dev server tries to send a notification,
you might get in the server log an error like this one
(reformatted for readability):

```
INFO [zerver.lib.push_notifications] Sending push notifications to mobile clients for user 11
…
INFO [zerver.lib.push_notifications] APNs: Removing invalid/expired token FD524D9B9018CB7340051C26E4F99304F71D4B37E2164265AB0BBA3543225331 (BadDeviceToken)
…
INFO [zerver.lib.push_notifications] Deleting push tokens based on response from bouncer: Android: [], Apple: ['FD524D9B9018CB7340051C26E4F99304F71D4B37E2164265AB0BBA3543225331']
```

This can happen when you're using a release build of the app
(such as the one from TestFlight or the App Store),
which the server's sandbox-only certificate is unable to send to.
To fix it, use a debug build of the app.


##### Error: TopicDisallowed

When the dev server tries to send a notification,
you might get in the server log an error like this one
(reformatted for readability):

```
INFO [zerver.lib.push_notifications] Sending push notifications to mobile clients for user 11
INFO [zilencer.views] Sending mobile push notifications for remote user 1db86aa5-1327-4c03-8db8-c8189aa23b0c:<id:11><uuid:29acb8b2-4500-4268-80e5-219fd9af2c2d>: 0 via FCM devices, 1 via APNs devices
INFO [zerver.lib.push_notifications] APNs: Sending notification for remote user 1db86aa5-1327-4c03-8db8-c8189aa23b0c:<id:11><uuid:29acb8b2-4500-4268-80e5-219fd9af2c2d> to 1 devices (skipped 0 duplicates)
WARN [zerver.lib.push_notifications] APNs: Failed to send for user <id:11><uuid:29acb8b2-4500-4268-80e5-219fd9af2c2d> to device 34FBEF8A439C8F9B6CC6AEFC42CDFD2A9618FFA3E0C8C50B9A56CB96D3F2D727: TopicDisallowed
```

This can happen when the app's bundle ID
(which gets used as an APNs "topic")
is different from the one your server's APNs certificate is for.
To fix it, either get a certificate for the desired topic,
or edit the app's bundle ID to match the certificate.

To edit the bundle ID, try a command like:
```
$ perl -i -0pe 's/org\.zulip\.Zulip/OTHER_NAME/g' \
    -- $(git grep -l org.zulip.Zulip)
```


### Another workaround (if the first doesn't work)

Make a release build of the app, and upload it [as an alpha][].
Update your device to the alpha from TestFlight, and test there.

[as an alpha]: ../release.md#build-and-upload-alpha-ios

This works OK, but it's slow: about 5m to build and upload, and
another few on Apple's servers before it's available in alpha.  In
total perhaps 10m from "save and hit go" to actually getting to test.

The long iteration cycle can be tolerable for changes that are very
likely to need only zero to one revision -- because they're very
small, or already well tested on Android -- but makes serious
development basically infeasible.


#### Tip: setting the iOS build number

For making a throwaway alpha build like this approach calls for,
you'll want to set the [iOS build number][].

In a Flutter app, this is set through `pubspec.yaml`, as
the portion after the `+` in the `version` field.
(The portion before the `+` is the user-facing [version number][].)

The build number needs to be set so that the new build can
coexist on TestFlight with previous and future builds.
Specifically, the rule appears to be:

 * The user-facing version number must be strictly greater than the
   last one published to the App Store.

 * The user-facing version number can stay the same across a series of
   alpha and/or beta releases, but the build number must strictly
   increase.

So if the last version in main is already in the App Store (and not
still in alpha or beta), then we'll want to:

 * Increment the user-facing version number.

 * To avoid confusion when we next release, use a build number
   starting with "0." -- e.g., `0.0.1` or `0.20260414.1`.

For example if `pubspec.yaml` currently has a line like this,
reflecting a version that's already in the App Store:
```
version: 30.0.271+271
```

then you might edit it to read like this:
```
version: 30.0.272+0.20260414.1
```

[iOS build number]: https://developer.apple.com/documentation/bundleresources/information_property_list/cfbundleversion
[version number]: https://developer.apple.com/documentation/bundleresources/information_property_list/cfbundleshortversionstring


### Possible future solution

Better yet, for many development purposes, would be to be able to
dispense with a local dev server, and still get notifications from
zulipchat.com and chat.zulip.org in a development build of the app.

The ingredient that'd be needed for that is to get a production
Zulip server, or the production bouncer it talks to,
to optionally send notifications through
Apple's sandbox instance of APNs.

* One way to arrange that might be to have the production bouncer talk
  to either the production or staging instance of APNs; the client
  tell the Zulip server which one to use for that client's
  notifications, and the Zulip server pass that information on to the
  bouncer.

* Another might be to leave the bouncer out of it, and have the Zulip
  server talk directly to the sandbox APNs when the client asks it to,
  rather than talk to the bouncer.
