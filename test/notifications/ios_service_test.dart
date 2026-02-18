import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/host/ios_notifications.g.dart';
import 'package:zulip/notifications/ios_service.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';
import 'open_test.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  IosNotifFlutterApi iosNotifFlutterApi() => TestZulipBinding.instance.iosNotifFlutterApi!;

  test('smoke', () async {
    IosNotificationService.init();

    final title = 'test title';
    final content = 'test content';
    final payload = messageApnsPayload(
      eg.streamMessage(content: content),
      title: title);

    final result = await iosNotifFlutterApi()
      .didReceivePushNotification(NotificationContent(payload: payload));
    check(result)
      ..title.equals(title)
      ..body.equals(content);
  });
}

extension on Subject<MutatedNotificationContent> {
  Subject<String> get title => has((x) => x.title, 'title');
  Subject<String?> get body => has((x) => x.body, 'body');
}
