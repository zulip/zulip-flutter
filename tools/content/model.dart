import 'dart:io';
import 'dart:convert';

/// A data structure representing a message.
final class MessageEntry {
  const MessageEntry({
    required this.id,
    required this.content,
  });

  /// Selectively parses from get-message responses.
  ///
  /// See also: https://zulip.com/api/get-messages#response
  factory MessageEntry.fromJson(Map<String, Object?> json) {
    try {
      return MessageEntry(
        id: (json['id'] as num).toInt(), content: json['content'] as String);
    } catch (e) {
      throw FormatException(
        'Malformed corpus data entry. Got: $e\n'
        'When parsing: $json');
    }
  }

  Map<String, Object> toJson() => {'id': id, 'content': content};

  /// The message ID, unique within a server.
  final int id;

  /// The rendered HTML of the message.
  final String content;
}

/// Open the given JSON Lines file and read [MessageEntry]'s from it.
///
/// We store the entries in JSON Lines format and return them from a stream to
/// avoid excessive use of memory.
Stream<MessageEntry> readMessagesFromJsonl(File file) => file.openRead()
  .transform(utf8.decoder).transform(const LineSplitter())
  .map(jsonDecode).map((x) => MessageEntry.fromJson(x as Map<String, Object?>));
