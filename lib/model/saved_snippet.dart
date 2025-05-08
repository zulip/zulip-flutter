import 'package:collection/collection.dart';

import '../api/model/events.dart';
import '../api/model/model.dart';

mixin SavedSnippetStore {
  Map<int, SavedSnippet> get savedSnippets;
}

class SavedSnippetStoreImpl with SavedSnippetStore {
  SavedSnippetStoreImpl({required Iterable<SavedSnippet> savedSnippets})
    : _savedSnippets = Map.fromIterable(
        savedSnippets, key: (x) => (x as SavedSnippet).id);

  @override
  late Map<int, SavedSnippet> savedSnippets = UnmodifiableMapView(_savedSnippets);
  final Map<int, SavedSnippet> _savedSnippets;

  void handleSavedSnippetsEvent(SavedSnippetsEvent event) {
    switch (event) {
      case SavedSnippetsAddEvent(:final savedSnippet):
        _savedSnippets[savedSnippet.id] = savedSnippet;

      case SavedSnippetsUpdateEvent(:final savedSnippet):
        assert(_savedSnippets[savedSnippet.id]!.dateCreated
                 == savedSnippet.dateCreated); // TODO(log)
        _savedSnippets[savedSnippet.id] = savedSnippet;

      case SavedSnippetsRemoveEvent(:final savedSnippetId):
        _savedSnippets.remove(savedSnippetId);
    }
  }
}
