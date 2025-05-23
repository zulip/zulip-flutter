import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/channels.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/api/route/saved_snippets.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/model/typing_status.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/button.dart';
import 'package:zulip/widgets/color.dart';
import 'package:zulip/widgets/compose_box.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/theme.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/store_checks.dart';
import '../model/test_store.dart';
import '../model/typing_status_test.dart';
import '../stdlib_checks.dart';
import '../test_navigation.dart';
import 'compose_box_checks.dart';
import 'dialog_checks.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;
  late FakeApiConnection connection;
  late ComposeBoxState state;

  // Caution: when testing edit-message UI, this will often be stale;
  // read state.controller instead.
  late ComposeBoxController? controller;

  Future<void> prepareComposeBox(WidgetTester tester, {
    required Narrow narrow,
    User? selfUser,
    List<User> otherUsers = const [],
    List<ZulipStream> streams = const [],
    bool? mandatoryTopics,
    int? zulipFeatureLevel,
  }) async {
    if (narrow case ChannelNarrow(:var streamId) || TopicNarrow(: var streamId)) {
      assert(streams.any((stream) => stream.streamId == streamId),
        'Add a channel with "streamId" the same as of $narrow.streamId to the store.');
    }
    addTearDown(testBinding.reset);
    selfUser ??= eg.selfUser;
    zulipFeatureLevel ??= eg.futureZulipFeatureLevel;
    final selfAccount = eg.account(user: selfUser, zulipFeatureLevel: zulipFeatureLevel);
    await testBinding.globalStore.add(selfAccount, eg.initialSnapshot(
      realmUsers: [selfUser, ...otherUsers],
      streams: streams,
      zulipFeatureLevel: zulipFeatureLevel,
      realmMandatoryTopics: mandatoryTopics,
      realmAllowMessageEditing: true,
      realmMessageContentEditLimitSeconds: null,
    ));

    store = await testBinding.globalStore.perAccount(selfAccount.id);

    connection = store.connection as FakeApiConnection;

    connection.prepare(json:
      eg.newestGetMessagesResult(foundOldest: true, messages: []).toJson());
    await tester.pumpWidget(TestZulipApp(accountId: selfAccount.id,
      child: MessageListPage(initNarrow: narrow)));
    await tester.pumpAndSettle();
    connection.takeRequests();

    state = tester.state<ComposeBoxState>(find.byType(ComposeBox));
    controller = state.controller;
  }

  /// A [Finder] for the topic input.
  ///
  /// To enter some text, use [enterTopic].
  final topicInputFinder = find.byWidgetPredicate(
    (widget) => widget is TextField && widget.controller is ComposeTopicController);

  /// Set the topic input's text to [topic], using [WidgetTester.enterText].
  Future<void> enterTopic(WidgetTester tester, {
    required ChannelNarrow narrow,
    required String topic,
  }) async {
    connection.prepare(body:
      jsonEncode(GetStreamTopicsResult(topics: [eg.getStreamTopicsEntry()]).toJson()));
    await tester.enterText(topicInputFinder, topic);
    check(connection.takeRequests()).single
      ..method.equals('GET')
      ..url.path.equals('/api/v1/users/me/${narrow.streamId}/topics');
  }

  /// A [Finder] for the content input.
  ///
  /// To enter some text, use [enterContent].
  final contentInputFinder = find.byWidgetPredicate(
    (widget) => widget is TextField && widget.controller is ComposeContentController);

  /// Set the content input's text to [content], using [WidgetTester.enterText].
  Future<void> enterContent(WidgetTester tester, String content) async {
    await tester.enterText(contentInputFinder, content);
  }

  void checkContentInputValue(WidgetTester tester, String expected) {
    check(tester.widget<TextField>(contentInputFinder))
      .controller.isNotNull().value.text.equals(expected);
  }

  final sendButtonFinder = find.byIcon(ZulipIcons.send);

  Future<void> tapSendButton(WidgetTester tester) async {
    connection.prepare(json: SendMessageResult(id: 123).toJson());
    await tester.tap(sendButtonFinder);
    await tester.pump(Duration.zero);
  }

  group('ComposeBoxTheme', () {
    test('lerp light to dark, no crash', () {
      final a = ComposeBoxTheme.light;
      final b = ComposeBoxTheme.dark;

      check(() => a.lerp(b, 0.5)).returnsNormally();
    });
  });

  group('ComposeContentController', () {
    group('insertPadded', () {
      // Like `parseMarkedText` in test/model/autocomplete_test.dart,
      //   but a bit different -- could maybe deduplicate some.
      TextEditingValue parseMarkedText(String markedText) {
        final textBuffer = StringBuffer();
        int? insertionPoint;
        int i = 0;
        for (final char in markedText.codeUnits) {
          if (char == 94 /* ^ */) {
            if (insertionPoint != null) {
              throw Exception('Test error: too many ^ in input');
            }
            insertionPoint = i;
            continue;
          }
          textBuffer.writeCharCode(char);
          i++;
        }
        if (insertionPoint == null) {
          throw Exception('Test error: expected ^ in input');
        }
        return TextEditingValue(text: textBuffer.toString(), selection: TextSelection.collapsed(offset: insertionPoint));
      }

      /// Test the given `insertPadded` call, in a convenient format.
      ///
      /// In valueBefore, represent the insertion point as "^".
      /// In expectedValue, represent the collapsed selection as "^".
      void testInsertPadded(String description, String valueBefore, String textToInsert, String expectedValue) {
        test(description, () {
          final controller = ComposeContentController();
          controller.value = parseMarkedText(valueBefore);
          controller.insertPadded(textToInsert);
          check(controller.value).equals(parseMarkedText(expectedValue));
        });
      }

      // TODO(?) exercise the part of insertPadded that chooses the insertion
      //   point based on [TextEditingValue.selection], which may be collapsed,
      //   expanded, or null (what they call !TextSelection.isValid).

      testInsertPadded('empty; insert one line',
        '^', 'a\n',    'a\n\n^');
      testInsertPadded('empty; insert two lines',
        '^', 'a\nb\n', 'a\nb\n\n^');

      group('insert at end', () {
        testInsertPadded('one empty line; insert one line',
          '\n^',     'a\n',    '\na\n\n^');
        testInsertPadded('two empty lines; insert one line',
          '\n\n^',   'a\n',    '\n\na\n\n^');
        testInsertPadded('one line, incomplete; insert one line',
          'a^',      'b\n',    'a\n\nb\n\n^');
        testInsertPadded('one line, complete; insert one line',
          'a\n^',    'b\n',    'a\n\nb\n\n^');
        testInsertPadded('multiple lines, last is incomplete; insert one line',
          'a\nb^',   'c\n',    'a\nb\n\nc\n\n^');
        testInsertPadded('multiple lines, last is complete; insert one line',
          'a\nb\n^', 'c\n',    'a\nb\n\nc\n\n^');
        testInsertPadded('multiple lines, last is complete; insert two lines',
          'a\nb\n^', 'c\nd\n', 'a\nb\n\nc\nd\n\n^');
      });

      group('insert at start', () {
        testInsertPadded('one empty line; insert one line',
          '^\n',     'a\n',    'a\n\n^');
        testInsertPadded('two empty lines; insert one line',
          '^\n\n',   'a\n',    'a\n\n^\n');
        testInsertPadded('one line, incomplete; insert one line',
          '^a',      'b\n',    'b\n\n^a');
        testInsertPadded('one line, complete; insert one line',
          '^a\n',    'b\n',    'b\n\n^a\n');
        testInsertPadded('multiple lines, last is incomplete; insert one line',
          '^a\nb',   'c\n',    'c\n\n^a\nb');
        testInsertPadded('multiple lines, last is complete; insert one line',
          '^a\nb\n', 'c\n',    'c\n\n^a\nb\n');
        testInsertPadded('multiple lines, last is complete; insert two lines',
          '^a\nb\n', 'c\nd\n', 'c\nd\n\n^a\nb\n');
      });

      group('insert in middle', () {
        testInsertPadded('middle of line',
          'a^a\n',       'b\n', 'a\n\nb\n\n^a\n');
        testInsertPadded('start of non-empty line, after empty line',
          'b\n\n^a\n',   'c\n', 'b\n\nc\n\n^a\n');
        testInsertPadded('end of non-empty line, before non-empty line',
          'a^\nb\n',     'c\n', 'a\n\nc\n\n^b\n');
        testInsertPadded('start of non-empty line, after non-empty line',
          'a\n^b\n',     'c\n', 'a\n\nc\n\n^b\n');
        testInsertPadded('text start; one empty line; insertion point; one empty line',
          '\n^\n',       'a\n', '\na\n\n^');
        testInsertPadded('text start; one empty line; insertion point; two empty lines',
          '\n^\n\n',     'a\n', '\na\n\n^\n');
        testInsertPadded('text start; two empty lines; insertion point; one empty line',
          '\n\n^\n',     'a\n', '\n\na\n\n^');
        testInsertPadded('text start; two empty lines; insertion point; two empty lines',
          '\n\n^\n\n',   'a\n', '\n\na\n\n^\n');
      });
    });

    group('ContentValidationError.empty', () {
      late ComposeContentController controller;

      void checkCountsAsEmpty(String text, bool expected) {
        controller.value = TextEditingValue(text: text);
        expected
          ? check(controller).validationErrors.contains(ContentValidationError.empty)
          : check(controller).validationErrors.not((it) => it.contains(ContentValidationError.empty));
      }

      testWidgets('requireNotEmpty: true (default)', (tester) async {
        controller = ComposeContentController();
        addTearDown(controller.dispose);
        checkCountsAsEmpty('', true);
        checkCountsAsEmpty(' ', true);
        checkCountsAsEmpty('a', false);
      });

      testWidgets('requireNotEmpty: false', (tester) async {
        controller = ComposeContentController(requireNotEmpty: false);
        addTearDown(controller.dispose);
        checkCountsAsEmpty('', false);
        checkCountsAsEmpty(' ', false);
        checkCountsAsEmpty('a', false);
      });
    });
  });

  group('length validation', () {
    final channel = eg.stream();

    /// String where there are [n] Unicode code points,
    /// >[n] UTF-16 code units, and <[n] "characters" a.k.a. grapheme clusters.
    String makeStringWithCodePoints(int n) {
      assert(n >= 5);
      const graphemeCluster = '👨‍👩‍👦';
      assert(graphemeCluster.runes.length == 5);
      assert(graphemeCluster.length == 8);
      assert(graphemeCluster.characters.length == 1);

      final result =
        graphemeCluster * (n ~/ 5)
        + 'a' * (n % 5);
      assert(result.runes.length == n);

      return result;
    }

    group('content', () {
      Future<void> prepareWithContent(WidgetTester tester, String content) async {
        TypingNotifier.debugEnable = false;
        addTearDown(TypingNotifier.debugReset);

        final narrow = ChannelNarrow(channel.streamId);
        await prepareComposeBox(tester, narrow: narrow, streams: [channel]);
        await enterTopic(tester, narrow: narrow, topic: 'some topic');
        await enterContent(tester, content);
      }

      Future<void> checkErrorResponse(WidgetTester tester) async {
        await tester.tap(find.byWidget(checkErrorDialog(tester,
          expectedTitle: 'Message not sent',
          expectedMessage: 'Message length shouldn\'t be greater than 10000 characters.')));
      }

      testWidgets('too-long content is rejected', (tester) async {
        await prepareWithContent(tester,
          makeStringWithCodePoints(kMaxMessageLengthCodePoints + 1));
        await tapSendButton(tester);
        await checkErrorResponse(tester);
      });

      testWidgets('max-length content not rejected', (tester) async {
        await prepareWithContent(tester,
          makeStringWithCodePoints(kMaxMessageLengthCodePoints));
        await tapSendButton(tester);
        checkNoErrorDialog(tester);
      });

      testWidgets('code points not counted unnecessarily', (tester) async {
        await prepareWithContent(tester, 'a' * kMaxMessageLengthCodePoints);
        check(controller!.content.debugLengthUnicodeCodePointsIfLong).isNull();
      });
    });

    group('topic', () {
      Future<void> prepareWithTopic(WidgetTester tester, String topic) async {
        TypingNotifier.debugEnable = false;
        addTearDown(TypingNotifier.debugReset);

        final narrow = ChannelNarrow(channel.streamId);
        await prepareComposeBox(tester, narrow: narrow, streams: [channel]);
        await enterTopic(tester, narrow: narrow, topic: topic);
        await enterContent(tester, 'some content');
      }

      Future<void> checkErrorResponse(WidgetTester tester) async {
        await tester.tap(find.byWidget(checkErrorDialog(tester,
          expectedTitle: 'Message not sent',
          expectedMessage: 'Topic length shouldn\'t be greater than 60 characters.')));
      }

      testWidgets('too-long topic is rejected', (tester) async {
        await prepareWithTopic(tester,
          makeStringWithCodePoints(kMaxTopicLengthCodePoints + 1));
        await tapSendButton(tester);
        await checkErrorResponse(tester);
      });

      testWidgets('max-length topic not rejected', (tester) async {
        await prepareWithTopic(tester,
          makeStringWithCodePoints(kMaxTopicLengthCodePoints));
        await tapSendButton(tester);
        checkNoErrorDialog(tester);
      });

      testWidgets('code points not counted unnecessarily', (tester) async {
        await prepareWithTopic(tester, 'a' * kMaxTopicLengthCodePoints);
        check((controller as StreamComposeBoxController)
          .topic.debugLengthUnicodeCodePointsIfLong).isNull();
      });
    });
  });

  group('ComposeBox hintText', () {
    final channel = eg.stream();

    Future<void> prepare(WidgetTester tester, {
      required Narrow narrow,
      bool? mandatoryTopics,
      int? zulipFeatureLevel,
    }) async {
      await prepareComposeBox(tester,
        narrow: narrow,
        otherUsers: [eg.otherUser, eg.thirdUser],
        streams: [channel],
        mandatoryTopics: mandatoryTopics,
        zulipFeatureLevel: zulipFeatureLevel);
    }

    /// This checks the input's configured hint text without regard to whether
    /// it's currently visible, as it won't be if the user has entered some text.
    ///
    /// If `topicHintText` is `null`, check that the topic input is not present.
    void checkComposeBoxHintTexts(WidgetTester tester, {
      String? topicHintText,
      required String contentHintText,
    }) {
      if (topicHintText != null) {
        check(tester.widget<TextField>(topicInputFinder))
          .decoration.isNotNull().hintText.equals(topicHintText);
      } else {
        check(topicInputFinder).findsNothing();
      }
      check(tester.widget<TextField>(contentInputFinder))
        .decoration.isNotNull().hintText.equals(contentHintText);
    }

    group('to ChannelNarrow, topics not mandatory', () {
      final narrow = ChannelNarrow(channel.streamId);

      testWidgets('with empty topic, topic input has focus', (tester) async {
        await prepare(tester, narrow: narrow, mandatoryTopics: false);
        await enterTopic(tester, narrow: narrow, topic: '');
        await tester.pump();
        checkComposeBoxHintTexts(tester,
          topicHintText: 'Enter a topic '
                         '(skip for “${eg.defaultRealmEmptyTopicDisplayName}”)',
          contentHintText: 'Message #${channel.name}');
      });

      testWidgets('legacy: with empty topic, topic input has focus', (tester) async {
        await prepare(tester, narrow: narrow, mandatoryTopics: false,
          zulipFeatureLevel: 333); // TODO(server-10)
        await enterTopic(tester, narrow: narrow, topic: '');
        await tester.pump();
        checkComposeBoxHintTexts(tester,
          topicHintText: 'Enter a topic (skip for “(no topic)”)',
          contentHintText: 'Message #${channel.name}');
      });

      testWidgets('with non-empty but vacuous topic, topic input has focus', (tester) async {
        await prepare(tester, narrow: narrow, mandatoryTopics: false);
        await enterTopic(tester, narrow: narrow,
          topic: eg.defaultRealmEmptyTopicDisplayName);
        await tester.pump();
        checkComposeBoxHintTexts(tester,
          topicHintText: 'Enter a topic '
                         '(skip for “${eg.defaultRealmEmptyTopicDisplayName}”)',
          contentHintText: 'Message #${channel.name}');
      });

      testWidgets('with empty topic, topic input has focus, then content input gains focus', (tester) async {
        await prepare(tester, narrow: narrow, mandatoryTopics: false);
        await enterTopic(tester, narrow: narrow, topic: '');
        await tester.pump();
        checkComposeBoxHintTexts(tester,
          topicHintText: 'Enter a topic '
                         '(skip for “${eg.defaultRealmEmptyTopicDisplayName}”)',
          contentHintText: 'Message #${channel.name}');

        await enterContent(tester, '');
        await tester.pump();
        checkComposeBoxHintTexts(tester,
          topicHintText: eg.defaultRealmEmptyTopicDisplayName,
          contentHintText: 'Message #${channel.name} > '
                           '${eg.defaultRealmEmptyTopicDisplayName}');
      });

      testWidgets('with empty topic, topic input has focus, then loses it', (tester) async {
        await prepare(tester, narrow: narrow, mandatoryTopics: false);
        await enterTopic(tester, narrow: narrow, topic: '');
        await tester.pump();
        checkComposeBoxHintTexts(tester,
          topicHintText: 'Enter a topic '
                         '(skip for “${eg.defaultRealmEmptyTopicDisplayName}”)',
          contentHintText: 'Message #${channel.name}');

        FocusManager.instance.primaryFocus!.unfocus();
        await tester.pump();
        checkComposeBoxHintTexts(tester,
          topicHintText: 'Topic',
          contentHintText: 'Message #${channel.name}');
      });

      testWidgets('with empty topic, content input has focus', (tester) async {
        await prepare(tester, narrow: narrow, mandatoryTopics: false);
        await enterContent(tester, '');
        await tester.pump();
        checkComposeBoxHintTexts(tester,
          topicHintText: eg.defaultRealmEmptyTopicDisplayName,
          contentHintText: 'Message #${channel.name} > '
                           '${eg.defaultRealmEmptyTopicDisplayName}');
        check(tester.widget<TextField>(topicInputFinder)).decoration.isNotNull()
          .hintStyle.isNotNull().fontStyle.equals(FontStyle.italic);
      });

      testWidgets('legacy: with empty topic, content input has focus', (tester) async {
        await prepare(tester, narrow: narrow, mandatoryTopics: false,
          zulipFeatureLevel: 333);
        await enterContent(tester, '');
        await tester.pump();
        checkComposeBoxHintTexts(tester,
          topicHintText: '(no topic)',
          contentHintText: 'Message #${channel.name} > (no topic)');
        check(tester.widget<TextField>(topicInputFinder)).decoration.isNotNull()
          .hintStyle.isNotNull().fontStyle.isNull();
      });

      testWidgets('with empty topic, content input has focus, then topic input gains focus', (tester) async {
        await prepare(tester, narrow: narrow, mandatoryTopics: false);
        await enterContent(tester, '');
        await tester.pump();
        checkComposeBoxHintTexts(tester,
          topicHintText: eg.defaultRealmEmptyTopicDisplayName,
          contentHintText: 'Message #${channel.name} > '
                           '${eg.defaultRealmEmptyTopicDisplayName}');

        await enterTopic(tester, narrow: narrow, topic: '');
        await tester.pump();
        checkComposeBoxHintTexts(tester,
          topicHintText: 'Enter a topic '
                         '(skip for “${eg.defaultRealmEmptyTopicDisplayName}”)',
          contentHintText: 'Message #${channel.name}');
      });

      testWidgets('with empty topic, content input has focus, then loses it', (tester) async {
        await prepare(tester, narrow: narrow, mandatoryTopics: false);
        await enterContent(tester, '');
        await tester.pump();
        checkComposeBoxHintTexts(tester,
          topicHintText: eg.defaultRealmEmptyTopicDisplayName,
          contentHintText: 'Message #${channel.name} > '
                           '${eg.defaultRealmEmptyTopicDisplayName}');

        FocusManager.instance.primaryFocus!.unfocus();
        await tester.pump();
        checkComposeBoxHintTexts(tester,
          topicHintText: eg.defaultRealmEmptyTopicDisplayName,
          contentHintText: 'Message #${channel.name} > '
                           '${eg.defaultRealmEmptyTopicDisplayName}');
      });

      testWidgets('with non-empty topic', (tester) async {
        await prepare(tester, narrow: narrow, mandatoryTopics: false);
        await enterTopic(tester, narrow: narrow, topic: 'new topic');
        await tester.pump();
        checkComposeBoxHintTexts(tester,
          topicHintText: 'Enter a topic '
                         '(skip for “${eg.defaultRealmEmptyTopicDisplayName}”)',
          contentHintText: 'Message #${channel.name} > new topic');
      });
    });

    group('to ChannelNarrow, mandatory topics', () {
      final narrow = ChannelNarrow(channel.streamId);

      testWidgets('with empty topic', (tester) async {
        await prepare(tester, narrow: narrow, mandatoryTopics: true);
        checkComposeBoxHintTexts(tester,
          topicHintText: 'Topic',
          contentHintText: 'Message #${channel.name}');
      });

      testWidgets('legacy: with empty topic', (tester) async {
        await prepare(tester, narrow: narrow, mandatoryTopics: true,
          zulipFeatureLevel: 333); // TODO(server-10)
        checkComposeBoxHintTexts(tester,
          topicHintText: 'Topic',
          contentHintText: 'Message #${channel.name}');
      });

      group('with non-empty but vacuous topics', () {
        testWidgets('realm_empty_topic_display_name', (tester) async {
          await prepare(tester, narrow: narrow, mandatoryTopics: true);
          await enterTopic(tester, narrow: narrow,
            topic: eg.defaultRealmEmptyTopicDisplayName);
          await tester.pump();
          checkComposeBoxHintTexts(tester,
            topicHintText: 'Topic',
            contentHintText: 'Message #${channel.name}');
        });

        testWidgets('"(no topic)"', (tester) async {
          await prepare(tester, narrow: narrow, mandatoryTopics: true);
          await enterTopic(tester, narrow: narrow,
            topic: '(no topic)');
          await tester.pump();
          checkComposeBoxHintTexts(tester,
            topicHintText: 'Topic',
            contentHintText: 'Message #${channel.name}');
        });
      });

      testWidgets('with non-empty topic', (tester) async {
        await prepare(tester, narrow: narrow, mandatoryTopics: true);
        await enterTopic(tester, narrow: narrow, topic: 'new topic');
        await tester.pump();
        checkComposeBoxHintTexts(tester,
          topicHintText: 'Topic',
          contentHintText: 'Message #${channel.name} > new topic');
      });
    });

    group('to TopicNarrow', () {
      testWidgets('with non-empty topic', (tester) async {
        await prepare(tester,
          narrow: TopicNarrow(channel.streamId, TopicName('topic')));
        checkComposeBoxHintTexts(tester,
          contentHintText: 'Message #${channel.name} > topic');
      });

      testWidgets('with empty topic', (tester) async {
        await prepare(tester,
          narrow: TopicNarrow(channel.streamId, TopicName('')));
        checkComposeBoxHintTexts(tester, contentHintText:
          'Message #${channel.name} > ${eg.defaultRealmEmptyTopicDisplayName}');
      });
    });

    testWidgets('to DmNarrow with self', (tester) async {
      await prepare(tester, narrow: DmNarrow.withUser(
        eg.selfUser.userId, selfUserId: eg.selfUser.userId));
      checkComposeBoxHintTexts(tester,
        contentHintText: 'Jot down something');
    });

    testWidgets('to 1:1 DmNarrow', (tester) async {
      await prepare(tester, narrow: DmNarrow.withUser(
        eg.otherUser.userId, selfUserId: eg.selfUser.userId));
      checkComposeBoxHintTexts(tester,
        contentHintText: 'Message @${eg.otherUser.fullName}');
    });

    testWidgets('to group DmNarrow', (tester) async {
      await prepare(tester, narrow: DmNarrow.withOtherUsers(
        [eg.otherUser.userId, eg.thirdUser.userId],
        selfUserId: eg.selfUser.userId));
      checkComposeBoxHintTexts(tester,
        contentHintText: 'Message group');
    });
  });

  group('ComposeBox textCapitalization', () {
    void checkComposeBoxTextFields(WidgetTester tester, {
      required bool expectTopicTextField,
    }) {
      if (expectTopicTextField) {
        final topicController = (controller as StreamComposeBoxController).topic;
        final topicTextField = tester.widgetList<TextField>(find.byWidgetPredicate(
          (widget) => widget is TextField && widget.controller == topicController
        )).singleOrNull;
        check(topicTextField).isNotNull()
          .textCapitalization.equals(TextCapitalization.none);
      } else {
        check(controller).isA<FixedDestinationComposeBoxController>();
        check(find.byType(TextField)).findsOne(); // just content input, no topic
      }

      final contentTextField = tester.widget<TextField>(find.byWidgetPredicate(
        (widget) => widget is TextField
          && widget.controller == controller!.content));
      check(contentTextField)
        .textCapitalization.equals(TextCapitalization.sentences);
    }

    testWidgets('_StreamComposeBox', (tester) async {
      final channel = eg.stream();
      await prepareComposeBox(tester,
        narrow: ChannelNarrow(channel.streamId), streams: [channel]);
      checkComposeBoxTextFields(tester, expectTopicTextField: true);
    });

    testWidgets('_FixedDestinationComposeBox', (tester) async {
      final channel = eg.stream();
      await prepareComposeBox(tester,
        narrow: eg.topicNarrow(channel.streamId, 'topic'), streams: [channel]);
      checkComposeBoxTextFields(tester, expectTopicTextField: false);
    });
  });

  group('ComposeBox typing notices', () {
    final channel = eg.stream();
    final narrow = eg.topicNarrow(channel.streamId, 'some topic');

    void checkTypingRequest(TypingOp op, SendableNarrow narrow) =>
      checkSetTypingStatusRequests(connection.takeRequests(), [(op, narrow)]);

    Future<void> checkStartTyping(WidgetTester tester, SendableNarrow narrow) async {
      connection.prepare(json: {});
      await enterContent(tester, 'hello world');
      checkTypingRequest(TypingOp.start, narrow);
    }

    testWidgets('smoke TopicNarrow', (tester) async {
      await prepareComposeBox(tester, narrow: narrow, streams: [channel]);

      await checkStartTyping(tester, narrow);

      connection.prepare(json: {});
      await tester.pump(store.typingNotifier.typingStoppedWaitPeriod);
      checkTypingRequest(TypingOp.stop, narrow);
    });

    testWidgets('smoke DmNarrow', (tester) async {
      final narrow = DmNarrow.withUsers(
        [eg.otherUser.userId], selfUserId: eg.selfUser.userId);
      await prepareComposeBox(tester, narrow: narrow);

      await checkStartTyping(tester, narrow);

      connection.prepare(json: {});
      await tester.pump(store.typingNotifier.typingStoppedWaitPeriod);
      checkTypingRequest(TypingOp.stop, narrow);
    });

    testWidgets('smoke ChannelNarrow', (tester) async {
      final narrow = ChannelNarrow(channel.streamId);
      final destinationNarrow = eg.topicNarrow(narrow.streamId, 'test topic');
      await prepareComposeBox(tester, narrow: narrow, streams: [channel]);
      await enterTopic(tester, narrow: narrow, topic: 'test topic');

      await checkStartTyping(tester, destinationNarrow);

      connection.prepare(json: {});
      await tester.pump(store.typingNotifier.typingStoppedWaitPeriod);
      checkTypingRequest(TypingOp.stop, destinationNarrow);
    });

    testWidgets('clearing text sends a "typing stopped" notice', (tester) async {
      await prepareComposeBox(tester, narrow: narrow, streams: [channel]);

      await checkStartTyping(tester, narrow);

      connection.prepare(json: {});
      await enterContent(tester, '');
      checkTypingRequest(TypingOp.stop, narrow);
    });

    testWidgets('hitting send button sends a "typing stopped" notice', (tester) async {
      await prepareComposeBox(tester, narrow: narrow, streams: [channel]);

      await checkStartTyping(tester, narrow);

      connection.prepare(json: {});
      connection.prepare(json: SendMessageResult(id: 123).toJson());
      await tester.tap(sendButtonFinder);
      await tester.pump(Duration.zero);
      final requests = connection.takeRequests();
      checkSetTypingStatusRequests([requests.first], [(TypingOp.stop, narrow)]);
      check(requests).length.equals(2);
    });

    Future<void> prepareComposeBoxWithNavigation(WidgetTester tester) async {
      addTearDown(testBinding.reset);
      final selfUser = eg.selfUser;
      final selfAccount = eg.account(user: selfUser);
      await testBinding.globalStore.add(selfAccount, eg.initialSnapshot());

      store = await testBinding.globalStore.perAccount(selfAccount.id);
      await store.addUser(selfUser);
      await store.addStream(channel);
      connection = store.connection as FakeApiConnection;

      await tester.pumpWidget(const ZulipApp());
      await tester.pump();
      final navigator = await ZulipApp.navigator;
      unawaited(navigator.push(MaterialAccountWidgetRoute(
        accountId: selfAccount.id, page: ComposeBox(narrow: narrow))));
      await tester.pumpAndSettle();
    }

    testWidgets('navigating away sends a "typing stopped" notice', (tester) async {
      await prepareComposeBoxWithNavigation(tester);

      await checkStartTyping(tester, narrow);

      connection.prepare(json: {});
      (await ZulipApp.navigator).pop();
      await tester.pump(Duration.zero);
      checkTypingRequest(TypingOp.stop, narrow);
    });

    testWidgets('for content input, unfocusing sends a "typing stopped" notice', (tester) async {
      final narrow = ChannelNarrow(channel.streamId);
      final destinationNarrow = eg.topicNarrow(narrow.streamId, 'test topic');
      await prepareComposeBox(tester, narrow: narrow, streams: [channel]);
      await enterTopic(tester, narrow: narrow, topic: 'test topic');

      await checkStartTyping(tester, destinationNarrow);

      connection.prepare(json: {});
      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pump(Duration.zero);
      checkTypingRequest(TypingOp.stop, destinationNarrow);
    });

    testWidgets('selection change sends a "typing started" notice', (tester) async {
      await prepareComposeBox(tester, narrow: narrow, streams: [channel]);

      await checkStartTyping(tester, narrow);

      connection.prepare(json: {});
      await tester.pump(store.typingNotifier.typingStoppedWaitPeriod);
      checkTypingRequest(TypingOp.stop, narrow);

      connection.prepare(json: {});
      controller!.content.selection =
        const TextSelection(baseOffset: 0, extentOffset: 2);
      checkTypingRequest(TypingOp.start, narrow);

      // Ensures that a "typing stopped" notice is sent when the test ends.
      connection.prepare(json: {});
      await tester.pump(store.typingNotifier.typingStoppedWaitPeriod);
      checkTypingRequest(TypingOp.stop, narrow);
    });

    testWidgets('unfocusing app sends a "typing stopped" notice', (tester) async {
      await prepareComposeBox(tester, narrow: narrow, streams: [channel]);

      await checkStartTyping(tester, narrow);

      connection.prepare(json: {});
      // While this state lives on [ServicesBinding], testWidgets resets it
      // for us when the test ends so we don't have to:
      //   https://github.com/flutter/flutter/blob/c78c166e3ecf963ca29ed503e710fd3c71eda5c9/packages/flutter_test/lib/src/binding.dart#L1189
      // On iOS and Android, a transition to [hidden] is synthesized before
      // transitioning into [paused].
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.hidden);
      await tester.pump(Duration.zero);
      checkTypingRequest(TypingOp.stop, narrow);

      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.paused);
      await tester.pump(Duration.zero);
      check(connection.lastRequest).isNull();
    });
  });

  group('message-send request response', () {
    Future<void> setupAndTapSend(WidgetTester tester, {
      required void Function(int messageId) prepareResponse,
    }) async {
      TypingNotifier.debugEnable = false;
      addTearDown(TypingNotifier.debugReset);

      final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
      await prepareComposeBox(tester, narrow: eg.topicNarrow(123, 'some topic'),
        streams: [eg.stream(streamId: 123)]);

      await enterContent(tester, 'hello world');

      prepareResponse(456);
      await tester.tap(find.byTooltip(zulipLocalizations.composeBoxSendTooltip));
      await tester.pump(Duration.zero);

      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages')
        ..bodyFields.deepEquals({
            'type': 'stream',
            'to': '123',
            'topic': 'some topic',
            'content': 'hello world',
            'read_by_sender': 'true',
          });
    }

    testWidgets('success', (tester) async {
      await setupAndTapSend(tester, prepareResponse: (int messageId) {
        connection.prepare(json: SendMessageResult(id: messageId).toJson());
      });
      checkNoErrorDialog(tester);
    });

    testWidgets('ZulipApiException', (tester) async {
      await setupAndTapSend(tester, prepareResponse: (message) {
        connection.prepare(apiException: eg.apiBadRequest(
          message: 'You do not have permission to initiate direct message conversations.'));
      });
      final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
      await tester.tap(find.byWidget(checkErrorDialog(tester,
        expectedTitle: zulipLocalizations.errorMessageNotSent,
        expectedMessage: zulipLocalizations.errorServerMessage(
          'You do not have permission to initiate direct message conversations.'),
      )));
    });
  });

  group('sending to empty topic', () {
    late ZulipStream channel;

    Future<void> setupAndTapSend(WidgetTester tester, {
      required String topicInputText,
      required bool mandatoryTopics,
      int? zulipFeatureLevel,
    }) async {
      TypingNotifier.debugEnable = false;
      addTearDown(TypingNotifier.debugReset);

      channel = eg.stream();
      final narrow = ChannelNarrow(channel.streamId);
      await prepareComposeBox(tester,
        narrow: narrow, streams: [channel],
        mandatoryTopics: mandatoryTopics,
        zulipFeatureLevel: zulipFeatureLevel);

      await enterTopic(tester, narrow: narrow, topic: topicInputText);
      await tester.enterText(contentInputFinder, 'test content');
      await tester.tap(sendButtonFinder);
      await tester.pump();
    }

    void checkMessageNotSent(WidgetTester tester) {
      check(connection.takeRequests()).isEmpty();
      checkErrorDialog(tester,
        expectedTitle: 'Message not sent',
        expectedMessage: 'Topics are required in this organization.');
    }

    testWidgets('empty topic -> ""', (tester) async {
      await setupAndTapSend(tester,
        topicInputText: '',
        mandatoryTopics: false);
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages')
        ..bodyFields['topic'].equals('');
    });

    testWidgets('legacy: empty topic -> "(no topic)"', (tester) async {
      await setupAndTapSend(tester,
        topicInputText: '',
        mandatoryTopics: false,
        zulipFeatureLevel: 333);
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages')
        ..bodyFields['topic'].equals('(no topic)');
    });

    testWidgets('if topics are mandatory, reject empty topic', (tester) async {
      await setupAndTapSend(tester,
        topicInputText: '',
        mandatoryTopics: true);
      checkMessageNotSent(tester);
    });

    testWidgets('if topics are mandatory, reject `realmEmptyTopicDisplayName`', (tester) async {
      await setupAndTapSend(tester,
        topicInputText: eg.defaultRealmEmptyTopicDisplayName,
        mandatoryTopics: true);
      checkMessageNotSent(tester);
    });

    testWidgets('if topics are mandatory, reject "(no topic)"', (tester) async {
      await setupAndTapSend(tester,
        topicInputText: '(no topic)',
        mandatoryTopics: true);
      checkMessageNotSent(tester);
    });
  });

  group('uploads', () {
    void checkAppearsLoading(WidgetTester tester, bool expected) {
      final sendButtonElement = tester.element(find.ancestor(
        of: sendButtonFinder,
        matching: find.byType(IconButton)));
      final sendButtonWidget = sendButtonElement.widget as IconButton;
      final designVariables = DesignVariables.of(sendButtonElement);
      final expectedIconColor = expected
        ? designVariables.icon.withFadedAlpha(0.5)
        : designVariables.icon;
      check(sendButtonWidget.icon)
        .isA<Icon>().color.isNotNull().isSameColorAs(expectedIconColor);
    }

    group('attach from media library', () {
      testWidgets('success', (tester) async {
        TypingNotifier.debugEnable = false;
        addTearDown(TypingNotifier.debugReset);

        final channel = eg.stream();
        final narrow = ChannelNarrow(channel.streamId);
        await prepareComposeBox(tester, narrow: narrow, streams: [channel]);

        // (When we check that the send button looks disabled, it should be because
        // the file is uploading, not a pre-existing reason.)
        await enterTopic(tester, narrow: narrow, topic: 'some topic');
        controller!.content.value = const TextEditingValue(text: 'see image: ');
        await tester.pump();
        checkAppearsLoading(tester, false);

        testBinding.pickFilesResult = FilePickerResult([PlatformFile(
          readStream: Stream.fromIterable(['asdf'.codeUnits]),
          // TODO test inference of MIME type from initial bytes, when
          //   it can't be inferred from path
          path: '/private/var/mobile/Containers/Data/Application/foo/tmp/image.jpg',
          name: 'image.jpg',
          size: 12345,
        )]);
        connection.prepare(delay: const Duration(seconds: 1), json:
          UploadFileResult(uri: '/user_uploads/1/4e/m2A3MSqFnWRLUf9SaPzQ0Up_/image.jpg').toJson());

        await tester.tap(find.byIcon(ZulipIcons.image));
        await tester.pump();
        final call = testBinding.takePickFilesCalls().single;
        check(call.allowMultiple).equals(true);
        check(call.type).equals(FileType.media);

        checkNoErrorDialog(tester);

        check(controller!.content.text)
          .equals('see image: [Uploading image.jpg…]()\n\n');
        // (the request is checked more thoroughly in API tests)
        check(connection.lastRequest!).isA<http.MultipartRequest>()
          ..method.equals('POST')
          ..files.single.which((it) => it
            ..field.equals('file')
            ..length.equals(12345)
            ..filename.equals('image.jpg')
            ..contentType.asString.equals('image/jpeg')
            ..has<Future<List<int>>>((f) => f.finalize().toBytes(), 'contents')
              .completes((it) => it.deepEquals(['asdf'.codeUnits].expand((l) => l)))
          );
        checkAppearsLoading(tester, true);

        await tester.pump(const Duration(seconds: 1));
        check(controller!.content.text)
          .equals('see image: [image.jpg](/user_uploads/1/4e/m2A3MSqFnWRLUf9SaPzQ0Up_/image.jpg)\n\n');
        checkAppearsLoading(tester, false);
      });

      // TODO test what happens when selecting/uploading fails
    });

    group('attach from camera', () {
      testWidgets('success', (tester) async {
        TypingNotifier.debugEnable = false;
        addTearDown(TypingNotifier.debugReset);

        final channel = eg.stream();
        final narrow = ChannelNarrow(channel.streamId);
        await prepareComposeBox(tester, narrow: narrow, streams: [channel]);

        // (When we check that the send button looks disabled, it should be because
        // the file is uploading, not a pre-existing reason.)
        await enterTopic(tester, narrow: narrow, topic: 'some topic');
        controller!.content.value = const TextEditingValue(text: 'see image: ');
        await tester.pump();
        checkAppearsLoading(tester, false);

        testBinding.pickImageResult = XFile.fromData(
          // TODO test inference of MIME type when it's missing here
          mimeType: 'image/jpeg',
          utf8.encode('asdf'),
          name: 'image.jpg',
          length: 12345,
          path: '/private/var/mobile/Containers/Data/Application/foo/tmp/image.jpg',
        );
        connection.prepare(delay: const Duration(seconds: 1), json:
          UploadFileResult(uri: '/user_uploads/1/4e/m2A3MSqFnWRLUf9SaPzQ0Up_/image.jpg').toJson());

        await tester.tap(find.byIcon(ZulipIcons.camera));
        await tester.pump();
        final call = testBinding.takePickImageCalls().single;
        check(call.source).equals(ImageSource.camera);
        check(call.requestFullMetadata).equals(false);

        checkNoErrorDialog(tester);

        check(controller!.content.text)
          .equals('see image: [Uploading image.jpg…]()\n\n');
        // (the request is checked more thoroughly in API tests)
        check(connection.lastRequest!).isA<http.MultipartRequest>()
          ..method.equals('POST')
          ..files.single.which((it) => it
            ..field.equals('file')
            ..length.equals(12345)
            ..filename.equals('image.jpg')
            ..contentType.asString.equals('image/jpeg')
            ..has<Future<List<int>>>((f) => f.finalize().toBytes(), 'contents')
              .completes((it) => it.deepEquals(['asdf'.codeUnits].expand((l) => l)))
          );
        checkAppearsLoading(tester, true);

        await tester.pump(const Duration(seconds: 1));
        check(controller!.content.text)
          .equals('see image: [image.jpg](/user_uploads/1/4e/m2A3MSqFnWRLUf9SaPzQ0Up_/image.jpg)\n\n');
        checkAppearsLoading(tester, false);
      });

      // TODO test what happens when capturing/uploading fails
    },
    // This test fails on Windows because [XFile.name] splits on
    // [Platform.pathSeparator], corresponding to the actual host platform
    // the test is running on, instead of the path separator for the
    // target platform the test is simulating.
    // TODO(upstream): unskip after fix to https://github.com/flutter/flutter/issues/161073
    skip: Platform.isWindows);
  });

  testWidgets('_ShowSavedSnippetsButton', (tester) async {
    final channel = eg.stream();
    await prepareComposeBox(tester, narrow: ChannelNarrow(channel.streamId),
      streams: [channel]);

    check(find.byIcon(ZulipIcons.message_square_text)).findsOne();
  });

  testWidgets('legacy: _ShowSavedSnippetsButton', (tester) async {
    final channel = eg.stream();
    await prepareComposeBox(tester, narrow: ChannelNarrow(channel.streamId),
      streams: [channel],
      zulipFeatureLevel: 296);

    check(find.byIcon(ZulipIcons.message_square_text)).findsNothing();
  });

  // Tests for the bottom sheet that _ShowSavedSnippetsButton leads to
  // are in test/widgets/saved_snippet_test.dart.

  group('SavedSnippetComposeBox', () {
    final newSavedSnippetInputFinder = find.descendant(
      of: find.byType(SavedSnippetComposeBox), matching: find.byType(TextField));

    late List<Route<void>> poppedRoutes;

    Future<void> prepareSavedSnippetComposeBox(WidgetTester tester, {
      required String title,
      required String content,
    }) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      connection = store.connection as FakeApiConnection;

      poppedRoutes = [];
      final navigatorObserver = TestNavigatorObserver()
        ..onPopped = (route, prevRoute) => poppedRoutes.add(route);
      await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
        navigatorObservers: [navigatorObserver],
        child: const SavedSnippetComposeBox()));
      await tester.pump();
      await tester.enterText(newSavedSnippetInputFinder.first, title);
      await tester.enterText(newSavedSnippetInputFinder.last, content);
    }

    testWidgets('should not offer _ShowSavedSnippetsButton', (tester) async {
      await prepareSavedSnippetComposeBox(tester,
        title: 'title foo', content: 'content bar');
      check(find.byIcon(ZulipIcons.message_square_text)).findsNothing();
    });

    testWidgets('add new saved snippet', (tester) async {
      await prepareSavedSnippetComposeBox(tester,
        title: 'title foo', content: 'content bar');

      connection.prepare(json:
        CreateSavedSnippetResult(savedSnippetId: 123).toJson());
      await tester.tap(find.byIcon(ZulipIcons.check));
      await tester.pump(Duration.zero);
      check(poppedRoutes).single;
      check(connection.takeRequests()).single.isA<http.Request>()
        ..bodyFields['title'].equals('title foo')
        ..bodyFields['content'].equals('content bar');
      checkNoErrorDialog(tester);

      await store.handleEvent(SavedSnippetsAddEvent(id: 100,
        savedSnippet: eg.savedSnippet(
          id: 123, title: 'title foo', content: 'content bar')));
      await tester.pump();
      check(find.text('title foo')).findsOne();
      check(find.text('content bar')).findsOne();
    });

    testWidgets('handle unexpected API exception', (tester) async {
      await prepareSavedSnippetComposeBox(tester,
        title: 'title foo', content: 'content bar');

      connection.prepare(apiException: eg.apiExceptionUnauthorized());
      await tester.tap(find.byIcon(ZulipIcons.check));
      await tester.pump(Duration.zero);
      check(poppedRoutes).isEmpty();
      checkErrorDialog(tester,
        expectedTitle: 'Failed to create saved snippet',
        expectedMessage: 'The server said:\n\nInvalid API key');
    });

    group('client validation errors', () {
      testWidgets('empty title', (tester) async {
        await prepareSavedSnippetComposeBox(tester,
          title: '', content: 'content bar');

        await tester.tap(find.byIcon(ZulipIcons.check));
        await tester.pump(Duration.zero);
        check(poppedRoutes).isEmpty();
        check(connection.takeRequests()).isEmpty();
        checkErrorDialog(tester,
          expectedTitle: 'Failed to create saved snippet',
          expectedMessage: 'Title cannot be empty.');
      });

      testWidgets('empty content', (tester) async {
        await prepareSavedSnippetComposeBox(tester,
          title: 'title foo', content: '');

        await tester.tap(find.byIcon(ZulipIcons.check));
        await tester.pump(Duration.zero);
        check(poppedRoutes).isEmpty();
        check(connection.takeRequests()).isEmpty();
        checkErrorDialog(tester,
          expectedTitle: 'Failed to create saved snippet',
          expectedMessage: 'Content cannot be empty.');
      });

      testWidgets('title is too long', (tester) async {
        await prepareSavedSnippetComposeBox(tester,
          title: 'a' * 61, content: 'content bar');

        await tester.tap(find.byIcon(ZulipIcons.check));
        await tester.pump(Duration.zero);
        check(poppedRoutes).isEmpty();
        check(connection.takeRequests()).isEmpty();
        checkErrorDialog(tester,
          expectedTitle: 'Failed to create saved snippet',
          expectedMessage: "Title length shouldn't be greater than 60 characters.");
      });

      testWidgets('content is too long', (tester) async {
        await prepareSavedSnippetComposeBox(tester,
          title: 'title foo', content: 'a' * 10001);

        await tester.tap(find.byIcon(ZulipIcons.check));
        await tester.pump(Duration.zero);
        check(poppedRoutes).isEmpty();
        check(connection.takeRequests()).isEmpty();
        checkErrorDialog(tester,
          expectedTitle: 'Failed to create saved snippet',
          expectedMessage: "Content length shouldn't be greater than 10000 characters.");
      });

      testWidgets('disable send button if there are validation errors', (tester) async {
        await prepareSavedSnippetComposeBox(tester,
          title: '', content: 'content bar');
        final iconElement = tester.element(find.byIcon(ZulipIcons.check));
        final designVariables = DesignVariables.of(iconElement);
        check(iconElement.widget).isA<Icon>().color.isNotNull()
          .isSameColorAs(designVariables.icon.withFadedAlpha(0.5));

        await tester.enterText(newSavedSnippetInputFinder.first, 'title foo');
        await tester.pump();
        check(iconElement.widget).isA<Icon>().color.isNotNull()
          .isSameColorAs(designVariables.icon);
      });
    });
  });

  group('error banner', () {
    final zulipLocalizations = GlobalLocalizations.zulipLocalizations;

    Finder inputFieldFinder() => find.descendant(
      of: find.byType(ComposeBox),
      matching: find.byType(TextField));

    Finder attachButtonFinder(IconData icon) => find.descendant(
      of: find.byType(ComposeBox),
      matching: find.widgetWithIcon(IconButton, icon));

    void checkComposeBoxParts({required bool areShown}) {
      final inputFieldCount = inputFieldFinder().evaluate().length;
      areShown ? check(inputFieldCount).isGreaterThan(0) : check(inputFieldCount).equals(0);
      check(attachButtonFinder(ZulipIcons.attach_file).evaluate().length).equals(areShown ? 1 : 0);
      check(attachButtonFinder(ZulipIcons.image).evaluate().length).equals(areShown ? 1 : 0);
      check(attachButtonFinder(ZulipIcons.camera).evaluate().length).equals(areShown ? 1 : 0);
    }

    void checkBannerWithLabel(String label, {required bool isShown}) {
      check(find.text(label).evaluate().length).equals(isShown ? 1 : 0);
    }

    void checkComposeBoxIsShown(bool isShown, {required String bannerLabel}) {
      checkComposeBoxParts(areShown: isShown);
      checkBannerWithLabel(bannerLabel, isShown: !isShown);
    }

    group('in DMs with deactivated users', () {
      void checkComposeBox({required bool isShown}) => checkComposeBoxIsShown(isShown,
        bannerLabel: zulipLocalizations.errorBannerDeactivatedDmLabel);

      Future<void> changeUserStatus(WidgetTester tester,
          {required User user, required bool isActive}) async {
        await store.handleEvent(RealmUserUpdateEvent(id: 1,
          userId: user.userId, isActive: isActive));
        await tester.pump();
      }

      DmNarrow dmNarrowWith(User otherUser) => DmNarrow.withUser(otherUser.userId,
        selfUserId: eg.selfUser.userId);

      DmNarrow groupDmNarrowWith(List<User> otherUsers) => DmNarrow.withOtherUsers(
        otherUsers.map((u) => u.userId), selfUserId: eg.selfUser.userId);

      group('1:1 DMs', () {
        testWidgets('compose box replaced with a banner', (tester) async {
          final deactivatedUser = eg.user(isActive: false);
          await prepareComposeBox(tester, narrow: dmNarrowWith(deactivatedUser),
            otherUsers: [deactivatedUser]);
          checkComposeBox(isShown: false);
        });

        testWidgets('active user becomes deactivated -> '
            'compose box is replaced with a banner', (tester) async {
          final activeUser = eg.user(isActive: true);
          await prepareComposeBox(tester, narrow: dmNarrowWith(activeUser),
            otherUsers: [activeUser]);
          checkComposeBox(isShown: true);

          await changeUserStatus(tester, user: activeUser, isActive: false);
          checkComposeBox(isShown: false);
        });

        testWidgets('deactivated user becomes active -> '
            'banner is replaced with the compose box', (tester) async {
          final deactivatedUser = eg.user(isActive: false);
          await prepareComposeBox(tester, narrow: dmNarrowWith(deactivatedUser),
            otherUsers: [deactivatedUser]);
          checkComposeBox(isShown: false);

          await changeUserStatus(tester, user: deactivatedUser, isActive: true);
          checkComposeBox(isShown: true);
        });
      });

      group('group DMs', () {
        testWidgets('compose box replaced with a banner', (tester) async {
          final deactivatedUsers = [eg.user(isActive: false), eg.user(isActive: false)];
          await prepareComposeBox(tester, narrow: groupDmNarrowWith(deactivatedUsers),
            otherUsers: deactivatedUsers);
          checkComposeBox(isShown: false);
        });

        testWidgets('at least one user becomes deactivated -> '
            'compose box is replaced with a banner', (tester) async {
          final activeUsers = [eg.user(isActive: true), eg.user(isActive: true)];
          await prepareComposeBox(tester, narrow: groupDmNarrowWith(activeUsers),
            otherUsers: activeUsers);
          checkComposeBox(isShown: true);

          await changeUserStatus(tester, user: activeUsers[0], isActive: false);
          checkComposeBox(isShown: false);
        });

        testWidgets('all deactivated users become active -> '
            'banner is replaced with the compose box', (tester) async {
          final deactivatedUsers = [eg.user(isActive: false), eg.user(isActive: false)];
          await prepareComposeBox(tester, narrow: groupDmNarrowWith(deactivatedUsers),
            otherUsers: deactivatedUsers);
          checkComposeBox(isShown: false);

          await changeUserStatus(tester, user: deactivatedUsers[0], isActive: true);
          checkComposeBox(isShown: false);

          await changeUserStatus(tester, user: deactivatedUsers[1], isActive: true);
          checkComposeBox(isShown: true);
        });
      });
    });

    group('in channel/topic narrow according to channel post policy', () {
      void checkComposeBox({required bool isShown}) => checkComposeBoxIsShown(isShown,
        bannerLabel: zulipLocalizations.errorBannerCannotPostInChannelLabel);

      final narrowTestCases = [
        ('channel', const ChannelNarrow(1)),
        ('topic',   eg.topicNarrow(1, 'topic')),
      ];

      for (final (String narrowType, Narrow narrow) in narrowTestCases) {
        testWidgets('compose box is shown in $narrowType narrow', (tester) async {
          await prepareComposeBox(tester,
            narrow: narrow,
            selfUser: eg.user(role: UserRole.administrator),
            streams: [eg.stream(streamId: 1,
              channelPostPolicy: ChannelPostPolicy.moderators)]);
          checkComposeBox(isShown: true);
        });

        testWidgets('error banner is shown in $narrowType narrow', (tester) async {
          await prepareComposeBox(tester,
            narrow: narrow,
            selfUser: eg.user(role: UserRole.moderator),
            streams: [eg.stream(streamId: 1,
              channelPostPolicy: ChannelPostPolicy.administrators)]);
          checkComposeBox(isShown: false);
        });
      }

      testWidgets('user loses privilege -> compose box is replaced with the banner', (tester) async {
        final selfUser = eg.user(role: UserRole.administrator);
        await prepareComposeBox(tester,
          narrow: const ChannelNarrow(1),
          selfUser: selfUser,
          streams: [eg.stream(streamId: 1,
            channelPostPolicy: ChannelPostPolicy.administrators)]);
        checkComposeBox(isShown: true);

        await store.handleEvent(RealmUserUpdateEvent(id: 1,
          userId: selfUser.userId, role: UserRole.moderator));
        await tester.pump();
        checkComposeBox(isShown: false);
      });

      testWidgets('user gains privilege -> banner is replaced with the compose box', (tester) async {
        final selfUser = eg.user(role: UserRole.guest);
        await prepareComposeBox(tester,
          narrow: const ChannelNarrow(1),
          selfUser: selfUser,
          streams: [eg.stream(streamId: 1,
            channelPostPolicy: ChannelPostPolicy.moderators)]);
        checkComposeBox(isShown: false);

        await store.handleEvent(RealmUserUpdateEvent(id: 1,
          userId: selfUser.userId, role: UserRole.administrator));
        await tester.pump();
        checkComposeBox(isShown: true);
      });

      testWidgets('channel policy becomes stricter -> compose box is replaced with the banner', (tester) async {
        final selfUser = eg.user(role: UserRole.guest);
        final channel = eg.stream(streamId: 1,
          channelPostPolicy: ChannelPostPolicy.any);

        await prepareComposeBox(tester,
          narrow: const ChannelNarrow(1),
          selfUser: selfUser,
          streams: [channel]);
        checkComposeBox(isShown: true);

        await store.handleEvent(eg.channelUpdateEvent(channel,
          property: ChannelPropertyName.channelPostPolicy,
          value: ChannelPostPolicy.fullMembers));
        await tester.pump();
        checkComposeBox(isShown: false);
      });

      testWidgets('channel policy becomes less strict -> banner is replaced with the compose box', (tester) async {
        final selfUser = eg.user(role: UserRole.moderator);
        final channel = eg.stream(streamId: 1,
          channelPostPolicy: ChannelPostPolicy.administrators);

        await prepareComposeBox(tester,
          narrow: const ChannelNarrow(1),
          selfUser: selfUser,
          streams: [channel]);
        checkComposeBox(isShown: false);

        await store.handleEvent(eg.channelUpdateEvent(channel,
          property: ChannelPropertyName.channelPostPolicy,
          value: ChannelPostPolicy.moderators));
        await tester.pump();
        checkComposeBox(isShown: true);
      });
    });
  });

  group('ComposeBox content input scaling', () {
    const verticalPadding = 8;
    final stream = eg.stream();
    final narrow = eg.topicNarrow(stream.streamId, 'foo');

    Future<void> checkContentInputMaxHeight(WidgetTester tester, {
      required double maxHeight,
      required int maxVisibleLines,
    }) async {
      TypingNotifier.debugEnable = false;
      addTearDown(TypingNotifier.debugReset);

      // Add one line at a time, until the content input reaches its max height.
      int numLines;
      double? height;
      for (numLines = 2; numLines <= 1000; numLines++) {
        final content = List.generate(numLines, (_) => 'foo').join('\n');
        await enterContent(tester, content);
        await tester.pump();
        final newHeight = tester.getRect(contentInputFinder).height;
        if (newHeight == height) {
          break;
        }
        height = newHeight;
      }
      check(height).isNotNull().isCloseTo(maxHeight, 0.5);
      // The last line added did not stretch the content input,
      // so only the lines before it are at least partially visible.
      check(numLines - 1).equals(maxVisibleLines);
    }

    testWidgets('normal text scale factor', (tester) async {
      await prepareComposeBox(tester, narrow: narrow, streams: [stream]);

      await checkContentInputMaxHeight(tester,
        maxHeight: verticalPadding + 170, maxVisibleLines: 8);
    });

    testWidgets('lower text scale factor', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 0.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await prepareComposeBox(tester, narrow: narrow, streams: [stream]);
      await checkContentInputMaxHeight(tester,
        maxHeight: verticalPadding + 170 * 0.8, maxVisibleLines: 8);
    });

    testWidgets('higher text scale factor', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await prepareComposeBox(tester, narrow: narrow, streams: [stream]);
      await checkContentInputMaxHeight(tester,
        maxHeight: verticalPadding + 170 * 1.5, maxVisibleLines: 8);
    });

    testWidgets('higher text scale factor exceeding threshold', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await prepareComposeBox(tester, narrow: narrow, streams: [stream]);
      await checkContentInputMaxHeight(tester,
        maxHeight: verticalPadding + 170 * 1.5, maxVisibleLines: 6);
    });
  });

  group('ComposeBoxState new-event-queue transition', () {
    testWidgets('content input not cleared when store changes', (tester) async {
      // Regression test for: https://github.com/zulip/zulip-flutter/issues/1470

      TypingNotifier.debugEnable = false;
      addTearDown(TypingNotifier.debugReset);

      final channel = eg.stream();
      await prepareComposeBox(tester,
        narrow: eg.topicNarrow(channel.streamId, 'topic'), streams: [channel]);

      await enterContent(tester, 'some content');
      checkContentInputValue(tester, 'some content');

      // Encache a new connection; prepare it for the message-list fetch
      final newConnection = (testBinding.globalStore
          ..clearCachedApiConnections()
          ..useCachedApiConnections = true)
        .apiConnectionFromAccount(store.account) as FakeApiConnection;
      newConnection.prepare(json:
        eg.newestGetMessagesResult(foundOldest: true, messages: []).toJson());

      store.updateMachine!
        ..debugPauseLoop()
        ..poll()
        ..debugPrepareLoopError(
            eg.apiExceptionBadEventQueueId(queueId: store.queueId))
        ..debugAdvanceLoop();
      await tester.pump();
      await tester.pump(Duration.zero);

      final newStore = testBinding.globalStore.perAccountSync(store.accountId)!;
      check(newStore)
        // a new store has replaced the old one
        ..not((it) => it.identicalTo(store))
        // new store has the same boring data, in order to present a compose box
        // that allows composing, instead of a no-posting-permission banner
        ..accountId.equals(store.accountId)
        ..streams.containsKey(channel.streamId);

      checkContentInputValue(tester, 'some content');
    });
  });

  group('edit message', () {
    final channel = eg.stream();
    final topic = 'topic';
    final message = eg.streamMessage(sender: eg.selfUser, stream: channel, topic: topic);
    final dmMessage = eg.dmMessage(from: eg.selfUser, to: [eg.otherUser]);

    final channelNarrow = ChannelNarrow(channel.streamId);
    final topicNarrow = eg.topicNarrow(channel.streamId, topic);
    final dmNarrow = DmNarrow.ofMessage(dmMessage, selfUserId: eg.selfUser.userId);

    Message msgInNarrow(Narrow narrow) {
      final List<Message> messages = [message, dmMessage];
      return messages.where((m) => narrow.containsMessage(m)).single;
    }

    int msgIdInNarrow(Narrow narrow) => msgInNarrow(narrow).id;

    Future<void> prepareEditMessage(WidgetTester tester, {required Narrow narrow}) async {
      await prepareComposeBox(tester,
        narrow: narrow,
        streams: [channel]);
      await store.addMessages([message, dmMessage]);
      await tester.pump(); // message list updates
    }

    /// Check that the compose box is in the "Preparing…" state,
    /// awaiting the fetch-raw-content request.
    Future<void> checkAwaitingRawMessageContent(WidgetTester tester) async {
      check(state.controller)
        .isA<EditMessageComposeBoxController>()
        ..originalRawContent.isNull()
        ..content.value.text.equals('');
      check(tester.widget(contentInputFinder))
        .isA<TextField>()
        .decoration.isNotNull().hintText.equals('Preparing…');
      checkContentInputValue(tester, '');

      // Controls are disabled
      await tester.tap(find.byIcon(ZulipIcons.attach_file), warnIfMissed: false);
      await tester.pump();
      check(testBinding.takePickFilesCalls()).isEmpty();

      // Save button is disabled
      final lastRequest = connection.lastRequest;
      await tester.tap(
        find.widgetWithText(ZulipWebUiKitButton, 'Save'), warnIfMissed: false);
      await tester.pump(Duration.zero);
      check(connection.lastRequest).equals(lastRequest);
    }

    /// Starts an interaction from the action sheet's 'Edit message' button.
    ///
    /// The fetch-raw-content request is prepared with [delay] (default 1s).
    Future<void> startInteractionFromActionSheet(
      WidgetTester tester, {
      required int messageId,
      String originalRawContent = 'foo',
      Duration delay = const Duration(seconds: 1),
      bool fetchShouldSucceed = true,
    }) async {
      await tester.longPress(find.byWidgetPredicate((widget) =>
        widget is MessageWithPossibleSender && widget.item.message.id == messageId));
      // sheet appears onscreen; default duration of bottom-sheet enter animation
      await tester.pump(const Duration(milliseconds: 250));
      final findEditButton = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byIcon(ZulipIcons.edit, skipOffstage: false));
      await tester.ensureVisible(findEditButton);
      if (fetchShouldSucceed) {
        connection.prepare(delay: delay,
          json: GetMessageResult(message: eg.streamMessage(content: originalRawContent)).toJson());
      } else {
        connection.prepare(apiException: eg.apiBadRequest(), delay: delay);
      }
      await tester.tap(findEditButton);
      await tester.pump();
      await tester.pump();
      connection.takeRequests();
    }

    /// Starts an interaction by tapping a failed edit in the message list.
    Future<void> startInteractionFromRestoreFailedEdit(
      WidgetTester tester, {
      required int messageId,
      String originalRawContent = 'foo',
      String newContent = 'bar',
    }) async {
      await startInteractionFromActionSheet(tester,
        messageId: messageId, originalRawContent: originalRawContent);
      await tester.pump(Duration(seconds: 1)); // raw-content request
      await enterContent(tester, newContent);

      connection.prepare(apiException: eg.apiBadRequest());
      await tester.tap(find.widgetWithText(ZulipWebUiKitButton, 'Save'));
      await tester.pump(Duration.zero);
      await tester.tap(find.text('EDIT NOT SAVED'));
      await tester.pump();
      connection.takeRequests();
    }

    void checkRequest(int messageId, {
      required String prevContent,
      required String content,
    }) {
      final prevContentSha256 = sha256.convert(utf8.encode(prevContent)).toString();
      check(connection.takeRequests()).single.isA<http.Request>()
        ..method.equals('PATCH')
        ..url.path.equals('/api/v1/messages/$messageId')
        ..bodyFields.deepEquals({
          'prev_content_sha256': prevContentSha256,
          'content': content,
        });
    }

    /// Check that the compose box is not in editing mode.
    void checkNotInEditingMode(WidgetTester tester, {
      required Narrow narrow,
      String expectedContentText = '',
    }) {
      switch (narrow) {
        case ChannelNarrow():
          check(state.controller)
            .isA<StreamComposeBoxController>()
            .content.value.text.equals(expectedContentText);
        case TopicNarrow():
        case DmNarrow():
          check(state.controller)
            .isA<FixedDestinationComposeBoxController>()
            .content.value.text.equals(expectedContentText);
        default:
          throw StateError('unexpected narrow type');
      }
      checkContentInputValue(tester, expectedContentText);
    }

    void testSmoke({required Narrow narrow, required _EditInteractionStart start}) {
      testWidgets('smoke: $narrow, ${start.message()}', (tester) async {
        await prepareEditMessage(tester, narrow: narrow);
        checkNotInEditingMode(tester, narrow: narrow);

        final messageId = msgIdInNarrow(narrow);
        switch (start) {
          case _EditInteractionStart.actionSheet:
            await startInteractionFromActionSheet(tester,
              messageId: messageId,
              originalRawContent: 'foo');
            await checkAwaitingRawMessageContent(tester);
            await tester.pump(Duration(seconds: 1)); // fetch-raw-content request
            checkContentInputValue(tester, 'foo');
          case _EditInteractionStart.restoreFailedEdit:
            await startInteractionFromRestoreFailedEdit(tester,
              messageId: messageId,
              originalRawContent: 'foo',
              newContent: 'bar');
            checkContentInputValue(tester, 'bar');
        }

        // Now that we have the raw content, check the input is interactive
        // but no typing notifications are sent…
        check(TypingNotifier.debugEnable).isTrue();
        check(state).controller.contentFocusNode.hasFocus.isTrue();
        await enterContent(tester, 'some new content');
        check(connection.takeRequests()).isEmpty();

        // …and the upload buttons work.
        testBinding.pickFilesResult = FilePickerResult([
          PlatformFile(name: 'file.jpg', size: 1000, readStream: Stream.fromIterable(['asdf'.codeUnits]))]);
        connection.prepare(json:
          UploadFileResult(uri: '/path/file.jpg').toJson());
        await tester.tap(find.byIcon(ZulipIcons.attach_file), warnIfMissed: false);
        await tester.pump(Duration.zero);
        checkNoErrorDialog(tester);
        check(testBinding.takePickFilesCalls()).length.equals(1);
        connection.takeRequests(); // upload request

        // TODO could also check that quote-and-reply and autocomplete work
        //   (but as their own test cases, for a single narrow and start)

        // Save; check that the request is made and the compose box resets.
        connection.prepare(json: UpdateMessageResult().toJson());
        await tester.tap(find.widgetWithText(ZulipWebUiKitButton, 'Save'));
        checkRequest(messageId,
          prevContent: 'foo', content: 'some new content[file.jpg](/path/file.jpg)');
        await tester.pump(Duration.zero);
        checkNotInEditingMode(tester, narrow: narrow);
      });
    }
    testSmoke(narrow: channelNarrow, start: _EditInteractionStart.actionSheet);
    testSmoke(narrow: topicNarrow,   start: _EditInteractionStart.actionSheet);
    testSmoke(narrow: dmNarrow,      start: _EditInteractionStart.actionSheet);
    testSmoke(narrow: channelNarrow, start: _EditInteractionStart.restoreFailedEdit);
    testSmoke(narrow: topicNarrow,   start: _EditInteractionStart.restoreFailedEdit);
    testSmoke(narrow: dmNarrow,      start: _EditInteractionStart.restoreFailedEdit);

    Future<void> expectAndHandleDiscardConfirmation(
      WidgetTester tester, {
      required bool shouldContinue,
    }) async {
      final (actionButton, cancelButton) = checkSuggestedActionDialog(tester,
        expectedTitle: 'Discard the message you’re writing?',
        expectedMessage: 'When you edit a message, the content that was previously in the compose box is discarded.',
        expectedActionButtonText: 'Discard');
      if (shouldContinue) {
        await tester.tap(find.byWidget(actionButton));
      } else {
        await tester.tap(find.byWidget(cancelButton));
      }
    }

    // Test the "Discard…?" confirmation dialog when you tap "Edit message" in
    // the action sheet but there's text in the compose box for a new message.
    void testInterruptComposingFromActionSheet({required Narrow narrow}) {
      testWidgets('interrupting new-message compose: $narrow', (tester) async {
        TypingNotifier.debugEnable = false;
        addTearDown(TypingNotifier.debugReset);

        final messageId = msgIdInNarrow(narrow);
        await prepareEditMessage(tester, narrow: narrow);
        checkNotInEditingMode(tester, narrow: narrow);

        await enterContent(tester, 'composing new message');

        // Expect confirmation dialog; tap Cancel
        await startInteractionFromActionSheet(tester, messageId: messageId);
        await expectAndHandleDiscardConfirmation(tester, shouldContinue: false);
        check(connection.takeRequests()).isEmpty();
        // fetch-raw-content request wasn't actually sent;
        // take back its prepared response
        connection.clearPreparedResponses();

        // Twiddle the input to make sure it still works
        checkNotInEditingMode(tester,
          narrow: narrow, expectedContentText: 'composing new message');
        await enterContent(tester, 'composing new message…');
        checkContentInputValue(tester, 'composing new message…');

        // Try again, but this time tap Discard and expect to enter an edit session
        await startInteractionFromActionSheet(tester,
          messageId: messageId, originalRawContent: 'foo');
        await expectAndHandleDiscardConfirmation(tester, shouldContinue: true);
        await tester.pump();
        await checkAwaitingRawMessageContent(tester);
        await tester.pump(Duration(seconds: 1)); // fetch-raw-content request
        check(connection.takeRequests()).length.equals(1);
        checkContentInputValue(tester, 'foo');
        await enterContent(tester, 'bar');

        // Save; check that the request is made and the compose box resets.
        connection.prepare(json: UpdateMessageResult().toJson());
        await tester.tap(find.widgetWithText(ZulipWebUiKitButton, 'Save'));
        checkRequest(messageId, prevContent: 'foo', content: 'bar');
        await tester.pump(Duration.zero);
        checkNotInEditingMode(tester, narrow: narrow);
      });
    }
    // Cover multiple narrows, checking that the Discard button resets the state
    // correctly for each one.
    testInterruptComposingFromActionSheet(narrow: channelNarrow);
    testInterruptComposingFromActionSheet(narrow: topicNarrow);
    testInterruptComposingFromActionSheet(narrow: dmNarrow);

    // Test the "Discard…?" confirmation dialog when you want to restore
    // a failed edit but there's text in the compose box for a new message.
    void testInterruptComposingFromFailedEdit({required Narrow narrow}) {
      testWidgets('interrupting new-message compose by tapping failed edit to restore: $narrow', (tester) async {
        TypingNotifier.debugEnable = false;
        addTearDown(TypingNotifier.debugReset);

        final messageId = msgIdInNarrow(narrow);
        await prepareEditMessage(tester, narrow: narrow);

        await startInteractionFromActionSheet(tester,
          messageId: messageId, originalRawContent: 'foo');
        await tester.pump(Duration(seconds: 1)); // raw-content request
        await enterContent(tester, 'bar');

        connection.prepare(apiException: eg.apiBadRequest());
        await tester.tap(find.widgetWithText(ZulipWebUiKitButton, 'Save'));
        connection.takeRequests();
        await tester.pump(Duration.zero);
        checkNotInEditingMode(tester, narrow: narrow);
        check(find.text('EDIT NOT SAVED')).findsOne();

        await enterContent(tester, 'composing new message');

        // Expect confirmation dialog; tap Cancel
        await tester.tap(find.text('EDIT NOT SAVED'));
        await tester.pump();
        await expectAndHandleDiscardConfirmation(tester, shouldContinue: false);
        checkNotInEditingMode(tester,
          narrow: narrow, expectedContentText: 'composing new message');

        // Twiddle the input to make sure it still works
        await enterContent(tester, 'composing new message…');

        // Try again, but this time tap Discard and expect to enter edit session
        await tester.tap(find.text('EDIT NOT SAVED'));
        await tester.pump();
        await expectAndHandleDiscardConfirmation(tester, shouldContinue: true);
        await tester.pump();
        checkContentInputValue(tester, 'bar');
        await enterContent(tester, 'baz');

        // Save; check that the request is made and the compose box resets.
        connection.prepare(json: UpdateMessageResult().toJson());
        await tester.tap(find.widgetWithText(ZulipWebUiKitButton, 'Save'));
        checkRequest(messageId, prevContent: 'foo', content: 'baz');
        await tester.pump(Duration.zero);
        checkNotInEditingMode(tester, narrow: narrow);
      });
    }
    // (So tests run faster, skip some narrows that are already covered above.)
    testInterruptComposingFromFailedEdit(narrow: channelNarrow);
    // testInterruptComposingFromFailedEdit(narrow: topicNarrow);
    // testInterruptComposingFromFailedEdit(narrow: dmNarrow);

    // TODO also test:
    //   - Restore a failed edit, but when there's compose input for an edit-
    //     message session. (The failed edit would be for a different message,
    //     or else started from a different MessageListPage.)

    void testFetchRawContentFails({required Narrow narrow}) {
      final description = 'fetch-raw-content fails: $narrow';
      testWidgets(description, (tester) async {
        await prepareEditMessage(tester, narrow: narrow);
        checkNotInEditingMode(tester, narrow: narrow);

        final messageId = msgIdInNarrow(narrow);
        await startInteractionFromActionSheet(tester,
          messageId: messageId,
          originalRawContent: 'foo',
          fetchShouldSucceed: false);
        await checkAwaitingRawMessageContent(tester);
        await tester.pump(Duration(seconds: 1)); // fetch-raw-content request
        checkErrorDialog(tester, expectedTitle: 'Could not edit message');
        checkNotInEditingMode(tester, narrow: narrow);
      });
    }
    // Skip some narrows so the tests run faster;
    // the codepaths to be tested are basically the same.
    // testFetchRawContentFails(narrow: channelNarrow);
    testFetchRawContentFails(narrow: topicNarrow);
    // testFetchRawContentFails(narrow: dmNarrow);

    /// Test that an edit session is really cleared by the Cancel button.
    ///
    /// If `start: _EditInteractionStart.actionSheet` (the default),
    /// pass duringFetchRawContentRequest to control whether the Cancel button
    /// is tapped during (true) or after (false) the fetch-raw-content request.
    ///
    /// If `start: _EditInteractionStart.restoreFailedEdit`,
    /// don't pass duringFetchRawContentRequest.
    void testCancel({
      required Narrow narrow,
      _EditInteractionStart start = _EditInteractionStart.actionSheet,
      bool? duringFetchRawContentRequest,
    }) {
      final description = StringBuffer()..write('tap Cancel ');
      switch (start) {
        case _EditInteractionStart.actionSheet:
          assert(duringFetchRawContentRequest != null);
          description
            ..write(duringFetchRawContentRequest! ? 'during ' : 'after ')
            ..write('fetch-raw-content request: ');
        case _EditInteractionStart.restoreFailedEdit:
          assert(duringFetchRawContentRequest == null);
          description.write('when editing from a restored failed edit: ');
      }
      description.write('$narrow');
      testWidgets(description.toString(), (tester) async {
        await prepareEditMessage(tester, narrow: narrow);
        checkNotInEditingMode(tester, narrow: narrow);

        final messageId = msgIdInNarrow(narrow);
        switch (start) {
          case _EditInteractionStart.actionSheet:
            await startInteractionFromActionSheet(tester,
              messageId: messageId, delay: Duration(seconds: 5));
            await checkAwaitingRawMessageContent(tester);
            await tester.pump(duringFetchRawContentRequest!
              ? Duration(milliseconds: 500)
              : Duration(seconds: 5));
          case _EditInteractionStart.restoreFailedEdit:
            await startInteractionFromRestoreFailedEdit(tester,
              messageId: messageId,
              newContent: 'bar');
            checkContentInputValue(tester, 'bar');
        }

        await tester.tap(find.widgetWithText(ZulipWebUiKitButton, 'Cancel'));
        await tester.pump();
        checkNotInEditingMode(tester, narrow: narrow);

        // We've canceled the previous edit session, so we should be able to
        // do a new edit-message session…
        await startInteractionFromActionSheet(tester,
          messageId: messageId, originalRawContent: 'foo');
        await checkAwaitingRawMessageContent(tester);
        await tester.pump(Duration(seconds: 1)); // fetch-raw-content request
        checkContentInputValue(tester, 'foo');
        await enterContent(tester, 'qwerty');
        connection.prepare(json: UpdateMessageResult().toJson());
        await tester.tap(find.widgetWithText(ZulipWebUiKitButton, 'Save'));
        checkRequest(messageId, prevContent: 'foo', content: 'qwerty');
        await tester.pump(Duration.zero);
        checkNotInEditingMode(tester, narrow: narrow);

        // …or send a new message.
        connection.prepare(json: {}); // for typing-start request
        connection.prepare(json: {}); // for typing-stop request
        await enterContent(tester, 'new message to send');
        state.controller.contentFocusNode.unfocus();
        await tester.pump();
        check(connection.takeRequests()).deepEquals(<Condition<Object?>>[
          (it) => it.isA<http.Request>()
            ..method.equals('POST')..url.path.equals('/api/v1/typing'),
          (it) => it.isA<http.Request>()
            ..method.equals('POST')..url.path.equals('/api/v1/typing')]);
        if (narrow is ChannelNarrow) {
          await enterTopic(tester, narrow: narrow, topic: topic);
        }
        await tester.pump();
        await tapSendButton(tester);
        check(connection.takeRequests()).single.isA<http.Request>()
          ..method.equals('POST')
          ..url.path.equals('/api/v1/messages');
        checkContentInputValue(tester, '');

        if (start == _EditInteractionStart.actionSheet && duringFetchRawContentRequest!) {
          // Await the fetch-raw-content request from the canceled edit session;
          // its completion shouldn't affect anything.
          await tester.pump(Duration(seconds: 5));
        }
        checkNotInEditingMode(tester, narrow: narrow);
        check(connection.takeRequests()).isEmpty();
      });
    }
    // Skip some narrows so the tests run faster;
    // the codepaths to be tested are basically the same.
    testCancel(narrow: channelNarrow, duringFetchRawContentRequest: false);
    // testCancel(narrow: topicNarrow,   duringFetchRawContentRequest: false);
    testCancel(narrow: dmNarrow,      duringFetchRawContentRequest: false);
    // testCancel(narrow: channelNarrow, duringFetchRawContentRequest: true);
    testCancel(narrow: topicNarrow,   duringFetchRawContentRequest: true);
    // testCancel(narrow: dmNarrow,      duringFetchRawContentRequest: true);
    testCancel(narrow: channelNarrow, start: _EditInteractionStart.restoreFailedEdit);
    // testCancel(narrow: topicNarrow,   start: _EditInteractionStart.restoreFailedEdit);
    // testCancel(narrow: dmNarrow,      start: _EditInteractionStart.restoreFailedEdit);
  });
}

/// How the edit interaction is started:
/// from the action sheet, or by restoring a failed edit.
enum _EditInteractionStart {
  actionSheet,
  restoreFailedEdit;

  String message() {
    return switch (this) {
      _EditInteractionStart.actionSheet => 'from action sheet',
      _EditInteractionStart.restoreFailedEdit => 'from restoring a failed edit',
    };
  }
}
