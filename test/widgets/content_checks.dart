import 'package:checks/checks.dart';
import 'package:zulip/widgets/content.dart';

extension RealmContentNetworkImageChecks on Subject<RealmContentNetworkImage> {
  Subject<Uri> get src => has((i) => i.src, 'src');
  // TODO others
}
