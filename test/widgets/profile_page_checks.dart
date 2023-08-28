import 'package:checks/checks.dart';
import 'package:zulip/widgets/profile.dart';

extension ProfilePageChecks on Subject<ProfilePage> {
  Subject<int> get userId => has((x) => x.userId, 'userId');
}
