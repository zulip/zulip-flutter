import '../../log.dart';
import '../../model/store.dart';
import 'submessage.dart';

/// States of a poll Zulip widget.
///
/// See also:
/// - https://zulip.com/help/create-a-poll
/// - https://github.com/zulip/zulip/blob/304d948416465c1a085122af5d752f03d6797003/web/shared/src/poll_data.ts
class Poll {
  Poll({
    required this.submessages,
    required this.pollSenderId,
    required this.question,
    required final List<String> options,
  }) {
    for (int index = 0; index < options.length; index += 1) {
      // [null] is necessary for creating initial poll options.
      _addOption(null, options[index], optionIndex: index);
    }
  }

  factory Poll.fromSubmessages(
    List<Submessage> submessages,
    {required int senderId, required PollWidgetData widgetData}
  ) {
    assert(submessages.isNotEmpty);
    final widgetEventSubmessages = submessages.sublist(1);

    final poll = Poll(
      submessages: submessages,
      pollSenderId: senderId,
      question: widgetData.extraData.question,
      options: widgetData.extraData.options,
    );

    for (final submessage in widgetEventSubmessages) {
      final event = PollEvent.fromJson(submessage.content as Map<String, Object?>);
      poll.applyEvent(submessage.senderId, event);
    }
    return poll;
  }

  /// See [Message._pollToJson].
  final List<Submessage> submessages;
  final int pollSenderId;
  String question;

  /// The limit of options any single user can add to a poll.
  ///
  /// See https://github.com/zulip/zulip/blob/304d948416465c1a085122af5d752f03d6797003/web/shared/src/poll_data.ts#L69-L71
  static const maxOptionIndex = 1000; // TODO validate

  Iterable<Option> get options => _options.values;
  final Set<String> _optionNames = {};
  final Map<String, Option> _options = {};

  void applyEvent(int senderId, PollEvent event) {
    switch (event) {
      case PollOptionEvent():
        _addOption(
          senderId,
          event.option,
          optionIndex: event.latestOptionIndex,
        );

      case PollQuestionEvent():
        if (senderId != pollSenderId) {
          // Only the message owner can edit the question.
          assert(debugLog('unexpected poll data: user $senderId is not allowed to edit the question')); // TODO(log)
          return;
        }

        question = event.question;

      case PollVoteEvent():
        final option = _options[event.key];
        if (option == null) {
          assert(debugLog('vote for unknown key ${event.key}')); // TODO(log)
          return;
        }

        switch (event.op) {
          case VoteOp.add:
            option.voters.add(senderId);
          case VoteOp.remove:
            option.voters.remove(senderId);
          case VoteOp.unknown:
        }

      case UnknownPollEvent():
    }
  }

  void _addOption(int? senderId, String option, {required int optionIndex}) {
    if (optionIndex > maxOptionIndex) return;
    final key = PollEvent.optionKey(senderId: senderId, optionIndex: optionIndex);
    // The web client suppresses duplicate options, which can be created through
    // the /poll command as there is no server-side validation.
    if (_optionNames.contains(option)) return;
    assert(!_options.containsKey(key));
    _options[key] = Option(text: option);
    _optionNames.add(option);
  }
}

class Option {
  Option({required this.text});

  factory Option.withVoters(String text, Iterable<int> voters) =>
    Option(text: text)..voters.addAll(voters);

  final String text;
  final Set<int> voters = {};

  Iterable<String> getVoterNames(PerAccountStore store, String fallback) =>
    voters.map((userId) => store.users[userId]?.fullName ?? fallback);

  @override
  bool operator ==(Object other) {
    if (other is! Option) return false;

    return other.hashCode == hashCode;
  }

  @override
  int get hashCode => Object.hash('Option', text, voters.join(','));

  @override
  String toString() => 'Option(option: $text, voters: {${voters.join(', ')}})';
}
