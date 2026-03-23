import '../../api/model/model.dart';
import '../../model/narrow.dart';

class InboxChannelSectionTopicData {
  final TopicName topic;
  final int count;
  final bool hasMention;
  final int lastUnreadId;

  const InboxChannelSectionTopicData({
    required this.topic,
    required this.count,
    required this.hasMention,
    required this.lastUnreadId,
  });
}

sealed class InboxSectionData {
  const InboxSectionData();
}

class AllDmsSectionData extends InboxSectionData {
  final int count;
  final bool hasMention;
  final List<(DmNarrow, int, bool)> items;

  const AllDmsSectionData(this.count, this.hasMention, this.items);
}

class StreamSectionData extends InboxSectionData {
  final int streamId;
  final int count;
  final bool hasMention;
  final List<InboxChannelSectionTopicData> items;

  const StreamSectionData(
    this.streamId,
    this.count,
    this.hasMention,
    this.items,
  );
}
