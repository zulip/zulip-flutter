import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/profile.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/test_store.dart';
import '../test_images.dart';
import '../test_navigation.dart';
import 'message_list_checks.dart';
import 'page_checks.dart';
import 'profile_page_checks.dart';
import 'test_app.dart';

late PerAccountStore store;

Future<void> setupPage(WidgetTester tester, {
  required int pageUserId,
  List<User>? users,
  List<int>? mutedUserIds,
  List<CustomProfileField>? customProfileFields,
  Map<String, RealmDefaultExternalAccount>? realmDefaultExternalAccounts,
  NavigatorObserver? navigatorObserver,
}) async {
  addTearDown(testBinding.reset);

  final initialSnapshot = eg.initialSnapshot(
    customProfileFields: customProfileFields,
    realmDefaultExternalAccounts: realmDefaultExternalAccounts);
  await testBinding.globalStore.add(eg.selfAccount, initialSnapshot);
  store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

  await store.addUser(eg.selfUser);
  if (users != null) {
    await store.addUsers(users);
  }
  if (mutedUserIds != null) {
    await store.setMutedUsers(mutedUserIds);
  }

  await tester.pumpWidget(TestZulipApp(
    accountId: eg.selfAccount.id,
    navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
    child: ProfilePage(userId: pageUserId)));

  // global store, per-account store, and page get loaded
  await tester.pumpAndSettle();
}

CustomProfileField mkCustomProfileField(
  int id,
  CustomProfileFieldType type, {
  int? order,
  bool? displayInProfileSummary,
  String? fieldData,
}) {
  return CustomProfileField(
    id: id,
    type: type,
    order: order ?? id,
    name: 'field$id',
    hint: 'hint$id',
    fieldData: fieldData ?? '',
    displayInProfileSummary: displayInProfileSummary ?? true,
  );
}

void main() {
  TestZulipBinding.ensureInitialized();

  group('ProfilePage', () {
    testWidgets('page builds; profile page renders', (tester) async {
      final user = eg.user(userId: 1, fullName: 'test user',
        deliveryEmail: 'testuser@example.com');

      await setupPage(tester, users: [user], pageUserId: user.userId);

      check(because: 'find user avatar', find.byType(Avatar).evaluate()).length.equals(1);
      check(because: 'find user name', find.text('test user').evaluate()).isNotEmpty();
      check(because: 'find user delivery email', find.text('testuser@example.com').evaluate()).isNotEmpty();
    });

    testWidgets('page builds; profile page renders with profileData', (tester) async {
      await setupPage(tester,
        users: [
          eg.user(userId: 1, profileData: {
            0: ProfileFieldUserData(value: 'shortTextValue'),
            1: ProfileFieldUserData(value: 'longTextValue'),
            2: ProfileFieldUserData(value: 'x'),
            3: ProfileFieldUserData(value: 'dateValue'),
            4: ProfileFieldUserData(value: 'http://example/linkValue'),
            5: ProfileFieldUserData(value: '[2]'),
            6: ProfileFieldUserData(value: 'externalValue'),
            7: ProfileFieldUserData(value: 'pronounsValue'),
          }),
          eg.user(userId: 2, fullName: 'userValue'),
        ],
        pageUserId: 1,
        customProfileFields: [
          mkCustomProfileField(0, CustomProfileFieldType.shortText),
          mkCustomProfileField(1, CustomProfileFieldType.longText),
          mkCustomProfileField(2, CustomProfileFieldType.choice,
            fieldData: '{"x": {"text": "choiceValue", "order": "1"}}'),
          mkCustomProfileField(3, CustomProfileFieldType.date),
          mkCustomProfileField(4, CustomProfileFieldType.link),
          mkCustomProfileField(5, CustomProfileFieldType.user),
          mkCustomProfileField(6, CustomProfileFieldType.externalAccount,
            fieldData: '{"subtype": "external1"}'),
          mkCustomProfileField(7, CustomProfileFieldType.pronouns),
        ], realmDefaultExternalAccounts: {
          'external1': RealmDefaultExternalAccount(
            name: 'external1',
            text: '',
            hint: '',
            urlPattern: 'https://example/%(username)s')});

      final testCases = [
        (find.text('field0'), find.text('shortTextValue'), CustomProfileFieldType.shortText),
        (find.text('field1'), find.text('longTextValue'), CustomProfileFieldType.longText),
        (find.text('field2'), find.text('choiceValue'), CustomProfileFieldType.choice),
        (find.text('field3'), find.text('dateValue'), CustomProfileFieldType.date),
        (find.text('field4'), find.text('http://example/linkValue'), CustomProfileFieldType.link),
        (find.text('field5'), find.text('userValue'), CustomProfileFieldType.user),
        (find.text('field6'), find.text('externalValue'), CustomProfileFieldType.externalAccount),
        (find.text('field7'), find.text('pronounsValue'), CustomProfileFieldType.pronouns),
      ];
      for (final testCase in testCases) {
        Finder labelFinder = testCase.$1;
        Finder fieldFinder = testCase.$2;
        CustomProfileFieldType testCaseType = testCase.$3;
        check(
          because: 'find label for $testCaseType',
          labelFinder.evaluate().length
        ).equals(1);
        check(
          because: 'find field for $testCaseType',
          fieldFinder.evaluate().length
        ).equals(1);
      }
      final avatars = tester.widgetList<Avatar>(find.byType(Avatar));
      check(avatars.map((w) => w.userId).toList())
        .deepEquals([1, 2]);
    });

    testWidgets('page builds; error page shows up if data is missing', (tester) async {
      await setupPage(tester, pageUserId: eg.selfUser.userId + 1989);
      check(because: 'find no user avatar', find.byType(Avatar).evaluate()).isEmpty();
      check(because: 'find error icon', find.byIcon(Icons.error).evaluate()).isNotEmpty();
    });

    testWidgets('page builds; link type will navigate', (tester) async {
      const testUrl = 'http://example/url';
      final user = eg.user(userId: 1, profileData: {
        0: ProfileFieldUserData(value: testUrl),
      });

      await setupPage(tester,
        users: [user],
        pageUserId: user.userId,
        customProfileFields: [mkCustomProfileField(0, CustomProfileFieldType.link)],
      );

      await tester.tap(find.text(testUrl));
      check(testBinding.takeLaunchUrlCalls()).single.equals((
        url: Uri.parse(testUrl),
        mode: LaunchMode.inAppBrowserView,
      ));
    });

    testWidgets('page builds; external link type navigates away', (tester) async {
      final user = eg.user(userId: 1, profileData: {
        0: ProfileFieldUserData(value: 'externalValue'),
      });

      await setupPage(tester,
        users: [user],
        pageUserId: user.userId,
        customProfileFields: [
          mkCustomProfileField(0, CustomProfileFieldType.externalAccount,
            fieldData: '{"subtype": "external1"}')
        ],
        realmDefaultExternalAccounts: {
          'external1': RealmDefaultExternalAccount(
            name: 'external1',
            text: '',
            hint: '',
            urlPattern: 'http://example/%(username)s')},
      );

      await tester.tap(find.text('externalValue'));
      check(testBinding.takeLaunchUrlCalls()).single.equals((
        url: Uri.parse('http://example/externalValue'),
        mode: LaunchMode.inAppBrowserView,
      ));
    });

    testWidgets('page builds; user links to profile', (tester) async {
      final users = [
        eg.user(userId: 1, profileData: {
          0: ProfileFieldUserData(value: '[2]'),
        }),
        eg.user(userId: 2, fullName: 'test user'),
      ];
      final pushedRoutes = <Route<dynamic>>[];
      final testNavObserver = TestNavigatorObserver()
        ..onPushed = (route, prevRoute) => pushedRoutes.add(route);

      await setupPage(tester,
        users: users,
        pageUserId: 1,
        customProfileFields: [mkCustomProfileField(0, CustomProfileFieldType.user)],
        navigatorObserver: testNavObserver,
      );

      final textFinder = find.text('test user');
      check(textFinder.evaluate()).length.equals(1);
      final fieldContainer = find.ancestor(of: textFinder, matching: find.byType(Column)).first;
      final targetWidget = find.descendant(of: fieldContainer, matching:find.byType(Avatar));
      await tester.tap(targetWidget, warnIfMissed: false);
      check(pushedRoutes).last.isA<WidgetRoute>().page.isA<ProfilePage>().userId.equals(2);
    });

    testWidgets('page builds; user field with unknown user', (tester) async {
      final users = [
        eg.user(userId: 1, profileData: {
          0: ProfileFieldUserData(value: '[2]'),
        }),
      ];
      await setupPage(tester,
        users: users,
        pageUserId: 1,
        customProfileFields: [mkCustomProfileField(0, CustomProfileFieldType.user)],
      );

      final textFinder = find.text('(unknown user)');
      check(textFinder.evaluate()).length.equals(1);
    });

    testWidgets('page builds; user field with muted user', (tester) async {
      prepareBoringImageHttpClient();

      Finder avatarFinder(int userId) => find.byWidgetPredicate(
        (widget) => widget is Avatar && widget.userId == userId);
      Finder mutedAvatarFinder(int userId) => find.descendant(
        of: avatarFinder(userId),
        matching: find.byIcon(ZulipIcons.person));
      Finder nonmutedAvatarFinder(int userId) => find.descendant(
        of: avatarFinder(userId),
        matching: find.byType(RealmContentNetworkImage));

      final users = [
        eg.user(userId: 1, profileData: {
          0: ProfileFieldUserData(value: '[2,3]'),
        }),
        eg.user(userId: 2, fullName: 'test user2', avatarUrl: '/foo.png'),
        eg.user(userId: 3, fullName: 'test user3', avatarUrl: '/bar.png'),
      ];

      await setupPage(tester,
        users: users,
        mutedUserIds: [2],
        pageUserId: 1,
        customProfileFields: [mkCustomProfileField(0, CustomProfileFieldType.user)]);

      check(find.text('Muted user')).findsOne();
      check(mutedAvatarFinder(2)).findsOne();
      check(nonmutedAvatarFinder(2)).findsNothing();

      check(find.text('test user3')).findsOne();
      check(mutedAvatarFinder(3)).findsNothing();
      check(nonmutedAvatarFinder(3)).findsOne();

      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('page builds; dm links to correct narrow', (tester) async {
      final pushedRoutes = <Route<dynamic>>[];
      final testNavObserver = TestNavigatorObserver()
        ..onPushed = (route, prevRoute) => pushedRoutes.add(route);

      await setupPage(tester,
        users: [eg.user(userId: 1)],
        pageUserId: 1,
        navigatorObserver: testNavObserver,
      );

      final targetWidget = find.byIcon(Icons.email);
      await tester.ensureVisible(targetWidget);
      await tester.tap(targetWidget);
      check(pushedRoutes).last.isA<WidgetRoute>().page
        .isA<MessageListPage>()
        .initNarrow.equals(DmNarrow.withUser(1, selfUserId: eg.selfUser.userId));
    });

    testWidgets('page builds; user links render multiple avatars', (tester) async {
      final users = [
        eg.user(userId: 1, profileData: {
          0: ProfileFieldUserData(value: '[2,3]'),
        }),
        eg.user(userId: 2, fullName: 'test user2'),
        eg.user(userId: 3, fullName: 'test user3'),
      ];

      await setupPage(tester,
        users: users,
        pageUserId: 1,
        customProfileFields: [mkCustomProfileField(0, CustomProfileFieldType.user)],
      );

      final avatars = tester.widgetList<Avatar>(find.byType(Avatar));
      check(avatars.map((w) => w.userId).toList())
        .deepEquals([1, 2, 3]);
    });

    testWidgets('page builds; ensure long name does not overflow', (tester) async {
      final longString = 'X' * 400;
      final user = eg.user(userId: 1, fullName: longString);
      await setupPage(tester, users: [user], pageUserId: user.userId);
      check(find.text(longString).evaluate()).isNotEmpty();
    });

    testWidgets('page builds; ensure long customProfileFields do not overflow', (tester) async {
      final longString = 'X' * 400;
      final user = eg.user(userId: 1, fullName: 'fullName', profileData: {
        0: ProfileFieldUserData(value: longString),
        1: ProfileFieldUserData(value: longString),
        2: ProfileFieldUserData(value: 'x'),
        3: ProfileFieldUserData(value: 'http://example/$longString'),
        4: ProfileFieldUserData(value: '[2]'),
        5: ProfileFieldUserData(value: longString),
        6: ProfileFieldUserData(value: longString),
      });
      final user2 = eg.user(userId: 2, fullName: longString);

      await setupPage(tester, users: [user, user2], pageUserId: user.userId,
        customProfileFields: [
          mkCustomProfileField(0, CustomProfileFieldType.shortText),
          mkCustomProfileField(1, CustomProfileFieldType.longText),
          mkCustomProfileField(2, CustomProfileFieldType.choice,
            fieldData: '{"x": {"text": "$longString", "order": "1"}}'),
          // no [CustomProfileFieldType.date] because those can't be made long
          mkCustomProfileField(3, CustomProfileFieldType.link),
          mkCustomProfileField(4, CustomProfileFieldType.user),
          mkCustomProfileField(5, CustomProfileFieldType.externalAccount,
            fieldData: '{"subtype": "external1"}'),
          mkCustomProfileField(6, CustomProfileFieldType.pronouns),
        ], realmDefaultExternalAccounts: {
          'external1': RealmDefaultExternalAccount(
            name: 'external1',
            text: '',
            hint: '',
            urlPattern: 'https://example/%(username)s')});

      check(find.textContaining(longString).evaluate()).length.equals(7);
    });
  });
}
