import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/store.dart';

extension PerAccountStoreTestExtension on PerAccountStore {
  void addUser(User user) {
    handleEvent(RealmUserAddEvent(id: 1, person: user));
  }

  void addUsers(Iterable<User> users) {
    for (final user in users) {
      addUser(user);
    }
  }
}
