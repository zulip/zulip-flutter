import 'dart:convert';

class GetLinkifierResults {
  final List<LinkifierData> linkifiers;
  final String result;
  final String message;

  GetLinkifierResults({
    required this.linkifiers,
    required this.result,
    required this.message,
  });

  factory GetLinkifierResults.fromJson(Map<String, dynamic> data) {
    final List<dynamic> linkifiers = data['linkifiers'] is List<dynamic>
        ? data['linkifiers'] as List<dynamic>
        : [];
    return GetLinkifierResults(
      linkifiers: linkifiers
          .map((item) => LinkifierData.fromJson(item as Map<String, dynamic>))
          .toList(),
      result: data['result'] is String ? data['result'] as String : "",
      message: data['msg'] is String ? data['msg'] as String : "",
    );
  }
}

class LinkifierData {
  final int id;
  final String pattern;
  final String urlTemplate;
  final String? exampleInput;
  final String? reverseTemplate;
  final List<String> alternativeUrlTemplates;
  final String dataResponse;

  LinkifierData({
    required this.id,
    required this.pattern,
    required this.urlTemplate,
    required this.exampleInput,
    required this.reverseTemplate,
    required this.alternativeUrlTemplates,
    required this.dataResponse,
  });

  factory LinkifierData.fromJson(Map<String, dynamic> data) {
    return LinkifierData(
      id: data['id'] as int,
      pattern: data['pattern'] as String,
      urlTemplate: data['url_template'] as String,
      exampleInput: data['example_input'] is String
          ? data['example_input'] as String
          : null,
      reverseTemplate: data['reverse_template'] is String
          ? data['reverse_template'] as String
          : null,
      alternativeUrlTemplates: data['alternative_url_templates'] is List<String>
          ? data['alternative_url_templates'] as List<String>
          : [],
      dataResponse: jsonEncode(data),
    );
  }

  @override
  String toString() {
    return dataResponse;
  }
}
