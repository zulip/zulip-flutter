# Testing Push Notifications on iOS Simulator

For documentation on testing push notifications on Android or a real
iOS device, see https://github.com/zulip/zulip-mobile/blob/main/docs/howto/push-notifications.md

This doc describes how to test client-side changes on iOS Simulator.
It will demonstrate how to use APNs payloads the server sends to
the Apple Push Notification service to show notifications on iOS
Simulator.


### Contents

* [Trigger a notification on the iOS Simulator](#trigger-notification)
* [Canned APNs payloads](#canned-payloads)
* [Produce sample APNs payloads](#produce-payload)


<div id="trigger-notification" />

## Trigger a notification on the iOS Simulator

The iOS Simulator permits delivering a notification payload
artificially, as if APNs had delivered it to the device,
but without actually involving APNs or any other server.

As input for this operation, you'll need an APNs payload,
i.e. a JSON blob representing what APNs might deliver to the app
for a notification.

To get an APNs payload, you can generate one from a Zulip dev server
by following the [instructions in a section below](#produce-payload),
or you can use one of the payloads included
in this document [below](#canned-payloads).


### 1. Determine the device ID of the iOS Simulator

To receive a notification on the iOS Simulator, we need to first
determine the device ID of the iOS Simulator, to specify which
Simulator instance we want to push the payload to.

```shell-session
$ xcrun simctl list devices booted
```

<details>
<summary>Example output:</summary>

```shell-session
$ xcrun simctl list devices booted
== Devices ==
-- iOS 18.3 --
    iPhone 16 Pro (90CC33B2-679B-4053-B380-7B986A29F28C) (Booted)
```

</details>


### 2. Trigger a notification by pushing the payload to the iOS Simulator

By running the following command with a valid APNs payload, you should
receive a notification on the iOS Simulator for the zulip-flutter app.
Tapping on the notification should route to the respective conversation.

```shell-session
$ xcrun simctl push [device-id] org.zulip.Zulip [payload json path]
```

<details>
<summary>Example output:</summary>

```shell-session
$ xcrun simctl push 90CC33B2-679B-4053-B380-7B986A29F28C org.zulip.Zulip ./dm.json
Notification sent to 'org.zulip.Zulip'
```

</details>


<div id="canned-payloads" />

## Canned APNs payloads

The following pre-canned APNs payloads can be used in case you don't
have one.

These canned payloads were generated from
Zulip Server 11.0-dev+git 8fd04b0f0, API Feature Level 377,
in April 2025.
The `user_id` is that of `iago@zulip.com` in the Zulip dev environment.

These canned payloads assume that EXTERNAL_HOST has its default value
for the dev server. If you've
[set EXTERNAL_HOST to use an IP address](https://github.com/zulip/zulip-mobile/blob/main/docs/howto/dev-server.md#4-set-external_host)
in order to enable your device to connect to the dev server, you'll
need to adjust the `realm_url` fields. You can do this by a
find-and-replace for `localhost`; for example,
`perl -i -0pe s/localhost/10.0.2.2/g tmp/*.json` after saving the
canned payloads to files `tmp/*.json`.

<details>
<summary>Payload: dm.json</summary>

```json
{
    "aps": {
        "alert": {
            "title": "Zoe",
            "subtitle": "",
            "body": "But wouldn't that show you contextually who is in the audience before you have to open the compose box?"
        },
        "sound": "default",
        "badge": 0,
    },
    "zulip": {
        "server": "zulipdev.com:9991",
        "realm_id": 2,
        "realm_uri": "http://localhost:9991",
        "realm_url": "http://localhost:9991",
        "realm_name": "Zulip Dev",
        "user_id": 11,
        "sender_id": 7,
        "sender_email": "user7@zulipdev.com",
        "time": 1740890583,
        "recipient_type": "private",
        "message_ids": [
            87
        ]
    }
}
```

</details>

<details>
<summary>Payload: group_dm.json</summary>

```json
{
    "aps": {
        "alert": {
            "title": "Othello, the Moor of Venice, Polonius (guest), Iago",
            "subtitle": "Othello, the Moor of Venice:",
            "body": "Sit down awhile; And let us once again assail your ears, That are so fortified against our story What we have two nights seen."
        },
        "sound": "default",
        "badge": 0,
    },
    "zulip": {
        "server": "zulipdev.com:9991",
        "realm_id": 2,
        "realm_uri": "http://localhost:9991",
        "realm_url": "http://localhost:9991",
        "realm_name": "Zulip Dev",
        "user_id": 11,
        "sender_id": 12,
        "sender_email": "user12@zulipdev.com",
        "time": 1740533641,
        "recipient_type": "private",
        "pm_users": "11,12,13",
        "message_ids": [
            17
        ]
    }
}
```

</details>

<details>
<summary>Payload: stream.json</summary>

```json
{
    "aps": {
        "alert": {
            "title": "#devel > plotter",
            "subtitle": "Desdemona:",
            "body": "Despite the fact that such a claim at first glance seems counterintuitive, it is derived from known results. Electrical engineering follows a cycle of four phases: location, refinement, visualization, and evaluation."
        },
        "sound": "default",
        "badge": 0,
    },
    "zulip": {
        "server": "zulipdev.com:9991",
        "realm_id": 2,
        "realm_uri": "http://localhost:9991",
        "realm_url": "http://localhost:9991",
        "realm_name": "Zulip Dev",
        "user_id": 11,
        "sender_id": 9,
        "sender_email": "user9@zulipdev.com",
        "time": 1740558997,
        "recipient_type": "stream",
        "stream": "devel",
        "stream_id": 11,
        "topic": "plotter",
        "message_ids": [
            40
        ]
    }
}
```

</details>


<div id="produce-payload" />

## Produce sample APNs payloads

### 1. Set up dev server

To set up and run the dev server on the same Mac machine that hosts
the iOS Simulator, follow Zulip's
[standard instructions](https://zulip.readthedocs.io/en/latest/development/setup-recommended.html)
for setting up a dev server.

If you want to run the dev server on a different machine than the Mac
host, you'll need to follow extra steps
[documented here](https://github.com/zulip/zulip-mobile/blob/main/docs/howto/dev-server.md)
to make it possible for the app running on the iOS Simulator to
connect to the dev server.


### 2. Set up the dev user to receive mobile notifications.

We'll use the devlogin user `iago@zulip.com` to test notifications.
Log in to that user by going to `/devlogin` on that server on Web.

Then follow the steps [here](https://zulip.com/help/mobile-notifications)
to enable Mobile Notifications for "Channels".


### 3. Log in as the dev user on zulip-flutter.

<!-- TODO(#405) Guide to use the new devlogin page instead -->

To log in as this user in the Flutter app, you'll need the password
that was generated by the development server. You can print the
password by running this command inside your `vagrant ssh` shell:
```
$ ./manage.py print_initial_password iago@zulip.com
```

Then run the app on the iOS Simulator, accept the permission to
receive push notifications, and then log in as the dev user
(`iago@zulip.com`).


### 4. Edit the server code to log the notification payload.

We need to retrieve the APNs payload the server generates and sends
to the bouncer. To do that we can add a log statement after the
server completes generating the payload in `zerver/lib/push_notifications.py`:

```diff
     apns_payload = get_message_payload_apns(
         user_profile,
         message,
         trigger,
         mentioned_user_group_id,
         mentioned_user_group_name,
         can_access_sender,
     )
     gcm_payload, gcm_options = get_message_payload_gcm(
         user_profile, message, mentioned_user_group_id, mentioned_user_group_name, can_access_sender
     )
     logger.info("Sending push notifications to mobile clients for user %s", user_profile_id)
+    logger.info("APNS payload %s", orjson.dumps(apns_payload).decode())

     android_devices = list(
         PushDeviceToken.objects.filter(user=user_profile, kind=PushDeviceToken.FCM).order_by("id")
```


### 5. Send messages to the dev user

To generate notifications to the dev user `iago@zulip.com` we need to
send messages from another user. For a variety of different types of
payloads try sending a message in a topic, a message in a group DM,
and one in one-one DM. Then look for the payloads in the server logs
by searching for "APNS payload".


### 6. Transform and save the payload to a file

The payload JSON recorded in the steps above is in the form the
Zulip server sends to the bouncer.  The bouncer restructures this
slightly to produce the actual payload which it sends to APNs,
and which APNs delivers to the app on the device.
To apply the same restructuring, run the payload through
the following `jq` command:

```shell-session
$ echo '{"alert":{"title": ...' \
    | jq '{aps: {alert, sound, badge}, zulip: .custom.zulip}' \
    > payload.json
```
