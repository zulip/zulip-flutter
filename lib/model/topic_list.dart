import 'package:flutter/foundation.dart';
import '../api/route/channels.dart';
import '../model/store.dart';

class TopicListView extends ChangeNotifier {
  TopicListView({required this.store, required this.streamId});

  final PerAccountStore store;
  final int streamId;

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<GetStreamTopicsEntry>? _topics;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  List<GetStreamTopicsEntry>? get topics => _topics;

  Future<void> fetchTopics() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await getStreamTopics(store.connection, streamId: streamId);
      _topics = response.topics;
      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}