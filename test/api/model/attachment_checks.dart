import 'package:checks/checks.dart';
import 'package:zulip/api/model/attachment.dart';

extension AttachmentChecks on Subject<Attachment> {
  Subject<int> get id => has((e) => e.id, 'id');
  Subject<String> get name => has((e) => e.name, 'name');
}
