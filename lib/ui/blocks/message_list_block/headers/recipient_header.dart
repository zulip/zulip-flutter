import 'package:flutter/material.dart';

import '../../../../api/model/model.dart';
import '../../../../model/narrow.dart';
import 'dm_recipient_header.dart';
import 'stream_message_recipient_header.dart';

class RecipientHeader extends StatelessWidget {
  const RecipientHeader({
    super.key,
    required this.message,
    required this.narrow,
  });

  final MessageBase message;
  final Narrow narrow;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    return switch (message) {
      MessageBase<StreamConversation>() => StreamMessageRecipientHeader(
        message: message,
        narrow: narrow,
      ),
      MessageBase<DmConversation>() => DmRecipientHeader(
        message: message,
        narrow: narrow,
      ),
      MessageBase<Conversation>() => throw StateError(
        'Bad concrete subclass of MessageBase',
      ),
    };
  }
}
