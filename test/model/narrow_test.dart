
import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/narrow.dart';

import '../example_data.dart' as eg;
import 'narrow_checks.dart';

void main() {
  group('DmNarrow', () {
    test('constructor assertions', () {
      check(() => DmNarrow(allRecipientIds: [2, 12], selfUserId: 2)).returnsNormally();
      check(() => DmNarrow(allRecipientIds: [2],     selfUserId: 2)).returnsNormally();

      check(() => DmNarrow(allRecipientIds: [12, 2], selfUserId: 2)).throws();
      check(() => DmNarrow(allRecipientIds: [2, 2],  selfUserId: 2)).throws();
      check(() => DmNarrow(allRecipientIds: [2, 12], selfUserId: 1)).throws();
      check(() => DmNarrow(allRecipientIds: [],      selfUserId: 2)).throws();
    });

    test('otherRecipientIds', () {
      check(DmNarrow(allRecipientIds: [1, 2, 3], selfUserId: 2))
        .otherRecipientIds.deepEquals([1, 3]);
      check(DmNarrow(allRecipientIds: [1, 2], selfUserId: 2))
        .otherRecipientIds.deepEquals([1]);
      check(DmNarrow(allRecipientIds: [2], selfUserId: 2))
        .otherRecipientIds.deepEquals([]);
    });

    test('containsMessage', () {
      final user1 = eg.user(userId: 1);
      final user2 = eg.user(userId: 2);
      final user3 = eg.user(userId: 3);
      final narrow2   = DmNarrow(allRecipientIds: [2],       selfUserId: 2);
      final narrow12  = DmNarrow(allRecipientIds: [1, 2],    selfUserId: 2);
      final narrow123 = DmNarrow(allRecipientIds: [1, 2, 3], selfUserId: 2);

      Message dm(User from, List<User> to) => eg.dmMessage(from: from, to: to);
      final streamMessage = eg.streamMessage(sender: user2);

      check(narrow2.containsMessage(streamMessage)).isFalse();
      check(narrow2.containsMessage(dm(user2, []))).isTrue();
      check(narrow2.containsMessage(dm(user1, [user2]))).isFalse();
      check(narrow2.containsMessage(dm(user2, [user1]))).isFalse();
      check(narrow2.containsMessage(dm(user1, [user2, user3]))).isFalse();
      check(narrow2.containsMessage(dm(user2, [user1, user3]))).isFalse();
      check(narrow2.containsMessage(dm(user3, [user1, user2]))).isFalse();

      check(narrow12.containsMessage(streamMessage)).isFalse();
      check(narrow12.containsMessage(dm(user2, []))).isFalse();
      check(narrow12.containsMessage(dm(user1, [user2]))).isTrue();
      check(narrow12.containsMessage(dm(user2, [user1]))).isTrue();
      check(narrow12.containsMessage(dm(user1, [user2, user3]))).isFalse();
      check(narrow12.containsMessage(dm(user2, [user1, user3]))).isFalse();
      check(narrow12.containsMessage(dm(user3, [user1, user2]))).isFalse();

      check(narrow123.containsMessage(streamMessage)).isFalse();
      check(narrow123.containsMessage(dm(user2, []))).isFalse();
      check(narrow123.containsMessage(dm(user1, [user2]))).isFalse();
      check(narrow123.containsMessage(dm(user2, [user1]))).isFalse();
      check(narrow123.containsMessage(dm(user1, [user2, user3]))).isTrue();
      check(narrow123.containsMessage(dm(user2, [user1, user3]))).isTrue();
      check(narrow123.containsMessage(dm(user3, [user1, user2]))).isTrue();
    });
  });
}
