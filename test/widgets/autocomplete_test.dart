import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/compose.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/store.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/test_store.dart';
import '../test_images.dart';

/// Simulates loading a [MessageListPage] and tapping to focus the compose input.
///
/// Also adds [users] to the [PerAccountStore],
/// so they can show up in autocomplete.
///
/// Also sets [debugNetworkImageHttpClientProvider] to return a constant image.
///
/// The caller must set [debugNetworkImageHttpClientProvider] back to null
/// before the end of the test.
Future<Finder> setupToComposeInput(WidgetTester tester, {
  required List<User> users,
}) async {
  addTearDown(testBinding.reset);
  await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
  final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
  await store.addUsers([eg.selfUser, eg.otherUser]);
  await store.addUsers(users);
  final connection = store.connection as FakeApiConnection;

  // prepare message list data
  final message = eg.dmMessage(from: eg.selfUser, to: [eg.otherUser]);
  connection.prepare(json: GetMessagesResult(
    anchor: message.id,
    foundNewest: true,
    foundOldest: true,
    foundAnchor: true,
    historyLimited: false,
    messages: [message],
  ).toJson());

  prepareBoringImageHttpClient();

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: ZulipLocalizations.localizationsDelegates,
      supportedLocales: ZulipLocalizations.supportedLocales,
      home: GlobalStoreWidget(
        child: PerAccountStoreWidget(
          accountId: eg.selfAccount.id,
          child: MessageListPage(
            narrow: DmNarrow(
              allRecipientIds: [eg.selfUser.userId, eg.otherUser.userId],
              selfUserId: eg.selfUser.userId,
            ))))));

  // global store, per-account store, and message list get loaded
  await tester.pumpAndSettle();

  // (hint text of compose input in a 1:1 DM)
  final finder = find.widgetWithText(TextField, 'Message @${eg.otherUser.fullName}');
  check(finder.evaluate()).isNotEmpty();
  return finder;
}

void main() {
  TestZulipBinding.ensureInitialized();

  group('ComposeAutocomplete', () {

    Finder findNetworkImage(String url) {
      return find.byWidgetPredicate((widget) => switch(widget) {
        Image(image: NetworkImage(url: var imageUrl)) when imageUrl == url
          => true,
        _ => false,
      });
    }

    void checkUserShown(User user, PerAccountStore store, {required bool expected}) {
      check(find.text(user.fullName).evaluate().length).equals(expected ? 1 : 0);
      final avatarFinder =
        findNetworkImage(store.tryResolveUrl(user.avatarUrl!).toString());
      check(avatarFinder.evaluate().length).equals(expected ? 1 : 0);
    }

    testWidgets('options appear, disappear, and change correctly', (WidgetTester tester) async {
      final user1 = eg.user(userId: 1, fullName: 'User One', avatarUrl: 'user1.png');
      final user2 = eg.user(userId: 2, fullName: 'User Two', avatarUrl: 'user2.png');
      final user3 = eg.user(userId: 3, fullName: 'User Three', avatarUrl: 'user3.png');
      final composeInputFinder = await setupToComposeInput(tester, users: [user1, user2, user3]);
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      // Options are filtered correctly for query
      // TODO(#226): Remove this extra edit when this bug is fixed.
      await tester.enterText(composeInputFinder, 'hello @user ');
      await tester.enterText(composeInputFinder, 'hello @user t');
      await tester.pumpAndSettle(); // async computation; options appear

      // "User Two" and "User Three" appear, but not "User One"
      checkUserShown(user1, store, expected: false);
      checkUserShown(user2, store, expected: true);
      checkUserShown(user3, store, expected: true);

      // Finishing autocomplete updates compose box; causes options to disappear
      await tester.tap(find.text('User Three'));
      await tester.pump();
      check(tester.widget<TextField>(composeInputFinder).controller!.text)
        .contains(mention(user3, users: store.users));
      checkUserShown(user1, store, expected: false);
      checkUserShown(user2, store, expected: false);
      checkUserShown(user3, store, expected: false);

      // Then a new autocomplete intent brings up options again
      // TODO(#226): Remove this extra edit when this bug is fixed.
      await tester.enterText(composeInputFinder, 'hello @user tw');
      await tester.enterText(composeInputFinder, 'hello @user two');
      await tester.pumpAndSettle(); // async computation; options appear
      checkUserShown(user2, store, expected: true);

      // Removing autocomplete intent causes options to disappear
      // TODO(#226): Remove one of these edits when this bug is fixed.
      await tester.enterText(composeInputFinder, '');
      await tester.enterText(composeInputFinder, ' ');
      checkUserShown(user1, store, expected: false);
      checkUserShown(user2, store, expected: false);
      checkUserShown(user3, store, expected: false);

      debugNetworkImageHttpClientProvider = null;
    });
  });
}
