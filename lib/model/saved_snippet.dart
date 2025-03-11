import '../api/model/events.dart';
import '../api/model/model.dart';

mixin SavedSnippetStore {
  Iterable<SavedSnippet> get savedSnippets;
}

class SavedSnippetStoreImpl with SavedSnippetStore {
  SavedSnippetStoreImpl({required Iterable<SavedSnippet> savedSnippets})
    : _savedSnippets = Map.fromIterable(
        savedSnippets, key: (x) => (x as SavedSnippet).id);

  @override
  Iterable<SavedSnippet> get savedSnippets => _savedSnippets.values;

  final Map<int, SavedSnippet> _savedSnippets;

  void handleSavedSnippetsEvent(SavedSnippetsEvent event) {
    switch (event) {
      case SavedSnippetsAddEvent(:final savedSnippet):
        _savedSnippets[savedSnippet.id] = savedSnippet;

      case SavedSnippetsRemoveEvent(:final savedSnippetId):
        _savedSnippets.remove(savedSnippetId);
    }
  }
}
