import '../api/model/initial_snapshot.dart';
import 'store.dart';

/// The portion of [PerAccountStore] for realm settings, server settings,
/// and similar data about the whole realm or server.
///
/// See also:
///  * [RealmStoreImpl] for the implementation of this that does the work.
mixin RealmStore {
}

/// The implementation of [RealmStore] that does the work.
class RealmStoreImpl extends PerAccountStoreBase with RealmStore {
  RealmStoreImpl({
    required super.core,
    required InitialSnapshot initialSnapshot,
  });
}
