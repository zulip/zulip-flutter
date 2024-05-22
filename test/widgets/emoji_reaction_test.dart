import 'dart:io' as io;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/emoji_reaction.dart';
import 'package:zulip/widgets/store.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/test_store.dart';
import '../test_images.dart';
import 'text_test.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('ReactionChipsList', () {
    late PerAccountStore store;

    Future<void> prepare() async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      await store.addUser(eg.selfUser);

      // TODO do this more centrally, or put in reusable helper
      final Future<ByteData> font = rootBundle.load('assets/Source_Sans_3/SourceSans3VF-Upright.otf');
      final fontLoader = FontLoader('Source Sans 3')..addFont(font);
      await fontLoader.load();
    }

    Future<void> setupChipsInBox(WidgetTester tester, {
      required List<Reaction> reactions,
      double? width,
      TextDirection? textDirection,
    }) async {
      final message = eg.streamMessage(reactions: reactions);

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: textDirection ?? TextDirection.ltr,
            child: GlobalStoreWidget(
              child: PerAccountStoreWidget(
                accountId: eg.selfAccount.id,
                child: Center(
                  child: ColoredBox(
                    color: Colors.white,
                    child: SizedBox(
                      width: width ?? 245.0, // (seen in context on an iPhone 13 Pro)
                      child: ReactionChipsList(
                        messageId: message.id,
                        reactions: message.reactions!,
                      )))))))));

      // global store, per-account store
      await tester.pumpAndSettle();
    }

    // Smoke tests under various conditions.
    for (final displayEmojiReactionUsers in [true, false]) {
      for (final emojiset in [Emojiset.text, Emojiset.google]) {
        for (final textDirection in TextDirection.values) {
          for (final textScaleFactor in kTextScaleFactors) {
            Future<void> runSmokeTest(
              String description,
              List<Reaction> reactions, {
              required List<User> users,
              required Map<String, RealmEmojiItem> realmEmoji,
            }) async {
              final descriptionDetails = [
                displayEmojiReactionUsers ? 'show names when few' : 'no names',
                emojiset.name,
                textDirection.name,
                'text scale: $textScaleFactor',
              ].join(' / ');
              testWidgets('smoke ($description): $descriptionDetails', (tester) async {
                // Skip iOS. We're not covering the iOS code, for now, because it
                // contains a workaround for layout issues that we think will only
                // reproduce on actual iOS, and not in this test environment:
                //   <https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/flutter.3A.20reactions.20ui.20testing/near/1691415>
                // If those layout issues get fixed and we want to cover
                // TargetPlatform.iOS, remember that we suspect the Apple Color
                // Emoji font only works on Apple platforms, so for any tests
                // aimed at iOS, we should only run them on macOS.
                // TODO Could do an on-device integration test, which would let us
                //   cover iOS before a layout fix lands upstream:
                //     <https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/flutter.3A.20reactions.20ui.20testing/near/1691418>
                debugDefaultTargetPlatformOverride = TargetPlatform.android;

                tester.platformDispatcher.textScaleFactorTestValue = textScaleFactor;
                addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

                await prepare();

                await store.addUsers(users);
                await store.handleEvent(RealmEmojiUpdateEvent(id: 1,
                  realmEmoji: realmEmoji));
                await store.handleEvent(UserSettingsUpdateEvent(id: 1,
                  property: UserSettingName.displayEmojiReactionUsers,
                  value: displayEmojiReactionUsers));
                await store.handleEvent(UserSettingsUpdateEvent(id: 1,
                  property: UserSettingName.emojiset,
                  value: emojiset));

                // This does mean that all image emoji will look the same…
                // shrug, at least for now.
                final httpClient = FakeImageHttpClient();
                debugNetworkImageHttpClientProvider = () => httpClient;
                httpClient.request.response
                  ..statusCode = HttpStatus.ok
                  ..content = kSolidBlueAvatar;

                await setupChipsInBox(tester, textDirection: textDirection, reactions: reactions);

                // TODO(upstream) Do these in an addTearDown, once we can:
                //   https://github.com/flutter/flutter/issues/123189
                debugDefaultTargetPlatformOverride = null;
                debugNetworkImageHttpClientProvider = null;
              },
              // The Android code for Unicode emojis can't be exercised faithfully
              // on a Mac, because Noto Color Emoji can't work there:
              //   <https://github.com/flutter/flutter/issues/134897#issuecomment-1821632095>
              // So, skip on macOS.
              skip: io.Platform.isMacOS);
            }

            // Base JSON for various unicode emoji reactions. Just missing user_id.
            final u1 = {'emoji_name': '+1', 'emoji_code': '1f44d', 'reaction_type': 'unicode_emoji'};
            final u2 = {'emoji_name': 'family_man_man_girl_boy', 'emoji_code': '1f468-200d-1f468-200d-1f467-200d-1f466', 'reaction_type': 'unicode_emoji'};
            final u3 = {'emoji_name': 'smile', 'emoji_code': '1f642', 'reaction_type': 'unicode_emoji'};
            final u4 = {'emoji_name': 'tada', 'emoji_code': '1f389', 'reaction_type': 'unicode_emoji'};
            final u5 = {'emoji_name': 'exploding_head', 'emoji_code': '1f92f', 'reaction_type': 'unicode_emoji'};

            // Base JSON for various realm-emoji reactions. Just missing user_id.
            final i1 = {'emoji_name': 'twocents', 'emoji_code': '181', 'reaction_type': 'realm_emoji'};
            final i2 = {'emoji_name': 'threecents', 'emoji_code': '182', 'reaction_type': 'realm_emoji'};

            // Base JSON for the one "Zulip extra emoji" reaction. Just missing user_id.
            final z1 = {'emoji_name': 'zulip', 'emoji_code': 'zulip', 'reaction_type': 'zulip_extra_emoji'};

            final user1 = eg.user(fullName: 'abc');
            final user2 = eg.user(fullName: 'Long Name With Many Words In It');
            final user3 = eg.user(fullName: 'longnamelongnamelongnamelongname');
            final user4 = eg.user();
            final user5 = eg.user();

            final users = [user1, user2, user3, user4, user5];

            final realmEmoji = <String, RealmEmojiItem>{
              '181': RealmEmojiItem(id: '181', name: 'twocents', authorId: 7,
                  deactivated: false, sourceUrl: '/foo/2', stillUrl: null),
              '182': RealmEmojiItem(id: '182', name: 'threecents', authorId: 7,
                  deactivated: false, sourceUrl: '/foo/3', stillUrl: null),
            };

            runSmokeTest('same reaction, different users, with one unknown user', [
              Reaction.fromJson({ ...u1, 'user_id': user1.userId}),
              Reaction.fromJson({ ...u1, 'user_id': user2.userId}),
              // unknown user; shouldn't crash (name should show as "(unknown user)")
              Reaction.fromJson({ ...u1, 'user_id': eg.user().userId}),
            ], users: users, realmEmoji: realmEmoji);

            runSmokeTest('same user on different reactions', [
              Reaction.fromJson({ ...u1, 'user_id': user2.userId}),
              Reaction.fromJson({ ...u2, 'user_id': user2.userId}),
              Reaction.fromJson({ ...u3, 'user_id': user2.userId}),
            ], users: users, realmEmoji: realmEmoji);

            runSmokeTest('self user', [
              Reaction.fromJson({ ...i1, 'user_id': eg.selfUser.userId}),
              Reaction.fromJson({ ...i2, 'user_id': user1.userId}),
            ], users: users, realmEmoji: realmEmoji);

            runSmokeTest('different [ReactionType]s', [
              Reaction.fromJson({ ...u1, 'user_id': user1.userId}),
              Reaction.fromJson({ ...i1, 'user_id': user2.userId}),
              Reaction.fromJson({ ...z1, 'user_id': user3.userId}),
            ], users: users, realmEmoji: realmEmoji);

            runSmokeTest('many, varied', [
              Reaction.fromJson({ ...u1, 'user_id': user1.userId}),
              Reaction.fromJson({ ...u1, 'user_id': user2.userId}),
              Reaction.fromJson({ ...u2, 'user_id': user2.userId}),
              Reaction.fromJson({ ...u3, 'user_id': user3.userId}),
              Reaction.fromJson({ ...u4, 'user_id': user4.userId}),
              Reaction.fromJson({ ...u5, 'user_id': user4.userId}),
              Reaction.fromJson({ ...u5, 'user_id': user5.userId}),
              Reaction.fromJson({ ...i1, 'user_id': user5.userId}),
              Reaction.fromJson({ ...z1, 'user_id': user5.userId}),
              Reaction.fromJson({ ...u5, 'user_id': eg.selfUser.userId}),
              Reaction.fromJson({ ...i1, 'user_id': eg.selfUser.userId}),
              Reaction.fromJson({ ...z1, 'user_id': eg.selfUser.userId}),
            ], users: users, realmEmoji: realmEmoji);
          }
        }
      }
    }
  });

  // TODO more tests:
  // - Tapping a chip does the right thing
  // - When an image emoji fails to load, falls back to :text_emoji:
  // - Label text correctly chooses names or number
  // - When a user isn't found, says "(unknown user)"
  // - More about layout? (not just that it's error-free)
  // - Non-animated image emoji is selected when intended
}
