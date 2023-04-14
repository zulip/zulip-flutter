import '../api/model/model.dart';

class MentionAutocompleteQuery {
  MentionAutocompleteQuery(this.raw)
    : _lowercaseWords = raw.toLowerCase().split(' ');

  final String raw;

  final List<String> _lowercaseWords;

  bool testUser(User user) {
    // TODO test email too, not just name
    // TODO test with diacritics stripped, where appropriate

    // TODO cache, elsewhere
    final List<String> nameWords = user.fullName.toLowerCase().split(' ');

    int nameWordsIndex = 0;
    int queryWordsIndex = 0;
    while (true) {
      if (queryWordsIndex == _lowercaseWords.length) {
        return true;
      }
      if (nameWordsIndex == nameWords.length) {
        return false;
      }

      if (nameWords[nameWordsIndex].startsWith(_lowercaseWords[queryWordsIndex])) {
        queryWordsIndex++;
      }
      nameWordsIndex++;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is MentionAutocompleteQuery && other.raw == raw;
  }

  @override
  int get hashCode => Object.hash('MentionAutocompleteQuery', raw);
}
