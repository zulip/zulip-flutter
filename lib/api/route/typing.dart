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
      return connection.post('setTypingStatus', (_) {}, 'typing', {
        'op':        RawParameter(op.toJson()),
        'type':      RawParameter(supportsTypeChannel ? 'channel' : 'stream'),
        'stream_id': destination.streamId,
        'topic':     RawParameter(destination.topic.apiName),
      });
    case DmDestination():
      return connection.post('setTypingStatus', (_) {}, 'typing', {
        'op':   RawParameter(op.toJson()),
        'type': RawParameter('direct'),
        'to':   destination.userIds,
      });
  }
}
