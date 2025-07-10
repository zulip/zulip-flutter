import '../core.dart';
import '../model/events.dart';
import 'messages.dart';


/// https://zulip.com/api/set-typing-status
Future<void> setTypingStatus(ApiConnection connection, {
  required TypingOp op,
  required MessageDestination destination,
}) {
  switch (destination) {
    case StreamDestination():
      final supportsTypeChannel = connection.zulipFeatureLevel! >= 248; // TODO(server-9)
      final supportsStreamId = connection.zulipFeatureLevel! >= 215; // TODO(server-8)
      return connection.post('setTypingStatus', (_) {}, 'typing', {
        'op':    RawParameter(op.toJson()),
        'type':  RawParameter(supportsTypeChannel ? 'channel' : 'stream'),
        if (supportsStreamId) 'stream_id': destination.streamId
        else                  'to': [destination.streamId],
        'topic': RawParameter(destination.topic.apiName),
      });
    case DmDestination():
      final supportsDirect = connection.zulipFeatureLevel! >= 174; // TODO(server-7)
      return connection.post('setTypingStatus', (_) {}, 'typing', {
        'op':   RawParameter(op.toJson()),
        'type': RawParameter(supportsDirect ? 'direct' : 'private'),
        'to':   destination.userIds,
      });
  }
}
